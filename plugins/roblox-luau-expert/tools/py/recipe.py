#!/usr/bin/env python3
"""Look up what a picked style code or feature builds, without reading a pack.

A reply that has "T21 + M4 + H3" needs three table rows and the names of the
files to paste, not the whole 30,000-character style guide. This prints exactly
that: the row, the call, and each recipe file once, however many codes use it.

Usage:
    python tools/py/recipe.py T21 M4 H3
    python tools/py/recipe.py fly esp
    python tools/py/recipe.py --paste T21 M4     also print each recipe file in full
    python tools/py/recipe.py --list             every code and feature, one line each

Exit 1 when a code is unknown. Standard library only, Python 3.8 and up.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SKILLS = os.path.join(ROOT, ".claude", "skills")
STYLE_GUIDE = os.path.join(SKILLS, "roblox-ui-components", "references", "style-recipes.md")
STYLE_ASSETS = os.path.join(SKILLS, "roblox-ui-components", "assets")
FEATURE_GUIDE = os.path.join(SKILLS, "roblox-executor-features", "SKILL.md")
FEATURE_ASSETS = os.path.join(SKILLS, "roblox-executor-features", "assets")

SECTION = re.compile(r"^## (.+?) — (.+)$")
ROW = re.compile(r"^\| ([A-Z]\d+) \| (.*) \|\s*$")
FEATURE_ROW = re.compile(r"^\| ([A-Za-z][A-Za-z -]*) \| `assets/([a-z-]+\.luau)` \| (.*) \|\s*$")
CALL = re.compile(r"`([a-zA-Z.]+\([^`]*\))`")
CONSTRUCTOR = re.compile(r"`((?:create|attach|show|play|confirm)[A-Za-z]*\([^`]*\))`")
STYLE_TYPE = re.compile(r"^(?:export )?type (\w+) = (.+)$", re.M)
# `notifier.percent(...)` is a method of what createNotifier returns.
OWNER = {"notifier": "createNotifier"}


def read(path):
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def defining(files, build):
    """The one file of a section that defines the function a row calls."""
    found = CALL.search(build)
    if not found or len(files) == 1:
        return files
    parts = found.group(1).split("(")[0].split(".")
    name = OWNER.get(parts[0], parts[-1]) if len(parts) > 1 else parts[0]
    owners = [path for path in files if "local function %s(" % name in read(path)]
    return owners or files


def styles_taken(files):
    """Each constructor's name mapped to the codes its style parameter accepts."""
    taken = {}
    for path in files:
        source = read(path)
        unions = dict(STYLE_TYPE.findall(source))

        def codes(name, seen=()):
            found = set()
            for part in unions.get(name, "").split("|"):
                part = part.strip()
                if part.startswith('"'):
                    found.add(part.strip('"'))
                elif part in unions and part not in seen:
                    found |= codes(part, seen + (name,))
            return found

        pattern = r"local function (\w+)\((?:[^()]|\([^()]*\))*?style: (\w+)"
        for function, union in re.findall(pattern, source):
            taken[function] = codes(union)
    return taken


def call_for(code, calls, taken):
    for call in calls:
        if code in taken.get(call.split("(")[0], ()):
            return call
    return calls[0] if calls else None


def style_entries():
    entries = {}
    title, files, calls = None, [], []
    for line in read(STYLE_GUIDE).splitlines():
        heading = SECTION.match(line)
        if heading:
            title = heading.group(1)
            names = re.findall(r"`\.\./assets/([a-z-]+\.luau)`", heading.group(2))
            files = [os.path.join(STYLE_ASSETS, name) for name in names]
            calls = []
            continue
        if line.startswith("## "):
            title, files, calls = None, [], []
            continue
        row = ROW.match(line)
        if title and not row and not line.startswith("|"):
            calls += [found for found in CONSTRUCTOR.findall(line) if found not in calls]
        if row and files:
            cells = [cell.strip() for cell in row.group(2).split(" | ")]
            build = cells[2] if len(cells) > 2 else ""
            own = CALL.search(build)
            entries[row.group(1)] = {
                "section": title,
                "files": defining(files, build),
                "call": None if own else call_for(row.group(1), calls, styles_taken(files)),
                "words": cells[0] if cells else "",
                "name": cells[1] if len(cells) > 1 else "",
                "build": cells[2] if len(cells) > 2 else "",
            }
    return entries


def feature_entries():
    entries = {}
    for line in read(FEATURE_GUIDE).splitlines():
        row = FEATURE_ROW.match(line)
        if row:
            cells = [cell.strip() for cell in row.group(3).split(" | ")]
            key = row.group(2)[: -len(".luau")]
            entries[key] = {
                "section": "Executor feature",
                "files": [os.path.join(FEATURE_ASSETS, row.group(2))],
                "call": None,
                "words": row.group(1),
                "name": "keys: " + cells[0],
                "build": cells[1] if len(cells) > 1 else "",
            }
    return entries


def shown(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def main(argv):
    paste = "--paste" in argv
    wanted = [arg for arg in argv if not arg.startswith("--")]
    entries = style_entries()
    entries.update(feature_entries())

    if "--list" in argv:
        for key, entry in entries.items():
            print("%-14s %s: %s" % (key, entry["section"], entry["name"]))
        return 0
    if not wanted:
        print(__doc__.strip().split("Usage:")[1], file=sys.stderr)
        return 2

    unknown = [key for key in wanted if key not in entries and key.upper() not in entries]
    files = []
    for key in wanted:
        entry = entries.get(key) or entries.get(key.upper())
        if entry is None:
            continue
        code = key if key in entries else key.upper()
        print("%s  %s (%s)" % (code, entry["name"], entry["section"]))
        print("  people say: %s" % entry["words"])
        print("  builds:     %s" % entry["build"])
        if entry["call"]:
            print("  call:       %s" % entry["call"])
        for path in entry["files"]:
            if path not in files:
                files.append(path)

    if files:
        print("\npaste, once each, THEME changed only:")
        for path in files:
            print("  %s  (%d lines)" % (shown(path), read(path).count("\n")))
    if paste:
        for path in files:
            print("\n-- %s\n%s" % (shown(path), read(path).rstrip()))
    if unknown:
        print("\nunknown: %s (python tools/py/recipe.py --list)" % ", ".join(unknown), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
