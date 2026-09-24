#!/usr/bin/env node
// Recompute every contrast ratio stated in design-directions.md.
//
// A palette written into prose is an unchecked claim. The v3 stack learned this
// the expensive way with API names; colour is the same problem with worse
// symptoms, because a failing ratio looks fine to whoever wrote it and is
// unreadable to somebody else.
//
// Checks, per direction:
//   1. Every stated ratio matches the recomputed one.
//   2. Primary text clears 4.5:1 on page, base, raised and overlay.
//   3. Secondary text clears 4.5:1 on base.
//   4. Muted text clears 3.0:1 on base - it is allowed to fail body-text AA,
//      it is not allowed to be invisible.
//   5. Text-on-accent clears 4.5:1.
//   6. The slot named as "Accent as text" clears 4.5:1 on base.
//   7. Adjacent surfaces differ by at least 1.12:1, so they read as separate.
//
// Usage:
//   node tools/bin/lint-ui-directions.mjs [--json]
//
// Exit 1 on any failure.

import { readFileSync, existsSync } from "node:fs";
import { relative } from "node:path";
import { contrast, parseRgb, AA_NORMAL, AA_LARGE } from "./lib/contrast.mjs";
import { REPO_ROOT } from "./lib/dump.mjs";
import { resolveSkillPath, missingSkillsMessage } from "./lib/skills.mjs";

const DOC = resolveSkillPath("roblox-ui", "references", "design-directions.md");

// A stated ratio and a recomputed one may differ by this much before it counts
// as wrong. Both are rounded to two places, so anything above half a unit in
// the last place is a real disagreement.
const TOLERANCE = 0.006;

const MIN_SURFACE_STEP = 1.12;

