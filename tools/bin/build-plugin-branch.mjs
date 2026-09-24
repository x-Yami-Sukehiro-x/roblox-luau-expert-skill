#!/usr/bin/env node
// Build the tree of the `plugin` branch, which Codex and the ChatGPT desktop app
// install the plugin from.
//
// GitHub's workflow runs this after the gates pass on a push to main, and commits
// the result to the branch. The tree holds a marketplace listing one plugin, the
// plugin itself, and `files/`: a flat copy of the skill text for a custom GPT
// Action. The Action reads files from raw.githubusercontent.com one name at a
// time, and a path parameter there cannot contain a slash, so `skills/a/b.md`
// is published as `skills__a__b.md`.
//
// Output (gitignored):
//   dist/plugin-branch/.agents/plugins/marketplace.json
//   dist/plugin-branch/plugins/roblox-luau-expert/
//   dist/plugin-branch/files/index.json and the flat copies
//
// Usage:
//   node tools/bin/build-plugin-branch.mjs [--source-sha <sha>]

import { spawnSync } from "node:child_process";
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { extname, join } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";
import { GITHUB } from "./lib/github.mjs";
import { collectPackageFiles } from "./lib/portable-package.mjs";

const OUT = join(REPO_ROOT, "dist", "plugin-branch");
const BUILT = join(REPO_ROOT, "dist", "openai-plugin", GITHUB.plugin);

const FLAT_TYPES = new Set([".md", ".luau", ".lua", ".txt", ".json", ".html"]);
// A GPT Action response over roughly 100,000 characters is rejected outright.
const FLAT_LIMIT = 95_000;

function argument(name) {
  const at = process.argv.indexOf(name);
  return at === -1 ? null : process.argv[at + 1];
}

function buildPlugin() {
  const built = spawnSync(process.execPath, [join(REPO_ROOT, "tools", "bin", "build-openai-plugin.mjs")], {
    encoding: "utf8",
    stdio: "inherit",
  });
  if (built.status !== 0) throw new Error(`build-openai-plugin.mjs exited ${built.status}`);
}

function writeJson(path, value) {
  writeFileSync(path, JSON.stringify(value, null, 2) + "\n", "utf8");
}

function main() {
  const sourceSha = argument("--source-sha");
  buildPlugin();
  rmSync(OUT, { recursive: true, force: true });

  const plugin = join(OUT, "plugins", GITHUB.plugin);
  cpSync(BUILT, plugin, { recursive: true });
  const manifestPath = join(plugin, "plugin.json");
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  // sync-plugin.mjs reinstalls when this differs from the installed version.
  if (sourceSha) manifest.version = `${manifest.version}+g${sourceSha.slice(0, 7)}`;
  writeJson(manifestPath, manifest);

  // Codex clones this branch on Windows too; converting line endings there would
  // change the bytes the plugin's own checkers read.
  writeFileSync(join(OUT, ".gitattributes"), "* -text\n", "utf8");
  mkdirSync(join(OUT, ".agents", "plugins"), { recursive: true });
  writeJson(join(OUT, ".agents", "plugins", "marketplace.json"), {
    name: GITHUB.marketplace,
    interface: { displayName: "Roblox Luau Expert (GitHub)" },
    plugins: [
      {
        name: GITHUB.plugin,
        source: { source: "local", path: `./plugins/${GITHUB.plugin}` },
        policy: { installation: "AVAILABLE", authentication: "ON_INSTALL" },
        category: "Coding",
      },
    ],
  });

  const flat = join(OUT, "files");
  mkdirSync(flat, { recursive: true });
  const listed = [];
  const skipped = [];
  for (const file of collectPackageFiles(plugin, ["skills", "docs", "library", "AGENTS.md"])) {
    if (!FLAT_TYPES.has(extname(file.path))) continue;
    if (file.bytes.length > FLAT_LIMIT) {
      skipped.push({ path: file.path, bytes: file.bytes.length });
      continue;
    }
    const name = file.path.replaceAll("/", "__");
    writeFileSync(join(flat, name), file.bytes);
    listed.push({ name, path: file.path, bytes: file.bytes.length });
  }
  writeJson(join(flat, "index.json"), {
    repository: `${GITHUB.owner}/${GITHUB.repo}`,
    source: sourceSha,
    version: manifest.version,
    files: listed,
    tooLargeForAnAction: skipped,
  });

  writeFileSync(
    join(OUT, "README.md"),
    `# ${GITHUB.plugin} - built plugin\n\n` +
      `Generated from \`${GITHUB.sourceBranch}\`${sourceSha ? ` at ${sourceSha.slice(0, 7)}` : ""} by ` +
      "`tools/bin/build-plugin-branch.mjs`. Do not edit this branch; edit `main` and it is rebuilt.\n\n" +
      `Codex and the ChatGPT desktop app: \`codex plugin marketplace add ${GITHUB.owner}/${GITHUB.repo} ` +
      `--ref ${GITHUB.pluginBranch}\`, then \`codex plugin add ${GITHUB.plugin}@${GITHUB.marketplace}\`.\n`,
    "utf8"
  );

  console.log(`dist/plugin-branch  plugin ${manifest.version}, ${listed.length} flat file(s), ${skipped.length} too large`);
}

main();
