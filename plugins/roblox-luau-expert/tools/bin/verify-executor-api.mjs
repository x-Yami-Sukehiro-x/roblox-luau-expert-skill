#!/usr/bin/env node
// Look up an executor function against the vendored sUNC reference.
//
// verify-api.mjs answers for Roblox APIs and correctly reports every executor
// function as absent, because the API dump does not contain them. That left the
// executor half with no mechanical gate at all - and it is the half where
// inventing a plausible name is easiest, because the naming is inconsistent and
// half the internet's examples are wrong.
//
// This is the same contract as verify-api.mjs: a non-zero exit is the signal
// you were about to invent something.
//
// Usage:
//   node tools/bin/verify-executor-api.mjs hookmetamethod
//   node tools/bin/verify-executor-api.mjs --list
//   node tools/bin/verify-executor-api.mjs --audit
//   node tools/bin/verify-executor-api.mjs --json getgc
//
// Exit 1 when the name is not documented, or when --audit finds a global the
// block linter accepts that no reference file explains.

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";
import { resolveSkillPath, missingSkillsMessage } from "./lib/skills.mjs";

// Resolved rather than hardcoded: install.ps1 puts tools/ and the skills in two
// different places, so a path relative to this file only works in the repo.
const EXECUTOR_REFERENCES = resolveSkillPath("roblox-executor", "references");

const API_DIR = EXECUTOR_REFERENCES ? join(EXECUTOR_REFERENCES, "api") : null;

// Two surfaces are documented where they are used rather than in api/, because
// neither makes sense without the technique around it.
const EXTRA_SOURCES = EXECUTOR_REFERENCES
  ? [
      join(EXECUTOR_REFERENCES, "technique", "actors-parallel.md"),
      join(EXECUTOR_REFERENCES, "technique", "raknet.md"),
      join(EXECUTOR_REFERENCES, "recon", "thread-identity.md"),
    ]
  : [];

/**
 * Build the index from the reference files.
 *
 * Two shapes carry a name: a `## name` heading, and a `function name(...)`
 * signature inside a Luau block. The heading is what makes something a
 * documented entry; the signature is what makes the answer useful.
 */
function loadIndex() {
  if (!API_DIR || !existsSync(API_DIR)) {
    console.error(missingSkillsMessage("roblox-executor/references/api"));
    process.exit(2);
  }

  const index = new Map();

  const sources = [
    ...readdirSync(API_DIR)
      .filter((entry) => entry.endsWith(".md"))
      .map((entry) => join(API_DIR, entry)),
    ...EXTRA_SOURCES.filter(existsSync),
  ];

  for (const path of sources) {
    const rel = relative(REPO_ROOT, path).split(sep).join("/");
    const lines = readFileSync(path, "utf8").split(/\r?\n/);

    let current = null;

    for (const [number, line] of lines.entries()) {
      const heading = /^##+\s+`?([A-Za-z_][\w.]*)`?\s*$/.exec(line);
      if (heading) {
        current = heading[1];
        if (!index.has(current)) {
          index.set(current, { name: current, file: rel, line: number + 1, signature: null });
        }
        continue;
      }

      // A line may declare siblings: `function mouse1click() / mouse1press()`.
      // Capturing only the first name is why mouse1press read as undocumented.
      if (/^\s*function\s/.test(line)) {
        for (const call of line.matchAll(/([A-Za-z_][\w.]*)\s*\(/g)) {
          const name = call[1];
          if (name === "function" || STOPWORDS.has(name)) continue;
          const record = index.get(name) ?? { name, file: rel, line: number + 1, signature: null };
          record.signature = line.trim();
          record.file = rel;
          if (!index.has(name)) record.line = number + 1;
          index.set(name, record);
        }
        continue;
      }

      // A signature written without the `function` keyword, which is how the
      // technique files list the Actor and packet surfaces:
      //   getactorthreads(): {thread}
      const bare = /^\s*([a-z_][\w]*)\s*\([^)]*\)\s*:/.exec(line);
      if (bare && !STOPWORDS.has(bare[1])) {
        const name = bare[1];
        const record = index.get(name) ?? { name, file: rel, line: number + 1, signature: null };
        record.signature = record.signature ?? line.trim();
        index.set(name, record);
      }

      // Names documented in prose and tables rather than under a heading -
      // `getrawmetatable`, `crypt.encrypt`, `Drawing.new`. Indexing these
      // errs toward inclusion on purpose: a missed real function makes this
      // tool report that something real does not exist, which is a far worse
      // failure than indexing an extra word.
      for (const match of line.matchAll(/`([A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)?)`/g)) {
        const name = match[1];
        if (index.has(name) || STOPWORDS.has(name)) continue;
        if (!name.includes(".") && name.length < 4) continue;
        index.set(name, { name, file: rel, line: number + 1, signature: null });
      }
    }

    void current;
  }

  return index;
}

