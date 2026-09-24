import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { join, resolve, sep } from "node:path";
import { tmpdir } from "node:os";
import { REPO_ROOT } from "../bin/lib/dump.mjs";

test("the offline compiler catches invalid Luau without executing valid source", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "roblox-compile-test-"));
  t.after(() => {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + sep));
    assert.ok(directory.split(sep).at(-1).startsWith("roblox-compile-test-"));
    rmSync(directory, { recursive: true, force: true });
  });
  const source = join(directory, "specimen.luau");
  const check = () => spawnSync("python", [join(REPO_ROOT, "tools/py/check_luau.py"), source], { encoding: "utf8" });
  writeFileSync(source, 'local values = table.freeze({ level = "Medium", )\n');
  const invalid = check();
  assert.equal(invalid.status, 1, invalid.stderr);
  assert.match(invalid.stderr, /SyntaxError/);
  writeFileSync(source, 'local quality: string = "Medium"\nerror("This source must never run")\n');
  const valid = check();
  assert.equal(valid.status, 0, valid.stderr);
  assert.match(valid.stdout, /source was not executed/);
  const unavailable = spawnSync("python", [join(REPO_ROOT, "tools/py/check_luau.py"), source], {
    encoding: "utf8", env: { ...process.env, LUAU_COMPILE_BIN: join(directory, "absent-compiler") },
  });
  assert.equal(unavailable.status, 2);
  assert.match(unavailable.stderr, /unavailable/);
});
