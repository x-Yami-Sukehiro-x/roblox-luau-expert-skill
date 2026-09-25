#!/usr/bin/env node
// Generate the host-specific rule files from docs/portability/rules.md.
//
// Four hosts carry this stack: Claude Code (the skills themselves), Codex
// (AGENTS.md), Cursor (.cursor/rules/*.mdc) and a custom GPT (an instructions
// field with a hard character cap, plus a knowledge file). Four hand-maintained
// copies rot within a month, so they are generated, and --check fails CI when
// they are behind.
//
// Tiers are cumulative: P0 everywhere, P1 adds detail, P2 adds area depth. The
// GPT instructions field takes P0 only, because it is the one target with a
// budget that P1 cannot fit inside.
//
// Usage:
//   node tools/bin/build-portable.mjs            write the generated files
//   node tools/bin/build-portable.mjs --check    exit 1 if any is stale
//   node tools/bin/build-portable.mjs --list     print sizes and exit

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";
import { collectPackageFiles, checkPackage, writePackage } from "./lib/portable-package.mjs";

const SOURCE = join(REPO_ROOT, "docs", "portability", "rules.md");
const SKILLS_DIR = join(REPO_ROOT, ".claude", "skills");

// Everything a custom GPT needs lives under one folder, because the alternative
// is remembering six months later which two of the files in docs/portability
// were the ones to upload.
const GPT_DIR = join(REPO_ROOT, "docs", "portability", "gpt");
const GPT_KNOWLEDGE_DIR = join(GPT_DIR, "knowledge");

// The GPT's Knowledge already holds a file by this name. Renaming it would
// upload a second copy beside the first rather than replacing it, so the name
// is fixed even though the folder now makes the prefix redundant.
const GPT_KNOWLEDGE_NAME = "gpt-knowledge.md";
const GPT_ZIP_NAME = "roblox-luau-expert-skill.zip";
const GPT_MANIFEST = join(GPT_DIR, "package-manifest.json");
const WORKFLOW_SOURCES = [
  "roblox-request-intake/references/visual-choices.md",
  "roblox-luau-expert/references/task-contract.md",
  "roblox-executor/SKILL.md",
  "roblox-executor/references/technique/feature-search.md",
  "roblox-executor/references/technique/feature-ideas.md",
  "roblox-executor/references/technique/decompiled-source.md",
  "roblox-executor/references/technique/source-to-api.md",
  "roblox-executor/references/technique/lifecycle.md",
  "roblox-ui/SKILL.md",
  "roblox-ui/references/build-order.md",
  "roblox-ui/references/self-review.md",
  "roblox-ui/references/functional-proof.md",
  "roblox-ui/references/screen-archetypes.md",
  "roblox-ui/references/layout-ux.md",
  "roblox-ui/references/crisp-ui.md",
  "roblox-ui/references/image-to-ui.md",
  "roblox-ui/references/ui-copy.md",
  "roblox-ui/references/design-spec.md",
  "roblox-luau-language/references/compiler-limits.md",
  "roblox-reply-craft/SKILL.md",
  "roblox-reply-craft/references/code-output.md",
  "roblox-reply-craft/references/fast-path.md",
  "roblox-executor-features/SKILL.md",
  "roblox-executor-features/references/feature-quality.md",
  "roblox-executor-features/references/feature-catalog.md",
  "roblox-executor-reliability/SKILL.md",
  "roblox-executor-reliability/references/failure-modes.md",
  "roblox-executor-reliability/references/regression-matrix.md",
  "roblox-executor-reliability/references/composition.md",
  "roblox-executor-reliability/references/diagnosis.md",
  "roblox-attempt-memory/SKILL.md",
  "roblox-attempt-memory/references/ledger-format.md",
  "roblox-attempt-memory/references/recovering-context.md",
  "roblox-attempt-memory/references/known-failures.md",
  "roblox-ui/references/weak-prompt.md",
  "roblox-ui/references/clipping.md",
  "roblox-ui-viewport/SKILL.md",
  "roblox-ui-viewport/references/device-matrix.md",
  "roblox-ui-viewport/references/overflow.md",
  "roblox-ui-interaction/SKILL.md",
  "roblox-ui-interaction/references/blocked-input.md",
  "roblox-ui-interaction/references/input-matrix.md",
];

