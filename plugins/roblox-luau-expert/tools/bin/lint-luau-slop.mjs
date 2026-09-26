#!/usr/bin/env node
// Count the machine-written tells in a real Luau file.
//
// roblox-code-craft has said "comment the why, not the what" since v1, and
// models keep shipping a thirteen-line provenance essay above a sixty-line
// script anyway. Prose does not bind a weak model. A command that exits 1 does.
//
// This is the code half of what lint-roblox-ui.mjs is for interfaces: every
// check is decidable from the text of a file, nothing here needs taste, and
// anything that needed taste was left in the reference.
//
// Calibration rule, same as the UI linter: a finding the author already
// handled teaches you to stop reading the output. Every check below runs clean
// on library/src, which is hand-written code this stack considers correct.
//
// Usage:
//   node tools/bin/lint-luau-slop.mjs <file.luau> [more.luau ...]
//   node tools/bin/lint-luau-slop.mjs <directory>
//   node tools/bin/lint-luau-slop.mjs --json <file.luau>
//   node tools/bin/lint-luau-slop.mjs --compare <before.luau> <after.luau>
//   cat script.luau | node tools/bin/lint-luau-slop.mjs --stdin
//
// Exit 1 on any E-* finding. W-* are reported and do not fail.

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

// A file that executes on load carries no header. A module may explain the
// decisions behind its public surface, which takes more room.
const MAX_HEADER_LINES_SCRIPT = 4;
const MAX_HEADER_LINES_MODULE = 24;

// One guard, not a guard per function. Three separate `if typeof(x)` statements
// is the point where it should have been one assert.
const MAX_CAPABILITY_STATEMENTS = 2;

// An error message is a search key, not a paragraph.
const MAX_MESSAGE_WORDS = 12;

// Three call sites repeating the same literal prefix is a constant that was
// never declared.
const MAX_REPEATED_PREFIX = 2;

// Section banners are navigation. Below this many lines there is nothing to
// navigate.
const BANNER_MIN_CODE_LINES = 120;

// Deliberately loose. A teaching module that explains every decision is not
// slop; line-by-line narration runs at 80% and up, which is what this catches.
const MAX_COMMENT_RATIO = 0.55;
const MIN_LINES_FOR_RATIO = 40;

const MAX_PCALL_PER_CODE_LINE = 1 / 25;
const MIN_PCALLS_FOR_DENSITY = 4;

// Comments that narrate where the code came from rather than what it does.
// This is the single clearest tell in generated Luau: it addresses the reader
// of a conversation, not the reader of a file.
const PROVENANCE = [
  /\bbased (on|upon) the (uploaded|supplied|provided|attached|given|pasted)\b/i,
  /\bthe (uploaded|supplied|provided|attached|pasted|original) (source|script|dump|file|code|listing)\b/i,
  /\bsource[- ]established\b/i,
  /\bthe dump (has|shows|contains|establishes|gave|told)\b/i,
  /\bas (you |we )?(requested|asked|discussed)\b/i,
  /\bper your\b/i,
  /\byou (asked|provided|uploaded|supplied|gave|wanted|mentioned)\b/i,
  /\bthis (version|revision|implementation|rewrite)\b/i,
  /\bi (have|will|would|can|am)\b/i,
  /\b(note|notice) that\b/i,
  /\b(originally|previously) (generated|written|produced|suggested)\b/i,
  /\b(unlike|instead of) the (previous|earlier|first) (version|attempt|script)\b/i,
];

// Narrating the edit rather than the code. Distinct from PROVENANCE: these
// appear when a model is handed a working file and asked to change it, and
// they describe the diff - which git already holds, in a place that stays
// correct when the next edit lands. Only the comment-initial position counts:
// "the part is no longer parented while idle" is a fact about the game and
// must not be caught.
const EDIT_NARRATION = [
  /^(fixed|fix|changed|change|updated|update|added|add|removed|remove|renamed|replaced|refactored|moved|new|old|was|before|after)\s*[:\u2014-]/i,
  /^(fixed|changed|updated|added|removed|renamed|replaced|moved|switched|converted)\s+(the|this|a|an|it|from|to)\b/i,
  /\bin (this|the) (fix|patch|update|revision|edit|change|rewrite)\b/i,
  /\b(previously|formerly|originally),? (this|it|the (code|script|function|line))\b/i,
  /\bkept for (backwards |backward )?compat/i,
];

// A comment that is only a file name. The file already has one, and a rename
// leaves this lying.
const FILENAME_COMMENT = /^[A-Za-z_][\w.-]*\.(lua|luau|client\.lua|server\.lua)$/i;

// Header lines that summarise the code below instead of carrying a fact from
// outside it. The header budget caps how MANY lines there are; this caps what
// they are allowed to be about. Four lines of this passed the length cap:
//
//   -- NotificationDemo.client.lua
//   -- This interface is client-owned and never stores authoritative game state.
//   -- The close image is Roblox Creator Hub asset 5577404210.
//   -- Connections and delayed threads are torn down with the ScreenGui.
//
// Line one is the file name. Line two restates a rule every file here follows.
// Line three restates the constant below it. Line four restates the teardown
// function. None of them survive contact with the code changing.
const HEADER_SUMMARY = [
  /^(handles|manages|creates|builds|renders|displays|provides|implements|sets up|defines)\b/i,
  /^this (script|module|interface|file|ui|code|system|panel|menu|component)\b/i,
  /\bclient[- ]owned\b/i,
  /\bnever stores? (any )?authoritative\b/i,
  /\b(server|client)[- ]authoritative\b/i,
  /\bclient[- ]side only\b/i,
  /\b(connections?|threads?|tweens?|listeners?|signals?)\b[^.]{0,60}\b(torn down|tear down|cleaned up|disconnected|destroyed|cancelled|canceled)\b/i,
  /\b(torn down|cleaned up|disconnected) (with|when|on) the\b/i,
];

