#!/usr/bin/env node
// Ask Roblox whether every asset id in a file is real, and whether it is an
// image.
//
// An invented `rbxassetid://` is the worst kind of wrong answer: it compiles,
// it runs, nothing errors, and the icon is simply blank. No amount of reading
// the code finds it. Only the asset service knows.
//
// The thumbnail service answers all three cases distinctly:
//
//   state Completed, url .../Image/...          real, and it is an image
//   state Completed, url .../UnknownImage/...   the id exists, but is not an
//                                               image - it will render blank
//   state Error,     url .../BrokenImage/...    no such asset
//
// `rbxassetid://1234567890`, the placeholder every model reaches for, is an
// UnknownImage. That is the whole reason this file exists.
//
// Usage:
//   node tools/bin/verify-asset-ids.mjs <file.luau|directory> [...]
//   node tools/bin/verify-asset-ids.mjs --ids 116396312853810,86817768619372
//   node tools/bin/verify-asset-ids.mjs --json <file.luau>
//
// Exit 1 on any id that is not a real image. Exit 2 if the service could not
// be reached - a gate that passes when it could not check is worse than no
// gate.

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

const THUMBNAIL_ENDPOINT = "https://thumbnails.roblox.com/v1/assets";
const BATCH_SIZE = 50;
const TIMEOUT_MS = 15000;

// Ids that are deliberately not real, written so a reader can see that at a
// glance. Anything else numeric is a claim about a real asset.
const OBVIOUS_PLACEHOLDER = /^0+$/;

/** Strip comments so a documented example id is not treated as shipped code. */
function stripComments(source) {
  return source
    .replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, " ")
    .replace(/--[^\n]*/g, " ");
}

function lineOf(source, index) {
  return source.slice(0, index).split("\n").length;
}

/** Every asset id a file actually ships, with the line it is on. */
function extractIds(rawSource) {
  const source = stripComments(rawSource);
  const found = new Map();
  const note = (id, index) => {
    if (OBVIOUS_PLACEHOLDER.test(id)) return;
    if (!found.has(id)) found.set(id, lineOf(source, index));
  };

  for (const match of source.matchAll(/rbxassetid:\/\/(\d+)/g)) {
    note(match[1], match.index);
  }
  // `Image = 116396312853810` and `IconImage = ICONS.x` both happen; only the
  // numeric form is checkable here.
  for (const match of source.matchAll(
    /\b(?:Image|ImageId|Texture|TextureId|IconImage|Icon)\s*=\s*["']?(\d{6,})["']?/g
  )) {
    note(match[1], match.index);
  }
  return found;
}

async function classify(ids) {
  const results = new Map();
  for (let start = 0; start < ids.length; start += BATCH_SIZE) {
    const batch = ids.slice(start, start + BATCH_SIZE);
    const url = `${THUMBNAIL_ENDPOINT}?assetIds=${batch.join(",")}&size=150x150&format=Png`;
    const response = await fetch(url, { signal: AbortSignal.timeout(TIMEOUT_MS) });
    if (!response.ok) {
      throw new Error(`thumbnail service returned ${response.status}`);
    }
    const body = await response.json();
    for (const entry of body.data ?? []) {
      const id = String(entry.targetId);
      const imageUrl = entry.imageUrl ?? "";
      if (entry.state !== "Completed" || /BrokenImage/.test(imageUrl)) {
        results.set(id, { ok: false, reason: "no such asset" });
      } else if (/UnknownImage/.test(imageUrl)) {
        results.set(id, { ok: false, reason: "asset exists but is not an image - renders blank" });
      } else {
        results.set(id, { ok: true, reason: "image" });
      }
    }
    for (const id of batch) {
      if (!results.has(id)) {
        results.set(id, { ok: false, reason: "the service returned no row for this id" });
      }
    }
  }
  return results;
}

function collect(target, out = []) {
  if (statSync(target).isDirectory()) {
    for (const entry of readdirSync(target)) {
      if (entry === "node_modules" || entry === ".git") continue;
      collect(join(target, entry), out);
    }
  } else if (/\.luau?$/.test(target)) {
    out.push(target);
  }
  return out;
}

async function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const idsFlag = args.indexOf("--ids");

  /** @type {Map<string, {file: string, line: number}[]>} */
  const sites = new Map();

  if (idsFlag !== -1) {
    for (const id of (args[idsFlag + 1] ?? "").split(/[,\s]+/).filter(Boolean)) {
      sites.set(id, [{ file: "--ids", line: 0 }]);
    }
  } else {
    const targets = args.filter((a) => !a.startsWith("--"));
    if (targets.length === 0) {
      console.error(
        "usage: node tools/bin/verify-asset-ids.mjs <file.luau|directory> [...]\n" +
          "       node tools/bin/verify-asset-ids.mjs --ids <id,id,...>\n" +
          "Asks Roblox whether each asset id is real and is an image."
      );
      process.exit(2);
    }
    const files = [];
    for (const target of targets) {
      const full = existsSync(target) ? target : join(REPO_ROOT, target);
      if (!existsSync(full)) {
        console.error(`no such path: ${target}`);
        process.exit(2);
      }
      collect(full, files);
    }
    for (const file of files) {
      const inside = relative(REPO_ROOT, file).split(sep).join("/");
      const rel = inside.startsWith("..") ? file.split(/[/\\]/).pop() : inside;
      for (const [id, line] of extractIds(readFileSync(file, "utf8"))) {
        if (!sites.has(id)) sites.set(id, []);
        sites.get(id).push({ file: rel, line });
      }
    }
  }

  const ids = [...sites.keys()];
  if (ids.length === 0) {
    if (!asJson) console.log("no asset ids found");
    return;
  }

  let classified;
  try {
    classified = await classify(ids);
  } catch (error) {
    console.error(`could not reach the Roblox thumbnail service: ${error.message}`);
    console.error("not reporting a pass - re-run when the network is available");
    process.exit(2);
  }

  const bad = [];
  for (const id of ids) {
    const verdict = classified.get(id);
    if (!verdict.ok) bad.push({ id, ...verdict, sites: sites.get(id) });
  }

  if (asJson) {
    console.log(
      JSON.stringify(
        { checked: ids.length, bad: bad.map((b) => ({ id: b.id, reason: b.reason, sites: b.sites })) },
        null,
        2
      )
    );
  } else {
    for (const entry of bad) {
      for (const site of entry.sites) {
        console.log(`  ${site.file}:${site.line}  E-ASSET  rbxassetid://${entry.id} - ${entry.reason}`);
      }
    }
    console.log(`\n${ids.length} asset id(s) checked - ${bad.length} bad`);
  }

  if (bad.length > 0) process.exitCode = 1;
}

await main();
