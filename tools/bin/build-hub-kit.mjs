#!/usr/bin/env node
// Bundle library/hub-kit/src into dist/HubKit.luau, one file an executor can
// run with loadstring.
//
// The sources are ordinary ModuleScripts that require each other the Rojo way,
// `require(script.Parent.Parent.Core.Theme)`, so the same folder works in
// Studio. An executor has no instance tree to walk, so each require is
// resolved here, statically, to a module id and rewritten as a call into a
// table of module functions. A require this cannot resolve (a variable, a
// string path, a Parent above the root) is an error, not a guess: the bundle
// would otherwise fail at run time in somebody's executor.
//
// Resolution follows Rojo: `Core/Theme.luau` is the instance Core.Theme, and
// `Elements/init.luau` is the instance Elements itself, so `script.Button`
// inside it is Elements.Button.
//
// Usage:
//   node tools/bin/build-hub-kit.mjs          write dist/HubKit.luau
//   node tools/bin/build-hub-kit.mjs --check  exit 1 if the bundle is stale

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { pathToFileURL } from "node:url";
import { REPO_ROOT } from "./lib/dump.mjs";

export const KIT = join(REPO_ROOT, "library", "hub-kit");
const SRC = join(KIT, "src");
export const BUNDLE = join(KIT, "dist", "HubKit.luau");

const REQUIRE = /require\(\s*([^()]*)\s*\)/g;
const SCRIPT_PATH = /^script(?:\.[A-Za-z_]\w*)*$/;

function listModules(dir, prefix = []) {
  const modules = [];
  for (const entry of readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      modules.push(...listModules(full, [...prefix, entry.name]));
    } else if (entry.name.endsWith(".luau")) {
      const name = entry.name.slice(0, -".luau".length);
      const segments = name === "init" ? prefix : [...prefix, name];
      modules.push({ id: segments.join("/"), segments, path: full });
    }
  }
  return modules;
}

function resolveRequire(module, expression, ids, line) {
  const where = `${relative(REPO_ROOT, module.path).split("\\").join("/")}:${line}`;
  if (!SCRIPT_PATH.test(expression)) {
    throw new Error(`${where}: require(${expression}) is not a script.* path the bundler can resolve`);
  }
  const target = [...module.segments];
  for (const step of expression.split(".").slice(1)) {
    if (step === "Parent") {
      if (target.length === 0) throw new Error(`${where}: require(${expression}) climbs above src/`);
      target.pop();
    } else {
      target.push(step);
    }
  }
  const id = target.join("/");
  if (!ids.has(id)) throw new Error(`${where}: require(${expression}) names ${id || "the root"}, which is not a module`);
  return id;
}

export function bundle() {
  const modules = listModules(SRC);
  const ids = new Set(modules.map((module) => module.id));
  const root = readFileSync(join(SRC, "init.luau"), "utf8");
  const version = /Version = "([^"]+)"/.exec(root)?.[1] ?? "unversioned";

  const parts = [
    `-- HubKit ${version}: library/hub-kit/src bundled into one file by tools/bin/build-hub-kit.mjs.`,
    "-- Generated; edit the sources and rebuild rather than editing this file.",
    "local modules = {}",
    "local loaded = {}",
    "local loading = {}",
    "",
    "local function requireModule(id)",
    "\tlocal cached = loaded[id]",
    "\tif cached == nil then",
    "\t\tassert(not loading[id], `require cycle through {id}`)",
    "\t\tloading[id] = true",
    "\t\tcached = modules[id]()",
    "\t\tloaded[id] = cached",
    "\tend",
    "\treturn cached",
    "end",
  ];

  for (const module of modules) {
    const source = readFileSync(module.path, "utf8").replace(/\r\n/g, "\n");
    const rewritten = source
      .split("\n")
      .map((text, index) => {
        if (/^--!(strict|nonstrict|nocheck)\s*$/.test(text)) return null;
        const line = text.replace(/^export type /, "type ");
        return line.replace(REQUIRE, (_, expression) => `requireModule("${resolveRequire(module, expression.trim(), ids, index + 1)}")`);
      })
      .filter((line) => line !== null)
      .join("\n")
      .trimEnd();
    parts.push("", `modules["${module.id}"] = function()`, rewritten, "end");
  }
  parts.push("", `return requireModule("")`, "");
  return parts.join("\n");
}

function main() {
  const text = bundle();
  if (process.argv.includes("--check")) {
    const current = existsSync(BUNDLE) ? readFileSync(BUNDLE, "utf8").replace(/\r\n/g, "\n") : "";
    if (current !== text) {
      console.error("library/hub-kit/dist/HubKit.luau is stale - run node tools/bin/build-hub-kit.mjs");
      process.exit(1);
    }
    console.log(`library/hub-kit/dist/HubKit.luau matches ${relative(REPO_ROOT, SRC).split("\\").join("/")}`);
    return;
  }
  mkdirSync(dirname(BUNDLE), { recursive: true });
  writeFileSync(BUNDLE, text, "utf8");
  const lines = text.split("\n").length;
  console.log(`library/hub-kit/dist/HubKit.luau  ${listModules(SRC).length} modules, ${lines} lines`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
