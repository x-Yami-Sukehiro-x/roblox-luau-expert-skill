#!/usr/bin/env node
// Build the OpenAI plugin that replaces the custom GPT.
//
// OpenAI retires custom GPTs on 11 December 2026. Its built-in "Migrate to
// plugin" turns the GPT's 8,000-character instructions into one skill and copies
// the knowledge files beside it. This builds the better replacement: all
// twenty-one skills with their references, each loaded in full when its
// description matches, plus the tools, library and guide the skills point at.
//
// Output (gitignored, rebuilt from source):
//   dist/openai-plugin/roblox-luau-expert/          the plugin folder
//   dist/openai-plugin/roblox-luau-expert-plugin.zip
//   dist/openai-plugin/package-manifest.json
//
// Usage:
//   node tools/bin/build-openai-plugin.mjs

import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, readdirSync } from "node:fs";
import { join, relative } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";
import { collectPackageFiles, writePackage } from "./lib/portable-package.mjs";

const NAME = "roblox-luau-expert";
const OUT_ROOT = join(REPO_ROOT, "dist", "openai-plugin");
const PLUGIN = join(OUT_ROOT, NAME);
const SKILLS = join(REPO_ROOT, ".claude", "skills");

// Paths the skills name at run time: the checkers, the reference library, the
// style picker and the vetted UI exemplars. Nothing else from the repository.
const SUPPORT = [
  "tools",
  "library",
  "docs/visual-guide",
  "docs/portability/gpt/UIs",
  "docs/SOURCES.md",
  "docs/mcp.md",
  "docs/CHANGELOG.md",
  "AGENTS.md",
  "LICENSE.md",
  "NOTICE.md",
];

const SKIP = new Set(["__pycache__", "node_modules", "toastharness.luau"]);

// The plugin card's images, from docs/assets/ into the plugin's own assets/.
const IMAGES = {
  composerIcon: "icon.png",
  logo: "logo.png",
  screenshots: ["screenshot-picker.png", "screenshot-designer.png"],
};

// Skill references resolve from the plugin root, which is two folders above
// each SKILL.md. Said once, in the router every Roblox task loads first.
const PATHS_NOTE = `

## Plugin paths

This skill is installed as the \`${NAME}\` plugin. \`tools/\`, \`library/\` and
\`docs/\` sit at the plugin root, two folders above this file (\`../../\`), and
the other Roblox skills are its siblings under \`skills/\`. Resolve a path such
as \`tools/py/roblox_lint.py\` or \`.claude/skills/roblox-ui/...\` from there:
\`.claude/skills/<name>/\` in this repository is \`skills/<name>/\` here. Run the
Python checkers when Node is unavailable; a checker that cannot run is reported
as not run, never as passed. \`python tools/py/dump_index.py <dump> --feature
"<words>"\` searches a decompiled dump for a feature, and \`--inventory\` lists
what the dump shows for feature ideas. \`node tools/bin/check-registers.mjs
<file>\` (no Node: \`python tools/py/register_budget.py\`) compiles a script and
reports how close each function is to the local-register limit.
\`node tools/bin/check-file.mjs <file>\` (no Node: \`python tools/py/check_file.py\`)
runs every file-level check in one call, and \`python tools/py/recipe.py T2 M4
fly\` names the recipe file for a picked code or feature. The style
picker page is \`skills/roblox-request-intake/assets/roblox-ui-style-picker.html\`;
attach it when the hosted link does not open. The UI designer is
\`docs/visual-guide/designer.html\`, hosted beside the picker as \`designer.html\`.
`;

function version() {
  const manifest = JSON.parse(readFileSync(join(REPO_ROOT, ".claude-plugin", "plugin.json"), "utf8"));
  return manifest.version;
}

function copyTree(source, destination) {
  cpSync(source, destination, {
    recursive: true,
    filter: (path) => !SKIP.has(path.split(/[\\/]/).pop()) && !path.endsWith(".pyc"),
  });
}

