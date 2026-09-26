---
name: roblox-toolchain
description: Roblox tooling outside Studio - Rojo, Rokit, Wally, selene, StyLua, luau-lsp, Lune, CI. Use for setup, linting, packages.
---

# Toolchain

Versions below were verified against the live repositories. Where a project is
archived, that is stated — a lot of Roblox tutorials still recommend dead tools.

## Load a reference when

| Need | File |
|---|---|
| `.luaurc`, language mode, lint config, aliases, `globalTypes.d.luau` | `references/luaurc.md` |

---

## The stack

| Tool | ★ | Purpose | Status |
|---|---|---|---|
| **Rojo** | 1,726 | sync a file tree into Studio | v7.7.0, active |
| **Rokit** | 450 | install and pin the other tools | v1.2.0, active |
| **Wally** | 494 | package manager | v0.3.2, active |
| **StyLua** | 2,288 | formatter | active |
| **selene** | 813 | linter | active |
| **luau-lsp** | 533 | language server | v1.69.0, active |
| **Lune** | 946 | standalone Luau runtime, for CI | active |
| **jest-roblox** | 46 | test runner | active |
| **Argon** | 142 | Rojo alternative with two-way sync | active |
| ~~Aftman~~ | 198 | toolchain manager | **archived 2025** — use Rokit |
| ~~TestEZ~~ | 209 | test runner | **archived** — use jest-roblox |

---

## Rokit — install everything else

`rokit.toml` at the project root pins exact versions, so every machine and CI
runner gets the same toolchain.

```toml
[tools]
rojo = "rojo-rbx/rojo@7.7.0"
wally = "UpliftGames/wally@0.3.2"
stylua = "JohnnyMorganz/StyLua@2.0.2"
selene = "Kampfkarren/selene@0.28.0"
luau-lsp = "JohnnyMorganz/luau-lsp@1.69.0"
lune = "lune-org/lune@0.8.9"
```

```bash
rokit install          # installs everything in rokit.toml
rokit add rojo-rbx/rojo
```

Pin exact versions. A floating version means a tool update silently changes your
formatter's output or your linter's verdict mid-project.

Aftman is archived; `aftman.toml` files still work but new projects should use
Rokit.

---

## Rojo — file tree to DataModel

`default.project.json` maps directories onto the DataModel:

```json
{
  "name": "MyGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared":   { "$path": "src/shared" },
      "Packages": { "$path": "Packages" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

> Older project files set `Workspace.FilteringEnabled` here. Do not copy that:
> the property is `[Deprecated]` and gated to `Plugin` for **writes**, so Rojo
> cannot set it. Filtering has been permanently on for years and the property is
> inert.

```bash
rojo serve                          # live sync; connect from the Studio plugin
rojo build -o build.rbxlx           # place file, for CI
rojo sourcemap --output sourcemap.json --include-non-scripts
```

**File naming decides the instance class:**

| File | Becomes |
|---|---|
| `Foo.luau` | `ModuleScript` |
| `Foo.server.luau` | `Script` |
| `Foo.client.luau` | `LocalScript` |
| `init.luau` | the folder itself becomes a ModuleScript |
| `init.server.luau` | the folder becomes a `Script` |
| `Foo.model.json` / `Foo.rbxmx` | an instance tree |
| `Foo.meta.json` | properties for the sibling file's instance |

**Rojo sync is one-way** by default: files to Studio. Edits made in Studio to
synced scripts are overwritten. Build in your editor, not in Studio, or use
**Argon** if two-way sync matters to your workflow.

Keep binary assets (models, meshes) in the place file and code in the file tree.
Trying to keep everything in Git makes merges painful for no gain.

---

## Wally — packages

```toml
# wally.toml
[package]
name = "you/yourgame"
version = "0.1.0"
realm = "shared"
registry = "https://github.com/UpliftGames/wally-index"

[dependencies]
Trove = "sleitnick/trove@1.5.0"
Signal = "sleitnick/signal@2.0.1"
Promise = "evaera/promise@4.0.0"
ProfileStore = "madstudioroblox/profilestore@1.0.0"

