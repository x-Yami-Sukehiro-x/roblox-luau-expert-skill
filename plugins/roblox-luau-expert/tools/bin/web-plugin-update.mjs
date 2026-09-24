#!/usr/bin/env node
// Keep the plugin uploaded at chatgpt.com/plugins in step with this repository.
//
// chatgpt.com/plugins has no repository sync: a new version is a ZIP uploaded
// through Plugin actions, "Upload new version", in a signed-in browser. This
// builds that ZIP from the current tree and remembers which version was last
// uploaded, so the scheduled browser task knows whether there is work to do.
//
// Usage:
//   node tools/bin/web-plugin-update.mjs --status   build, compare; exit 0 current, 3 upload needed
//   node tools/bin/web-plugin-update.mjs --record   mark the built version as uploaded
//
// The record lives in the .git folder beside auto-update.log, so it never
// reaches the public repository.

import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { REPO_ROOT } from "./lib/dump.mjs";
import { git } from "./lib/github.mjs";

const OUT = join(REPO_ROOT, "dist", "openai-plugin");
const ZIP = join(OUT, "roblox-luau-expert-plugin.zip");
const MANIFEST = join(OUT, "roblox-luau-expert", "plugin.json");
const NEEDS_UPLOAD = 3;

function build() {
  const result = spawnSync(process.execPath, [join(REPO_ROOT, "tools", "bin", "build-openai-plugin.mjs")], {
    encoding: "utf8",
  });
  if (result.status !== 0) throw new Error(`plugin build failed: ${(result.stderr || result.stdout).trim()}`);
  return JSON.parse(readFileSync(MANIFEST, "utf8")).version;
}

function recordPath() {
  return join(git(["rev-parse", "--absolute-git-dir"]).out, "web-plugin-upload.json");
}

function main() {
  const version = build();
  const path = recordPath();
  const last = existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : null;

  if (process.argv.includes("--record")) {
    writeFileSync(path, JSON.stringify({ version, uploadedAt: new Date().toISOString() }, null, 2) + "\n", "utf8");
    console.log(`recorded ${version} as uploaded`);
    return;
  }

  console.log(`built    ${version}`);
  console.log(`uploaded ${last ? `${last.version} (${last.uploadedAt})` : "nothing recorded"}`);
  console.log(`zip      ${ZIP}  ${Math.round(statSync(ZIP).size / 1024)} KB`);
  if (last?.version === version) {
    console.log("CURRENT");
    return;
  }
  console.log("UPLOAD NEEDED");
  process.exitCode = NEEDS_UPLOAD;
}

main();
