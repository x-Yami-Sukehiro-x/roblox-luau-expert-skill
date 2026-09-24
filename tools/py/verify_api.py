#!/usr/bin/env python3
"""Check Roblox and executor names against the vendored ground truth, offline.

tools/bin/verify-api.mjs is the authority, and it parses the full API dump. It
needs Node, which a custom GPT's Code Interpreter does not have, so a GPT was
told to verify every API and given no way to do it. This reads the generated
flat indexes instead - plain text files that ship in the same archive - so the
check survives being run in a Python sandbox with no network.

    python verify_api.py Humanoid.WalkSpeed     exists, deprecated, reachable
    python verify_api.py WalkSpeed              which classes declare it
    python verify_api.py Enum.EasingStyle.Quad  is that enum item real
    python verify_api.py --exec hookmetamethod  is that executor function documented
    python verify_api.py --scan Script.luau     every name this file establishes

Exit 1 when a name is absent, 2 when the indexes cannot be found.
"""

import os
import re
import sys

# A repository or an unpacked archive keeps the skills under .claude/skills; the
# OpenAI plugin keeps them under skills/. Either layout is accepted.
SKILL_LAYOUTS = (os.path.join(".claude", "skills"), "skills")
VERIFIED_TAIL = os.path.join("roblox-luau-expert", "references", "verified")
EXECUTOR_TAIL = os.path.join("roblox-executor", "references", "api")
VERIFIED = os.path.join(SKILL_LAYOUTS[0], VERIFIED_TAIL)
EXECUTOR_API = os.path.join(SKILL_LAYOUTS[0], EXECUTOR_TAIL)


def skills_dir(root):
    for layout in SKILL_LAYOUTS:
        if os.path.isdir(os.path.join(root, layout, VERIFIED_TAIL)):
            return os.path.join(root, layout)
    return None

USAGE = __doc__


def find_root():
    """The repository root, from the script, the CWD, or anywhere beneath one.

    A GPT unzips the archive into a directory it chose, so a fixed relative
    path is wrong more often than right. Walking up finds a normal checkout;
    walking down finds an unpacked archive.
    """
    probes = [os.path.dirname(os.path.abspath(__file__)), os.getcwd()]
    for probe in probes:
        current = probe
        for _ in range(6):
            if skills_dir(current):
                return current
            parent = os.path.dirname(current)
            if parent == current:
                break
            current = parent

    for base in probes:
        for root, dirs, _ in os.walk(base):
            dirs[:] = [name for name in dirs if name not in (".git", "node_modules")]
            if skills_dir(root):
                return root
            if root.count(os.sep) - base.count(os.sep) > 4:
                dirs[:] = []
    return None


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def lines_of(path):
    if not os.path.exists(path):
        return []
    return read(path).replace("\r\n", "\n").split("\n")


def load(root):
    verified = os.path.join(skills_dir(root), VERIFIED_TAIL)

    api = set()
    members = {}
    for line in lines_of(os.path.join(verified, "api-index.txt")):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        api.add(line)
        if "." in line:
            owner, member = line.split(".", 1)
            members.setdefault(member, []).append(owner)

    datatypes = set()
    for line in lines_of(os.path.join(verified, "datatype-index.txt")):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        datatypes.add(line)
        match = re.match(r"^([A-Za-z_]\w*)[.:](\w+)$", line)
        if match:
            members.setdefault(match.group(2), []).append(match.group(1))

    deprecated = {}
    current_class = None
    for line in lines_of(os.path.join(verified, "deprecated-apis.md")):
        heading = re.match(r"^##\s+(\w+)\s*$", line)
        if heading:
            current_class = heading.group(1)
            continue
        row = re.match(r"^\|\s*`([^`]+)`\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|", line)
        if row and current_class:
            deprecated["%s.%s" % (current_class, row.group(1))] = (row.group(2), row.group(3))

    security = {}
    for line in lines_of(os.path.join(verified, "security-tagged-apis.md")):
        row = re.match(r"^\|\s*`([\w.]+)`\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|", line)
        if row:
            security[row.group(1)] = (row.group(2), row.group(3))

    enums = set()
    for line in lines_of(os.path.join(verified, "enum-index.txt")):
        line = line.strip()
        if line and not line.startswith("#"):
            enums.add(line)

    superclass = {}
    for line in lines_of(os.path.join(verified, "class-hierarchy.txt")):
        match = re.match(r"^(\w+)\s*:\s*(\S+)$", line.strip())
        if match:
            superclass[match.group(1)] = None if match.group(2) == "-" else match.group(2)

    return {"api": api, "members": members, "datatypes": datatypes,
            "deprecated": deprecated, "security": security,
            "enums": enums, "superclass": superclass}


