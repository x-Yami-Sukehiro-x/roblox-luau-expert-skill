#!/usr/bin/env python3
"""Count the UI rubric over a real Luau file, without Node.

A port of tools/bin/lint-roblox-ui.mjs and the GUI model it reads through,
held to identical findings by tools/bin/lint-parity.mjs --ui. It exists for the
same reason roblox_lint.py does: a custom GPT's Code Interpreter is Python, and
an interface gate that cannot run in the host producing the interfaces is a gate
that never runs.

It resolves the GUI objects a file builds rather than grepping for `x.Prop = v`,
because the first version of the Node original did the latter and gave a 726-line
UI script a perfect score having resolved nothing at all. Two construction forms
are understood:

    A  local v = Instance.new("Class")   then  v.Prop = value,  v.Parent = p
    B  local v = helper("Class", { Prop = value, ... }, parent)

Usage:
    python ui_lint.py <file.luau> [more.luau ...]
    python ui_lint.py <directory>
    python ui_lint.py --json <file.luau>
    python ui_lint.py --compare <before.luau> <after.luau>

Exit 1 on any E-* finding. W-* are reported and do not fail.
"""

import json
import math
import os
import re
import sys

# A repository or an unpacked archive keeps the skills under .claude/skills; the
# OpenAI plugin keeps them under skills/. Either layout is accepted.
SKILL_LAYOUTS = (os.path.join(".claude", "skills"), "skills")
VERIFIED_TAIL = os.path.join("roblox-luau-expert", "references", "verified")
VERIFIED = os.path.join(SKILL_LAYOUTS[0], VERIFIED_TAIL)


def verified_dir(root):
    for layout in SKILL_LAYOUTS:
        path = os.path.join(root, layout, VERIFIED_TAIL)
        if os.path.isdir(path):
            return path
    return None

SPACING_SCALE = {0, 2, 4, 8, 12, 16, 24, 32}
TYPE_SCALE = {12, 13, 14, 16, 17, 20, 22, 28, 30, 32, 34}
MIN_TEXT_SIZE = 12
MIN_TOUCH_TARGET = 44
FIT_WIDTH = 640
FIT_HEIGHT = 300
CLIPPING_CLASSES = {"ScrollingFrame", "CanvasGroup"}
TEXT_CLASSES = {"TextLabel", "TextButton", "TextBox"}
MAX_DISTINCT_TEXT_SIZES = 5
MAX_DISTINCT_RADII = 2
MAX_COLOUR_LITERALS = 14
MIN_TOAST_SECONDS = 1.5

DEFAULT_TEXT = {"TextLabel": "Label", "TextButton": "Button", "TextBox": "TextBox"}

TOAST_CONSTANT = re.compile(
    r"(TOAST|NOTIF|SNACK|BANNER|POPUP)\w*(LIFETIME|DURATION|TIME|TTL|HOLD|LINGER|DISMISS)", re.I)
ABSORBER_NAMES = re.compile(
    r"^(scrim|blocker|backdrop|overlay|catcher|shade|veil|hit|hitbox|dismiss)", re.I)
TEARDOWN_HINTS = re.compile(
    r"(:Disconnect\(|Disconnect\(\)|table\.clear\(|Trove|Janitor|:Destroy\(\)|:destroy\(\)"
    r"|:Clean\(|:clean\(|maid)", re.I)

NUMBER = r"-?\d+(?:\.\d+)?"


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def find_root():
    probes = [os.path.dirname(os.path.abspath(__file__)), os.getcwd()]
    for probe in probes:
        current = probe
        for _ in range(6):
            if verified_dir(current):
                return current
            parent = os.path.dirname(current)
            if parent == current:
                break
            current = parent
    for base in probes:
        for root, dirs, _ in os.walk(base):
            dirs[:] = [name for name in dirs if name not in (".git", "node_modules")]
            if verified_dir(root):
                return root
            if root.count(os.sep) - base.count(os.sep) > 4:
                dirs[:] = []
    return None


def load_gui_classes(root):
    path = os.path.join(verified_dir(root), "gui-classes.txt")
    if not os.path.exists(path):
        sys.stderr.write("missing %s - run: node tools/bin/generate-tables.mjs\n" % path)
        sys.exit(2)
    sets = {"GuiObject": set(), "UIBase": set(), "LayerCollector": set()}
    for line in read(path).replace("\r\n", "\n").split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) == 2 and parts[0] in sets:
            sets[parts[0]].add(parts[1])
    return sets


# --------------------------------------------------------------------------
# Text handling


def strip_comments(source):
    source = re.sub(r"--\[(=*)\[[\s\S]*?\]\1\]",
                    lambda m: re.sub(r"[^\n]", " ", m.group(0)), source)
    return re.sub(r"--[^\n]*", "", source)


def strip_all(source):
    source = strip_comments(source)
    source = re.sub(r"\[(=*)\[[\s\S]*?\]\1\]", '""', source)
    source = re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', source)
    return re.sub(r"'(?:[^'\\\n]|\\.)*'", '""', source)


def line_of(source, index):
    return source.count("\n", 0, index) + 1


