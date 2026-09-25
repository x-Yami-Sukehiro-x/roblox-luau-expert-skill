#!/usr/bin/env node
// Remember what was tried, and refuse to try it again.
//
// A repair that fails in chat is forgotten by the next chat, and often by the
// next reply: the model reaches for the same plausible approach, the user sees
// the same failure, and says "you didn't fix it". The ledger is the Attempts
// section of the project's PROJECT_CONTEXT.md, written in a fixed shape so a
// tool can read it back:
//
//   ### A3 failed: fly jitters for other players
//   - Tried: set HumanoidRootPart.CFrame every RenderStepped
//   - Saw: others see stutter; the server snapped the character back
//   - Instead: LinearVelocity and AlignOrientation (assets/fly.luau)
//   - Avoid: `\.CFrame\s*=.*RenderStepped`
//
// The stack's own entries, roblox-attempt-memory/references/known-failures.md,
// are read the same way and apply to every project.
//
// Usage:
//   node tools/bin/attempt-ledger.mjs check <file.luau> [...]     recorded mistakes back in the code
//   node tools/bin/attempt-ledger.mjs plan "<approach>"            does this repeat a failed attempt?
//   node tools/bin/attempt-ledger.mjs search <words...>            entries about a symptom
//   node tools/bin/attempt-ledger.mjs lint                         format errors and repeated attempts
//   node tools/bin/attempt-ledger.mjs add --status failed --title "..." --tried "..." --saw "..." [...]
//
//   --ledger <PROJECT_CONTEXT.md>   use this file instead of searching upward
//   --no-builtin                    leave out the stack's known failures
//
// Exit 1 when check finds a recorded mistake, plan finds a repeat, or lint
// finds an error. Exit 2 on bad usage.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join, resolve, relative } from "node:path";
import { resolveSkillPath } from "./lib/skills.mjs";

const LEDGER_NAME = "PROJECT_CONTEXT.md";
const BUILTIN = ["roblox-attempt-memory", "references", "known-failures.md"];
const STATUSES = new Set(["failed", "rejected", "fixed", "works", "open"]);
// A failed or rejected approach must not come back; a fixed bug must not return.
const GUARDED = new Set(["failed", "rejected", "fixed"]);
const FIELDS = ["tried", "saw", "cause", "instead", "never", "avoid", "unless", "check", "date"];
const HEADING = /^###\s+([A-Z]+\d+)\s+([a-z]+):\s*(.+?)\s*$/;
const FIELD = /^-\s+([A-Za-z]+):\s*(.*)$/;
const REPEAT_OVERLAP = 0.6;
const REPEAT_SHARED = 3;

const STOPWORDS = new Set(
  (
    "the a an and or but to of in on at for with by from into onto it its this that these those is are was were " +
    "be been being do does did done not no so then than too very can could should would will just also only " +
    "when while each every all any some one two use used using make made set sets via per after before again"
  ).split(" ")
);

/**
 * Words that carry meaning, keyed by a crude stem so "writes" meets "write".
 * The value is the first spelling seen, for printing.
 */
export function tokens(text) {
  const out = new Map();
  for (const word of String(text).toLowerCase().match(/[a-z][a-z0-9_]*/g) ?? []) {
    if (word.length < 3 || STOPWORDS.has(word)) continue;
    const stem = /(ss|eed)$/.test(word) ? word : word.replace(/(ing|ed|es|s)$/, "");
    const key = stem.length >= 3 ? stem : word;
    if (!out.has(key)) out.set(key, word);
  }
  return out;
}

function overlap(a, b) {
  const shared = [...a.keys()].filter((stem) => b.has(stem)).map((stem) => a.get(stem));
  const smaller = Math.min(a.size, b.size);
  return { shared, ratio: smaller === 0 ? 0 : shared.length / smaller };
}

