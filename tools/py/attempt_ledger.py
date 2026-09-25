#!/usr/bin/env python3
"""Remember what was tried, and refuse to try it again.

The Python port of tools/bin/attempt-ledger.mjs, for hosts with Python and no
Node, such as a custom GPT's Code Interpreter. Same commands, same output,
held to the Node version by tools/tests/attempt-ledger.test.mjs.

Usage:
  python tools/py/attempt_ledger.py check <file.luau> [...]
  python tools/py/attempt_ledger.py plan "<approach>"
  python tools/py/attempt_ledger.py search <words...>
  python tools/py/attempt_ledger.py lint
  python tools/py/attempt_ledger.py add --status failed --title "..." --tried "..." --saw "..." [...]

  --ledger <PROJECT_CONTEXT.md>   use this file instead of searching upward
  --no-builtin                    leave out the stack's known failures
"""

import datetime
import os
import re
import sys

LEDGER_NAME = "PROJECT_CONTEXT.md"
BUILTIN = ("roblox-attempt-memory", "references", "known-failures.md")
STATUSES = ["failed", "rejected", "fixed", "works", "open"]
GUARDED = {"failed", "rejected", "fixed"}
FIELDS = ["tried", "saw", "cause", "instead", "never", "avoid", "unless", "check", "date"]
HEADING = re.compile(r"^###\s+([A-Z]+\d+)\s+([a-z]+):\s*(.+?)\s*$")
FIELD = re.compile(r"^-\s+([A-Za-z]+):\s*(.*)$")
REPEAT_OVERLAP = 0.6
REPEAT_SHARED = 3

STOPWORDS = set((
    "the a an and or but to of in on at for with by from into onto it its this that these those is are was were "
    "be been being do does did done not no so then than too very can could should would will just also only "
    "when while each every all any some one two use used using make made set sets via per after before again"
).split(" "))

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def tokens(text):
    out = {}
    for word in re.findall(r"[a-z][a-z0-9_]*", str(text).lower()):
        if len(word) < 3 or word in STOPWORDS:
            continue
        stem = word if re.search(r"(ss|eed)$", word) else re.sub(r"(ing|ed|es|s)$", "", word)
        key = stem if len(stem) >= 3 else word
        if key not in out:
            out[key] = word
    return out


def overlap(a, b):
    shared = [a[stem] for stem in a if stem in b]
    smaller = min(len(a), len(b))
    return shared, (0 if smaller == 0 else len(shared) / smaller)


def patterns(value):
    return re.findall(r"`([^`]+)`", value or "")


class Entry:
    def __init__(self, ident, status, title, line, source):
        self.id = ident
        self.status = status
        self.title = title
        self.line = line
        self.source = source
        self.fields = {}


def parse_ledger(text, source):
    entries = []
    problems = []
    current = None
    for index, line in enumerate(re.split(r"\r?\n", text)):
        heading = HEADING.match(line)
        if heading:
            current = Entry(heading.group(1), heading.group(2), heading.group(3), index + 1, source)
            entries.append(current)
            if current.status not in STATUSES:
                problems.append((current, 'status "%s" is not one of %s' % (current.status, ", ".join(STATUSES))))
            continue
        if re.match(r"^#{1,3}\s", line):
            current = None
            continue
        field = FIELD.match(line) if current else None
        if field:
            key = field.group(1).lower()
            if key not in FIELDS:
                problems.append((current, 'unknown field "%s"' % field.group(1)))
                continue
            current.fields[key] = ("%s %s" % (current.fields[key], field.group(2))
                                   if key in current.fields else field.group(2))
    return entries, problems


def find_ledger(start):
    directory = os.path.abspath(start)
    while True:
        candidate = os.path.join(directory, LEDGER_NAME)
        if os.path.exists(candidate):
            return candidate
        parent = os.path.dirname(directory)
        if parent == directory:
            return None
        directory = parent


def builtin_path():
    roots = [os.path.join(REPO_ROOT, ".claude", "skills"), os.path.join(REPO_ROOT, "skills")]
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if plugin_root:
        roots.append(os.path.join(plugin_root, ".claude", "skills"))
    home = os.path.expanduser("~")
    roots += [os.path.join(home, ".claude", "skills"), os.path.join(home, ".cursor", "skills")]
    for root in roots:
        full = os.path.join(root, *BUILTIN)
        if os.path.exists(full):
            return full
    return None


