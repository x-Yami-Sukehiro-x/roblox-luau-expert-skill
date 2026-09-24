#!/usr/bin/env node
// Check every API claim in the skill prose against the vendored API dump.
//
// The stack already owned ground truth and never pointed it at itself. That is
// how a recommendation to use a [Deprecated] API survived in the same repo that
// generates the deprecation table listing it.
//
// Usage:
//   node tools/bin/lint-prose.mjs            lint the whole stack
//   node tools/bin/lint-prose.mjs <path...>  lint specific files
//   node tools/bin/lint-prose.mjs --json     machine-readable output
//
// Exit 1 on any E-* finding. W-* are reported but do not fail.

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";
import {
  loadDump,
  loadDatatypes,
  resolveDatatypeMember,
  resolveMember,
  isUnreachable,
  assignmentBlocker,
  formatSignature,
  ALIASES,
  SECURITY_NOTES,
  REPO_ROOT,
} from "./lib/dump.mjs";

const SKILLS_DIR = join(REPO_ROOT, ".claude", "skills");
const ALLOW_PATH = join(REPO_ROOT, "tools", "lint-allow.txt");

// references/verified/ is generated straight from the dump, so linting it would
// only ever restate the dump to itself.
const SKIP_DIRS = new Set(["verified", "node_modules", ".git"]);

// Words that, near a finding, show the author already knows. A deprecated API
// named *because* it is deprecated is documentation, not a defect.
const DEPRECATION_WORDS =
  /\b(deprecat|legacy|superseded|supersedes|replaced|replacement|instead|obsolete|do not use|don't use|avoid|no longer|removed|old form|older|historical|not the|stale)\b/i;
const SECURITY_WORDS =
  /\b(plugin|robloxscript|corescript|security|gated|gate|restricted|not available|cannot|can't|unavailable|elevated|internal|opencloud|open cloud)\b/i;
const WRITETIME_WORDS =
  /\b(read-only|readonly|not scriptable|notscriptable|loadonly|load-only|load time|cannot be set|can't be set|cannot set|not settable|set it in studio|studio only|at load|design time)\b/i;
const ALIAS_WORDS =
  /\b(alias|aliases|same (event|point|thing|frame)|renamed|new name|supersed\w*|current names?|two names|identical)\b/i;

const ISO_DATE = /\b20\d{2}-\d{2}-\d{2}\b/;
// A count beside the star: "12k stars", "★ 4,100". "Star rating (C17)" is not one.
const STAR_FIGURE = /\d[\d,.]*\s*[km]?\+?\s*(?:★|⭐|\bstars?\b)|(?:★|⭐|\bstars?\b):?\s*\d/i;

function loadAllowlist() {
  const allow = new Map();
  if (!existsSync(ALLOW_PATH)) return allow;
  const lines = readFileSync(ALLOW_PATH, "utf8").split(/\r?\n/);
  for (const [i, raw] of lines.entries()) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    // Format:  CODE  symbol  # reason
    const m = /^(\S+)\s+(\S+)\s*#\s*(.+)$/.exec(line);
    if (!m) {
      console.error(
        `lint-allow.txt:${i + 1}: entry needs "CODE symbol # reason" - an unreasoned entry is not an allowlist, it is a hiding place`
      );
      process.exitCode = 1;
      continue;
    }
    allow.set(`${m[1]}:${m[2]}`, m[3]);
  }
  return allow;
}

function walk(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      if (SKIP_DIRS.has(entry)) continue;
      walk(full, out);
    } else if (entry.endsWith(".md")) {
      out.push(full);
    }
  }
  return out;
}

// Whether the author already flagged the caveat. Scoped to the enclosing
// markdown section rather than a fixed line radius: a note further down under
// the same heading is still the author knowing, and a tight window turns those
// into false alarms. False alarms are worse than no linter — they teach you to
// stop reading the output.
function context(lines, index) {
  let from = 0;
  for (let i = index; i >= 0; i -= 1) {
    if (/^#{1,6}\s/.test(lines[i])) {
      from = i;
      break;
    }
  }
  let to = lines.length;
  for (let i = index + 1; i < lines.length; i += 1) {
    if (/^#{1,6}\s/.test(lines[i])) {
      to = i;
      break;
    }
  }
  // Widen for prose that sits before the first heading in a file.
  from = Math.min(from, Math.max(0, index - 3));
  to = Math.max(to, Math.min(lines.length, index + 4));
  return lines.slice(from, to).join("\n");
}

