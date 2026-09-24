#!/usr/bin/env node
// Publish this repository to GitHub as one snapshot commit.
//
// GitHub is the published copy, not a second place to edit. A run snapshots the
// working tree the way `git add -A` sees it - tracked and new files, .gitignore
// respected - into a private index, and pushes it as one commit on top of
// GitHub's main. The local branch, index and history are not touched. GitHub's
// workflow then rebuilds the plugin branch that Codex and ChatGPT install from.
//
// If GitHub's main moved since the last publish from here, the run stops rather
// than overwrite an edit made somewhere else. It also stops on anything that
// looks like a credential, or on the local git email address.
//
// Usage:
//   node tools/bin/publish-github.mjs              snapshot the working tree
//   node tools/bin/publish-github.mjs --committed  publish HEAD's tree instead
//   node tools/bin/publish-github.mjs --dry-run    say what would be pushed
//   node tools/bin/publish-github.mjs --adopt      accept GitHub's current main
//                                                  as the parent (after a merge)

import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { GITHUB, GITHUB_URL, PUBLISHER, git } from "./lib/github.mjs";

// Tracked, but machine-local: this checkout's Claude permission list.
const LOCAL_ONLY = [".claude/settings.local.json"];

const CREDENTIAL_PATTERNS = [
  "gh[pousr]_[A-Za-z0-9]{36,}",
  "github_pat_[A-Za-z0-9_]{50,}",
  "sk-(proj-)?[A-Za-z0-9_-]{32,}",
  "AKIA[0-9A-Z]{16}",
  "-----BEGIN [A-Z ]*PRIVATE KEY-----",
  "xox[baprs]-[A-Za-z0-9-]{10,}",
  "_[|]WARNING:-DO-NOT-SHARE-THIS",
  "discord(app)?[.]com/api/webhooks/[0-9]+",
];

function localEmails() {
  const found = git(["config", "--get-all", "user.email"], { allowFailure: true }).out;
  return found.split("\n").map((email) => email.trim()).filter(Boolean);
}

function snapshotTree(gitDir, committed) {
  if (committed) return git(["rev-parse", "HEAD^{tree}"]).out;
  const index = join(gitDir, "publish-github.index");
  rmSync(index, { force: true });
  const env = { GIT_INDEX_FILE: index };
  git(["add", "-A"], { env });
  git(["rm", "--cached", "-r", "-q", "--ignore-unmatch", "--", ...LOCAL_ONLY], { env });
  const tree = git(["write-tree"], { env }).out;
  rmSync(index, { force: true });
  return tree;
}

function fetchRemoteTip() {
  const fetched = git(
    ["fetch", "--quiet", GITHUB.remote, `+refs/heads/${GITHUB.sourceBranch}:refs/remotes/${GITHUB.remote}/${GITHUB.sourceBranch}`],
    { allowFailure: true }
  );
  if (!fetched.ok) {
    if (/couldn't find remote ref/i.test(fetched.err)) return null;
    throw new Error(`fetch from ${GITHUB.remote} failed: ${fetched.err}`);
  }
  return git(["rev-parse", `refs/remotes/${GITHUB.remote}/${GITHUB.sourceBranch}`]).out;
}

function credentialHits(tree) {
  const patterns = [...CREDENTIAL_PATTERNS, ...localEmails().map((email) => email.replace(/[.+]/g, "[$&]"))];
  const args = ["grep", "-I", "-l", "-E"];
  for (const pattern of patterns) args.push("-e", pattern);
  const found = git([...args, tree, "--"], { allowFailure: true });
  return found.out ? found.out.split("\n").map((line) => line.slice(tree.length + 1)) : [];
}

function message(tree, changes, committed) {
  const head = git(["log", "-1", "--format=%s%n%n%b"]).out;
  if (committed || tree === git(["rev-parse", "HEAD^{tree}"]).out) return head + "\n";
  const listed = changes.slice(0, 30).join("\n");
  const more = changes.length > 30 ? `\n... and ${changes.length - 30} more` : "";
  return `Working tree after "${head.split("\n")[0]}"\n\n${changes.length} path(s) changed:\n${listed}${more}\n`;
}

export function publish(flags = new Set()) {
  const committed = flags.has("--committed");
  const gitDir = git(["rev-parse", "--absolute-git-dir"]).out;
  const stateFile = join(gitDir, "publish-github-last");

  if (!git(["remote", "get-url", GITHUB.remote], { allowFailure: true }).ok) {
    git(["remote", "add", GITHUB.remote, GITHUB_URL]);
  }

  const tree = snapshotTree(gitDir, committed);
  const remoteTip = fetchRemoteTip();
  const lastPublished = existsSync(stateFile) ? readFileSync(stateFile, "utf8").trim() : null;
  if (remoteTip && remoteTip !== lastPublished && !flags.has("--adopt")) {
    throw new Error(
      `GitHub ${GITHUB.sourceBranch} is at ${remoteTip.slice(0, 7)}, not the last publish from here ` +
        `(${lastPublished ? lastPublished.slice(0, 7) : "none"}); bring that change in, then rerun with --adopt`
    );
  }

  const remoteTree = remoteTip ? git(["rev-parse", `${remoteTip}^{tree}`]).out : null;
  if (tree === remoteTree) {
    return { commit: null, report: `GitHub ${GITHUB.sourceBranch} already matches (${remoteTip.slice(0, 7)})` };
  }

  const hits = credentialHits(tree);
  if (hits.length) throw new Error(`refusing to publish, credential or local email in: ${hits.join(", ")}`);

  const base = remoteTree ?? git(["hash-object", "-t", "tree", "--stdin"], { input: "" }).out;
  const changes = git(["diff-tree", "-r", "--no-renames", "--name-status", base, tree]).out.split("\n").filter(Boolean);
  const identity = {
    GIT_AUTHOR_NAME: PUBLISHER.name,
    GIT_AUTHOR_EMAIL: PUBLISHER.email,
    GIT_COMMITTER_NAME: PUBLISHER.name,
    GIT_COMMITTER_EMAIL: PUBLISHER.email,
  };
  const parents = remoteTip ? ["-p", remoteTip] : [];
  const commit = git(["commit-tree", tree, ...parents, "-F", "-"], {
    env: identity,
    input: message(tree, changes, committed),
  }).out;

  const target = `github.com/${GITHUB.owner}/${GITHUB.repo} ${GITHUB.sourceBranch}`;
  if (flags.has("--dry-run")) {
    return { commit: null, report: `would push ${commit.slice(0, 7)} to ${target}: ${changes.length} path(s) changed` };
  }
  git(["push", "--quiet", GITHUB.remote, `${commit}:refs/heads/${GITHUB.sourceBranch}`]);
  writeFileSync(stateFile, commit + "\n", "utf8");
  return { commit, report: `pushed ${commit.slice(0, 7)} to ${target}: ${changes.length} path(s) changed` };
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    console.log(publish(new Set(process.argv.slice(2))).report);
  } catch (error) {
    console.error(`publish-github: ${error.message}`);
    process.exit(1);
  }
}