// Comment text that is Lua rather than English.
const COMMENTED_OUT = [
  /^\s*local\s+[\w.]+\s*=/,
  /^\s*function\s+[\w.:]*\s*\(/,
  /^\s*end\)?[,;]?\s*$/,
  /^\s*return\s+\w/,
  /^\s*(if|elseif)\s+.+\bthen\s*$/,
  /^\s*(for|while)\s+.+\bdo\s*$/,
  /^\s*[\w.]+[:.][\w]+\(.*\)\s*$/,
];

// Calls that construct a value and cannot raise. A pcall around only these is
// wrapping nothing.
const INFALLIBLE_CALLS =
  /^(Vector2|Vector3|Vector2int16|Vector3int16|CFrame|Color3|UDim|UDim2|Rect|NumberRange|Region3|TweenInfo|BrickColor)\.(new|from[A-Za-z]+)$|^(tostring|tonumber|math\.[a-z]+|table\.create)$/;

// Calls that genuinely can raise, so a pcall around them is correct.
const FALLIBLE_HINT =
  /\b(require|GetAsync|SetAsync|UpdateAsync|RemoveAsync|HttpGet|HttpPost|request|InvokeServer|InvokeClient|Invoke|WaitForChild|getsenv|getrenv|getgenv|getgc|filtergc|hookfunction|hookmetamethod|getcustomasset|writefile|readfile|loadstring|decompile|JSONDecode|JSONEncode|GetProductInfo|PromptPurchase|SetPrimaryPartCFrame|error|assert)\b|\bdebug\.[a-z]/;

const SUCCESS_NARRATION =
  /\b(enabled|loaded|unloaded|initiali[sz]ed|success|successfully|ready|complete|completed|done|started|starting|installed|injected|executing|running|active|attached)\b/i;

// Text a player reads: labels, descriptions, notices, placeholders.
const PLAYER_TEXT =
  /\b(Text|Title|Description|Content|Subtitle|PlaceholderText|Name)\s*=\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)')/g;

const HYPE_WORDS =
  /\b(seamless(?:ly)?|effortless(?:ly)?|unleash(?:es|ed)?|elevate[sd]?|powerful|cutting-edge|next-level|supercharge[sd]?|blazing(?:ly)?|lightning-fast|successfully|the power of|experience the)\b/i;

const PROSE_IN_MESSAGE =
  /\b(refusing to|please|make sure|you should|you can|try again|likely|probably|appears to|seems to|it looks like|in order to|so that|because of this|for some reason)\b/i;

// A causal or contrastive connective is what makes a comment a "why".
const CONNECTIVE =
  /\b(because|so that|otherwise|since|but|which|rather than|instead of|would|will|cannot|can't|does not|doesn't|must|only|never|always|even|unless|until|per|see|avoids?|prevents?|breaks?|fails?|wrong|safe|deliberate|on purpose|beware)\b/i;

const STOPWORDS = new Set([
  "the", "a", "an", "and", "or", "but", "for", "with", "from", "into", "onto",
  "this", "that", "these", "those", "its", "it's", "is", "are", "was", "were",
  "be", "been", "being", "to", "of", "in", "on", "at", "by", "as", "we", "you",
  "not", "no", "all", "any", "each", "every", "one", "two", "here", "there",
  "when", "then", "than", "so", "if", "it", "our", "their", "them", "they",
]);

const GENERIC_LOCALS = new Set([
  "data", "temp", "tmp", "obj", "val", "info", "stuff", "thing", "things",
  "arr", "dict", "payload", "cfg", "ctx", "elem", "misc", "helper", "manager",
  "utils", "util", "handler", "res", "ret", "vars", "stuff2", "processor",
]);

// Decompiler output has no names. `v14`, `u3` and `p1` are slot numbers the
// decompiler printed because the real names were compiled away. Carrying them
// into delivered code means nobody - including the author next week - can read
// it, and it is the single loudest sign the source was copied rather than read.
const DECOMPILER_NAME = /^(?:[vup]|arg|var|upv)_?\d+$/i;

// The layers a value can live on in a running client. Each row is a different
// OBJECT reached by a different mechanism, so falling back from one to the next
// does not retry the same lookup - it edits something else and reports success.
// Two layers in a file is a hook plus a read. Three is guessing.
const VALUE_LAYERS = {
  upvalue: /\b(?:debug\.)?(?:get|set)upvalue(?:s)?\b/g,
  constant: /\b(?:debug\.)?(?:get|set)constant(?:s)?\b/g,
  environment: /\b(?:getsenv|getrenv|getfenv|setfenv|getmenv)\b/g,
  heap: /\b(?:getgc|filtergc|getinstances|getnilinstances|getloadedmodules)\b/g,
  hook: /\b(?:hookfunction|hookmetamethod|replaceclosure|newcclosure|restorefunction)\b/g,
  connection: /\b(?:getconnections|firesignal|replicatesignal)\b/g,
};

