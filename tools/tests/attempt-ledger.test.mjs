import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { join, resolve, sep } from "node:path";
import { tmpdir } from "node:os";
import { REPO_ROOT } from "../bin/lib/dump.mjs";

const PORTS = [
  [process.execPath, join(REPO_ROOT, "tools/bin/attempt-ledger.mjs")],
  ["python", join(REPO_ROOT, "tools/py/attempt_ledger.py")],
];

const LEDGER = `# Project context

## Attempts

### A1 failed: speed resets after a few seconds
- Tried: set Humanoid.WalkSpeed once when the toggle turns on
- Saw: speed returns to 16 after about 3 s
- Instead: write back on GetPropertyChangedSignal
- Avoid: \`WalkSpeed\\s*=\\s*\\d+\\s*$\`
- Unless: \`GetPropertyChangedSignal\`

### A2 fixed: close button did nothing on phones
- Cause: MouseButton1Click
- Avoid: \`MouseButton1Click\`

### A3 failed: set WalkSpeed once each time the toggle turns on
- Tried: set the Humanoid WalkSpeed once whenever the toggle turns on
- Saw: same reset
`;

function workspace(t) {
  const directory = mkdtempSync(join(tmpdir(), "roblox-ledger-test-"));
  t.after(() => {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + sep));
    rmSync(directory, { recursive: true, force: true });
  });
  writeFileSync(join(directory, "PROJECT_CONTEXT.md"), LEDGER);
  writeFileSync(
    join(directory, "Speed.client.luau"),
    [
      "local humanoid = script.Parent",
      "humanoid.WalkSpeed = 60",
      "-- button.MouseButton1Click is only a comment here",
      "button.MouseButton1Click:Connect(print)",
      "",
    ].join("\n")
  );
  return directory;
}

const run = ([command, script], args, cwd) => spawnSync(command, [script, ...args], { cwd, encoding: "utf8" });

test("both ports find recorded mistakes in code, not in comments", (t) => {
  const directory = workspace(t);
  const outputs = PORTS.map((port) => run(port, ["check", "Speed.client.luau", "--no-builtin"], directory));
  for (const result of outputs) {
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stdout, /Speed\.client\.luau:2  A1 failed: speed resets after a few seconds/);
    assert.match(result.stdout, /Speed\.client\.luau:4  A2 fixed: close button did nothing on phones/);
    assert.doesNotMatch(result.stdout, /Speed\.client\.luau:3/);
  }
  assert.equal(outputs[1].stdout.replace(/\r/g, ""), outputs[0].stdout);
});

test("an Unless pattern switches an entry off once the fix is present", (t) => {
  const directory = workspace(t);
  writeFileSync(
    join(directory, "Held.client.luau"),
    'humanoid.WalkSpeed = 60\nhumanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(hold)\n'
  );
  for (const port of PORTS) {
    const result = run(port, ["check", "Held.client.luau", "--no-builtin"], directory);
    assert.equal(result.status, 0, result.stdout);
  }
});

test("plan refuses an approach that already failed, whatever the wording", (t) => {
  const directory = workspace(t);
  const outputs = PORTS.map((port) => run(port, ["plan", "set WalkSpeed on the humanoid once the toggle is on", "--no-builtin"], directory));
  for (const result of outputs) {
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stdout, /^REPEAT A1 failed/m);
  }
  assert.equal(outputs[1].stdout.replace(/\r/g, ""), outputs[0].stdout);
  for (const port of PORTS) {
    assert.equal(run(port, ["plan", "hold it from GetPropertyChangedSignal", "--no-builtin"], directory).status, 0);
  }
});

test("lint reports the same approach failing twice", (t) => {
  const directory = workspace(t);
  const outputs = PORTS.map((port) => run(port, ["lint", "--no-builtin"], directory));
  for (const result of outputs) {
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stdout, /A3  repeats A1: the same approach failed twice/);
  }
  assert.equal(outputs[1].stdout.replace(/\r/g, ""), outputs[0].stdout);
});

test("add numbers the entry, keeps the format lint accepts, and names a repeat", (t) => {
  for (const port of PORTS) {
    const directory = workspace(t);
    const result = run(
      port,
      ["add", "--status", "failed", "--title", "speed resets again", "--tried", "set Humanoid.WalkSpeed once when the toggle turns on", "--saw", "resets", "--date", "2026-09-25", "--no-builtin"],
      directory
    );
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /added A4/);
    assert.match(result.stdout, /A4 repeats A1/);
    const text = readFileSync(join(directory, "PROJECT_CONTEXT.md"), "utf8");
    assert.match(text, /### A4 failed: speed resets again\n- Tried: set Humanoid\.WalkSpeed once when the toggle turns on\n- Saw: resets\n- Date: 2026-09-25\n$/);
  }
});

test("the stack's known failures parse cleanly", () => {
  for (const port of PORTS) {
    const result = run(port, ["lint", "--ledger", join(REPO_ROOT, ".claude/skills/roblox-attempt-memory/references/known-failures.md"), "--no-builtin"], REPO_ROOT);
    assert.equal(result.status, 0, result.stdout);
  }
});
