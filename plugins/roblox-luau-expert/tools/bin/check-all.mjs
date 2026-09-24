#!/usr/bin/env node
// Run every gate in this repository, in order, and report one verdict.
//
// There are twenty-one of them now. Remembering sixteen commands is how seven get
// run and four get skipped, and the ones that get skipped are the ones that
// were added most recently - which is to say the ones nobody has habits about
// yet.
//
// Usage:
//   node tools/bin/check-all.mjs
//   node tools/bin/check-all.mjs --quick    skip the slow ones (dump, tests)
//
// Exit 1 if any gate fails. Output is one line per gate plus the failures.

import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { REPO_ROOT } from "./lib/dump.mjs";

const bin = (name) => join(REPO_ROOT, "tools", "bin", name);

// The two files the GPT is told to imitate. They are scored in their own README
// and quoted in the UI pack, so an unguarded edit would make that README lie.
const EXEMPLARS = join(REPO_ROOT, "docs", "portability", "gpt", "UIs", "exemplars");

// The implementations the visual guide's labels point at. A model copies these
// when the user answers "T2 + M4", so they are held to the exemplars' bar.
const RECIPES = join(REPO_ROOT, ".claude", "skills", "roblox-ui-components", "assets");

// Scripts a reply hands to the user unchanged, such as the runtime probe.
const EXECUTOR_ASSETS = join(REPO_ROOT, ".claude", "skills", "roblox-executor", "assets");

const GATES = [
  {
    name: "portable package and verdict tests",
    argv: ["--test", ...["check-all", "portable-package", "install", "luau-compile", "dump-index"].map((name) => join(REPO_ROOT, "tools", "tests", `${name}.test.mjs`))],
  },
  {
    name: "prose vs the API dump",
    argv: [bin("lint-prose.mjs")],
  },
  {
    name: "shipped Luau examples",
    argv: [bin("lint-luau-blocks.mjs")],
    slow: true,
  },
  {
    name: "file references resolve",
    argv: [bin("lint-links.mjs")],
  },
  {
    name: "stated contrast ratios",
    argv: [bin("lint-ui-directions.mjs")],
  },
  {
    name: "UI rubric over library/src",
    argv: [bin("lint-roblox-ui.mjs"), join(REPO_ROOT, "library", "src")],
  },
  {
    name: "slop rubric over library/src",
    argv: [bin("lint-luau-slop.mjs"), join(REPO_ROOT, "library", "src")],
  },
  {
    name: "format rubric over library/src",
    argv: [bin("lint-luau-format.mjs"), join(REPO_ROOT, "library", "src")],
  },
  {
    name: "format rubric over the exemplars",
    argv: [bin("lint-luau-format.mjs"), EXEMPLARS],
  },
  {
    name: "Python port matches Node",
    argv: [bin("lint-parity.mjs")],
    slow: true,
  },
  {
    name: "executor globals documented",
    argv: [bin("verify-executor-api.mjs"), "--audit"],
  },
  {
    name: "generated tables match the dump",
    argv: [bin("generate-tables.mjs"), "--check"],
  },
  {
    name: "host rule files are current",
    argv: [bin("build-portable.mjs"), "--check"],
  },
  {
    name: "UI rubric over the exemplars",
    argv: [bin("lint-roblox-ui.mjs"), EXEMPLARS],
  },
  {
    name: "slop rubric over the exemplars",
    argv: [bin("lint-luau-slop.mjs"), EXEMPLARS],
  },
  {
    name: "UI rubric over the style recipes",
    argv: [bin("lint-roblox-ui.mjs"), RECIPES],
  },
  {
    name: "slop rubric over the style recipes",
    argv: [bin("lint-luau-slop.mjs"), RECIPES],
  },
  {
    name: "format rubric over the style recipes",
    argv: [bin("lint-luau-format.mjs"), RECIPES],
  },
  {
    name: "slop rubric over the executor assets",
    argv: [bin("lint-luau-slop.mjs"), EXECUTOR_ASSETS],
  },
  {
    name: "format rubric over the executor assets",
    argv: [bin("lint-luau-format.mjs"), EXECUTOR_ASSETS],
  },
  {
    name: "asset ids are real images",
    argv: [bin("verify-asset-ids.mjs"), join(REPO_ROOT, "library", "src"), EXEMPLARS, RECIPES],
    slow: true,
  },
  {
    name: "library assertions",
    argv: [bin("run-library-tests.mjs")],
    slow: true,
  },
  {
    name: "style recipe behaviour",
    argv: [bin("run-recipe-tests.mjs")],
    slow: true,
  },
];

export function classifyGate(result) {
  const output = `${result.stdout ?? ""}${result.stderr ?? ""}`.trim();
  if (result.error || result.signal || result.status === null) {
    return { status: "FAIL", output: output || String(result.error ?? result.signal) };
  }
  if (result.status === 2) return { status: "SKIP", output };
  if (result.status !== 0) return { status: "FAIL", output };
  const partial = output.split("\n").find((line) =>
    /^\s*SKIP\b|^\s*\([^)]*\bwas skipped\b|^[ℹ#\s]*(?:skipped|skip)\s+[1-9]\d*\b/.test(line)
  );
  return { status: partial ? "PART" : "PASS", output, partial };
}

function main() {
  const quick = process.argv.includes("--quick");
  const gates = quick ? GATES.filter((gate) => !gate.slow) : GATES;

  const failures = [];
  const counts = { PASS: 0, PART: 0, SKIP: 0, FAIL: 0 };

  for (const gate of gates) {
    const result = spawnSync(process.execPath, gate.argv, { encoding: "utf8" });
    const { status, output, partial } = classifyGate(result);
    counts[status] += 1;

    // Exit 2 is a tool that could not run - a missing luau binary, say. That is
    // worth saying out loud rather than folding into "failed", because the fix
    // is completely different.
    if (status === "SKIP") {
      console.log(`SKIP  ${gate.name}`);
      const reason = output.split("\n").find((line) => line.trim()) ?? "could not run";
      console.log(`      ${reason}`);
      continue;
    }

    if (status === "PASS" || status === "PART") {
      const summary = output
        .split("\n")
        .reverse()
        .find((line) => line.trim());
      console.log(`${status}  ${gate.name.padEnd(34)} ${summary ? summary.trim() : ""}`);
      if (partial && partial.trim() !== summary?.trim()) console.log(`      ${partial.trim()}`);
      continue;
    }

    console.log(`FAIL  ${gate.name}`);
    failures.push({ gate, output });
  }

  if (failures.length > 0) {
    for (const failure of failures) {
      console.log(`\n--- ${failure.gate.name} ---`);
      console.log(failure.output);
    }
    console.log(`\n${failures.length} of ${gates.length} gate(s) failed.`);
    process.exit(1);
  }

  console.log(`\n${counts.PASS} passed, ${counts.PART} partial, ${counts.SKIP} skipped, 0 failed.`);
  if (quick) console.log(`${GATES.length - gates.length} slow gate(s) not selected (--quick).`);
  if (counts.PART || counts.SKIP) {
    console.log("Validation is incomplete; skipped checks are not passes.");
    process.exitCode = 2;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
