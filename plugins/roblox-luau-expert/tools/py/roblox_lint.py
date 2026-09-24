#!/usr/bin/env python3
"""Count the machine-written tells in a real Luau file.

A port of tools/bin/lint-luau-slop.mjs, held to identical findings by
tools/bin/lint-parity.mjs. It exists because the Node original cannot run in
the host that needs it most: a custom GPT's Code Interpreter is a Python
sandbox with no Node, so every instruction saying "run the counter" was advice
a model could not follow there, and advice a model cannot follow is prose.

Standard library only, Python 3.8 and up, one file. A dependency would be a
reason not to run it.

Usage:
    python roblox_lint.py <file.luau> [more.luau ...]
    python roblox_lint.py <directory>
    python roblox_lint.py --json <file.luau>
    python roblox_lint.py --compare <before.luau> <after.luau>
    cat script.luau | python roblox_lint.py --stdin

Exit 1 on any E-* finding. W-* are reported and do not fail.
"""

import json
import os
import re
import sys

MAX_HEADER_LINES_SCRIPT = 4
MAX_HEADER_LINES_MODULE = 24
MAX_CAPABILITY_STATEMENTS = 2
MAX_MESSAGE_WORDS = 12
MAX_REPEATED_PREFIX = 2
BANNER_MIN_CODE_LINES = 120
MAX_COMMENT_RATIO = 0.55
MIN_LINES_FOR_RATIO = 40
MAX_PCALL_PER_CODE_LINE = 1 / 25
MIN_PCALLS_FOR_DENSITY = 4
MIN_CLAUSE_WORDS = 3
CLAUSE_ECHO_RATIO = 0.75
CLAUSE_LOOKAHEAD = 6
MAX_VALUE_LAYERS = 2
MAX_EXECUTOR_SURFACE = 5


def rx(pattern, ignorecase=False):
    """ASCII semantics, so \\w and \\b mean what they mean in the Node original."""
    flags = re.ASCII
    if ignorecase:
        flags |= re.IGNORECASE
    return re.compile(pattern, flags)


PROVENANCE = [
    rx(r"\bbased (on|upon) the (uploaded|supplied|provided|attached|given|pasted)\b", True),
    rx(r"\bthe (uploaded|supplied|provided|attached|pasted|original) (source|script|dump|file|code|listing)\b", True),
    rx(r"\bsource[- ]established\b", True),
    rx(r"\bthe dump (has|shows|contains|establishes|gave|told)\b", True),
    rx(r"\bas (you |we )?(requested|asked|discussed)\b", True),
    rx(r"\bper your\b", True),
    rx(r"\byou (asked|provided|uploaded|supplied|gave|wanted|mentioned)\b", True),
    rx(r"\bthis (version|revision|implementation|rewrite)\b", True),
    rx(r"\bi (have|will|would|can|am)\b", True),
    rx(r"\b(note|notice) that\b", True),
    rx(r"\b(originally|previously) (generated|written|produced|suggested)\b", True),
    rx(r"\b(unlike|instead of) the (previous|earlier|first) (version|attempt|script)\b", True),
]

EDIT_NARRATION = [
    rx(r"^(fixed|fix|changed|change|updated|update|added|add|removed|remove|renamed|replaced|refactored|moved|new|old|was|before|after)\s*[:—-]", True),
    rx(r"^(fixed|changed|updated|added|removed|renamed|replaced|moved|switched|converted)\s+(the|this|a|an|it|from|to)\b", True),
    rx(r"\bin (this|the) (fix|patch|update|revision|edit|change|rewrite)\b", True),
    rx(r"\b(previously|formerly|originally),? (this|it|the (code|script|function|line))\b", True),
    rx(r"\bkept for (backwards |backward )?compat", True),
]

FILENAME_COMMENT = rx(r"^[A-Za-z_][\w.-]*\.(lua|luau|client\.lua|server\.lua)$", True)

HEADER_SUMMARY = [
    rx(r"^(handles|manages|creates|builds|renders|displays|provides|implements|sets up|defines)\b", True),
    rx(r"^this (script|module|interface|file|ui|code|system|panel|menu|component)\b", True),
    rx(r"\bclient[- ]owned\b", True),
    rx(r"\bnever stores? (any )?authoritative\b", True),
    rx(r"\b(server|client)[- ]authoritative\b", True),
    rx(r"\bclient[- ]side only\b", True),
    rx(r"\b(connections?|threads?|tweens?|listeners?|signals?)\b[^.]{0,60}\b(torn down|tear down|cleaned up|disconnected|destroyed|cancelled|canceled)\b", True),
    rx(r"\b(torn down|cleaned up|disconnected) (with|when|on) the\b", True),
]

