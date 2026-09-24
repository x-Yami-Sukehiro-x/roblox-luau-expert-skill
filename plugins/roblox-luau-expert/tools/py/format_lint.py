#!/usr/bin/env python3
"""Count the formatting a Roblox Luau expert would not have shipped.

A port of tools/bin/lint-luau-format.mjs, held to identical findings by
tools/bin/lint-parity.mjs. StyLua is the real answer and this is not a
replacement for it — it is what runs where StyLua does not: a chat window hands
back a file, nobody pipes it through a formatter, and the result reads as
generated before a single rule about comments has been broken.

Thresholds match the stylua.toml this stack documents: column_width = 100,
indent_type = Tabs, indent_width = 4.

Usage:
    python format_lint.py <file.luau> [more.luau ...]
    python format_lint.py <directory>
    python format_lint.py --json <file.luau>

Exit 1 on any E-* finding. W-* are reported and do not fail.
"""

import json
import os
import re
import sys

COLUMN_WIDTH = 100
INDENT_WIDTH = 4
MAX_BLANK_RUN = 1
MAX_DENSE_RUN = 35
JOINABLE_WIDTH = COLUMN_WIDTH

OPENS_BLOCK = re.compile(r"\b(then|do|repeat)\s*$|[({\[]\s*$|\bfunction\b[^)]*\)\s*$")
CLOSES_BLOCK = re.compile(r"^\s*(end|until|\}|\))[,;)]?\s*$")
STARTS_SPLIT = re.compile(r"[({\[]\s*$|=\s*$")
BLOCK_WORD = re.compile(r"\b(function|then|do)\b")


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def mask(source):
    """Blank the contents of strings and comments; keep the line structure."""
    out = list(source)
    index = 0
    length = len(source)

    def blank(start, stop):
        for i in range(start, min(stop, length)):
            if out[i] != "\n":
                out[i] = " "

    while index < length:
        char = source[index]

        if char == "-" and source[index + 1:index + 2] == "-":
            bracket = re.match(r"^\[(=*)\[", source[index + 2:index + 12])
            if bracket:
                closer = "]" + bracket.group(1) + "]"
                close = source.find(closer, index + 2 + len(bracket.group(0)))
                stop = length if close == -1 else close + len(closer)
                blank(index + 2, stop)
                index = stop
                continue
            stop = source.find("\n", index)
            if stop == -1:
                stop = length
            blank(index + 2, stop)
            index = stop
            continue

        if char in ('"', "'"):
            cursor = index + 1
            while cursor < length and source[cursor] != char and source[cursor] != "\n":
                if source[cursor] == "\\":
                    cursor += 1
                cursor += 1
            blank(index + 1, cursor)
            index = cursor + 1
            continue

        long = re.match(r"^\[(=*)\[", source[index:index + 10])
        if long:
            closer = "]" + long.group(1) + "]"
            close = source.find(closer, index + len(long.group(0)))
            stop = length if close == -1 else close + len(closer)
            blank(index + len(long.group(0)), stop - len(closer))
            index = stop
            continue

        index += 1

    return "".join(out)


def width(line):
    columns = 0
    for char in line:
        columns += INDENT_WIDTH if char == "\t" else 1
    return columns


def depth_delta(text):
    delta = 0
    for char in text:
        if char in "([{":
            delta += 1
        elif char in ")]}":
            delta -= 1
    return delta