/** Backtick-quoted patterns on a field line. */
function patterns(value) {
  return [...String(value ?? "").matchAll(/`([^`]+)`/g)].map((m) => m[1]);
}

export function parseLedger(text, source) {
  const entries = [];
  const problems = [];
  let current = null;
  text.split(/\r?\n/).forEach((line, index) => {
    const heading = HEADING.exec(line);
    if (heading) {
      current = { id: heading[1], status: heading[2], title: heading[3], line: index + 1, source, fields: {} };
      entries.push(current);
      if (!STATUSES.has(current.status)) {
        problems.push({ entry: current, message: `status "${current.status}" is not one of ${[...STATUSES].join(", ")}` });
      }
      return;
    }
    if (/^#{1,3}\s/.test(line)) {
      current = null;
      return;
    }
    const field = current && FIELD.exec(line);
    if (field) {
      const key = field[1].toLowerCase();
      if (!FIELDS.includes(key)) {
        problems.push({ entry: current, message: `unknown field "${field[1]}"` });
        return;
      }
      current.fields[key] = current.fields[key] ? `${current.fields[key]} ${field[2]}` : field[2];
    }
  });
  return { entries, problems };
}

/** The nearest PROJECT_CONTEXT.md at or above a directory. */
function findLedger(start) {
  let dir = resolve(start);
  for (;;) {
    const candidate = join(dir, LEDGER_NAME);
    if (existsSync(candidate)) return candidate;
    const parent = dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function load(options, startDir) {
  const files = [];
  const project = options.ledger ?? findLedger(startDir);
  if (options.ledger && !existsSync(options.ledger)) {
    console.error(`no ledger at ${options.ledger}`);
    process.exit(2);
  }
  if (project) files.push(project);
  if (options.builtin) {
    const builtin = resolveSkillPath(...BUILTIN);
    if (builtin) files.push(builtin);
  }
  const entries = [];
  const problems = [];
  for (const file of files) {
    const parsed = parseLedger(readFileSync(file, "utf8"), file);
    entries.push(...parsed.entries);
    problems.push(...parsed.problems);
  }
  return { files, entries, problems, project };
}

const where = (entry) => `${relative(process.cwd(), entry.source).split("\\").join("/")}:${entry.line}`;
const advice = (entry) => entry.fields.never || entry.fields.instead || entry.fields.cause || "";

/** Luau comments blanked out, line numbers kept. */
function stripComments(source) {
  return source
    .replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, (block) => block.replace(/[^\n]/g, " "))
    .replace(/--[^\n]*/g, "");
}

function check(files, options) {
  let hits = 0;
  for (const file of files) {
    if (!existsSync(file)) {
      console.error(`no such file: ${file}`);
      process.exit(2);
    }
    const { entries } = load(options, dirname(resolve(file)));
    const raw = readFileSync(file, "utf8");
    const code = stripComments(raw);
    const lines = code.split(/\r?\n/);
    for (const entry of entries) {
      if (!GUARDED.has(entry.status)) continue;
      const unless = patterns(entry.fields.unless);
      if (unless.some((pattern) => new RegExp(pattern).test(code))) continue;
      for (const pattern of patterns(entry.fields.avoid)) {
        const regex = new RegExp(pattern);
        lines.forEach((line, index) => {
          if (!regex.test(line)) return;
          hits += 1;
          console.log(`${file}:${index + 1}  ${entry.id} ${entry.status}: ${entry.title}`);
          if (advice(entry)) console.log(`    ${advice(entry)}`);
        });
      }
    }
  }
  console.log(hits === 0 ? "no recorded mistake found" : `${hits} recorded mistake(s) found`);
  return hits === 0 ? 0 : 1;
}

function repeatsOf(entries, approach) {
  const wanted = tokens(approach);
  const repeats = [];
  for (const entry of entries) {
    if (entry.status !== "failed" && entry.status !== "rejected") continue;
    const { shared, ratio } = overlap(wanted, tokens(entry.fields.tried ?? entry.title));
    if (shared.length >= REPEAT_SHARED && ratio >= REPEAT_OVERLAP) repeats.push({ entry, shared, ratio });
  }
  return repeats.sort((a, b) => b.ratio - a.ratio);
}

function printRepeats(repeats) {
  for (const { entry, shared } of repeats) {
    console.log(`REPEAT ${entry.id} ${entry.status}: ${entry.title}  (${where(entry)})`);
    console.log(`    tried: ${entry.fields.tried ?? ""}`);
    if (entry.fields.saw) console.log(`    saw: ${entry.fields.saw}`);
    if (entry.fields.instead) console.log(`    instead: ${entry.fields.instead}`);
    console.log(`    shared: ${shared.join(", ")}`);
  }
}

function plan(approach, options) {
  const { entries } = load(options, process.cwd());
  const repeats = repeatsOf(entries, approach);
  printRepeats(repeats);
  console.log(
    repeats.length === 0
      ? "no failed attempt matches this approach"
      : `${repeats.length} failed attempt(s) match - change the approach or state what is different this time`
  );
  return repeats.length === 0 ? 0 : 1;
}

function search(words, options) {
  const { entries } = load(options, process.cwd());
  const wanted = tokens(words.join(" "));
  const ranked = entries
    .map((entry) => {
      const text = [entry.title, entry.fields.tried, entry.fields.saw, entry.fields.cause].join(" ");
      const found = tokens(text);
      return { entry, score: [...wanted.keys()].filter((stem) => found.has(stem)).length };
    })
    .filter((row) => row.score > 0)
    .sort((a, b) => b.score - a.score || a.entry.id.localeCompare(b.entry.id))
    .slice(0, 5);
  for (const { entry } of ranked) {
    console.log(`${entry.id} ${entry.status}: ${entry.title}  (${where(entry)})`);
    for (const key of ["tried", "saw", "instead", "never"]) {
      if (entry.fields[key]) console.log(`    ${key}: ${entry.fields[key]}`);
    }
  }
  console.log(ranked.length === 0 ? "no entry mentions these words" : `${ranked.length} entr${ranked.length === 1 ? "y" : "ies"}`);
  return 0;
}

function lint(options) {
  const { files, entries, problems } = load(options, process.cwd());
  if (files.length === 0) {
    console.log(`no ${LEDGER_NAME} found at or above ${process.cwd()}`);
    return 0;
  }
  const errors = problems.map(({ entry, message }) => `${where(entry)}  ${entry.id}  ${message}`);
  const seen = new Map();
  for (const entry of entries) {
    const key = `${entry.source}#${entry.id}`;
    if (seen.has(key)) errors.push(`${where(entry)}  ${entry.id}  duplicate id (first at line ${seen.get(key)})`);
    seen.set(key, entry.line);
    if ((entry.status === "failed" || entry.status === "rejected") && (!entry.fields.tried || !entry.fields.saw)) {
      errors.push(`${where(entry)}  ${entry.id}  a ${entry.status} entry needs Tried and Saw`);
    }
    if (entry.status === "fixed" && !entry.fields.avoid && !entry.fields.check) {
      errors.push(`${where(entry)}  ${entry.id}  a fixed entry needs Avoid or Check, or the bug can come back unnoticed`);
    }
    for (const pattern of [...patterns(entry.fields.avoid), ...patterns(entry.fields.unless)]) {
      try {
        new RegExp(pattern);
      } catch {
        errors.push(`${where(entry)}  ${entry.id}  pattern does not compile: ${pattern}`);
      }
    }
  }
  const failed = entries.filter((entry) => entry.status === "failed" && entry.fields.tried);
  for (let i = 0; i < failed.length; i += 1) {
    for (let j = i + 1; j < failed.length; j += 1) {
      const { shared, ratio } = overlap(tokens(failed[i].fields.tried), tokens(failed[j].fields.tried));
      if (shared.length >= REPEAT_SHARED && ratio >= REPEAT_OVERLAP) {
        errors.push(`${where(failed[j])}  ${failed[j].id}  repeats ${failed[i].id}: the same approach failed twice (${shared.join(", ")})`);
      }
    }
  }
  for (const error of errors) console.log(error);
  console.log(`${entries.length} entr${entries.length === 1 ? "y" : "ies"} in ${files.length} file(s) - ${errors.length} problem(s)`);
  return errors.length === 0 ? 0 : 1;
}