COMMENTED_OUT = [
    rx(r"^\s*local\s+[\w.]+\s*="),
    rx(r"^\s*function\s+[\w.:]*\s*\("),
    rx(r"^\s*end\)?[,;]?\s*$"),
    rx(r"^\s*return\s+\w"),
    rx(r"^\s*(if|elseif)\s+.+\bthen\s*$"),
    rx(r"^\s*(for|while)\s+.+\bdo\s*$"),
    rx(r"^\s*[\w.]+[:.][\w]+\(.*\)\s*$"),
]

INFALLIBLE_CALLS = rx(
    r"^(Vector2|Vector3|Vector2int16|Vector3int16|CFrame|Color3|UDim|UDim2|Rect|NumberRange|Region3|TweenInfo|BrickColor)"
    r"\.(new|from[A-Za-z]+)$|^(tostring|tonumber|math\.[a-z]+|table\.create)$"
)

FALLIBLE_HINT = rx(
    r"\b(require|GetAsync|SetAsync|UpdateAsync|RemoveAsync|HttpGet|HttpPost|request|InvokeServer|InvokeClient|Invoke|"
    r"WaitForChild|getsenv|getrenv|getgenv|getgc|filtergc|hookfunction|hookmetamethod|getcustomasset|writefile|readfile|"
    r"loadstring|decompile|JSONDecode|JSONEncode|GetProductInfo|PromptPurchase|SetPrimaryPartCFrame|error|assert)\b"
    r"|\bdebug\.[a-z]"
)

SUCCESS_NARRATION = rx(
    r"\b(enabled|loaded|unloaded|initiali[sz]ed|success|successfully|ready|complete|completed|done|started|starting|"
    r"installed|injected|executing|running|active|attached)\b", True
)

PROSE_IN_MESSAGE = rx(
    r"\b(refusing to|please|make sure|you should|you can|try again|likely|probably|appears to|seems to|it looks like|"
    r"in order to|so that|because of this|for some reason)\b", True
)

CONNECTIVE = rx(
    r"\b(because|so that|otherwise|since|but|which|rather than|instead of|would|will|cannot|can't|does not|doesn't|"
    r"must|only|never|always|even|unless|until|per|see|avoids?|prevents?|breaks?|fails?|wrong|safe|deliberate|"
    r"on purpose|beware)\b", True
)

DECOMPILER_NAME = rx(r"^(?:[vup]|arg|var|upv)_?\d+$", True)

VALUE_LAYERS = [
    ("upvalue", rx(r"\b(?:debug\.)?(?:get|set)upvalue(?:s)?\b")),
    ("constant", rx(r"\b(?:debug\.)?(?:get|set)constant(?:s)?\b")),
    ("environment", rx(r"\b(?:getsenv|getrenv|getfenv|setfenv|getmenv)\b")),
    ("heap", rx(r"\b(?:getgc|filtergc|getinstances|getnilinstances|getloadedmodules)\b")),
    ("hook", rx(r"\b(?:hookfunction|hookmetamethod|replaceclosure|newcclosure|restorefunction)\b")),
    ("connection", rx(r"\b(?:getconnections|firesignal|replicatesignal)\b")),
]

EXECUTOR_ALIASES = [
    {"getcustomasset", "getsynasset"},
    {"gethui", "get_hidden_gui"},
    {"setclipboard", "toclipboard", "setrbxclipboard"},
    {"request", "http_request", "httprequest"},
    {"getexecutorname", "identifyexecutor"},
]

EXECUTOR_GLOBALS = rx(
    r"\b(?:getgenv|getrenv|getsenv|getfenv|setfenv|getmenv|getgc|filtergc|getinstances|getnilinstances|getloadedmodules|"
    r"getscripts|getrunningscripts|getconnections|firesignal|replicatesignal|hookfunction|hookmetamethod|replaceclosure|"
    r"newcclosure|restorefunction|checkcaller|islclosure|iscclosure|isexecutorclosure|clonefunction|getcallingscript|"
    r"getscriptbytecode|getscripthash|decompile|gethui|get_hidden_gui|getcustomasset|getsynasset|setclipboard|toclipboard|"
    r"readfile|writefile|appendfile|isfile|isfolder|makefolder|delfile|delfolder|listfiles|loadstring|setidentity|"
    r"getidentity|getthreadidentity|setthreadidentity|setscriptable|gethiddenproperty|sethiddenproperty|getrawmetatable|"
    r"setrawmetatable|setreadonly|isreadonly|getnamecallmethod|setnamecallmethod|getcallbackvalue|fireclickdetector|"
    r"fireproximityprompt|firetouchinterest|queue_on_teleport|queueonteleport|getexecutorname|identifyexecutor|messagebox|"
    r"setfpscap|mousemoverel|keypress|keyrelease)\b"
)