// Two executors' names for one function are an alias, not a fallback. Resolving
// `getcustomasset or getsynasset` once at the top is correct and must not fire.
const EXECUTOR_ALIASES = [
  new Set(["getcustomasset", "getsynasset"]),
  new Set(["gethui", "get_hidden_gui"]),
  new Set(["setclipboard", "toclipboard", "setrbxclipboard"]),
  new Set(["request", "http_request", "httprequest"]),
  new Set(["getexecutorname", "identifyexecutor"]),
];

// Every documented executor global, for the surface count. Not a capability
// list - it is here to notice when a single-purpose script has reached for
// twelve different mechanisms, which happens when the dump was never read.
const EXECUTOR_GLOBALS =
  /\b(?:getgenv|getrenv|getsenv|getfenv|setfenv|getmenv|getgc|filtergc|getinstances|getnilinstances|getloadedmodules|getscripts|getrunningscripts|getconnections|firesignal|replicatesignal|hookfunction|hookmetamethod|replaceclosure|newcclosure|restorefunction|checkcaller|islclosure|iscclosure|isexecutorclosure|clonefunction|getcallingscript|getscriptbytecode|getscripthash|decompile|gethui|get_hidden_gui|getcustomasset|getsynasset|setclipboard|toclipboard|readfile|writefile|appendfile|isfile|isfolder|makefolder|delfile|delfolder|listfiles|loadstring|setidentity|getidentity|getthreadidentity|setthreadidentity|setscriptable|gethiddenproperty|sethiddenproperty|getrawmetatable|setrawmetatable|setreadonly|isreadonly|getnamecallmethod|setnamecallmethod|getcallbackvalue|fireclickdetector|fireproximityprompt|firetouchinterest|queue_on_teleport|queueonteleport|getexecutorname|identifyexecutor|messagebox|setfpscap|mousemoverel|keypress|keyrelease)\b/g;

// Clauses that carry a cause, a contrast or a constraint are the point of a
// comment. A clause with none of these and nothing but the identifiers below it
// is the line spelled twice, however load-bearing its neighbours are.
const CLAUSE_SPLIT = /(?:[.;]\s+|\s+(?:so|because|since|which|but|however)\s+|\s+-\s+|\s+—\s+)/;
const MIN_CLAUSE_WORDS = 3;
const CLAUSE_ECHO_RATIO = 0.75;
const CLAUSE_LOOKAHEAD = 6;

// Three layers, or this many distinct globals, in one single-purpose script.
const MAX_VALUE_LAYERS = 2;
const MAX_EXECUTOR_SURFACE = 5;

const BAD_ABBREVIATIONS = new Set([
  "plr", "plrs", "chr", "pos", "cnt", "tbl", "str", "num", "idx", "btn", "txt",
  "evt", "dmg", "lvl", "spd", "amt", "qty", "desc", "scr", "inst", "wep", "itm",
  "clr", "bg", "fg", "hdl", "mgr", "ply", "hum", "wrkspc", "rs", "ws",
]);

/**
 * Split a file into code text and comment units.
 *
 * A character walk rather than a regex, because `local s = "a -- b"` is not a
 * comment and `--[[ ]]` spans lines. Consecutive `--` lines are joined into one
 * unit: a wrapped comment is one thought, and scoring its continuation lines
 * separately produces findings about half-sentences.
 */
function scan(source) {
  // A UTF-8 BOM is one non-whitespace character on line 1, so without this the
  // scanner reads line 1 as code, every header comment sorts after it, and the
  // header rules stop firing on exactly the files a Windows editor saved.
  if (source.charCodeAt(0) === 0xfeff) source = source.slice(1);
  const rawLines = source.split(/\r?\n/);
  const codeLines = rawLines.map(() => "");
  const comments = [];

  let index = 0;
  let line = 0;
  let pendingRun = null;

  const flushRun = () => {
    if (pendingRun) comments.push(pendingRun);
    pendingRun = null;
  };

  const longBracket = (at) => {
    if (source[at] !== "[") return null;
    let cursor = at + 1;
    let level = 0;
    while (source[cursor] === "=") {
      level += 1;
      cursor += 1;
    }
    return source[cursor] === "[" ? { level, end: cursor + 1 } : null;
  };

  while (index < source.length) {
    const char = source[index];

    if (char === "\n") {
      line += 1;
      index += 1;
      continue;
    }

    if (char === "-" && source[index + 1] === "-") {
      const bracket = longBracket(index + 2);
      if (bracket) {
        const closer = `]${"=".repeat(bracket.level)}]`;
        const close = source.indexOf(closer, bracket.end);
        const stop = close === -1 ? source.length : close + closer.length;
        const body = source.slice(bracket.end, close === -1 ? source.length : close);
        flushRun();
        comments.push({
          line: line + 1,
          text: body.trim(),
          block: true,
          lines: body.split("\n").length,
          parts: body.split("\n").map((part, offset) => ({ line: line + 1 + offset, text: part.trim() })),
        });
        for (const character of source.slice(index, stop)) if (character === "\n") line += 1;
        index = stop;
        continue;
      }

      let stop = source.indexOf("\n", index);
      if (stop === -1) stop = source.length;
      const body = source.slice(index + 2, stop).trim();
      const hasCodeBefore = codeLines[line].trim().length > 0;

      if (hasCodeBefore) {
        // A trailing comment annotates one line; it is never a header, a
        // banner or commented-out code.
        flushRun();
        comments.push({
          line: line + 1,
          text: body,
          block: false,
          trailing: true,
          lines: 1,
          parts: [{ line: line + 1, text: body }],
        });
      } else if (pendingRun && pendingRun.endLine === line) {
        pendingRun.text += ` ${body}`;
        pendingRun.endLine = line + 1;
        pendingRun.lines += 1;
        pendingRun.parts.push({ line: line + 1, text: body });
      } else {
        flushRun();
        pendingRun = {
          line: line + 1,
          text: body,
          block: false,
          endLine: line + 1,
          lines: 1,
          parts: [{ line: line + 1, text: body }],
        };
      }

      index = stop;
      continue;
    }

    if (char === '"' || char === "'") {
      let cursor = index + 1;
      while (cursor < source.length && source[cursor] !== char) {
        if (source[cursor] === "\\") cursor += 1;
        if (source[cursor] === "\n") break;
        cursor += 1;
      }
      codeLines[line] += source.slice(index, cursor + 1);
      index = cursor + 1;
      flushRun();
      continue;
    }

    const bracket = longBracket(index);
    if (bracket) {
      const closer = `]${"=".repeat(bracket.level)}]`;
      const close = source.indexOf(closer, bracket.end);
      const stop = close === -1 ? source.length : close + closer.length;
      codeLines[line] += '""';
      for (const character of source.slice(index, stop)) if (character === "\n") line += 1;
      index = stop;
      flushRun();
      continue;
    }

    codeLines[line] += char;
    index += 1;
    if (char.trim().length > 0) flushRun();
  }

  flushRun();
  return { codeLines, comments, rawLines };
}