def load_executor(root):
    directory = os.path.join(skills_dir(root), EXECUTOR_TAIL)
    names = {}
    if not os.path.isdir(directory):
        return names
    for entry in sorted(os.listdir(directory)):
        if not entry.endswith(".md"):
            continue
        for number, line in enumerate(lines_of(os.path.join(directory, entry)), 1):
            heading = re.match(r"^##+\s+`?([A-Za-z_][\w.]*)`?\s*$", line)
            if heading:
                names.setdefault(heading.group(1), (entry, number))
                continue
            if re.match(r"^\s*function\s", line):
                for call in re.finditer(r"([A-Za-z_][\w.]*)\s*\(", line):
                    if call.group(1) != "function":
                        names.setdefault(call.group(1), (entry, number))
    return names


def declares(index, class_name, member):
    """Does `class_name`, or anything it inherits from, declare `member`?

    api-index.txt lists a member against the class that declares it, so
    `Workspace.Raycast` is absent from it and `WorldRoot.Raycast` is not.
    Grepping one line without walking the chain reports a real API as invented.
    """
    seen = set()
    current = class_name
    while current and current not in seen:
        seen.add(current)
        if "%s.%s" % (current, member) in index["api"]:
            return current
        current = index["superclass"].get(current)
    return None


def report_enum(index, name):
    if not index["enums"]:
        print("UNCHECKED  %s - enum-index.txt is missing from this copy." % name)
        return 1
    if name in index["enums"]:
        print("EXISTS  %s" % name)
        return 0
    parts = name.split(".")
    family = "Enum.%s." % parts[1] if len(parts) > 2 else None
    siblings = sorted(item.split(".")[2] for item in index["enums"]
                      if family and item.startswith(family))
    print("ABSENT  %s" % name)
    if siblings:
        print("        Enum.%s exists and has: %s" % (parts[1], ", ".join(siblings[:12])))
    else:
        print("        There is no Enum.%s in the dump." % (parts[1] if len(parts) > 1 else name))
    return 1


def report_one(index, name):
    if name.startswith("Enum."):
        return report_enum(index, name)

    if "." in name or ":" in name:
        normalised = name.replace(":", ".")
        owner, member = normalised.split(".", 1)

        declared_on = declares(index, owner, member) if owner in index["superclass"] else None
        exists = declared_on is not None or normalised in index["api"]
        if not exists:
            exists = normalised in index["datatypes"] or name.replace(".", ":") in index["datatypes"]

        if not exists:
            print("ABSENT  %s" % name)
            print("        Not in the dump, the datatype index, or any ancestor of %s." % owner)
            print("        It does not exist - say so rather than writing it with a hedge.")
            near = index["members"].get(member, [])
            if near:
                print("        A member by that name is declared on: %s" % ", ".join(sorted(near)[:8]))
            return 1

        print("EXISTS  %s" % name)
        if declared_on and declared_on != owner:
            print("        Declared on %s; %s inherits it." % (declared_on, owner))
        lookup = "%s.%s" % (declared_on or owner, member)
        deprecated = index["deprecated"].get(lookup) or index["deprecated"].get(normalised)
        if deprecated:
            replacement = deprecated[1] or "no direct successor in the dump"
            print("        DEPRECATED (%s) - replacement: %s" % (deprecated[0] or "member", replacement))
        gate = index["security"].get(lookup) or index["security"].get(normalised)
        if gate:
            print("        SECURITY %s (%s) - a Script or LocalScript cannot reach this." % gate)
        if not deprecated and not gate:
            print("        Not deprecated, no security tag.")
        return 0

    owners = index["members"].get(name, [])
    if not owners:
        print("ABSENT  no class or datatype declares a member named %s" % name)
        return 1
    print("EXISTS  %s is declared on %d type(s): %s"
          % (name, len(owners), ", ".join(sorted(owners)[:12])))
    if len(owners) > 12:
        print("        ... and %d more. Qualify it as Class.%s to check one." % (len(owners) - 12, name))
    return 0


