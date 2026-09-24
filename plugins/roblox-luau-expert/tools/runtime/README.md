# Offline Luau compiler and test runtime

These are unmodified x64 release binaries from
[Luau 0.739](https://github.com/luau-lang/luau/releases/tag/0.739), retrieved
2026-09-21. The accompanying `LICENSE-Luau.txt` is the upstream MIT license.

Archive SHA-256 values were checked before extraction:

- Windows: `c5db8c3273f056416da224fd3cf20aa4644afb5af8498303b6b87ca0bd843ad1`
- Ubuntu: `8a9b4b381021722c82d6e6cda0964b5c9e7f354ec1035fcd8b657acc22e49247`

`tools/py/check_luau.py` invokes the compiler's `--null` mode. It compiles the
actual file without running its code, catching syntax/register-limit defects
that regex linters cannot detect. The Linux copy lets a custom GPT check syntax
offline after extracting the knowledge archive. Unsupported hosts report a
missing check or can set `LUAU_COMPILE_BIN` to a compatible official compiler.

The separate `luau` runtime executes only the repository's explicit mock-test
harnesses. It is not Roblox Studio and does not establish UI rendering, game
integration, server acceptance or executor compatibility. `LUAU_BIN` overrides
it when a different standalone runtime is intentionally required.
