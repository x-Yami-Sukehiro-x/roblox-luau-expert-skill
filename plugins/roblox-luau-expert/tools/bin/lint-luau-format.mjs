#!/usr/bin/env node
// Count the formatting a Roblox Luau expert would not have shipped.
//
// StyLua is the real answer and this is not a replacement for it. It is what
// runs where StyLua does not: a custom GPT hands back a file in a chat window,
// nobody pipes it through a formatter, and the result reads as generated before
// a single rule about comments has been broken. The two complaints, in the
// user's words, are "clustered" and "putting things on new lines that doesn't
// need to have a new line" - which are opposite failures of the same missing
// standard, and both are countable.
//
// Every threshold below matches the stylua.toml this stack documents:
// column_width = 100, indent_type = Tabs, indent_width = 4. Every check runs
// clean on library/src, which is hand-written code this stack considers correct.
//
// Usage:
//   node tools/bin/lint-luau-format.mjs <file.luau> [more.luau ...]
//   node tools/bin/lint-luau-format.mjs <directory>
//   node tools/bin/lint-luau-format.mjs --json <file.luau>
//
// Exit 1 on any E-* finding. W-* are reported and do not fail.

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { REPO_ROOT } from "./lib/dump.mjs";

const COLUMN_WIDTH = 100;
const INDENT_WIDTH = 4;

// StyLua collapses a run of blank lines to one. Two is the point at which
// somebody was spacing by feel rather than by structure.
const MAX_BLANK_RUN = 1;

// A stretch of statements with no blank line anywhere in it is the "clustered"
// half of the complaint. Lines inside a table literal do not count: a flat
// table of 81 icons is data, and data is dense on purpose.
const MAX_DENSE_RUN = 35;

// A joined line at or under this width is one StyLua would have joined, so a
// break inside it was a choice nobody made on purpose.
const JOINABLE_WIDTH = COLUMN_WIDTH;

