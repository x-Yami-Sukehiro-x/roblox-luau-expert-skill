#!/usr/bin/env node
// Prove the Python port and the Node original agree, finding for finding.
//
// Two implementations of one rule set drift. The drift is silent and it is
// one-directional in the worst way: the host that most needs the gate - a
// custom GPT, which has Python and no Node - is the host nobody runs the Node
// gate in, so a Python check that quietly stopped firing would look like clean
// code for months.
//
// So the port is not trusted, it is compared. Every Luau file in the repo goes
// through both, and any difference in code, line or message fails.
//
// Usage:
//   node tools/bin/lint-parity.mjs            every Luau file in the repo
//   node tools/bin/lint-parity.mjs <path>     one file or directory

import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

// Two implementations each, and each pair must agree exactly.
const PAIRS = {
  slop: {
    node: join(REPO_ROOT, "tools", "bin", "lint-luau-slop.mjs"),
    python: join(REPO_ROOT, "tools", "py", "roblox_lint.py"),
  },
  ui: {
    node: join(REPO_ROOT, "tools", "bin", "lint-roblox-ui.mjs"),
    python: join(REPO_ROOT, "tools", "py", "ui_lint.py"),
  },
  format: {
    node: join(REPO_ROOT, "tools", "bin", "lint-luau-format.mjs"),
    python: join(REPO_ROOT, "tools", "py", "format_lint.py"),
  },
};

// Where Luau that the linters are calibrated against lives. Skipping the rest
// of the repo keeps the gate fast; the rules are the same either way.
const DEFAULT_TARGETS = ["library", "evals", "docs/portability/gpt/UIs/exemplars"];

function collect(target, out = []) {
  if (!existsSync(target)) return out;
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

function pythonCommand() {
  for (const candidate of ["python", "python3", "py"]) {
    try {
      execFileSync(candidate, ["--version"], { stdio: "ignore" });
      return candidate;
    } catch {
      continue;
    }
  }
  return null;
}

function run(command, args) {
  try {
    return execFileSync(command, args, { encoding: "utf8", maxBuffer: 32 * 1024 * 1024 });
  } catch (error) {
    // Both linters exit 1 when they find something, which is not a failure to
    // run. Only a missing stdout is.
    if (error.stdout) return error.stdout;
    throw error;
  }
}

function findingsOf(json, file) {
  const parsed = JSON.parse(json);
  const result = parsed.results.find((entry) => entry.file.endsWith(file)) ?? parsed.results[0];
  return (result?.findings ?? []).map((finding) => `${finding.code}:${finding.line}:${finding.message}`);
}

function main() {
  const python = pythonCommand();
  if (!python) {
    console.error("no python on PATH - the parity gate cannot run");
    process.exit(2);
  }

  const flags = process.argv.slice(2).filter((arg) => arg.startsWith("--"));
  const only = flags.filter((flag) => PAIRS[flag.slice(2)]).map((flag) => flag.slice(2));
  const pairs = only.length > 0 ? only : Object.keys(PAIRS);
  const requested = process.argv.slice(2).filter((arg) => !arg.startsWith("--"));
  const roots = requested.length > 0 ? requested : DEFAULT_TARGETS;

  const files = [];
  for (const root of roots) {
    const full = existsSync(root) ? root : join(REPO_ROOT, root);
    collect(full, files);
  }

  if (files.length === 0) {
    console.error("no Luau files found");
    process.exit(2);
  }

  let mismatched = 0;
  for (const name of pairs) {
    const pair = PAIRS[name];
    for (const file of files) {
      const rel = relative(REPO_ROOT, file).split(sep).join("/");
      const fromNode = findingsOf(run("node", [pair.node, "--json", file]), rel);
      const fromPython = findingsOf(run(python, [pair.python, "--json", file]), rel);

      const onlyNode = fromNode.filter((finding) => !fromPython.includes(finding));
      const onlyPython = fromPython.filter((finding) => !fromNode.includes(finding));
      if (onlyNode.length === 0 && onlyPython.length === 0) continue;

      mismatched += 1;
      console.error(`\n${name}  ${rel}`);
      for (const finding of onlyNode) console.error(`  node only    ${finding}`);
      for (const finding of onlyPython) console.error(`  python only  ${finding}`);
    }
  }

  console.log(
    `\n${files.length} file(s) x ${pairs.length} linter pair(s) - ${mismatched} disagreement(s)` +
      (mismatched === 0 ? ". Every port is current." : ".")
  );
  if (mismatched > 0) process.exitCode = 1;
}

main();
