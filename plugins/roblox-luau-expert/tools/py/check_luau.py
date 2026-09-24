#!/usr/bin/env python3
"""Compile Luau files without executing them; exit 1 for invalid code, 2 if unavailable."""

import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def compiler():
    override = os.environ.get("LUAU_COMPILE_BIN")
    if override:
        found = shutil.which(override)
        if not found:
            raise FileNotFoundError("LUAU_COMPILE_BIN does not resolve to an executable")
        return Path(found)
    machine = platform.machine().lower()
    host = {"Windows": "windows-x64", "Linux": "linux-x64"}.get(platform.system())
    if host and machine in ("amd64", "x86_64"):
        name = "luau-compile.exe" if host == "windows-x64" else "luau-compile"
        bundled = Path(__file__).resolve().parents[1] / "runtime" / host / name
        if bundled.is_file():
            if os.name != "nt":
                bundled.chmod(bundled.stat().st_mode | 0o100)
            return bundled
    found = shutil.which("luau-compile")
    if found:
        return Path(found)
    raise FileNotFoundError("no Luau compiler for this host; syntax check not run")


def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/py/check_luau.py <file.luau> [more files]", file=sys.stderr)
        return 2
    try:
        executable = compiler()
        files = [Path(argument).resolve(strict=True) for argument in sys.argv[1:]]
        if any(not path.is_file() for path in files):
            raise ValueError("every input must be a file")
        result = subprocess.run(
            [str(executable), "--null", *map(str, files)],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"Luau syntax check unavailable: {error}", file=sys.stderr)
        return 2
    if result.stdout:
        print(result.stdout.rstrip())
    if result.stderr:
        print(result.stderr.rstrip(), file=sys.stderr)
    if result.returncode != 0:
        return 1
    print(f"{len(files)} file(s) compiled; source was not executed. Compiler: {executable}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
