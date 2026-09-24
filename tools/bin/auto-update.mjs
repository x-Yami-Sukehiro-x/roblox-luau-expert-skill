#!/usr/bin/env node
// One auto-update pass: publish local edits to GitHub, wait for the workflow to
// build them, then bring the installed Codex / ChatGPT desktop plugin up to date.
//
// The scheduled task from install-auto-update.ps1 runs this every 20 minutes and
// at sign-in. Each pass appends one line to auto-update.log in the .git folder,
// which is where to look when an update did not arrive.
//
// Usage:
//   node tools/bin/auto-update.mjs              publish, wait, install
//   node tools/bin/auto-update.mjs --no-publish install the newest build only

import { appendFileSync, existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { GITHUB, git } from "./lib/github.mjs";
import { publish } from "./publish-github.mjs";
import { syncPlugin } from "./sync-plugin.mjs";

const BUILD_WAIT_MS = 10 * 60 * 1000;
const POLL_MS = 30 * 1000;
const LOG_LIMIT = 256 * 1024;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// The workflow names each plugin-branch commit "Build <source sha7>: ...".
async function waitForBuild(commit) {
  const deadline = Date.now() + BUILD_WAIT_MS;
  while (Date.now() < deadline) {
    await sleep(POLL_MS);
    const fetched = git(["fetch", "--quiet", GITHUB.remote, GITHUB.pluginBranch], { allowFailure: true });
    if (!fetched.ok) continue;
    if (git(["log", "-1", "--format=%s", "FETCH_HEAD"]).out.startsWith(`Build ${commit.slice(0, 7)}`)) return true;
  }
  return false;
}

function log(gitDir, line) {
  const path = join(gitDir, "auto-update.log");
  if (existsSync(path) && statSync(path).size > LOG_LIMIT) {
    writeFileSync(path, readFileSync(path, "utf8").slice(-LOG_LIMIT / 2), "utf8");
  }
  appendFileSync(path, `${new Date().toISOString()}  ${line}\n`, "utf8");
  console.log(line);
}

async function main() {
  const gitDir = git(["rev-parse", "--absolute-git-dir"]).out;
  const steps = [];
  try {
    if (!process.argv.includes("--no-publish")) {
      const published = publish();
      steps.push(published.report);
      if (published.commit && !(await waitForBuild(published.commit))) {
        steps.push(`no build of ${published.commit.slice(0, 7)} within 10 minutes; see the repository's Actions tab`);
      }
    }
    steps.push(syncPlugin());
    log(gitDir, steps.join("; "));
  } catch (error) {
    log(gitDir, [...steps, `FAILED ${error.message}`].join("; "));
    process.exit(1);
  }
}

main();
