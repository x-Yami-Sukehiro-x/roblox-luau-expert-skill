import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { join, resolve, sep } from "node:path";
import { tmpdir } from "node:os";
import { REPO_ROOT } from "../bin/lib/dump.mjs";
import { measure } from "../bin/check-registers.mjs";

test("the listing reader finds each function's peak register, line and upvalues", () => {
  const listing = [
    "Function 0 (onClick):",
    "    4:   local total = a + b",
    "GETUPVAL R1 0",
    "GETUPVAL R2 1",
    "ADD R0 R1 R2",
    "Function 1 (??):",
    "    1: local a = 1",
    "LOADK R0 K0 [1]",
    "    9: print(onClick())",
    "CAPTURE VAL R0",
    "MOVE R5 R2",
  ].join("\n");
  const [handler, main] = measure(listing);
  assert.deepEqual(
    { name: handler.name, first: handler.first, registers: handler.registers, upvalues: handler.upvalues },
    { name: "onClick", first: 4, registers: 3, upvalues: 2 }
  );
  assert.deepEqual({ name: main.name, registers: main.registers, peakLine: main.peakLine }, { name: "main chunk", registers: 6, peakLine: 9 });
});

test("both ports explain the local limit and flag a file near it", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "roblox-register-test-"));
  t.after(() => {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + sep));
    rmSync(directory, { recursive: true, force: true });
  });
  const over = join(directory, "over.luau");
  const near = join(directory, "near.luau");
  const locals = (count) => Array.from({ length: count }, (_, index) => `local slot${index} = os.clock()`).join("\n");
  writeFileSync(over, `${locals(201)}\n`);
  writeFileSync(near, `${locals(170)}\nprint(slot0)\n`);

  const runs = [
    [process.execPath, join(REPO_ROOT, "tools/bin/check-registers.mjs")],
    ["python", join(REPO_ROOT, "tools/py/register_budget.py")],
  ];
  for (const [command, script] of runs) {
    const failed = spawnSync(command, [script, over], { encoding: "utf8" });
    if (failed.status === 2) return t.skip("no Luau compiler on this host");
    assert.equal(failed.status, 1, failed.stderr);
    assert.match(failed.stdout, /Out of local registers .* too many locals alive at once/);
    const warned = spawnSync(command, [script, near], { encoding: "utf8" });
    assert.equal(warned.status, 1, warned.stderr);
    assert.match(warned.stdout, /W-REGISTERS main chunk peaks at 17\d of 255/);
  }
});

test("both ports catch a local moved out of scope and name the families filling the main chunk", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "roblox-register-test-"));
  t.after(() => {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + sep));
    rmSync(directory, { recursive: true, force: true });
  });
  const leaked = join(directory, "leaked.luau");
  writeFileSync(leaked, [
    "local getgc, getconstants =",
    "\tgetgc, debug.getconstants",
    "do",
    "\tlocal shopFrame = Instance.new(\"Frame\")",
    "\tshopFrame.Name = \"Shop\"",
    "end",
    "shopFrame.Visible = true",
    "print(getgc, getconstants)",
    "",
  ].join("\n"));
  const hub = join(directory, "hub.luau");
  const elements = Array.from({ length: 150 }, (_, index) => `local Toggle${index} = Tab:CreateToggle({ Name = "T${index}" })`);
  const helpers = Array.from({ length: 55 }, (_, index) => `local function feature${index}() end`);
  writeFileSync(hub, ["local Tab = Window:CreateTab(\"Main\")", ...elements, ...helpers, "print(Toggle3)", ""].join("\n"));

  const runs = [
    [process.execPath, join(REPO_ROOT, "tools/bin/check-registers.mjs")],
    ["python", join(REPO_ROOT, "tools/py/register_budget.py")],
  ];
  for (const [command, script] of runs) {
    const scoped = spawnSync(command, [script, leaked], { encoding: "utf8" });
    if (scoped.status === 2) return t.skip("no Luau compiler on this host");
    assert.equal(scoped.status, 1, scoped.stderr);
    assert.match(scoped.stdout, /7: W-SCOPE `shopFrame` is declared local at line 4 but used here outside that scope/);
    assert.doesNotMatch(scoped.stdout, /`getgc`/, "the capability bind reads the global on purpose");
    const full = spawnSync(command, [script, hub], { encoding: "utf8" });
    assert.equal(full.status, 1, full.stderr);
    assert.match(full.stdout, /Out of local registers/);
    assert.match(full.stdout, /I-LOCALS the main chunk declares 206 top-level locals: 151 library elements, 149 never used again/);
    assert.match(full.stdout, /55 local functions \(make them fields of one table\)/);
  }
});
