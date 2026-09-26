#!/usr/bin/env node
// Measure how close each function in a Luau file is to the compiler's
// register, local and upvalue limits, before it fails with "Out of local
// registers".
//
// The compiler is the ground truth. The file is compiled at -O0, where every
// local keeps its own register, and the bytecode listing is read for the
// highest register and upvalue each function touches. -O1 and -O2 only fold
// constant locals away, so a function that fits at -O0 fits at every level.
//
// Two findings come from the source beside the listing. W-SCOPE: a name
// declared `local` somewhere in the file is read or written as a global
// elsewhere, which is what a local moved into a `do` block or below its first
// use turns into: it compiles, and it is nil at runtime. I-LOCALS: when the
// main chunk is the function that is full, which families its top-level
// locals fall into, so the fix starts with the largest.
//
// Usage:
//   node tools/bin/check-registers.mjs <file.luau|directory> [...]
//   node tools/bin/check-registers.mjs --budget 120 <file>    warn earlier
//   node tools/bin/check-registers.mjs --json <file>
//
// Exit 1 when a file does not compile or a function is over budget; exit 2
// when no Luau compiler is available. Python port: tools/py/register_budget.py.

import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync, chmodSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { pathToFileURL } from "node:url";
import { REPO_ROOT } from "./lib/dump.mjs";

const LOCAL_LIMIT = 200;
const REGISTER_LIMIT = 255;
const UPVALUE_LIMIT = 200;
const DEFAULT_BUDGET = 160;

// Each compile error names a different limit, and each has a different fix.
const CAUSES = [
  [/Out of local registers/, "too many locals alive at once in one function (limit 200)",
    "group related locals into one table, close finished steps with do ... end, or move a section into its own local function"],
  [/Out of registers when trying to allocate/, "one expression needs more temporary slots than are left (limit 255)",
    "pass a table instead of a very long argument list, build long text with table.concat, return one table"],
  [/Out of upvalue registers/, "one function uses more than 200 locals from outside it",
    "pass one context table in, or group the outer locals into tables"],
  [/Exceeded constant limit/, "too many different literal values in one function",
    "move the data into a ModuleScript or a separate function"],
  [/Exceeded function instruction limit/, "one function body is too long",
    "split it into several functions"],
  [/return count limit/, "a return statement lists too many values",
    "return one table instead"],
];

function compiler() {
  if (process.env.LUAU_COMPILE_BIN) return process.env.LUAU_COMPILE_BIN;
  const host = { win32: "windows-x64", linux: "linux-x64" }[process.platform];
  if (host && process.arch === "x64") {
    const name = process.platform === "win32" ? "luau-compile.exe" : "luau-compile";
    const bundled = join(REPO_ROOT, "tools", "runtime", host, name);
    if (existsSync(bundled)) {
      if (process.platform !== "win32") chmodSync(bundled, 0o755);
      return bundled;
    }
  }
  return "luau-compile";
}

function collect(target, out = []) {
  if (statSync(target).isDirectory()) {
    for (const entry of readdirSync(target)) {
      if (entry === "node_modules" || entry === ".git") continue;
      collect(join(target, entry), out);
    }
  } else if (/\.luau?$/i.test(target)) {
    out.push(target);
  }
  return out;
}

// The listing prints each function as a header, then source lines ("  12: ...")
// interleaved with the instructions compiled from them.
export function measure(listing) {
  const functions = [];
  let current = null;
  let line = 0;
  for (const text of listing.split(/\r?\n/)) {
    const header = /^Function \d+ \((.*?)\)/.exec(text);
    if (header) {
      current = { name: header[1], first: 0, registers: 0, peakLine: 0, upvalues: 0 };
      functions.push(current);
      continue;
    }
    if (!current) continue;
    const source = /^\s+(\d+):/.exec(text);
    if (source) {
      line = Number(source[1]);
      if (!current.first) current.first = line;
      continue;
    }
    for (const match of text.matchAll(/\bR(\d+)\b/g)) {
      const used = Number(match[1]) + 1;
      if (used > current.registers) {
        current.registers = used;
        current.peakLine = line;
      }
    }
    for (const match of text.matchAll(/\b(?:GETUPVAL|SETUPVAL) R\d+ (\d+)|\bCAPTURE UPVAL U(\d+)/g)) {
      current.upvalues = Math.max(current.upvalues, Number(match[1] ?? match[2]) + 1);
    }
  }
  // The main chunk is listed last and has no name.
  if (functions.length) functions.at(-1).name = "main chunk";
  for (const entry of functions) if (entry.name === "??") entry.name = "anonymous function";
  return functions;
}