/** camelCase, PascalCase and snake_case into lowercase word stems. */
function identifierWords(text) {
  const words = new Set();
  for (const token of text.split(/[^A-Za-z]+/)) {
    if (!token) continue;
    for (const part of token.replace(/([a-z0-9])([A-Z])/g, "$1 $2").split(/\s+/)) {
      const word = part.toLowerCase().replace(/s$/, "");
      if (word.length >= 3) words.add(word);
    }
  }
  return words;
}

function contentWords(text) {
  return [...new Set(
    text
      .toLowerCase()
      .split(/[^a-z0-9']+/)
      .filter((word) => word.length >= 3 && !STOPWORDS.has(word))
      .map((word) => word.replace(/s$/, ""))
  )];
}

function wordCount(text) {
  return text.split(/\s+/).filter(Boolean).length;
}

function analyse(rawSource, rel) {
  const { codeLines, comments } = scan(rawSource);
  const findings = [];
  const add = (code, line, message) => findings.push({ code, line, message, file: rel });

  const code = codeLines.join("\n");
  const codeLineCount = codeLines.filter((text) => text.trim().length > 0).length;
  const commentLineCount = comments.reduce((total, unit) => total + (unit.trailing ? 0 : unit.lines), 0);

  // A ModuleScript ends by returning its table. Anything else runs on load, and
  // a script that runs on load has no public surface to document.
  const isModule = /\breturn\s+[A-Za-z_][\w.]*\s*(?:\([\s\S]*\))?\s*$/.test(code.trimEnd());

  const firstCodeLine = codeLines.findIndex((text) => text.trim().length > 0 && !/^--!/.test(text.trim()));

  // --- header -------------------------------------------------------------
  const headerUnits = comments.filter(
    (unit) => !unit.trailing && (firstCodeLine === -1 || unit.line <= firstCodeLine)
  );
  const headerLines = headerUnits.reduce((total, unit) => total + unit.lines, 0);
  for (const unit of headerUnits) {
    for (const part of unit.parts ?? []) {
      const text = part.text.trim();
      if (!text) continue;
      for (const pattern of HEADER_SUMMARY) {
        if (!pattern.test(text)) continue;
        add(
          "E-HEADERSUMMARY",
          part.line,
          `header line summarises the code instead of carrying a fact from outside it: ` +
            `"${text.slice(0, 60)}". The code below already says this, and stays right when it changes.`
        );
        break;
      }
    }
  }

  const headerCap = isModule ? MAX_HEADER_LINES_MODULE : MAX_HEADER_LINES_SCRIPT;
  if (headerLines > headerCap) {
    add(
      "E-HEADER",
      headerUnits[0]?.line ?? 1,
      `${headerLines}-line header on a ${isModule ? "module" : "script"} (cap ${headerCap}). ` +
        `A header carries decisions the code cannot show, not a summary of it.`
    );
  }

  // --- what the comments are about ----------------------------------------
  let labelCount = 0;
  for (const unit of comments) {
    const text = unit.text.trim();
    if (!text) continue;

    for (const pattern of PROVENANCE) {
      if (pattern.test(text)) {
        add(
          "E-PROVENANCE",
          unit.line,
          `comment narrates where the code came from: "${text.slice(0, 64)}". ` +
            `Say that in the reply; the file is read by someone who was not in the conversation.`
        );
        break;
      }
    }

    for (const pattern of EDIT_NARRATION) {
      if (pattern.test(text)) {
        add(
          "E-EDITNOTE",
          unit.line,
          `comment narrates the edit rather than the code: "${text.slice(0, 64)}". ` +
            `The diff already says what changed, and stays right when the next edit lands.`
        );
        break;
      }
    }

    for (const part of unit.parts ?? []) {
      const partText = part.text.trim();
      if (!FILENAME_COMMENT.test(partText)) continue;
      add(
        "E-FILENAME",
        part.line,
        `comment is the file name: "${partText}". The file already has one, and a rename leaves this behind.`
      );
    }

    if (/\b(TODO|FIXME|XXX|HACK)\b/.test(text)) {
      add("E-TODO", unit.line, `"${text.slice(0, 48)}" - resolve it or drop it before delivery.`);
    }

    if (!unit.block && !unit.trailing) {
      for (const pattern of COMMENTED_OUT) {
        if (pattern.test(text) && text.length <= 90) {
          add("E-QUOTE", unit.line, `commented-out code: "${text.slice(0, 56)}"`);
          break;
        }
      }
    }

    // A bare noun phrase with no punctuation is a section label, and a label
    // above two lines of code is a heading for nothing.
    const isSeparator = /[-=*#/_]{2,}/.test(text);
    if (
      !unit.block &&
      !unit.trailing &&
      !isSeparator &&
      !/[.!?:]/.test(text) &&
      wordCount(text) <= 6 &&
      wordCount(text) >= 2
    ) {
      labelCount += 1;
      add("W-LABEL", unit.line, `"${text}" labels the code below instead of explaining it.`);
    }

    if (
      !unit.block &&
      codeLineCount < BANNER_MIN_CODE_LINES &&
      isSeparator &&
      /[-=*#/_]{3,}/.test(text)
    ) {
      add("W-BANNER", unit.line, `section banner in a ${codeLineCount}-line file - there is nothing to navigate.`);
    }
  }

  // --- restatement --------------------------------------------------------
  for (const unit of comments) {
    if (unit.block || unit.trailing) continue;
    const words = contentWords(unit.text);
    if (words.length < 2) continue;

    let target = -1;
    for (let i = unit.line; i < codeLines.length; i += 1) {
      if (codeLines[i].trim().length > 0) {
        target = i;
        break;
      }
    }
    if (target === -1) continue;

    const inCode = identifierWords(codeLines[target]);
    const matched = words.filter((word) => inCode.has(word)).length;
    if (matched / words.length >= 0.6) {
      add(
        "E-RESTATE",
        unit.line,
        `"${unit.text.slice(0, 48)}" repeats line ${target + 1}. Delete it, or say why the line is there.`
      );
    }
  }

  if (codeLineCount >= MIN_LINES_FOR_RATIO && commentLineCount / codeLineCount > MAX_COMMENT_RATIO) {
    add(
      "W-DENSITY",
      1,
      `${commentLineCount} comment lines to ${codeLineCount} of code ` +
        `(${Math.round((commentLineCount / codeLineCount) * 100)}%, cap ${MAX_COMMENT_RATIO * 100}%).`
    );
  }

  // --- capability checks --------------------------------------------------
  const capabilityStatements = [
    ...code.matchAll(
      /\b(?:if|elseif|assert)\s*\(?\s*(?:not\s+)?(typeof|type)\s*\(\s*[\w.]+\s*\)\s*(?:~=|==)\s*["'](?:function|table)["']/g
    ),
  ];
  if (capabilityStatements.length > MAX_CAPABILITY_STATEMENTS) {
    add(
      "E-CAPCHECK",
      lineOf(code, capabilityStatements[0].index),
      `${capabilityStatements.length} separate capability checks (cap ${MAX_CAPABILITY_STATEMENTS}). ` +
        `Bind the functions once and assert once - see roblox-executor/references/technique/source-to-api.md.`
    );
  }

  // --- pcall --------------------------------------------------------------
  const pcalls = [...code.matchAll(/\b(?:pcall|xpcall|ypcall)\s*\(/g)];
  for (const match of code.matchAll(/\b(?:pcall|xpcall)\s*\(\s*function\s*\(\s*\)([\s\S]*?)\bend\s*\)/g)) {
    const body = match[1];
    if (FALLIBLE_HINT.test(body)) continue;
    const assignments = (body.match(/[^=~<>]=[^=]/g) ?? []).length;
    if (assignments !== 1) continue;
    const calls = [...body.matchAll(/([A-Za-z_][\w.]*)\s*\(/g)].map((call) => call[1]);
    if (calls.every((name) => INFALLIBLE_CALLS.test(name))) {
      add(
        "E-PCALL-INFALLIBLE",
        lineOf(code, match.index),
        `pcall around a property write, which does not raise. It hides a typo instead of a failure.`
      );
    }
  }
  if (pcalls.length >= MIN_PCALLS_FOR_DENSITY && pcalls.length / codeLineCount > MAX_PCALL_PER_CODE_LINE) {
    add(
      "W-PCALL-DENSITY",
      lineOf(code, pcalls[0].index),
      `${pcalls.length} pcalls in ${codeLineCount} lines. Wrap the calls that cross a boundary, not every statement.`
    );
  }

  // --- messages -----------------------------------------------------------
  const prefixes = new Map();
  const messageCalls = [...code.matchAll(/\b(error|warn|assert|print)\s*\(([\s\S]{0,400}?)\)\s*(?:\n|$)/g)];
  for (const call of messageCalls) {
    const [, kind, args] = call;
    const line = lineOf(code, call.index);
    for (const literal of args.matchAll(/"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'/g)) {
      const text = literal[1] ?? literal[2] ?? "";
      if (text.length < 4) continue;

      if (kind !== "print") {
        if (wordCount(text) > MAX_MESSAGE_WORDS) {
          add("E-ERRPROSE", line, `${kind} message is ${wordCount(text)} words (cap ${MAX_MESSAGE_WORDS}): "${text.slice(0, 56)}"`);
        } else if (/;\s/.test(text)) {
          add("E-ERRPROSE", line, `${kind} message has two clauses: "${text.slice(0, 56)}". Name the failing value and stop.`);
        } else if (PROSE_IN_MESSAGE.test(text)) {
          add("E-ERRPROSE", line, `${kind} message argues with the reader: "${text.slice(0, 56)}"`);
        }
      }

      if (/[Ā-￿]/.test(text) || /!/.test(text)) {
        add("W-EMOJI", line, `${kind} message carries decoration: "${text.slice(0, 40)}"`);
      }

      if (kind === "print" && SUCCESS_NARRATION.test(text)) {
        add("W-SUCCESSPRINT", line, `print narrates success: "${text.slice(0, 48)}". Shipped code is quiet when it works.`);
      }

      const prefix = /^([^:]{4,40}):/.exec(text);
      if (prefix) {
        const key = prefix[1].trim();
        prefixes.set(key, (prefixes.get(key) ?? 0) + 1);
      }
    }
  }
  for (const [prefix, count] of prefixes) {
    if (count > MAX_REPEATED_PREFIX) {
      add(
        "E-PREFIX",
        1,
        `"${prefix}" is typed into ${count} messages. Declare it once as a constant and concatenate.`
      );
    }
  }

  // --- words a player reads ------------------------------------------------
  // A label, description or notice that praises itself claims what no player
  // can check; naming the effect in the game's words is the text's whole job.
  for (const match of code.matchAll(PLAYER_TEXT)) {
    const text = match[2] ?? match[3] ?? "";
    const hype = HYPE_WORDS.exec(text);
    if (hype) {
      add("W-HYPE", lineOf(code, match.index), `"${text.slice(0, 48)}" says "${hype[1]}", which no player can check. Name the effect.`);
    }
  }

  // --- naming -------------------------------------------------------------
  for (const declaration of code.matchAll(/\blocal\s+([A-Za-z_][\w]*)\s*(?:,\s*([A-Za-z_][\w]*)\s*)?=\s*([^\n]*)/g)) {
    const rhs = declaration[3] ?? "";
    for (const name of [declaration[1], declaration[2]]) {
      if (!name) continue;
      const lower = name.toLowerCase();
      const line = lineOf(code, declaration.index);

      // `local ok, result = pcall(...)` is the house idiom, not a generic name.
      if (/\bp?call\s*\(/.test(rhs) && /^(ok|success|result|err|error|reason)$/i.test(name)) continue;

      if (GENERIC_LOCALS.has(lower)) {
        add("W-GENERIC", line, `"${name}" would fit in any project. Name it from the game's vocabulary.`);
      } else if (BAD_ABBREVIATIONS.has(lower)) {
        add("W-ABBREV", line, `"${name}" is an abbreviation. Spell the word out.`);
      } else if (/[a-z]\d$/.test(name) && !/^[A-Z]/.test(name)) {
        add("W-NUMSUFFIX", line, `"${name}" ends in a digit - name the difference instead of numbering it.`);
      }
    }
  }

  // --- unnamed repeated values --------------------------------------------
  // Fractions every layout uses as an anchor. Naming 0.5 does not help anyone.
  const CANONICAL_FRACTIONS = new Set(["0.5", "0.25", "0.75", "1.0", "0.0", "2.0"]);
  const literals = new Map();
  const stripped = code.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/g, '""');
  for (const match of stripped.matchAll(/(?<![\w.])(\d+\.\d+|\d{4,})(?![\w.])/g)) {
    const value = match[1];
    if (CANONICAL_FRACTIONS.has(value)) continue;
    if (!literals.has(value)) literals.set(value, []);
    // `stripped` is where the index came from. Reading the line out of `code`
    // drifts by the difference in string-literal lengths, which is silent and
    // wrong on any file with a long string above the number.
    literals.get(value).push(lineOf(stripped, match.index));
  }
  for (const [value, lines] of literals) {
    if (lines.length >= 3) {
      add(
        "W-MAGIC",
        lines[0],
        `${value} appears ${lines.length} times (lines ${lines.slice(0, 4).join(", ")}). Give it a name once.`
      );
    }
  }

  // --- clauses inside a surviving comment ---------------------------------
  // E-RESTATE scores a comment as one unit, so a four-line comment whose first
  // line carries a real constraint dilutes three lines of restatement below the
  // threshold and passes. The clause is the unit that has to earn its place: a
  // comment with one load-bearing line is one line long.
  for (const unit of comments) {
    if (unit.block || unit.trailing || unit.lines < 2) continue;

    const following = [];
    for (let i = unit.line; i < codeLines.length && following.length < CLAUSE_LOOKAHEAD; i += 1) {
      if (codeLines[i].trim().length > 0) following.push(codeLines[i]);
    }
    if (following.length === 0) continue;
    const inCode = identifierWords(following.join(" "));

    for (const part of unit.parts ?? []) {
      for (const clause of part.text.split(CLAUSE_SPLIT)) {
        const words = contentWords(clause);
        if (words.length < MIN_CLAUSE_WORDS) continue;
        if (CONNECTIVE.test(clause)) continue;
        const matched = words.filter((word) => inCode.has(word)).length;
        if (matched / words.length < CLAUSE_ECHO_RATIO) continue;
        add(
          "E-CLAUSE",
          part.line,
          `"${clause.trim().slice(0, 52)}" is built from the identifiers below it. ` +
            `Keep the clause that says why; the rest is the code spelled twice.`
        );
      }
    }
  }

  // --- decompiler placeholders --------------------------------------------
  const declaredNames = [
    ...code.matchAll(/\blocal\s+(?:function\s+)?([A-Za-z_][\w]*)((?:\s*,\s*[A-Za-z_][\w]*)*)/g),
  ].flatMap((match) => {
    const line = lineOf(code, match.index);
    const rest = (match[2] ?? "").split(",").map((name) => name.trim()).filter(Boolean);
    return [match[1], ...rest].map((name) => ({ name, line }));
  });
  const parameterNames = [...code.matchAll(/\bfunction\s*[\w.:]*\s*\(([^)]*)\)/g)].flatMap((match) => {
    const line = lineOf(code, match.index);
    return match[1]
      .split(",")
      .map((name) => name.trim())
      .filter((name) => /^[A-Za-z_][\w]*$/.test(name))
      .map((name) => ({ name, line }));
  });
  for (const { name, line } of [...declaredNames, ...parameterNames]) {
    if (!DECOMPILER_NAME.test(name)) continue;
    add(
      "E-DECOMPNAME",
      line,
      `"${name}" is a decompiler slot number, not a name. ` +
        `Rename it from what the source proved it holds, or say the source did not establish it.`
    );
  }

  // --- how many places this script reaches into ---------------------------
  const layersTouched = new Map();
  for (const [layer, pattern] of Object.entries(VALUE_LAYERS)) {
    for (const match of code.matchAll(new RegExp(pattern.source, "g"))) {
      if (!layersTouched.has(layer)) layersTouched.set(layer, lineOf(code, match.index));
    }
  }

  // An `or` between two layers is the fallback chain the executor reference
  // exists to stop: the two branches reach different objects, so after a game
  // update the script silently edits the wrong one and reports success.
  for (const expression of code.matchAll(/^[^\n]*\bor\b[^\n]*$/gm)) {
    const text = expression[0];
    const present = new Set();
    for (const [layer, pattern] of Object.entries(VALUE_LAYERS)) {
      if (new RegExp(pattern.source).test(text)) present.add(layer);
    }
    if (present.size < 2) continue;
    add(
      "E-LAYERCHAIN",
      lineOf(code, expression.index),
      `fallback between the ${[...present].join(" and ")} layers in one expression. ` +
        `They reach different objects - pick the layer the source proved and assert on it.`
    );
  }

  if (layersTouched.size > MAX_VALUE_LAYERS) {
    add(
      "E-LAYERCHAIN",
      Math.min(...layersTouched.values()),
      `${layersTouched.size} value layers in one file (${[...layersTouched.keys()].join(", ")}, cap ${MAX_VALUE_LAYERS}). ` +
        `Read the dump again and decide which one holds the value.`
    );
  }

  const executorGlobals = new Set(
    [...code.matchAll(new RegExp(EXECUTOR_GLOBALS.source, "g"))].map((match) => match[0])
  );
  // Aliases for one function count once: resolving `getcustomasset or
  // getsynasset` at the top is two names for one call, not two places to look.
  let surface = executorGlobals.size;
  for (const alias of EXECUTOR_ALIASES) {
    const used = [...executorGlobals].filter((name) => alias.has(name.toLowerCase()));
    if (used.length > 1) surface -= used.length - 1;
  }
  if (surface > MAX_EXECUTOR_SURFACE) {
    add(
      "W-EXECSURFACE",
      1,
      `${surface} distinct executor functions (cap ${MAX_EXECUTOR_SURFACE}). ` +
        `A single-purpose script that needs this many usually never found the right layer.`
    );
  }

  const counts = {
    codeLines: codeLineCount,
    commentLines: commentLineCount,
    headerLines,
    capabilityStatements: capabilityStatements.length,
    pcalls: pcalls.length,
    labels: labelCount,
    valueLayers: [...layersTouched.keys()].sort(),
    executorSurface: surface,
    isModule,
  };

  return { findings, counts };
}

function lineOf(source, index) {
  return source.slice(0, index).split("\n").length;
}

/** Ten rows, two points each. A row fails if any of its codes fired. */
function score(findings) {
  const has = (...codes) => findings.some((finding) => codes.includes(finding.code));
  const rows = [
    ["header", !has("E-HEADER")],
    ["provenance and edit narration", !has("E-PROVENANCE") && !has("E-EDITNOTE")],
    ["header carries facts, not a summary", !has("E-HEADERSUMMARY") && !has("E-FILENAME")],
    ["commented-out code", !has("E-QUOTE")],
    ["restatement", !has("E-RESTATE", "W-LABEL", "E-CLAUSE")],
    ["capability checks", !has("E-CAPCHECK")],
    ["pcall discipline", !has("E-PCALL-INFALLIBLE", "W-PCALL-DENSITY")],
    ["message wording", !has("E-ERRPROSE", "W-EMOJI", "W-HYPE")],
    ["repeated prefix", !has("E-PREFIX")],
    ["naming", !has("W-GENERIC", "W-ABBREV", "W-NUMSUFFIX", "E-DECOMPNAME")],
    ["noise", !has("W-SUCCESSPRINT", "W-MAGIC", "W-BANNER", "W-DENSITY", "E-TODO")],
    ["one API per job", !has("E-LAYERCHAIN", "W-EXECSURFACE")],
  ];
  return { rows, points: rows.filter(([, ok]) => ok).length * 2, total: rows.length * 2 };
}

/**
 * Prove a rewrite happened.
 *
 * The failure this exists for: a model is asked to redesign or clean up a file,
 * answers "done", and returns something with the same counts and the same
 * findings. The claim is unfalsifiable from the reply alone, so the user finds
 * out by reading the code - which is the job they delegated.
 *
 * This prints what changed. A row that did not move is a row the rewrite did
 * not touch, and a rewrite with no moved rows is not a rewrite.
 */
function compare(beforeFile, afterFile) {
  const read = (file) => {
    const full = existsSync(file) ? file : join(REPO_ROOT, file);
    if (!existsSync(full)) {
      console.error(`no such path: ${file}`);
      process.exit(2);
    }
    const source = readFileSync(full, "utf8");
    const { findings, counts } = analyse(source, file);
    return { findings, counts, score: score(findings), lines: source.split(/\r?\n/).length };
  };

  const before = read(beforeFile);
  const after = read(afterFile);

  const key = (finding) => `${finding.code}:${finding.message}`;
  const beforeKeys = new Set(before.findings.map(key));
  const afterKeys = new Set(after.findings.map(key));
  const resolved = before.findings.filter((finding) => !afterKeys.has(key(finding)));
  const introduced = after.findings.filter((finding) => !beforeKeys.has(key(finding)));
  const carried = before.findings.filter((finding) => afterKeys.has(key(finding)));

  const rows = [
    ["score", `${before.score.points}/${before.score.total}`, `${after.score.points}/${after.score.total}`],
    ["lines", before.lines, after.lines],
    ["code lines", before.counts.codeLines, after.counts.codeLines],
    ["comment lines", before.counts.commentLines, after.counts.commentLines],
    ["header lines", before.counts.headerLines, after.counts.headerLines],
    ["capability checks", before.counts.capabilityStatements, after.counts.capabilityStatements],
    ["pcalls", before.counts.pcalls, after.counts.pcalls],
    ["value layers", before.counts.valueLayers.join("/") || "none", after.counts.valueLayers.join("/") || "none"],
    ["executor surface", before.counts.executorSurface, after.counts.executorSurface],
  ];

  console.log(`\n${beforeFile} -> ${afterFile}\n`);
  const width = Math.max(...rows.map(([name]) => name.length));
  let moved = 0;
  for (const [name, from, to] of rows) {
    const same = String(from) === String(to);
    if (!same) moved += 1;
    console.log(`  ${name.padEnd(width)}  ${String(from).padStart(9)} -> ${String(to).padEnd(9)} ${same ? "unchanged" : ""}`);
  }

  console.log(`\n  resolved   ${resolved.length}`);
  for (const finding of resolved.slice(0, 12)) console.log(`    - ${finding.code}  ${finding.message.slice(0, 88)}`);
  console.log(`  introduced ${introduced.length}`);
  for (const finding of introduced.slice(0, 12)) console.log(`    + ${finding.code}  ${finding.message.slice(0, 88)}`);
  console.log(`  still there ${carried.length}`);
  for (const finding of carried.slice(0, 12)) console.log(`    = ${finding.code}  ${finding.message.slice(0, 88)}`);

  console.log(
    `\n  ${moved}/${rows.length} counted rows moved. ` +
      (moved === 0
        ? "Nothing measurable changed - do not report this as a rewrite."
        : `${resolved.length} finding(s) resolved, ${introduced.length} introduced.`)
  );

  if (after.findings.some((finding) => finding.code.startsWith("E-"))) process.exitCode = 1;
}

function collect(target, out = []) {
  if (statSync(target).isDirectory()) {
    for (const entry of readdirSync(target)) collect(join(target, entry), out);
  } else if (/\.(luau|lua)$/i.test(target)) {
    out.push(target);
  }
  return out;
}

function report(results, asJson) {
  if (asJson) {
    console.log(JSON.stringify({ results }, null, 2));
    return;
  }
  for (const result of results) {
    console.log(`\n${result.file}`);
    for (const finding of result.findings) {
      console.log(`  ${result.file}:${finding.line}  ${finding.code}  ${finding.message}`);
    }
    const failed = result.score.rows.filter(([, ok]) => !ok).map(([name]) => name);
    console.log(
      `  score ${result.score.points}/${result.score.total}` +
        (failed.length ? `  failing: ${failed.join(", ")}` : "  all counted checks pass")
    );
  }
}

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf8");
}

async function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const useStdin = args.includes("--stdin");
  const targets = args.filter((arg) => !arg.startsWith("--"));

  if (args.includes("--compare")) {
    if (targets.length !== 2) {
      console.error("usage: node tools/bin/lint-luau-slop.mjs --compare <before.luau> <after.luau>");
      process.exit(2);
    }
    compare(targets[0], targets[1]);
    return;
  }

  const results = [];

  if (useStdin) {
    const source = await readStdin();
    const { findings, counts } = analyse(source, "<stdin>");
    results.push({ file: "<stdin>", findings, counts, score: score(findings) });
  } else {
    if (targets.length === 0) {
      console.error(
        "usage: node tools/bin/lint-luau-slop.mjs <file.luau|directory> [...]\n" +
          "       node tools/bin/lint-luau-slop.mjs --stdin\n" +
          "Counts the machine-written tells in roblox-code-craft/references/anti-slop-code.md."
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

    for (const file of files) {
      const inside = relative(REPO_ROOT, file).split(sep).join("/");
      const rel = inside.startsWith("..") ? file.split(/[/\\]/).pop() : inside;
      const { findings, counts } = analyse(readFileSync(file, "utf8"), rel);
      results.push({ file: rel, findings, counts, score: score(findings) });
    }
  }

  report(results, asJson);

  const errors = results.flatMap((result) => result.findings).filter((finding) => finding.code.startsWith("E-"));
  const warnings = results.flatMap((result) => result.findings).filter((finding) => finding.code.startsWith("W-"));
  if (!asJson) {
    console.log(`\n${results.length} file(s) - ${errors.length} error(s), ${warnings.length} warning(s)`);
  }
  if (errors.length > 0) process.exitCode = 1;
}

main();
