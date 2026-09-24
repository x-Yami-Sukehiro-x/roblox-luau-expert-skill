# From source evidence to one API

`decompiled-source.md` covers reading a dump. This file covers the step straight
after: turning what you read into **one established access path** per job.

The failure this exists to stop is the fallback chain — a script that tries
`getsenv`, then `getgc`, then `filtergc`, then a DataModel search, because the
author never decided where the value lives. It is longer, slower, harder to fix,
and it fails in a way that tells you nothing, because you cannot tell which path
was supposed to work.

> **A fallback chain is a confession that the source was not read.**
> If you have the source, the source says which one. Pick it.

---

## The ladder

Read the left column off the dump and verify the live representation. The right
column is the matching access path, not permission to mutate the first result.

| What the source shows | Where the value actually lives | The one API |
|---|---|---|
| `local x = …` at file scope, read inside a function | **upvalue** of that function | `debug.getupvalues(f)` → `debug.setupvalue(f, i, v)` |
| `x = …` at file scope, no `local` | **global** in that script's environment | `getsenv(script).x` |
| a number or string literal inside a function body | candidate **constant**, if retained by the compiler | inspect `debug.getconstants(f)`; resolve the intended slot before `debug.setconstant` |
| a table literal in a `ModuleScript` that is `return`ed | a table in that module's runtime/VM; consumers may clone it | use its established live reference, or `filtergc("table", { Keys = { … } }, false)` and identify one candidate |
| a `local function` you need to call | a live **closure**, if retained and reachable | `filtergc("function", { Constants = { "<a string from it>" } }, false)`, then identify it |
| a property rewritten every frame by a loop | a property **plus a writer** | find the source-defined setter/config first; disable only an identified connection whose other duties are understood |
| `instance.Parent = nil` anywhere | the instance **leaves the DataModel** | capture it from an upvalue, or `getnilinstances()` |
| `remote:FireServer(a, b, c)` | the **server boundary** | build the same three arguments and call it |
| you need to see or edit that call as it happens | same | `hookmetamethod(game, "__namecall", …)` + `getnamecallmethod()` |
| `GetAttribute("X")` / `SetAttribute("X", …)` | an **attribute** | `instance:GetAttribute("X")` — no executor API needed |
| a property the dump shows but Studio hides | a **hidden property** | `gethiddenproperty(instance, "X")` |
| `game:GetService("X"):WaitForChild("Y")` | an ordinary **DataModel path** | index it. **No executor API at all** |

The last row is the one models skip. Most of a good executor script is plain
Roblox code. Reach for `filtergc` when the source shows you something the
DataModel does not expose — not as an opening move.

Literal presence alone does not guarantee an editable constant-table slot.
Local module returns are not automatically the same table in an executor VM,
an Actor and the game's client. Establish the relationship actually consumed by
the feature; `require` is appropriate only when that same-context identity and
its initialization side effects are understood.

---

## How many executor functions should a script use?

One to three, for a single-purpose script.

| Count | What it usually means |
|---|---|
| 0–1 | The job was DataModel work with a `getgenv` handle. Normal |
| 2–3 | One value layer reached, plus persistence. Normal |
| 4–5 | Two layers, or a hook plus a search. Justify each one |
| 6+ | Guessing. Go back to the dump |

The dragger in `roblox-code-craft/references/slop-rewrite.md` reaches an
upvalue, patches a constant and stores an unload handle: `getsenv`,
`debug.getupvalues`, `debug.getconstants`, `debug.setconstant`, `getgenv`. Five,
every one of them justified by a specific line of the source.

---

## The fallback chain, and what replaces it

```lua
-- WRONG. Four attempts, none of them checked against the source.
local config
if typeof(getsenv) == "function" then
    local ok, env = pcall(getsenv, script)
    if ok and env then config = env.Config end
end
if not config and typeof(getgc) == "function" then
    for _, value in getgc(true) do
        if typeof(value) == "table" and rawget(value, "WalkSpeed") then
            config = value
            break
        end
    end
end
if not config then
    config = require(game.ReplicatedStorage:WaitForChild("Config"))
end
if not config then
    warn("could not find config")
    return
end
```

