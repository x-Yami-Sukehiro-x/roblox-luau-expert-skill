#!/usr/bin/env node
// Resolve a Roblox API name against the vendored dump.
//
// Two questions, both answered here: does this exist, and can the script I am
// about to write actually touch it. Exit code 1 means the name is absent from
// the dump - treat that as "you were about to invent an API" and stop.
//
// Usage:
//   node tools/bin/verify-api.mjs GuiService.TopbarInset
//   node tools/bin/verify-api.mjs SmoothDamp             substring search
//   node tools/bin/verify-api.mjs UIShadow --members      list a class
//   node tools/bin/verify-api.mjs Enum.GradientType       enum items
//   node tools/bin/verify-api.mjs TopbarInset --exact
//
// Exit codes: 0 found, 1 not found, 2 dump missing.

import {
  loadDump,
  loadDatatypes,
  resolveDatatypeMember,
  resolveMember,
  isUnreachable,
  isWriteGated,
  assignmentBlocker,
  isLegacySerialised,
  formatSignature,
  SECURITY_NOTES,
} from "./lib/dump.mjs";

// Where an obsolete name should send you. The dump records [Deprecated] but
// rarely the replacement, and the replacement is the useful half.
const REPLACEMENTS = {
  Remove: "Instance:Destroy",
  BodyVelocity: "LinearVelocity",
  BodyAngularVelocity: "AngularVelocity",
  BodyPosition: "AlignPosition",
  BodyGyro: "AlignOrientation",
  BodyForce: "VectorForce",
  BodyThrust: "VectorForce",
  RocketPropulsion: "LinearVelocity plus AlignOrientation",
  FindPartOnRay: "WorldRoot:Raycast",
  FindPartOnRayWithIgnoreList: "WorldRoot:Raycast with RaycastParams.FilterDescendantsInstances",
  FindPartOnRayWithWhitelist: "WorldRoot:Raycast with RaycastParams.FilterType = Include",
  FindPartsInRegion3: "WorldRoot:GetPartBoundsInBox",
  FindPartsInRegion3WithIgnoreList: "WorldRoot:GetPartBoundsInBox with OverlapParams",
  FindPartsInRegion3WithWhiteList: "WorldRoot:GetPartBoundsInBox with OverlapParams",
  Stepped: "RunService.PreSimulation (the same point, not a deprecation)",
  RenderStepped: "RunService.PreRender (the same point, not a deprecation)",
  Heartbeat: "RunService.PostSimulation (the same point, not a deprecation)",
  Chat: "TextChatService",
  LoadCharacterBlocking: "Player:LoadCharacter",
  GetGlobalDataStore: "DataStoreService:GetDataStore with an explicit name",
  FilteringEnabled: "always on now; the property is inert",
  CreateHumanoidModelFromDescription: "Players:CreateHumanoidModelFromDescriptionAsync",
  CreateDockWidgetPluginGui: "Plugin:CreateDockWidgetPluginGuiAsync",
  PlayerOwnsAsset: "MarketplaceService:UserOwnsGamePassAsync for passes",
  TeleportToPlaceInstance: "TeleportService:TeleportAsync with TeleportOptions",
  TeleportToSpawnByName: "TeleportService:TeleportAsync with TeleportOptions",
  CornerRadius: "UICorner TopLeftRadius / TopRightRadius / BottomLeftRadius / BottomRightRadius",
  IgnoreGuiInset: "ScreenGui.ScreenInsets - both work; ScreenInsets is the current surface",
  SafeZoneOffsetsChanged: "GuiService:GetPropertyChangedSignal(\"TopbarInset\")",
};

function describe(record, indent = "  ") {
  const out = [];
  out.push(`${indent}${formatSignature(record.signature)}`);

  const gate = isUnreachable(record);
  if (gate) {
    out.push(`${indent}  SECURITY ${gate} - ${SECURITY_NOTES[gate] ?? "not reachable from a normal script"}`);
  } else {
    const write = isWriteGated(record);
    if (write) {
      out.push(`${indent}  SECURITY readable by any script; WRITES require ${write}`);
    }
  }

  const blocker = assignmentBlocker(record);
  if (blocker) out.push(`${indent}  NOT ASSIGNABLE at runtime: ${blocker}`);

  if (isLegacySerialised(record)) {
    out.push(
      `${indent}  [LoadOnly] - a serialization flag, NOT a scriptability one. Still` +
      `
${indent}             assignable at runtime; usually a legacy property kept for` +
      `
${indent}             file compatibility and superseded by a newer one.`
    );
  }

  if (record.deprecated) {
    const replacement = REPLACEMENTS[record.name];
    out.push(`${indent}  DEPRECATED${replacement ? ` - use ${replacement}` : ""}`);
  }
  if (record.yields) out.push(`${indent}  YIELDS - re-validate anything you captured before the call`);

  const a = record.annotations;
  if (a.parallel) out.push(`${indent}  PARALLEL ${a.parallel}`);
  if (a.capabilities.length) out.push(`${indent}  CAPABILITY ${a.capabilities.join(" + ")}`);

  const extra = record.tags.filter((t) =>
    ["Hidden", "NotReplicated", "NotBrowsable", "CustomLuaState"].includes(t)
  );
  if (extra.length) out.push(`${indent}  FLAGS ${extra.join(" ")}`);

  return out.join("\n");
}

