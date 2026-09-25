#!/usr/bin/env node
// Every file-level check on a Luau file, in one call, run in parallel.
//
// A reply that runs eight checks one after another spends most of its wait on
// process start-up and on reading eight outputs. This runs them together and
// prints one line per check, with the full output only for a check that failed.
//
// Usage:
//   node tools/bin/check-file.mjs <file.luau> [more.luau ...]
//   node tools/bin/check-file.mjs --compare <before.luau> <after.luau>
//
// Exit 0 when every check passes, 1 when any fails, 2 when a check could not
// run (no Python, no luau binary) and none failed. A skipped check is not a pass.

import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { join, relative } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

const PYTHON = process.env.PYTHON ?? (process.platform === "win32" ? "python" : "python3");
const GUI_CLASS =
  /Instance\.new\(\s*"(ScreenGui|BillboardGui|SurfaceGui|Frame|CanvasGroup|ScrollingFrame|TextLabel|TextButton|TextBox|ImageLabel|ImageButton)"/;

const node = (script, ...args) => [process.execPath, [join(REPO_ROOT, "tools", "bin", script), ...args]];
const python = (script, ...args) => [PYTHON, [join(REPO_ROOT, "tools", "py", script), ...args]];

function checksFor(file, before) {
  const drawn = GUI_CLASS.test(readFileSync(file, "utf8"));
  return [
    ["slop", before ? node("lint-luau-slop.mjs", "--compare", before, file) : node("lint-luau-slop.mjs", file)],
    ["format", node("lint-luau-format.mjs", file)],
    ["ui", drawn ? node("lint-roblox-ui.mjs", file) : null],
    ["api", python("verify_api.py", "--scan", file)],
    ["compile", python("check_luau.py", file)],
    ["registers", node("check-registers.mjs", file)],
    ["viewport", drawn ? python("viewport_fit.py", file) : null],
    ["ledger", node("attempt-ledger.mjs", "check", file)],
  ];
}

function run([command, args]) {
  return new Promise((resolve) => {
    execFile(command, args, { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 }, (error, stdout, stderr) => {
      const output = `${stdout ?? ""}${stderr ?? ""}`.trim();
      const code = error ? (typeof error.code === "number" ? error.code : 2) : 0;
      resolve({ code, output });
    });
  });
}

// The line a person would read first: a score, a verdict or a highest register.
function headline(name, output) {
  const lines = output.split("\n").map((line) => line.trim());
  const score = lines.find((line) => line.startsWith("score "));
  if (score) return score.replace(/^score /, "");
  if (name === "registers") return lines.find((line) => / ok; highest/.test(line))?.replace(/^.*ok; /, "") ?? "";
  if (name === "api") return lines.find((line) => /every resolved member/.test(line)) ?? "";
  if (name === "compile") return "compiles; not executed";
  if (name === "viewport" || name === "ledger") return lines.filter(Boolean).at(-1) ?? "";
  return "";
}

async function main() {
  const argv = process.argv.slice(2);
  let before = null;
  if (argv[0] === "--compare") {
    before = argv[1];
    argv.splice(0, 2);
    if (!before || argv.length !== 1) {
      console.error("usage: check-file.mjs --compare <before.luau> <after.luau>");
      process.exit(2);
    }
  }
  if (argv.length === 0) {
    console.error("usage: check-file.mjs <file.luau> [more.luau ...]");
    process.exit(2);
  }

  const jobs = argv.flatMap((file) => checksFor(file, before).map(([name, command]) => ({ file, name, command })));
  const results = await Promise.all(jobs.map((job) => (job.command ? run(job.command) : null)));

  const tally = { PASS: 0, FAIL: 0, SKIP: 0 };
  let current = null;
  jobs.forEach((job, index) => {
    if (job.file !== current) {
      current = job.file;
      console.log(relative(process.cwd(), job.file).split("\\").join("/"));
    }
    const result = results[index];
    if (result === null) {
      console.log(`  n/a   ${job.name.padEnd(10)} builds no GUI`);
      return;
    }
    const status = result.code === 0 ? "PASS" : result.code === 2 ? "SKIP" : "FAIL";
    tally[status] += 1;
    const lines = result.output.split("\n");
    const failure = lines.find((line) => /\bE-[A-Z]|Error/.test(line)) ?? lines[0];
    const detail = status === "PASS" ? headline(job.name, result.output) : failure.trim();
    console.log(`  ${status.padEnd(5)} ${job.name.padEnd(10)} ${detail}`);
    if (status === "FAIL") {
      for (const line of lines) console.log(`        ${line}`);
    }
  });

  console.log(`\n${tally.PASS} passed, ${tally.FAIL} failed, ${tally.SKIP} could not run.`);
  process.exitCode = tally.FAIL ? 1 : tally.SKIP ? 2 : 0;
}

main();
