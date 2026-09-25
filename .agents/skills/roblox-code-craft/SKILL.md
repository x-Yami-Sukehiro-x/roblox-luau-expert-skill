---
name: roblox-code-craft
description: How Roblox Luau code should read - names, errors, comments, pcall discipline, formatting, the ceremony budget, removing AI-generated slop, matching an existing file. Use when writing or reviewing any Luau, or when code looks AI-made.
---

# Code craft

Correctness is the other skills' job. This one is about code someone can
navigate and fix six months later.

| Topic | File |
|---|---|
| **the counted rules, and the command that runs them** | `references/anti-slop-code.md` |
| **how the file is laid out** — breaks, blank lines, width | `references/formatting.md` |
| a 330-line script cut to 59, line by line | `references/slop-rewrite.md` |
| what to call things | `references/naming.md` |
| errors, warns, prints, comments | `references/diagnostics.md` |
| matching an existing file, the tell catalogue, the review pass | `references/code-signature.md` |

---

## Run this before delivering Luau

```powershell
node tools/bin/lint-luau-slop.mjs path/to/Script.luau
node tools/bin/lint-luau-format.mjs path/to/Script.luau
python tools/py/roblox_lint.py path/to/Script.luau     # same rules, no Node
python tools/py/format_lint.py path/to/Script.luau
```

The second one is newer and answers a complaint the first cannot see: code that
is correct, commented correctly, and **laid out** like nothing a Roblox
developer would hand over — `local x =` on its own line above a 40-column call,
two blank lines between every statement, or forty statements with none. Details
and the before/after: `references/formatting.md`.

Exit 1 means the file broke a rule below. It scores out of 24. Everything this
stack ships scores 24/24; a generated script that has not been through the rules
typically scores 4 to 12.

The Python file is a port, not an approximation: `tools/bin/lint-parity.mjs`
runs every Luau file in the repo through both and fails on any difference in
code, line or message. It exists because the host that most needs these rules -
a custom GPT, whose Code Interpreter is Python with no Node - could not run the
Node one, so every instruction saying "run the counter" was advice it could not
take.

### Claiming the file is fixed

**A claim needs a command in the same reply.** "Cleaned up", "fixed",
"rewritten" and "now passes" are all falsifiable, and the way to falsify them is
cheap:

```powershell
node tools/bin/lint-luau-slop.mjs --compare before.luau after.luau
```

It prints score, line count, comment count, header lines, capability checks,
`pcall`s, value layers and executor surface, before against after, and then how
many of those rows moved. **`0/9 counted rows moved` means these metrics did
not change**. Inspect the diff for behavioral changes; a counter does not
measure every possible repair. Report evidence for the claimed improvement.

**Run the command.** Do not decide from reading whether the code complies — that
is the check this stack already tried, and it is why a model can report "follows
the comment policy" above a thirteen-line provenance header.

### The budget, as numbers

| Thing | Limit |
|---|---|
| Header comment lines, script | 4 |
| Header comment lines, module | 24 |
| Comments about where the code came from | 0 |
| Lines of Lua inside a comment | 0 |
| Comments restating the line below | 0 |
| Clauses within a comment built from the identifiers below it | 0 |
| Decompiler slot numbers surviving as names (`v14`, `u3`, `p1`) | 0 |
| `if typeof(x) ~= "function"` statements per file | 2 |
| `pcall`s around something that cannot raise | 0 |
| `pcall`s | 1 per 25 lines |
| Words in an error or warn message | 12 |
| Clauses in an error message | 1 |
| Times a literal prefix may be typed | 2 |
| `print`s announcing success | 0 |
| Executor value layers reached in one file | 2 |
| Distinct executor functions in one file | 5 |

Full rules, with the reasoning and the counter-examples, in
`references/anti-slop-code.md`.

---

## The primacy rule

**Match the file you are editing.** Its existing conventions beat the official
style guide, which beats every default below.

A correctly-styled function that looks nothing like its neighbours is worse than
a slightly-off one that blends in, because mixed conventions in one file are
what make a codebase hard to patch. Read enough surrounding code to see the
casing, the comment density, the error style and the log prefixes actually in
use, then mirror them.

If a file's convention is genuinely harmful — a naming scheme that hides bugs, a
`pcall` habit that swallows errors — say so once, plainly, and then either fix it
throughout or follow it. Do not silently diverge in one function.

---

## Defaults for new files

| Kind | Casing | Example |
|---|---|---|
| locals, functions, members | `camelCase` | `applyReloadPenalty` |
| services, modules, class-likes | `PascalCase` | `ReplicatedStorage`, `Inventory` |
| constants | `LOUD_SNAKE_CASE` | `MAX_INVENTORY_SLOTS` |
| private members | `_camelCase` | `_sessionToken` |
| type names | `PascalCase` | `type WeaponConfig` |

Booleans read as assertions: `isReloading`, `hasKey`, `canPurchase`.
Functions read as actions: `grantItem`, `resolveHit`, `findNearestTarget`.
Predicates that return a boolean read as questions: `isOnCooldown(player)`.

**Spell words out.** `character` not `char`, `position` not `pos`, `remaining`
not `rem`. The tokenizer does not reward you for the short version and the
reader pays for it every time.

Standard domain abbreviations are fine because they are read as words: `id`,
`ui`, `hp`, `npc`, `cframe`.

---

## The ubiquitous-language test

**If an identifier would fit unchanged in another project, it is too generic.**

| Generic | Specific |
|---|---|
| `processData` | `applyReloadPenalty` |
| `handleEvent` | `onPurchaseRequested` |
| `Manager` | `RoundScheduler` |
| `Utils` | `CFrameMath`, `StringFormat` |
| `doThing` | `advanceCheckpoint` |
| `temp`, `data`, `info`, `obj` | the actual noun from the game |