CLAUSE_SPLIT = rx(r"(?:[.;]\s+|\s+(?:so|because|since|which|but|however)\s+|\s+-\s+|\s+—\s+)")

STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "for", "with", "from", "into", "onto",
    "this", "that", "these", "those", "its", "it's", "is", "are", "was", "were",
    "be", "been", "being", "to", "of", "in", "on", "at", "by", "as", "we", "you",
    "not", "no", "all", "any", "each", "every", "one", "two", "here", "there",
    "when", "then", "than", "so", "if", "it", "our", "their", "them", "they",
}

GENERIC_LOCALS = {
    "data", "temp", "tmp", "obj", "val", "info", "stuff", "thing", "things",
    "arr", "dict", "payload", "cfg", "ctx", "elem", "misc", "helper", "manager",
    "utils", "util", "handler", "res", "ret", "vars", "stuff2", "processor",
}

BAD_ABBREVIATIONS = {
    "plr", "plrs", "chr", "pos", "cnt", "tbl", "str", "num", "idx", "btn", "txt",
    "evt", "dmg", "lvl", "spd", "amt", "qty", "desc", "scr", "inst", "wep", "itm",
    "clr", "bg", "fg", "hdl", "mgr", "ply", "hum", "wrkspc", "rs", "ws",
}

CANONICAL_FRACTIONS = {"0.5", "0.25", "0.75", "1.0", "0.0", "2.0"}

IS_MODULE = rx(r"\breturn\s+[A-Za-z_][\w.]*\s*(?:\([\s\S]*\))?\s*\Z")
PCALL_IDIOM = rx(r"^(ok|success|result|err|error|reason)$", True)
PCALL_RHS = rx(r"\bp?call\s*\(")
CAPABILITY_STATEMENT = rx(
    r"\b(?:if|elseif|assert)\s*\(?\s*(?:not\s+)?(typeof|type)\s*\(\s*[\w.]+\s*\)\s*(?:~=|==)\s*[\"'](?:function|table)[\"']"
)
PCALL_ANY = rx(r"\b(?:pcall|xpcall|ypcall)\s*\(")
PCALL_CLOSURE = rx(r"\b(?:pcall|xpcall)\s*\(\s*function\s*\(\s*\)([\s\S]*?)\bend\s*\)")
ASSIGNMENT = rx(r"[^=~<>]=[^=]")
CALL_NAME = rx(r"([A-Za-z_][\w.]*)\s*\(")
MESSAGE_CALL = rx(r"\b(error|warn|assert|print)\s*\(([\s\S]{0,400}?)\)\s*(?:\n|\Z)")
STRING_LITERAL = rx(r"\"((?:[^\"\\]|\\.)*)\"|'((?:[^'\\]|\\.)*)'")
MESSAGE_PREFIX = rx(r"^([^:]{4,40}):")
LOCAL_DECLARATION = rx(r"\blocal\s+([A-Za-z_][\w]*)\s*(?:,\s*([A-Za-z_][\w]*)\s*)?=\s*([^\n]*)")
LOCAL_NAMES = rx(r"\blocal\s+(?:function\s+)?([A-Za-z_][\w]*)((?:\s*,\s*[A-Za-z_][\w]*)*)")
FUNCTION_PARAMETERS = rx(r"\bfunction\s*[\w.:]*\s*\(([^)]*)\)")
NUMBER_LITERAL = rx(r"(?<![\w.])(\d+\.\d+|\d{4,})(?![\w.])")
STRINGS_TO_BLANK = rx(r"\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*'")
OR_LINE = re.compile(r"^[^\n]*\bor\b[^\n]*$", re.MULTILINE | re.ASCII)
DIGIT_SUFFIX = rx(r"[a-z]\d$")
SEPARATOR_RUN = rx(r"[-=*#/_]{2,}")
BANNER_RUN = rx(r"[-=*#/_]{3,}")
SENTENCE_PUNCT = rx(r"[.!?:]")
DECORATION = re.compile(r"[Ā-￿]|!")
TWO_CLAUSES = rx(r";\s")
TODO = rx(r"\b(TODO|FIXME|XXX|HACK)\b")
SHEBANG_DIRECTIVE = rx(r"^--!")
CAMEL_BOUNDARY = rx(r"([a-z0-9])([A-Z])")


# --------------------------------------------------------------------------
# Scanning


def long_bracket(source, at):
    """The end index of a `[[` / `[=[` opener at `at`, or None."""
    if at >= len(source) or source[at] != "[":
        return None
    cursor = at + 1
    level = 0
    while cursor < len(source) and source[cursor] == "=":
        level += 1
        cursor += 1
    if cursor < len(source) and source[cursor] == "[":
        return level, cursor + 1
    return None


