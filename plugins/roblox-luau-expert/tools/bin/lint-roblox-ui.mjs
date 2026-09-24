#!/usr/bin/env node
// Count the UI rubric over a real Luau file, instead of asking whether it was
// followed.
//
// roblox-ui/references/self-review.md is a list of counts precisely so that no
// design judgement is needed to run it. A model asked to run it will report a
// score whether or not it counted. This counts.
//
// It reads the GUI objects a file builds through lib/gui-model.mjs rather than
// grepping for `x.Prop = v`. The first version did the latter, and a 726-line
// UI script written with a `new("Frame", { ... }, parent)` helper scored 20/20
// having resolved nothing at all. A gate that cannot see the file must say so,
// which is what E-BLIND is for.
//
// It is deliberately narrow. Every check here is decidable from the text of a
// file, and anything needing taste is left to the reference. A linter that
// reports things the author already handled teaches you to stop reading it,
// which is worse than having no linter.
//
// Usage:
//   node tools/bin/lint-roblox-ui.mjs <file.luau> [more.luau ...]
//   node tools/bin/lint-roblox-ui.mjs --json <file.luau>
//   node tools/bin/lint-roblox-ui.mjs --compare <before.luau> <after.luau>
//   node tools/bin/lint-roblox-ui.mjs <directory>
//
// Exit 1 on any E-* finding. W-* are reported and do not fail.

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";
import {
  GUI_OBJECTS,
  LAYER_COLLECTORS,
  DEFAULT_TEXT,
  parseElements,
  indexChildren,
  stripComments,
  lineOf,
  scaleOf,
  offsetOf,
  vector2Of,
  udimOffset,
  makeResolver,
} from "./lib/gui-model.mjs";

// The spacing scale from roblox-ui/references/build-order.md step 5.
const SPACING_SCALE = new Set([0, 2, 4, 8, 12, 16, 24, 32]);

// The type scale from step 6. A file may use a subset; it may not invent sizes.
const TYPE_SCALE = new Set([12, 13, 14, 16, 17, 20, 22, 28, 30, 32, 34]);

const MIN_TEXT_SIZE = 12;
const MIN_TOUCH_TARGET = 44;
const MAX_DISTINCT_TEXT_SIZES = 5;
const MAX_DISTINCT_RADII = 2;
const MAX_COLOUR_LITERALS = 14;

// toasts.md: "A toast is read in about a second and a half at a glance." Below
// that the message is decoration - it appears and leaves before it is read.
const MIN_TOAST_SECONDS = 1.5;

const TOAST_CONSTANT = /(TOAST|NOTIF|SNACK|BANNER|POPUP)\w*(LIFETIME|DURATION|TIME|TTL|HOLD|LINGER|DISMISS)/i;

// Names for a button that exists to swallow clicks rather than to be pressed.
const ABSORBER_NAMES = /^(scrim|blocker|backdrop|overlay|catcher|shade|veil|hit|hitbox|dismiss)/i;