SERVICE_BINDING = re.compile(
    r"""\blocal\s+([A-Za-z_]\w*)\s*(?::\s*\w+\s*)?=\s*game\s*:\s*GetService\s*\(\s*["']([A-Za-z_]\w*)["']""",
    re.ASCII)
INSTANCE_BINDING = re.compile(
    r"""\blocal\s+([A-Za-z_]\w*)\s*(?::\s*\w+\s*)?=\s*Instance\s*\.\s*new\s*\(\s*["']([A-Za-z_]\w*)["']""",
    re.ASCII)
ANNOTATED_BINDING = re.compile(r"\blocal\s+([A-Za-z_]\w*)\s*:\s*([A-Z]\w*)\s*[=\r\n]", re.ASCII)
# Any `name: ClassName` anywhere, including a field inside a `type` table. Used
# only to disqualify: Toast.luau has `local frame = Instance.new("Frame")` in
# one function and a `frame: CanvasGroup` type field for another, and reading
# GroupTransparency off the Frame binding is the false positive that follows.
# The lookahead keeps `function s:Fire(...)` out: a method definition is not a
# claim that `s` is a Fire instance, and Fire is a real Roblox class.
TYPE_FIELD = re.compile(r"\b([A-Za-z_]\w*)\s*:\s*([A-Z]\w*)\b(?!\s*\()", re.ASCII)
ENUM_USE = re.compile(r"\bEnum\.([A-Za-z_]\w*)\.([A-Za-z_]\w*)", re.ASCII)


def resolve_receivers(index, source, blanked):
    """Locals this file binds to exactly one class the dump knows about.

    One name bound twice is a shadow, and without scope analysis there is no
    way to tell which binding a given line means. Dropping it is the honest
    answer: an unchecked name is a gap, a wrongly-checked one is a false
    accusation that costs the reader more than the gap does.
    """
    candidates = {"workspace": {"Workspace"}, "Workspace": {"Workspace"}}
    for pattern, text in ((SERVICE_BINDING, source), (INSTANCE_BINDING, source),
                          (ANNOTATED_BINDING, blanked), (TYPE_FIELD, blanked)):
        for match in pattern.finditer(text):
            if match.group(2) in index["superclass"]:
                candidates.setdefault(match.group(1), set()).add(match.group(2))
    return {name: next(iter(classes)) for name, classes in candidates.items() if len(classes) == 1}


def member_uses(receiver):
    """`name.Property` and `name:Method(`, and neither `a.name.x` nor `name: Type`.

    The colon arm requires the call parenthesis because `local frame: Frame` and
    `{ frame: CanvasGroup }` are type annotations, not member access. The
    look-behind is what stops `Tokens.stroke.base` from reading as a member of
    the UIStroke named `stroke`.
    """
    return re.compile(
        r"(?<![.:\w])%s\s*(?:\.\s*([A-Za-z_]\w*)|:\s*([A-Za-z_]\w*)\s*\()" % re.escape(receiver),
        re.ASCII)


