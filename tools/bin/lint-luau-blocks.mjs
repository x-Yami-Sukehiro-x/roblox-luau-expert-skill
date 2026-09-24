#!/usr/bin/env node
// Check the Luau examples the skills actually ship.
//
// Three defects this exists to catch, all found in the v2.1 corpus:
//
//   1. Syntax errors.
//   2. An identifier used but never declared - component-states.md set
//      focusRing.Enabled inside a function that takes (button, visual) and
//      never declares focusRing. The flagship example of the interaction-states
//      skill did not run.
//   3. A member that does not exist on the annotated type - choreography.md
//      declared staggerIn(items: { GuiObject }) and then set
//      item.GroupTransparency, which only CanvasGroup has.
//
// A block that is a deliberate fragment opts out with a leading comment:
//   -- lint: fragment
//
// Usage:
//   node tools/bin/lint-luau-blocks.mjs [--json] [path...]
//
// Exit 1 on any error.

import { readFileSync, readdirSync, statSync, existsSync, writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { tmpdir } from "node:os";
import { execFileSync } from "node:child_process";
import { loadDump, resolveMember, assignmentBlocker, REPO_ROOT } from "./lib/dump.mjs";
import { luauRuntime } from "./lib/luau-runtime.mjs";

const SKILLS_DIR = join(REPO_ROOT, ".claude", "skills");
const LIBRARY_DIR = join(REPO_ROOT, "library", "src");
const SKIP_DIRS = new Set(["verified", "node_modules", ".git"]);

const FRAGMENT_MARKER = /--\s*lint:\s*fragment/;
const COMPLETE_MARKER = /--\s*lint:\s*complete/;

// Luau and Roblox names a snippet may use without declaring them.
const LUAU_GLOBALS = new Set([
  "assert", "error", "getfenv", "getmetatable", "ipairs", "next", "newproxy",
  "pairs", "pcall", "print", "rawequal", "rawget", "rawlen", "rawset",
  "require", "select", "setfenv", "setmetatable", "tonumber", "tostring",
  "type", "typeof", "unpack", "warn", "xpcall", "gcinfo", "collectgarbage",
  "coroutine", "debug", "math", "os", "string", "table", "utf8", "buffer",
  "vector", "task", "bit32", "_G", "shared", "script", "game", "workspace",
  "plugin", "settings", "Enum", "delay", "spawn", "tick", "time", "wait",
  "elapsedTime", "version", "UserSettings", "DebuggerManager", "stats",
  "PluginManager", "LoadLibrary", "printidentity", "loadstring",
]);

// Roblox datatype constructors. These are globals, not classes, so the dump
// does not list them.
const ROBLOX_DATATYPES = new Set([
  "Axes", "BrickColor", "CFrame", "CatalogSearchParams", "Color3",
  "ColorSequence", "ColorSequenceKeypoint", "Content", "DateTime",
  "DockWidgetPluginGuiInfo", "Faces", "FloatCurveKey", "Font", "Instance",
  "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "OverlapParams",
  "Path2DControlPoint", "PhysicalProperties", "Random", "Ray", "RaycastParams",
  "RaycastResult", "Rect", "Region3", "Region3int16", "RotationCurveKey",
  "SharedTable", "TweenInfo", "UDim", "UDim2", "Vector2", "Vector2int16",
  "Vector3", "Vector3int16", "SecurityCapabilities", "OpenCloudModel",
]);

// Executor globals. Only accepted inside roblox-executor, so a game-side
// snippet that reaches for one is still reported.
const EXECUTOR_GLOBALS = new Set([
  "getgenv", "getrenv", "getreg", "getgc", "filtergc", "gethui", "getsenv",
  "getinstances", "getnilinstances", "getscripts", "getrunningscripts",
  "getloadedmodules", "getcallingscript", "getscriptfromthread", "cloneref",
  "compareinstances", "cache", "hookfunction", "hookmetamethod", "newcclosure",
  "clonefunction", "restorefunction", "checkcaller", "checkcallstack",
  "iscclosure", "islclosure", "isexecutorclosure", "getnamecallmethod",
  "setnamecallmethod", "getrawmetatable", "setrawmetatable", "setreadonly",
  "isreadonly", "makewriteable", "makereadonly", "getthreadidentity",
  "setthreadidentity", "getconnections", "getconnection", "firesignal",
  "replicatesignal", "fireclickdetector", "fireproximityprompt",
  "firetouchinterest", "getcustomasset", "writefile", "readfile", "appendfile",
  "isfile", "isfolder", "makefolder", "delfile", "delfolder", "listfiles",
  "Drawing", "cleardrawcache", "isrenderobj", "getrenderproperty",
  "setrenderproperty", "WebSocket", "request", "identifyexecutor", "crypt",
  "base64_encode", "base64_decode", "setclipboard", "setrbxclipboard",
  "messagebox", "saveinstance", "decompile", "dumpstring", "getscriptbytecode",
  "getscripthash", "getscriptclosure", "getfunctionhash", "setfflag",
  "queue_on_teleport", "gethiddenproperty", "sethiddenproperty", "isscriptable",
  "setscriptable", "getactors", "getactorthreads", "run_on_actor",
  "create_comm_channel", "get_comm_channel", "is_parallel", "raknet", "rnet",
  "syn", "isrbxactive", "mouse1click", "mouse1press", "mouse1release",
  "mousemoverel", "mousemoveabs", "mousescroll", "rconsoleprint",
  "rconsoleinfo", "rconsolewarn", "rconsoleerr", "rconsoleclear",
  "rconsolename", "rconsolecreate", "rconsoledestroy", "getpcd", "getbspval",
  "getspecialinfo", "isnetworkowner", "setsimulationradius",
  "getrendersteppedlist", "getcallbackvalue", "setnonreplicatedproperty",
  "getconstant", "getconstants", "setconstant", "getproto", "getprotos",
  "getstack", "setstack", "getupvalue", "getupvalues", "setupvalue", "setname",
  "getinfo", "getregistry", "isvalidlevel", "protect_gui", "clear_teleport_queue",
  "get_thread_identity", "set_thread_identity", "issynapsefunction",
  "lz4compress", "lz4decompress",
]);

function walkMarkdown(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      if (SKIP_DIRS.has(entry)) continue;
      walkMarkdown(full, out);
    } else if (entry.endsWith(".md")) {
      out.push(full);
    }
  }
  return out;
}

