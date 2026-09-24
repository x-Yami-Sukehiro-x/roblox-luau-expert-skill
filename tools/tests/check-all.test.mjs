import test from "node:test";
import assert from "node:assert/strict";
import { classifyGate } from "../bin/check-all.mjs";

test("only completed checks become passes", () => {
  assert.equal(classifyGate({ status: 0, stdout: "42 assertions passed" }).status, "PASS");
  assert.equal(classifyGate({ status: 2, stderr: "luau missing" }).status, "SKIP");
  assert.equal(classifyGate({ status: 1, stdout: "2 findings" }).status, "FAIL");
});

test("a successful process with skipped subchecks remains partial", () => {
  const result = classifyGate({
    status: 0,
    stdout: "120 examples, 0 findings\n(luau binary not found: syntax checking was skipped)",
  });
  assert.equal(result.status, "PART");
  assert.match(result.partial, /syntax checking was skipped/);
});

test("launch failure and interrupted processes cannot pass", () => {
  assert.equal(classifyGate({ status: null, error: new Error("ENOENT") }).status, "FAIL");
  assert.equal(classifyGate({ status: null, signal: "SIGTERM" }).status, "FAIL");
});

test("test names and zero skip counts are not skipped checks", () => {
  const result = classifyGate({ status: 0, stdout: "✔ successful process with skipped subchecks\nℹ skipped 0" });
  assert.equal(result.status, "PASS");
  assert.equal(classifyGate({ status: 0, stdout: "ℹ skipped 1" }).status, "PART");
  assert.equal(classifyGate({ status: 0, stdout: "SKIP syntax checks" }).status, "PART");
});
