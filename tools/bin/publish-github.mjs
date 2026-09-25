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
//
// A release deserves a written message: put it in .git/publish-message and the
// next publish, including the scheduled one, uses it once and removes it.
// Without one, the subject names the areas that changed, and a version bump in
// .claude-plugin/plugin.json becomes "Release <version>" with the changelog
// entry's opening paragraph as the body.

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

const SUBJECT_WIDTH = 72;

// What a path belongs to, in the words a reader of the history would use.
function areaOf(path) {
  const parts = path.split("/");
  if (parts[0] === ".claude" && parts[1] === "skills") return `${parts[2]} skill`;
  if (path === "docs/visual-guide/designer.html") return "UI designer";
  if (path.startsWith("docs/visual-guide/")) return "style picker";
  if (path.startsWith("docs/portability/gpt/")) return "GPT package";
  if (path.startsWith("docs/portability/")) return "portability docs";
  if (path.startsWith("docs/assets/")) return "images";
  if (path === "docs/CHANGELOG.md") return "changelog";
  if (path.startsWith("library/tests/")) return "tests";
  if (parts[0] === "library") return "library";
  if (parts[0] === "tools") return "tools";
  if (parts[0] === ".claude-plugin") return "plugin manifest";
  if (parts[0] === ".github") return "CI";
  if (path === "AGENTS.md" || parts[0] === ".agents" || parts[0] === ".cursor") return "generated host rules";
  return parts.length > 1 ? parts[0] : path.replace(/\.md$/, "");
}

// Regenerated files follow their sources; they name the change only when alone.
const DERIVED = new Set(["generated host rules", "GPT package"]);

function joined(items) {
  return items.length < 2 ? items.join("") : `${items.slice(0, -1).join(", ")} and ${items.at(-1)}`;
}

function versionIn(tree) {
  const file = git(["show", `${tree}:.claude-plugin/plugin.json`], { allowFailure: true });
  return file.ok ? JSON.parse(file.out).version : null;
}

function releaseNotes(tree, version) {
  const changelog = git(["show", `${tree}:docs/CHANGELOG.md`], { allowFailure: true });
  if (!changelog.ok) return "";
  const entry = changelog.out.split(/^## /m).find((section) => section.startsWith(`${version} `));
  const paragraph = entry?.split("\n\n")[1] ?? "";
  return paragraph.startsWith("#") ? "" : paragraph.trim();
}

function subjectFor(changes) {
  const counts = new Map();
  for (const line of changes) {
    const area = areaOf(line.split("\t").pop());
    counts.set(area, (counts.get(area) ?? 0) + 1);
  }
  const ranked = [...counts.keys()].sort((a, b) => counts.get(b) - counts.get(a));
  const named = ranked.filter((area) => !DERIVED.has(area));
  const areas = named.length ? named : ranked;
  for (let shown = Math.min(3, areas.length); shown >= 1; shown--) {
    const rest = areas.length - shown;
    const list = rest ? [...areas.slice(0, shown), `${rest} other area${rest > 1 ? "s" : ""}`] : areas;
    const subject = `Update ${joined(list)}`;
    if (subject.length <= SUBJECT_WIDTH || shown === 1) return subject;
  }
  return "Update";
}

function message(tree, changes, committed, remoteTree, pending) {
  if (pending) return pending.trim() + "\n";
  if (committed || tree === git(["rev-parse", "HEAD^{tree}"]).out) {
    return git(["log", "-1", "--format=%s%n%n%b"]).out + "\n";
  }
  const version = versionIn(tree);
  const released = version && remoteTree && version !== versionIn(remoteTree);
  const subject = released ? `Release ${version}` : subjectFor(changes);
  const notes = released ? releaseNotes(tree, version) : "";
  const listed = changes.slice(0, 30).join("\n");
  const more = changes.length > 30 ? `\n... and ${changes.length - 30} more` : "";
  const files = `${changes.length} file(s):\n${listed}${more}`;
  return `${subject}\n\n${notes ? `${notes}\n\n` : ""}${files}\n`;
}

export function publish(flags = new Set()) {
  const committed = flags.has("--committed");
  const gitDir = git(["rev-parse", "--absolute-git-dir"]).out;
  const stateFile = join(gitDir, "publish-github-last");
  const pendingFile = join(gitDir, "publish-message");
  const pending = existsSync(pendingFile) ? readFileSync(pendingFile, "utf8") : null;

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
    input: message(tree, changes, committed, remoteTree, pending),
  }).out;

  const target = `github.com/${GITHUB.owner}/${GITHUB.repo} ${GITHUB.sourceBranch}`;
  if (flags.has("--dry-run")) {
    return { commit: null, report: `would push ${commit.slice(0, 7)} to ${target}: ${changes.length} path(s) changed` };
  }
  git(["push", "--quiet", GITHUB.remote, `${commit}:refs/heads/${GITHUB.sourceBranch}`]);
  writeFileSync(stateFile, commit + "\n", "utf8");
  if (pending) rmSync(pendingFile);
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