def scan(source):
    """Split a file into code text and comment units.

    A character walk rather than a regex, because `local s = "a -- b"` is not a
    comment and `--[[ ]]` spans lines. Consecutive `--` lines join into one
    unit: a wrapped comment is one thought, and scoring its continuation lines
    separately produces findings about half-sentences.
    """
    # A UTF-8 BOM is one non-whitespace character on line 1, so without this
    # the scanner reads line 1 as code, every header comment sorts after it,
    # and the header rules stop firing on files a Windows editor saved.
    if source[:1] == "﻿":
        source = source[1:]
    raw_lines = source.split("\n")
    raw_lines = [line[:-1] if line.endswith("\r") else line for line in raw_lines]
    code_lines = [""] * len(raw_lines)
    comments = []

    index = 0
    line = 0
    pending = None

    def flush():
        nonlocal pending
        if pending is not None:
            comments.append(pending)
        pending = None

    length = len(source)
    while index < length:
        char = source[index]

        if char == "\n":
            line += 1
            index += 1
            continue

        if char == "-" and index + 1 < length and source[index + 1] == "-":
            bracket = long_bracket(source, index + 2)
            if bracket:
                level, body_start = bracket
                closer = "]" + "=" * level + "]"
                close = source.find(closer, body_start)
                stop = length if close == -1 else close + len(closer)
                body = source[body_start:length if close == -1 else close]
                flush()
                parts = [
                    {"line": line + 1 + offset, "text": part.strip()}
                    for offset, part in enumerate(body.split("\n"))
                ]
                comments.append({
                    "line": line + 1,
                    "text": body.strip(),
                    "block": True,
                    "trailing": False,
                    "lines": len(body.split("\n")),
                    "parts": parts,
                })
                line += source.count("\n", index, stop)
                index = stop
                continue

            stop = source.find("\n", index)
            if stop == -1:
                stop = length
            body = source[index + 2:stop].strip()
            has_code_before = len(code_lines[line].strip()) > 0

            if has_code_before:
                flush()
                comments.append({
                    "line": line + 1,
                    "text": body,
                    "block": False,
                    "trailing": True,
                    "lines": 1,
                    "parts": [{"line": line + 1, "text": body}],
                })
            elif pending is not None and pending["endLine"] == line:
                pending["text"] += " " + body
                pending["endLine"] = line + 1
                pending["lines"] += 1
                pending["parts"].append({"line": line + 1, "text": body})
            else:
                flush()
                pending = {
                    "line": line + 1,
                    "text": body,
                    "block": False,
                    "trailing": False,
                    "endLine": line + 1,
                    "lines": 1,
                    "parts": [{"line": line + 1, "text": body}],
                }

            index = stop
            continue

        if char in ('"', "'"):
            cursor = index + 1
            while cursor < length and source[cursor] != char:
                if source[cursor] == "\\":
                    cursor += 1
                if cursor < length and source[cursor] == "\n":
                    break
                cursor += 1
            code_lines[line] += source[index:cursor + 1]
            index = cursor + 1
            flush()
            continue

        bracket = long_bracket(source, index)
        if bracket:
            level, body_start = bracket
            closer = "]" + "=" * level + "]"
            close = source.find(closer, body_start)
            stop = length if close == -1 else close + len(closer)
            code_lines[line] += '""'
            line += source.count("\n", index, stop)
            index = stop
            flush()
            continue

        code_lines[line] += char
        index += 1
        if char.strip():
            flush()

    flush()
    return code_lines, comments


def identifier_words(text):
    """camelCase, PascalCase and snake_case into lowercase word stems."""
    words = set()
    for token in re.split(r"[^A-Za-z]+", text):
        if not token:
            continue
        for part in CAMEL_BOUNDARY.sub(r"\1 \2", token).split():
            word = part.lower()
            if word.endswith("s"):
                word = word[:-1]
            if len(word) >= 3:
                words.add(word)
    return words


def content_words(text):
    out = []
    seen = set()
    for word in re.split(r"[^a-z0-9']+", text.lower()):
        if len(word) < 3 or word in STOPWORDS:
            continue
        stem = word[:-1] if word.endswith("s") else word
        if stem in seen:
            continue
        seen.add(stem)
        out.append(stem)
    return out


def word_count(text):
    return len([part for part in text.split() if part])


def line_of(source, index):
    return source.count("\n", 0, index) + 1


# --------------------------------------------------------------------------
# Analysis