Names come from the game's own vocabulary. If the design document calls it a
"rebirth", the function is `performRebirth`, not `resetProgressLevel`.

`Manager`, `Helper`, `Util`, `Handler`, `Service` and `Data` as a suffix are all
signals that the module owns more than one thing, or that its owner was not
named. That is a design smell surfacing as a naming smell.

---

## Errors and warnings

**Return failure for expected conditions. Throw for programming mistakes.**

```lua
-- expected: the caller decides what to do
local function loadProfile(userId: number): (boolean, PlayerData | string)
    local ok, result = pcall(function() return store:GetAsync(tostring(userId)) end)
    if not ok then return false, tostring(result) end
    return true, result
end

-- programming mistake: blame the caller's line
local function grantItem(player: Player, itemId: string)
    if typeof(itemId) ~= "string" then
        error("grantItem expects a string itemId, got " .. typeof(itemId), 2)
    end
end
```

**`error(msg, 2)` blames the caller's line, not yours.** Level 1 (the default)
points at the `error` call itself, which is almost never where the bug is. Use
level 2 in every argument-validation throw.

**Messages name the failing value and the subsystem.**

```lua
-- useless
error("invalid input")
warn("failed")

-- useful
error(("grantItem: unknown itemId %q"):format(itemId), 2)
warn(("[data] save failed for %d: %s"):format(userId, tostring(err)))
```

A consistent `[subsystem]` prefix makes the output window filterable, which is
worth more than it looks when four systems are logging at once.

**`print` for development trace, `warn` for recoverable problems, `error` for
"this must not continue".** Shipped code should have very few `print`s; a noisy
output window trains everyone to ignore it, including you when it matters.

---

## `pcall` discipline

```lua
-- WRONG: result is the ERROR MESSAGE when the call fails
local _, data = pcall(getData)

-- RIGHT
local ok, result = pcall(getData)
if not ok then
    warn(("[data] getData failed: %s"):format(tostring(result)))
    return nil
end
```

`local _, ` before a `pcall` is always a defect. So is a `pcall` whose failure
branch does nothing — if the failure genuinely does not matter, say so in a
comment, because the next reader will assume it was an oversight.

Wrap the smallest thing that can fail. A `pcall` around fifty lines tells you
something broke but not what.

---

## Comments

**Why, never what - and per clause, not per comment.**

A comment is not scored as a block. Each clause inside it earns its own line, so
a four-line comment whose first line carries a real constraint and whose next
three respell the code is a one-line comment with three lines of padding. That
is what `E-CLAUSE` counts, and it is the form that survives every rule written
as "comment the why": the why is there, with the what stapled underneath it.


<!-- lint: fragment -->
```lua
-- WRONG
-- loop through the players
for _, player in Players:GetPlayers() do

-- RIGHT
-- Reversed: applying knockback can remove the player from the list mid-iteration.
for i = #targets, 1, -1 do
```

Comment the non-obvious: a magic number's origin, a workaround for an engine
quirk, a deliberate deviation, an ordering requirement, an invariant the code
cannot express.

Delete comments that restate the line below. Delete commented-out code — that is
what version control is for. Delete `TODO`s you are not going to do.

A short block comment above a public function explaining its contract is worth
writing. Line-by-line narration is not.

---

## Tells that read as machine-written

The full catalogue is in `references/code-signature.md`. The ones that come up
most in Roblox code:

1. **Comment on every line**, restating it.
2. **Generic names** — `data`, `result`, `temp`, `item` where the domain has a
   real word.
3. **Defensive code for impossible cases** — nil-checking a value assigned three
   lines above.
4. **Over-abstraction** — an interface with one implementation, a config table
   for a value used once, a factory that constructs one thing.
5. **Uniform structure everywhere** — every function the same length, every
   module the same shape, regardless of what it does.
6. **Ceremonial section banners** in a 20-line file.
7. **`print` statements narrating success** — `print("Successfully initialized!")`.
8. **Emoji and exclamation marks** in error strings.
9. **Explaining the language** — `-- pcall returns a boolean`.
10. **Provenance narration** — `-- Based on the uploaded X`, `-- Source-established
    behavior:`, `-- This version retrieves…`. Written to somebody who was in the
    conversation, read by somebody who was not. This is the loudest one in
    practice, and `lint-luau-slop.mjs` fails on it.

None of this is about disguise. It is that each of these is independently a
readability cost, and code carrying several of them is measurably harder to
work with.

**The counter is not to manufacture inconsistency.** It is to make each decision
for a reason and let the variation follow from that.

Nine of these ten are countable, and `references/anti-slop-code.md` is where the
counting is defined.

---

## Before code leaves

The full checklist is `roblox-luau-expert/references/delivery-checklist.md`. The
craft subset:

- [ ] Matches the conventions of the file it is going into.
- [ ] Every name would be wrong in a different project.
- [ ] Argument validation uses `error(msg, 2)`.
- [ ] Every error and warn names the failing value.
- [ ] Every `pcall` binds and checks the first return.
- [ ] No comment restates the line below it.
- [ ] No unused `require`, no unreferenced function, no leftover `TODO`.
- [ ] No abstraction without a second real caller.
- [ ] Nothing defends against a case that cannot occur.
- [ ] `node tools/bin/lint-luau-slop.mjs <file>` exits 0.
- [ ] Editing an existing file: no comment narrates the change. The diff does
      that, and stays right when the next edit lands.

## Works with

- `roblox-reply-craft`: how the finished file is handed over.
- `roblox-luau-language`: types and language features the code relies on.
- `roblox-attempt-memory`: fix stories go in the ledger, never in comments.