function extractBlocks(path) {
  const text = readFileSync(path, "utf8");
  const lines = text.split(/\r?\n/);
  const blocks = [];
  let open = null;
  for (const [i, line] of lines.entries()) {
    const fence = /^\s*```\s*([A-Za-z0-9_+-]*)\s*$/.exec(line);
    if (!fence) continue;
    if (open === null) {
      const lang = (fence[1] || "").toLowerCase();
      open = lang === "lua" || lang === "luau" ? { start: i } : { start: -1 };
    } else {
      if (open.start >= 0) {
        // A block opts out with an HTML comment on the line above the fence.
        // That stays invisible in rendered markdown, where a "-- lint:" code
        // comment would show up as noise in the example itself.
        let marked = false;
        for (let k = open.start - 1; k >= 0 && k >= open.start - 3; k -= 1) {
          const prev = lines[k].trim();
          if (!prev) continue;
          marked = /<!--\s*lint:\s*fragment\s*-->/.test(prev);
          break;
        }
        blocks.push({
          startLine: open.start + 2, // first content line, 1-indexed
          source: lines.slice(open.start + 1, i).join("\n"),
          markedFragment: marked,
        });
      }
      open = null;
    }
  }
  return blocks;
}

// Remove strings and comments so identifier scanning is not fooled by prose.
function blank(source) {
  let out = "";
  let i = 0;
  const n = source.length;
  while (i < n) {
    const two = source.slice(i, i + 2);
    if (two === "--") {
      const longOpen = /^--\[(=*)\[/.exec(source.slice(i));
      if (longOpen) {
        const close = `]${longOpen[1]}]`;
        const end = source.indexOf(close, i);
        const stop = end === -1 ? n : end + close.length;
        out += source.slice(i, stop).replace(/[^\n]/g, " ");
        i = stop;
        continue;
      }
      const end = source.indexOf("\n", i);
      const stop = end === -1 ? n : end;
      out += " ".repeat(stop - i);
      i = stop;
      continue;
    }
    const longStr = /^\[(=*)\[/.exec(source.slice(i));
    if (longStr) {
      const close = `]${longStr[1]}]`;
      const end = source.indexOf(close, i);
      const stop = end === -1 ? n : end + close.length;
      out += source.slice(i, stop).replace(/[^\n]/g, " ");
      i = stop;
      continue;
    }
    const ch = source[i];
    if (ch === '"' || ch === "'" || ch === "`") {
      let j = i + 1;
      while (j < n && source[j] !== ch) {
        if (source[j] === "\\") j += 1;
        if (source[j] === "\n") break;
        j += 1;
      }
      const stop = Math.min(j + 1, n);
      out += source.slice(i, stop).replace(/[^\n]/g, " ");
      i = stop;
      continue;
    }
    out += ch;
    i += 1;
  }
  return out;
}

