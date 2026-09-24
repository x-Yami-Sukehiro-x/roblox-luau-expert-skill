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
// Usage:
//   node tools/bin/check-registers.mjs <file.luau|directory> [...]
//   node tools/bin/check-registers.mjs --budget 120 <file>    warn earlier
//   node tools/bin/check-registers.mjs --json <file>
//
// Exit 1 when a file does not compile or a function is over budget; exit 2
// when no Luau compiler is available. Python port: tools/py/register_budget.py.

import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, statSync, chmodSync } from "node:fs";
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
    return { findings: [{ code: "E-COMPILE", line: Number(at), message: `${kind}: ${message.trim()}${explained}` }], functions: [] };
  }

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
    }
    if (entry.upvalues >= Math.min(budget, UPVALUE_LIMIT)) {
      findings.push({
        code: "W-UPVALUES",
        line: entry.first,
        message: `${describe(entry)} uses ${entry.upvalues} of ${UPVALUE_LIMIT} upvalues; pass a context table instead`,
      });
    }
  }
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
