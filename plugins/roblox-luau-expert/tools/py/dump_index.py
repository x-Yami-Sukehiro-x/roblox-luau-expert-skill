"""Index a decompiled Roblox dump and search it for the code behind a feature.

    python tools/py/dump_index.py <dump file or folder> --summary
    python tools/py/dump_index.py <dump> --feature "auto farm"
    python tools/py/dump_index.py <dump> --feature "speed" --terms stamina,dash
    python tools/py/dump_index.py <dump> --feature "fly" --json
    python tools/py/dump_index.py <dump> --inventory

A dump is any mix of .lua, .luau and .txt files, a folder of them, or a
saveinstance .rbxlx / .rbxmx (script sources are read out of the XML).

Feature mode ranks every place the feature's words appear by what kind of code
they are in - a remote call site outranks a function name, which outranks a
stray string - and ends with a verdict:

    FOUND      a remote call site, function, attribute or tag names the feature
    PARTIAL    only strings or identifiers mention it; the mechanism is not shown
    NOT FOUND  nothing in the dump mentions it

Only FOUND is enough to build against. For the other two the output prints the
KEYWORDS line for roblox-executor/assets/runtime-probe.luau, which collects the
missing evidence from the live game instead of guessing names.

Fly, noclip, speed, jump, ESP, teleport and aim are engine routes: they are built
on the player's own character or camera, so their absence from the dump is
expected and the output names the engine members to build on instead.

Inventory mode answers "what could a script for this game do?". It lists only
what the dump shows: the remotes the client already fires and where, the
prompts, clicks and touches it listens to, the tunable numbers in client code,
the tags and attributes it reads, and the engine features that need no game
code. Every suggestion made from it cites a line it printed.

Exit 0 FOUND, --summary or --inventory, 3 PARTIAL, 4 NOT FOUND, 2 nothing readable.
"""

import json
import os
import re
import sys
from xml.sax.saxutils import unescape

TEXT_EXTENSIONS = (".lua", ".luau", ".txt")
XML_EXTENSIONS = (".rbxlx", ".rbxmx")

# Words that say nothing about which code implements a feature.
STOPWORDS = {
    "a", "an", "the", "my", "me", "i", "to", "for", "of", "and", "or", "in", "on",
    "with", "script", "feature", "make", "toggle", "button", "gui", "ui", "hub",
    "auto", "infinite", "inf", "give", "get", "set", "all", "player", "please",
}

# A request names the result; the dump names the mechanism. Each entry widens a
# user's word into the words game code tends to use for the same thing.
SYNONYMS = {
    "farm": ["farm", "collect", "harvest", "pickup", "gather", "coin", "cash", "orb", "drop",
             "reward", "claim", "loot", "chest", "sell", "deposit"],
    "coin": ["coin", "cash", "money", "currency", "gold", "gem", "orb", "collect"],
    "money": ["money", "cash", "coin", "currency", "gold", "gem", "balance"],
    "speed": ["speed", "walkspeed", "sprint", "run", "stamina", "dash", "velocity"],
    "sprint": ["sprint", "run", "stamina", "walkspeed", "speed", "dash"],
    "jump": ["jump", "jumppower", "jumpheight", "gravity", "doublejump"],
    "fly": ["fly", "flight", "flying", "noclip", "hover", "linearvelocity", "bodyvelocity"],
    "esp": ["esp", "highlight", "billboard", "nametag", "tracer", "chams"],
    "aim": ["aim", "aimbot", "target", "lockon", "camera", "raycast", "hitpart", "shoot"],
    "aimbot": ["aim", "target", "lockon", "camera", "raycast", "hitpart", "shoot"],
    "teleport": ["teleport", "tp", "pivotto", "cframe", "waypoint", "zone", "area", "spawn"],
    "damage": ["damage", "hit", "attack", "swing", "weapon", "combat", "kill", "hurt"],
    "kill": ["kill", "damage", "attack", "hit", "combat", "hurt"],
    "god": ["god", "health", "takedamage", "invincible", "immune", "damage"],
    "cooldown": ["cooldown", "debounce", "reload", "delay", "clock", "tick"],
    "ammo": ["ammo", "reload", "magazine", "bullet", "clip"],
    "buy": ["buy", "purchase", "shop", "store", "price", "cost", "product"],
    "egg": ["egg", "hatch", "pet", "roll", "gacha", "open"],
    "pet": ["pet", "egg", "hatch", "equip", "follow"],
    "rebirth": ["rebirth", "prestige", "ascend", "reset"],
    "quest": ["quest", "mission", "objective", "task"],
    "fish": ["fish", "rod", "cast", "reel", "bait", "catch"],
    "mine": ["mine", "ore", "pickaxe", "rock", "dig"],
    "chest": ["chest", "claim", "reward", "loot", "open"],
    "sell": ["sell", "deposit", "trade", "shop"],
}