function classifyFences(lines) {
  // Returns a per-line marker: null outside fences, the language inside.
  const marks = new Array(lines.length).fill(null);
  let lang = null;
  for (const [i, line] of lines.entries()) {
    const fence = /^\s*```\s*([A-Za-z0-9_+-]*)/.exec(line);
    if (fence) {
      if (lang === null) {
        lang = (fence[1] || "text").toLowerCase();
        marks[i] = "__open__";
      } else {
        marks[i] = "__close__";
        lang = null;
      }
      continue;
    }
    marks[i] = lang;
  }
  return marks;
}

function lintFile(path, dump, allow, findings) {
  const rel = relative(REPO_ROOT, path).split(sep).join("/");
  const text = readFileSync(path, "utf8");
  const lines = text.split(/\r?\n/);
  const fences = classifyFences(lines);

  const add = (code, line, symbol, message, detail) => {
    if (allow.has(`${code}:${symbol}`)) return;
    findings.push({ code, file: rel, line: line + 1, symbol, message, detail });
  };

  const fileHasDate = ISO_DATE.test(text);
  const datatypes = loadDatatypes();

  for (const [i, line] of lines.entries()) {
    const inCode = fences[i] !== null && !String(fences[i]).startsWith("__");
    const isLuau = inCode && /^(lua|luau)$/.test(String(fences[i]));

    // Ignore markdown link targets and headings-only lines for API extraction.
    const scan = line.replace(/\]\([^)]*\)/g, "");

    // ---- Enum paths -------------------------------------------------------
    for (const m of scan.matchAll(/\bEnum\.([A-Za-z0-9_]+)(?:\.([A-Za-z0-9_]+))?/g)) {
      const [, enumName, itemName] = m;
      const e = dump.enums.get(enumName);
      if (!e) {
        add("E-MISSING", i, `Enum.${enumName}`, `Enum.${enumName} is not in the dump`);
        continue;
      }
      if (itemName && !e.items.has(itemName)) {
        add(
          "E-MISSING",
          i,
          `Enum.${enumName}.${itemName}`,
          `Enum.${enumName} has no item ${itemName}`,
          `valid: ${[...e.items.keys()].slice(0, 8).join(", ")}`
        );
      }
    }

    // ---- Method calls: Class:Method( and Datatype.member( -----------------
    // Methods are never children, so a miss here is a real defect rather than
    // an instance being indexed by name.
    for (const m of scan.matchAll(/\b([A-Z][A-Za-z0-9_]*)\s*[.:]\s*([A-Za-z0-9_]+)\s*\(/g)) {
      const [, className, method] = m;
      // Datatypes (CFrame, SharedTable, RaycastParams) are absent from the API
      // dump entirely, so they resolve through the vendored datatype reference.
      // A few names are both - Instance is a class with a full member list and
      // a datatype carrying only the `new` constructor - so the class wins.
      if (datatypes.has(className) && !dump.classes.has(className)) {
        if (!resolveDatatypeMember(className, method)) {
          const dt = datatypes.get(className);
          add(
            "E-MISSING",
            i,
            `${className}.${method}`,
            `datatype ${className} has no member ${method}`,
            `members: ${[...dt.members.keys()].slice(0, 12).join(", ")}`
          );
        }
        continue;
      }
      if (!dump.classes.has(className)) continue;
      const rec = resolveMember(className, method);
      if (!rec) {
        // Constructors live on the datatype side even when a class shares the
        // name: Instance.new is the datatype constructor, not a class member.
        if (resolveDatatypeMember(className, method)) continue;
        add(
          "E-MISSING",
          i,
          `${className}:${method}`,
          `${className} has no member ${method}`
        );
        continue;
      }
      checkRecord(rec, i, `${className}:${method}`);
    }

    // ---- Qualified members: Class.Member ----------------------------------
    // Only checked for gates, never for existence: Workspace.Map is a child,
    // not a missing API, and flagging it would make the linter untrustworthy.
    for (const m of scan.matchAll(/\b([A-Z][A-Za-z0-9_]*)\.([A-Za-z0-9_]+)\b/g)) {
      const [, className, member] = m;
      if (className === "Enum") continue;
      if (!dump.classes.has(className)) continue;
      const rec = resolveMember(className, member);
      if (!rec) continue;
      checkRecord(rec, i, `${className}.${member}`);

      // Assignment to a property that cannot be assigned at runtime.
      if (isLuau || !inCode) {
        const assign = new RegExp(
          `\\b${className}\\.${member}\\s*=(?!=)`
        );
        if (assign.test(scan)) {
          const blocker = assignmentBlocker(rec);
          if (blocker && !WRITETIME_WORDS.test(context(lines, i))) {
            add(
              "E-WRITETIME",
              i,
              `${className}.${member}`,
              `assigns ${className}.${member}, which is ${blocker}`,
              formatSignature(rec.signature)
            );
          }
        }
      }
    }
  }

  function checkRecord(rec, i, symbol) {
    if (rec.deprecated && !DEPRECATION_WORDS.test(context(lines, i))) {
      add(
        "E-DEPRECATED",
        i,
        symbol,
        `${rec.qualified} is [Deprecated] and is presented without a note`,
        formatSignature(rec.signature)
      );
    }
    const gate = isUnreachable(rec);
    if (gate && !SECURITY_WORDS.test(context(lines, i))) {
      add(
        "E-SECURITY",
        i,
        symbol,
        `${rec.qualified} is gated to ${gate} - ${SECURITY_NOTES[gate] ?? "not reachable from a normal script"}`,
        formatSignature(rec.signature)
      );
    }
  }

  // ---- Aliases described as distinct --------------------------------------
  for (const [a, b] of ALIASES) {
    const shortA = a.split(".")[1];
    const shortB = b.split(".")[1];
    const hasA = new RegExp(`\\b${shortA}\\b`).test(text);
    const hasB = new RegExp(`\\b${shortB}\\b`).test(text);
    if (hasA && hasB && !ALIAS_WORDS.test(text)) {
      const idx = lines.findIndex((l) => new RegExp(`\\b${shortA}\\b`).test(l));
      findings.push({
        code: "W-ALIAS",
        file: rel,
        line: Math.max(idx, 0) + 1,
        symbol: `${shortA}/${shortB}`,
        message: `${a} and ${b} are the same event; this file names both without saying so`,
      });
    }
  }

  // ---- Undated popularity figures -----------------------------------------
  if (!fileHasDate) {
    for (const [i, line] of lines.entries()) {
      if (STAR_FIGURE.test(line)) {
        findings.push({
          code: "W-UNDATED",
          file: rel,
          line: i + 1,
          symbol: line.trim().slice(0, 60),
          message: "star or recency figure with no date stamp anywhere in the file",
        });
        break;
      }
    }
  }
}

function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const explicit = args.filter((a) => !a.startsWith("--"));

  const dump = loadDump();
  const allow = loadAllowlist();
  const files = explicit.length
    ? explicit.flatMap((p) => {
        // A directory argument used to crash with EISDIR. Expanding it is what
        // anyone typing one meant, and the crash taught nothing.
        const full = existsSync(p) ? p : join(REPO_ROOT, p);
        if (!existsSync(full)) {
          console.error(`no such path: ${p}`);
          process.exitCode = 2;
          return [];
        }
        return statSync(full).isDirectory() ? walk(full) : [full];
      })
    : walk(SKILLS_DIR);

  const findings = [];
  for (const f of files) lintFile(f, dump, allow, findings);

  const errors = findings.filter((f) => f.code.startsWith("E-"));
  const warnings = findings.filter((f) => f.code.startsWith("W-"));

  if (asJson) {
    console.log(JSON.stringify({ dump: dump.version, findings }, null, 2));
  } else {
    const order = ["E-MISSING", "E-DEPRECATED", "E-SECURITY", "E-WRITETIME", "W-ALIAS", "W-UNDATED"];
    findings.sort(
      (a, b) =>
        order.indexOf(a.code) - order.indexOf(b.code) ||
        a.file.localeCompare(b.file) ||
        a.line - b.line
    );
    for (const f of findings) {
      console.log(`${f.file}:${f.line}  ${f.code}  ${f.message}`);
      if (f.detail) console.log(`    ${f.detail}`);
    }
    console.log(
      `\n${files.length} files - ${errors.length} error(s), ${warnings.length} warning(s) - dump ${dump.version}`
    );
  }

  if (errors.length) process.exitCode = 1;
}

main();
