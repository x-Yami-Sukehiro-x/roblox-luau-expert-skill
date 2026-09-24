#!/usr/bin/env node
// Build and run the headless harness for library/src.
//
// Toast.luau owns real bookkeeping - a visible set, a capped queue, dedup keys,
// severity preemption and index-derived reflow - and that logic is worth testing
// without Studio. The harness stubs just enough of the engine for it to run
// under the standalone luau binary.
//
// Assembly order:
//   library/tests/stubs.luau        Instance, signals, TweenService, task
//   library/src/*.luau              the real modules, wrapped as require targets
//   library/tests/assertions.luau   the assertions
//
// Usage:
//   node tools/bin/run-library-tests.mjs [--keep]
//
// --keep leaves the generated harness on disk for inspection.

import { readFileSync, writeFileSync, rmSync, existsSync } from "node:fs";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import { REPO_ROOT } from "./lib/dump.mjs";
import { luauRuntime } from "./lib/luau-runtime.mjs";

const TESTS_DIR = join(REPO_ROOT, "library", "tests");
const SRC_DIR = join(REPO_ROOT, "library", "src");
const HARNESS = join(TESTS_DIR, "toastharness.luau");

// Order matters: Tokens has no dependencies, Motion reads Tokens, everything
// else reads one or both. A module is registered under its basename, which is
// what `script.Parent.<Name>` resolves to in the stubs.
const MODULES = [
  "Tokens",
  "Icons",
  "Motion",
  "Toast",
  "Layout",
  "Components/Button",
  "Components/Toggle",
  "Components/Slider",
  "Components/TabBar",
];

// Each is concatenated after the modules, in order.
const ASSERTIONS = ["assertions.luau", "components.luau"];

function read(path) {
  if (!existsSync(path)) {
    console.error(`missing: ${path}`);
    process.exit(2);
  }
  return readFileSync(path, "utf8");
}

function main() {
  const keep = process.argv.includes("--keep");

  const parts = [
    read(join(TESTS_DIR, "stubs.luau")),
    "local __modules = {}",
    "function require(token) return __modules[token] end",
  ];

  for (const path of MODULES) {
    const name = path.split("/").pop();
    const src = read(join(SRC_DIR, `${path}.luau`));
    parts.push(`script.Parent.${name} = "${name}"`);
    parts.push(`__modules["${name}"] = (function()\n${src}\nend)()`);
  }
  for (const file of ASSERTIONS) {
    parts.push(read(join(TESTS_DIR, file)));
  }

  writeFileSync(HARNESS, parts.join("\n"), "utf8");

  const luau = luauRuntime();
  try {
    execFileSync(luau, ["--help"], { stdio: "ignore" });
  } catch {
    console.error(
      `luau not found on PATH (set LUAU_BIN to override).\n` +
        `Install it with: rokit add luau-lang/luau`
    );
    process.exit(2);
  }

  let code = 0;
  let out = "";
  try {
    out = execFileSync(luau, [HARNESS], { encoding: "utf8" });
    process.stdout.write(out);
  } catch (e) {
    out = String(e.stdout ?? "");
    process.stdout.write(out);
    process.stderr.write(String(e.stderr ?? ""));
    code = 1;
  }

  // Each assertion file prints its own tally. check-all.mjs reports the last
  // line of a gate's output as its summary, so without this it reported the
  // second file's count as though it were the whole suite.
  const tallies = [...out.matchAll(/^(\d+) passed, (\d+) failed$/gm)];
  if (tallies.length > 1) {
    const passed = tallies.reduce((total, row) => total + Number(row[1]), 0);
    const failed = tallies.reduce((total, row) => total + Number(row[2]), 0);
    console.log(`${passed} passed, ${failed} failed across ${tallies.length} file(s)`);
  }

  if (!keep) rmSync(HARNESS, { force: true });
  process.exit(code);
}

main();