const IDENTIFIER = /^[A-Za-z_][A-Za-z0-9_]*/;
// A line ending in one of these continues the statement on the next line.
const CONTINUES = /(=|,|\(|\{|\.\.|\band|\bor|[-+*\/])\s*$/;

function withoutComment(text) {
  const at = text.indexOf("--");
  return at === -1 ? text : text.slice(0, at);
}

function namesDeclared(text) {
  const named = /^\s*local\s+function\s+([A-Za-z_][A-Za-z0-9_]*)/.exec(text);
  if (named) return [named[1]];
  const list = /^\s*local\s+([^=]+)/.exec(withoutComment(text));
  if (!list) return [];
  let depth = 0;
  let piece = "";
  const pieces = [];
  for (const char of list[1]) {
    if ("<({[".includes(char)) depth += 1;
    if (">)}]".includes(char)) depth -= 1;
    if (char === "," && depth === 0) {
      pieces.push(piece);
      piece = "";
    } else {
      piece += char;
    }
  }
  pieces.push(piece);
  return pieces.map((part) => IDENTIFIER.exec(part.trim())?.[0]).filter(Boolean);
}

// Each local declaration: its names and the lines its statement spans, so the
// global read in `local getgc = getgc` is not mistaken for a scope leak.
export function declarations(source) {
  const lines = source.split(/\r?\n/);
  const found = [];
  for (let index = 0; index < lines.length; index += 1) {
    const names = namesDeclared(lines[index]);
    if (!names.length) continue;
    let last = index;
    while (last + 1 < lines.length && CONTINUES.test(withoutComment(lines[last]))) last += 1;
    found.push({ names, first: index + 1, last: last + 1, top: /^local\s/.test(lines[index]), text: lines[index] });
  }
  return found;
}

export function scopeLeaks(listing, source) {
  const declared = new Map();
  for (const entry of declarations(source)) {
    for (const name of entry.names) {
      if (!declared.has(name)) declared.set(name, []);
      declared.get(name).push(entry);
    }
  }
  const leaks = new Map();
  let line = 0;
  for (const text of listing.split(/\r?\n/)) {
    const at = /^\s+(\d+):/.exec(text);
    if (at) {
      line = Number(at[1]);
      continue;
    }
    const global = /^(?:GETGLOBAL|SETGLOBAL) R\d+ K\d+ \['([A-Za-z_][A-Za-z0-9_]*)'\]/.exec(text);
    if (!global || !declared.has(global[1])) continue;
    const owners = declared.get(global[1]);
    if (owners.some((entry) => line >= entry.first && line <= entry.last)) continue;
    const leak = leaks.get(global[1]);
    if (leak) {
      if (!leak.lines.includes(line)) leak.lines.push(line);
    } else {
      leaks.set(global[1], { name: global[1], declaredAt: owners[0].first, lines: [line] });
    }
  }
  return [...leaks.values()].map((leak) => {
    leak.lines.sort((a, b) => a - b);
    const extra = leak.lines.length - 1;
    const more = extra ? ` (${extra} more use${extra > 1 ? "s" : ""})` : "";
    return {
      code: "W-SCOPE",
      line: leak.lines[0],
      message: `\`${leak.name}\` is declared local at line ${leak.declaredAt} but used here outside that scope, ` +
        `so it reads a global that is nil${more}; keep it in a table both places can see`,
    };
  });
}

const FAMILIES = [
  ["library elements", /:\s*(?:Create|Add|New|Make)[A-Za-z0-9_]*\s*\(/, "drop `local name =` from the unused ones"],
  ["instances", /\bInstance\.new\s*\(/, "put them in one ui table"],
  ["services", /:GetService\s*\(/, null],
  ["child lookups", /:(?:WaitForChild|FindFirstChild)\s*\(/, "put them in one table named for what they are, such as remotes"],
  ["literal settings", /^\s*(?:-?[0-9][0-9_.]*|"[^"]*"|'[^']*'|true|false)\s*$/, "put them in one CONFIG table"],
];

// Which kinds of top-level local fill the main chunk, largest first.
export function localFamilies(source) {
  const lines = source.split(/\r?\n/);
  const top = declarations(source).filter((entry) => entry.top);
  const counts = new Map();
  let names = 0;
  let unusedElements = 0;
  for (const entry of top) {
    names += entry.names.length;
    let family = "local functions";
    if (!/^local\s+function\s/.test(entry.text)) {
      const value = withoutComment(entry.text).split("=").slice(1).join("=");
      family = FAMILIES.find(([, pattern]) => pattern.test(value))?.[0] ?? "other";
      if (family === "library elements" && entry.names.length === 1) {
        const rest = lines.slice(entry.last).join("\n");
        const use = new RegExp(`(?<![A-Za-z0-9_.:])${entry.names[0]}(?![A-Za-z0-9_])`);
        if (!use.test(rest)) unusedElements += 1;
      }
    }
    counts.set(family, (counts.get(family) ?? 0) + entry.names.length);
  }
  const advice = new Map(FAMILIES.map(([family, , hint]) => [family, hint]));
  advice.set("local functions", "make them fields of one table");
  const parts = [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1))
    .map(([family, count]) => {
      const unused = family === "library elements" && unusedElements ? `, ${unusedElements} never used again` : "";
      const hint = advice.get(family);
      return `${count} ${family}${unused}${hint ? ` (${hint})` : ""}`;
    });
  return { names, summary: parts.join(", ") };
}

const FAMILY_MINIMUM = 60;

function familyFinding(source) {
  const { names, summary } = localFamilies(source);
  if (names < FAMILY_MINIMUM) return [];
  return [{ code: "I-LOCALS", line: 1, message: `the main chunk declares ${names} top-level locals: ${summary}` }];
}

function describe(entry) {
  return entry.name === "main chunk" ? "main chunk" : `${entry.name} (line ${entry.first})`;
}

export function check(file, budget) {
  const listed = spawnSync(compiler(), ["--text", "-O0", file], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  if (listed.error) return { unavailable: String(listed.error.message ?? listed.error) };

  const output = `${listed.stdout ?? ""}${listed.stderr ?? ""}`;
  const failure = /\((\d+),\d+\): (\w+Error): (.*)/.exec(output);
  if (listed.status !== 0 || failure) {
    const [, at, kind, message] = failure ?? [null, "0", "Error", output.trim().split("\n")[0]];
    const cause = CAUSES.find(([pattern]) => pattern.test(message));
    const explained = cause ? ` - ${cause[1]}; ${cause[2]}` : "";
    const findings = [{ code: "E-COMPILE", line: Number(at), message: `${kind}: ${message.trim()}${explained}` }];
    if (/Out of (?:local )?registers/.test(message)) findings.push(...familyFinding(readFileSync(file, "utf8")));
    return { findings, functions: [] };
  }

  const source = readFileSync(file, "utf8");
  const functions = measure(listed.stdout);
  const findings = [];
  for (const entry of functions) {
    if (entry.registers >= budget) {
      findings.push({
        code: "W-REGISTERS",
        line: entry.peakLine,
        message: `${describe(entry)} peaks at ${entry.registers} of ${REGISTER_LIMIT} registers ` +
          `(locals stop at ${LOCAL_LIMIT}); move locals into tables or functions now`,
      });
      if (entry.name === "main chunk") findings.push(...familyFinding(source));
    }
    if (entry.upvalues >= Math.min(budget, UPVALUE_LIMIT)) {
      findings.push({
        code: "W-UPVALUES",
        line: entry.first,
        message: `${describe(entry)} uses ${entry.upvalues} of ${UPVALUE_LIMIT} upvalues; pass a context table instead`,
      });
    }
  }
  findings.push(...scopeLeaks(listed.stdout, source));
  return { findings, functions };
}

function main() {
  const args = process.argv.slice(2);
  const json = args.includes("--json");
  let budget = DEFAULT_BUDGET;
  const targets = [];
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === "--budget") budget = Number(args[++index]);
    else if (!args[index].startsWith("--")) targets.push(args[index]);
  }
  if (!Number.isInteger(budget) || budget < 1 || budget > REGISTER_LIMIT || targets.length === 0) {
    console.error("Usage: node tools/bin/check-registers.mjs [--budget N] [--json] <file.luau|directory> [...]");
    process.exit(2);
  }

  const files = targets.flatMap((target) => collect(target));
  const results = [];
  for (const file of files) {
    const outcome = check(file, budget);
    if (outcome.unavailable) {
      console.error(`Luau compiler unavailable; register budget not checked: ${outcome.unavailable}`);
      process.exit(2);
    }
    results.push({ file: relative(REPO_ROOT, file).split(sep).join("/"), ...outcome });
  }

  if (json) {
    console.log(JSON.stringify({ budget, results: results.map(({ file, findings }) => ({ file, findings })) }, null, 2));
  } else {
    for (const { file, findings, functions } of results) {
      const top = [...functions].sort((a, b) => b.registers - a.registers)[0];
      const headroom = top ? `; highest: ${describe(top)} at ${top.registers}/${REGISTER_LIMIT}` : "";
      console.log(`${file}${findings.length ? "" : `  ok${headroom}`}`);
      for (const finding of findings) console.log(`  ${finding.line}: ${finding.code} ${finding.message}`);
    }
    const flagged = results.filter((result) => result.findings.length).length;
    console.log(`\n${files.length} file(s) compiled at -O0, budget ${budget} registers: ${flagged} need work.`);
  }
  if (results.some((result) => result.findings.length)) process.exitCode = 1;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