def analyse(source, rel):
    code_lines, comments = scan(source)
    findings = []

    def add(code, line, message):
        findings.append({"code": code, "line": line, "message": message, "file": rel})

    code = "\n".join(code_lines)
    code_line_count = len([text for text in code_lines if text.strip()])
    comment_line_count = sum(0 if unit["trailing"] else unit["lines"] for unit in comments)

    is_module = bool(IS_MODULE.search(code.rstrip()))

    first_code_line = -1
    for i, text in enumerate(code_lines):
        stripped = text.strip()
        if stripped and not SHEBANG_DIRECTIVE.match(stripped):
            first_code_line = i
            break

    # --- header -----------------------------------------------------------
    header_units = [
        unit for unit in comments
        if not unit["trailing"] and (first_code_line == -1 or unit["line"] <= first_code_line)
    ]
    header_lines = sum(unit["lines"] for unit in header_units)
    for unit in header_units:
        for part in unit["parts"]:
            text = part["text"].strip()
            if not text:
                continue
            for pattern in HEADER_SUMMARY:
                if not pattern.search(text):
                    continue
                add("E-HEADERSUMMARY", part["line"],
                    "header line summarises the code instead of carrying a fact from outside it: "
                    '"%s". The code below already says this, and stays right when it changes.' % text[:60])
                break

    header_cap = MAX_HEADER_LINES_MODULE if is_module else MAX_HEADER_LINES_SCRIPT
    if header_lines > header_cap:
        add("E-HEADER", header_units[0]["line"] if header_units else 1,
            "%d-line header on a %s (cap %d). A header carries decisions the code cannot show, "
            "not a summary of it." % (header_lines, "module" if is_module else "script", header_cap))

    # --- what the comments are about --------------------------------------
    label_count = 0
    for unit in comments:
        text = unit["text"].strip()
        if not text:
            continue

        for pattern in PROVENANCE:
            if pattern.search(text):
                add("E-PROVENANCE", unit["line"],
                    'comment narrates where the code came from: "%s". Say that in the reply; '
                    "the file is read by someone who was not in the conversation." % text[:64])
                break

        for pattern in EDIT_NARRATION:
            if pattern.search(text):
                add("E-EDITNOTE", unit["line"],
                    'comment narrates the edit rather than the code: "%s". The diff already says '
                    "what changed, and stays right when the next edit lands." % text[:64])
                break

        for part in unit["parts"]:
            part_text = part["text"].strip()
            if not FILENAME_COMMENT.match(part_text):
                continue
            add("E-FILENAME", part["line"],
                'comment is the file name: "%s". The file already has one, and a rename leaves '
                "this behind." % part_text)

        if TODO.search(text):
            add("E-TODO", unit["line"], '"%s" - resolve it or drop it before delivery.' % text[:48])

        if not unit["block"] and not unit["trailing"]:
            for pattern in COMMENTED_OUT:
                if pattern.search(text) and len(text) <= 90:
                    add("E-QUOTE", unit["line"], 'commented-out code: "%s"' % text[:56])
                    break

        is_separator = bool(SEPARATOR_RUN.search(text))
        if (not unit["block"] and not unit["trailing"] and not is_separator
                and not SENTENCE_PUNCT.search(text)
                and 2 <= word_count(text) <= 6):
            label_count += 1
            add("W-LABEL", unit["line"], '"%s" labels the code below instead of explaining it.' % text)

        if (not unit["block"] and code_line_count < BANNER_MIN_CODE_LINES
                and is_separator and BANNER_RUN.search(text)):
            add("W-BANNER", unit["line"],
                "section banner in a %d-line file - there is nothing to navigate." % code_line_count)

    # --- restatement ------------------------------------------------------
    for unit in comments:
        if unit["block"] or unit["trailing"]:
            continue
        words = content_words(unit["text"])
        if len(words) < 2:
            continue

        target = -1
        for i in range(unit["line"], len(code_lines)):
            if code_lines[i].strip():
                target = i
                break
        if target == -1:
            continue

        in_code = identifier_words(code_lines[target])
        matched = len([word for word in words if word in in_code])
        if matched / len(words) >= 0.6:
            add("E-RESTATE", unit["line"],
                '"%s" repeats line %d. Delete it, or say why the line is there.'
                % (unit["text"][:48], target + 1))

    if code_line_count >= MIN_LINES_FOR_RATIO and comment_line_count / code_line_count > MAX_COMMENT_RATIO:
        add("W-DENSITY", 1,
            "%d comment lines to %d of code (%d%%, cap %d%%)."
            % (comment_line_count, code_line_count,
               round(comment_line_count / code_line_count * 100), MAX_COMMENT_RATIO * 100))

    # --- clauses inside a surviving comment -------------------------------
    for unit in comments:
        if unit["block"] or unit["trailing"] or unit["lines"] < 2:
            continue

        following = []
        for i in range(unit["line"], len(code_lines)):
            if len(following) >= CLAUSE_LOOKAHEAD:
                break
            if code_lines[i].strip():
                following.append(code_lines[i])
        if not following:
            continue
        in_code = identifier_words(" ".join(following))

        for part in unit["parts"]:
            for clause in CLAUSE_SPLIT.split(part["text"]):
                words = content_words(clause)
                if len(words) < MIN_CLAUSE_WORDS:
                    continue
                if CONNECTIVE.search(clause):
                    continue
                matched = len([word for word in words if word in in_code])
                if matched / len(words) < CLAUSE_ECHO_RATIO:
                    continue
                add("E-CLAUSE", part["line"],
                    '"%s" is built from the identifiers below it. Keep the clause that says why; '
                    "the rest is the code spelled twice." % clause.strip()[:52])

    # --- capability checks ------------------------------------------------
    capability_statements = list(CAPABILITY_STATEMENT.finditer(code))
    if len(capability_statements) > MAX_CAPABILITY_STATEMENTS:
        add("E-CAPCHECK", line_of(code, capability_statements[0].start()),
            "%d separate capability checks (cap %d). Bind the functions once and assert once - "
            "see roblox-executor/references/technique/source-to-api.md."
            % (len(capability_statements), MAX_CAPABILITY_STATEMENTS))

    # --- pcall ------------------------------------------------------------
    pcalls = list(PCALL_ANY.finditer(code))
    for match in PCALL_CLOSURE.finditer(code):
        body = match.group(1)
        if FALLIBLE_HINT.search(body):
            continue
        if len(ASSIGNMENT.findall(body)) != 1:
            continue
        calls = [call.group(1) for call in CALL_NAME.finditer(body)]
        if all(INFALLIBLE_CALLS.search(name) for name in calls):
            add("E-PCALL-INFALLIBLE", line_of(code, match.start()),
                "pcall around a property write, which does not raise. It hides a typo instead of a failure.")
    if len(pcalls) >= MIN_PCALLS_FOR_DENSITY and len(pcalls) / code_line_count > MAX_PCALL_PER_CODE_LINE:
        add("W-PCALL-DENSITY", line_of(code, pcalls[0].start()),
            "%d pcalls in %d lines. Wrap the calls that cross a boundary, not every statement."
            % (len(pcalls), code_line_count))

    # --- messages ---------------------------------------------------------
    prefixes = {}
    for call in MESSAGE_CALL.finditer(code):
        kind, args = call.group(1), call.group(2)
        line = line_of(code, call.start())
        for literal in STRING_LITERAL.finditer(args):
            text = literal.group(1) if literal.group(1) is not None else (literal.group(2) or "")
            if len(text) < 4:
                continue

            if kind != "print":
                if word_count(text) > MAX_MESSAGE_WORDS:
                    add("E-ERRPROSE", line,
                        '%s message is %d words (cap %d): "%s"'
                        % (kind, word_count(text), MAX_MESSAGE_WORDS, text[:56]))
                elif TWO_CLAUSES.search(text):
                    add("E-ERRPROSE", line,
                        '%s message has two clauses: "%s". Name the failing value and stop.' % (kind, text[:56]))
                elif PROSE_IN_MESSAGE.search(text):
                    add("E-ERRPROSE", line, '%s message argues with the reader: "%s"' % (kind, text[:56]))

            if DECORATION.search(text):
                add("W-EMOJI", line, '%s message carries decoration: "%s"' % (kind, text[:40]))

            if kind == "print" and SUCCESS_NARRATION.search(text):
                add("W-SUCCESSPRINT", line,
                    'print narrates success: "%s". Shipped code is quiet when it works.' % text[:48])

            prefix = MESSAGE_PREFIX.match(text)
            if prefix:
                key = prefix.group(1).strip()
                prefixes[key] = prefixes.get(key, 0) + 1

    for prefix, count in prefixes.items():
        if count > MAX_REPEATED_PREFIX:
            add("E-PREFIX", 1,
                '"%s" is typed into %d messages. Declare it once as a constant and concatenate.'
                % (prefix, count))

    # --- naming -----------------------------------------------------------
    for declaration in LOCAL_DECLARATION.finditer(code):
        rhs = declaration.group(3) or ""
        line = line_of(code, declaration.start())
        for name in (declaration.group(1), declaration.group(2)):
            if not name:
                continue
            lower = name.lower()
            if PCALL_RHS.search(rhs) and PCALL_IDIOM.match(name):
                continue
            if lower in GENERIC_LOCALS:
                add("W-GENERIC", line,
                    '"%s" would fit in any project. Name it from the game\'s vocabulary.' % name)
            elif lower in BAD_ABBREVIATIONS:
                add("W-ABBREV", line, '"%s" is an abbreviation. Spell the word out.' % name)
            elif DIGIT_SUFFIX.search(name) and not name[0].isupper():
                add("W-NUMSUFFIX", line,
                    '"%s" ends in a digit - name the difference instead of numbering it.' % name)

    # --- decompiler placeholders ------------------------------------------
    declared = []
    for match in LOCAL_NAMES.finditer(code):
        line = line_of(code, match.start())
        rest = [name.strip() for name in (match.group(2) or "").split(",") if name.strip()]
        for name in [match.group(1)] + rest:
            declared.append((name, line))
    for match in FUNCTION_PARAMETERS.finditer(code):
        line = line_of(code, match.start())
        for name in match.group(1).split(","):
            name = name.strip()
            if re.match(r"^[A-Za-z_][\w]*$", name, re.ASCII):
                declared.append((name, line))
    for name, line in declared:
        if not DECOMPILER_NAME.match(name):
            continue
        add("E-DECOMPNAME", line,
            '"%s" is a decompiler slot number, not a name. Rename it from what the source proved '
            "it holds, or say the source did not establish it." % name)

    # --- how many places this script reaches into -------------------------
    layers_touched = {}
    for layer, pattern in VALUE_LAYERS:
        match = pattern.search(code)
        if match:
            layers_touched[layer] = line_of(code, match.start())

    for expression in OR_LINE.finditer(code):
        text = expression.group(0)
        present = [layer for layer, pattern in VALUE_LAYERS if pattern.search(text)]
        if len(present) < 2:
            continue
        add("E-LAYERCHAIN", line_of(code, expression.start()),
            "fallback between the %s layers in one expression. They reach different objects - "
            "pick the layer the source proved and assert on it." % " and ".join(present))

    if len(layers_touched) > MAX_VALUE_LAYERS:
        add("E-LAYERCHAIN", min(layers_touched.values()),
            "%d value layers in one file (%s, cap %d). Read the dump again and decide which one "
            "holds the value." % (len(layers_touched), ", ".join(layers_touched.keys()), MAX_VALUE_LAYERS))

    executor_globals = set(match.group(0) for match in EXECUTOR_GLOBALS.finditer(code))
    surface = len(executor_globals)
    for alias in EXECUTOR_ALIASES:
        used = [name for name in executor_globals if name.lower() in alias]
        if len(used) > 1:
            surface -= len(used) - 1
    if surface > MAX_EXECUTOR_SURFACE:
        add("W-EXECSURFACE", 1,
            "%d distinct executor functions (cap %d). A single-purpose script that needs this many "
            "usually never found the right layer." % (surface, MAX_EXECUTOR_SURFACE))

    # --- unnamed repeated values ------------------------------------------
    literals = {}
    stripped = STRINGS_TO_BLANK.sub('""', code)
    for match in NUMBER_LITERAL.finditer(stripped):
        value = match.group(1)
        if value in CANONICAL_FRACTIONS:
            continue
        literals.setdefault(value, []).append(line_of(stripped, match.start()))
    for value, lines in literals.items():
        if len(lines) >= 3:
            add("W-MAGIC", lines[0],
                "%s appears %d times (lines %s). Give it a name once."
                % (value, len(lines), ", ".join(str(line) for line in lines[:4])))

    counts = {
        "codeLines": code_line_count,
        "commentLines": comment_line_count,
        "headerLines": header_lines,
        "capabilityStatements": len(capability_statements),
        "pcalls": len(pcalls),
        "labels": label_count,
        "valueLayers": sorted(layers_touched.keys()),
        "executorSurface": surface,
        "isModule": is_module,
    }
    return findings, counts


