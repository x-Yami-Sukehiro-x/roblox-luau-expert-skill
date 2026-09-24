import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve, sep } from "node:path";
import test from "node:test";
import { checkPackage, collectPackageFiles, createPackageZip, writePackage } from "../bin/lib/portable-package.mjs";

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), "roblox-portable-test-"));
  t.after(() => {
    const target = resolve(root);
    assert.ok(target.startsWith(resolve(tmpdir()) + sep));
    assert.ok(target.split(sep).at(-1).startsWith("roblox-portable-test-"));
    rmSync(target, { recursive: true, force: true });
  });
  function put(path, content) {
    mkdirSync(join(root, path, ".."), { recursive: true });
    writeFileSync(join(root, path), content);
  }
  put(".claude/skills/example/SKILL.md", "# Skill\nUnicode: \u2713\n");
  put("docs/source.md", "source\n");
  put("docs/old.zip", "old archive");
  put("docs/__pycache__/cached.pyc", "cached");
  put("docs/ignored/report.md", "run-specific report");
  put("README.md", "readme\n");
  const archive = join(root, "docs/knowledge.zip");
  const manifest = join(root, "docs/package-manifest.json");
  const files = () => collectPackageFiles(root, [".claude", "docs", "README.md"], ["docs/package-manifest.json", "docs/ignored"]);
  return { root, put, files, archive, manifest };
}

test("archives include hidden skills, omit generated archives and cache, and have stable bytes", (t) => {
  const f = fixture(t);
  const files = f.files();
  assert.deepEqual(files.map((file) => file.path), [".claude/skills/example/SKILL.md", "README.md", "docs/source.md"]);
  writePackage(files, f.archive, f.manifest);
  const firstZip = readFileSync(f.archive);
  const firstManifest = readFileSync(f.manifest);
  writePackage(f.files(), f.archive, f.manifest);
  assert.deepEqual(readFileSync(f.archive), firstZip);
  assert.deepEqual(readFileSync(f.manifest), firstManifest);
  assert.deepEqual(checkPackage(f.files(), f.archive, f.manifest, true), []);
  // Read with an independent implementation, including CRC validation.
  const output = execFileSync("python", ["-c", "import zipfile,sys; z=zipfile.ZipFile(sys.argv[1]); assert z.testzip() is None; assert z.read('.claude/skills/example/SKILL.md').decode() == '# Skill\\nUnicode: \\u2713\\n'; print(len(z.namelist()))", f.archive], { encoding: "utf8" });
  assert.equal(output.trim(), "3");
});

test("freshness detects edited sources, added sources and tampered archive bytes", (t) => {
  const f = fixture(t);
  writePackage(f.files(), f.archive, f.manifest);
  f.put("docs/source.md", "edited\n");
  assert.match(checkPackage(f.files(), f.archive, f.manifest, true).join("\n"), /source hashes are stale/);
  f.put("docs/source.md", "source\n");
  f.put("docs/new.md", "new\n");
  assert.match(checkPackage(f.files(), f.archive, f.manifest, true).join("\n"), /source hashes are stale/);
  writePackage(f.files(), f.archive, f.manifest);
  writeFileSync(f.archive, "damaged");
  assert.match(checkPackage(f.files(), f.archive, f.manifest, true).join("\n"), /archive hash differs/);
});

test("a checkout can omit its untracked archive, but upload verification requires it", (t) => {
  const f = fixture(t);
  writePackage(f.files(), f.archive, f.manifest);
  rmSync(f.archive);
  assert.deepEqual(checkPackage(f.files(), f.archive, f.manifest), []);
  assert.match(checkPackage(f.files(), f.archive, f.manifest, true).join("\n"), /archive missing/);
});

test("failed package construction preserves the last good archive", (t) => {
  const f = fixture(t);
  writePackage(f.files(), f.archive, f.manifest);
  const before = readFileSync(f.archive);
  const malformed = [{ path: "a".repeat(65536), bytes: Buffer.from("bad") }];
  assert.throws(() => writePackage(malformed, f.archive, f.manifest), /ZIP size limit/);
  assert.deepEqual(readFileSync(f.archive), before);
  assert.deepEqual(checkPackage(f.files(), f.archive, f.manifest, true), []);
});

test("required input files cannot silently disappear from the package", (t) => {
  const f = fixture(t);
  assert.throws(() => collectPackageFiles(f.root, ["missing"]), /source missing/);
  assert.throws(() => createPackageZip(Array.from({ length: 65536 })), /entry limit/);
});