// Everything a picked style code needs, in one retrievable file: the question,
// the everyday-word map, the label contract and the tested recipes in full. A
// GPT that only retrieves fragments still finds "T2" next to the code for T2.
const STYLE_SOURCES = [
  "roblox-request-intake/references/visual-choices.md",
  "roblox-request-intake/references/ui-words.md",
  "roblox-ui-components/references/style-recipes.md",
  "roblox-ui-components/references/icon-meaning.md",
  "roblox-ui-tooltips/SKILL.md",
];
const STYLE_RECIPES_DIR = join(SKILLS_DIR, "roblox-ui-components", "assets");

// Scripts a reply hands over unchanged but for one config line, in full, so a
// GPT pastes the tested file instead of writing its own from the description.
const EXECUTOR_ASSETS_DIR = join(SKILLS_DIR, "roblox-executor", "assets");
const FEATURE_ASSETS_DIR = join(SKILLS_DIR, "roblox-executor-features", "assets");

// The style picker page itself. The hosted copy is private until its owner
// shares it, so the GPT carries the page and can hand it over as a file.
const STYLE_PICKER = join(REPO_ROOT, "docs", "visual-guide", "index.html");
const GPT_STYLE_PICKER_NAME = "roblox-ui-style-picker.html";

// The UI pack, flattened into one uploadable file. The folder version is the
// source and the zip carries it too, but a zip only helps a GPT that thinks to
// unpack it, and the interfaces are the part it gets wrong when it does not.
// One markdown file is retrieved the same way the knowledge file is.
const GPT_UI_PACK_NAME = "ui-pack.md";
const UI_PACK_DIR = join(GPT_DIR, "UIs");

// What goes in the uploaded archive. Deliberately not the whole repo: .git is
// large and useless to a GPT, and the scratch files are noise.
const ZIP_CONTENTS = [
  ".claude",
  "docs",
  "library",
  "tools",
  "evals",
  "README.md",
  "AGENTS.md",
  "LICENSE.md",
  "NOTICE.md",
];

// OpenAI's GPT builder caps the instructions field at 8000 characters. Leave
// room for the header this tool prepends.
const GPT_INSTRUCTIONS_CAP = 8000;

const BANNER = (source) =>
  `<!-- GENERATED FILE - do not edit.\n` +
  `     Source: ${source}\n` +
  `     Rebuild: node tools/bin/build-portable.mjs\n` +
  `     Verify:  node tools/bin/build-portable.mjs --check -->`;

function parseSections(text) {
  const body = text.includes("\n---\n") ? text.split("\n---\n").slice(1).join("\n---\n") : text;
  const sections = [];
  let current = null;

  for (const line of body.split(/\r?\n/)) {
    const m = /^##\s+\[(P\d)\]\s+(.+?)\s*$/.exec(line);
    if (m) {
      current = { tier: Number(m[1].slice(1)), title: m[2], lines: [] };
      sections.push(current);
      continue;
    }
    if (current) current.lines.push(line);
  }

  return sections;
}

function render(sections, maxTier) {
  return sections
    .filter((s) => s.tier <= maxTier)
    .map((s) => `## ${s.title}\n${s.lines.join("\n").replace(/\n{3,}/g, "\n\n").trimEnd()}`)
    .join("\n\n")
    .trim();
}

// The skill descriptions are the routing table for a host that can load them.
// Reading them here means a new skill appears in every target automatically.
function skillIndex() {
  if (!existsSync(SKILLS_DIR)) return [];
  const rows = [];
  for (const entry of readdirSync(SKILLS_DIR)) {
    const skillFile = join(SKILLS_DIR, entry, "SKILL.md");
    if (!existsSync(skillFile)) continue;
    const text = readFileSync(skillFile, "utf8");
    const m = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text);
    if (!m) continue;
    const name = /^name:\s*(.+)$/m.exec(m[1]);
    const description = /^description:\s*([\s\S]*?)(?=\n[a-z-]+:|$)/m.exec(m[1]);
    if (!name) continue;
    const summary = (description ? description[1] : "")
      .replace(/\s+/g, " ")
      .trim();
    rows.push({ name: name[1].trim(), summary });
  }
  rows.sort((a, b) => a.name.localeCompare(b.name));
  return rows;
}

// One sentence per skill: enough to route, short enough not to dominate.
function shortSummary(summary) {
  const cut = summary.split(/\.\s|—\s/)[0];
  return cut.length > 150 ? `${cut.slice(0, 147)}...` : cut;
}