def score(findings):
    codes = set(finding["code"] for finding in findings)

    def none(*wanted):
        return not codes.intersection(wanted)

    rows = [
        ("header", none("E-HEADER")),
        ("provenance and edit narration", none("E-PROVENANCE", "E-EDITNOTE")),
        ("header carries facts, not a summary", none("E-HEADERSUMMARY", "E-FILENAME")),
        ("commented-out code", none("E-QUOTE")),
        ("restatement", none("E-RESTATE", "W-LABEL", "E-CLAUSE")),
        ("capability checks", none("E-CAPCHECK")),
        ("pcall discipline", none("E-PCALL-INFALLIBLE", "W-PCALL-DENSITY")),
        ("message wording", none("E-ERRPROSE", "W-EMOJI")),
        ("repeated prefix", none("E-PREFIX")),
        ("naming", none("W-GENERIC", "W-ABBREV", "W-NUMSUFFIX", "E-DECOMPNAME")),
        ("noise", none("W-SUCCESSPRINT", "W-MAGIC", "W-BANNER", "W-DENSITY", "E-TODO")),
        ("one API per job", none("E-LAYERCHAIN", "W-EXECSURFACE")),
    ]
    passed = len([row for row in rows if row[1]])
    return {"rows": rows, "points": passed * 2, "total": len(rows) * 2}


