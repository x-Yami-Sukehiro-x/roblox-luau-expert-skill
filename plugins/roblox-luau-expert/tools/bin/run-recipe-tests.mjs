#!/usr/bin/env node
// Run the behaviour tests for the style recipes the visual guide labels point at,
// and for the executor assets a reply hands to the user as-is.
//
// Each recipe in .claude/skills/roblox-ui-components/assets/ is the one
// implementation a label such as T2 or N4 means. A model copies it, so it has to
// work: every file is loaded into the engine stubs with its own test and run
// under the standalone luau binary. The stubs model signals and property
// writes, not rendering, so this proves callbacks and state, never pixels.
//
// Usage:
//   node tools/bin/run-recipe-tests.mjs [--keep]

import { existsSync, readFileSync, writeFileSync, rmSync, readdirSync, mkdtempSync } from "node:fs";
import { join, basename } from "node:path";
import { tmpdir } from "node:os";
import { execFileSync } from "node:child_process";
import { REPO_ROOT } from "./lib/dump.mjs";
import { luauRuntime } from "./lib/luau-runtime.mjs";

// Every skill's assets folder: a new skill that ships Luau is tested without
// anyone remembering to list it here.
const SKILLS = join(REPO_ROOT, ".claude", "skills");
const RECIPE_DIRS = readdirSync(SKILLS)
  .sort()
  .map((skill) => join(SKILLS, skill, "assets"))
  .filter((dir) => existsSync(dir));
const TESTS = join(REPO_ROOT, "library", "tests", "recipes");
const STUBS = join(REPO_ROOT, "library", "tests", "stubs.luau");

function main() {
  const keep = process.argv.includes("--keep");
  const luau = luauRuntime();
  try {
    execFileSync(luau, ["--help"], { stdio: "ignore" });
  } catch {
    console.error("luau not found (set LUAU_BIN to override).");
    process.exit(2);
  }

  const stubs = readFileSync(STUBS, "utf8");
  const work = mkdtempSync(join(tmpdir(), "recipe-tests-"));
  const recipes = RECIPE_DIRS.flatMap((dir) =>
    readdirSync(dir).filter((name) => name.endsWith(".luau")).sort().map((name) => ({ dir, name }))
  );
  let passed = 0;
  let failed = 0;
  let broken = 0;

  for (const { dir, name } of recipes) {
    const testPath = join(TESTS, name);
    let test;
    try {
      test = readFileSync(testPath, "utf8");
    } catch {
      console.error(`${name}: no test at library/tests/recipes/${name}`);
      broken += 1;
      continue;
    }
    const recipe = readFileSync(join(dir, name), "utf8").replace(/^--!strict\s*$/m, "");
    const harness = join(work, `harness-${basename(name)}`);
    writeFileSync(harness, `${stubs}\nlocal function __recipe()\n${recipe}\nend\n${test}`, "utf8");

    let out = "";
    try {
      out = execFileSync(luau, [harness], { encoding: "utf8" });
    } catch (e) {
      out = String(e.stdout ?? "") + String(e.stderr ?? "");
      broken += 1;
    }
    for (const line of out.split("\n")) {
      if (line.startsWith("FAIL")) console.log(`${name}: ${line}`);
    }
    const tally = /^(\d+) passed, (\d+) failed$/m.exec(out);
    if (!tally) {
      console.error(`${name}: did not finish\n${out.trim().split("\n").slice(-5).join("\n")}`);
      broken += 1;
      continue;
    }
    passed += Number(tally[1]);
    failed += Number(tally[2]);
  }

  if (!keep) rmSync(work, { recursive: true, force: true });
  console.log(`${passed} passed, ${failed} failed across ${recipes.length} recipe(s)`);
  process.exit(failed || broken ? 1 : 0);
}

main();