function add(options) {
  const status = options.values.status;
  const title = options.values.title;
  if (!STATUSES.has(status) || !title) {
    console.error(`add needs --status (${[...STATUSES].join(", ")}) and --title`);
    process.exit(2);
  }
  const file = options.ledger ?? findLedger(process.cwd()) ?? join(process.cwd(), LEDGER_NAME);
  let text = existsSync(file) ? readFileSync(file, "utf8") : `# Project context\n`;
  const { entries } = parseLedger(text, file);
  const next = entries.reduce((high, entry) => Math.max(high, Number(entry.id.replace(/\D/g, "")) || 0), 0) + 1;
  const lines = [`### A${next} ${status}: ${title}`];
  for (const key of FIELDS) {
    if (key === "date") continue;
    const value = options.values[key];
    if (value) lines.push(`- ${key[0].toUpperCase()}${key.slice(1)}: ${value}`);
  }
  lines.push(`- Date: ${options.values.date ?? new Date().toISOString().slice(0, 10)}`);
  if (!/^## Attempts\s*$/m.test(text)) text = `${text.trimEnd()}\n\n## Attempts\n`;
  text = `${text.trimEnd()}\n\n${lines.join("\n")}\n`;
  const repeats = status === "failed" && options.values.tried ? repeatsOf(entries, options.values.tried) : [];
  writeFileSync(file, text, "utf8");
  console.log(`added A${next} to ${relative(process.cwd(), file) || LEDGER_NAME}`);
  if (repeats.length > 0) {
    printRepeats(repeats);
    console.log(`A${next} repeats ${repeats.map((row) => row.entry.id).join(", ")} - record what differs, or stop retrying it`);
  }
  return 0;
}

function parseArgs(argv) {
  const options = { builtin: true, ledger: null, values: {}, rest: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--no-builtin") options.builtin = false;
    else if (arg === "--ledger") options.ledger = argv[++i];
    else if (arg.startsWith("--")) {
      const key = arg.slice(2);
      const value = argv[++i] ?? "";
      options.values[key] = key === "avoid" && options.values.avoid ? `${options.values.avoid} ${value}` : value;
    } else options.rest.push(arg);
  }
  return options;
}

function main() {
  const [command, ...argv] = process.argv.slice(2);
  const options = parseArgs(argv);
  const usage = "usage: attempt-ledger.mjs check <file...> | plan \"<approach>\" | search <words...> | lint | add --status <s> --title <t> [...]";
  let code;
  if (command === "check" && options.rest.length > 0) code = check(options.rest, options);
  else if (command === "plan" && options.rest.length > 0) code = plan(options.rest.join(" "), options);
  else if (command === "search" && options.rest.length > 0) code = search(options.rest, options);
  else if (command === "lint") code = lint(options);
  else if (command === "add") code = add(options);
  else {
    console.error(usage);
    process.exit(2);
  }
  process.exitCode = code;
}

main();
