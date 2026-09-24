# `.luaurc`

The file that configures Luau itself. It decides what `--!strict` means
project-wide, what the linter complains about, and what `require("@Shared/Foo")`
resolves to.

It is read by `luau-lsp` (both the editor server and `luau-lsp analyze`), by the
standalone `luau` binary, and by other Luau tooling. It is **not** read by
Roblox Studio — Studio has its own settings — which is why a project can pass
`luau-lsp analyze` in CI and still show different diagnostics in Studio.

---

## Where it goes

A `.luaurc` applies to its directory and everything below it, and the nearest
one wins. That is the mechanism for having strict application code and relaxed
vendored packages:

```
.luaurc                 languageMode: strict
src/.luaurc             (inherits)
Packages/.luaurc        languageMode: nonstrict   <- vendored code you did not write
```

Without the second file, every `--!strict` complaint in a dependency lands in
your CI output and there is nothing you can do about it.

---

## A project root

```json
{
  "languageMode": "strict",
  "lint": {
    "*": true,
    "LocalUnused": false
  },
  "lintErrors": true,
  "typeErrors": true,
  "globals": ["shared"],
  "aliases": {
    "Shared": "src/shared",
    "Server": "src/server",
    "Client": "src/client",
    "Packages": "Packages"
  }
}
```

| Key | Meaning |
|---|---|
| `languageMode` | `"nocheck"`, `"nonstrict"` or `"strict"`. The project-wide default a file's `--!` comment overrides |
| `lint` | Per-rule switches. `"*": true` enables everything, then disable individually |
| `lintErrors` | Promote lint warnings to errors, so CI fails on them |
| `typeErrors` | Whether type errors are errors. Default true |
| `globals` | Extra names the linter should not report as `UnknownGlobal` |
| `aliases` | `@Name` require prefixes |

**`languageMode` is the setting most projects are missing.** Writing `--!strict`
at the top of every file works but is a convention nobody enforces; setting it
here makes strict the default and `--!nonstrict` the deliberate exception.

---

## Aliases

Aliases turn brittle relative requires into stable ones:

```lua
-- Without aliases: correct until someone moves the file.
local Signal = require(script.Parent.Parent.Parent.shared.Signal)

-- With aliases: says what it means.
local Signal = require("@Shared/Signal")
```

Two things to know before adopting them:

- **The path is relative to the `.luaurc` that declares the alias**, not to the
  requiring file.
- **Roblox and Rojo must agree.** String requires and aliases are a Luau-level
  feature; whether a given Roblox runtime resolves them, and how Rojo maps them
  onto the DataModel, has moved between versions. Check both before converting a
  codebase, and keep the instance-based `require` if they do not line up. An
  alias that only works in the editor is worse than no alias.

---

## The lint rules worth naming

Luau's linter is on by default and each rule has a code and a name. The ones
that catch real defects:

| Rule | Catches |
|---|---|
| `UnknownGlobal` | A typo'd name, or a global you meant to be local |
| `GlobalUsedAsLocal` | A variable that should have been `local` and leaked |
| `LocalShadow` | An inner declaration hiding an outer one |
| `LocalUnused`, `FunctionUnused`, `ImportUnused` | Dead code, usually a leftover |
| `DuplicateLocal` | Two locals with the same name in one scope |
| `PlaceholderRead` | Reading `_`, which by convention holds nothing |
| `DuplicateFunction`, `DuplicateCondition` | Copy-paste that did not get edited |
| `TableOperations` | Misuse of `table.*`, including the `table.insert` cost trap |
| `FormatString` | A `string.format` specifier that does not match its argument |

`LocalUnused` is the one people disable, because a deliberately-unused parameter
trips it. Prefer prefixing the name with `_` — which the linter accepts — over
turning the rule off for the whole project.

Set `"lintErrors": true` once the codebase is clean. A warning nobody has to fix
becomes a warning nobody reads.

---

## Where `globalTypes.d.luau` comes from

`luau-lsp analyze --definitions=globalTypes.d.luau` needs a file describing the
Roblox API. It is **not** in your repository and it is not produced by Rojo — it
comes from the `JohnnyMorganz/luau-lsp` release assets, and it should be fetched
in CI rather than committed, so it tracks the Roblox release rather than the day
someone last downloaded it.

```yaml
- name: Fetch Roblox type definitions
  run: |
    curl -sSL -o globalTypes.d.luau \
      https://github.com/JohnnyMorganz/luau-lsp/releases/latest/download/globalTypes.d.luau
```

Pair it with a sourcemap, or the language server knows the API but not *your*
DataModel:

```bash
rojo sourcemap default.project.json --output sourcemap.json --include-non-scripts
luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau src/
```

`--include-non-scripts` matters: without it the sourcemap omits `Folder`s,
`RemoteEvent`s and `ValueBase` objects, so every `ReplicatedStorage.Remotes.Foo`
becomes an error.

The sourcemap is generated output. Gitignore it, and regenerate it in CI and on
project layout changes.

---

## Editor settings that pair with it

`.luaurc` configures Luau; a few `luau-lsp` settings configure the bridge to
Roblox and belong in `.vscode/settings.json`:

| Setting | Why |
|---|---|
| `luau-lsp.types.roblox` | Enable Roblox types at all |
| `luau-lsp.sourcemap.enabled` / `.autogenerate` | Keep the sourcemap fresh as files move |
| `luau-lsp.types.definitionFiles` | Point at `globalTypes.d.luau` |
| `luau-lsp.diagnostics.strictDatamodelTypes` | Stricter DataModel typing. Loud at first, and correct |

Commit these so the whole team sees the same diagnostics. A type error that only
one person's editor reports is a type error that ships.

---

## Checklist

- [ ] A `.luaurc` at the project root with an explicit `languageMode`.
- [ ] A second one in `Packages/` so vendored code does not fail your build.
- [ ] `aliases` verified to work in Roblox and Rojo, not only in the editor.
- [ ] Lint rules enabled broadly; unused parameters prefixed `_` rather than the rule disabled.
- [ ] `lintErrors` on once clean.
- [ ] `globalTypes.d.luau` fetched in CI, never committed.
- [ ] Sourcemap generated with `--include-non-scripts` and gitignored.
- [ ] Editor settings committed so diagnostics match across the team.