def match_bracket(source, open_index, opener, closer):
    depth = 0
    i = open_index
    length = len(source)
    while i < length:
        char = source[i]
        if char in ('"', "'"):
            quote = char
            i += 1
            while i < length and source[i] != quote:
                if source[i] == "\\":
                    i += 1
                i += 1
        elif char == opener:
            depth += 1
        elif char == closer:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def match_brace(source, open_index):
    """The `}` matching the `{` at open_index; nested brackets all count."""
    depth = 0
    i = open_index
    length = len(source)
    while i < length:
        char = source[i]
        if char in ('"', "'"):
            quote = char
            i += 1
            while i < length and source[i] != quote:
                if source[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def split_at_depth(text, separator=","):
    parts = []
    depth = 0
    start = 0
    for i, char in enumerate(text):
        if char in "({[":
            depth += 1
        elif char in ")}]":
            depth -= 1
        elif char == separator and depth == 0:
            parts.append(text[start:i])
            start = i + 1
    parts.append(text[start:])
    return parts


def parse_table(body):
    """Top-level `Key = value` pairs of a table body, ignoring nested tables."""
    props = {}
    entries = []
    depth = 0
    start = 0
    i = 0
    length = len(body)
    while i < length:
        char = body[i]
        if char in ('"', "'"):
            quote = char
            i += 1
            while i < length and body[i] != quote:
                if body[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if char in "{([":
            depth += 1
        elif char in "})]":
            depth -= 1
        elif char == "," and depth == 0:
            entries.append(body[start:i])
            start = i + 1
        i += 1
    entries.append(body[start:])

    for entry in entries:
        match = re.match(r"^\s*([A-Za-z_]\w*)\s*=\s*([\s\S]+?)\s*$", entry)
        if match:
            props[match.group(1)] = re.sub(r"\s+", " ", match.group(2))
    return props


def value_from(source, start):
    """The assignment value at `start`, continuing past newlines while open."""
    depth = 0
    i = start
    length = len(source)
    while i < length:
        char = source[i]
        if char in ('"', "'"):
            quote = char
            i += 1
            while i < length and source[i] != quote:
                if source[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if char in "({[":
            depth += 1
        elif char in ")}]":
            depth -= 1
        elif char == "\n" and depth <= 0:
            return source[start:i]
        i += 1
    return source[start:]


# --------------------------------------------------------------------------
# The element model


class Element(object):
    __slots__ = ("variable", "cls", "line", "source_index", "parent", "parent_line",
                 "props", "prop_lines", "form", "template")

    def __init__(self, **kwargs):
        for slot in self.__slots__:
            setattr(self, slot, kwargs.get(slot))
        if self.props is None:
            self.props = {}
        if self.prop_lines is None:
            self.prop_lines = {}
        self.template = bool(self.template)


HELPER_CALL = re.compile(
    r"""(?:local\s+([A-Za-z_]\w*)\s*=\s*)?([A-Za-z_][\w.:]*)\s*\(\s*["']([A-Za-z]+)["']\s*,\s*\{""")
INSTANCE_NEW = re.compile(
    r"""(?:local\s+([A-Za-z_]\w*)\s*=\s*)?Instance\.new\(\s*["']([A-Za-z]+)["']\s*"""
    r"""(?:,\s*([A-Za-z_][\w.]*)\s*)?\)""")
ASSIGNMENT = re.compile(r"\b([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*=\s*(?=[^\n=])")
FUNCTION_HEAD = re.compile(r"(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(([^)]*)\)")
WORD = re.compile(r"[A-Za-z_]\w*")


def function_spans(code):
    spans = []
    for match in FUNCTION_HEAD.finditer(code):
        params = [name.strip() for name in match.group(2).split(",")]
        params = [name for name in params if re.match(r"^[A-Za-z_]\w*$", name)]
        if not params:
            continue
        depth = 0
        end = -1
        for word in WORD.finditer(code, match.start()):
            text = word.group(0)
            if text in ("function", "if", "do", "repeat"):
                depth += 1
            elif text in ("end", "until"):
                depth -= 1
                if depth == 0:
                    end = word.start()
                    break
        if end != -1:
            spans.append({"name": match.group(1), "params": params,
                          "start": match.start(), "end": end})
    return spans


def expand_attachers(code, elements, ui_modifiers):
    """Replay modifier-attaching helpers at their call sites.

    A helper that parents a UICorner to one of its own parameters leaves the
    element attached to the parameter name, so nothing links it to the caller's
    frame. Three dead Size values hid behind exactly this in a real file.
    """
    spans = function_spans(code)
    if not spans:
        return elements

    attachers = {}
    for span in spans:
        for element in elements:
            index = element.source_index
            if index is None or index < span["start"] or index > span["end"]:
                continue
            if element.parent not in span["params"]:
                continue
            if element.cls not in ui_modifiers:
                continue
            element.template = True
            record = attachers.setdefault(span["name"], {"span": span, "attached": []})
            record["attached"].append((element, span["params"].index(element.parent)))

    for name, record in attachers.items():
        span = record["span"]
        pattern = re.compile(r"(?<![\w.:])%s\s*\(" % re.escape(name))
        for call in pattern.finditer(code):
            open_index = call.end() - 1
            if span["start"] < open_index < span["end"]:
                continue
            close = match_bracket(code, open_index, "(", ")")
            if close == -1:
                continue
            args = [part.strip() for part in split_at_depth(code[open_index + 1:close])]

            bound = {}
            for index, param in enumerate(span["params"]):
                if index < len(args) and args[index] != "":
                    bound[param] = args[index]

            for element, param_index in record["attached"]:
                target = args[param_index] if param_index < len(args) else None
                if not target or not re.match(r"^[A-Za-z_]\w*$", target):
                    continue
                props = {}
                for key, value in element.props.items():
                    props[key] = re.sub(r"\b[A-Za-z_]\w*\b",
                                        lambda m: bound.get(m.group(0), m.group(0)), value)
                elements.append(Element(
                    variable=None, cls=element.cls, line=line_of(code, call.start()),
                    source_index=call.start(), parent=target,
                    parent_line=line_of(code, call.start()),
                    props=props, prop_lines={}, form="attached"))
    return elements


def parse_elements(raw_source, gui):
    all_classes = gui["GuiObject"] | gui["UIBase"] | gui["LayerCollector"]
    code = strip_comments(raw_source)
    elements = []
    events = []
    consumed = []

    for match in HELPER_CALL.finditer(code):
        class_name = match.group(3)
        if class_name not in all_classes:
            continue
        if match.group(2) == "Instance.new":
            continue
        open_index = match.end() - 1
        close = match_brace(code, open_index)
        if close == -1:
            continue
        tail = code[close + 1:close + 200]
        parent_match = re.match(r"^\s*,\s*([A-Za-z_][\w.]*)", tail)
        events.append(("construct", match.start(), Element(
            variable=match.group(1), cls=class_name, line=line_of(code, match.start()),
            source_index=match.start(),
            parent=parent_match.group(1) if parent_match else None,
            parent_line=line_of(code, match.start()) if parent_match else None,
            props=parse_table(code[open_index + 1:close]), prop_lines={}, form="table")))
        consumed.append((match.start(), close))

    for match in INSTANCE_NEW.finditer(code):
        class_name = match.group(2)
        if class_name not in all_classes:
            continue
        events.append(("construct", match.start(), Element(
            variable=match.group(1), cls=class_name, line=line_of(code, match.start()),
            source_index=match.start(), parent=match.group(3),
            parent_line=line_of(code, match.start()) if match.group(3) else None,
            props={}, prop_lines={}, form="instance")))

    def in_consumed(index):
        return any(start < index < end for start, end in consumed)

    for match in ASSIGNMENT.finditer(code):
        if in_consumed(match.start()):
            continue
        value = value_from(code, match.end())
        value = re.sub(r",\s*$", "", value)
        events.append(("assign", match.start(),
                       (match.group(1), match.group(2), re.sub(r"\s+", " ", value).strip())))

    events.sort(key=lambda event: event[1])

    live = {}
    for kind, index, payload in events:
        if kind == "construct":
            elements.append(payload)
            if payload.variable:
                live[payload.variable] = payload
            continue
        variable, key, value = payload
        element = live.get(variable)
        if element is None:
            continue
        line = line_of(code, index)
        if key == "Parent":
            if not element.parent:
                element.parent = value
                element.parent_line = line
            continue
        if key not in element.props:
            element.props[key] = value
            element.prop_lines[key] = line

    expand_attachers(code, elements, gui["UIBase"])

    by_variable = {}
    for element in elements:
        if element.variable and element.variable not in by_variable:
            by_variable[element.variable] = element

    class_literals = 0
    for match in re.finditer(r"""["']([A-Za-z]+)["']""", raw_source):
        if match.group(1) in all_classes:
            class_literals += 1

    return {
        "elements": elements,
        "by_variable": by_variable,
        "class_literals": class_literals,
        "blind": len(elements) == 0 and class_literals >= 5,
    }


def index_children(elements):
    children = {}
    for element in elements:
        if not element.parent:
            continue
        children.setdefault(element.parent, []).append(element)
    return children


def numeric_constants(source):
    """Constants a file binds exactly once, so named numbers count as numbers.

    Without this the rubric is strictest on code that names its numbers and
    blindest to code that sprays them, which is backwards.
    """
    code = strip_comments(source)
    counts = {}
    values = {}
    for match in re.finditer(r"^[^\S\n]*local[^\S\n]+([A-Za-z_][\w,\s]*?)[^\S\n]*=([^\n]+)$",
                             code, re.M):
        names = [name.strip() for name in match.group(1).split(",")]
        if any(not re.match(r"^[A-Za-z_]\w*$", name) for name in names):
            continue
        parts = split_at_depth(match.group(2))
        for index, name in enumerate(names):
            counts[name] = counts.get(name, 0) + 1
            raw = (parts[index] if index < len(parts) else "").strip().replace("_", "")
            try:
                values[name] = float(raw)
            except ValueError:
                pass
    return {name: value for name, value in values.items() if counts.get(name) == 1}


def make_resolver(source):
    constants = numeric_constants(source)
    if not constants:
        return lambda expression: expression

    def render(value):
        return str(int(value)) if value == int(value) else str(value)

    def resolve(expression):
        if not isinstance(expression, str):
            return expression
        return re.sub(r"\b[A-Za-z_]\w*\b",
                      lambda m: render(constants[m.group(0)]) if m.group(0) in constants
                      else m.group(0), expression)
    return resolve


def number(text):
    try:
        value = float(text)
    except (TypeError, ValueError):
        return None
    return int(value) if value == int(value) else value


def scale_of(expression):
    if not expression:
        return None
    match = re.search(r"UDim2\.fromScale\(\s*(%s)\s*,\s*(%s)\s*\)" % (NUMBER, NUMBER), expression)
    if match:
        return {"x": number(match.group(1)), "y": number(match.group(2))}
    match = re.search(r"UDim2\.new\(\s*(%s)\s*,\s*%s\s*,\s*(%s)\s*,\s*%s\s*\)"
                      % (NUMBER, NUMBER, NUMBER, NUMBER), expression)
    if match:
        return {"x": number(match.group(1)), "y": number(match.group(2))}
    if "UDim2.fromOffset(" in expression:
        return {"x": 0, "y": 0}
    return None


def offset_of(expression):
    if not expression:
        return None
    match = re.search(r"UDim2\.fromOffset\(\s*(%s)\s*,\s*(%s)\s*\)" % (NUMBER, NUMBER), expression)
    if match:
        return {"x": number(match.group(1)), "y": number(match.group(2))}
    match = re.search(r"UDim2\.new\(\s*%s\s*,\s*(%s)\s*,\s*%s\s*,\s*(%s)\s*\)"
                      % (NUMBER, NUMBER, NUMBER, NUMBER), expression)
    if match:
        return {"x": number(match.group(1)), "y": number(match.group(2))}
    if "UDim2.fromScale(" in expression:
        return {"x": 0, "y": 0}
    return None


def vector2_of(expression):
    if not expression:
        return None
    match = re.search(r"Vector2\.new\(\s*(%s)\s*,\s*(%s)\s*\)" % (NUMBER, NUMBER), expression)
    return {"x": number(match.group(1)), "y": number(match.group(2))} if match else None


def udim_offset(expression):
    if not expression:
        return None
    match = re.search(r"UDim\.new\(\s*0(?:\.0+)?\s*,\s*(%s)\s*\)" % NUMBER, expression)
    return number(match.group(1)) if match else None


def glyph_label(expression):
    if not expression:
        return None
    match = re.match(r"""^["'](.*)["']$""", expression.strip(), re.S)
    if not match:
        return None
    text = match.group(1)
    if len(text) == 0 or len(text) > 2:
        return None
    if not all(ord(char) > 127 for char in text):
        return None
    return text


# --------------------------------------------------------------------------
# The rubric


def analyse(raw_source, rel, gui):
    source = strip_all(raw_source)
    code = strip_comments(raw_source)
    findings = []

    def add(code_, line, message):
        findings.append({"code": code_, "line": line, "message": message, "file": rel})

    model = parse_elements(raw_source, gui)
    elements = [element for element in model["elements"] if not element.template]
    by_variable = model["by_variable"]
    resolve = make_resolver(raw_source)

    def prop(element, key):
        value = element.props.get(key)
        return resolve(value) if value is not None else None

    children = index_children(elements)
    drawables = [e for e in elements if e.cls in gui["GuiObject"] or e.cls in gui["LayerCollector"]]

    if model["blind"]:
        add("E-BLIND", 1,
            "%d GUI class name(s) in this file and not one resolved construction - "
            "the rubric cannot be counted here, so it is not scored (see lib/gui-model.mjs)"
            % model["class_literals"])
        return findings, None, True

    created = set(element.cls for element in elements)

    buttons = [e for e in elements
               if e.cls in ("TextButton", "ImageButton")
               and not (e.variable and ABSORBER_NAMES.match(e.variable))]
    builds_button = len(buttons) > 0
    builds_anything = len(elements) > 0

    def modifiers(element):
        return children.get(element.variable, []) if element.variable else []

    def flex_axis(element):
        layout = next((c for c in children.get(element.parent, []) if c.cls == "UIListLayout"), None)
        if layout is None:
            return None
        return "x" if "Horizontal" in (layout.props.get("FillDirection") or "") else "y"

    # --- type scale -------------------------------------------------------
    text_sizes = set()
    for element in elements:
        raw = prop(element, "TextSize")
        if raw is None:
            continue
        numeric = number(raw)
        if numeric is not None:
            text_sizes.add(numeric)
            if numeric < MIN_TEXT_SIZE:
                add("E-TEXTSIZE", element.line,
                    "TextSize %s is below the %d floor - illegible on a phone"
                    % (numeric, MIN_TEXT_SIZE))
            if numeric not in TYPE_SCALE:
                add("E-TYPESCALE", element.line,
                    "TextSize %s is not on a type scale - see build-order.md step 6" % numeric)
        else:
            text_sizes.add(raw)
    if len(text_sizes) > MAX_DISTINCT_TEXT_SIZES:
        add("E-TYPESCALE", 1,
            "%d distinct TextSize values (%s) - the scale allows %d"
            % (len(text_sizes), ", ".join(str(size) for size in text_sizes), MAX_DISTINCT_TEXT_SIZES))

    # --- TextScaled -------------------------------------------------------
    text_scaled = [e for e in elements if (e.props.get("TextScaled") or "").strip() == "true"]
    if len(text_scaled) > 1:
        add("E-TEXTSCALED", text_scaled[1].line,
            "TextScaled = true %d times - it is for one badge, not a layout strategy (tell R2)"
            % len(text_scaled))
    if text_scaled and "UITextSizeConstraint" not in created:
        add("W-TEXTBOUND", text_scaled[0].line,
            "TextScaled without a UITextSizeConstraint - unbounded on small and huge screens")

    # --- corner radii -----------------------------------------------------
    radii = set()
    for element in elements:
        for key in ("CornerRadius", "TopLeftRadius", "TopRightRadius",
                    "BottomLeftRadius", "BottomRightRadius"):
            expression = prop(element, key)
            if expression is None:
                continue
            offset = udim_offset(expression)
            if offset is not None:
                radii.add(offset)
            elif re.search(r"UDim\.new\(\s*0?\.5", expression):
                radii.add("pill")
            else:
                radii.add(re.sub(r"\s+", "", expression))
    if len(radii) > MAX_DISTINCT_RADII:
        add("E-RADII", 1,
            "%d distinct corner radii (%s) - two is the whole language (build-order.md step 7)"
            % (len(radii), ", ".join(str(value) for value in radii)))

    # --- spacing rhythm ---------------------------------------------------
    spacing = set()
    for element in elements:
        for key, expression in element.props.items():
            if not re.match(r"^(Padding|PaddingTop|PaddingBottom|PaddingLeft|PaddingRight|CellPadding)$", key):
                continue
            values = []
            resolved = resolve(expression)
            single = udim_offset(resolved)
            if single is not None:
                values.append(single)
            pair = offset_of(resolved)
            if pair:
                values.extend([pair["x"], pair["y"]])
            for value in values:
                spacing.add(value)
                if value not in SPACING_SCALE:
                    add("E-SPACING", element.line,
                        "spacing %s is off the 4 / 8 / 12 / 16 / 24 / 32 scale - "
                        "mixed arbitrary values are tell R6" % value)

    # --- input reach ------------------------------------------------------
    for match in re.finditer(r"\.(MouseButton1Click|MouseButton1Down|MouseButton1Up)\b", source):
        add("E-MOUSEONLY", line_of(source, match.start()),
            "%s is mouse-only - use Activated, which also fires for touch, gamepad and Enter"
            % match.group(1))

    if builds_button and not any((b.props.get("AutoButtonColor") or "").strip() == "false"
                                 for b in buttons):
        add("E-AUTOBUTTON", buttons[0].line,
            "a button without AutoButtonColor = false - the engine tint fights every state "
            "you set yourself")

    if builds_button and not re.search(r"MouseEnter|InputBegan|SelectionGained", source):
        add("W-STATES", buttons[0].line,
            "a button with no hover, press or focus handling - six states are required, "
            "not optional")

    # --- deprecated scheduling -------------------------------------------
    for match in re.finditer(r"(?<![.\w:])(wait|spawn|delay)\s*\(", source):
        add("E-DEPRECATED", line_of(source, match.start()),
            "%s() is deprecated - use task.%s" % (match.group(1), match.group(1)))

    # --- responsiveness ---------------------------------------------------
    # A BillboardGui or SurfaceGui is sized in the world, not on the screen, and
    # has no ScreenInsets, so these rules belong to the ScreenGui alone.
    root = next((e for e in elements if e.cls == "ScreenGui"), None)
    if root:
        if "UISizeConstraint" not in created and "UIAspectRatioConstraint" not in created:
            add("E-UNBOUNDED", root.line,
                "a screen with no UISizeConstraint - absurd on ultrawide, unusable on a phone "
                "(build-order.md step 3)")
        if "ResetOnSpawn" not in root.props:
            add("W-RESPAWN", root.line,
                "ScreenGui without ResetOnSpawn set - it rebuilds on every death by default")
        if "ScreenInsets" not in root.props and "IgnoreGuiInset" not in root.props:
            add("W-INSET", root.line,
                "ScreenGui without ScreenInsets - the topbar and phone notches will cover content")
        if "ScreenInsets" in root.props and "IgnoreGuiInset" in root.props:
            add("W-INSETBOTH", root.line,
                "ScreenInsets and IgnoreGuiInset both set - ScreenInsets supersedes it, "
                "so one of these is a guess")

        screen_scaled = any(m.cls == "UIScale" for m in modifiers(root))
        for panel in drawables:
            if panel.parent != root.variable or panel.cls not in gui["GuiObject"]:
                continue
            scaled = screen_scaled or any(m.cls == "UIScale" for m in modifiers(panel))
            constraint = next((m for m in modifiers(panel) if m.cls == "UISizeConstraint"), None)
            minimum = vector2_of(prop(constraint, "MinSize")) if constraint else None
            maximum = vector2_of(prop(constraint, "MaxSize")) if constraint else None
            scale = scale_of(prop(panel, "Size"))
            offset = offset_of(prop(panel, "Size"))
            smallest = minimum
            if not scaled and offset and scale and scale["x"] == 0 and scale["y"] == 0:
                smallest = {
                    axis: max(minimum[axis] if minimum else 0,
                              min(offset[axis], maximum[axis] if maximum else float("inf")))
                    for axis in ("x", "y")
                }
            if not smallest or (smallest["x"] <= FIT_WIDTH and smallest["y"] <= FIT_HEIGHT):
                continue
            add("E-MINFIT", constraint.line if constraint else panel.line,
                "%s cannot shrink below %sx%spx - a 640x360 phone leaves %dx%d under the topbar, "
                "so it runs off the screen"
                % (panel.variable or panel.cls, smallest["x"], smallest["y"], FIT_WIDTH, FIT_HEIGHT))

    # --- touch targets ----------------------------------------------------
    for button in buttons:
        constraint = next((m for m in modifiers(button) if m.cls == "UISizeConstraint"), None)
        minimum = vector2_of(prop(constraint, "MinSize")) if constraint else None
        offset = offset_of(prop(button, "Size"))
        width = minimum["x"] if minimum else (offset["x"] if offset else None)
        height = minimum["y"] if minimum else (offset["y"] if offset else None)
        for axis, value in (("wide", width), ("tall", height)):
            if value is not None and 0 < value < MIN_TOUCH_TARGET:
                add("W-TOUCH", button.line,
                    "%s is %spx %s - %dpx is the touch-target floor"
                    % (button.variable or button.cls, value, axis, MIN_TOUCH_TARGET))

    # --- the token spine --------------------------------------------------
    colours = set()
    for match in re.finditer(r"Color3\.fromRGB\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", source):
        colours.add("%s,%s,%s" % match.groups())
    if builds_anything and len(colours) > MAX_COLOUR_LITERALS:
        add("W-TOKENS", 1,
            "%d distinct colour literals - past about %d this is a palette, and it belongs "
            "in one token block" % (len(colours), MAX_COLOUR_LITERALS))

    # --- layout hygiene ---------------------------------------------------
    for layout in [e for e in elements if e.cls in ("UIListLayout", "UIGridLayout")]:
        if "SortOrder" not in layout.props:
            add("W-SORTORDER", layout.line,
                "layout without SortOrder - the default sorts by name, which surprises "
                "everyone once")

    # --- L1  sizing that does nothing -------------------------------------
    for element in drawables:
        size = prop(element, "Size")
        scale = scale_of(size)
        offset = offset_of(size)
        if not scale and not offset:
            continue
        dead = []

        constraint = next((m for m in modifiers(element) if m.cls == "UISizeConstraint"), None)
        if constraint:
            minimum = vector2_of(prop(constraint, "MinSize"))
            maximum = vector2_of(prop(constraint, "MaxSize"))
            if minimum and maximum:
                for axis in ("x", "y"):
                    if minimum[axis] != maximum[axis]:
                        continue
                    stated = (scale or {}).get(axis) or (offset or {}).get(axis)
                    if stated:
                        dead.append("%s %s (pinned to %spx)"
                                    % (axis.upper(), stated, minimum[axis]))

        flex = next((m for m in modifiers(element) if m.cls == "UIFlexItem"), None)
        if flex and re.search(r"\bFill\b", flex.props.get("FlexMode") or ""):
            axis = flex_axis(element)
            if axis:
                if scale and scale[axis] != 0 and scale[axis] != 1:
                    dead.append("%s scale %s (UIFlexItem Fill decides it)"
                                % (axis.upper(), scale[axis]))
                if offset and offset[axis] != 0:
                    dead.append("%s %spx (UIFlexItem Fill decides it)" % (axis.upper(), offset[axis]))

        if dead:
            add("E-DEADSIZE", element.line,
                "%s.Size states %s - a number that changes nothing is a guess left in the file"
                % (element.variable or element.cls, " and ".join(dead)))

    for element in elements:
        if element.cls != "UIPadding":
            continue
        values = [udim_offset(resolve(value)) for key, value in element.props.items()
                  if key.startswith("Padding")]
        if values and all(value == 0 for value in values):
            add("E-DEADPAD", element.line,
                "a UIPadding whose every side is 0 - an Instance created to do nothing")

    # --- L2  alignment that disagrees with the layout ---------------------
    for element in elements:
        alignment = element.props.get("TextYAlignment")
        if not alignment or not re.search(r"\.(Top|Bottom)\b", alignment):
            continue
        layout = next((c for c in children.get(element.parent, []) if c.cls == "UIListLayout"), None)
        vertical = layout.props.get("VerticalAlignment") if layout else None
        if vertical and re.search(r"\.Center\b", vertical):
            add("E-ALIGNMENT", element.line,
                "%s sets TextYAlignment %s inside a row the layout centres - the label will "
                "not line up with anything beside it"
                % (element.variable or element.cls, "Top" if "Top" in alignment else "Bottom"))

    for element in drawables:
        z_index = element.props.get("ZIndex")
        if z_index is None:
            continue
        if re.search(r"\w+\.ZIndex", z_index):
            continue
        if element.parent not in by_variable:
            continue
        siblings = [s for s in children.get(element.parent, []) if s.cls in gui["GuiObject"]]
        if len(siblings) == 1:
            add("E-DEADZINDEX", element.line,
                "%s sets ZIndex and is an only child - ZIndex orders siblings, so this "
                "changes nothing" % (element.variable or element.cls))

    # --- L2  a position the layout will overwrite -------------------------
    layouts = {"UIListLayout", "UIGridLayout", "UITableLayout", "UIPageLayout"}

    def laid_out(element):
        return element.parent in by_variable and any(
            child.cls in layouts for child in children.get(element.parent, []))

    for element in drawables:
        if "Position" not in element.props or not laid_out(element):
            continue
        add("E-LAYOUTPOS", element.prop_lines.get("Position") or element.line,
            "%s sets Position inside a parent with a layout - the layout places it, so the "
            "value is ignored" % (element.variable or element.cls))
    for match in re.finditer(r"\b(\w+)\s*,\s*[\w.]+(?:\([^()]*\))?\s*,\s*\{[^{}]*\bPosition\s*=", source):
        element = by_variable.get(match.group(1))
        if element is None or element.cls not in gui["GuiObject"] or not laid_out(element):
            continue
        add("E-LAYOUTPOS", line_of(source, match.start()),
            "%s tweens Position inside a parent with a layout - the layout holds it, so it "
            "never moves" % match.group(1))

    # --- L3  text set where the element is built --------------------------
    for element in elements:
        fallback = DEFAULT_TEXT.get(element.cls)
        if not fallback:
            continue
        if "Text" not in element.props:
            add("E-DEFAULTTEXT", element.line,
                '%s built with no Text - it renders the engine default "%s"'
                % (element.cls, fallback))
            continue
        text_line = element.prop_lines.get("Text")
        if text_line is not None and element.parent_line is not None and text_line > element.parent_line:
            add("W-DEFAULTTEXT", element.line,
                '%s is parented on line %d and gets its Text on line %d - it renders "%s" in between'
                % (element.variable or element.cls, element.parent_line, text_line, fallback))

    # --- L6  rounded corners that something square pokes out of -----------
    for element in drawables:
        if element.cls == "CanvasGroup":
            continue
        own = modifiers(element)
        if not any(m.cls == "UICorner" for m in own):
            continue

        if element.cls == "ScrollingFrame":
            add("E-SCROLLCORNER", element.line,
                "UICorner on a ScrollingFrame - Roblox documents this as unsupported. "
                "Round a Frame around it instead")
            continue

        if any(m.cls == "UIPadding" for m in own):
            continue

        clips = (element.props.get("ClipsDescendants") or "").strip() == "true"
        kids = [c for c in children.get(element.variable, []) if c.cls in gui["GuiObject"]]

        for child in kids:
            transparency = number(child.props.get("BackgroundTransparency") or "0")
            if transparency == 1:
                continue
            if any(m.cls == "UICorner" for m in children.get(child.variable, [])):
                continue
            scale = scale_of(resolve(child.props.get("Size")))
            if not scale:
                continue
            axis = "X" if scale["x"] == 1 else ("Y" if scale["y"] == 1 else None)
            if not axis:
                continue
            add("E-CORNERBLEED", child.line,
                "%s fills %s inside a rounded %s %s - its square corner draws over the "
                "rounded one. Make the container a CanvasGroup"
                % (child.variable or child.cls, axis, element.variable or element.cls,
                   "whose ClipsDescendants clips to the rectangle, not the curve" if clips
                   else "and has no rounding of its own"))
            break

    # --- L6  an outline cut off by the parent that clips it ---------------
    def padding_sides(container):
        padding = next((m for m in modifiers(container) if m.cls == "UIPadding"), None)
        sides = []
        for side in ("PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"):
            value = udim_offset(resolve(padding.props.get(side))) if padding else None
            sides.append(value if value is not None else 0)
        return sides

    for stroke in elements:
        if stroke.cls != "UIStroke":
            continue
        outlined = by_variable.get(stroke.parent)
        container = by_variable.get(outlined.parent) if outlined else None
        if outlined is None or container is None or outlined.cls not in gui["GuiObject"]:
            continue
        clips = (container.cls in CLIPPING_CLASSES
                 or (container.props.get("ClipsDescendants") or "").strip() == "true")
        if not clips:
            continue
        mode = stroke.props.get("ApplyStrokeMode") or ""
        if outlined.cls in TEXT_CLASSES and not re.search(r"Border", mode):
            continue
        position = stroke.props.get("BorderStrokePosition") or ""
        if re.search(r"Inner", position):
            continue
        thickness = number(resolve(stroke.props.get("Thickness") or "1"))
        if thickness is None or thickness <= 0:
            continue
        overflow = thickness / 2 if re.search(r"Center", position) else thickness
        stacked = any(c.cls in layouts for c in children.get(container.variable, []))
        scale = scale_of(resolve(outlined.props.get("Size")))
        touches = stacked or (scale is not None and (scale["x"] == 1 or scale["y"] == 1))
        if not touches or all(side >= overflow for side in padding_sides(container)):
            continue
        add("E-STROKECLIP", stroke.line,
            "%s's %spx outline draws outside it, inside %s, a %s - the edge is cut off. "
            "Use BorderStrokePosition Inner or pad the parent %dpx"
            % (outlined.variable or outlined.cls, thickness, container.variable or container.cls,
               container.cls if container.cls in CLIPPING_CLASSES else "ClipsDescendants parent",
               int(math.ceil(overflow))))

    # --- L5  a notification anyone can read -------------------------------
    for match in re.finditer(r"^[^\S\n]*local\s+([A-Z][A-Z0-9_,\s]*?)\s*=\s*([^\n]+)$", code, re.M):
        names = [name.strip() for name in match.group(1).split(",")]
        values = [part.strip() for part in split_at_depth(match.group(2))]
        for index, name in enumerate(names):
            if not TOAST_CONSTANT.search(name):
                continue
            value = number((values[index] if index < len(values) else "").replace("_", ""))
            if value is not None and 0 < value < MIN_TOAST_SECONDS:
                add("E-TOASTFAST", line_of(code, match.start()),
                    "%s is %ss - a toast is read in about %ss at a glance, so this one leaves "
                    "before it is read" % (name, value, MIN_TOAST_SECONDS))

    for element in elements:
        glyph = glyph_label(element.props.get("Text"))
        if not glyph:
            continue
        add("W-GLYPHICON", element.line,
            'Text is the glyph "%s" - a font character is not an icon; it sits on the text '
            "baseline, not the optical centre, and its weight does not match the rest "
            "(see icons.md)" % glyph)

    for element in elements:
        for key, value in element.props.items():
            if not re.match(r"^(Image|Texture|IconImage)", key):
                continue
            if not re.search(r"rbxassetid://\d+", value):
                continue
            add("W-ASSETLOOSE", element.line,
                "%s is a literal asset id - put ids in one named table and run "
                "verify-asset-ids.mjs, or it is an id nobody has checked" % key)

    # --- lifetime ---------------------------------------------------------
    connects = len(re.findall(r"[:.]Connect\(", source))
    if connects > 0 and not TEARDOWN_HINTS.search(source):
        add("E-LEAK", 1,
            "%d connection(s) and no teardown path - undisconnected connections are the "
            "most common real Roblox memory leak" % connects)

    counts = {
        "elements": len(elements),
        "textSizes": len(text_sizes),
        "textScaled": len(text_scaled),
        "radii": len(radii),
        "spacing": sorted(spacing),
        "colours": len(colours),
        "connections": connects,
    }
    return findings, counts, False


def score(counts, findings):
    codes = set(finding["code"] for finding in findings)

    def none(*wanted):
        return not codes.intersection(wanted)

    rows = [
        ("C1 distinct TextSize values", counts["textSizes"] <= MAX_DISTINCT_TEXT_SIZES
         and none("E-TEXTSIZE")),
        ("C2 TextScaled assignments", counts["textScaled"] <= 1),
        ("C3 distinct corner radii", counts["radii"] <= MAX_DISTINCT_RADII),
        ("C5 spacing values on the scale", none("E-SPACING")),
        ("C8 interaction states present", none("W-STATES", "E-AUTOBUTTON")),
        ("H1 colours come from tokens", none("W-TOKENS")),
        ("H2 root is bounded and fits a phone", none("E-UNBOUNDED", "E-MINFIT")),
        ("H4 touch targets", none("W-TOUCH")),
        ("H5 Activated, not MouseButton1Click", none("E-MOUSEONLY")),
        ("H7 connections torn down", none("E-LEAK")),
        ("L1 no sizing that changes nothing", none("E-DEADSIZE", "E-DEADPAD")),
        ("L2 alignment agrees with the layout", none("E-ALIGNMENT", "E-DEADZINDEX", "E-LAYOUTPOS")),
        ("L3 text set where the element is built", none("E-DEFAULTTEXT", "W-DEFAULTTEXT")),
        ("L4 icons are assets, not glyphs", none("W-GLYPHICON", "W-ASSETLOOSE")),
        ("L5 notifications can be read", none("E-TOASTFAST", "W-INSETBOTH")),
        ("L6 nothing poking out or clipped off", none("E-CORNERBLEED", "E-SCROLLCORNER", "E-STROKECLIP")),
    ]
    passed = len([row for row in rows if row[1]])
    return {"rows": rows, "passed": passed, "total": len(rows), "points": passed * 2}


# --------------------------------------------------------------------------
# Reporting


def collect(target, out):
    if os.path.isdir(target):
        for entry in sorted(os.listdir(target)):
            if entry in ("node_modules", ".git"):
                continue
            collect(os.path.join(target, entry), out)
    elif re.search(r"\.luau?$", target):
        out.append(target)
    return out


def compare(gui, before_file, after_file):
    def load(path):
        if not os.path.exists(path):
            sys.stderr.write("no such path: %s\n" % path)
            sys.exit(2)
        findings, counts, blind = analyse(read(path), path, gui)
        return {"findings": findings, "counts": counts, "blind": blind,
                "score": None if blind else score(counts, findings)}

    before = load(before_file)
    after = load(after_file)
    if before["blind"] or after["blind"]:
        sys.stderr.write("one of the files could not be counted - resolve E-BLIND before comparing\n")
        return 2

    def key(finding):
        return "%s:%s:%s" % (finding["code"], finding["line"], finding["message"])

    before_keys = set(key(f) for f in before["findings"])
    after_keys = set(key(f) for f in after["findings"])
    resolved = [f for f in before["findings"] if key(f) not in after_keys]
    introduced = [f for f in after["findings"] if key(f) not in before_keys]

    rows = [
        ("score", "%d/%d" % (before["score"]["points"], before["score"]["total"] * 2),
         "%d/%d" % (after["score"]["points"], after["score"]["total"] * 2)),
        ("elements", before["counts"]["elements"], after["counts"]["elements"]),
        ("distinct TextSize", before["counts"]["textSizes"], after["counts"]["textSizes"]),
        ("TextScaled", before["counts"]["textScaled"], after["counts"]["textScaled"]),
        ("distinct radii", before["counts"]["radii"], after["counts"]["radii"]),
        ("spacing set", "[%s]" % ",".join(str(v) for v in before["counts"]["spacing"]),
         "[%s]" % ",".join(str(v) for v in after["counts"]["spacing"])),
        ("colour literals", before["counts"]["colours"], after["counts"]["colours"]),
        ("connections", before["counts"]["connections"], after["counts"]["connections"]),
    ]

    print("\n%s -> %s\n" % (before_file, after_file))
    width = max(len(row[0]) for row in rows)
    moved = 0
    for name, source_value, target_value in rows:
        same = str(source_value) == str(target_value)
        if not same:
            moved += 1
        print("  %s  %12s -> %-12s %s" % (name.ljust(width), source_value, target_value,
                                          "unchanged" if same else ""))

    print("\n  resolved   %d" % len(resolved))
    for finding in resolved[:12]:
        print("    - %s  %s" % (finding["code"], finding["message"][:84]))
    print("  introduced %d" % len(introduced))
    for finding in introduced[:12]:
        print("    + %s  %s" % (finding["code"], finding["message"][:84]))

    structural = len([row for row in rows[1:] if str(row[1]) != str(row[2])])
    print("\n  %d/%d rows moved, %d of them structural. %s"
          % (moved, len(rows), structural,
             "The layout, type scale and palette are identical - this is not a redesign."
             if structural == 0 else "Report these numbers rather than the word."))

    return 1 if any(f["code"].startswith("E-") for f in after["findings"]) else 0


def main(argv):
    args = argv[1:]
    as_json = "--json" in args
    targets = [arg for arg in args if not arg.startswith("--")]

    root = find_root()
    if root is None:
        sys.stderr.write(
            "could not find %s from here.\n"
            "Unpack roblox-luau-expert-skill.zip first, or run this from inside the repo.\n"
            % VERIFIED.replace(os.sep, "/"))
        return 2
    gui = load_gui_classes(root)

    if "--compare" in args:
        if len(targets) != 2:
            sys.stderr.write("usage: python ui_lint.py --compare <before.luau> <after.luau>\n")
            return 2
        return compare(gui, targets[0], targets[1])

    if not targets:
        sys.stderr.write(
            "usage: python ui_lint.py <file.luau|directory> [...]\n"
            "       python ui_lint.py --compare <before.luau> <after.luau>\n"
            "Counts the rubric in roblox-ui/references/self-review.md over real code.\n")
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
        findings, counts, blind = analyse(read(path), rel, gui)
        results.append({"file": rel, "findings": findings, "counts": counts, "blind": blind,
                        "score": None if blind else score(counts, findings)})

    if as_json:
        print(json.dumps({"results": results}, indent=2))
    else:
        for result in results:
            print("\n%s" % result["file"])
            for finding in result["findings"]:
                print("  %s:%s  %s  %s" % (result["file"], finding["line"],
                                           finding["code"], finding["message"]))
            if result["blind"]:
                print("  not scored - the rubric could not be counted over this file")
                continue
            failed = [name for name, ok in result["score"]["rows"] if not ok]
            print("  score %d/%d%s" % (
                result["score"]["points"], result["score"]["total"] * 2,
                ("  failing: " + ", ".join(failed)) if failed else "  all counted checks pass"))
            counts = result["counts"]
            print("  counts: %d element(s), %d text size(s), %d radius value(s), "
                  "%d colour literal(s), %d connection(s), spacing [%s]"
                  % (counts["elements"], counts["textSizes"], counts["radii"],
                     counts["colours"], counts["connections"],
                     ", ".join(str(value) for value in counts["spacing"])))

    errors = [f for r in results for f in r["findings"] if f["code"].startswith("E-")]
    warnings = [f for r in results for f in r["findings"] if f["code"].startswith("W-")]
    if not as_json:
        print("\n%d file(s) - %d error(s), %d warning(s)" % (len(files), len(errors), len(warnings)))

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
