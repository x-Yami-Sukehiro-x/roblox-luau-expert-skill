// Find the skills directory, wherever this copy of the tools is running from.
//
// The router tells a model to run verify-executor-api.mjs and
// lint-ui-directions.mjs. Those read the skill files. But install.ps1 copies
// tools/ to ~/.claude/roblox-luau-expert/ and the skills to ~/.claude/skills/ -
// two different places - so a tool that only looked beside itself worked in the
// repository and failed everywhere it was actually installed.
//
// A gate that only runs for its author is not a gate.

import { existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { REPO_ROOT } from "./dump.mjs";

/**
 * Candidate roots, most specific first:
 *   1. this repository, or the OpenAI plugin that bundles these tools
 *   2. the plugin root, when Claude Code has set it
 *   3. the per-user install ~/.claude/skills
 *   4. the Cursor mirror, which install parity keeps in step
 */
function candidates() {
  // The OpenAI plugin layout keeps the skills at skills/ beside tools/.
  const roots = [join(REPO_ROOT, ".claude", "skills"), join(REPO_ROOT, "skills")];

  const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT;
  if (pluginRoot) roots.push(join(pluginRoot, ".claude", "skills"));

  const home = homedir();
  roots.push(join(home, ".claude", "skills"));
  roots.push(join(home, ".cursor", "skills"));

  return roots;
}

/** The skills directory, or null when none of the candidates exist. */
export function findSkillsDir() {
  return candidates().find((root) => existsSync(root)) ?? null;
}

/**
 * Resolve a path inside the skills directory.
 *
 * @param {string[]} parts path segments below the skills directory
 * @returns {string | null} the resolved path, or null if it is not there
 */
export function resolveSkillPath(...parts) {
  for (const root of candidates()) {
    const full = join(root, ...parts);
    if (existsSync(full)) return full;
  }
  return null;
}

/** The message to print when a skill file cannot be found anywhere. */
export function missingSkillsMessage(what) {
  return (
    `could not find ${what} in any skills directory.\n` +
    `Looked in:\n` +
    candidates()
      .map((root) => `  ${root}`)
      .join("\n") +
    `\nRun this from the repository, or install the skills with install.ps1.`
  );
}