# --------------------------------------------------------------------------
# Reporting


def collect(target, out):
    if os.path.isdir(target):
        for entry in sorted(os.listdir(target)):
            collect(os.path.join(target, entry), out)
    elif target.lower().endswith((".luau", ".lua")):
        out.append(target)
    return out


def read_source(path):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def compare(before_file, after_file):
    def read(path):
        if not os.path.exists(path):
            sys.stderr.write("no such path: %s\n" % path)
            sys.exit(2)
        source = read_source(path)
        findings, counts = analyse(source, path)
        return {
            "findings": findings,
            "counts": counts,
            "score": score(findings),
            "lines": len(source.split("\n")),
        }

    before = read(before_file)
    after = read(after_file)

    def key(finding):
        return "%s:%s" % (finding["code"], finding["message"])

    before_keys = set(key(finding) for finding in before["findings"])
    after_keys = set(key(finding) for finding in after["findings"])
    resolved = [finding for finding in before["findings"] if key(finding) not in after_keys]
    introduced = [finding for finding in after["findings"] if key(finding) not in before_keys]
    carried = [finding for finding in before["findings"] if key(finding) in after_keys]

    rows = [
        ("score", "%d/%d" % (before["score"]["points"], before["score"]["total"]),
         "%d/%d" % (after["score"]["points"], after["score"]["total"])),
        ("lines", before["lines"], after["lines"]),
        ("code lines", before["counts"]["codeLines"], after["counts"]["codeLines"]),
        ("comment lines", before["counts"]["commentLines"], after["counts"]["commentLines"]),
        ("header lines", before["counts"]["headerLines"], after["counts"]["headerLines"]),
        ("capability checks", before["counts"]["capabilityStatements"], after["counts"]["capabilityStatements"]),
        ("pcalls", before["counts"]["pcalls"], after["counts"]["pcalls"]),
        ("value layers", "/".join(before["counts"]["valueLayers"]) or "none",
         "/".join(after["counts"]["valueLayers"]) or "none"),
        ("executor surface", before["counts"]["executorSurface"], after["counts"]["executorSurface"]),
    ]

    print("\n%s -> %s\n" % (before_file, after_file))
    width = max(len(row[0]) for row in rows)
    moved = 0
    for name, source_value, target_value in rows:
        same = str(source_value) == str(target_value)
        if not same:
            moved += 1
        print("  %s  %9s -> %-9s %s" % (name.ljust(width), source_value, target_value,
                                        "unchanged" if same else ""))

    print("\n  resolved   %d" % len(resolved))
    for finding in resolved[:12]:
        print("    - %s  %s" % (finding["code"], finding["message"][:88]))
    print("  introduced %d" % len(introduced))
    for finding in introduced[:12]:
        print("    + %s  %s" % (finding["code"], finding["message"][:88]))
    print("  still there %d" % len(carried))
    for finding in carried[:12]:
        print("    = %s  %s" % (finding["code"], finding["message"][:88]))

    if moved == 0:
        verdict = "Nothing measurable changed - do not report this as a rewrite."
    else:
        verdict = "%d finding(s) resolved, %d introduced." % (len(resolved), len(introduced))
    print("\n  %d/%d counted rows moved. %s" % (moved, len(rows), verdict))

    return 1 if any(f["code"].startswith("E-") for f in after["findings"]) else 0


