---
name: roblox-register-budget
description: Out of local registers, too many locals, the 200-local limit - long scripts under budget, fixed without scope bugs. Use before long scripts.
---

# Staying under the register limit

A Luau function holds at most **200 live locals** and **255 registers**
(locals plus the temporaries one expression needs). A script over either
limit does not compile, so not even its first line runs. The main chunk of a
script is a function too: every `local` at the top level of a single-file
executor script or UI builder counts against the same 200.

The error arrives late and far from its cause. A hub measured for this skill
had 199 top-level locals and compiled; adding one toggle gave

```
Out of local registers when trying to allocate AnotherToggle: exceeded limit 200
```

on the line of the new toggle, which was not the problem. The problem was
the 198 lines above it. So the budget is a structural decision made before
writing, not a repair made after the error.

## Why generated scripts hit it

| Pattern | Typical count | Write instead |
|---|---|---|
| Keeping every library element: `local SpeedToggle = Tab:CreateToggle({...})` | 60-150 | Drop `local X =` when the value is never used again; keep the few you call later in `ui.speedToggle` |
| One `local function` per feature at the top | 20-50 | `local Features = {}` and `function Features.fly()` |
| One local per setting: `local WALK_SPEED = 16` | 20-60 | One `CONFIG` table |
| One local per remote or child: `local BuyRemote = Remotes:WaitForChild(...)` | 10-40 | `remotes.buy`, filled where the family starts |
| GUI-to-Lua converter output: `local Frame1 = Instance.new("Frame")` | 100-400 | A `make(className, props, children)` helper over a nested table, or one builder function per panel |
| Forward declarations for mutual calls: `local a, b, c, d` | 5-30 | Fields of one table, declared as needed |

In the measured hub, the tool's breakdown of those 199 locals was 113 library
elements (103 never used again), 40 literal settings, 30 child lookups, 12
local functions and 3 services. The rewrite in
[hub-rewrite.md](references/hub-rewrite.md) has 9 top-level locals and peaks
at 16 registers, with every toggle still built.

## The shape to write from the start

Any script expected past about 150 lines starts with handles, not items:

```lua
local Players = game:GetService("Players")

local CONFIG = {
	walkSpeed = 32,
	farmInterval = 0.5,
}

local state = {
	farming = false,
}

local ui = {}
local remotes = {}
local Features = {}

function Features.autoFarm(on: boolean)
	state.farming = on
end

local function buildFarmTab(window)
	local tab = window:CreateTab("Farm")
	tab:CreateToggle({ Name = "Auto farm", CurrentValue = false, Callback = Features.autoFarm })
end
```

The rules behind it:

1. **The main chunk holds families, never members.** Services, one `CONFIG`,
   one `state`, one `ui`, one `remotes`, one `Features`, the session and the
   builder functions. Not one local per button, setting, remote or colour.
2. **Each tab, panel or feature is built by a `local function`.** A function
   gets its own 200, so its locals leave the main chunk entirely.
3. **A value used once is not stored.** A toggle whose return value nothing
   reads is a call statement, not a local.
4. **One-shot setup goes in `do ... end`**, so its temporaries die at `end`.
5. **Name fields as carefully as locals.** `ui.shopFrame`, `CONFIG.walkSpeed`;
   never a bag called `data` or `vars`.

Table fields read with a literal name (`CONFIG.walkSpeed`) are cached by the
VM and cost nothing measurable outside a hot loop;
`roblox-luau-language/references/compiler-limits.md` has the detail.

## Counting without a compiler

When no tool can run, count the lines that start with `local ` in column 0.
That is the main chunk's local count, near enough. **Past 120, restructure
before adding anything**; the compiler also needs registers for temporaries,
and the next edit should not be the one that breaks it. Inside one function,
count its locals and parameters: past 80, split it.

## Measuring

```bash
node tools/bin/check-registers.mjs <file.luau>
python tools/py/register_budget.py <file.luau>
```

It compiles the file at `-O0` and reports, with line numbers:

| Code | Meaning |
|---|---|
| `E-COMPILE` | The file does not compile; names which of the six limits and its fix |
| `W-REGISTERS` | A function peaks at 160 registers or more: one edit from failing |
| `I-LOCALS` | When the main chunk is full, which families its top-level locals fall into, largest first, and how many library elements are never used again |
| `W-SCOPE` | A name declared `local` in the file is read or written as a global elsewhere, so it is nil at runtime |
| `W-UPVALUES` | A closure captures 160 or more outer locals |

`check-file` runs it with the other gates. Report the numbers before and
after a change: `main chunk 206 -> 16 registers`.

## Fixing a script that already fails

1. Read the error: `Out of local registers` is the 200-local limit;
   `Out of registers` is one wide expression on top of many locals; the rest
   are in `compiler-limits.md`. The line named is where the budget ran out,
   rarely where the problem is.
2. Run the checker and read `I-LOCALS`. Move the largest family first.
3. Delete `local X =` from library elements nothing reads. Search each name,
   whole word, before deleting.
4. Move settings into `CONFIG`, lookups into `remotes` or `ui`, feature
   functions into `Features`, one family per pass, names unchanged apart from
   the prefix, so the diff reads as a rename.
5. Move each tab's construction into a builder function.
6. Compile after every pass and read `W-SCOPE`. Then report both counts.

Keep the user's names and structure otherwise. A register fix that also
renames and reformats is a diff nobody can review.

## The fix that breaks the script

Moving locals into a `do` block or a function shortens their lives, which is
the point, and also hides them from any code outside that block. A use left
outside **compiles as a global read and is nil at runtime**, with no error
until that line runs. `W-SCOPE` reports each one:

```
7: W-SCOPE `shopFrame` is declared local at line 4 but used here outside that
scope, so it reads a global that is nil; keep it in a table both places can see
```

Two related mistakes: wrapping the whole script in one `do ... end` changes
nothing, because every local inside is still alive at once; and dropping
`local` to make values global "fixes" the error by making every access slower
and leaking the script's state into the executor's global table.

## In an executor

A script loaded with `loadstring(source)()` that fails to compile does not
show the compile error. `loadstring` returns `nil` and the message, and the
trailing `()` then fails with `attempt to call a nil value`. To see the real
error:

```lua
assert(loadstring(game:HttpGet(SCRIPT_URL)))()
```

`assert` passes the chunk through, or raises the compile message itself.
Pasting the script into the executor's editor also shows it directly.

## Works with

- `roblox-luau-language`: every compiler limit, the six errors and their fixes.
- `roblox-code-craft`: names for the tables the locals move into.
- `roblox-executor-quality`: the premium script template, built to this shape.
- `roblox-hub-library`: element returns you keep versus the ones you drop.
- `roblox-ai-mistakes`: the other defects generated scripts share with this one.
- `roblox-debugging`: `attempt to call a nil value` and what else it can mean.