Thirty lines that work by accident when they work at all. The three paths reach
**three different tables** — the script's globals, some table in the heap with a
`WalkSpeed` key, and a module return — and the script does not care which one it
got. When the game updates, it silently takes a different branch and appears to
succeed.

If the source shows `local Config = require(...)` read by `fireWeapon`, establish
that live closure, enumerate its upvalues and match the table's source-defined
fields and reader relationship. Require one matching table. Repeated `FireRate`
fields do not identify a weapon; a `break` after the first match hides ambiguity.

One path. When it fails it says which step failed, and the fix is to re-read the
dump rather than to add a fifth branch.

### The one fallback that is legitimate

Two executors implementing the **same job** under different names. Resolve it
once, at bind time, at the top of the file:

```lua
local getui = gethui or get_hidden_gui
assert(getui, "no hidden GUI container")
```

That is not a search. It is a name difference, decided before any work starts,
and the assert means a missing implementation stops the script instead of
quietly degrading it. `references/api/misc.md` has the alias table.

**Never** fall back from one *value layer* to another. Upvalue, constant, global
and property are different places; a script that will take whichever it finds
does not know what it is editing.

---

## Feature detection: once, at the top

```lua
local getsenv = getsenv
local getupvalues, setupvalue = debug.getupvalues, debug.setupvalue
assert(getsenv and getupvalues and setupvalue, "needs getsenv and debug upvalue access")
```

The `local` line **is** the capability list, so it cannot drift away from what
the code calls. Ten `if typeof(x) ~= "function"` blocks can, and do.

Do not check a capability twice. Do not check that a fetched closure is a
Luau closure again when its identity already establishes that fact. The bind
proves availability, not that a target, slot or executor implementation is valid.
Keep expected discovery failures explicit; use `pcall` at a real executor or
foreign-code boundary when recovery is required, and report the returned error.
Do not suppress it and switch value layers. The budget is in
`roblox-code-craft/references/anti-slop-code.md` (row 5: two `typeof` statements
per file, maximum).

`islclosure` earns its line in exactly one place: when you are iterating
closures you did not choose, such as a `getgc` sweep, and some of them will be C
closures. Not after `getsenv` handed you a named function from a `LocalScript`.

---

## Before the script goes out

```powershell
node tools/bin/verify-executor-api.mjs <name>        # exit 1 = absent from this reference
node tools/bin/lint-luau-slop.mjs Script.luau        # exit 1 = ceremony
python tools/py/roblox_lint.py Script.luau           # the same, without Node
```

The linter counts this page's rule directly. `E-LAYERCHAIN` fails on an `or`
between two value layers on one line, and on a third layer appearing anywhere in
the file; `W-EXECSURFACE` warns past five distinct executor functions, counting
alias spellings of one function once. The ladder above is the table it uses, so
a script that disagrees with the count disagrees with this page.

Run `verify-executor-api.mjs` on **every executor name in the script**. It
resolves alias spellings and namespaced members, so `getconstants` finds
`debug.getconstants`. A non-zero exit is the signal that the name came from
memory rather than from the reference.

Then answer these, from the source rather than from habit:

- [ ] Every executor call traces to a specific line of the dump.
- [ ] No job has two code paths.
- [ ] Exactly one target and intended slot were identified by source and runtime evidence.
- [ ] Decompiler labels and repeated values were not used as identity proofs.
- [ ] Anything read for a restore was **captured**, not retyped as a literal.
- [ ] The count of executor functions is defensible — see the table above.
- [ ] What the dump could not establish is stated in the reply.
- [ ] Re-execution and unload follow `lifecycle.md`; runtime checks are reported separately.

---

## Related references
- `decompiled-source.md` — reading the dump; the extraction pass
- `function-selection.md` — the same map for when you have **no** source
- `value-persistence.md` — the ladder when the value gets rewritten
- `client-feasibility.md` — whether it is reachable from the client at all
- `lifecycle.md` — ownership, re-execution, asynchronous work and restoration
- `roblox-code-craft/references/anti-slop-code.md` — the ceremony budget
- `roblox-code-craft/references/slop-rewrite.md` — a worked 330-to-59 rewrite