# Features built on engine members of the player's own character or camera. For
# these, missing game code is expected: the dump is read for what resets or
# detects the change, and the probe is only for a reset seen in play.
ENGINE_ROUTE = {
    "fly": "LinearVelocity or AlignPosition on your own HumanoidRootPart",
    "noclip": "BasePart.CanCollide on your own character's parts",
    "speed": "Humanoid.WalkSpeed on your own character",
    "walkspeed": "Humanoid.WalkSpeed on your own character",
    "jump": "Humanoid.JumpPower or JumpHeight on your own character",
    "esp": "Highlight instances or Drawing objects over other characters",
    "teleport": "PVInstance:PivotTo on your own character",
    "tp": "PVInstance:PivotTo on your own character",
    "aim": "Camera.CFrame and Workspace:Raycast",
    "aimbot": "Camera.CFrame and Workspace:Raycast",
}

# Service and engine names that would match everything if left in.
ENGINE_NOISE = {
    "runservice", "userinputservice", "tweenservice", "replicatedstorage", "replicatedfirst",
    "serverscriptservice", "serverstorage", "startergui", "starterplayer", "httpservice",
    "contextactionservice", "collectionservice", "guiservice", "soundservice", "textservice",
}

WEIGHTS = {
    "remote": 6,
    "instance": 5,
    "function": 4,
    "attribute": 4,
    "tag": 4,
    "label": 3,
    "string": 2,
    "identifier": 1,
}
DECISIVE = {"remote", "function", "attribute", "tag", "instance"}

FAILED_REGION = re.compile(r"DECOMPILER ERROR|Failed to decompile|failed to decompile|Luau bytecode|-- Unsupported")
PATH_HEADER = re.compile(r"--\s*(?:Script Path|Path|Name)\s*:\s*(.+)")
STRING = re.compile(r'"((?:[^"\\\n]|\\.)*)"|\'((?:[^\'\\\n]|\\.)*)\'')
REMOTE_CALL = re.compile(r"([\w.:\[\]\"'()]+?)\s*:\s*(FireServer|InvokeServer)\s*\(")
REMOTE_LISTEN = re.compile(r"([\w.:\[\]\"'()]+?)\.(OnClientEvent|OnClientInvoke)\b")
CHILD_NAME = re.compile(r":\s*(?:WaitForChild|FindFirstChild|FindFirstChildOfClass|FindFirstChildWhichIsA)\s*\(\s*[\"']([^\"']+)[\"']")
FUNCTION_DEF = re.compile(r"(?:local\s+)?function\s+([\w.:]+)\s*\(|([\w.]+)\s*=\s*function\s*\(|\[\s*[\"']([\w ]+)[\"']\s*\]\s*=\s*function\s*\(")
ATTRIBUTE = re.compile(r"(?:GetAttribute|SetAttribute|GetAttributeChangedSignal)\s*\(\s*[\"']([^\"']+)[\"']")
TAG = re.compile(r"(?:GetTagged|HasTag|AddTag|RemoveTag|GetInstanceAddedSignal|GetInstanceRemovedSignal)\s*\(\s*(?:[^,()]+,\s*)?[\"']([^\"']+)[\"']")
REQUIRE = re.compile(r"\brequire\s*\(([^()]*(?:\([^()]*\))?[^()]*)\)")
LABEL = re.compile(r"\.(?:Text|Name|PlaceholderText|Title)\s*=\s*[\"']([^\"']+)[\"']")
MECHANISM = re.compile(r"\.(Touched|Triggered|MouseClick|Activated|Heartbeat|RenderStepped|Stepped|PreRender|CharacterAdded|ChildAdded)\b")
TOKEN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
ASSIGNMENT = re.compile(r"^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*(.+)$")
TUNABLE = re.compile(
    r"\b([A-Za-z_]\w*?(?:Cooldown|Delay|Speed|Range|Damage|Radius|Distance|Duration|Interval|Multiplier|Chance|Reach|Rate))"
    r"\s*=\s*(-?\d+(?:\.\d+)?)\b", re.IGNORECASE)

