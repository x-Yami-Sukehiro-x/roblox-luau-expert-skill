#!/usr/bin/env python3
"""Measure how close each Luau function is to the register, local and upvalue limits.

Port of tools/bin/check-registers.mjs; lint-parity.mjs holds the two to the
same findings. The file is compiled at -O0, where every local keeps its own
register, and the bytecode listing is read for the highest register and
upvalue each function touches.

Two findings come from the source beside the listing: W-SCOPE, a name declared
local in the file but read or written as a global elsewhere (nil at runtime),
and I-LOCALS, the families of top-level locals when the main chunk is full.

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


IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*")
# A line ending in one of these continues the statement on the next line.
CONTINUES = re.compile(r"(=|,|\(|\{|\.\.|\band|\bor|[-+*/])\s*$")


def without_comment(text):
    at = text.find("--")
    return text if at == -1 else text[:at]


def names_declared(text):
    named = re.match(r"^\s*local\s+function\s+([A-Za-z_][A-Za-z0-9_]*)", text)
    if named:
        return [named.group(1)]
    listed = re.match(r"^\s*local\s+([^=]+)", without_comment(text))
    if not listed:
        return []
    depth = 0
    piece = ""
    pieces = []
    for char in listed.group(1):
        if char in "<({[":
            depth += 1
        if char in ">)}]":
            depth -= 1
        if char == "," and depth == 0:
            pieces.append(piece)
            piece = ""
        else:
            piece += char
    pieces.append(piece)
    names = []
    for part in pieces:
        match = IDENTIFIER.match(part.strip())
        if match:
            names.append(match.group(0))
    return names


def declarations(source):
    lines = re.split(r"\r?\n", source)
    found = []
    for index, text in enumerate(lines):
        names = names_declared(text)
        if not names:
            continue
        last = index
        while last + 1 < len(lines) and CONTINUES.search(without_comment(lines[last])):
            last += 1
        found.append({"names": names, "first": index + 1, "last": last + 1,
                      "top": bool(re.match(r"^local\s", text)), "text": text})
    return found


def scope_leaks(listing, source):
    declared = {}
    for entry in declarations(source):
        for name in entry["names"]:
            declared.setdefault(name, []).append(entry)
    leaks = {}
    line = 0
    for text in re.split(r"\r?\n", listing):
        at = re.match(r"^\s+(\d+):", text)
        if at:
            line = int(at.group(1))
            continue
        found = re.match(r"^(?:GETGLOBAL|SETGLOBAL) R\d+ K\d+ \['([A-Za-z_][A-Za-z0-9_]*)'\]", text)
        if not found or found.group(1) not in declared:
            continue
        name = found.group(1)
        owners = declared[name]
        if any(entry["first"] <= line <= entry["last"] for entry in owners):
            continue
        if name in leaks:
            if line not in leaks[name]["lines"]:
                leaks[name]["lines"].append(line)
        else:
            leaks[name] = {"name": name, "declaredAt": owners[0]["first"], "lines": [line]}
    findings = []
    for leak in leaks.values():
        leak["lines"].sort()
        extra = len(leak["lines"]) - 1
        more = f" ({extra} more use{'s' if extra > 1 else ''})" if extra else ""
        findings.append({
            "code": "W-SCOPE",
            "line": leak["lines"][0],
            "message": f"`{leak['name']}` is declared local at line {leak['declaredAt']} but used here outside that scope, "
            f"so it reads a global that is nil{more}; keep it in a table both places can see",
        })
    return findings


FAMILIES = [
    ("library elements", re.compile(r":\s*(?:Create|Add|New|Make)[A-Za-z0-9_]*\s*\("), "drop `local name =` from the unused ones"),
    ("instances", re.compile(r"\bInstance\.new\s*\("), "put them in one ui table"),
    ("services", re.compile(r":GetService\s*\("), None),
    ("child lookups", re.compile(r":(?:WaitForChild|FindFirstChild)\s*\("), "put them in one table named for what they are, such as remotes"),
    ("literal settings", re.compile(r"""^\s*(?:-?[0-9][0-9_.]*|"[^"]*"|'[^']*'|true|false)\s*$"""), "put them in one CONFIG table"),
]
FAMILY_MINIMUM = 60


def local_families(source):
    lines = re.split(r"\r?\n", source)
    top = [entry for entry in declarations(source) if entry["top"]]
    counts = {}
    names = 0
    unused_elements = 0
    for entry in top:
        names += len(entry["names"])
        family = "local functions"
        if not re.match(r"^local\s+function\s", entry["text"]):
            value = "=".join(without_comment(entry["text"]).split("=")[1:])
            family = next((name for name, pattern, _ in FAMILIES if pattern.search(value)), "other")
            if family == "library elements" and len(entry["names"]) == 1:
                rest = "\n".join(lines[entry["last"]:])
                use = re.compile(r"(?<![A-Za-z0-9_.:])" + entry["names"][0] + r"(?![A-Za-z0-9_])")
                if not use.search(rest):
                    unused_elements += 1
        counts[family] = counts.get(family, 0) + len(entry["names"])
    advice = {name: hint for name, _, hint in FAMILIES}
    advice["local functions"] = "make them fields of one table"
    parts = []
    for family, count in sorted(counts.items(), key=lambda item: (-item[1], item[0])):
        unused = f", {unused_elements} never used again" if family == "library elements" and unused_elements else ""
        hint = advice.get(family)
        parts.append(f"{count} {family}{unused}{f' ({hint})' if hint else ''}")
    return names, ", ".join(parts)


def family_finding(source):
    names, summary = local_families(source)
    if names < FAMILY_MINIMUM:
        return []
    return [{"code": "I-LOCALS", "line": 1, "message": f"the main chunk declares {names} top-level locals: {summary}"}]


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
        findings = [{"code": "E-COMPILE", "line": int(at), "message": f"{kind}: {message.strip()}{explained}"}]
        if re.search(r"Out of (?:local )?registers", message):
            findings.extend(family_finding(Path(file).read_text(encoding="utf-8")))
        return {"findings": findings, "functions": []}

    source = Path(file).read_text(encoding="utf-8")
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
            if entry["name"] == "main chunk":
                findings.extend(family_finding(source))
        if entry["upvalues"] >= min(budget, UPVALUE_LIMIT):
            findings.append({
                "code": "W-UPVALUES",
                "line": entry["first"],
                "message": f"{describe(entry)} uses {entry['upvalues']} of {UPVALUE_LIMIT} upvalues; pass a context table instead",
            })
    findings.extend(scope_leaks(listed.stdout, source))
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
