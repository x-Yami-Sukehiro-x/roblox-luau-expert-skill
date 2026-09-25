#!/usr/bin/env python3
"""Work out what a panel's size becomes on real screens, before anyone opens Studio.

A panel that looks right at 1280 x 720 is the one that runs off a landscape
phone, and a UIScale that fixes the phone quietly shrinks 12 px text to 8. This
takes the sizes a file states - each top-level panel's Size, its
UISizeConstraint, a UIScale if the file makes one - and computes the rendered
panel, the smallest text and the smallest button on each device profile.

Usage:
    python tools/py/viewport_fit.py <file.luau>
    python tools/py/viewport_fit.py --size 0.5,0,0.7,0 --min 300,260 --max 640,480
        [--uiscale none|reference|<number>] [--reference 1280x720] [--clamp 0.7,1.6]
        [--text 14] [--button 44]

With a UIScale in the file and no --uiscale, the reference-viewport formula
from roblox-ui/references/scaling-and-dpi.md is assumed and the output says so.

Insets are approximate: 58 px of topbar, plus the safe areas of a notched
phone. Studio's device emulator and GuiService:GetInsetArea give exact ones.
The layout inside the panel is not modelled; a panel that fits can still
overflow inside, which roblox-ui-viewport/references/overflow.md covers.

Exit 1 when a panel does not fit, text renders under 12 px, or a button
renders under 44 px on a touch screen.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ui_lint import (  # noqa: E402
    find_root,
    index_children,
    load_gui_classes,
    make_resolver,
    number,
    offset_of,
    parse_elements,
    read,
    scale_of,
    vector2_of,
)

MIN_TEXT = 12
MIN_TARGET = 44
TOPBAR = 58

# name, viewport, insets (top, bottom, left, right) beyond the topbar, input.
DEVICES = [
    ("small phone, landscape", (640, 360), (0, 0, 0, 0), "touch"),
    ("iPhone SE, landscape", (667, 375), (0, 0, 0, 0), "touch"),
    ("notched phone, landscape", (844, 390), (0, 21, 47, 47), "touch"),
    ("phone, portrait (if enabled)", (390, 844), (47, 34, 0, 0), "touch"),
    ("tablet, landscape", (1024, 768), (0, 0, 0, 0), "touch"),
    ("laptop", (1366, 768), (0, 0, 0, 0), "mouse"),
    ("1080p monitor", (1920, 1080), (0, 0, 0, 0), "mouse"),
    ("1440p monitor", (2560, 1440), (0, 0, 0, 0), "mouse"),
    ("ultrawide", (3440, 1440), (0, 0, 0, 0), "mouse"),
    ("4K monitor", (3840, 2160), (0, 0, 0, 0), "mouse"),
    ("console on a TV", (1920, 1080), (0, 0, 0, 0), "gamepad"),
]


def usable(viewport, insets):
    top, bottom, left, right = insets
    return viewport[0] - left - right, viewport[1] - TOPBAR - top - bottom


def reference_scale(viewport, reference, clamp):
    raw = min(viewport[0] / reference[0], viewport[1] / reference[1])
    if viewport[0] < viewport[1]:
        raw = viewport[1] / reference[1] * 0.75
    return max(clamp[0], min(clamp[1], raw))


def panel_size(spec, area):
    size = []
    for axis, extent in (("x", area[0]), ("y", area[1])):
        value = spec["scale"][axis] * extent + spec["offset"][axis]
        if spec["max"] is not None:
            value = min(value, spec["max"][axis])
        if spec["min"] is not None:
            value = max(value, spec["min"][axis])
        size.append(value)
    return size


def report(name, spec, scaling, text, button):
    print(name)
    detail = "  Size scale %s,%s offset %s,%s" % (
        fmt(spec["scale"]["x"]), fmt(spec["scale"]["y"]), fmt(spec["offset"]["x"]), fmt(spec["offset"]["y"]))
    if spec["min"]:
        detail += "  min %sx%s" % (fmt(spec["min"]["x"]), fmt(spec["min"]["y"]))
    if spec["max"]:
        detail += "  max %sx%s" % (fmt(spec["max"]["x"]), fmt(spec["max"]["y"]))
    detail += "  UIScale %s" % scaling["label"]
    print(detail)
    print("  %-30s %-10s %-10s %-12s %-6s %-7s %s" % ("device", "viewport", "usable", "panel", "scale", "text", "button"))
    failures = []
    for device, viewport, insets, input_kind in DEVICES:
        area = usable(viewport, insets)
        factor = scaling["of"](viewport)
        size = [value * factor for value in panel_size(spec, area)]
        fits = size[0] <= area[0] and size[1] <= area[1]
        text_px = text * factor if text else None
        button_px = button * factor if button else None
        notes = []
        if not fits:
            notes.append("runs off by %sx%s" % (fmt(max(0, size[0] - area[0])), fmt(max(0, size[1] - area[1]))))
        if text_px is not None and text_px < MIN_TEXT:
            notes.append("text under %d px" % MIN_TEXT)
        if button_px is not None and input_kind == "touch" and button_px < MIN_TARGET:
            notes.append("button under %d px" % MIN_TARGET)
        print("  %-30s %-10s %-10s %-12s %-6s %-7s %-6s %s" % (
            device,
            "%dx%d" % viewport,
            "%dx%d" % area,
            "%sx%s" % (fmt(size[0]), fmt(size[1])),
            "%.2f" % factor,
            fmt(text_px) if text_px is not None else "-",
            fmt(button_px) if button_px is not None else "-",
            "; ".join(notes) if notes else "ok",
        ))
        failures += ["%s: %s" % (device, note) for note in notes]
    return failures


def fmt(value):
    if value is None:
        return "-"
    rounded = round(value, 1)
    return str(int(rounded)) if rounded == int(rounded) else str(rounded)


def scaling_for(choice, reference, clamp):
    if choice == "none":
        return {"label": "none", "of": lambda viewport: 1.0}
    if choice == "reference":
        return {
            "label": "assumed: reference %dx%d clamped %s-%s" % (reference[0], reference[1], fmt(clamp[0]), fmt(clamp[1])),
            "of": lambda viewport: reference_scale(viewport, reference, clamp),
        }
    fixed = float(choice)
    return {"label": "fixed %s" % fmt(fixed), "of": lambda viewport: fixed}


def pair(text, separator=","):
    parts = [float(part) for part in text.lower().replace("x", separator).split(separator)]
    return parts[0], parts[1]


def from_file(path, options):
    root = find_root()
    if root is None:
        print("could not find the verified indexes; run from the repository or the unpacked archive",
              file=sys.stderr)
        sys.exit(2)
    gui = load_gui_classes(root)
    source = read(path)
    model = parse_elements(source, gui)
    elements = [element for element in model["elements"] if not element.template]
    children = index_children(elements)
    resolve = make_resolver(source)

    def prop(element, key):
        value = element.props.get(key)
        return resolve(value) if value is not None else None

    screen = next((element for element in elements if element.cls == "ScreenGui"), None)
    if screen is None:
        print("%s builds no ScreenGui, so there is no top-level panel to fit" % path)
        return None
    panels = [element for element in elements
              if element.parent == screen.variable and element.cls in gui["GuiObject"]]
    if not panels:
        print("%s puts nothing directly in its ScreenGui" % path)
        return None

    sizes = [number(prop(element, "TextSize")) for element in elements if prop(element, "TextSize") is not None]
    sizes = [size for size in sizes if size is not None]
    text = options.get("text") or (min(sizes) if sizes else None)
    buttons = []
    for element in elements:
        if element.cls not in ("TextButton", "ImageButton"):
            continue
        constraint = next((m for m in children.get(element.variable, []) if m.cls == "UISizeConstraint"), None)
        minimum = vector2_of(prop(constraint, "MinSize")) if constraint else None
        offset = offset_of(prop(element, "Size"))
        for axis in ("x", "y"):
            value = minimum[axis] if minimum else (offset[axis] if offset else None)
            if value:
                buttons.append(value)
    button = options.get("button") or (min(buttons) if buttons else None)

    # A UIScale on the screen or a panel resizes it; one deeper is press feedback.
    roots = {screen.variable} | {panel.variable for panel in panels}
    made_scale = any(element.cls == "UIScale" and element.parent in roots for element in elements)
    choice = options.get("uiscale") or ("reference" if made_scale else "none")
    scaling = scaling_for(choice, options["reference"], options["clamp"])

    failures = []
    computed = 0
    for panel in panels:
        size = prop(panel, "Size")
        scale = scale_of(size) or {"x": 0, "y": 0}
        offset = offset_of(size) or {"x": 0, "y": 0}
        if scale_of(size) is None and offset_of(size) is None:
            print("%s: Size %s is not a literal UDim2, so it cannot be computed here"
                  % (panel.variable or panel.cls, size))
            continue
        constraint = next((m for m in children.get(panel.variable, []) if m.cls == "UISizeConstraint"), None)
        spec = {
            "scale": scale,
            "offset": offset,
            "min": vector2_of(prop(constraint, "MinSize")) if constraint else None,
            "max": vector2_of(prop(constraint, "MaxSize")) if constraint else None,
        }
        failures += report("%s (line %d)" % (panel.variable or panel.cls, panel.line), spec, scaling, text, button)
        computed += 1
        print()
    return failures if computed else None


def main(argv):
    options = {"reference": (1280.0, 720.0), "clamp": (1.0, 1.6)}
    files = []
    spec = {"scale": {"x": 0, "y": 0}, "offset": {"x": 0, "y": 0}, "min": None, "max": None}
    manual = False
    i = 0
    while i < len(argv):
        arg = argv[i]
        value = argv[i + 1] if i + 1 < len(argv) else None
        if arg == "--size":
            parts = [float(part) for part in value.split(",")]
            spec["scale"] = {"x": parts[0], "y": parts[2]}
            spec["offset"] = {"x": parts[1], "y": parts[3]}
            manual = True
        elif arg in ("--min", "--max"):
            x, y = pair(value)
            spec[arg[2:]] = {"x": x, "y": y}
        elif arg == "--uiscale":
            options["uiscale"] = value
        elif arg == "--reference":
            options["reference"] = pair(value)
        elif arg == "--clamp":
            options["clamp"] = pair(value)
        elif arg in ("--text", "--button"):
            options[arg[2:]] = float(value)
        else:
            files.append(arg)
            i += 1
            continue
        i += 2

    if not files and not manual:
        print(__doc__.strip().split("\n\n")[1], file=sys.stderr)
        return 2

    failures = []
    measured = 0
    if manual:
        scaling = scaling_for(options.get("uiscale") or "none", options["reference"], options["clamp"])
        failures += report("panel", spec, scaling, options.get("text"), options.get("button"))
        measured += 1
        print()
    for path in files:
        found = from_file(path, options)
        if found is not None:
            failures += found
            measured += 1

    if measured == 0:
        print("nothing to measure")
        return 0
    if failures:
        print("%d problem(s): %s" % (len(failures), "; ".join(failures[:6]) + (" ..." if len(failures) > 6 else "")))
        return 1
    print("fits every device profile")
    return 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