const TEARDOWN_HINTS =
  /(:Disconnect\(|Disconnect\(\)|table\.clear\(|Trove|Janitor|:Destroy\(\)|:destroy\(\)|:Clean\(|:clean\(|maid)/i;

/** Strip comments and string literals so they cannot produce findings. */
function stripAll(source) {
  return stripComments(source)
    .replace(/\[(=*)\[[\s\S]*?\]\1\]/g, '""')
    .replace(/"(?:[^"\\\n]|\\.)*"/g, '""')
    .replace(/'(?:[^'\\\n]|\\.)*'/g, '""');
}

/** Split a comma list at depth zero. */
function splitTopLevel(text) {
  const parts = [];
  let depth = 0;
  let start = 0;
  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (char === "(" || char === "{" || char === "[") depth += 1;
    else if (char === ")" || char === "}" || char === "]") depth -= 1;
    else if (char === "," && depth === 0) {
      parts.push(text.slice(start, i).trim());
      start = i + 1;
    }
  }
  parts.push(text.slice(start).trim());
  return parts;
}

/** A control label that is one or two symbol characters and no words. */
function isGlyphLabel(expression) {
  const match = /^["'](.*)["']$/s.exec(expression?.trim() ?? "");
  if (!match) return null;
  const text = match[1];
  if (text.length === 0 || [...text].length > 2) return null;
  if (![...text].every((char) => char.codePointAt(0) > 127)) return null;
  return text;
}

function analyse(rawSource, rel) {
  const source = stripAll(rawSource);
  const code = stripComments(rawSource);
  const findings = [];
  const add = (code_, line, message) => findings.push({ code: code_, line, message, file: rel });
  const has = (pattern) => pattern.test(source);

  const { elements: parsed, byVariable, classLiterals, blind } = parseElements(rawSource);
  // A modifier written inside an attacher helper is a template. Its real
  // instances are the synthesized ones at each call site; counting both makes
  // `addCorner(panel, 10)` look like two different radii.
  const elements = parsed.filter((element) => !element.template);
  // Reading `UDim.new(0, GAP_BASE)` the same way as `UDim.new(0, 8)`.
  const resolve = makeResolver(rawSource);
  const prop = (element, key) => resolve(element.props.get(key));
  const children = indexChildren(elements);
  const drawables = elements.filter((e) => GUI_OBJECTS.has(e.class) || LAYER_COLLECTORS.has(e.class));

  // --- can this file be read at all? --------------------------------------
  if (blind) {
    add(
      "E-BLIND",
      1,
      `${classLiterals} GUI class name(s) in this file and not one resolved construction - ` +
        "the rubric cannot be counted here, so it is not scored (see lib/gui-model.mjs)"
    );
    return { findings, counts: null, blind: true };
  }

  const created = new Set(elements.map((e) => e.class));
  const buildsScreenGui = elements.some((e) => LAYER_COLLECTORS.has(e.class));

  const buttons = elements.filter(
    (e) => /^(TextButton|ImageButton)$/.test(e.class) && !(e.variable && ABSORBER_NAMES.test(e.variable))
  );
  const buildsButton = buttons.length > 0;
  const buildsAnything = elements.length > 0;

  /** Modifier children of an element, e.g. its UICorner or UIFlexItem. */
  const modifiers = (element) => (element.variable ? (children.get(element.variable) ?? []) : []);

  /** The axis a parent UIListLayout flexes along, or null. */
  const flexAxis = (element) => {
    const layout = (children.get(element.parent) ?? []).find((c) => c.class === "UIListLayout");
    if (!layout) return null;
    // UIListLayout defaults to Vertical.
    return /Horizontal/.test(layout.props.get("FillDirection") ?? "") ? "x" : "y";
  };

  // --- type scale ---------------------------------------------------------
  const textSizes = new Set();
  for (const element of elements) {
    const raw = prop(element, "TextSize");
    if (raw === undefined) continue;
    const numeric = Number(raw);
    if (Number.isFinite(numeric)) {
      textSizes.add(numeric);
      if (numeric < MIN_TEXT_SIZE) {
        add("E-TEXTSIZE", element.line, `TextSize ${numeric} is below the ${MIN_TEXT_SIZE} floor - illegible on a phone`);
      }
      if (!TYPE_SCALE.has(numeric)) {
        add("E-TYPESCALE", element.line, `TextSize ${numeric} is not on a type scale - see build-order.md step 6`);
      }
    } else {
      textSizes.add(raw);
    }
  }
  if (textSizes.size > MAX_DISTINCT_TEXT_SIZES) {
    add(
      "E-TYPESCALE",
      1,
      `${textSizes.size} distinct TextSize values (${[...textSizes].join(", ")}) - the scale allows ${MAX_DISTINCT_TEXT_SIZES}`
    );
  }

  // --- TextScaled ---------------------------------------------------------
  const textScaled = elements.filter((e) => /^true$/.test(e.props.get("TextScaled") ?? ""));
  if (textScaled.length > 1) {
    add(
      "E-TEXTSCALED",
      textScaled[1].line,
      `TextScaled = true ${textScaled.length} times - it is for one badge, not a layout strategy (tell R2)`
    );
  }
  if (textScaled.length > 0 && !created.has("UITextSizeConstraint")) {
    add("W-TEXTBOUND", textScaled[0].line, "TextScaled without a UITextSizeConstraint - unbounded on small and huge screens");
  }

  // --- corner radii -------------------------------------------------------
  const radii = new Set();
  for (const element of elements) {
    for (const key of ["CornerRadius", "TopLeftRadius", "TopRightRadius", "BottomLeftRadius", "BottomRightRadius"]) {
      const expression = prop(element, key);
      if (expression === undefined) continue;
      const offset = udimOffset(expression);
      if (offset !== null) radii.add(offset);
      else if (/UDim\.new\(\s*0?\.5/.test(expression)) radii.add("pill");
      else radii.add(expression.replace(/\s+/g, ""));
    }
  }
  if (radii.size > MAX_DISTINCT_RADII) {
    add(
      "E-RADII",
      1,
      `${radii.size} distinct corner radii (${[...radii].join(", ")}) - two is the whole language (build-order.md step 7)`
    );
  }

  // --- spacing rhythm -----------------------------------------------------
  const spacing = new Set();
  for (const element of elements) {
    for (const [key, expression] of element.props) {
      if (!/^(Padding|PaddingTop|PaddingBottom|PaddingLeft|PaddingRight|CellPadding)$/.test(key)) continue;
      const values = [];
      const resolved = resolve(expression);
      const single = udimOffset(resolved);
      if (single !== null) values.push(single);
      const pair = offsetOf(resolved);
      if (pair) values.push(pair.x, pair.y);
      for (const value of values) {
        spacing.add(value);
        if (!SPACING_SCALE.has(value)) {
          add(
            "E-SPACING",
            element.line,
            `spacing ${value} is off the 4 / 8 / 12 / 16 / 24 / 32 scale - mixed arbitrary values are tell R6`
          );
        }
      }
    }
  }

  // --- input reach --------------------------------------------------------
  for (const match of source.matchAll(/\.(MouseButton1Click|MouseButton1Down|MouseButton1Up)\b/g)) {
    add(
      "E-MOUSEONLY",
      lineOf(source, match.index),
      `${match[1]} is mouse-only - use Activated, which also fires for touch, gamepad and Enter`
    );
  }

  if (buildsButton && !buttons.some((b) => /^false$/.test(b.props.get("AutoButtonColor") ?? ""))) {
    add("E-AUTOBUTTON", buttons[0].line, "a button without AutoButtonColor = false - the engine tint fights every state you set yourself");
  }

  if (buildsButton && !has(/MouseEnter|InputBegan|SelectionGained/)) {
    add("W-STATES", buttons[0].line, "a button with no hover, press or focus handling - six states are required, not optional");
  }

  // --- deprecated scheduling ---------------------------------------------
  for (const match of source.matchAll(/(?<![.\w:])(wait|spawn|delay)\s*\(/g)) {
    add("E-DEPRECATED", lineOf(source, match.index), `${match[1]}() is deprecated - use task.${match[1]}`);
  }

  // --- responsiveness -----------------------------------------------------
  if (buildsScreenGui) {
    const root = elements.find((e) => LAYER_COLLECTORS.has(e.class));
    if (!created.has("UISizeConstraint") && !created.has("UIAspectRatioConstraint")) {
      add("E-UNBOUNDED", root.line, "a screen with no UISizeConstraint - absurd on ultrawide, unusable on a phone (build-order.md step 3)");
    }
    if (!root.props.has("ResetOnSpawn")) {
      add("W-RESPAWN", root.line, "ScreenGui without ResetOnSpawn set - it rebuilds on every death by default");
    }
    if (!root.props.has("ScreenInsets") && !root.props.has("IgnoreGuiInset")) {
      add("W-INSET", root.line, "ScreenGui without ScreenInsets - the topbar and phone notches will cover content");
    }
    if (root.props.has("ScreenInsets") && root.props.has("IgnoreGuiInset")) {
      add(
        "W-INSETBOTH",
        root.line,
        "ScreenInsets and IgnoreGuiInset both set - ScreenInsets supersedes it, so one of these is a guess"
      );
    }
  }

  // --- touch targets ------------------------------------------------------
  // A button's own box, whether stated as an offset or pinned by a constraint.
  for (const button of buttons) {
    const constraint = modifiers(button).find((m) => m.class === "UISizeConstraint");
    const min = constraint ? vector2Of(prop(constraint, "MinSize")) : null;
    const offset = offsetOf(prop(button, "Size"));
    const width = min?.x ?? offset?.x;
    const height = min?.y ?? offset?.y;
    for (const [axis, value] of [["wide", width], ["tall", height]]) {
      if (Number.isFinite(value) && value > 0 && value < MIN_TOUCH_TARGET) {
        add(
          "W-TOUCH",
          button.line,
          `${button.variable ?? button.class} is ${value}px ${axis} - ${MIN_TOUCH_TARGET}px is the touch-target floor`
        );
      }
    }
  }

  // --- the token spine ----------------------------------------------------
  const colours = new Set();
  for (const match of source.matchAll(/Color3\.fromRGB\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/g)) {
    colours.add(`${match[1]},${match[2]},${match[3]}`);
  }
  if (buildsAnything && colours.size > MAX_COLOUR_LITERALS) {
    add(
      "W-TOKENS",
      1,
      `${colours.size} distinct colour literals - past about ${MAX_COLOUR_LITERALS} this is a palette, and it belongs in one token block`
    );
  }

  // --- layout hygiene -----------------------------------------------------
  const listLayouts = elements.filter((e) => e.class === "UIListLayout" || e.class === "UIGridLayout");
  for (const layout of listLayouts) {
    if (!layout.props.has("SortOrder")) {
      add("W-SORTORDER", layout.line, "layout without SortOrder - the default sorts by name, which surprises everyone once");
    }
  }

  // --- L1  sizing that does nothing ---------------------------------------
  for (const element of drawables) {
    const size = prop(element, "Size");
    const scale = scaleOf(size);
    const offset = offsetOf(size);
    if (!scale && !offset) continue;
    const dead = [];

    const constraint = modifiers(element).find((m) => m.class === "UISizeConstraint");
    if (constraint) {
      const min = vector2Of(prop(constraint, "MinSize"));
      const max = vector2Of(prop(constraint, "MaxSize"));
      if (min && max) {
        for (const axis of ["x", "y"]) {
          if (min[axis] !== max[axis]) continue;
          const stated = scale?.[axis] || offset?.[axis];
          if (stated) dead.push(`${axis.toUpperCase()} ${stated} (pinned to ${min[axis]}px)`);
        }
      }
    }

    const flex = modifiers(element).find((m) => m.class === "UIFlexItem");
    if (flex && /\bFill\b/.test(flex.props.get("FlexMode") ?? "")) {
      const axis = flexAxis(element);
      // A scale of 1 on a filled axis is idiomatic filler, not a claim. An
      // offset is never filler - somebody picked that number.
      if (axis) {
        if (scale && scale[axis] !== 0 && scale[axis] !== 1) {
          dead.push(`${axis.toUpperCase()} scale ${scale[axis]} (UIFlexItem Fill decides it)`);
        }
        if (offset && offset[axis] !== 0) {
          dead.push(`${axis.toUpperCase()} ${offset[axis]}px (UIFlexItem Fill decides it)`);
        }
      }
    }

    if (dead.length > 0) {
      add(
        "E-DEADSIZE",
        element.line,
        `${element.variable ?? element.class}.Size states ${dead.join(" and ")} - a number that changes nothing is a guess left in the file`
      );
    }
  }

  for (const element of elements) {
    if (element.class !== "UIPadding") continue;
    const values = [...element.props]
      .filter(([key]) => /^Padding/.test(key))
      .map(([, value]) => udimOffset(resolve(value)));
    if (values.length > 0 && values.every((value) => value === 0)) {
      add("E-DEADPAD", element.line, "a UIPadding whose every side is 0 - an Instance created to do nothing");
    }
  }

  // --- L2  alignment that disagrees with the layout -----------------------
  for (const element of elements) {
    const alignment = element.props.get("TextYAlignment");
    if (!alignment || !/\.(Top|Bottom)\b/.test(alignment)) continue;
    const layout = (children.get(element.parent) ?? []).find((c) => c.class === "UIListLayout");
    const vertical = layout?.props.get("VerticalAlignment");
    if (vertical && /\.Center\b/.test(vertical)) {
      add(
        "E-ALIGNMENT",
        element.line,
        `${element.variable ?? element.class} sets TextYAlignment ${/Top/.test(alignment) ? "Top" : "Bottom"} inside a row ` +
          "the layout centres - the label will not line up with anything beside it"
      );
    }
  }

  for (const element of drawables) {
    const zIndex = element.props.get("ZIndex");
    if (zIndex === undefined) continue;
    // `list.ZIndex = panel.ZIndex` is inheriting a stacking context, not
    // claiming an order among siblings.
    if (/\w+\.ZIndex/.test(zIndex)) continue;
    // A parent this file did not build may have any number of other children.
    if (!byVariable.has(element.parent)) continue;
    const siblings = (children.get(element.parent) ?? []).filter((s) => GUI_OBJECTS.has(s.class));
    if (siblings.length === 1) {
      add(
        "E-DEADZINDEX",
        element.line,
        `${element.variable ?? element.class} sets ZIndex and is an only child - ZIndex orders siblings, so this changes nothing`
      );
    }
  }

  // --- L2  a position the layout will overwrite ---------------------------
  // A layout places every sibling it manages, so a Position set or tweened on
  // one is ignored. A toast written to slide in this way never moves.
  const LAYOUTS = new Set(["UIListLayout", "UIGridLayout", "UITableLayout", "UIPageLayout"]);
  const laidOut = (element) =>
    byVariable.has(element.parent) &&
    (children.get(element.parent) ?? []).some((child) => LAYOUTS.has(child.class));
  for (const element of drawables) {
    if (!element.props.has("Position") || !laidOut(element)) continue;
    add(
      "E-LAYOUTPOS",
      element.propLines.get("Position") ?? element.line,
      `${element.variable ?? element.class} sets Position inside a parent with a layout - the layout places it, so the value is ignored`
    );
  }
  for (const match of source.matchAll(/\b(\w+)\s*,\s*[\w.]+(?:\([^()]*\))?\s*,\s*\{[^{}]*\bPosition\s*=/g)) {
    const element = byVariable.get(match[1]);
    if (!element || !GUI_OBJECTS.has(element.class) || !laidOut(element)) continue;
    add(
      "E-LAYOUTPOS",
      lineOf(source, match.index),
      `${match[1]} tweens Position inside a parent with a layout - the layout holds it, so it never moves`
    );
  }

  // --- L3  text set where the element is built ----------------------------
  for (const element of elements) {
    const fallback = DEFAULT_TEXT.get(element.class);
    if (!fallback) continue;
    if (!element.props.has("Text")) {
      add("E-DEFAULTTEXT", element.line, `${element.class} built with no Text - it renders the engine default "${fallback}"`);
      continue;
    }
    // On screen before it has anything to say. Setting Text after the element
    // is parented shows the engine default for at least a frame.
    const textLine = element.propLines.get("Text");
    if (textLine !== undefined && element.parentLine !== null && textLine > element.parentLine) {
      add(
        "W-DEFAULTTEXT",
        element.line,
        `${element.variable ?? element.class} is parented on line ${element.parentLine} and gets its Text on line ${textLine} - ` +
          `it renders "${fallback}" in between`
      );
    }
  }

  // Whether two surfaces should share a border is an elevation question, and
  // elevation needs taste: a focus ring, a shadow and a floating panel all
  // differ from the resting border on purpose. That belongs in
  // roblox-ui-components/references/shadows-and-elevation.md, not here.

  // --- L6  rounded corners that something square pokes out of --------------
  //
  // Roblox's UICorner docs: "Input, but not descendants, will be clipped to
  // the round corner area." A child that reaches the container's edge keeps
  // its square corner and draws over the rounded one - the accent bar down
  // the side of a toast is the classic case.
  //
  // ClipsDescendants does not rescue it: that clips to the rectangle. The
  // CanvasGroup docs are explicit that a CanvasGroup is the fix - "UICorner
  // and UIGradient under a CanvasGroup will also apply to the whole group".
  for (const element of drawables) {
    if (element.class === "CanvasGroup") continue;
    const own = modifiers(element);
    if (!own.some((m) => m.class === "UICorner")) continue;

    if (element.class === "ScrollingFrame") {
      add(
        "E-SCROLLCORNER",
        element.line,
        `UICorner on a ScrollingFrame - Roblox documents this as unsupported. Round a Frame around it instead`
      );
      continue;
    }

    // Padding on the container keeps every child away from the corner.
    if (own.some((m) => m.class === "UIPadding")) continue;

    const clips = /^true$/.test(element.props.get("ClipsDescendants") ?? "");
    const kids = (children.get(element.variable) ?? []).filter((c) => GUI_OBJECTS.has(c.class));

    for (const child of kids) {
      // A transparent child draws nothing, so nothing pokes out.
      const transparency = Number(child.props.get("BackgroundTransparency") ?? "0");
      if (transparency === 1) continue;
      // A child with its own rounding follows the curve.
      if ((children.get(child.variable) ?? []).some((m) => m.class === "UICorner")) continue;

      const scale = scaleOf(resolve(child.props.get("Size")));
      if (!scale) continue;
      const axis = scale.x === 1 ? "X" : scale.y === 1 ? "Y" : null;
      if (!axis) continue;

      add(
        "E-CORNERBLEED",
        child.line,
        `${child.variable ?? child.class} fills ${axis} inside a rounded ${element.variable ?? element.class} ` +
          (clips
            ? "whose ClipsDescendants clips to the rectangle, not the curve"
            : "and has no rounding of its own") +
          ` - its square corner draws over the rounded one. Make the container a CanvasGroup`
      );
      break;
    }
  }

  // --- L5  a notification anyone can read ---------------------------------
  for (const match of code.matchAll(/^[^\S\n]*local\s+([A-Z][A-Z0-9_,\s]*?)\s*=\s*([^\n]+)$/gm)) {
    const names = match[1].split(",").map((name) => name.trim());
    const values = splitTopLevel(match[2]);
    names.forEach((name, index) => {
      if (!TOAST_CONSTANT.test(name)) return;
      const value = Number((values[index] ?? "").replace(/_/g, ""));
      if (Number.isFinite(value) && value > 0 && value < MIN_TOAST_SECONDS) {
        add(
          "E-TOASTFAST",
          lineOf(code, match.index),
          `${name} is ${value}s - a toast is read in about ${MIN_TOAST_SECONDS}s at a glance, so this one leaves before it is read`
        );
      }
    });
  }

  for (const element of elements) {
    const glyph = isGlyphLabel(element.props.get("Text"));
    if (!glyph) continue;
    add(
      "W-GLYPHICON",
      element.line,
      `Text is the glyph "${glyph}" - a font character is not an icon; it sits on the text baseline, ` +
        "not the optical centre, and its weight does not match the rest (see icons.md)"
    );
  }

  for (const element of elements) {
    for (const [key, value] of element.props) {
      if (!/^(Image|Texture|IconImage)/.test(key)) continue;
      if (!/rbxassetid:\/\/\d+/.test(value)) continue;
      add(
        "W-ASSETLOOSE",
        element.line,
        `${key} is a literal asset id - put ids in one named table and run verify-asset-ids.mjs, ` +
          "or it is an id nobody has checked"
      );
    }
  }

  // --- lifetime -----------------------------------------------------------
  const connects = (source.match(/[:.]Connect\(/g) ?? []).length;
  if (connects > 0 && !TEARDOWN_HINTS.test(source)) {
    add(
      "E-LEAK",
      1,
      `${connects} connection(s) and no teardown path - undisconnected connections are the most common real Roblox memory leak`
    );
  }

  const counts = {
    elements: elements.length,
    textSizes: textSizes.size,
    textScaled: textScaled.length,
    radii: radii.size,
    spacing: [...spacing].sort((a, b) => a - b),
    colours: colours.size,
    connections: connects,
  };

  return { findings, counts, blind: false };
}

/**
 * The counted half of self-review.md, scored the way that file scores it.
 * Only the rows this tool can decide are scored; the rest stay the reader's.
 */
function score(counts, findings) {
  const none = (...codes) => !findings.some((f) => codes.includes(f.code));
  const rows = [
    // Not applicable is a pass. A component that renders no text cannot have a
    // wrong type scale, and scoring it down teaches you to ignore the score.
    ["C1 distinct TextSize values", counts.textSizes <= MAX_DISTINCT_TEXT_SIZES && none("E-TEXTSIZE")],
    ["C2 TextScaled assignments", counts.textScaled <= 1],
    ["C3 distinct corner radii", counts.radii <= MAX_DISTINCT_RADII],
    ["C5 spacing values on the scale", none("E-SPACING")],
    ["C8 interaction states present", none("W-STATES", "E-AUTOBUTTON")],
    ["H1 colours come from tokens", none("W-TOKENS")],
    ["H2 root is bounded", none("E-UNBOUNDED")],
    ["H4 touch targets", none("W-TOUCH")],
    ["H5 Activated, not MouseButton1Click", none("E-MOUSEONLY")],
    ["H7 connections torn down", none("E-LEAK")],
    ["L1 no sizing that changes nothing", none("E-DEADSIZE", "E-DEADPAD")],
    ["L2 alignment agrees with the layout", none("E-ALIGNMENT", "E-DEADZINDEX", "E-LAYOUTPOS")],
    ["L3 text set where the element is built", none("E-DEFAULTTEXT", "W-DEFAULTTEXT")],
    ["L4 icons are assets, not glyphs", none("W-GLYPHICON", "W-ASSETLOOSE")],
    ["L5 notifications can be read", none("E-TOASTFAST", "W-INSETBOTH")],
    ["L6 nothing square inside a rounded box", none("E-CORNERBLEED", "E-SCROLLCORNER")],
  ];
  const passed = rows.filter(([, ok]) => ok).length;
  return { rows, passed, total: rows.length, points: passed * 2 };
}

/**
 * Prove a redesign happened.
 *
 * "Completely redesign the UI" comes back as a new file with the same eleven
 * elements, the same three text sizes and the same two colours, and a reply
 * saying it was redesigned. The user finds out by opening Studio.
 *
 * A redesign moves the structural rows: how many elements there are, the type
 * scale, the radii, the spacing set, the palette. If none of those moved, the
 * file was reformatted, and saying otherwise is a false claim about work.
 */
function compare(beforeFile, afterFile) {
  const read = (file) => {
    const full = existsSync(file) ? file : join(REPO_ROOT, file);
    if (!existsSync(full)) {
      console.error(`no such path: ${file}`);
      process.exit(2);
    }
    const source = readFileSync(full, "utf8");
    const { findings, counts, blind } = analyse(source, file);
    return { findings, counts, blind, score: blind ? null : score(counts, findings) };
  };

  const before = read(beforeFile);
  const after = read(afterFile);

  if (before.blind || after.blind) {
    console.error("one of the files could not be counted - resolve E-BLIND before comparing");
    process.exit(2);
  }

  const key = (finding) => `${finding.code}:${finding.line}:${finding.message}`;
  const beforeKeys = new Set(before.findings.map(key));
  const afterKeys = new Set(after.findings.map(key));
  const resolved = before.findings.filter((f) => !afterKeys.has(key(f)));
  const introduced = after.findings.filter((f) => !beforeKeys.has(key(f)));

  const rows = [
    ["score", `${before.score.points}/${before.score.total * 2}`, `${after.score.points}/${after.score.total * 2}`],
    ["elements", before.counts.elements, after.counts.elements],
    ["distinct TextSize", before.counts.textSizes, after.counts.textSizes],
    ["TextScaled", before.counts.textScaled, after.counts.textScaled],
    ["distinct radii", before.counts.radii, after.counts.radii],
    ["spacing set", `[${before.counts.spacing.join(",")}]`, `[${after.counts.spacing.join(",")}]`],
    ["colour literals", before.counts.colours, after.counts.colours],
    ["connections", before.counts.connections, after.counts.connections],
  ];

  console.log(`\n${beforeFile} -> ${afterFile}\n`);
  const width = Math.max(...rows.map(([name]) => name.length));
  let moved = 0;
  for (const [name, from, to] of rows) {
    const same = String(from) === String(to);
    if (!same) moved += 1;
    console.log(`  ${name.padEnd(width)}  ${String(from).padStart(12)} -> ${String(to).padEnd(12)} ${same ? "unchanged" : ""}`);
  }

  console.log(`\n  resolved   ${resolved.length}`);
  for (const finding of resolved.slice(0, 12)) console.log(`    - ${finding.code}  ${finding.message.slice(0, 84)}`);
  console.log(`  introduced ${introduced.length}`);
  for (const finding of introduced.slice(0, 12)) console.log(`    + ${finding.code}  ${finding.message.slice(0, 84)}`);

  // Structure is rows 2 to 8; the score alone can move on a one-line fix.
  const structural = rows.slice(1).filter(([, from, to]) => String(from) !== String(to)).length;
  console.log(
    `\n  ${moved}/${rows.length} rows moved, ${structural} of them structural. ` +
      (structural === 0
        ? "The layout, type scale and palette are identical - this is not a redesign."
        : "Report these numbers rather than the word.")
  );

  if (after.findings.some((f) => f.code.startsWith("E-"))) process.exitCode = 1;
}

function collect(target, out = []) {
  if (statSync(target).isDirectory()) {
    for (const entry of readdirSync(target)) {
      if (entry === "node_modules" || entry === ".git") continue;
      collect(join(target, entry), out);
    }
  } else if (/\.luau?$/.test(target)) {
    out.push(target);
  }
  return out;
}

function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const targets = args.filter((a) => !a.startsWith("--"));

  if (args.includes("--compare")) {
    if (targets.length !== 2) {
      console.error("usage: node tools/bin/lint-roblox-ui.mjs --compare <before.luau> <after.luau>");
      process.exit(2);
    }
    compare(targets[0], targets[1]);
    return;
  }

  if (targets.length === 0) {
    console.error(
      "usage: node tools/bin/lint-roblox-ui.mjs <file.luau|directory> [...]\n" +
        "Counts the rubric in roblox-ui/references/self-review.md over real code."
    );
    process.exit(2);
  }

  const files = [];
  for (const target of targets) {
    const full = existsSync(target) ? target : join(REPO_ROOT, target);
    if (!existsSync(full)) {
      console.error(`no such path: ${target}`);
      process.exit(2);
    }
    collect(full, files);
  }

  const results = [];
  for (const file of files) {
    const inside = relative(REPO_ROOT, file).split(sep).join("/");
    const rel = inside.startsWith("..") ? file.split(/[/\\]/).pop() : inside;
    const { findings, counts, blind } = analyse(readFileSync(file, "utf8"), rel);
    results.push({ file: rel, findings, counts, blind, score: blind ? null : score(counts, findings) });
  }

  if (asJson) {
    console.log(JSON.stringify({ results }, null, 2));
  } else {
    for (const result of results) {
      console.log(`\n${result.file}`);
      for (const finding of result.findings) {
        console.log(`  ${result.file}:${finding.line}  ${finding.code}  ${finding.message}`);
      }
      if (result.blind) {
        console.log("  not scored - the rubric could not be counted over this file");
        continue;
      }
      const failed = result.score.rows.filter(([, ok]) => !ok).map(([name]) => name);
      console.log(
        `  score ${result.score.points}/${result.score.total * 2}` +
          (failed.length ? `  failing: ${failed.join(", ")}` : "  all counted checks pass")
      );
      console.log(
        `  counts: ${result.counts.elements} element(s), ${result.counts.textSizes} text size(s), ` +
          `${result.counts.radii} radius value(s), ${result.counts.colours} colour literal(s), ` +
          `${result.counts.connections} connection(s), spacing [${result.counts.spacing.join(", ")}]`
      );
    }
  }

  const errors = results.flatMap((r) => r.findings).filter((f) => f.code.startsWith("E-"));
  const warnings = results.flatMap((r) => r.findings).filter((f) => f.code.startsWith("W-"));
  if (!asJson) {
    console.log(`\n${files.length} file(s) - ${errors.length} error(s), ${warnings.length} warning(s)`);
  }
  if (errors.length > 0) process.exitCode = 1;
}

main();