# Path words that name where a remote lives, not what it does.
REMOTE_NOISE = {
    "game", "workspace", "script", "parent", "replicatedstorage", "getservice", "waitforchild",
    "findfirstchild", "remotes", "remote", "events", "event", "network", "networking", "remoteevent",
    "remotefunction", "functions", "shared", "modules", "packages", "net", "comm", "fireserver",
    "invokeserver",
}


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def scripts_from_xml(path, text):
    """Script sources inside a saveinstance XML, named by class and Name."""
    found = []
    for match in re.finditer(r'<Item class="(LocalScript|ModuleScript|Script)"[^>]*>', text):
        start = match.end()
        stop = text.find("<Item ", start)
        body = text[start:stop if stop != -1 else len(text)]
        name = re.search(r'<string name="Name">([^<]*)</string>', body)
        source = re.search(r'<ProtectedString name="Source">(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</ProtectedString>', body)
        if not source:
            continue
        label = "%s:%s (%s)" % (os.path.basename(path), unescape(name.group(1)) if name else "?", match.group(1))
        found.append((label, unescape(source.group(1))))
    return found


def load(target):
    units = []
    paths = []
    if os.path.isdir(target):
        for root, dirs, files in os.walk(target):
            dirs[:] = [d for d in dirs if d not in (".git", "node_modules")]
            for name in sorted(files):
                paths.append(os.path.join(root, name))
    elif os.path.isfile(target):
        paths.append(target)
    for path in paths:
        lower = path.lower()
        if lower.endswith(XML_EXTENSIONS):
            units.extend(scripts_from_xml(path, read(path)))
        elif lower.endswith(TEXT_EXTENSIONS):
            text = read(path)
            header = PATH_HEADER.search(text[:400])
            label = os.path.relpath(path, target if os.path.isdir(target) else os.path.dirname(path) or ".")
            if header:
                label = "%s [%s]" % (label, header.group(1).strip())
            units.append((label, text))
    return units


def split_args(text):
    """Top-level arguments of a call whose opening parenthesis starts `text`."""
    depth, current, args, quote = 0, "", [], None
    for char in text:
        if quote:
            current += char
            if char == quote:
                quote = None
            continue
        if char in "\"'":
            quote = char
            current += char
            continue
        if char in "([{":
            depth += 1
            if depth == 1 and char == "(":
                continue
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                if current.strip():
                    args.append(current.strip())
                return args, True
        if depth == 1 and char == ",":
            args.append(current.strip())
            current = ""
            continue
        if depth >= 1:
            current += char
    return args, False


