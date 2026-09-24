// Resolve the GUI objects a Luau file builds, whichever way it builds them.
//
// This exists because the first version of the UI linter matched `x.Prop = v`
// and `Instance.new("Literal")` only. Handed a 726-line UI script written with
// the other common idiom -
//
//     local function new(className, properties, parent) ... end
//     local title = new("TextLabel", { TextSize = 16, ... }, header)
//
// - it resolved zero elements, found zero text sizes, zero radii, zero
// buttons, and reported a perfect score. It passed by blindness, which is
// worse than failing: it teaches you the file was checked.
//
// So construction is resolved into one model first, and every check reads the
// model. Two forms are understood:
//
//   A  local v = Instance.new("Class")   then  v.Prop = value,  v.Parent = p
//   B  local v = helper("Class", { Prop = value, ... }, parent)
//
// Form B's helper may be called anything. The string literal naming a GUI
// class, followed by a table, is the signal - that is what makes it decidable
// without resolving the function.

import { loadDump } from "./dump.mjs";

function descendantsOf(classes, root) {
  const names = new Set();
  for (const [name, record] of classes) {
    let current = name;
    while (current) {
      if (current === root && name !== root) {
        names.add(name);
        break;
      }
      current = classes.get(current)?.superclass;
    }
  }
  return names;
}

const classes = loadDump().classes;

/** Frame, TextLabel, ScrollingFrame and the rest of the drawable surfaces. */
export const GUI_OBJECTS = descendantsOf(classes, "GuiObject");
/** UICorner, UIListLayout, UIPadding - the modifiers that attach to one. */
export const UI_MODIFIERS = descendantsOf(classes, "UIBase");
/** ScreenGui, BillboardGui, SurfaceGui. */
export const LAYER_COLLECTORS = descendantsOf(classes, "LayerCollector");

export const ALL_GUI_CLASSES = new Set([...GUI_OBJECTS, ...UI_MODIFIERS, ...LAYER_COLLECTORS]);

/** Classes that render a `Text` property, and the string the engine shows
 *  when nothing sets it. */
export const DEFAULT_TEXT = new Map([
  ["TextLabel", "Label"],
  ["TextButton", "Button"],
  ["TextBox", "TextBox"],
]);

/** Strip comments. Strings are kept: `Text = "x"` is a value this reads. */
export function stripComments(source) {
  return source
    .replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, (match) => match.replace(/[^\n]/g, " "))
    .replace(/--[^\n]*/g, "");
}

export function lineOf(source, index) {
  return source.slice(0, index).split("\n").length;
}

/** Index of the `}` matching the `{` at `open`, skipping string contents. */
function matchBrace(source, open) {
  let depth = 0;
  for (let i = open; i < source.length; i += 1) {
    const char = source[i];
    if (char === '"' || char === "'") {
      const quote = char;
      i += 1;
      while (i < source.length && source[i] !== quote) {
        if (source[i] === "\\") i += 1;
        i += 1;
      }
      continue;
    }
    if (char === "{") depth += 1;
    else if (char === "}") {
      depth -= 1;
      if (depth === 0) return i;
    }
  }
  return -1;
}

/** Top-level `Key = value` pairs of a table body, ignoring nested tables. */
function parseTable(body) {
  const props = new Map();
  let depth = 0;
  let start = 0;
  const entries = [];
  for (let i = 0; i < body.length; i += 1) {
    const char = body[i];
    if (char === '"' || char === "'") {
      const quote = char;
      i += 1;
      while (i < body.length && body[i] !== quote) {
        if (body[i] === "\\") i += 1;
        i += 1;
      }
      continue;
    }
    if (char === "{" || char === "(" || char === "[") depth += 1;
    else if (char === "}" || char === ")" || char === "]") depth -= 1;
    else if (char === "," && depth === 0) {
      entries.push(body.slice(start, i));
      start = i + 1;
    }
  }
  entries.push(body.slice(start));

  for (const entry of entries) {
    const match = /^\s*([A-Za-z_]\w*)\s*=\s*([\s\S]+?)\s*$/.exec(entry);
    if (match) props.set(match[1], match[2].replace(/\s+/g, " "));
  }
  return props;
}

/**
 * The value of an assignment starting at `from`, continuing past newlines
 * while brackets are still open.
 *
 *     corner.CornerRadius = UDim.new(
 *         0,
 *         radius
 *     )
 *
 * is one value. Stopping at the first newline records `UDim.new(`, which reads
 * as an unparseable expression and quietly drops the radius from the count.
 */
