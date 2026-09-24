import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

test("cross-host installation carries offline tools, backs up edits, preserves unrelated files, and uninstalls its own files", { skip: process.platform !== "win32", timeout: 120000 }, (t) => {
  const profile = mkdtempSync(join(tmpdir(), "roblox-install-test-"));
  t.after(() => {
    const target = resolve(profile);
    assert.ok(target.startsWith(resolve(tmpdir()) + sep));
    assert.ok(target.split(sep).at(-1).startsWith("roblox-install-test-"));
    rmSync(target, { recursive: true, force: true });
  });
  function put(path, content) {
    const destination = join(profile, path);
    mkdirSync(dirname(destination), { recursive: true });
    writeFileSync(destination, content);
  }
  function install(...args) {
    return execFileSync("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", join(root, "install.ps1"), "-HostName", "All", "-ProfileRoot", profile, ...args], { encoding: "utf8", timeout: 90000 });
  }
  const sourceSkills = join(root, ".claude/skills");
  const names = readdirSync(sourceSkills).filter((name) => existsSync(join(sourceSkills, name, "SKILL.md")));
  for (const host of ["claude", "codex", "cursor"]) put(`.${host}/skills/unrelated/SKILL.md`, "unrelated\n");
  put(".codex/skills/roblox-luau-expert-skill/.git/keep", "git metadata\n");
  put(".codex/skills/roblox-luau-expert-skill/private-note.txt", "private note\n");
  assert.match(install(), /Installed skills and complete verification bundle for Claude, Codex, Cursor/);

  for (const host of ["claude", "codex", "cursor"]) {
    const bundle = join(profile, `.${host}`, host === "codex" ? "skills/roblox-luau-expert-skill" : "roblox-luau-expert");
    for (const name of names) {
      const source = readFileSync(join(sourceSkills, name, "SKILL.md"));
      assert.deepEqual(readFileSync(join(bundle, ".claude/skills", name, "SKILL.md")), source);
      if (host !== "codex") {
        const installed = readFileSync(join(profile, `.${host}/skills`, name, "SKILL.md"));
        if (name === "roblox-luau-expert") assert.ok(installed.toString().startsWith(source.toString()));
        else assert.deepEqual(installed, source);
      }
    }
    assert.ok(existsSync(join(bundle, "tools/py/verify_api.py")));
    assert.ok(existsSync(join(bundle, "tools/api-dump/API-Dump.txt")));
    assert.ok(existsSync(join(bundle, "install.ps1")));
    assert.ok(existsSync(join(bundle, ".agents/skills/roblox-luau-expert/SKILL.md")));
    assert.ok(existsSync(join(bundle, ".cursor/rules/roblox-luau-expert.mdc")));
    assert.ok(!existsSync(join(bundle, "docs/portability/gpt/knowledge/roblox-luau-expert-skill.zip")));
    const api = execFileSync("python", [join(bundle, "tools/py/verify_api.py"), "--exec", "getgenv"], { cwd: profile, encoding: "utf8" });
    assert.match(api, /getgenv/);
    execFileSync(process.execPath, [join(bundle, "tools/bin/verify-api.mjs"), "GuiService.TopbarInset"], { cwd: profile, encoding: "utf8" });
  }
  assert.match(readFileSync(join(profile, ".cursor/rules/roblox-luau-expert.mdc"), "utf8"), /Installed bundle paths/);
  assert.match(readFileSync(join(profile, ".codex/skills/roblox-luau-expert-skill/SKILL.md"), "utf8"), /bundle root/);

  put(".claude/skills/roblox-luau-expert/SKILL.md", "local edit to retain\n");
  install();
  const backups = readdirSync(join(profile, ".claude/skill-backups"));
  assert.ok(backups.some((backup) => {
    const path = join(profile, ".claude/skill-backups", backup, "skills/roblox-luau-expert/SKILL.md");
    return existsSync(path) && readFileSync(path, "utf8") === "local edit to retain\n";
  }));
  assert.match(install("-Uninstall"), /Moved installed stack to backups/);
  for (const host of ["claude", "codex", "cursor"]) {
    assert.equal(readFileSync(join(profile, `.${host}/skills/unrelated/SKILL.md`), "utf8"), "unrelated\n");
  }
  assert.ok(!existsSync(join(profile, ".claude/skills/roblox-luau-expert")));
  assert.ok(!existsSync(join(profile, ".cursor/skills/roblox-luau-expert")));
  assert.ok(!existsSync(join(profile, ".codex/skills/roblox-luau-expert-skill/SKILL.md")));
  assert.equal(readFileSync(join(profile, ".codex/skills/roblox-luau-expert-skill/.git/keep"), "utf8"), "git metadata\n");
  assert.equal(readFileSync(join(profile, ".codex/skills/roblox-luau-expert-skill/private-note.txt"), "utf8"), "private note\n");
  assert.ok(!readdirSync(profile).some((entry) => entry.startsWith(".roblox-luau-expert-stage-")));
});