def scan(index, path):
    """Check the names whose owning class this file actually establishes.

    Deliberately narrow. An earlier version flagged every dotted name and
    reported `toast.gap` and `Enum.HorizontalAlignment.Center` as unverified
    APIs. That is the failure this repository's linters are calibrated against:
    a gate that reports what the author already handled teaches you to stop
    reading it. What survives is the decidable subset - a receiver bound to a
    known class, and an enum item - and the report says what it did not check.
    """
    source = read(path)
    # Blank the comments, keep their newlines: dropping them shifts every line
    # number below, and a finding that points at the wrong line is a finding
    # nobody trusts.
    source = re.sub(r"--\[(=*)\[[\s\S]*?\]\1\]",
                    lambda match: "\n" * match.group(0).count("\n"), source)
    source = re.sub(r"--[^\n]*", "", source)
    # Two views. Binding resolution reads `Instance.new("Part")`, so it needs the
    # string literals; everything else must not, because
    # `error("Toast: PlayerGui never appeared")` is prose, not a type annotation.
    blanked = re.sub(r"\"(?:[^\"\\\n]|\\.)*\"|'(?:[^'\\\n]|\\.)*'", '""', source)

    bound = resolve_receivers(index, source, blanked)
    source = blanked
    findings = []

    for receiver, class_name in sorted(bound.items()):
        for match in member_uses(receiver).finditer(source):
            member = match.group(1) or match.group(2)
            if declares(index, class_name, member):
                continue
            line = source.count("\n", 0, match.start()) + 1
            findings.append((line, "%s.%s" % (receiver, member),
                             "%s declares no %s, on itself or any ancestor" % (class_name, member)))

    for match in ENUM_USE.finditer(source):
        qualified = "Enum.%s.%s" % (match.group(1), match.group(2))
        if not index["enums"] or qualified in index["enums"]:
            continue
        line = source.count("\n", 0, match.start()) + 1
        family = "Enum.%s." % match.group(1)
        siblings = sorted(item.split(".")[2] for item in index["enums"] if item.startswith(family))
        hint = ("Enum.%s has: %s" % (match.group(1), ", ".join(siblings[:8]))) \
            if siblings else "there is no Enum.%s" % match.group(1)
        findings.append((line, qualified, hint))

    print("%s" % path)
    print("  receivers resolved: %s" % ", ".join(
        "%s=%s" % (name, class_name) for name, class_name in sorted(bound.items())))

    if not findings:
        print("  every resolved member and every enum item is in the dump.")
        print("  Members on receivers this file does not bind to a class are not checked here.")
        return 0

    for line, name, message in sorted(findings):
        print("  INVENTED  line %d  %s - %s" % (line, name, message))
    print("\n  %d name(s) do not exist. Fix them; do not ship them with a hedge." % len(findings))
    return 1


def main(argv):
    args = argv[1:]
    if not args:
        sys.stderr.write(USAGE)
        return 2

    root = find_root()
    if root is None:
        sys.stderr.write(
            "could not find %s from here.\n"
            "Unpack roblox-luau-expert-skill.zip first, or run this from inside the repo.\n"
            % VERIFIED.replace(os.sep, "/"))
        return 2

    index = load(root)

    if args[0] == "--exec":
        if len(args) < 2:
            sys.stderr.write("usage: python verify_api.py --exec <name>\n")
            return 2
        executor = load_executor(root)
        name = args[1]
        record = executor.get(name)
        if record is None:
            print("ABSENT  %s is not in %s" % (name, EXECUTOR_API.replace(os.sep, "/")))
            print("        The API dump has no executor functions either, so a miss from")
            print("        verify-api.mjs proves nothing here. Report it missing.")
            return 1
        print("DOCUMENTED  %s  (%s:%d)" % (name, record[0], record[1]))
        print("            Feature-detect it anyway: availability varies per executor.")
        return 0

    if args[0] == "--scan":
        if len(args) < 2:
            sys.stderr.write("usage: python verify_api.py --scan <file.luau>\n")
            return 2
        if not os.path.exists(args[1]):
            sys.stderr.write("no such path: %s\n" % args[1])
            return 2
        return scan(index, args[1])

    status = 0
    for name in args:
        if report_one(index, name):
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv))
