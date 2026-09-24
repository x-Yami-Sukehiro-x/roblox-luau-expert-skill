// Parser for the vendored Roblox API dump.
//
// The dump is the stack's ground truth. Everything that claims a Roblox API
// exists, is reachable, or is current resolves through here.
//
// Line shapes:
//   Class TweenService : Instance [NotCreatable] [Service]
//   <TAB>Function TweenService:Create(a: T, b: U) -> Tween {CAP}
//   <TAB>Property UIGradient.Color: ColorSequence {CAP}
//   <TAB>Event RunService.Heartbeat(dt: number) {CAP}
//   Enum GradientTileMode
//   <TAB>EnumItem GradientTileMode.Clamp : 0
//
// Annotations carry an emoji prefix that encodes which kind of gate applies.
// Conflating them produces wrong advice, so they are decoded separately:
//
//   U+1F512 padlock    security on read AND write
//   U+1F50D magnifier  security on read only
//   U+270F  pencil     security on write only
//   U+1F6A7 barrier    script capability a sandboxed container must grant
//   U+1F9EC dna        parallel-Luau safety (Safe / Unsafe)
//   U+1F680 rocket     simulation access
//   U+1F4C1 folder     LoadOnly - settable at load time, not at runtime

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
export const REPO_ROOT = join(HERE, "..", "..", "..");
export const DUMP_DIR = join(REPO_ROOT, "tools", "api-dump");

const LOCK_BOTH = "\u{1F512}";
const LOCK_READ = "\u{1F50D}";
const LOCK_WRITE = "\u{270F}";
const CAPABILITY = "\u{1F6A7}";
const PARALLEL = "\u{1F9EC}";
const SIM_ACCESS = "\u{1F680}";

// Security levels that mean no ordinary Script or LocalScript can reach this.
export const UNREACHABLE_SECURITY = new Set([
  "RobloxScript",
  "RobloxEngine",
  "Plugin",
  "LocalUser",
  "NotAccessible",
  "PluginOrOpenCloud",
]);

export const SECURITY_NOTES = {
  RobloxScript: "CoreScript only. A normal Script or LocalScript cannot touch this.",
  RobloxEngine: "Engine internal. Unreachable from any user script.",
  Plugin: "Plugin and command bar only. Not available at runtime in a live game.",
  PluginOrOpenCloud: "Plugin or Open Cloud only. Not available to a runtime game script.",
  LocalUser: "Elevated local context only. Not available to a normal LocalScript.",
  NotAccessible: "Not reachable from Luau at all.",
};

// Members that are two names for the same thing. Describing them as distinct
// engine features is a factual error, so the linter needs to know the pairs.
export const ALIASES = [
  ["RunService.Stepped", "RunService.PreSimulation"],
  ["RunService.RenderStepped", "RunService.PreRender"],
  ["RunService.Heartbeat", "RunService.PostSimulation"],
];

function stripBrackets(text) {
  const out = [];
  const re = /\[([^\]]+)\]/gu;
  let m;
  while ((m = re.exec(text)) !== null) {
    const cleaned = m[1].replace(/[^\x20-\x7E]/gu, "").trim();
    if (cleaned) out.push(cleaned);
  }
  return out;
}

function parseAnnotations(text) {
  const result = {
    security: null,
    readSecurity: null,
    writeSecurity: null,
    capabilities: [],
    parallel: null,
    simAccess: false,
  };

  const re = /\{([^}]+)\}/gu;
  let m;
  while ((m = re.exec(text)) !== null) {
    const raw = m[1];
    const marker = [...raw][0];
    const value = raw.replace(/[^\x20-\x7E]/gu, "").trim();
    if (!value) continue;

    if (marker === LOCK_BOTH) {
      result.security = value;
    } else if (marker === LOCK_READ) {
      result.readSecurity = value;
    } else if (marker === LOCK_WRITE) {
      result.writeSecurity = value;
    } else if (marker === CAPABILITY) {
      result.capabilities.push(
        ...value.split("+").map((s) => s.trim()).filter(Boolean)
      );
    } else if (marker === PARALLEL) {
      result.parallel = value;
    } else if (marker === SIM_ACCESS) {
      result.simAccess = true;
    }
  }
  return result;
}

let cached = null;

