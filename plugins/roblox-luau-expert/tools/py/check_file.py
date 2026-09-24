#!/usr/bin/env python3
"""Every file-level check on a Luau file, in one call, run in parallel.

The Python twin of tools/bin/check-file.mjs, for a host with no Node such as a
custom GPT's Code Interpreter. Six checks one after another cost six start-ups
and six outputs to read; this runs them together and prints one line each, with
the full output only for a check that failed.

Usage:
    python tools/py/check_file.py <file.luau> [more.luau ...]
    python tools/py/check_file.py --compare <before.luau> <after.luau>

Exit 0 when every check passes, 1 when any fails, 2 when a check could not run
and none failed. A check that could not run is not a pass.
"""

import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
GUI_CLASS = re.compile(
    r'Instance\.new\(\s*"(ScreenGui|BillboardGui|SurfaceGui|Frame|CanvasGroup|ScrollingFrame|'
    r'TextLabel|TextButton|TextBox|ImageLabel|ImageButton)"'
)


def tool(script, *args):
    return [sys.executable, os.path.join(HERE, script)] + list(args)


def checks_for(path, before):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        drawn = GUI_CLASS.search(handle.read()) is not None
    slop = tool("roblox_lint.py", "--compare", before, path) if before else tool("roblox_lint.py", path)
    return [
        ("slop", slop),
        ("format", tool("format_lint.py", path)),
        ("ui", tool("ui_lint.py", path) if drawn else None),
        ("api", tool("verify_api.py", "--scan", path)),
        ("compile", tool("check_luau.py", path)),
        ("registers", tool("register_budget.py", path)),
    ]


def run(command):
    if command is None:
        return None
    done = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return done.returncode, (done.stdout + done.stderr).strip()


def headline(name, output):
    lines = [line.strip() for line in output.splitlines()]
    for line in lines:
        if line.startswith("score "):
            return line[len("score "):]
    if name == "registers":
        found = next((line for line in lines if " ok; highest" in line), "")
        return found.split("ok; ", 1)[-1]
    if name == "api":
        return next((line for line in lines if "every resolved member" in line), "")
    if name == "compile":
        return "compiles; not executed"
    return ""


def main(argv):
    before = None
    if argv[:1] == ["--compare"]:
        if len(argv) != 3:
            print("usage: check_file.py --compare <before.luau> <after.luau>", file=sys.stderr)
            return 2
        before, argv = argv[1], argv[2:]
    if not argv:
        print("usage: check_file.py <file.luau> [more.luau ...]", file=sys.stderr)
        return 2

    jobs = [(path, name, command) for path in argv for name, command in checks_for(path, before)]
    with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
        results = list(pool.map(run, [command for _, _, command in jobs]))

    tally = {"PASS": 0, "FAIL": 0, "SKIP": 0}
    current = None
    for (path, name, _), result in zip(jobs, results):
        if path != current:
            current = path
            print(path.replace("\\", "/"))
        if result is None:
            print("  n/a   %-10s builds no GUI" % name)
            continue
        code, output = result
        status = "PASS" if code == 0 else "SKIP" if code == 2 else "FAIL"
        tally[status] += 1
        lines = output.splitlines() or [""]
        failure = next((line for line in lines if re.search(r"\bE-[A-Z]|Error", line)), lines[0])
        detail = headline(name, output) if status == "PASS" else failure.strip()
        print("  %-5s %-10s %s" % (status, name, detail))
        if status == "FAIL":
            for line in output.splitlines():
                print("        " + line)

    print("\n%d passed, %d failed, %d could not run." % (tally["PASS"], tally["FAIL"], tally["SKIP"]))
    if tally["FAIL"]:
        return 1
    return 2 if tally["SKIP"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