function main() {
  const args = process.argv.slice(2);
  const flags = new Set(args.filter((a) => a.startsWith("--")));
  const query = args.filter((a) => !a.startsWith("--"))[0];

  if (!query) {
    console.error("usage: node tools/bin/verify-api.mjs <Class.Member | Class | Enum.Name | substring> [--members] [--exact]");
    process.exit(2);
  }

  let dump;
  try {
    dump = loadDump();
  } catch (e) {
    console.error(String(e.message));
    process.exit(2);
  }

  let found = false;

  // Enum.Name or Enum.Name.Item
  const enumMatch = /^Enum\.([A-Za-z0-9_]+)(?:\.([A-Za-z0-9_]+))?$/.exec(query);
  if (enumMatch) {
    const e = dump.enums.get(enumMatch[1]);
    if (!e) {
      console.log(`Enum.${enumMatch[1]}  NOT FOUND in the Roblox API dump.`);
      process.exit(1);
    }
    if (enumMatch[2]) {
      if (!e.items.has(enumMatch[2])) {
        console.log(`Enum.${enumMatch[1]} has no item ${enumMatch[2]}.`);
        console.log(`  items: ${[...e.items.keys()].join(", ")}`);
        process.exit(1);
      }
      console.log(`Enum.${enumMatch[1]}.${enumMatch[2]} = ${e.items.get(enumMatch[2])}`);
      process.exit(0);
    }
    console.log(`Enum ${enumMatch[1]}`);
    for (const [k, v] of e.items) console.log(`  ${k} = ${v}`);
    process.exit(0);
  }

  // Class.Member or Class:Method
  const qualified = /^([A-Za-z0-9_]+)[.:]([A-Za-z0-9_]+)$/.exec(query);
  if (qualified) {
    const rec = resolveMember(qualified[1], qualified[2]);
    if (rec) {
      const via = rec.owner === qualified[1] ? "" : `  (inherited from ${rec.owner})`;
      console.log(`${qualified[1]}.${qualified[2]}${via}`);
      console.log(describe(rec));
      process.exit(0);
    }
    // Datatypes are not in the dump at all - CFrame, TweenInfo, RaycastParams
    // and SharedTable live in the vendored creator-docs datatype reference.
    const dtHit = resolveDatatypeMember(qualified[1], qualified[2]);
    if (dtHit) {
      console.log(`${dtHit.qualified}   (datatype ${dtHit.owner}, ${dtHit.kind})`);
      console.log("  source: tools/api-dump/datatypes - the API dump does not cover datatypes");
      process.exit(0);
    }
    const dt = loadDatatypes().get(qualified[1]);
    if (dt) {
      console.log(`${qualified[1]} is a datatype, but has no member ${qualified[2]}.`);
      console.log(`  members: ${[...dt.members.keys()].join(", ")}`);
      process.exit(1);
    }
    if (dump.classes.has(qualified[1])) {
      console.log(`${qualified[1]} exists, but has no member ${qualified[2]}.`);
      console.log(`  (a child instance of that name is a different thing - the dump only knows API members)`);
      process.exit(1);
    }
  }

  // Whole datatype
  const wholeDatatype = loadDatatypes().get(query);
  if (wholeDatatype) {
    console.log(`Datatype ${query}   (source: vendored creator-docs, not the API dump)`);
    for (const [name, rec] of wholeDatatype.members) {
      console.log(`  ${rec.qualified}   [${rec.kind}]`);
    }
    process.exit(0);
  }

  // Whole class
  const cls = dump.classes.get(query);
  if (cls) {
    found = true;
    const chain = [];
    let cursor = cls;
    while (cursor) {
      chain.push(cursor.name);
      cursor = cursor.superclass ? dump.classes.get(cursor.superclass) : null;
    }
    console.log(`Class ${chain.join(" : ")}${cls.tags.length ? `  [${cls.tags.join("] [")}]` : ""}`);
    if (flags.has("--members")) {
      for (const rec of cls.members.values()) console.log(describe(rec));
    } else {
      console.log(`  ${cls.members.size} own member(s). Pass --members to list them.`);
    }
    process.exit(0);
  }

  // Substring search across every member name
  const needle = query.toLowerCase();
  const hits = [];
  for (const [bare, records] of dump.bareMembers) {
    const match = flags.has("--exact")
      ? bare.toLowerCase() === needle
      : bare.toLowerCase().includes(needle);
    if (match) hits.push(...records);
  }
  for (const name of dump.enums.keys()) {
    const match = flags.has("--exact")
      ? name.toLowerCase() === needle
      : name.toLowerCase().includes(needle);
    if (match) hits.push({ enumName: name });
  }

  if (hits.length) {
    found = true;
    const shown = hits.slice(0, 40);
    for (const hit of shown) {
      if (hit.enumName) {
        const e = dump.enums.get(hit.enumName);
        console.log(`Enum ${hit.enumName}: ${[...e.items.keys()].join(", ")}`);
        continue;
      }
      console.log(hit.qualified);
      console.log(describe(hit));
    }
    if (hits.length > shown.length) {
      console.log(`\n... and ${hits.length - shown.length} more. Narrow the query or pass --exact.`);
    }
  }

  if (!found) {
    console.log(`${query}  NOT FOUND in the Roblox API dump (${dump.version}).`);
    console.log("You were about to invent an API. Stop and look up the real one.");
    process.exit(1);
  }
}

main();