export function loadDump() {
  if (cached) return cached;

  const dumpPath = join(DUMP_DIR, "API-Dump.txt");
  let text;
  try {
    text = readFileSync(dumpPath, "utf8");
  } catch {
    throw new Error(
      `API dump not found at ${dumpPath}. Run: node tools/bin/update-dump.mjs`
    );
  }

  let version = "unknown";
  try {
    version = readFileSync(join(DUMP_DIR, "version.txt"), "utf8").trim();
  } catch {
    // version.txt is optional
  }

  const classes = new Map();
  const enums = new Map();
  const memberIndex = new Map();
  const bareMembers = new Map();

  let currentClass = null;
  let currentEnum = null;

  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (!line.trim()) continue;

    const lineNumber = i + 1;
    const indented = /^[\t ]/u.test(line);
    const body = line.trim();

    if (!indented) {
      let m = /^Class\s+([A-Za-z0-9_]+)(?:\s*:\s*([A-Za-z0-9_]+))?/u.exec(body);
      if (m) {
        currentEnum = null;
        currentClass = {
          name: m[1],
          superclass: m[2] ?? null,
          tags: stripBrackets(body),
          members: new Map(),
          line: lineNumber,
        };
        classes.set(currentClass.name, currentClass);
        continue;
      }
      m = /^Enum\s+([A-Za-z0-9_]+)/u.exec(body);
      if (m) {
        currentClass = null;
        currentEnum = { name: m[1], items: new Map(), line: lineNumber };
        enums.set(currentEnum.name, currentEnum);
        continue;
      }
      currentClass = null;
      currentEnum = null;
      continue;
    }

    if (currentEnum) {
      const m = /^EnumItem\s+[A-Za-z0-9_]+\.([A-Za-z0-9_]+)\s*:\s*(-?\d+)/u.exec(body);
      if (m) currentEnum.items.set(m[1], Number(m[2]));
      continue;
    }

    if (!currentClass) continue;

    // Member names are not all identifiers. Properties can carry spaces,
    // hyphens and parentheses - "Studio.Auto-Recovery Interval (Minutes)",
    // "PVInstance.Pivot Offset", "BevelMesh.Bevel Roundness" - so a \w+ capture
    // silently truncates them and collapses distinct members onto one key.
    // Properties end at the type separator; the callable kinds end at "(".
    let kind;
    let owner;
    let member;

    const prop = /^Property\s+([A-Za-z0-9_]+)\.(.*)\s*:\s*([^:]*)$/u.exec(body);
    if (prop) {
      kind = "Property";
      owner = prop[1];
      member = prop[2].trim();
    } else {
      const call = /^(Function|Event|Callback)\s+([A-Za-z0-9_]+)[.:]([^(]+?)\s*\(/u.exec(body);
      if (!call) continue;
      kind = call[1];
      owner = call[2];
      member = call[3].trim();
    }
    if (!member) continue;
    const tags = stripBrackets(body);
    const record = {
      kind,
      owner,
      name: member,
      qualified: `${owner}.${member}`,
      signature: body,
      tags,
      deprecated: tags.includes("Deprecated"),
      yields: tags.includes("Yields"),
      readOnly: tags.includes("ReadOnly"),
      notScriptable: tags.includes("NotScriptable"),
      hidden: tags.includes("Hidden"),
      notReplicated: tags.includes("NotReplicated"),
      loadOnly: tags.includes("LoadOnly"),
      annotations: parseAnnotations(body),
      line: lineNumber,
    };

    currentClass.members.set(member, record);
    memberIndex.set(record.qualified, record);
    if (!bareMembers.has(member)) bareMembers.set(member, []);
    bareMembers.get(member).push(record);
  }

  cached = { version, classes, enums, memberIndex, bareMembers };
  return cached;
}

// Walk the inheritance chain so GuiObject members resolve on Frame.
export function resolveMember(className, memberName) {
  const { classes } = loadDump();
  let cursor = classes.get(className);
  const seen = new Set();
  while (cursor && !seen.has(cursor.name)) {
    seen.add(cursor.name);
    const hit = cursor.members.get(memberName);
    if (hit) return hit;
    cursor = cursor.superclass ? classes.get(cursor.superclass) : null;
  }
  return null;
}

// Non-null when no ordinary Script or LocalScript can call or read this.
export function isUnreachable(record) {
  const a = record.annotations;
  if (a.security && UNREACHABLE_SECURITY.has(a.security)) return a.security;
  if (a.readSecurity && UNREACHABLE_SECURITY.has(a.readSecurity)) return a.readSecurity;
  return null;
}

// Non-null when a normal script may read it but not write it.
export function isWriteGated(record) {
  const a = record.annotations;
  if (a.writeSecurity && UNREACHABLE_SECURITY.has(a.writeSecurity)) return a.writeSecurity;
  if (a.security && UNREACHABLE_SECURITY.has(a.security)) return a.security;
  return null;
}

// Why a property cannot be assigned from a running script, or null if it can.
//
// [LoadOnly] is deliberately NOT treated as a blocker. It is a *serialization*
// flag - the property is read from the file format but not written back - and
// says nothing about scriptability. Instance.Parent carries it, and Parent is
// the most-assigned property in the engine. Reading it as "cannot be set at
// runtime" produces confident, wrong advice about IgnoreGuiInset,
// UICorner.CornerRadius, TextLabel.Font and 170 others.
export function assignmentBlocker(record) {
  if (record.kind !== "Property") return null;
  if (record.readOnly) return "[ReadOnly]";
  if (record.notScriptable) return "[NotScriptable]";
  const gate = isWriteGated(record);
  if (gate) return `write gated to ${gate}`;
  return null;
}

// [LoadOnly] almost always marks a legacy property kept for file compatibility
// and superseded by a newer one. It is still assignable; it is just not the
// surface you should be writing against.
export function isLegacySerialised(record) {
  return record.kind === "Property" && record.loadOnly;
}

// Drop emoji prefixes so terminal output survives any console codepage.
export function formatSignature(text) {
  return text
    .replace(/[^\x00-\x7F]/gu, "")
    .replace(/\{\s+/gu, "{")
    .replace(/\s+/gu, " ")
    .trim();
}

// --- Datatypes ---------------------------------------------------------------
//
// The API dump covers classes and enums and nothing else. CFrame, Vector3,
// TweenInfo, RaycastParams and SharedTable are *datatypes*, so a claim about
// them cannot be checked against API-Dump.txt at all. The v2.1 corpus asserted
// "verbatim from the vendored dump" for RaycastParams properties that the dump
// does not contain, which is how that gap surfaced.
//
// Roblox publishes the datatype reference as YAML in creator-docs. Those files
// are vendored alongside the dump so datatype claims have ground truth too.
//
// Only the member names are parsed. That is what verification needs, and it
// avoids taking a YAML dependency for a file shape this regular.

import { readdirSync } from "node:fs";

let datatypeCache = null;

export function loadDatatypes() {
  if (datatypeCache) return datatypeCache;

  const dir = join(DUMP_DIR, "datatypes");
  const datatypes = new Map();
  let files = [];
  try {
    files = readdirSync(dir).filter((f) => f.endsWith(".yaml"));
  } catch {
    return (datatypeCache = datatypes);
  }

  for (const file of files) {
    const text = readFileSync(join(dir, file), "utf8");
    const name = /^name:\s*(\S+)/m.exec(text)?.[1] ?? file.replace(/\.yaml$/, "");
    const members = new Map();
    let section = null;

    for (const line of text.split(/\r?\n/)) {
      const top = /^([a-z_]+):\s*$/.exec(line);
      if (top) {
        section = top[1];
        continue;
      }
      if (/^[a-z_]+:/.test(line)) {
        section = null;
        continue;
      }
      // Member entries sit at exactly two spaces; parameters are deeper.
      const member = /^ {2}- name:\s*(\S+)\s*$/.exec(line);
      if (!member || !section) continue;
      const raw = member[1];
      const short = raw.includes(".") || raw.includes(":")
        ? raw.split(/[.:]/).slice(1).join(".")
        : raw;
      members.set(short, { kind: section, qualified: raw, owner: name, name: short });
    }
    datatypes.set(name, { name, members });
  }

  return (datatypeCache = datatypes);
}

export function resolveDatatypeMember(typeName, memberName) {
  const dt = loadDatatypes().get(typeName);
  if (!dt) return null;
  return dt.members.get(memberName) ?? null;
}