def main(argv):
    args = argv[1:]
    as_json = "--json" in args
    use_stdin = "--stdin" in args
    targets = [arg for arg in args if not arg.startswith("--")]

    if "--compare" in args:
        if len(targets) != 2:
            sys.stderr.write("usage: python roblox_lint.py --compare <before.luau> <after.luau>\n")
            return 2
        return compare(targets[0], targets[1])

    results = []
    if use_stdin:
        findings, counts = analyse(sys.stdin.read(), "<stdin>")
        results.append({"file": "<stdin>", "findings": findings, "counts": counts,
                        "score": score(findings)})
    else:
        if not targets:
            sys.stderr.write(
                "usage: python roblox_lint.py <file.luau|directory> [...]\n"
                "       python roblox_lint.py --stdin\n"
                "       python roblox_lint.py --compare <before.luau> <after.luau>\n"
                "Counts the rules in roblox-code-craft/references/anti-slop-code.md.\n")
            return 2

        files = []
        for target in targets:
            if not os.path.exists(target):
                sys.stderr.write("no such path: %s\n" % target)
                return 2
            collect(target, files)

        for path in files:
            rel = path.replace("\\", "/")
            findings, counts = analyse(read_source(path), rel)
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
            print("  score %d/%d%s" % (
                result["score"]["points"], result["score"]["total"],
                ("  failing: " + ", ".join(failed)) if failed else "  all counted checks pass"))

    errors = [f for result in results for f in result["findings"] if f["code"].startswith("E-")]
    warnings = [f for result in results for f in result["findings"] if f["code"].startswith("W-")]
    if not as_json:
        print("\n%d file(s) - %d error(s), %d warning(s)" % (len(results), len(errors), len(warnings)))

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
