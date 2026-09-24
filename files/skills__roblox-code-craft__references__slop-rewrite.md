# One script, 330 lines to 59

A real executor script, produced by a capable model from a real decompiled
source dump. The API choices in it are **correct** — it reads the BodyPosition
off `moveDrag`'s upvalue rather than searching the DataModel, which is exactly
what the source supported. It still scores **4/20**.

That is the point of this file. Slop is not the same thing as being wrong. A
script can pick every API correctly and still bury the working part under five
times its weight in ceremony.

```powershell
node tools/bin/lint-luau-slop.mjs Dragger.luau
```

| | Original | Rewrite |
|---|---|---|
| Lines | 330 | 59 |
| Score | 4/20 | 20/20 |
| Errors | 13 | 0 |
| `pcall`s | 8 | 0 |
| `if typeof(x) ~= "function"` | 10 | 0 |
| Hand-written error strings | 15 | 5 |
| Latent bugs | 1 | 0 |

---

## What came out, and why

| Original | Lines | Replaced by | Reason |
|---|---|---|---|
| Header essay: "Based on the uploaded…", "Source-established behavior:" | 13 | nothing | Written to somebody who was in the conversation |
| `if not LocalPlayer then error(...)` | 3 | nothing | Indexing nil already names the field |
| Seven `if typeof(x) ~= "function"` blocks building a `missing` table | 38 | one `local` bind + one `assert` | 5 lines, and the bind list cannot drift from the code |
| Previous-install teardown wrapped in `pcall` with a `warn` | 15 | `installed.unload()` | This script wrote that table. It has `unload` |
| Three `FindFirstChild` guards with three prose errors | 26 | one property chain | `ItemDraggingGUI is not a valid member of PlayerGui` names the exact child |
| `pcall(getsenv, script)` plus an error branch | 11 | direct call | A failure here is a programming error; a stack trace beats a warning |
| Four `typeof` checks and two `islclosure` checks on the fetched functions | 30 | nothing | `debug.getupvalues` on a non-closure raises and says so |
| Five commented-out lines quoting the decompiled `moveDrag` | 8 | one two-line comment | The quote is in the reply, not the file |
| `pcall(debug.getupvalues, ...)` plus error branch | 10 | direct call | Guarded by the assert at the top |
| Index collection into a table, then two multi-clause errors | 26 | `assert` inside the loop | Same guarantee, one line |
| `pcall(debug.setconstant, ...)` plus error branch | 14 | direct call | Same |
| `pcall` around `MaxForce = …` plus a rollback branch with its own `warn` | 30 | one assignment | Type/access errors should surface here; the wrapper offered no useful recovery |
| `Unload` with two `pcall`s, three `warn`s and an `Enabled` flag | 44 | a 6-line closure | Nothing in it can fail |
| `print("… enabled | force=170000")` | 5 | nothing | Shipped code is quiet when it works |

**271 lines removed. Zero behaviour removed.**

---

## The bug the ceremony was hiding

The original reads the threshold constant by searching for `1.2`, then restores
a hardcoded `1.2` in three separate places:

```lua
-- original, three times
pcall(debug.setconstant, clickFunction, autoDropIndex, 1.2)
```

It never captured the value it found. If LT2 ships `1.25`, the script silently
writes `1.2` back on unload and leaves the game subtly modified. The rewrite
keeps what it read:

```lua
for index, constant in getconstants(click) do
    if constant == 1.2 then
        assert(not autoDropIndex, "two candidate thresholds")
        autoDropIndex, autoDropSeconds = index, constant
    end
end
...
setconstant(click, autoDropIndex, autoDropSeconds)   -- the value it actually found
```

This is the argument against ceremony that is not about taste. At 330 lines the
restore path is three widely separated `pcall`s and nobody reads them. At 59 the
mistake is visible.

---

## The rewrite

```lua
-- Raises LT2's drag force and disables its automatic drop.
-- Unload with getgenv().LT2HardDragger.unload().

local Players = game:GetService("Players")

local DRAG_FORCE = 170000
local AUTO_DROP_DISABLED = 1e9

local getgenv, getsenv = getgenv, getsenv
local getupvalues, getconstants, setconstant =
    debug.getupvalues, debug.getconstants, debug.setconstant

assert(
    getgenv and getsenv and getupvalues and getconstants and setconstant,
    "needs getsenv and debug constant access"
)

local installed = getgenv().LT2HardDragger
if installed then
    installed.unload()
end

local draggerScript = Players.LocalPlayer.PlayerGui.ItemDraggingGUI.Dragger
local draggerEnvironment = getsenv(draggerScript)
local click, moveDrag = draggerEnvironment.click, draggerEnvironment.moveDrag

-- LT2 unparents the drag part between drags, so the DataModel cannot be
-- searched for it. moveDrag holds the live BodyPosition as an upvalue.
local bodyPosition
for _, upvalue in getupvalues(moveDrag) do
    if typeof(upvalue) == "Instance" and upvalue:IsA("BodyPosition") then
        bodyPosition = upvalue
        break
    end
end
assert(bodyPosition, "moveDrag holds no BodyPosition")

-- click() drops the object once accumulated failure time passes this constant.
local autoDropIndex, autoDropSeconds
for index, constant in getconstants(click) do
    if constant == 1.2 then
        assert(not autoDropIndex, "two candidate thresholds")
        autoDropIndex, autoDropSeconds = index, constant
    end
end
assert(autoDropIndex, "no drop threshold in click")

local originalMaxForce = bodyPosition.MaxForce

setconstant(click, autoDropIndex, AUTO_DROP_DISABLED)
bodyPosition.MaxForce = Vector3.one * DRAG_FORCE

getgenv().LT2HardDragger = {
    unload = function()
        setconstant(click, autoDropIndex, autoDropSeconds)
        bodyPosition.MaxForce = originalMaxForce
        getgenv().LT2HardDragger = nil
    end,
}
```

Two comments survive. Both state a fact about LT2 that the code cannot show:
the part is unparented, and the constant is a timeout. Everything the original
said about the dump, the upload and the reasoning went into the reply, where it
belongs.

---

## The three lines that carry the design

```lua
local getupvalues, getconstants, setconstant =
    debug.getupvalues, debug.getconstants, debug.setconstant
```

The capability list and the usage list are now the same list. Thirty-eight lines
of `if typeof` can disagree with the code below them; this cannot.

```lua
local draggerScript = Players.LocalPlayer.PlayerGui.ItemDraggingGUI.Dragger
```

Twenty-six lines of `FindFirstChild` guards produced a worse error than the
engine's own. Write the path. When it breaks, Roblox names the exact child that
is missing, at the exact line.

```lua
bodyPosition.MaxForce = Vector3.one * DRAG_FORCE
```

Thirty lines of `pcall` and rollback offered no recovery for this deterministic
write. Invalid property types or access can still raise an engine error.

---

## What to tell the user instead

Everything deleted from the comments is worth saying **once, in the reply**:

> Read the dragger source. It unparents the drag part between drags, so the
> script takes the live `BodyPosition` off `moveDrag`'s upvalue rather than
> searching the workspace. The `1.2` in `click` is the auto-drop timeout —
> patched to `1e9` and restored on unload. Needs `getsenv` and `debug`
> constant access; it asserts on those at the top.

That is the same information, aimed at somebody who asked for it, and it does
not survive into a file where it means nothing.

---

## Related references
- `anti-slop-code.md` — the ten rules and the command
- `roblox-executor/references/technique/source-to-api.md` — why the API choices
  in the original were right, and how to reach them without a fallback chain
- `roblox-executor/references/technique/decompiled-source.md` — reading the dump