// Codex and Cursor both run commands, so both get the tool contract. It is
// written once here rather than twice in the templates.
const TOOLS_SECTION = `## Verification tools

\`\`\`bash
node tools/bin/verify-api.mjs <Name>              # Roblox APIs, against the dump
node tools/bin/verify-executor-api.mjs <name>     # executor functions, against sUNC
node tools/bin/lint-roblox-ui.mjs <file.luau>     # counts the UI rubric over real code
node tools/bin/check-all.mjs                      # every gate in this repo, one verdict
\`\`\`

**Two rules about these.**

A name you are not certain of gets checked before it is written. A non-zero exit
is the signal you were about to invent one. Roblox APIs and executor functions
have different ground truth and different commands - \`verify-api.mjs\` reports
every executor function as missing, correctly, because the dump does not contain
them.

UI gets counted, not estimated. \`lint-roblox-ui.mjs\` reports distinct text
sizes, corner radii, spacing values, touch targets, mouse-only handlers and
undisconnected connections, and exits 1 on any error. Run it on what you wrote
and report what it prints.`;

function buildAgents(sections, skills) {
  const table = skills
    .map((s) => `| \`${s.name}\` | ${shortSummary(s.summary)} |`)
    .join("\n");

  return `${BANNER("docs/portability/rules.md")}

# Roblox Luau Expert — agent rules

Applies to every \`.lua\` and \`.luau\` file in a Roblox project, and to any task
mentioning Luau, Rojo, RemoteEvent, DataStore, Humanoid, Instance, sUNC or an
executor.

${render(sections, 2)}

---

## Deeper references in this repository

Each of these is a full skill with its own reference files under
\`.claude/skills/\`. Open the matching \`SKILL.md\` when a task goes deeper than
the rules above.

| Skill | Covers |
|---|---|
${table}

${TOOLS_SECTION}
`;
}

function buildCursor(sections, skills) {
  const table = skills
    .map((s) => `| \`${s.name}\` | ${shortSummary(s.summary)} |`)
    .join("\n");

  // Cursor reads MDC frontmatter: description, globs, alwaysApply.
  return `---
description: Roblox and Luau expertise - engine APIs, networking, DataStores, UI and UX, performance, anti-exploit, and client/executor scripting. Applies to Luau files and any Roblox task.
globs: ["**/*.luau", "**/*.lua", "**/*.project.json", "**/*.rbxmx", "**/wally.toml", "**/.luaurc"]
alwaysApply: false
---

${BANNER("docs/portability/rules.md")}

# Roblox Luau Expert

${render(sections, 2)}

---

## Deeper references

Full skills with their own reference files live under \`.claude/skills/\`.

| Skill | Covers |
|---|---|
${table}

---

${TOOLS_SECTION}
`;
}

function buildGptInstructions(sections) {
  const core = render(sections, 0);

  const header = `You are a Roblox and Luau expert. Follow these rules exactly; consult your attached knowledge when a task needs more depth than they carry.

`;

  const footer = `

## Scope

Support legitimate client/executor work and game defense; exclude theft, malware, account compromise and disruption. Judge the action, not technical vocabulary. State replication and compatibility limits.
`;

  return `${header}${core}${footer}`;
}

function buildGptKnowledge(sections, skills) {
  const table = skills
    .map((s) => `| \`${s.name}\` | ${shortSummary(s.summary)} |`)
    .join("\n");

  return `${BANNER("docs/portability/rules.md")}

# Roblox Luau Expert — knowledge base

Upload this file to the GPT's Knowledge. The instructions field carries the
spine; this carries the detail behind it.

${render(sections, 2)}

---

## The full stack

This condenses a ${skills.length}-skill stack. Each skill below has its own
reference files; the source repository is where the depth lives.

| Skill | Covers |
|---|---|
${table}
`;
}

/**
 * Flatten docs/portability/gpt/UIs into one markdown file.
 *
 * Concatenation rather than rewriting, so there is exactly one copy of each
 * fact and the linters that gate the originals gate this too. The exemplars
 * come in as fenced Luau, which is what lint-luau-blocks.mjs reads.
 */