[dev-dependencies]
Jest = "jsdotlua/jest@3.6.1"
```

```bash
wally install       # writes Packages/ and wally.lock
```

Commit `wally.lock`. Do not commit `Packages/` — it is generated.

`realm` matters: `shared` packages go in `ReplicatedStorage`, `server` packages
in `ServerScriptService`. Getting it wrong ships server code to clients.

Wally package names are lowercase on the registry. The folder Wally generates is
named after **the alias key on the left of the `=`** in `[dependencies]`, not
after the registry name — so `Jest = "jsdotlua/jest@3.6.1"` gives you
`Packages.Jest`. Pick alias keys that read well at the require site.

Wally does **not** preserve the upstream package's casing, which is the mental
model most people arrive with.

---

## luau-lsp — the piece that makes typing real

Without a sourcemap, the language server has no idea what
`ReplicatedStorage.Shared.Combat` is. With one, `require` resolves, instance
paths type-check, and `--!strict` becomes genuinely useful.

```bash
rojo sourcemap --output sourcemap.json --include-non-scripts --watch
```

VS Code settings:

```json
{
  "luau-lsp.sourcemap.enabled": true,
  "luau-lsp.sourcemap.autogenerate": true,
  "luau-lsp.sourcemap.rojoProjectFile": "default.project.json",
  "luau-lsp.types.roblox": true,
  "luau-lsp.completion.imports.enabled": true,
  "luau-lsp.diagnostics.strictDatamodelTypes": true
}
```

`autogenerate` runs `rojo sourcemap --watch` for you. If autocomplete on your
own modules is missing, the sourcemap is stale or absent — that is nearly always
the cause.

---

## StyLua and selene

```toml
# stylua.toml
column_width = 100
indent_type = "Tabs"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

```toml
# selene.toml
std = "roblox"

[lints]
unused_variable = "warn"
shadowing = "warn"
undefined_variable = "deny"
```

```bash
stylua src/
selene src/
selene generate-roblox-std        # regenerate the Roblox std after an API update
```

Regenerate the Roblox standard library after a Roblox release, or selene will
flag newly added globals as undefined.

Run both in CI and in a pre-commit hook. Formatting arguments are a waste of
review time; let the tool decide and stop discussing it.

---

## Testing

`jest-roblox` is the current runner. `TestEZ` is archived — do not start there.

```lua
-- Damage.test.luau
local JestGlobals = require(script.Parent.Parent.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Damage = require(script.Parent.Damage)

describe("compute", function()
    it("floors the result", function()
        expect(Damage.compute(25, 1.5)).toBe(37)
    end)

    it("ignores unknown weapons", function()
        expect(Damage.compute(0, 1)).toBe(0)
    end)
end)
```

Three things differ from TestEZ, and copying a TestEZ example into a Jest-Lua
project fails on all three: globals are **required and destructured** rather
than ambient, matchers are `toBe` / `toEqual` rather than the `.to.equal`
chain, and the file **does not** return a function. The filename convention is
`.test.luau` or a `__tests__` folder, not `.spec.luau`.

Test the **pure** layer — functions that take values and return values. Testing
the wiring layer requires mocking the DataModel and usually costs more than it
returns. `roblox-architecture` covers how to separate the two so this is
possible at all.

---

## CI

**Lune** runs Luau outside Roblox, which is what makes real CI possible.

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: CompeyDev/setup-rokit@v0.1.2
      - run: rokit install
      - run: wally install
      - run: stylua --check src/
      - run: selene src/
      - run: rojo sourcemap --output sourcemap.json
      - run: luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau src/
      - run: lune run tests          # pure-Luau tests only; see note below
```

`luau-lsp analyze` is the type-check step — it is what turns `--!strict` from a
suggestion into a build gate. `globalTypes.d.luau` is not in your repository;
fetch it in CI from the `JohnnyMorganz/luau-lsp` release assets before this step.

> **The `lune run tests` line only runs pure-Luau tests.** Lune is a standalone
> Luau runtime with no DataModel: there is no `game`, no `Instance`, no
> services. A jest-roblox suite that touches Roblox globals will not run under
> it. Either keep the tested layer pure — which is what
> `roblox-architecture` recommends anyway, and what makes tests worth having —
> or run the suite inside a real Roblox process with `run-in-roblox`. Do not
> assume the line above executes a DataModel-dependent suite.

---

## Studio MCP

Roblox Studio ships an MCP server. Enable it at
**Assistant → Manage MCP Servers → Enable Studio as MCP server**; use the
client options actually shown in the current Studio build, then verify the
generated stdio configuration in that client.

It exposes script read/edit/grep, asset generation and Creator Store insert,
instance tree and property inspection, Luau execution in Edit/Client/Server
contexts, playtest control, viewport screenshots, input simulation, console
logs, and API documentation lookup.

Roblox's own warning is worth repeating: *"Make sure to only connect clients you
trust"* — a connected client can read and modify content in your open places.

Full comparison of Studio MCP options, including the vetted third-party
alternative and the ones this stack rejected, is in `docs/mcp.md`.

---

## Recommended starting layout

```
mygame/
  rokit.toml
  wally.toml
  wally.lock
  default.project.json
  stylua.toml
  selene.toml
  .github/workflows/ci.yml
  src/
    shared/
    server/
    client/
  tests/
```

`Packages/`, `sourcemap.json` and `build.rbxlx` go in `.gitignore`.

## Works with

- `roblox-studio-mcp`: driving the open Studio place from an agent.
- `roblox-architecture`: the folder layout Rojo maps.
- `roblox-luau-language`: strict types checked by luau-lsp.