def analyse(raw_source, rel):
    findings = []

    def add(code, line, message):
        findings.append({"code": code, "line": line, "message": message, "file": rel})

    source = raw_source[1:] if raw_source[:1] == "﻿" else raw_source
    raw = re.split(r"\r?\n", source)
    masked = re.split(r"\r?\n", mask(source))

    def masked_at(index):
        return masked[index] if 0 <= index < len(masked) else ""

    # --- indentation ------------------------------------------------------
    tabs = 0
    spaces = 0
    for index, line in enumerate(raw):
        # A continuation line inside a doc comment aligns a numbered list with
        # tab-then-spaces, which is correct and is not indentation at all. Only
        # a line carrying code has the indent this rule is about.
        if not masked_at(index).strip():
            continue
        lead = re.match(r"^[ \t]*", line).group(0)
        if not lead:
            continue
        if "\t" in lead:
            tabs += 1
        if re.match(r"^ {2,}", lead):
            spaces += 1
        # A space before a tab is unambiguous: no editor setting renders it right.
        if re.search(r" \t", lead):
            add("E-MIXEDINDENT", index + 1,
                "a space before a tab in the indent - renders differently for every reader")
    if tabs > 0 and spaces > 0:
        add("E-MIXEDINDENT", 1,
            "%d line(s) indent with tabs and %d with spaces - pick the one the file already uses"
            % (tabs, spaces))

    # --- per line ---------------------------------------------------------
    blank_run = 0
    dense_run = 0
    dense_start = 0
    brace_depth = 0

    for index, line in enumerate(raw):
        number = index + 1
        masked_line = masked_at(index)

        if not line.strip():
            blank_run += 1
            if blank_run == MAX_BLANK_RUN + 1:
                add("E-BLANKRUN", number,
                    "%d blank lines in a row - one separates, more is spacing by feel"
                    % (MAX_BLANK_RUN + 1))
            dense_run = 0
            continue
        blank_run = 0

        # Depth is measured before this line is counted, so the opening `{` of a
        # table is the last line counted and its contents are not.
        if brace_depth > 0:
            dense_run = 0
        else:
            if dense_run == 0:
                dense_start = number
            dense_run += 1
        brace_depth += masked_line.count("{") - masked_line.count("}")
        if brace_depth < 0:
            brace_depth = 0

        if dense_run == MAX_DENSE_RUN + 1:
            add("W-DENSE", dense_start,
                "%d lines with no blank line since %d - nothing marks where one idea ends"
                % (MAX_DENSE_RUN + 1, dense_start))

        if re.search(r"[ \t]+$", line):
            add("W-TRAILWS", number, "trailing whitespace")

        # StyLua sets the width of code and never reflows a comment, so neither
        # does this. A wrapped sentence is the writer's business.
        if masked_line.strip() and width(line) > COLUMN_WIDTH:
            add("W-WIDTH", number,
                "%d columns of code (column_width is %d)" % (width(line), COLUMN_WIDTH))

        previous = raw[index - 1] if index - 1 >= 0 else None
        if previous is not None and not previous.strip():
            opener = masked_at(index - 2)
            if OPENS_BLOCK.search(opener):
                add("E-BLANKEDGE", number - 1,
                    "blank line directly after the line that opens the block")
        if CLOSES_BLOCK.match(line) and previous is not None and not previous.strip():
            add("E-BLANKEDGE", number - 1,
                "blank line directly before the line that closes the block")

        if re.search(r";\s*$", masked_line):
            add("W-SEMICOLON", number,
                "trailing semicolon - Luau does not need it and StyLua removes it")

        for match in re.finditer(r",(?=\S)", masked_line):
            following = masked_line[match.start() + 1:match.start() + 2]
            if following in (")", "}"):
                continue
            add("W-COMMA", number, "no space after a comma")
            break
        if re.search(r"[^,]\s+,", masked_line):
            add("W-COMMA", number, "space before a comma")

    # --- breaks that did not need to be breaks ----------------------------
    index = 0
    while index < len(raw):
        masked_line = masked_at(index)
        trimmed = masked_line.rstrip()
        if not trimmed.strip():
            index += 1
            continue
        if not STARTS_SPLIT.search(trimmed):
            index += 1
            continue

        depth = depth_delta(trimmed)
        if depth < 0:
            index += 1
            continue

        parts = [raw[index].strip()]
        cursor = index + 1
        closed = depth == 0 and re.search(r"=\s*$", trimmed) is not None
        table_literal = "{" in trimmed

        while cursor < len(raw) and cursor - index <= 12:
            nxt = masked_at(cursor)
            if not nxt.strip():
                break
            if re.match(r"^\s*--", raw[cursor]):
                break
            parts.append(raw[cursor].strip())
            depth += depth_delta(nxt)
            if "{" in nxt:
                table_literal = True
            if depth <= 0:
                closed = True
                break
            cursor += 1

        if not closed or len(parts) < 2:
            index += 1
            continue
        # StyLua keeps a table constructor expanded once it has a trailing
        # comma, and expanding a table is how a config block stays readable.
        if table_literal:
            index += 1
            continue
        if any(BLOCK_WORD.search(part) for part in parts):
            index += 1
            continue

        joined = " ".join(parts)
        joined = re.sub(r"\(\s+", "(", joined)
        joined = re.sub(r"\s+\)", ")", joined)
        joined = re.sub(r"\s+,", ",", joined)
        indent = re.match(r"^[ \t]*", raw[index]).group(0)
        if width(indent + joined) > JOINABLE_WIDTH:
            index += 1
            continue

        add("E-SPLIT", index + 1,
            "%d lines for %d columns of code - it fits on one, so the breaks say nothing"
            % (len(parts), width(indent + joined)))
        index = cursor + 1

    if not source.endswith("\n"):
        add("W-EOF", len(raw), "no newline at end of file")
    elif re.search(r"\n\s*\n$", source):
        add("W-EOF", len(raw), "blank line(s) at end of file")

    code_lines = len([line for line in raw if line.strip()])
    longest = max([0] + [width(line) for line in raw])
    counts = {
        "lines": len(raw),
        "codeLines": code_lines,
        "longestLine": longest,
        "indent": "tabs" if tabs > 0 and spaces == 0 else ("spaces" if spaces > 0 and tabs == 0 else "mixed"),
    }
    return findings, counts


