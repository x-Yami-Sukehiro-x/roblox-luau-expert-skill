// The feature search decides whether a script gets built or a runtime probe
// gets sent, so its verdicts are pinned against a small decompiled fixture.
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { REPO_ROOT } from "../bin/lib/dump.mjs";

const TOOL = join(REPO_ROOT, "tools", "py", "dump_index.py");
const DUMP = join(REPO_ROOT, "evals", "fixtures", "dump-sample");

function search(feature) {
  const result = spawnSync("python", [TOOL, DUMP, "--feature", feature, "--json"], { encoding: "utf8" });
  return { status: result.status, report: JSON.parse(result.stdout) };
}

test("a feature the dump implements is FOUND with its remote and argument count", () => {
  const { status, report } = search("auto farm");
  assert.equal(status, 0);
  assert.equal(report.verdict, "FOUND");
  const collect = report.related_remotes.find((call) => /CollectCoin/.test(call.source));
  assert.ok(collect, "CollectCoin call site resolved through its local alias");
  assert.equal(collect.count, 2);
});

test("a game feature the dump never mentions is NOT FOUND and says to probe", () => {
  const { status, report } = search("hatch eggs");
  assert.equal(status, 4);
  assert.equal(report.verdict, "NOT FOUND");
  assert.equal(report.evidence.length, 0);
  assert.equal(report.engine_route, null);
  assert.ok(report.failed_markers >= 1, "failed regions are reported, not ignored");
  const text = spawnSync("python", [TOOL, DUMP, "--feature", "hatch eggs"], { encoding: "utf8" }).stdout;
  assert.match(text, /runtime-probe\.luau/);
  assert.match(text, /local KEYWORDS = \{ "hatch", "egg", "pet", "roll", "gacha" \}/);
});

test("an engine feature missing from the dump names the engine members instead", () => {
  const { status, report } = search("fly");
  assert.equal(status, 4);
  assert.match(report.engine_route, /LinearVelocity/);
});

test("a short term matches whole words only", () => {
  const { report } = search("tp");
  assert.ok(!report.evidence.some((entry) => /HttpService|http/i.test(entry.code)));
});

test("script sources inside a saveinstance rbxlx are searched", () => {
  const { report } = search("fishing rod");
  assert.equal(report.verdict, "FOUND");
  assert.ok(report.evidence.some((entry) => entry.script.includes("RodController")));
});

test("a folder with nothing readable exits 2", () => {
  const result = spawnSync("python", [TOOL, join(REPO_ROOT, "tools", "api-dump", "datatypes")], { encoding: "utf8" });
  assert.equal(result.status, 2);
});
