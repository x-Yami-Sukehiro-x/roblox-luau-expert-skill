// Where the published copy of this repository lives, and who it is published as.
//
// The local history stays local. GitHub receives snapshot commits authored with the
// account's noreply address, so no local identity is published.

import { spawnSync } from "node:child_process";
import { REPO_ROOT } from "./dump.mjs";

export const GITHUB = {
  owner: "x-Yami-Sukehiro-x",
  userId: 332935035,
  repo: "roblox-luau-expert-skill",
  remote: "github",
  sourceBranch: "main",
  pluginBranch: "plugin",
  marketplace: "roblox-luau-expert-github",
  plugin: "roblox-luau-expert",
};

export const GITHUB_URL = `https://${GITHUB.owner}@github.com/${GITHUB.owner}/${GITHUB.repo}.git`;

export const PUBLISHER = {
  name: GITHUB.owner,
  email: `${GITHUB.userId}+${GITHUB.owner}@users.noreply.github.com`,
};

export function git(args, { env, input, allowFailure = false, cwd = REPO_ROOT } = {}) {
  const result = spawnSync("git", args, {
    cwd,
    encoding: "utf8",
    input,
    env: env ? { ...process.env, ...env } : process.env,
    maxBuffer: 64 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && !allowFailure) {
    throw new Error(`git ${args[0]} failed: ${(result.stderr || result.stdout).trim()}`);
  }
  return { ok: result.status === 0, out: result.stdout.trim(), err: result.stderr.trim() };
}