const LUAU_KEYWORDS = new Set([
  "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
  "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
  "until", "while", "continue", "type", "export", "self",
]);

function analyseBlock(code) {
  const src = blank(code);
  const declared = new Set();
  const typed = new Map(); // ident -> class name
  const arrayTyped = new Map(); // ident -> element class name

  // local a, b, c            local a: Frame = ...
  for (const m of src.matchAll(/\blocal\s+([A-Za-z_][\w\s,:{}?<>|.]*?)(?==|$|\n)/gm)) {
    for (const part of m[1].split(",")) {
      const d = /^\s*([A-Za-z_]\w*)\s*(?::\s*(.+?))?\s*$/.exec(part);
      if (!d) continue;
      declared.add(d[1]);
      recordType(d[1], d[2]);
    }
  }
  // local function f / function M.f / function M:f
  for (const m of src.matchAll(/\bfunction\s+([A-Za-z_]\w*)/g)) declared.add(m[1]);
  // parameters, including annotations
  for (const m of src.matchAll(/\bfunction\s*[A-Za-z_][\w.:]*\s*\(([^)]*)\)/g)) {
    for (const part of m[1].split(",")) {
      const d = /^\s*([A-Za-z_]\w*|\.\.\.)\s*(?::\s*(.+?))?\s*$/.exec(part);
      if (!d || d[1] === "...") continue;
      declared.add(d[1]);
      recordType(d[1], d[2]);
    }
  }
  // for k, v in ...   /   for i = a, b
  for (const m of src.matchAll(/\bfor\s+([A-Za-z_][\w\s,]*?)\s+(?:in|=)\s+([^\n]*)/g)) {
    const names = m[1].split(",").map((s) => s.trim()).filter(Boolean);
    for (const nm of names) declared.add(nm);
    // for _, item in items  -> item takes the element type of items
    const iter = /^\s*(?:ipairs\s*\(\s*)?([A-Za-z_]\w*)/.exec(m[2]);
    if (iter && names.length >= 1) {
      const elem = arrayTyped.get(iter[1]);
      if (elem) typed.set(names[names.length - 1], elem);
    }
  }

  // local frame = Instance.new("Frame")  ->  frame is a Frame.
  // Annotations cover the parameter case; this covers the construction case,
  // which is most of the examples in this corpus.
  // Scanned against the raw source: blank() strips string literals, which is
  // exactly where the class name lives.
  for (const m of code.matchAll(
    /\blocal\s+([A-Za-z_]\w*)[^=\r\n]*=\s*Instance\.new\s*\(\s*["']([A-Za-z0-9_]+)["']/g
  )) {
    typed.set(m[1], m[2]);
  }

  function recordType(name, annotation) {
    if (!annotation) return;
    const a = annotation.trim().replace(/\?$/, "");
    const arr = /^\{\s*([A-Za-z_]\w*)\s*\}$/.exec(a);
    if (arr) {
      arrayTyped.set(name, arr[1]);
      return;
    }
    const plain = /^([A-Za-z_]\w*)$/.exec(a);
    if (plain) typed.set(name, plain[1]);
  }

  return { src, declared, typed };
}

function lintBlock(block, rel, allowsExecutor, dump, findings) {
  const { source, startLine } = block;
  if (block.markedFragment || FRAGMENT_MARKER.test(source)) return;

  const { src, declared, typed } = analyseBlock(source);
  const codeLines = src.split("\n");
  const isComplete = COMPLETE_MARKER.test(source);

  // ---- undefined identifiers ----------------------------------------------
  // Opt-in. Reference docs are mostly deliberate fragments where `panel` or
  // `frame` is the reader's own object, so checking every block would bury the
  // real defects under hundreds of non-findings. A block that claims to be
  // complete gets held to it.
  if (isComplete) {
    for (const [i, line] of codeLines.entries()) {
      for (const m of line.matchAll(/(^|[^\w.:"'])([a-z][A-Za-z0-9_]*)\s*(?=[.:[(])/g)) {
        const name = m[2];
        if (LUAU_KEYWORDS.has(name) || declared.has(name)) continue;
        if (LUAU_GLOBALS.has(name)) continue;
        if (EXECUTOR_GLOBALS.has(name)) continue;
        findings.push({
          code: "E-UNDECLARED",
          file: rel,
          line: startLine + i,
          message: `${name} is used but never declared, in a block marked complete`,
        });
      }
    }
  }

  // ---- executor globals outside the executor skill -------------------------
  if (!allowsExecutor) {
    for (const [i, line] of codeLines.entries()) {
      for (const m of line.matchAll(/(^|[^\w.:])([a-z_][A-Za-z0-9_]*)\s*\(/g)) {
        const name = m[2];
        if (!EXECUTOR_GLOBALS.has(name) || declared.has(name)) continue;
        findings.push({
          code: "E-EXECUTOR-GLOBAL",
          file: rel,
          line: startLine + i,
          message: `${name} is an executor global used outside an executor context`,
        });
      }
    }
  }

  // ---- members that do not exist on the annotated type ---------------------
  // Only assignments and method calls. Reading `player.leaderstats` is a child
  // lookup and perfectly valid; writing `item.GroupTransparency` when item is
  // annotated GuiObject is not, because only CanvasGroup has it.
  for (const [i, line] of codeLines.entries()) {
    const hits = [
      ...line.matchAll(/\b([a-z][A-Za-z0-9_]*)\.([A-Za-z_]\w*)\s*=(?!=)/g),
      ...line.matchAll(/\b([a-z][A-Za-z0-9_]*):([A-Za-z_]\w*)\s*\(/g),
    ];
    for (const m of hits) {
      const [, ident, member] = m;
      const className = typed.get(ident);
      if (!className || !dump.classes.has(className)) continue;
      if (resolveMember(className, member)) continue;
      findings.push({
        code: "E-TYPE",
        file: rel,
        line: startLine + i,
        message: `${ident} is annotated ${className}, which has no member ${member}`,
      });
    }
  }

  // ---- assigning a property that cannot be assigned at runtime -------------
  // The prose linter catches the qualified form (`ScreenGui.IgnoreGuiInset`).
  // This catches the form examples actually use, through a local variable.
  for (const [i, line] of codeLines.entries()) {
    for (const m of line.matchAll(/\b([a-z][A-Za-z0-9_]*)\.([A-Za-z_]\w*)\s*=(?!=)/g)) {
      const [, ident, member] = m;
      const className = typed.get(ident);
      if (!className || !dump.classes.has(className)) continue;
      const rec = resolveMember(className, member);
      if (!rec) continue;
      const blocker = assignmentBlocker(rec);
      if (!blocker) continue;
      findings.push({
        code: "E-WRITETIME",
        file: rel,
        line: startLine + i,
        message: `${ident} is a ${className}; ${member} is ${blocker}`,
      });
    }
  }
}

// A block that lists signatures rather than running - `function getgenv(): table`
// with no body, or `Raycast(origin: Vector3) -> RaycastResult?`. These are
// documentation, but they sit in ```lua fences where they read as copyable code
// and will not parse. Reported as a warning suggesting a ```text fence.
function looksLikeSignatureList(source) {
  const lines = source
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("--"));
  if (!lines.length) return false;

  // A bare "..." standing in for omitted code is prose, not a vararg.
  const hasElision = lines.some((l) => /(^|[\s(=,{])\.\.\.(\s|$|[,)}])/.test(l) && !/\(\s*\.\.\./.test(l));
  if (hasElision) return true;

  const signatureish = lines.filter(
    (l) =>
      /->/.test(l) ||                          // Raycast(...) -> RaycastResult?
      /\)\s*:\s*[A-Za-z{(]/.test(l) ||         // function f(): boolean
      /\w\?\s*[,:)]/.test(l) ||                // optional parameter marker
      /^[A-Za-z_][\w.]*\s*\([^)]*\)\s*$/.test(l) || // name(args) alone
      /^(boolean|string|number|void|table|any)\s+\w/.test(l) // return-type-first
  ).length;
  const hasEnd = lines.some((l) => /^end\b/.test(l));
  return !hasEnd && signatureish / lines.length >= 0.4;
}

let luauAvailable = null;

function haveLuau(luau) {
  if (luauAvailable === null) {
    try {
      execFileSync(luau, ["--help"], { stdio: "ignore" });
      luauAvailable = true;
    } catch {
      luauAvailable = false;
    }
  }
  return luauAvailable;
}

// One luau process per file, not per block. Spawning 428 times took minutes;
// batching every block of a file into a single harness takes seconds.
function syntaxCheck(blocks, rel, findings) {
  const luau = luauRuntime();
  if (!haveLuau(luau)) return false;

  // Signature listings are documentation, not code. They are a normal docs
  // convention and reporting 100+ of them would drown the real breakage.
  const candidates = blocks.filter(
    (b) =>
      !b.markedFragment &&
      !FRAGMENT_MARKER.test(b.source) &&
      !looksLikeSignatureList(b.source)
  );
  if (!candidates.length) return true;

  const dir = mkdtempSync(join(tmpdir(), "luaulint-"));
  try {
    const harness = join(dir, "check.luau");
    const sources = candidates.map((b) => JSON.stringify(b.source)).join(",\n");
    writeFileSync(
      harness,
      `local blocks = {\n${sources}\n}\n` +
        `for index, src in ipairs(blocks) do\n` +
        `  local fn, err = loadstring(src)\n` +
        `  if not fn then print("SYNTAX\\t" .. index .. "\\t" .. tostring(err)) end\n` +
        `end\n`,
      "utf8"
    );

    let out = "";
    try {
      out = execFileSync(luau, [harness], {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "pipe"],
        maxBuffer: 32 * 1024 * 1024,
      });
    } catch (e) {
      out = String(e.stdout ?? "") + String(e.stderr ?? "");
    }

    for (const line of out.split("\n")) {
      const m = /^SYNTAX\t(\d+)\t(.*)$/.exec(line.trim());
      if (!m) continue;
      const block = candidates[Number(m[1]) - 1];
      if (!block) continue;
      findings.push({
        code: "E-SYNTAX",
        file: rel,
        line: block.startLine,
        message: m[2].trim(),
      });
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
  return true;
}

function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const explicit = args.filter((a) => !a.startsWith("--"));

  const dump = loadDump();
  const files = explicit.length
    ? explicit.flatMap((p) => {
        // A directory argument used to crash with EISDIR. Expanding it is what
        // anyone typing one meant, and the crash taught nothing.
        const full = existsSync(p) ? p : join(REPO_ROOT, p);
        if (!existsSync(full)) {
          console.error(`no such path: ${p}`);
          process.exitCode = 2;
          return [];
        }
        return statSync(full).isDirectory() ? walkMarkdown(full) : [full];
      })
    : walkMarkdown(SKILLS_DIR);

  const findings = [];
  let blockCount = 0;
  let syntaxRan = false;

  for (const path of files) {
    const rel = relative(REPO_ROOT, path).split(sep).join("/");
    // Executor globals are legitimate wherever the file is about executor
    // work, which includes the hub-UI sections of the UI skills.
    const loweredBody = readFileSync(path, "utf8").toLowerCase();
    const allowsExecutor =
      rel.includes("roblox-executor") ||
      loweredBody.includes("executor") ||
      loweredBody.includes("gethui") ||
      loweredBody.includes("script hub");
    const blocks = extractBlocks(path);
    blockCount += blocks.length;
    for (const block of blocks) lintBlock(block, rel, allowsExecutor, dump, findings);
    syntaxRan = syntaxCheck(blocks, rel, findings) || syntaxRan;
  }

  // library/src is real shipped Luau, not examples - syntax-check it whole.
  if (!explicit.length && existsSync(LIBRARY_DIR)) {
    for (const f of readdirSync(LIBRARY_DIR, { recursive: true })) {
      const full = join(LIBRARY_DIR, String(f));
      if (!String(f).endsWith(".luau") || !statSync(full).isFile()) continue;
      const rel = relative(REPO_ROOT, full).split(sep).join("/");
      syntaxCheck([{ startLine: 1, source: readFileSync(full, "utf8") }], rel, findings);
    }
  }

  if (asJson) {
    console.log(JSON.stringify({ dump: dump.version, findings }, null, 2));
  } else {
    findings.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);
    for (const f of findings) console.log(`${f.file}:${f.line}  ${f.code}  ${f.message}`);
    console.log(
      `\n${files.length} files, ${blockCount} Luau blocks - ${findings.length} finding(s)` +
        (syntaxRan ? "" : "\n(luau binary not found: syntax checking was skipped)")
    );
  }

  if (findings.some((f) => f.code.startsWith("E-"))) process.exitCode = 1;
}

main();
