#!/usr/bin/env node
// Rebuild the verified icon list and the designer's icon data.
//
// icons.rest publishes the lucide icon set already uploaded to Roblox, as a
// name-to-asset-id table inside its page bundle. An id is only useful if Roblox
// still serves it as an image, so every id is asked about on the thumbnail
// service and anything that is not a finished image is left out.
//
// The shapes come from lucide itself (ISC), at the version icons.rest built
// from, with a newer release for icons added since. A renamed icon is resolved
// through lucide-react's own alias exports rather than guessed.
//
// Writes:
//   .claude/skills/roblox-ui-components/references/icon-ids.txt
//   docs/visual-guide/designer.html   between the icons:start / icons:end marks
//
// Usage:
//   node tools/bin/update-icons.mjs
//   node tools/bin/update-icons.mjs --dry-run   fetch and report, write nothing

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

const SITE = "https://icons.rest";
const THUMBNAILS = "https://thumbnails.roblox.com/v1/assets";
const LUCIDE_VERSIONS = ["0.344.0", "0.460.0"];
const CDN = "https://cdn.jsdelivr.net/npm";
const LIST = join(REPO_ROOT, ".claude", "skills", "roblox-ui-components", "references", "icon-ids.txt");
const DESIGNER = join(REPO_ROOT, "docs", "visual-guide", "designer.html");
const MAX_TAGS = 6;

async function fetchText(url) {
  const response = await fetch(url, { headers: { "User-Agent": "roblox-luau-expert" } });
  if (!response.ok) throw new Error(`${url} -> HTTP ${response.status}`);
  return response.text();
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function siteRows() {
  const page = await fetchText(SITE);
  const script = /src="(\/assets\/index-[^"]+\.js)"/.exec(page);
  if (!script) throw new Error("icons.rest page no longer names its index bundle");
  const bundle = await fetchText(SITE + script[1]);
  const rows = new Map();
  for (const match of bundle.matchAll(/\{name:"([a-z0-9-]+)",asset_id:"(\d+)",lucideName:"([A-Za-z0-9]+)"\}/g)) {
    rows.set(match[1], { name: match[1], id: match[2], lucideName: match[3] });
  }
  if (rows.size < 1000) throw new Error(`only ${rows.size} icons found in the icons.rest bundle`);
  return [...rows.values()];
}

// state Completed with an /Image/ url is a real image; anything else is not
// (yet) something a player would see.
async function verify(ids) {
  const verdict = new Map();
  let pending = [...ids];
  for (let round = 0; round < 5 && pending.length > 0; round += 1) {
    if (round > 0) await sleep(3000);
    const retry = [];
    for (let start = 0; start < pending.length; start += 50) {
      const batch = pending.slice(start, start + 50);
      const url = `${THUMBNAILS}?assetIds=${batch.join(",")}&size=150x150&format=Png`;
      const body = JSON.parse(await fetchText(url));
      for (const item of body.data ?? []) {
        const id = String(item.targetId);
        const image = item.state === "Completed" && /\/Image\//.test(item.imageUrl ?? "");
        verdict.set(id, image ? "image" : item.state);
        if (item.state === "Pending") retry.push(id);
      }
      await sleep(300);
    }
    pending = retry;
  }
  return verdict;
}

async function lucide() {
  const shapes = new Map();
  const tags = new Map();
  const alias = new Map();
  for (const version of LUCIDE_VERSIONS) {
    const nodes = JSON.parse(await fetchText(`${CDN}/lucide-static@${version}/icon-nodes.json`));
    for (const [name, node] of Object.entries(nodes)) if (!shapes.has(name)) shapes.set(name, node);
    const words = JSON.parse(await fetchText(`${CDN}/lucide-static@${version}/tags.json`));
    for (const [name, list] of Object.entries(words)) if (!tags.has(name)) tags.set(name, list);
    const exports = await fetchText(`${CDN}/lucide-react@${version}/dist/esm/lucide-react.js`);
    for (const match of exports.matchAll(/export \{([^}]*)\} from '\.\/icons\/([a-z0-9-]+)\.js'/g)) {
      for (const [, exported] of match[1].matchAll(/default as (\w+)/g)) {
        if (!alias.has(exported)) alias.set(exported, match[2]);
      }
    }
  }
  return { shapes, tags, alias };
}

function markup(node) {
  return node
    .map(([tag, attributes]) => {
      const pairs = Object.entries(attributes)
        .filter(([key]) => key !== "key")
        .map(([key, value]) => `${key}='${value}'`)
        .join(" ");
      return `<${tag} ${pairs}/>`;
    })
    .join("");
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");
  const rows = await siteRows();
  const verdict = await verify([...new Set(rows.map((row) => row.id))]);
  const { shapes, tags, alias } = await lucide();

  const kept = [];
  const dropped = [];
  for (const row of rows.sort((a, b) => a.name.localeCompare(b.name))) {
    const canonical = shapes.has(row.name) ? row.name : alias.get(row.lucideName);
    const shape = canonical ? shapes.get(canonical) : null;
    if (verdict.get(row.id) !== "image") {
      dropped.push(`${row.name} (${verdict.get(row.id) ?? "no answer"})`);
      continue;
    }
    if (!shape) {
      dropped.push(`${row.name} (no lucide shape)`);
      continue;
    }
    const words = (tags.get(canonical) ?? []).slice(0, MAX_TAGS);
    kept.push({ ...row, canonical, shape: markup(shape), words });
  }

  const today = new Date().toISOString().slice(0, 10);
  console.log(`${kept.length} icon(s) verified as images; ${dropped.length} left out`);
  for (const line of dropped) console.log(`  left out: ${line}`);
  if (dryRun) return;

  const list = [
    `# Lucide icons already uploaded to Roblox (by icons.rest), each confirmed as a`,
    `# real image by thumbnails.roblox.com on ${today}: ${kept.length} icons.`,
    `# Columns: name <TAB> content id <TAB> what the icon is searched for (lucide tags).`,
    `# Regenerate and re-verify: node tools/bin/update-icons.mjs`,
    ...kept.map((icon) => `${icon.name}\trbxassetid://${icon.id}\t${icon.words.join(", ")}`),
    "",
  ].join("\n");
  writeFileSync(LIST, list, "utf8");
  console.log(`wrote ${LIST.slice(REPO_ROOT.length + 1)}`);

  if (!existsSync(DESIGNER)) {
    console.log("designer.html not found; icon data not injected");
    return;
  }
  const page = readFileSync(DESIGNER, "utf8");
  const data = kept.map((icon) => [icon.name, icon.id, icon.shape, icon.words.join(" ")]);
  const block = `/*icons:start*/const ICONS=${JSON.stringify(data)};const ICONS_CHECKED="${today}";/*icons:end*/`;
  const next = page.replace(/\/\*icons:start\*\/[\s\S]*?\/\*icons:end\*\//, () => block);
  if (next === page && !page.includes(block)) throw new Error("designer.html has no icons:start / icons:end marks");
  writeFileSync(DESIGNER, next, "utf8");
  console.log(`injected ${kept.length} icon(s) into docs/visual-guide/designer.html`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(2);
});