/** Blank the contents of strings and comments; keep the line structure. */
function mask(source) {
  const out = source.split("");
  let index = 0;
  const length = source.length;

  const blank = (from, to) => {
    for (let i = from; i < to && i < length; i += 1) {
      if (out[i] !== "\n") out[i] = " ";
    }
  };

  while (index < length) {
    const char = source[index];

    if (char === "-" && source[index + 1] === "-") {
      const bracket = /^\[(=*)\[/.exec(source.slice(index + 2, index + 12));
      if (bracket) {
        const closer = `]${bracket[1]}]`;
        const close = source.indexOf(closer, index + 2 + bracket[0].length);
        const stop = close === -1 ? length : close + closer.length;
        blank(index + 2, stop);
        index = stop;
        continue;
      }
      let stop = source.indexOf("\n", index);
      if (stop === -1) stop = length;
      blank(index + 2, stop);
      index = stop;
      continue;
    }

    if (char === '"' || char === "'") {
      let cursor = index + 1;
      while (cursor < length && source[cursor] !== char && source[cursor] !== "\n") {
        if (source[cursor] === "\\") cursor += 1;
        cursor += 1;
      }
      blank(index + 1, cursor);
      index = cursor + 1;
      continue;
    }

    const long = /^\[(=*)\[/.exec(source.slice(index, index + 10));
    if (long) {
      const closer = `]${long[1]}]`;
      const close = source.indexOf(closer, index + long[0].length);
      const stop = close === -1 ? length : close + closer.length;
      blank(index + long[0].length, stop - closer.length);
      index = stop;
      continue;
    }

    index += 1;
  }

  return out.join("");
}

/** Visual width, counting a tab as INDENT_WIDTH columns. */
function width(line) {
  let columns = 0;
  for (const char of line) columns += char === "\t" ? INDENT_WIDTH : 1;
  return columns;
}

function depthDelta(text) {
  let delta = 0;
  for (const char of text) {
    if (char === "(" || char === "[" || char === "{") delta += 1;
    else if (char === ")" || char === "]" || char === "}") delta -= 1;
  }
  return delta;
}

function analyse(rawSource, rel) {
  const findings = [];
  const add = (code, line, message) => findings.push({ code, line, message, file: rel });

  const source = rawSource.charCodeAt(0) === 0xfeff ? rawSource.slice(1) : rawSource;
  const raw = source.split(/\r?\n/);
  const masked = mask(source).split(/\r?\n/);

  // --- indentation --------------------------------------------------------
  let tabs = 0;
  let spaces = 0;
  for (const [index, line] of raw.entries()) {
    // A continuation line inside a doc comment aligns a numbered list with
    // tab-then-spaces, which is correct and is not indentation at all. Only a
    // line carrying code has the indent this rule is about.
    if (!(masked[index] ?? "").trim()) continue;
    const lead = /^[ 	]*/.exec(line)[0];
    if (!lead) continue;
    if (lead.includes("	")) tabs += 1;
    if (/^ {2,}/.test(lead)) spaces += 1;
    // A space before a tab is unambiguous: no editor setting renders it right.
    if (/ 	/.test(lead)) {
      add("E-MIXEDINDENT", index + 1, "a space before a tab in the indent - renders differently for every reader");
    }
  }
  if (tabs > 0 && spaces > 0) {
    add(
      "E-MIXEDINDENT",
      1,
      `${tabs} line(s) indent with tabs and ${spaces} with spaces - pick the one the file already uses`
    );
  }

  // --- per line -----------------------------------------------------------
  let blankRun = 0;
  let denseRun = 0;
  let denseStart = 0;
  let braceDepth = 0;

  for (const [index, line] of raw.entries()) {
    const number = index + 1;
    const maskedLine = masked[index] ?? "";

    if (!line.trim()) {
      blankRun += 1;
      if (blankRun === MAX_BLANK_RUN + 1) {
        add("E-BLANKRUN", number, `${MAX_BLANK_RUN + 1} blank lines in a row - one separates, more is spacing by feel`);
      }
      denseRun = 0;
      continue;
    }
    blankRun = 0;

    // Depth is measured before this line is counted, so the opening `{` of a
    // table is the last line counted and its contents are not.
    if (braceDepth > 0) {
      denseRun = 0;
    } else {
      if (denseRun === 0) denseStart = number;
      denseRun += 1;
    }
    braceDepth += (maskedLine.match(/\{/g) ?? []).length - (maskedLine.match(/\}/g) ?? []).length;
    if (braceDepth < 0) braceDepth = 0;
    if (denseRun === MAX_DENSE_RUN + 1) {
      add(
        "W-DENSE",
        denseStart,
        `${MAX_DENSE_RUN + 1} lines with no blank line since ${denseStart} - nothing marks where one idea ends`
      );
    }

    if (/[ \t]+$/.test(line)) {
      add("W-TRAILWS", number, "trailing whitespace");
    }

    // StyLua sets the width of code and never reflows a comment, so neither
    // does this. A wrapped sentence is the writer's business.
    if (maskedLine.trim() && width(line) > COLUMN_WIDTH) {
      add("W-WIDTH", number, `${width(line)} columns of code (column_width is ${COLUMN_WIDTH})`);
    }

    // A blank line immediately inside a block is padding, not structure.
    const previous = raw[index - 1];
    if (previous !== undefined && !previous.trim()) {
      const opener = masked[index - 2] ?? "";
      if (/\b(then|do|repeat)\s*$|[({[]\s*$|\bfunction\b[^)]*\)\s*$/.test(opener)) {
        add("E-BLANKEDGE", number - 1, "blank line directly after the line that opens the block");
      }
    }
    if (/^\s*(end|until|\}|\))[,;)]?\s*$/.test(line) && previous !== undefined && !previous.trim()) {
      add("E-BLANKEDGE", number - 1, "blank line directly before the line that closes the block");
    }

    if (/;\s*$/.test(maskedLine)) {
      add("W-SEMICOLON", number, "trailing semicolon - Luau does not need it and StyLua removes it");
    }

    for (const match of maskedLine.matchAll(/,(?=\S)/g)) {
      if (maskedLine[match.index + 1] === ")" || maskedLine[match.index + 1] === "}") continue;
      add("W-COMMA", number, "no space after a comma");
      break;
    }
    if (/[^,]\s+,/.test(maskedLine)) {
      add("W-COMMA", number, "space before a comma");
    }
  }

  // --- breaks that did not need to be breaks ------------------------------
  //
  // The half of the complaint that reads as "putting things on new lines that
  // doesn't need to have a new line". A construct opened and closed across
  // several lines whose joined form fits the column width is one StyLua would
  // have written on one line.
  for (let index = 0; index < raw.length; index += 1) {
    const maskedLine = masked[index] ?? "";
    const trimmed = maskedLine.trimEnd();
    if (!trimmed.trim()) continue;

    // Only an open bracket or a bare `=` at end of line starts one of these.
    if (!/[({[]\s*$|=\s*$/.test(trimmed)) continue;

    let depth = depthDelta(trimmed);
    if (depth < 0) continue;

    const parts = [raw[index].trim()];
    let cursor = index + 1;
    let closed = depth === 0 && /=\s*$/.test(trimmed);
    let tableLiteral = trimmed.includes("{");

    while (cursor < raw.length && cursor - index <= 12) {
      const next = masked[cursor] ?? "";
      if (!next.trim()) break;
      if (/^\s*--/.test(raw[cursor])) break;
      parts.push(raw[cursor].trim());
      depth += depthDelta(next);
      if (next.includes("{")) tableLiteral = true;
      if (depth <= 0) {
        closed = true;
        break;
      }
      cursor += 1;
    }

    if (!closed || parts.length < 2) continue;
    // StyLua keeps a table constructor expanded once it has a trailing comma,
    // and expanding a table is how a config block stays readable. Not a finding.
    if (tableLiteral) continue;
    if (parts.some((part) => /\b(function|then|do)\b/.test(part))) continue;

    const joined = parts.join(" ").replace(/\(\s+/g, "(").replace(/\s+\)/g, ")").replace(/\s+,/g, ",");
    const indent = /^[ \t]*/.exec(raw[index])[0];
    if (width(indent + joined) > JOINABLE_WIDTH) continue;

    add(
      "E-SPLIT",
      index + 1,
      `${parts.length} lines for ${width(indent + joined)} columns of code - it fits on one, so the breaks say nothing`
    );
    index = cursor;
  }

  if (!/\n$/.test(source)) {
    add("W-EOF", raw.length, "no newline at end of file");
  } else if (/\n\s*\n$/.test(source)) {
    add("W-EOF", raw.length, "blank line(s) at end of file");
  }

  const codeLines = raw.filter((line) => line.trim()).length;
  const longest = Math.max(0, ...raw.map(width));
  const counts = {
    lines: raw.length,
    codeLines,
    longestLine: longest,
    indent: tabs > 0 && spaces === 0 ? "tabs" : spaces > 0 && tabs === 0 ? "spaces" : "mixed",
  };

  return { findings, counts };
}

/** Four rows, two points each. */
function score(findings) {
  const has = (...codes) => findings.some((finding) => codes.includes(finding.code));
  const rows = [
    ["indentation", !has("E-MIXEDINDENT")],
    ["blank lines", !has("E-BLANKRUN", "E-BLANKEDGE", "W-DENSE")],
    ["breaks that earn their line", !has("E-SPLIT")],
    ["line hygiene", !has("W-WIDTH", "W-TRAILWS", "W-SEMICOLON", "W-COMMA", "W-EOF")],
  ];
  return { rows, points: rows.filter(([, ok]) => ok).length * 2, total: rows.length * 2 };
}

function collect(target, out = []) {
  if (statSync(target).isDirectory()) {
    for (const entry of readdirSync(target)) {
      if (entry === "node_modules" || entry === ".git") continue;
      collect(join(target, entry), out);
    }
  } else if (/\.luau?$/i.test(target)) {
    out.push(target);
  }
  return out;
}

function main() {
  const args = process.argv.slice(2);
  const asJson = args.includes("--json");
  const targets = args.filter((arg) => !arg.startsWith("--"));

  if (targets.length === 0) {
    console.error(
      "usage: node tools/bin/lint-luau-format.mjs <file.luau|directory> [...]\n" +
        "Counts the formatting rules in roblox-code-craft/references/formatting.md."
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

  const results = [];
  for (const file of files) {
    const inside = relative(REPO_ROOT, file).split(sep).join("/");
    const rel = inside.startsWith("..") ? file.split(/[/\\]/).pop() : inside;
    const { findings, counts } = analyse(readFileSync(file, "utf8"), rel);
    results.push({ file: rel, findings, counts, score: score(findings) });
  }

  if (asJson) {
    console.log(JSON.stringify({ results }, null, 2));
  } else {
    for (const result of results) {
      console.log(`\n${result.file}`);
      for (const finding of result.findings) {
        console.log(`  ${result.file}:${finding.line}  ${finding.code}  ${finding.message}`);
      }
      const failed = result.score.rows.filter(([, ok]) => !ok).map(([name]) => name);
      console.log(
        `  score ${result.score.points}/${result.score.total}` +
          (failed.length ? `  failing: ${failed.join(", ")}` : "  all counted checks pass") +
          `  (${result.counts.indent}, longest ${result.counts.longestLine})`
      );
    }
  }

  const errors = results.flatMap((r) => r.findings).filter((f) => f.code.startsWith("E-"));
  const warnings = results.flatMap((r) => r.findings).filter((f) => f.code.startsWith("W-"));
  if (!asJson) {
    console.log(`\n${files.length} file(s) - ${errors.length} error(s), ${warnings.length} warning(s)`);
  }
  if (errors.length > 0) process.exitCode = 1;
}

main();