def index_unit(label, text):
    lines = text.split("\n")
    info = {
        "label": label, "lines": len(lines), "failed": 0, "remotes": [], "listeners": [],
        "children": [], "functions": [], "attributes": [], "tags": [], "requires": [],
        "labels": [], "mechanisms": [], "strings": [], "tunables": [], "aliases": {},
    }
    for number, line in enumerate(lines, 1):
        if FAILED_REGION.search(line):
            info["failed"] += 1
        assigned = ASSIGNMENT.match(line)
        if assigned and assigned.group(1) not in info["aliases"]:
            info["aliases"][assigned.group(1)] = assigned.group(2).strip()
        for match in REMOTE_CALL.finditer(line):
            call_text = line[match.end() - 1:] + "\n" + "\n".join(lines[number:number + 6])
            args, closed = split_args(call_text)
            base = re.match(r"[A-Za-z_]\w*", match.group(1))
            source = info["aliases"].get(base.group(0), "") if base else ""
            info["remotes"].append({
                "line": number, "receiver": match.group(1), "method": match.group(2), "source": source,
                "args": args if closed else args + ["..."], "count": len(args) if closed else None,
            })
        for match in REMOTE_LISTEN.finditer(line):
            info["listeners"].append({"line": number, "receiver": match.group(1), "event": match.group(2)})
        for match in CHILD_NAME.finditer(line):
            info["children"].append({"line": number, "name": match.group(1)})
        for match in FUNCTION_DEF.finditer(line):
            name = match.group(1) or match.group(2) or match.group(3)
            info["functions"].append({"line": number, "name": name})
        for match in ATTRIBUTE.finditer(line):
            info["attributes"].append({"line": number, "name": match.group(1)})
        for match in TAG.finditer(line):
            info["tags"].append({"line": number, "name": match.group(1)})
        for match in REQUIRE.finditer(line):
            info["requires"].append({"line": number, "target": match.group(1).strip()})
        for match in LABEL.finditer(line):
            info["labels"].append({"line": number, "text": match.group(1)})
        for match in MECHANISM.finditer(line):
            info["mechanisms"].append({"line": number, "event": match.group(1)})
        for match in TUNABLE.finditer(line):
            info["tunables"].append({"line": number, "name": match.group(1), "value": match.group(2)})
        for match in STRING.finditer(line):
            value = match.group(1) if match.group(1) is not None else match.group(2)
            if value and len(value) <= 80:
                info["strings"].append({"line": number, "text": value})
    return info


def expand_terms(feature, extra):
    words = [w for w in re.split(r"[^a-z0-9]+", feature.lower()) if w and w not in STOPWORDS]
    terms = []
    for word in words + [t.strip().lower() for t in extra if t.strip()]:
        for candidate in [word] + SYNONYMS.get(word, []) + SYNONYMS.get(word.rstrip("s"), []):
            if candidate and candidate not in terms and candidate not in STOPWORDS:
                terms.append(candidate)
    return terms


def camel_tokens(text):
    tokens = []
    for token in TOKEN.findall(text):
        tokens.append(token.lower())
        tokens.extend(part.lower() for part in re.findall(r"[A-Z]?[a-z]+|[A-Z]+(?![a-z])|\d+", token))
    return tokens


def term_hits(text, terms):
    """Terms found in `text`. Short terms must be a whole token; longer ones may
    sit inside a token, so `walkspeed` finds `WalkSpeed` and `tp` stays out of `http`."""
    tokens = [t for t in camel_tokens(text) if t not in ENGINE_NOISE]
    hits = []
    for term in terms:
        if len(term) <= 3:
            if term in tokens:
                hits.append(term)
        elif any(term in token for token in tokens) or term in text.lower():
            hits.append(term)
    return hits


def enclosing_function(functions, line):
    best = None
    for entry in functions:
        if entry["line"] <= line:
            best = entry
    return best["name"] if best else "(top level)"


