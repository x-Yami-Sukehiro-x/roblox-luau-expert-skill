#!/usr/bin/env node
// Refresh the vendored ground truth and report what changed.
//
// Roblox ships weekly. The diff between releases is usually more useful than
// the dump itself: it tells you what was added, what disappeared, and what
// became deprecated since you last looked.
//
// Sources:
//   MaximumADHD/Roblox-Client-Tracker   API dump, FVariables, Luau types
//   Roblox/creator-docs                 datatype reference (the dump has none)
//
// Usage:
//   node tools/bin/update-dump.mjs           refresh, diff, regenerate tables
//   node tools/bin/update-dump.mjs --check   report only; exit 3 if behind
//   node tools/bin/update-dump.mjs --skip-tables

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import { DUMP_DIR, REPO_ROOT } from "./lib/dump.mjs";

const TRACKER = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox";
const DOCS_API = "https://api.github.com/repos/Roblox/creator-docs/contents/content/en-us/reference/engine/datatypes";
const DOCS_RAW = "https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/datatypes";

const TRACKER_FILES = {
  "version.txt": "version.txt",
  "API-Dump.txt": "API-Dump.txt",
  "FVariables.txt": "FVariables.txt",
  "LuauTypes.d.luau": "LuauTypes.d.luau",
};

async function fetchText(url) {
  const res = await fetch(url, { headers: { "User-Agent": "roblox-luau-expert" } });
  if (!res.ok) throw new Error(`${url} -> HTTP ${res.status}`);
  return res.text();
}

// Every Class.Member in a dump, for diffing one release against the next.
function memberSet(text) {
  const out = new Set();
  let owner = null;
  for (const line of text.split(/\r?\n/)) {
    if (!line.trim()) continue;
    if (!/^[\t ]/.test(line)) {
      const m = /^Class\s+([A-Za-z0-9_]+)/.exec(line.trim());
      owner = m ? m[1] : null;
      continue;
    }
    if (!owner) continue;
    const body = line.trim();
    const prop = /^Property\s+([A-Za-z0-9_]+)\.(.*)\s*:\s*[^:]*$/.exec(body);
    if (prop) {
      out.add(`${prop[1]}.${prop[2].trim()}${/\[Deprecated\]/.test(body) ? "  [Deprecated]" : ""}`);
      continue;
    }
    const call = /^(?:Function|Event|Callback)\s+([A-Za-z0-9_]+)[.:]([^(]+?)\s*\(/.exec(body);
    if (call) {
      out.add(`${call[1]}.${call[2].trim()}${/\[Deprecated\]/.test(body) ? "  [Deprecated]" : ""}`);
    }
  }
  return out;
}

async function main() {
  const args = process.argv.slice(2);
  const checkOnly = args.includes("--check");
  const skipTables = args.includes("--skip-tables");

  if (!existsSync(DUMP_DIR)) mkdirSync(DUMP_DIR, { recursive: true });

  const localVersion = existsSync(join(DUMP_DIR, "version.txt"))
    ? readFileSync(join(DUMP_DIR, "version.txt"), "utf8").trim()
    : "(none)";
  const remoteVersion = (await fetchText(`${TRACKER}/version.txt`)).trim();

  console.log(`vendored: ${localVersion}`);
  console.log(`upstream: ${remoteVersion}`);

  if (localVersion === remoteVersion) {
    console.log("\nUp to date.");
    if (checkOnly) return;
  } else if (checkOnly) {
    console.log("\nBEHIND upstream. Run without --check to refresh.");
    process.exitCode = 3;
    return;
  }

  const oldDumpPath = join(DUMP_DIR, "API-Dump.txt");
  const oldDump = existsSync(oldDumpPath) ? readFileSync(oldDumpPath, "utf8") : "";

  for (const [local, remote] of Object.entries(TRACKER_FILES)) {
    const text = await fetchText(`${TRACKER}/${remote}`);
    writeFileSync(join(DUMP_DIR, local), text, "utf8");
    console.log(`  fetched ${local}  (${text.length.toLocaleString()} bytes)`);
  }

  // Datatypes come from creator-docs; the API dump does not contain them.
  const dtDir = join(DUMP_DIR, "datatypes");
  if (!existsSync(dtDir)) mkdirSync(dtDir, { recursive: true });
  const listing = JSON.parse(await fetchText(DOCS_API));
  for (const entry of listing) {
    if (!entry.name.endsWith(".yaml")) continue;
    writeFileSync(join(dtDir, entry.name), await fetchText(`${DOCS_RAW}/${entry.name}`), "utf8");
  }
  console.log(`  fetched ${listing.length} datatype file(s)`);

  if (oldDump) {
    const before = memberSet(oldDump);
    const after = memberSet(readFileSync(oldDumpPath, "utf8"));
    const added = [...after].filter((x) => !before.has(x)).sort();
    const removed = [...before].filter((x) => !after.has(x)).sort();

    console.log(`\n${localVersion} -> ${remoteVersion}`);
    const show = (title, list) => {
      if (!list.length) return;
      console.log(`\n${title} (${list.length}):`);
      for (const x of list.slice(0, 60)) console.log(`  ${x}`);
      if (list.length > 60) console.log(`  ... and ${list.length - 60} more`);
    };
    show("ADDED", added);
    show("REMOVED", removed);
    if (!added.length && !removed.length) console.log("  no member-level changes");
  }

  if (!skipTables) {
    console.log("\nRegenerating verified/ tables...");
    execFileSync(process.execPath, [join(REPO_ROOT, "tools", "bin", "generate-tables.mjs")], {
      stdio: "inherit",
    });
    console.log("\nNow re-run the linters - a dump change can invalidate prose:");
    console.log("  node tools/bin/lint-prose.mjs");
    console.log("  node tools/bin/lint-luau-blocks.mjs");
  }
}

main().catch((e) => {
  console.error(String(e.message ?? e));
  process.exit(2);
});