function parseDirections(text) {
  const directions = [];
  let current = null;

  for (const line of text.split(/\r?\n/)) {
    const heading = /^##\s+Palette:\s+(.+?)\s*$/.exec(line);
    if (heading) {
      current = { name: heading[1], slots: new Map(), claims: [], properties: new Map() };
      directions.push(current);
      continue;
    }
    if (/^##\s+/.test(line)) {
      current = null;
      continue;
    }
    if (!current) continue;

    // | `slot` | `r, g, b` | `other` | `1.23:1` |
    const row = /^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$/.exec(line);
    if (row) {
      const rgb = parseRgb(row[2]);
      if (rgb) {
        current.slots.set(row[1], rgb);
        const against = /`([^`]+)`/.exec(row[3]);
        const ratio = /(\d+\.\d+):1/.exec(row[4]);
        if (against && ratio) {
          current.claims.push({
            slot: row[1],
            against: against[1],
            stated: Number(ratio[1]),
          });
        }
      }
      continue;
    }

    // | Property | value |
    const prop = /^\|\s*([A-Za-z][A-Za-z ]+?)\s*\|\s*(.+?)\s*\|\s*$/.exec(line);
    if (prop) {
      current.properties.set(prop[1].trim(), prop[2].trim());
    }
  }

  return directions;
}

function slotFromProperty(direction, propertyName) {
  const raw = direction.properties.get(propertyName);
  if (!raw) return null;
  const m = /`([^`]+)`/.exec(raw);
  return m ? m[1] : null;
}

function main() {
  const asJson = process.argv.includes("--json");

  // install.ps1 puts tools/ and the skills in two different places, so say
  // where this looked rather than throwing ENOENT at whoever ran it.
  if (!DOC || !existsSync(DOC)) {
    console.error(missingSkillsMessage("roblox-ui/references/design-directions.md"));
    process.exit(2);
  }

  const text = readFileSync(DOC, "utf8");
  const directions = parseDirections(text);
  const findings = [];

  if (directions.length === 0) {
    console.error(`no "## Palette:" sections found in ${relative(REPO_ROOT, DOC)}`);
    process.exit(2);
  }

  for (const direction of directions) {
    const slot = (name) => direction.slots.get(name);
    const fail = (code, message) =>
      findings.push({ direction: direction.name, code, message });

    const required = [
      "neutral[0]", "neutral[1]", "neutral[2]", "neutral[3]", "neutral[4]",
      "neutral[5]", "neutral[6]", "neutral[7]", "neutral[8]",
      "accent.dim", "accent.base", "accent.bright",
    ];
    const missing = required.filter((name) => !slot(name));
    if (missing.length > 0) {
      fail("E-INCOMPLETE", `missing slots: ${missing.join(", ")}`);
      continue;
    }

    // 1. Stated ratios.
    for (const claim of direction.claims) {
      const a = slot(claim.slot);
      const b = slot(claim.against);
      if (!b) {
        fail("E-UNKNOWN-SLOT", `${claim.slot} is checked against ${claim.against}, which is not a slot`);
        continue;
      }
      const actual = contrast(a, b);
      if (Math.abs(actual - claim.stated) > TOLERANCE) {
        fail(
          "E-RATIO",
          `${claim.slot} on ${claim.against}: states ${claim.stated.toFixed(2)}:1, computes ${actual.toFixed(2)}:1`
        );
      }
    }

    // 2-3. Text legibility.
    const primary = slot("neutral[8]");
    for (const surface of ["neutral[0]", "neutral[2]", "neutral[3]", "neutral[4]"]) {
      const ratio = contrast(primary, slot(surface));
      if (ratio < AA_NORMAL) {
        fail("E-TEXT", `primary text on ${surface} is ${ratio.toFixed(2)}:1, below ${AA_NORMAL}:1`);
      }
    }

    const secondary = contrast(slot("neutral[6]"), slot("neutral[2]"));
    if (secondary < AA_NORMAL) {
      fail("E-TEXT", `secondary text on neutral[2] is ${secondary.toFixed(2)}:1, below ${AA_NORMAL}:1`);
    }

    // 4. Muted may fail body AA; it may not disappear.
    const muted = contrast(slot("neutral[5]"), slot("neutral[2]"));
    if (muted < AA_LARGE) {
      fail("E-MUTED", `muted text on neutral[2] is ${muted.toFixed(2)}:1, below ${AA_LARGE}:1`);
    }

    // 5. Text on the accent fill.
    const onAccentSlot = slotFromProperty(direction, "Text on accent");
    if (!onAccentSlot || !slot(onAccentSlot)) {
      fail("E-PROPERTY", `no usable "Text on accent" slot`);
    } else {
      const ratio = contrast(slot(onAccentSlot), slot("accent.base"));
      if (ratio < AA_NORMAL) {
        fail("E-ON-ACCENT", `${onAccentSlot} on accent.base is ${ratio.toFixed(2)}:1, below ${AA_NORMAL}:1`);
      }
    }

    // 6. The accent used AS text.
    const asTextSlot = slotFromProperty(direction, "Accent as text");
    if (!asTextSlot || !slot(asTextSlot)) {
      fail("E-PROPERTY", `no usable "Accent as text" slot`);
    } else {
      const ratio = contrast(slot(asTextSlot), slot("neutral[2]"));
      if (ratio < AA_NORMAL) {
        fail("E-ACCENT-TEXT", `${asTextSlot} as text on neutral[2] is ${ratio.toFixed(2)}:1, below ${AA_NORMAL}:1`);
      }
    }

    // 7. Surfaces have to separate.
    const steps = [
      ["neutral[0]", "neutral[2]"],
      ["neutral[2]", "neutral[3]"],
      ["neutral[3]", "neutral[4]"],
    ];
    for (const [from, to] of steps) {
      const ratio = contrast(slot(from), slot(to));
      if (ratio < MIN_SURFACE_STEP) {
        fail(
          "E-FLAT",
          `${from} and ${to} differ by only ${ratio.toFixed(2)}:1 - they will read as one surface`
        );
      }
    }
  }

  if (asJson) {
    console.log(JSON.stringify({ directions: directions.length, findings }, null, 2));
  } else {
    for (const finding of findings) {
      console.log(`${finding.direction}: ${finding.code}: ${finding.message}`);
    }
    console.log(
      `\n${directions.length} direction(s) - ${findings.length} finding(s)`
    );
  }

  process.exit(findings.length > 0 ? 1 : 0);
}

main();
