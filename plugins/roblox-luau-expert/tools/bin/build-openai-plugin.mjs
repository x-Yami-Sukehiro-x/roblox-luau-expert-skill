#!/usr/bin/env node
// Build the OpenAI plugin that replaces the custom GPT.
//
// OpenAI retires custom GPTs on 11 December 2026. Its built-in "Migrate to
// plugin" turns the GPT's 8,000-character instructions into one skill and copies
// the knowledge files beside it. This builds the better replacement: all
// forty-six skills with their references, each loaded in full when its
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
import { spawnSync } from "node:child_process";
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

Installed as the \`${NAME}\` plugin: \`tools/\`, \`library/\` and \`docs/\` sit
two folders above this file (\`../../\`), and the other skills are siblings
under \`skills/\`, so \`.claude/skills/<name>/\` in this repository is
\`skills/<name>/\` here. Without Node run the Python checkers:
\`python tools/py/check_file.py <file>\` for every file check,
\`python tools/py/recipe.py T2 M4 fly\` for a picked code's recipe file,
\`python tools/py/attempt_ledger.py plan "<approach>"\` before a retry, and
\`python tools/py/dump_index.py <dump> --feature "<words>"\` for a decompiled
dump. A checker that cannot run is reported as not run, never as passed. The
style picker is \`skills/roblox-request-intake/assets/roblox-ui-style-picker.html\`
and the UI designer \`docs/visual-guide/designer.html\`.
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
    keywords: ["roblox", "luau", "ui", "ux", "executor", "hub", "decompiled", "probe", "registers", "anti-slop"],
    extensions: {
      "com.openai": {
        interface: {
          displayName: "Roblox Luau Expert",
          shortDescription: "Roblox scripts, clean UI and executor work, checked rather than guessed",
          longDescription:
            "Forty-six Roblox skills in one plugin. Long scripts are written under the 200-local limit " +
            "and checked with the Luau compiler, which also catches a local left outside its scope by a " +
            "fix. Executor work is planned before it is coded, built from the decompiled source's own call " +
            "sites with a paced action loop, held to a premium bar with honest feature status, and backed " +
            "by tested probe scripts (a remote spy and a table finder) when the source is missing a fact. " +
            "UI requests start from a playable style picker with " +
            "labeled toggles, checkboxes, dropdowns, menu animations, notifications and tooltips, and every " +
            "picked code has a tested recipe; a drag-and-drop UI designer copies whole screens for exact " +
            "rebuilds, sized for every screen from a 640 x 360 phone to 4K and held to one input contract " +
            "for mouse, touch and gamepad. Fly, noclip, ESP, spectate, freecam and other character " +
            "features ship as tested scripts, with a read-only doctor that reports why one does nothing, and " +
            "HubKit, a tested hub UI library in the shape of WindUI, is the base for any script hub. " +
            "An attempt ledger records what failed so it is not tried again. Decompiled " +
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

  // The copies the host loads must meet the same limits as the sources,
  // including the router with the path note appended.
  const lint = spawnSync(process.execPath, [join(REPO_ROOT, "tools", "bin", "lint-skills.mjs"), join(PLUGIN, "skills")], {
    encoding: "utf8",
  });
  if (lint.status !== 0) {
    console.error(`${lint.stdout}${lint.stderr}`.trim());
    process.exit(1);
  }
  console.log(lint.stdout.trim().split("\n").at(-1));

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
