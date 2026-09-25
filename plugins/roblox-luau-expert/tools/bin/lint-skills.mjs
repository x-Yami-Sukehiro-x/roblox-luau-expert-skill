#!/usr/bin/env node
// Check that every skill can actually be found and loaded by the hosts.
//
// Hosts show a model only each skill's name and description at start-up, from
// a shared budget: Codex caps the list at 2% of the context window or 8,000
// characters, Claude Code at about 1% of it, and both shorten descriptions and
// then drop skills when the list runs over. A skill that is dropped is never
// used, however good its body is. The Agent Skills specification adds its own
// limits on the fields.
//
// Rules, each a failure:
//   - frontmatter is exactly `name` and `description`, name matches the folder,
//     lowercase letters, digits and single hyphens, at most 64 characters
//   - description 1 to 1024 characters with no ": " (a YAML plain scalar)
//   - all names and descriptions together fit BUDGET characters
//   - SKILL.md at most 500 lines
//   - every skill but the router has a "Works with" section naming at least two
//     skills that exist, and the router names every skill
// A body over 20,000 characters (about 5,000 tokens) is a warning.
//
// Usage: node tools/bin/lint-skills.mjs [skills-dir]

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, relative } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

const ROUTER = "roblox-luau-expert";
// Below the 8,000-character list so the user's other skills still fit beside it.
const BUDGET = 7000;
const MAX_LINES = 500;
const WARN_CHARS = 20000;
const NAME = /^[a-z0-9]+(-[a-z0-9]+)*$/;

function frontmatter(text) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n/.exec(text);
  if (!match) return null;
  const fields = {};
  for (const line of match[1].split(/\r?\n/)) {
    const field = /^([a-z-]+):\s?(.*)$/.exec(line);
    if (field) fields[field[1]] = field[2];
    else fields.__stray = line;
  }
  return fields;
}

function main() {
  const dir = process.argv[2] ?? join(REPO_ROOT, ".claude", "skills");
  const skills = readdirSync(dir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && existsSync(join(dir, entry.name, "SKILL.md")))
    .map((entry) => entry.name)
    .sort();
  const errors = [];
  const warnings = [];
  let budget = 0;

  for (const skill of skills) {
    const path = join(dir, skill, "SKILL.md");
    const where = relative(REPO_ROOT, path).split("\\").join("/");
    const text = readFileSync(path, "utf8");
    const fields = frontmatter(text);
    if (!fields) {
      errors.push(`${where}  no frontmatter`);
      continue;
    }
    const keys = Object.keys(fields).filter((key) => key !== "__stray");
    if (fields.__stray !== undefined || keys.join(",") !== "name,description") {
      errors.push(`${where}  frontmatter must be exactly name and description, found ${keys.join(", ")}`);
    }
    const name = fields.name ?? "";
    const description = fields.description ?? "";
    if (name !== skill) errors.push(`${where}  name "${name}" does not match the folder`);
    if (!NAME.test(name) || name.length > 64) errors.push(`${where}  name "${name}" breaks the naming rule`);
    if (description.length < 1 || description.length > 1024) {
      errors.push(`${where}  description is ${description.length} characters; the limit is 1024`);
    }
    if (/:\s/.test(description)) errors.push(`${where}  description contains ": ", which breaks YAML parsers`);
    budget += name.length + description.length;

    const lines = text.split(/\r?\n/).length;
    if (lines > MAX_LINES) errors.push(`${where}  ${lines} lines; keep SKILL.md under ${MAX_LINES} and move detail to references`);
    if (text.length > WARN_CHARS) warnings.push(`${where}  ${text.length} characters, about ${Math.round(text.length / 4)} tokens`);

    if (skill === ROUTER) {
      for (const other of skills) {
        if (other !== ROUTER && !text.includes(other)) errors.push(`${where}  the router never names ${other}`);
      }
      continue;
    }
    const section = /\n## Works with\n([\s\S]*?)(\n## |$)/.exec(text);
    if (!section) {
      errors.push(`${where}  no "## Works with" section`);
      continue;
    }
    const partners = [...new Set([...section[1].matchAll(/`(roblox-[a-z-]+)`/g)].map((m) => m[1]))];
    for (const partner of partners) {
      if (!skills.includes(partner)) errors.push(`${where}  works with ${partner}, which does not exist`);
    }
    if (partners.filter((partner) => skills.includes(partner) && partner !== skill).length < 2) {
      errors.push(`${where}  "Works with" names fewer than two other skills`);
    }
  }

  if (budget > BUDGET) {
    errors.push(`names and descriptions total ${budget} characters; the budget is ${BUDGET}`);
  }
  for (const line of errors) console.log(`E  ${line}`);
  for (const line of warnings) console.log(`W  ${line}`);
  console.log(
    `${skills.length} skill(s), ${budget}/${BUDGET} metadata characters - ${errors.length} error(s), ${warnings.length} warning(s)`
  );
  process.exitCode = errors.length ? 1 : 0;
}

main();
