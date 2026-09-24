#!/usr/bin/env python3
"""Measure how close each Luau function is to the register, local and upvalue limits.

Port of tools/bin/check-registers.mjs; lint-parity.mjs holds the two to the
same findings. The file is compiled at -O0, where every local keeps its own
register, and the bytecode listing is read for the highest register and
upvalue each function touches.

Usage: python tools/py/register_budget.py [--budget N] [--json] <file.luau|directory> [...]
Exit 1 when a file does not compile or a function is over budget; exit 2 when
no Luau compiler is available.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_luau import compiler  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
LOCAL_LIMIT = 200
REGISTER_LIMIT = 255
UPVALUE_LIMIT = 200
DEFAULT_BUDGET = 160

CAUSES = [
    (r"Out of local registers", "too many locals alive at once in one function (limit 200)",
     "group related locals into one table, close finished steps with do ... end, or move a section into its own local function"),
    (r"Out of registers when trying to allocate", "one expression needs more temporary slots than are left (limit 255)",
     "pass a table instead of a very long argument list, build long text with table.concat, return one table"),
    (r"Out of upvalue registers", "one function uses more than 200 locals from outside it",
     "pass one context table in, or group the outer locals into tables"),
    (r"Exceeded constant limit", "too many different literal values in one function",
     "move the data into a ModuleScript or a separate function"),
    (r"Exceeded function instruction limit", "one function body is too long",
     "split it into several functions"),
    (r"return count limit", "a return statement lists too many values",
     "return one table instead"),
]


def collect(target, out):
    if target.is_dir():
        for entry in sorted(target.iterdir(), key=lambda path: path.name):
            if entry.name in ("node_modules", ".git"):
                continue
            collect(entry, out)
    elif re.search(r"\.luau?$", target.name, re.IGNORECASE):
        out.append(target)
    return out


def measure(listing):
    functions = []
    current = None
    line = 0
    for text in listing.splitlines():
        header = re.match(r"^Function \d+ \((.*?)\)", text)
        if header:
            current = {"name": header.group(1), "first": 0, "registers": 0, "peakLine": 0, "upvalues": 0}
            functions.append(current)
            continue
        if current is None:
            continue
        source = re.match(r"^\s+(\d+):", text)
        if source:
            line = int(source.group(1))
            if not current["first"]:
                current["first"] = line
            continue
        for match in re.finditer(r"\bR(\d+)\b", text):
            used = int(match.group(1)) + 1
            if used > current["registers"]:
                current["registers"] = used
                current["peakLine"] = line
        for match in re.finditer(r"\b(?:GETUPVAL|SETUPVAL) R\d+ (\d+)|\bCAPTURE UPVAL U(\d+)", text):
            current["upvalues"] = max(current["upvalues"], int(match.group(1) or match.group(2)) + 1)
    if functions:
        functions[-1]["name"] = "main chunk"
    for entry in functions:
        if entry["name"] == "??":
            entry["name"] = "anonymous function"
    return functions


def describe(entry):
    return "main chunk" if entry["name"] == "main chunk" else f"{entry['name']} (line {entry['first']})"


def check(file, budget):
    listed = subprocess.run(
        [str(compiler()), "--text", "-O0", str(file)], capture_output=True, text=True, timeout=60
    )
    output = (listed.stdout or "") + (listed.stderr or "")
    failure = re.search(r"\((\d+),\d+\): (\w+Error): (.*)", output)
    if listed.returncode != 0 or failure:
        if failure:
            at, kind, message = failure.group(1), failure.group(2), failure.group(3)
        else:
            at, kind, message = "0", "Error", output.strip().split("\n")[0]
        cause = next((entry for entry in CAUSES if re.search(entry[0], message)), None)
        explained = f" - {cause[1]}; {cause[2]}" if cause else ""
        return {"findings": [{"code": "E-COMPILE", "line": int(at), "message": f"{kind}: {message.strip()}{explained}"}], "functions": []}

    functions = measure(listed.stdout)
    findings = []
    for entry in functions:
        if entry["registers"] >= budget:
            findings.append({
                "code": "W-REGISTERS",
                "line": entry["peakLine"],
                "message": f"{describe(entry)} peaks at {entry['registers']} of {REGISTER_LIMIT} registers "
                f"(locals stop at {LOCAL_LIMIT}); move locals into tables or functions now",
            })
        if entry["upvalues"] >= min(budget, UPVALUE_LIMIT):
            findings.append({
                "code": "W-UPVALUES",
                "line": entry["first"],
                "message": f"{describe(entry)} uses {entry['upvalues']} of {UPVALUE_LIMIT} upvalues; pass a context table instead",
            })
    return {"findings": findings, "functions": functions}


def display(path):
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def main():
    args = sys.argv[1:]
    as_json = "--json" in args
    budget = DEFAULT_BUDGET
    targets = []
    index = 0
    while index < len(args):
        if args[index] == "--budget":
            index += 1
            budget = int(args[index]) if index < len(args) and args[index].isdigit() else 0
        elif not args[index].startswith("--"):
            targets.append(Path(args[index]))
        index += 1
    if not 1 <= budget <= REGISTER_LIMIT or not targets:
        print("Usage: python tools/py/register_budget.py [--budget N] [--json] <file.luau|directory> [...]", file=sys.stderr)
        return 2

    try:
        compiler()
    except FileNotFoundError as error:
        print(f"Luau compiler unavailable; register budget not checked: {error}", file=sys.stderr)
        return 2

    files = [path for target in targets for path in collect(target, [])]
    results = [{"file": display(path), **check(path, budget)} for path in files]

    if as_json:
        payload = {"budget": budget, "results": [{"file": r["file"], "findings": r["findings"]} for r in results]}
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        for result in results:
            top = max(result["functions"], key=lambda entry: entry["registers"], default=None)
            headroom = f"; highest: {describe(top)} at {top['registers']}/{REGISTER_LIMIT}" if top else ""
            print(result["file"] + ("" if result["findings"] else f"  ok{headroom}"))
            for finding in result["findings"]:
                print(f"  {finding['line']}: {finding['code']} {finding['message']}")
        flagged = sum(1 for result in results if result["findings"])
        print(f"\n{len(files)} file(s) compiled at -O0, budget {budget} registers: {flagged} need work.")
    return 1 if any(result["findings"] for result in results) else 0


if __name__ == "__main__":
    sys.exit(main())
