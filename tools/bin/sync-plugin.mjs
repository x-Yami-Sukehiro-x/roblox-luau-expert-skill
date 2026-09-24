#!/usr/bin/env node
// Bring the plugin Codex and the ChatGPT desktop app use up to the newest build
// on GitHub's `plugin` branch.
//
// Adds the GitHub marketplace the first time, refreshes its snapshot, and
// reinstalls when the snapshot's version differs from the installed one. The
// workflow stamps each build's version with its source commit, so a different
// version means a newer push was built. Reinstalling replaces the cached copy;
// chats started afterwards read the new files.
//
// Usage:
//   node tools/bin/sync-plugin.mjs
//
// CODEX_BIN overrides where the codex executable is looked for.

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { GITHUB } from "./lib/github.mjs";

function codexBinary() {
  if (process.env.CODEX_BIN) return process.env.CODEX_BIN;
  // The Codex desktop app keeps its CLI here, off PATH, one folder per build.
  const root = join(process.env.LOCALAPPDATA ?? "", "OpenAI", "Codex", "bin");
  const builds = existsSync(root)
    ? readdirSync(root)
        .map((folder) => join(root, folder, "codex.exe"))
        .filter((path) => existsSync(path))
    : [];
  builds.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
  return builds[0] ?? "codex";
}

function codex(bin, args) {
  const result = spawnSync(bin, args, { encoding: "utf8" });
  if (result.error) throw new Error(`cannot run ${bin}: ${result.error.message}`);
  const output = `${result.stdout}${result.stderr}`
    .split("\n")
    .filter((line) => !line.includes("could not create PATH aliases"))
    .join("\n")
    .trim();
  if (result.status !== 0) throw new Error(`codex ${args.join(" ")} failed: ${output}`);
  return result.stdout.trim();
}

function marketplaceRoot(bin) {
  for (const line of codex(bin, ["plugin", "marketplace", "list"]).split("\n")) {
    const [name, ...root] = line.trim().split(/\s+/);
    if (name === GITHUB.marketplace) return root.join(" ");
  }
  return null;
}

function installedVersion(bin) {
  const listed = JSON.parse(codex(bin, ["plugin", "list", "--marketplace", GITHUB.marketplace, "--json"]));
  return listed.installed.find((entry) => entry.name === GITHUB.plugin)?.version;
}

export function syncPlugin() {
  const bin = codexBinary();
  if (!marketplaceRoot(bin)) {
    codex(bin, ["plugin", "marketplace", "add", `${GITHUB.owner}/${GITHUB.repo}`, "--ref", GITHUB.pluginBranch]);
  }
  const before = installedVersion(bin);
  // An upgrade also refreshes an installed plugin; the add below covers a first
  // install and any upgrade that left the cached copy behind.
  codex(bin, ["plugin", "marketplace", "upgrade", GITHUB.marketplace]);

  const manifest = join(marketplaceRoot(bin), "plugins", GITHUB.plugin, "plugin.json");
  const available = JSON.parse(readFileSync(manifest, "utf8")).version;
  if (installedVersion(bin) !== available) codex(bin, ["plugin", "add", `${GITHUB.plugin}@${GITHUB.marketplace}`]);
  return before === available ? `plugin already at ${available}` : `plugin ${before ?? "not installed"} -> ${available}`;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    console.log(syncPlugin());
  } catch (error) {
    console.error(`sync-plugin: ${error.message}`);
    process.exit(1);
  }
}
