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