def load(options, start_dir):
    files = []
    if options["ledger"] and not os.path.exists(options["ledger"]):
        print("no ledger at %s" % options["ledger"], file=sys.stderr)
        sys.exit(2)
    project = options["ledger"] or find_ledger(start_dir)
    if project:
        files.append(project)
    if options["builtin"]:
        builtin = builtin_path()
        if builtin:
            files.append(builtin)
    entries = []
    problems = []
    for path in files:
        with open(path, encoding="utf-8") as handle:
            parsed, found = parse_ledger(handle.read(), path)
        entries += parsed
        problems += found
    return files, entries, problems


def where(entry):
    return "%s:%d" % (os.path.relpath(entry.source, os.getcwd()).replace("\\", "/"), entry.line)


def advice(entry):
    return entry.fields.get("never") or entry.fields.get("instead") or entry.fields.get("cause") or ""


def strip_comments(source):
    source = re.sub(r"--\[(=*)\[[\s\S]*?\]\1\]", lambda m: re.sub(r"[^\n]", " ", m.group(0)), source)
    return re.sub(r"--[^\n]*", "", source)


def check(files, options):
    hits = 0
    for path in files:
        if not os.path.exists(path):
            print("no such file: %s" % path, file=sys.stderr)
            sys.exit(2)
        _, entries, _ = load(options, os.path.dirname(os.path.abspath(path)))
        with open(path, encoding="utf-8") as handle:
            code = strip_comments(handle.read())
        lines = re.split(r"\r?\n", code)
        for entry in entries:
            if entry.status not in GUARDED:
                continue
            if any(re.search(pattern, code) for pattern in patterns(entry.fields.get("unless"))):
                continue
            for pattern in patterns(entry.fields.get("avoid")):
                regex = re.compile(pattern)
                for index, line in enumerate(lines):
                    if not regex.search(line):
                        continue
                    hits += 1
                    print("%s:%d  %s %s: %s" % (path, index + 1, entry.id, entry.status, entry.title))
                    if advice(entry):
                        print("    %s" % advice(entry))
    print("no recorded mistake found" if hits == 0 else "%d recorded mistake(s) found" % hits)
    return 0 if hits == 0 else 1


def repeats_of(entries, approach):
    wanted = tokens(approach)
    repeats = []
    for entry in entries:
        if entry.status not in ("failed", "rejected"):
            continue
        shared, ratio = overlap(wanted, tokens(entry.fields.get("tried", entry.title)))
        if len(shared) >= REPEAT_SHARED and ratio >= REPEAT_OVERLAP:
            repeats.append((entry, shared, ratio))
    return sorted(repeats, key=lambda row: -row[2])


def print_repeats(repeats):
    for entry, shared, _ in repeats:
        print("REPEAT %s %s: %s  (%s)" % (entry.id, entry.status, entry.title, where(entry)))
        print("    tried: %s" % entry.fields.get("tried", ""))
        if entry.fields.get("saw"):
            print("    saw: %s" % entry.fields["saw"])
        if entry.fields.get("instead"):
            print("    instead: %s" % entry.fields["instead"])
        print("    shared: %s" % ", ".join(shared))


def plan(approach, options):
    _, entries, _ = load(options, os.getcwd())
    repeats = repeats_of(entries, approach)
    print_repeats(repeats)
    print("no failed attempt matches this approach" if not repeats else
          "%d failed attempt(s) match - change the approach or state what is different this time" % len(repeats))
    return 0 if not repeats else 1


def search(words, options):
    _, entries, _ = load(options, os.getcwd())
    wanted = tokens(" ".join(words))
    ranked = []
    for entry in entries:
        text = " ".join(str(part) for part in (entry.title, entry.fields.get("tried"),
                                               entry.fields.get("saw"), entry.fields.get("cause")))
        found = tokens(text)
        score = len([stem for stem in wanted if stem in found])
        if score > 0:
            ranked.append((entry, score))
    ranked.sort(key=lambda row: (-row[1], row[0].id))
    ranked = ranked[:5]
    for entry, _ in ranked:
        print("%s %s: %s  (%s)" % (entry.id, entry.status, entry.title, where(entry)))
        for key in ("tried", "saw", "instead", "never"):
            if entry.fields.get(key):
                print("    %s: %s" % (key, entry.fields[key]))
    print("no entry mentions these words" if not ranked else
          "%d entr%s" % (len(ranked), "y" if len(ranked) == 1 else "ies"))
    return 0