function buildUiPack() {
  const part = (name) => {
    const path = join(UI_PACK_DIR, name);
    return existsSync(path) ? readFileSync(path, "utf8").trim() : null;
  };

  const catalog = part("catalog.md");
  const anatomy = part("anatomy.md");
  if (!catalog || !anatomy) return null;

  const exemplarDir = join(UI_PACK_DIR, "exemplars");
  const exemplars = existsSync(exemplarDir)
    ? readdirSync(exemplarDir)
        .filter((entry) => /\.luau?$/.test(entry))
        .sort()
        .map((entry) => {
          const body = readFileSync(join(exemplarDir, entry), "utf8").trimEnd();
          return `### ${entry}

\`\`\`lua
${body}
\`\`\``;
        })
    : [];

  const notes = part(join("exemplars", "README.md"));
  // The gallery's notes are the most directly useful UI material in the folder -
  // two real windows, read off the pixels. The images themselves only travel in
  // the zip; what a GPT retrieves is this text.
  const gallery = part(join("gallery", "README.md"));

  return [
    BANNER("docs/portability/gpt/UIs/"),
    "",
    "# UI pack",
    "",
    "Upload this to the GPT's Knowledge. It is `docs/portability/gpt/UIs/`",
    "flattened into one file: the vetted library catalog, the measurements for",
    "headers and notifications, and two complete interfaces that score 24/24 on",
    "the slop rubric and 32/32 on the UI rubric.",
    "",
    "---",
    "",
    catalog,
    "",
    "---",
    "",
    anatomy,
    "",
    "---",
    "",
    gallery ?? "",
    "",
    "---",
    "",
    notes ?? "# Exemplars",
    "",
    "---",
    "",
    "# The exemplars in full",
    "",
    ...exemplars,
    "",
  ].join("\n");
}

function buildWorkflowPack() {
  const sections = WORKFLOW_SOURCES.map((source) => {
    const content = readFileSync(join(SKILLS_DIR, source), "utf8").trim();
    return `## Source: .claude/skills/${source}\n\n${content}`;
  });
  for (const [dir, skill] of [[EXECUTOR_ASSETS_DIR, "roblox-executor"], [FEATURE_ASSETS_DIR, "roblox-executor-features"]]) {
    for (const name of readdirSync(dir).filter((file) => file.endsWith(".luau")).sort()) {
      const code = readFileSync(join(dir, name), "utf8").trimEnd();
      sections.push(`## Asset: .claude/skills/${skill}/assets/${name}\n\n\`\`\`lua\n${code}\n\`\`\``);
    }
  }
  return `${BANNER(".claude/skills/ (source paths below)")}\n\n# Task workflow pack\n\n` +
    "Retrieve the relevant task contract, UI workflow or source-to-executor workflow before drafting. " +
    "The source path above each section is its location in the attached archive; resolve references there.\n\n" +
    sections.join("\n\n---\n\n") + "\n";
}

function buildStylePack() {
  const guides = STYLE_SOURCES.map((source) => {
    const content = readFileSync(join(SKILLS_DIR, source), "utf8").trim();
    return `## Source: .claude/skills/${source}\n\n${content}`;
  });
  const recipes = readdirSync(STYLE_RECIPES_DIR)
    .filter((name) => name.endsWith(".luau"))
    .sort()
    .map((name) => {
      const code = readFileSync(join(STYLE_RECIPES_DIR, name), "utf8").trimEnd();
      return `## Recipe: .claude/skills/roblox-ui-components/assets/${name}\n\n\`\`\`lua\n${code}\n\`\`\``;
    });
  return `${BANNER(".claude/skills/ (source paths below)")}\n\n# Style pack\n\n` +
    "Read this before building or restyling UI. It holds the style picker question, " +
    "the everyday words users say, what each picked code (T1-T30, C1-C20, D1-D22, M0-M36, N1-N30, " +
    "O1-O20, P1-P22, S1-S22, H1-H12) " +
    "builds, and the tested recipe for every code in full. Recolour a recipe only through " +
    "its THEME block.\n\n" +
    [...guides, ...recipes].join("\n\n---\n\n") + "\n";
}

function skillMirrorTargets(path = SKILLS_DIR) {
  return readdirSync(path, { withFileTypes: true }).flatMap((entry) => {
    const source = join(path, entry.name);
    if (entry.isDirectory()) return skillMirrorTargets(source);
    if (!entry.isFile()) throw new Error(`unsupported skill entry: ${source}`);
    return [{
      path: join(REPO_ROOT, ".agents", "skills", relative(SKILLS_DIR, source)),
      content: readFileSync(source),
      mirror: true,
    }];
  });
}

