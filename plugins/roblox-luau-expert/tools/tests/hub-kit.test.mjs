// HubKit, the executor hub UI library in library/hub-kit, checked end to end:
// the committed bundle matches the sources, it compiles, every theme's text
// meets 4.5:1, every icon id is one already verified, and the bundle behaves
// as its README says under the engine stubs.
//
// The stubs model signals and property writes, not rendering. What this
// proves is callbacks, state, flags, configs and teardown; what a window looks
// like still needs Roblox (see library/hub-kit/README.md, "Testing").

import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve, sep } from "node:path";
import { REPO_ROOT } from "../bin/lib/dump.mjs";
import { contrast } from "../bin/lib/contrast.mjs";
import { luauRuntime } from "../bin/lib/luau-runtime.mjs";
import { BUNDLE, KIT, bundle } from "../bin/build-hub-kit.mjs";

const read = (path) => readFileSync(path, "utf8").replace(/\r\n/g, "\n");

function scratch(t) {
  const directory = mkdtempSync(join(tmpdir(), "hub-kit-test-"));
  t.after(() => {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + sep));
    rmSync(directory, { recursive: true, force: true });
  });
  return directory;
}

test("the committed bundle is built from the current sources", () => {
  assert.equal(read(BUNDLE), bundle(), "run node tools/bin/build-hub-kit.mjs");
});

// Through check_luau.py, which finds the bundled compiler for this platform
// and marks it executable; a checkout does not keep the Linux file's mode.
test("the bundle compiles", () => {
  const result = spawnSync("python", [join(REPO_ROOT, "tools", "py", "check_luau.py"), BUNDLE], { encoding: "utf8" });
  assert.equal(result.status, 0, `${result.stdout}${result.stderr}`);
});

test("every theme's text meets 4.5:1 and its accents 3:1", () => {
  const pairs = [
    ["text", "background", 4.5], ["text", "surface", 4.5], ["text", "raised", 4.5], ["text", "hover", 4.5],
    ["textMuted", "background", 4.5], ["textMuted", "surface", 4.5], ["textMuted", "raised", 4.5],
    ["textMuted", "hover", 4.5], ["onAccent", "accent", 4.5], ["onAccent", "danger", 4.5],
    ["accent", "raised", 3], ["focus", "raised", 3], ["success", "surface", 3], ["warning", "surface", 3],
    ["danger", "surface", 3], ["info", "surface", 3],
  ];
  const themes = join(KIT, "src", "Themes");
  const files = readdirSync(themes).filter((name) => name !== "init.luau");
  assert.ok(files.length >= 3);
  for (const file of files) {
    const palette = {};
    for (const [, role, r, g, b] of read(join(themes, file)).matchAll(/(\w+) = Color3\.fromRGB\((\d+), (\d+), (\d+)\)/g)) {
      palette[role] = [Number(r), Number(g), Number(b)];
    }
    for (const [foreground, background, minimum] of pairs) {
      const ratio = contrast(palette[foreground], palette[background]);
      assert.ok(ratio >= minimum, `${file}: ${foreground} on ${background} is ${ratio.toFixed(2)}:1`);
    }
  }
});

test("every icon id is one already verified in icon-ids.txt", () => {
  const verified = new Map();
  const list = read(join(REPO_ROOT, ".claude", "skills", "roblox-ui-components", "references", "icon-ids.txt"));
  for (const line of list.split("\n")) {
    const [name, id] = line.split("\t");
    if (id) verified.set(name, id);
  }
  const icons = read(join(KIT, "src", "Core", "Icons.luau"));
  const entries = [...icons.matchAll(/\["([\w-]+)"\] = "(rbxassetid:\/\/\d+)"/g)];
  assert.ok(entries.length > 20);
  for (const [, name, id] of entries) assert.equal(id, verified.get(name), `icon ${name}`);
});

function runHarness(t, name, ...parts) {
  const harness = join(scratch(t), `${name}.luau`);
  const common = [
    read(join(REPO_ROOT, "library", "tests", "stubs.luau")),
    read(join(KIT, "tests", "stubs-extra.luau")),
    "local function loadKit()",
    read(BUNDLE),
    "end",
  ];
  writeFileSync(harness, [...common, ...parts].join("\n"), "utf8");
  const result = spawnSync(luauRuntime(), [harness], { encoding: "utf8" });
  const output = `${result.stdout}${result.stderr}`;
  assert.equal(result.status, 0, output);
  const tally = /^(\d+) passed, (\d+) failed$/m.exec(result.stdout);
  assert.ok(tally, output);
  assert.equal(Number(tally[2]), 0, output);
  return Number(tally[1]);
}

test("the bundle behaves as documented under the engine stubs", (t) => {
  const passed = runHarness(t, "hub-kit-harness", read(join(KIT, "tests", "hub-kit.luau")));
  assert.ok(passed >= 90, `only ${passed} assertions ran`);
  console.log(`# hub-kit: ${passed} behaviour assertions passed`);
});

test("the example builds, survives a respawn and a rerun, and unloads cleanly", (t) => {
  const passed = runHarness(
    t,
    "hub-kit-example",
    "local function runExample()",
    read(join(KIT, "example", "Example.luau")),
    "end",
    read(join(KIT, "tests", "example.luau"))
  );
  assert.ok(passed >= 12, `only ${passed} assertions ran`);
  console.log(`# hub-kit example: ${passed} assertions passed`);
});