function valueFrom(source, from) {
  let depth = 0;
  for (let i = from; i < source.length; i += 1) {
    const char = source[i];
    if (char === '"' || char === "'") {
      const quote = char;
      i += 1;
      while (i < source.length && source[i] !== quote) {
        if (source[i] === "\\") i += 1;
        i += 1;
      }
      continue;
    }
    if (char === "(" || char === "{" || char === "[") depth += 1;
    else if (char === ")" || char === "}" || char === "]") depth -= 1;
    else if (char === "\n" && depth <= 0) {
      return source.slice(from, i);
    }
  }
  return source.slice(from);
}

/**
 * Every GUI object the file constructs.
 * @returns {{elements: Array, blind: boolean, classLiterals: number}}
 */
export function parseElements(rawSource) {
  const code = stripComments(rawSource);
  const elements = [];

  // Constructions and property assignments are walked in source order against
  // a live binding table. A file that writes `local layout = ...` in four
  // functions has four layouts, and folding all four into the first one both
  // hides real findings and invents false ones.
  const events = [];
  const consumed = [];

  // --- form B: helper("Class", { ... }, parent) ---------------------------
  const helperCall = /(?:local\s+([A-Za-z_]\w*)\s*=\s*)?([A-Za-z_][\w.:]*)\s*\(\s*["']([A-Za-z]+)["']\s*,\s*\{/g;
  for (const match of code.matchAll(helperCall)) {
    const className = match[3];
    if (!ALL_GUI_CLASSES.has(className)) continue;
    if (/^Instance\.new$/.test(match[2])) continue; // handled below
    const open = match.index + match[0].length - 1;
    const close = matchBrace(code, open);
    if (close === -1) continue;
    const parentMatch = /^\s*,\s*([A-Za-z_][\w.]*)/.exec(code.slice(close + 1, close + 200));
    events.push({
      kind: "construct",
      index: match.index,
      element: {
        variable: match[1] ?? null,
        class: className,
        line: lineOf(code, match.index),
        sourceIndex: match.index,
        parent: parentMatch ? parentMatch[1] : null,
        parentLine: parentMatch ? lineOf(code, match.index) : null,
        props: parseTable(code.slice(open + 1, close)),
        propLines: new Map(),
        form: "table",
      },
    });
    consumed.push([match.index, close]);
  }

  // --- form A: Instance.new("Class") --------------------------------------
  for (const match of code.matchAll(
    /(?:local\s+([A-Za-z_]\w*)\s*=\s*)?Instance\.new\(\s*["']([A-Za-z]+)["']\s*(?:,\s*([A-Za-z_][\w.]*)\s*)?\)/g
  )) {
    const className = match[2];
    if (!ALL_GUI_CLASSES.has(className)) continue;
    events.push({
      kind: "construct",
      index: match.index,
      element: {
        variable: match[1] ?? null,
        class: className,
        line: lineOf(code, match.index),
        sourceIndex: match.index,
        parent: match[3] ?? null,
        parentLine: match[3] ? lineOf(code, match.index) : null,
        props: new Map(),
        propLines: new Map(),
        form: "instance",
      },
    });
  }

  const inConsumed = (index) => consumed.some(([from, to]) => index > from && index < to);
  for (const match of code.matchAll(/\b([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*=\s*(?=[^\n=])/g)) {
    if (inConsumed(match.index)) continue;
    const value = valueFrom(code, match.index + match[0].length);
    events.push({
      kind: "assign",
      index: match.index,
      variable: match[1],
      key: match[2],
      value: value.replace(/,\s*$/, "").replace(/\s+/g, " ").trim(),
    });
  }

  events.sort((a, b) => a.index - b.index);

  const live = new Map();
  for (const event of events) {
    if (event.kind === "construct") {
      elements.push(event.element);
      if (event.element.variable) live.set(event.element.variable, event.element);
      continue;
    }
    const element = live.get(event.variable);
    if (!element) continue;
    const line = lineOf(code, event.index);
    if (event.key === "Parent") {
      if (!element.parent) {
        element.parent = event.value;
        element.parentLine = line;
      }
      continue;
    }
    if (!element.props.has(event.key)) {
      element.props.set(event.key, event.value);
      element.propLines.set(event.key, line);
    }
    element.assignedLater ??= new Set();
    element.assignedLater.add(event.key);
  }

  expandAttachers(code, elements);

  const byVariable = new Map();
  for (const element of elements) {
    if (element.variable && !byVariable.has(element.variable)) byVariable.set(element.variable, element);
  }

  // How many GUI class names the file names at all. If that is several and
  // nothing resolved, the parser is the thing that is wrong.
  let classLiterals = 0;
  for (const match of rawSource.matchAll(/["']([A-Za-z]+)["']/g)) {
    if (ALL_GUI_CLASSES.has(match[1])) classLiterals += 1;
  }

  return {
    elements,
    byVariable,
    classLiterals,
    blind: elements.length === 0 && classLiterals >= 5,
  };
}

// --- helpers that attach a modifier to whatever they are handed -----------
//
// The second blind spot, found the same way as the first. A file that writes
//
//     local function addFlexFill(parent)
//         local flex = Instance.new("UIFlexItem")
//         flex.FlexMode = Enum.UIFlexMode.Fill
//         flex.Parent = parent
//     end
//     addFlexFill(title)
//
// has a UIFlexItem on `title`, but the construction names the PARAMETER as its
// parent, so nothing links it to the element. Three dead `Size` values hid
// behind exactly this in a real generated file.
//
// So: find functions whose body parents a modifier to one of their own
// parameters, then replay that at every call site with the call's arguments
// substituted in. The definition's own copy stays flagged as a template and is
// not counted, or one `addCorner` helper would read as a radius of its own.

/** Span of every `function name(params)`, matched to its `end`. */
export function functionSpans(code) {
  const spans = [];
  for (const match of code.matchAll(/(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(([^)]*)\)/g)) {
    const params = match[2]
      .split(",")
      .map((name) => name.trim())
      .filter((name) => /^[A-Za-z_]\w*$/.test(name));
    if (params.length === 0) continue;

    // `for`/`while` always reach a `do`, so counting `do` covers both without
    // double counting. `elseif` and `then` open nothing.
    let depth = 0;
    let end = -1;
    const words = /[A-Za-z_]\w*/g;
    words.lastIndex = match.index;
    let word;
    while ((word = words.exec(code)) !== null) {
      const text = word[0];
      if (text === "function" || text === "if" || text === "do" || text === "repeat") depth += 1;
      else if (text === "end" || text === "until") {
        depth -= 1;
        if (depth === 0) {
          end = word.index;
          break;
        }
      }
    }
    if (end !== -1) spans.push({ name: match[1], params, start: match.index, end });
  }
  return spans;
}

/** Split a call's argument list at depth zero. */
function splitArguments(text) {
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

/** The `)` matching the `(` at `open`. */
function matchParen(source, open) {
  let depth = 0;
  for (let i = open; i < source.length; i += 1) {
    const char = source[i];
    if (char === '"' || char === "'") {
      const quote = char;
      i += 1;
      while (i < source.length && source[i] !== quote) {
        if (source[i] === "\\") i += 1;
        i += 1;
      }
      continue;
    }
    if (char === "(") depth += 1;
    else if (char === ")") {
      depth -= 1;
      if (depth === 0) return i;
    }
  }
  return -1;
}

/**
 * Replay modifier-attaching helpers at their call sites.
 * Mutates `elements`: templates get `template = true`, and one synthesized
 * element is appended per call.
 */
export function expandAttachers(code, elements) {
  const spans = functionSpans(code);
  if (spans.length === 0) return elements;

  /** helperName -> [{ element, paramIndex }] */
  const attachers = new Map();

  for (const span of spans) {
    for (const element of elements) {
      if (element.line === undefined) continue;
      const index = element.sourceIndex;
      if (index === undefined || index < span.start || index > span.end) continue;
      const paramIndex = span.params.indexOf(element.parent);
      if (paramIndex === -1) continue;
      if (!UI_MODIFIERS.has(element.class)) continue;
      element.template = true;
      if (!attachers.has(span.name)) attachers.set(span.name, { span, attached: [] });
      attachers.get(span.name).attached.push({ element, paramIndex });
    }
  }

  for (const [name, { span, attached }] of attachers) {
    const callPattern = new RegExp(`(?<![\\w.:])${name}\\s*\\(`, "g");
    for (const call of code.matchAll(callPattern)) {
      const open = call.index + call[0].length - 1;
      if (open > span.start && open < span.end) continue; // recursion inside itself
      const close = matchParen(code, open);
      if (close === -1) continue;
      const args = splitArguments(code.slice(open + 1, close));

      // Bind the call's literal arguments to the helper's parameter names so
      // `addCorner(panel, 10)` yields a radius of 10 rather than `radius`.
      const bound = new Map();
      span.params.forEach((param, index) => {
        const argument = args[index];
        if (argument !== undefined && argument !== "") bound.set(param, argument);
      });

      for (const { element, paramIndex } of attached) {
        const target = args[paramIndex];
        if (!target || !/^[A-Za-z_]\w*$/.test(target)) continue;
        const props = new Map();
        for (const [key, value] of element.props) {
          props.set(
            key,
            value.replace(/\b[A-Za-z_]\w*\b/g, (word) => (bound.has(word) ? bound.get(word) : word))
          );
        }
        elements.push({
          variable: null,
          class: element.class,
          line: lineOf(code, call.index),
          parent: target,
          parentLine: lineOf(code, call.index),
          props,
          propLines: new Map(),
          form: "attached",
        });
      }
    }
  }

  return elements;
}

/** Children of `element`, by the variable it was bound to. */
export function indexChildren(elements) {
  const children = new Map();
  for (const element of elements) {
    if (!element.parent) continue;
    if (!children.has(element.parent)) children.set(element.parent, []);
    children.get(element.parent).push(element);
  }
  return children;
}

/**
 * Numeric constants a file binds exactly once, so an expression written with
 * names can be read the same way as one written with literals.
 *
 * Without this the rubric is strictest on the code that names its numbers and
 * blindest to the code that sprays them, which is backwards. `UDim.new(0,
 * GAP_BASE)` is the good version of `UDim.new(0, 8)` and both must count.
 *
 * Bound more than once means it is a variable, not a constant, and is skipped.
 */
export function numericConstants(source) {
  const code = stripComments(source);
  const counts = new Map();
  const values = new Map();

  for (const match of code.matchAll(/^[^\S\n]*local[^\S\n]+([A-Za-z_][\w,\s]*?)[^\S\n]*=([^\n]+)$/gm)) {
    const names = match[1].split(",").map((name) => name.trim());
    if (names.some((name) => !/^[A-Za-z_]\w*$/.test(name))) continue;
    const parts = splitTopLevelCommas(match[2]);
    names.forEach((name, index) => {
      counts.set(name, (counts.get(name) ?? 0) + 1);
      const value = Number((parts[index] ?? "").trim().replace(/_/g, ""));
      if (Number.isFinite(value)) values.set(name, value);
    });
  }

  const resolved = new Map();
  for (const [name, value] of values) {
    if (counts.get(name) === 1) resolved.set(name, value);
  }
  return resolved;
}

function splitTopLevelCommas(text) {
  const parts = [];
  let depth = 0;
  let start = 0;
  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (char === "(" || char === "{" || char === "[") depth += 1;
    else if (char === ")" || char === "}" || char === "]") depth -= 1;
    else if (char === "," && depth === 0) {
      parts.push(text.slice(start, i));
      start = i + 1;
    }
  }
  parts.push(text.slice(start));
  return parts;
}

/** Substitutes known constants into an expression before it is parsed. */
export function makeResolver(source) {
  const constants = numericConstants(source);
  if (constants.size === 0) return (expression) => expression;
  return (expression) =>
    typeof expression === "string"
      ? expression.replace(/\b[A-Za-z_]\w*\b/g, (name) =>
          constants.has(name) ? String(constants.get(name)) : name
        )
      : expression;
}

const NUMBER = "-?\\d+(?:\\.\\d+)?";

/** Scale components of a UDim2 expression, or null if it is not a literal. */
export function scaleOf(expression) {
  if (!expression) return null;
  let match = new RegExp(`UDim2\\.fromScale\\(\\s*(${NUMBER})\\s*,\\s*(${NUMBER})\\s*\\)`).exec(expression);
  if (match) return { x: Number(match[1]), y: Number(match[2]) };
  match = new RegExp(
    `UDim2\\.new\\(\\s*(${NUMBER})\\s*,\\s*${NUMBER}\\s*,\\s*(${NUMBER})\\s*,\\s*${NUMBER}\\s*\\)`
  ).exec(expression);
  if (match) return { x: Number(match[1]), y: Number(match[2]) };
  if (/UDim2\.fromOffset\(/.test(expression)) return { x: 0, y: 0 };
  return null;
}

/** Offset components of a UDim2 expression, or null. */
export function offsetOf(expression) {
  if (!expression) return null;
  let match = new RegExp(`UDim2\\.fromOffset\\(\\s*(${NUMBER})\\s*,\\s*(${NUMBER})\\s*\\)`).exec(expression);
  if (match) return { x: Number(match[1]), y: Number(match[2]) };
  match = new RegExp(
    `UDim2\\.new\\(\\s*${NUMBER}\\s*,\\s*(${NUMBER})\\s*,\\s*${NUMBER}\\s*,\\s*(${NUMBER})\\s*\\)`
  ).exec(expression);
  if (match) return { x: Number(match[1]), y: Number(match[2]) };
  if (/UDim2\.fromScale\(/.test(expression)) return { x: 0, y: 0 };
  return null;
}

export function vector2Of(expression) {
  if (!expression) return null;
  const match = new RegExp(`Vector2\\.new\\(\\s*(${NUMBER})\\s*,\\s*(${NUMBER})\\s*\\)`).exec(expression);
  return match ? { x: Number(match[1]), y: Number(match[2]) } : null;
}

/** The single offset of a `UDim.new(0, n)`, or null. */
export function udimOffset(expression) {
  if (!expression) return null;
  const match = new RegExp(`UDim\\.new\\(\\s*0(?:\\.0+)?\\s*,\\s*(${NUMBER})\\s*\\)`).exec(expression);
  return match ? Number(match[1]) : null;
}