def search(indexed, units, terms):
    evidence = []
    for info, (label, text) in zip(indexed, units):
        lines = text.split("\n")

        def add(kind, line, detail, words):
            evidence.append({
                "script": label, "line": line, "kind": kind, "detail": detail,
                "terms": sorted(set(words)), "score": WEIGHTS[kind],
                "function": enclosing_function(info["functions"], line),
                "code": lines[line - 1].strip()[:160] if 0 < line <= len(lines) else "",
            })

        for call in info["remotes"]:
            words = term_hits(" ".join([call["receiver"], call["source"]] + call["args"]), terms)
            if words:
                add("remote", call["line"], "%s:%s(%s)" % (call["receiver"], call["method"], ", ".join(call["args"])), words)
        for kind, key, field in (("instance", "children", "name"), ("function", "functions", "name"),
                                 ("attribute", "attributes", "name"), ("tag", "tags", "name"),
                                 ("label", "labels", "text")):
            for entry in info[key]:
                words = term_hits(entry[field], terms)
                if words:
                    add(kind, entry["line"], entry[field], words)
        seen = {(e["line"], e["script"]) for e in evidence}
        for entry in info["strings"]:
            if (entry["line"], label) in seen:
                continue
            words = term_hits(entry["text"], terms)
            if words:
                add("string", entry["line"], entry["text"], words)
        seen = {(e["line"], e["script"]) for e in evidence}
        for number, line in enumerate(lines, 1):
            if (number, label) in seen or line.strip().startswith("--"):
                continue
            words = term_hits(STRING.sub("", line), terms)
            if words:
                add("identifier", number, line.strip()[:80], words)
    evidence.sort(key=lambda e: (-e["score"], e["script"], e["line"]))
    return evidence


def related_remotes(indexed, units, evidence):
    """Remote calls in the same functions as the strongest evidence: what the
    feature's code actually sends to the server."""
    wanted = {(e["script"], e["function"]) for e in evidence if e["kind"] in DECISIVE}
    related = []
    for info, (label, _) in zip(indexed, units):
        for call in info["remotes"]:
            if (label, enclosing_function(info["functions"], call["line"])) in wanted:
                related.append({"script": label, **call})
    return related


def verdict(evidence):
    if any(e["kind"] in DECISIVE for e in evidence):
        return "FOUND"
    return "PARTIAL" if evidence else "NOT FOUND"


# The probe matches substrings and caps each section, so a generic word would
# fill the cap with unrelated closures before the feature's own words are reached.
PROBE_NOISE = {"open", "run", "hit", "tick", "clock", "delay", "reset", "area", "zone", "spawn",
               "target", "camera", "drop", "task", "follow", "store", "cost", "rock", "clip", "cast"}


def keywords_line(terms):
    usable = [t for t in terms if len(t) >= 3 and t not in PROBE_NOISE]
    chosen = [t for t in usable if not any(o != t and o in t for o in usable)][:8]
    return "local KEYWORDS = { %s }" % ", ".join('"%s"' % t for t in chosen)


def summary(indexed):
    totals = {key: sum(len(i[key]) for i in indexed) for key in
              ("remotes", "listeners", "children", "functions", "attributes", "tags", "requires", "labels")}
    print("scripts: %d  lines: %d  failed-to-decompile markers: %d" % (
        len(indexed), sum(i["lines"] for i in indexed), sum(i["failed"] for i in indexed)))
    print("  " + "  ".join("%s %d" % (k, v) for k, v in totals.items()))
    print("\nremote calls (receiver, method, argument count at the call site):")
    for info in indexed:
        for call in info["remotes"]:
            count = call["count"] if call["count"] is not None else "?"
            where = "  = %s" % call["source"][:80] if call["source"] else ""
            print("  %s:%d  %s:%s  %s arg(s)  (%s)%s" % (info["label"], call["line"], call["receiver"],
                                                       call["method"], count, ", ".join(call["args"])[:100], where))
    for key, title in (("attributes", "attributes"), ("tags", "CollectionService tags"),
                       ("requires", "requires")):
        names = sorted({e.get("name") or e.get("target") for i in indexed for e in i[key]})
        if names:
            print("\n%s: %s" % (title, ", ".join(names[:60])))