function main() {
  rmSync(OUT_ROOT, { recursive: true, force: true });
  mkdirSync(PLUGIN, { recursive: true });

  for (const entry of readdirSync(SKILLS, { withFileTypes: true })) {
    if (!entry.isDirectory() || !existsSync(join(SKILLS, entry.name, "SKILL.md"))) continue;
    copyTree(join(SKILLS, entry.name), join(PLUGIN, "skills", entry.name));
  }
  cpSync(
    join(REPO_ROOT, "docs", "visual-guide", "index.html"),
    join(PLUGIN, "skills", "roblox-request-intake", "assets", "roblox-ui-style-picker.html")
  );
  for (const name of [IMAGES.composerIcon, IMAGES.logo, ...IMAGES.screenshots]) {
    cpSync(join(REPO_ROOT, "docs", "assets", name), join(PLUGIN, "assets", name));
  }
  const router = join(PLUGIN, "skills", "roblox-luau-expert", "SKILL.md");
  writeFileSync(router, readFileSync(router, "utf8").trimEnd() + PATHS_NOTE, "utf8");

  for (const entry of SUPPORT) {
    const source = join(REPO_ROOT, entry);
    if (!existsSync(source)) throw new Error(`plugin source missing: ${entry}`);
    copyTree(source, join(PLUGIN, entry));
  }

  const manifest = {
    $schema: "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    name: NAME,
    version: version(),
    description:
      "Roblox and Luau expertise: verified engine APIs, clean UI with a labeled style picker and tested " +
      "recipes, decompiled-source to executor scripts, networking, DataStores, performance and security.",
    author: { name: "x-Yami-Sukehiro-x" },
    license: "LicenseRef-PolyForm-Strict-1.0.0",
    keywords: ["roblox", "luau", "ui", "ux", "executor", "decompiled", "anti-slop"],
    extensions: {
      "com.openai": {
        interface: {
          displayName: "Roblox Luau Expert",
          shortDescription: "Roblox scripts, clean UI and executor work, checked rather than guessed",
          longDescription:
            "Twenty-one Roblox skills in one plugin. UI requests start from a playable style picker with " +
            "labeled toggles, checkboxes, dropdowns, menu animations, notifications and tooltips, and every " +
            "picked code has a tested recipe; a drag-and-drop UI designer copies whole screens for exact " +
            "rebuilds. Fly, noclip, ESP and other character features ship as tested scripts. Decompiled " +
            "source is searched for the requested feature; when it is missing, a " +
            "read-only runtime probe collects the evidence instead of guessed names. Every " +
            "Roblox API is checked against a vendored API dump, and bundled Python checkers count the " +
            "anti-slop and UI rules on the final file.",
          developerName: "x-Yami-Sukehiro-x",
          category: "Coding",
          brandColor: "#2EA07F",
          composerIcon: `./assets/${IMAGES.composerIcon}`,
          logo: `./assets/${IMAGES.logo}`,
          screenshots: IMAGES.screenshots.map((name) => `./assets/${name}`),
          defaultPrompt: [
            "Make me a clean settings menu for my Roblox game",
            "Here is decompiled source from a game, write me a script against it",
            "Clean the AI slop out of this Luau script",
          ],
        },
      },
    },
  };
  writeFileSync(join(PLUGIN, "plugin.json"), JSON.stringify(manifest, null, 2) + "\n", "utf8");

  const files = collectPackageFiles(OUT_ROOT, [NAME]);
  const zip = writePackage(
    files,
    join(OUT_ROOT, `${NAME}-plugin.zip`),
    join(OUT_ROOT, "package-manifest.json")
  );
  const skills = readdirSync(join(PLUGIN, "skills")).length;
  console.log(`${relative(REPO_ROOT, PLUGIN).split("\\").join("/")}  ${skills} skill(s), ${files.length} file(s)`);
  console.log(`dist/openai-plugin/${NAME}-plugin.zip  ${Math.round(zip.bytes / 1024)} KB`);
}

main();