// Luau keywords, globals and prose that would otherwise be indexed as names.
const STOPWORDS = new Set([
  "function", "local", "return", "true", "false", "nil", "then", "else",
  "elseif", "while", "repeat", "until", "break", "continue", "and", "not",
  "string", "table", "number", "boolean", "thread", "userdata", "vector",
  "buffer", "pcall", "xpcall", "typeof", "type", "print", "warn", "error",
  "assert", "select", "unpack", "pairs", "ipairs", "next", "tostring",
  "tonumber", "setmetatable", "getmetatable", "rawget", "rawset", "rawequal",
  "require", "coroutine", "task", "math", "game", "workspace", "script",
  "Instance", "Enum", "Vector2", "Vector3", "CFrame", "Color3", "UDim", "UDim2",
  "Players", "RunService", "self", "args", "value", "index", "name", "method",
  "object", "target", "source", "result", "callback", "handler", "instance",
]);

/** Cheap edit distance, capped: only used to suggest, never to decide. */
function distance(a, b) {
  const rows = Array.from({ length: a.length + 1 }, (_, i) => [i, ...Array(b.length).fill(0)]);
  for (let j = 0; j <= b.length; j += 1) rows[0][j] = j;
  for (let i = 1; i <= a.length; i += 1) {
    for (let j = 1; j <= b.length; j += 1) {
      rows[i][j] = Math.min(
        rows[i - 1][j] + 1,
        rows[i][j - 1] + 1,
        rows[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)
      );
    }
  }
  return rows[a.length][b.length];
}

function suggest(index, query) {
  const lowered = query.toLowerCase();
  return [...index.keys()]
    .map((name) => ({ name, score: distance(lowered, name.toLowerCase()) }))
    .filter((entry) => entry.score <= Math.max(2, Math.floor(query.length / 3)))
    .sort((a, b) => a.score - b.score)
    .slice(0, 5)
    .map((entry) => entry.name);
}

/**
 * One resolution path, shared by lookup and the coverage audit.
 *
 * A bare `getconstants` means `debug.getconstants`, and `crypt` is real
 * because its members are - both are how the reference actually writes them.
 */
function resolveName(index, query) {
  const lowered = query.toLowerCase();
  return (
    index.get(query) ??
    [...index.values()].find((entry) => entry.name.toLowerCase() === lowered) ??
    (query.includes(".")
      ? null
      : [...index.values()].find((entry) => entry.name.toLowerCase().endsWith(`.${lowered}`)) ??
        [...index.values()].find((entry) => entry.name.toLowerCase().startsWith(`${lowered}.`))) ??
    null
  );
}

function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const wantsList = args.includes("--list");
  const wantsAudit = args.includes("--audit");
  const query = args.find((a) => !a.startsWith("--"));

  const index = loadIndex();

  if (wantsList) {
    const names = [...index.keys()].sort();
    if (asJson) console.log(JSON.stringify({ count: names.length, names }, null, 2));
    else {
      for (const name of names) console.log(name);
      console.log(`\n${names.length} documented executor name(s)`);
    }
    return;
  }

  if (wantsAudit) {
    // Every executor global lint-luau-blocks accepts in an example has to be
    // documented somewhere a reader can reach. Otherwise the block linter waves
    // a name through and this tool then reports it as invented - two gates
    // disagreeing about what exists, which is worse than either alone.
    const linter = join(REPO_ROOT, "tools", "bin", "lint-luau-blocks.mjs");
    const block = /const EXECUTOR_GLOBALS = new Set\(\[([\s\S]*?)\]\);/.exec(
      readFileSync(linter, "utf8")
    );
    if (!block) {
      console.error("could not find EXECUTOR_GLOBALS in lint-luau-blocks.mjs");
      process.exit(2);
    }

    const globals = [...block[1].matchAll(/"([^"]+)"/g)].map((m) => m[1]);
    const missing = globals.filter((name) => !resolveName(index, name));

    if (asJson) {
      console.log(JSON.stringify({ checked: globals.length, missing }, null, 2));
    } else {
      for (const name of missing) {
        console.log(
          `UNDOCUMENTED  ${name}  - accepted by lint-luau-blocks, absent from references/api/`
        );
      }
      console.log(`\n${globals.length} global(s) checked - ${missing.length} undocumented`);
    }

    if (missing.length > 0) process.exit(1);
    return;
  }

  if (!query) {
    console.error(
      "usage: node tools/bin/verify-executor-api.mjs <name>\n" +
        "       node tools/bin/verify-executor-api.mjs --list\n" +
        "       node tools/bin/verify-executor-api.mjs --audit"
    );
    process.exit(2);
  }

  const exact = resolveName(index, query);

  if (exact) {
    if (asJson) {
      console.log(JSON.stringify({ found: true, ...exact }, null, 2));
    } else {
      console.log(exact.name);
      if (exact.signature) console.log(`  ${exact.signature}`);
      console.log(`  documented in ${exact.file}:${exact.line}`);
      console.log(
        `  FEATURE-DETECT IT: support varies per executor and per update.\n` +
          `    if typeof(${exact.name.split(".")[0]}) ~= "function" then ... end`
      );
    }
    return;
  }

  const near = suggest(index, query);

  if (asJson) {
    console.log(JSON.stringify({ found: false, query, suggestions: near }, null, 2));
  } else {
    console.log(`NOT FOUND in the sUNC reference: ${query}`);
    if (near.length > 0) console.log(`  did you mean: ${near.join(", ")}`);
    console.log(
      `  This is the signal that you were about to invent an executor function.\n` +
        `  Say it does not exist. Do not write it anyway with a hedge.\n` +
        `  Roblox APIs are a different question - use tools/bin/verify-api.mjs.`
    );
  }

  process.exit(1);
}

main();