def remote_name(call):
    """The last meaningful name on the path to a remote: `Remotes:WaitForChild("ClaimReward")`
    is ClaimReward. Decompiler labels such as v14 name nothing."""
    for text in (call["source"], call["receiver"]):
        names = [t for t in TOKEN.findall(text)
                 if t.lower() not in REMOTE_NOISE and not re.fullmatch(r"[vupla]\d+", t)]
        if names:
            return names[-1]
    return call["receiver"]


def words_of(name):
    return " ".join(part.lower() for part in re.findall(r"[A-Z]?[a-z]+|[A-Z]+(?![a-z])|\d+", name))


INTERACTIONS = {
    "Triggered": "a ProximityPrompt: fireproximityprompt, if the executor has it",
    "MouseClick": "a ClickDetector: fireclickdetector, if the executor has it",
    "Touched": "a touch part: firetouchinterest, if the executor has it",
}


def inventory(indexed, as_json):
    actions = {}
    for info in indexed:
        for call in info["remotes"]:
            name = remote_name(call)
            entry = actions.setdefault(name, {"remote": name, "idea": words_of(name), "calls": []})
            entry["calls"].append({
                "script": info["label"], "line": call["line"], "method": call["method"],
                "function": enclosing_function(info["functions"], call["line"]),
                "args": call["args"], "count": call["count"], "source": call["source"],
            })
    interactions = [
        {"script": i["label"], "line": m["line"], "event": m["event"], "route": INTERACTIONS[m["event"]],
         "function": enclosing_function(i["functions"], m["line"])}
        for i in indexed for m in i["mechanisms"] if m["event"] in INTERACTIONS
    ]
    tunables = [
        {"script": i["label"], "line": t["line"], "name": t["name"], "value": t["value"],
         "function": enclosing_function(i["functions"], t["line"])}
        for i in indexed for t in i["tunables"]
    ]
    tags = sorted({e["name"] for i in indexed for e in i["tags"]})
    attributes = sorted({e["name"] for i in indexed for e in i["attributes"]})
    failed = sum(i["failed"] for i in indexed)
    engine = sorted({route for route in ENGINE_ROUTE.values()})

    if as_json:
        print(json.dumps({"actions": list(actions.values()), "interactions": interactions,
                          "tunables": tunables, "tags": tags, "attributes": attributes,
                          "engine_routes": engine, "failed_markers": failed}, indent=1))
        return 0

    print("inventory of %d script(s); failed-to-decompile markers: %d" % (len(indexed), failed))
    print("\n1. Actions the client already sends (remote call sites). Feasible to repeat or")
    print("   automate by calling them as these lines do; the server decides whether it counts.")
    for entry in sorted(actions.values(), key=lambda e: (-len(e["calls"]), e["remote"])):
        print("  %s  (%s)" % (entry["remote"], entry["idea"] or "unnamed"))
        for call in entry["calls"][:4]:
            count = call["count"] if call["count"] is not None else "?"
            print("    %s:%d  in %s  %s(%s)  %s arg(s)" % (call["script"], call["line"], call["function"],
                                                         call["method"], ", ".join(call["args"])[:90], count))
        if len(entry["calls"]) > 4:
            print("    ... %d more call site(s)" % (len(entry["calls"]) - 4))
    if not actions:
        print("  none: this dump fires no remotes from client code")
    print("\n2. Interactions the game listens for (auto-interact candidates).")
    for entry in interactions[:30]:
        print("  %s:%d  in %s  .%s  -> %s" % (entry["script"], entry["line"], entry["function"],
                                             entry["event"], entry["route"]))
    if not interactions:
        print("  none found")
    print("\n3. Numbers in client code. Changing one changes only this client's copy; if the")
    print("   server checks the same rule, the change does nothing or gets noticed.")
    for entry in tunables[:40]:
        print("  %s:%d  in %s  %s = %s" % (entry["script"], entry["line"], entry["function"],
                                           entry["name"], entry["value"]))
    if not tunables:
        print("  none found")
    print("\n4. Tags and attributes the client reads (ESP, collect and teleport targets).")
    print("  tags: %s" % (", ".join(tags[:40]) or "none"))
    print("  attributes: %s" % (", ".join(attributes[:40]) or "none"))
    print("\n5. Engine features that need no game code:")
    for route in engine:
        print("  " + route)
    print("\nnext: suggest only what these sections show, cite each file:line, and say for each")
    print("      what the dump cannot show: whether the server accepts it.")
    if failed:
        print("      %d region(s) failed to decompile; features there are unknown, not absent." % failed)
    return 0