function packageFiles() {
  return collectPackageFiles(REPO_ROOT, ZIP_CONTENTS, [
    relative(REPO_ROOT, GPT_MANIFEST),
    ".claude/settings.local.json",
    ".claude/launch.json",
    "docs/briefs",
    "docs/portability/gpt/test-results",
    "evals/results",
  ]);
}

function main() {
  const check = process.argv.includes("--check");
  const checkArchive = process.argv.includes("--check-archive");
  const listOnly = process.argv.includes("--list");

  if (!existsSync(SOURCE)) {
    console.error(`missing source: ${relative(REPO_ROOT, SOURCE)}`);
    process.exit(2);
  }

  const sections = parseSections(readFileSync(SOURCE, "utf8"));
  if (sections.length === 0) {
    console.error(`no "## [Pn] Title" sections found in ${relative(REPO_ROOT, SOURCE)}`);
    process.exit(2);
  }

  const skills = skillIndex();

  const targets = [
    { path: join(REPO_ROOT, "AGENTS.md"), content: buildAgents(sections, skills) },
    {
      path: join(REPO_ROOT, ".cursor", "rules", "roblox-luau-expert.mdc"),
      content: buildCursor(sections, skills),
    },
    {
      path: join(GPT_DIR, "instructions.md"),
      content: buildGptInstructions(sections),
      cap: GPT_INSTRUCTIONS_CAP,
    },
    {
      path: join(GPT_KNOWLEDGE_DIR, GPT_KNOWLEDGE_NAME),
      content: buildGptKnowledge(sections, skills),
    },
  ];

  const uiPack = buildUiPack();
  if (uiPack) targets.push({ path: join(GPT_KNOWLEDGE_DIR, GPT_UI_PACK_NAME), content: uiPack });
  targets.push({ path: join(GPT_KNOWLEDGE_DIR, "workflow-pack.md"), content: buildWorkflowPack() });
  targets.push({ path: join(GPT_KNOWLEDGE_DIR, "style-pack.md"), content: buildStylePack() });
  targets.push({ path: join(GPT_KNOWLEDGE_DIR, GPT_STYLE_PICKER_NAME), content: readFileSync(STYLE_PICKER, "utf8") });
  targets.push(...skillMirrorTargets());

  let failed = false;

  for (const target of targets) {
    const rel = relative(REPO_ROOT, target.path).split("\\").join("/");
    const size = target.content.length;

    if (target.cap && size > target.cap) {
      console.error(
        `${rel}: ${size} characters exceeds the ${target.cap} cap. ` +
          `Move a P0 section to P1 in docs/portability/rules.md.`
      );
      failed = true;
      continue;
    }

    if (listOnly) {
      if (!target.mirror) console.log(`${rel.padEnd(48)} ${String(size).padStart(6)} chars`);
      continue;
    }

    if (check || checkArchive) {
      const existing = existsSync(target.path) ? readFileSync(target.path) : null;
      if (!existing?.equals(Buffer.from(target.content))) {
        console.error(`${rel}: stale. Run: node tools/bin/build-portable.mjs`);
        failed = true;
      }
      continue;
    }

    mkdirSync(dirname(target.path), { recursive: true });
    writeFileSync(target.path, target.content, "utf8");
    if (!target.mirror) console.log(`${rel.padEnd(48)} ${String(size).padStart(6)} chars`);
  }

  if (failed) process.exit(1);

  if (!listOnly && !check && !checkArchive) {
    const zip = writePackage(packageFiles(), join(GPT_KNOWLEDGE_DIR, GPT_ZIP_NAME), GPT_MANIFEST);
    const rel = relative(REPO_ROOT, join(GPT_KNOWLEDGE_DIR, GPT_ZIP_NAME))
      .split("\\")
      .join("/");
    console.log(`${rel.padEnd(48)} ${String(Math.round(zip.bytes / 1024)).padStart(6)} KB (${zip.files} files)`);
    console.log(`\n${targets.length} file(s) from ${sections.length} section(s).`);
  } else if (check || checkArchive) {
    const problems = checkPackage(packageFiles(), join(GPT_KNOWLEDGE_DIR, GPT_ZIP_NAME), GPT_MANIFEST, checkArchive);
    if (problems.length) {
      for (const problem of problems) console.error(problem);
      process.exit(1);
    }
    console.log(`${targets.length} generated file(s) are current.`);
  }
}

main();