def score(findings):
    codes = set(finding["code"] for finding in findings)

    def none(*wanted):
        return not codes.intersection(wanted)

    rows = [
        ("indentation", none("E-MIXEDINDENT")),
        ("blank lines", none("E-BLANKRUN", "E-BLANKEDGE", "W-DENSE")),
        ("breaks that earn their line", none("E-SPLIT")),
        ("line hygiene", none("W-WIDTH", "W-TRAILWS", "W-SEMICOLON", "W-COMMA", "W-EOF")),
    ]
    passed = len([row for row in rows if row[1]])
    return {"rows": rows, "points": passed * 2, "total": len(rows) * 2}


def collect(target, out):
    if os.path.isdir(target):
        for entry in sorted(os.listdir(target)):
            if entry in ("node_modules", ".git"):
                continue
            collect(os.path.join(target, entry), out)
    elif re.search(r"\.luau?$", target, re.I):
        out.append(target)
    return out


def main(argv):
    args = argv[1:]
    as_json = "--json" in args
    targets = [arg for arg in args if not arg.startswith("--")]

    if not targets:
        sys.stderr.write(
            "usage: python format_lint.py <file.luau|directory> [...]\n"
            "Counts the rules in roblox-code-craft/references/formatting.md.\n")
        return 2

    files = []
    for target in targets:
        if not os.path.exists(target):
            sys.stderr.write("no such path: %s\n" % target)
            return 2
        collect(target, files)

    results = []
    for path in files:
        rel = path.replace("\\", "/")
        findings, counts = analyse(read(path), rel)
        results.append({"file": rel, "findings": findings, "counts": counts,
                        "score": score(findings)})

    if as_json:
        print(json.dumps({"results": results}, indent=2))
    else:
        for result in results:
            print("\n%s" % result["file"])
            for finding in result["findings"]:
                print("  %s:%d  %s  %s" % (result["file"], finding["line"],
                                           finding["code"], finding["message"]))
            failed = [name for name, ok in result["score"]["rows"] if not ok]
            print("  score %d/%d%s  (%s, longest %d)" % (
                result["score"]["points"], result["score"]["total"],
                ("  failing: " + ", ".join(failed)) if failed else "  all counted checks pass",
                result["counts"]["indent"], result["counts"]["longestLine"]))

    errors = [f for r in results for f in r["findings"] if f["code"].startswith("E-")]
    warnings = [f for r in results for f in r["findings"] if f["code"].startswith("W-")]
    if not as_json:
        print("\n%d file(s) - %d error(s), %d warning(s)" % (len(files), len(errors), len(warnings)))

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