def main(argv):
    args = argv[1:]
    as_json = "--json" in args
    args = [a for a in args if a != "--json"]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return 2
    target = args[0]
    wants_inventory = "--inventory" in args
    feature = None
    extra = []
    if "--feature" in args:
        feature = args[args.index("--feature") + 1]
    if "--terms" in args:
        extra = args[args.index("--terms") + 1].split(",")

    units = load(target)
    if not units:
        sys.stderr.write("no readable .lua, .luau, .txt, .rbxlx or .rbxmx under %s\n" % target)
        return 2
    indexed = [index_unit(label, text) for label, text in units]
    failed = sum(i["failed"] for i in indexed)

    if wants_inventory:
        return inventory(indexed, as_json)

    if feature is None:
        if as_json:
            print(json.dumps(indexed, indent=1))
        else:
            summary(indexed)
        return 0

    terms = expand_terms(feature, extra)
    evidence = search(indexed, units, terms)
    related = related_remotes(indexed, units, evidence)
    result = verdict(evidence)
    words = re.split(r"[^a-z0-9]+", feature.lower())
    engine = next((ENGINE_ROUTE[w] for w in words if w in ENGINE_ROUTE), None)

    if as_json:
        print(json.dumps({"feature": feature, "terms": terms, "verdict": result, "evidence": evidence,
                          "related_remotes": related, "failed_markers": failed,
                          "engine_route": engine}, indent=1))
    else:
        print("feature: %s" % feature)
        print("search terms: %s" % ", ".join(terms))
        print("scripts searched: %d  (failed-to-decompile markers: %d)\n" % (len(indexed), failed))
        for entry in evidence[:40]:
            print("  [%-10s %d] %s:%d  in %s  -- %s" % (entry["kind"], entry["score"], entry["script"],
                                                     entry["line"], entry["function"], entry["code"]))
        if len(evidence) > 40:
            print("  ... %d more" % (len(evidence) - 40))
        if related:
            print("\nremote calls inside the matching functions:")
            for call in related:
                count = call["count"] if call["count"] is not None else "?"
                where = "  where %s = %s" % (call["receiver"], call["source"][:80]) if call["source"] else ""
                print("  %s:%d  %s:%s(%s)  %s arg(s)%s" % (call["script"], call["line"], call["receiver"],
                                                          call["method"], ", ".join(call["args"]), count, where))
        print("\nverdict: %s" % result)
        if engine and result != "FOUND":
            print("engine route: this feature needs no game code - %s." % engine)
            print("      Build on that. No client code this dump shows sets or resets it; if play shows")
            print("      a reset or a kick, send roblox-executor/assets/runtime-probe.luau with:")
            print("      " + keywords_line(terms))
        elif engine:
            print("engine route: %s - and the game's own code touches it." % engine)
            print("next: read each FOUND location in full; it may reset or detect the change.")
        elif result == "FOUND":
            print("next: read each FOUND location in full, trace it to the value or remote it changes,")
            print("      and build only against what those lines establish.")
        else:
            print("next: do not guess names. Send roblox-executor/assets/runtime-probe.luau with:")
            print("      " + keywords_line(terms))
            if failed:
                print("      %d region(s) failed to decompile; absence there is unknown, not proof." % failed)
    return {"FOUND": 0, "PARTIAL": 3, "NOT FOUND": 4}[result]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
