import { chmodSync, existsSync } from "node:fs";
import { join } from "node:path";
import { REPO_ROOT } from "./dump.mjs";

export function luauRuntime() {
  if (process.env.LUAU_BIN) return process.env.LUAU_BIN;
  const host = { win32: "windows-x64", linux: "linux-x64" }[process.platform];
  if (host && process.arch === "x64") {
    const bundled = join(REPO_ROOT, "tools", "runtime", host, process.platform === "win32" ? "luau.exe" : "luau");
    if (existsSync(bundled)) {
      if (process.platform !== "win32") chmodSync(bundled, 0o755);
      return bundled;
    }
  }
  return "luau";
}