def lint(options):
    files, entries, problems = load(options, os.getcwd())
    if not files:
        print("no %s found at or above %s" % (LEDGER_NAME, os.getcwd()))
        return 0
    errors = ["%s  %s  %s" % (where(entry), entry.id, message) for entry, message in problems]
    seen = {}
    for entry in entries:
        key = "%s#%s" % (entry.source, entry.id)
        if key in seen:
            errors.append("%s  %s  duplicate id (first at line %d)" % (where(entry), entry.id, seen[key]))
        seen[key] = entry.line
        if entry.status in ("failed", "rejected") and (not entry.fields.get("tried") or not entry.fields.get("saw")):
            errors.append("%s  %s  a %s entry needs Tried and Saw" % (where(entry), entry.id, entry.status))
        if entry.status == "fixed" and not entry.fields.get("avoid") and not entry.fields.get("check"):
            errors.append("%s  %s  a fixed entry needs Avoid or Check, or the bug can come back unnoticed"
                          % (where(entry), entry.id))
        for pattern in patterns(entry.fields.get("avoid")) + patterns(entry.fields.get("unless")):
            try:
                re.compile(pattern)
            except re.error:
                errors.append("%s  %s  pattern does not compile: %s" % (where(entry), entry.id, pattern))
    failed = [entry for entry in entries if entry.status == "failed" and entry.fields.get("tried")]
    for i in range(len(failed)):
        for j in range(i + 1, len(failed)):
            shared, ratio = overlap(tokens(failed[i].fields["tried"]), tokens(failed[j].fields["tried"]))
            if len(shared) >= REPEAT_SHARED and ratio >= REPEAT_OVERLAP:
                errors.append("%s  %s  repeats %s: the same approach failed twice (%s)"
                              % (where(failed[j]), failed[j].id, failed[i].id, ", ".join(shared)))
    for error in errors:
        print(error)
    print("%d entr%s in %d file(s) - %d problem(s)"
          % (len(entries), "y" if len(entries) == 1 else "ies", len(files), len(errors)))
    return 0 if not errors else 1


def add(options):
    values = options["values"]
    status = values.get("status")
    title = values.get("title")
    if status not in STATUSES or not title:
        print("add needs --status (%s) and --title" % ", ".join(STATUSES), file=sys.stderr)
        sys.exit(2)
    path = options["ledger"] or find_ledger(os.getcwd()) or os.path.join(os.getcwd(), LEDGER_NAME)
    text = "# Project context\n"
    if os.path.exists(path):
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    entries, _ = parse_ledger(text, path)
    highest = 0
    for entry in entries:
        digits = re.sub(r"\D", "", entry.id)
        highest = max(highest, int(digits) if digits else 0)
    number = highest + 1
    lines = ["### A%d %s: %s" % (number, status, title)]
    for key in FIELDS:
        if key == "date":
            continue
        if values.get(key):
            lines.append("- %s%s: %s" % (key[0].upper(), key[1:], values[key]))
    lines.append("- Date: %s" % (values.get("date") or datetime.date.today().isoformat()))
    if not re.search(r"^## Attempts\s*$", text, re.M):
        text = text.rstrip() + "\n\n## Attempts\n"
    text = text.rstrip() + "\n\n" + "\n".join(lines) + "\n"
    repeats = repeats_of(entries, values["tried"]) if status == "failed" and values.get("tried") else []
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    print("added A%d to %s" % (number, os.path.relpath(path, os.getcwd()) or LEDGER_NAME))
    if repeats:
        print_repeats(repeats)
        print("A%d repeats %s - record what differs, or stop retrying it"
              % (number, ", ".join(entry.id for entry, _, _ in repeats)))
    return 0


def parse_args(argv):
    options = {"builtin": True, "ledger": None, "values": {}, "rest": []}
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--no-builtin":
            options["builtin"] = False
        elif arg == "--ledger":
            i += 1
            options["ledger"] = argv[i] if i < len(argv) else None
        elif arg.startswith("--"):
            key = arg[2:]
            i += 1
            value = argv[i] if i < len(argv) else ""
            if key == "avoid" and options["values"].get("avoid"):
                value = "%s %s" % (options["values"]["avoid"], value)
            options["values"][key] = value
        else:
            options["rest"].append(arg)
        i += 1
    return options


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    argv = sys.argv[1:]
    command = argv[0] if argv else None
    options = parse_args(argv[1:])
    rest = options["rest"]
    if command == "check" and rest:
        code = check(rest, options)
    elif command == "plan" and rest:
        code = plan(" ".join(rest), options)
    elif command == "search" and rest:
        code = search(rest, options)
    elif command == "lint":
        code = lint(options)
    elif command == "add":
        code = add(options)
    else:
        print('usage: attempt_ledger.py check <file...> | plan "<approach>" | search <words...> | lint | '
              "add --status <s> --title <t> [...]", file=sys.stderr)
        sys.exit(2)
    sys.exit(code)


if __name__ == "__main__":
    main()
