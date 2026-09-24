# Anti-slop code — the mechanical rules

`naming.md` and `diagnostics.md` explain the reasoning. This file is the part a
model can apply without judgement, and there is a command that counts it:

```powershell
node tools/bin/lint-luau-slop.mjs path/to/Script.luau
python tools/py/roblox_lint.py path/to/Script.luau      # identical rules, no Node
```

Exit 1 means at least one rule below was broken. Twelve rows, two points each.
**Every file this stack ships scores 24/24.** A generated script that has not
been through these rules typically scores 4 to 12.

`tools/bin/lint-parity.mjs` runs every Luau file in the repo through both
implementations and fails on any difference in code, line or message, so the
Python port cannot quietly drift into agreeing with nothing.

Run it on code before delivering it. Not "consider whether the code follows
this" — run the command, read the findings, fix them, run it again.

---

## The ten rows

| # | Row | Rule | Codes |
|---|---|---|---|
| 1 | Header | A script gets **≤ 4** header comment lines. A module gets **≤ 24**, and only for decisions the code cannot show | `E-HEADER` |
| 2 | Provenance | **Zero** comments about where the code came from | `E-PROVENANCE` |
| 3 | Commented-out code | **Zero** lines of Lua inside a comment | `E-QUOTE` |
| 4 | Restatement | **Zero** comments repeating the line below, **zero** bare section labels | `E-RESTATE`, `W-LABEL` |
| 5 | Capability checks | **≤ 2** `if typeof(x) ~= "function"` statements per file | `E-CAPCHECK` |
| 6 | `pcall` | **Zero** `pcall`s around something that cannot raise; **≤ 1 per 25 lines** | `E-PCALL-INFALLIBLE`, `W-PCALL-DENSITY` |
| 7 | Messages | **≤ 12 words**, one clause, no pleading, no `!` | `E-ERRPROSE`, `W-EMOJI` |
| 8 | Repeated prefix | A literal prefix used **≥ 3** times is a constant | `E-PREFIX` |
| 9 | Naming | No generic names, no bad abbreviations, no digit suffixes | `W-GENERIC`, `W-ABBREV`, `W-NUMSUFFIX` |
| 10 | Noise | No success `print`, no unnamed repeated number, no banner in a short file, no `TODO` | `W-SUCCESSPRINT`, `W-MAGIC`, `W-BANNER`, `W-DENSITY`, `E-TODO` |
| 11 | Clauses | **Zero** clauses inside a surviving comment that are built from the identifiers below them | `E-CLAUSE` |
| 12 | One API per job | **≤ 2** executor value layers, **≤ 5** distinct executor functions, no `or` across two layers | `E-LAYERCHAIN`, `W-EXECSURFACE` |

Row 9 also fails on a decompiler slot number surviving as a name - `v14`, `u3`,
`p1` - under `E-DECOMPNAME`.

---

## 1. The header

A **script** — anything that runs when it loads — gets no header, or at most
four lines saying what it does and what it needs. It has no public surface and
no caller to inform.

A **module** may carry up to twenty-four lines, and only these three things:

- what the module is for, in one line
- the decisions a reader would otherwise reverse, and why
- constraints the type signatures cannot express

A header may never contain: a changelog, a summary of the code below, where the
code came from, what the previous attempt did, or an account of the reasoning
that produced it.

---

## 1a. Four lines is the cap, not the target

The header budget caps how *many* lines there are. It says nothing about what
they are allowed to be about, and four lines of nothing passes it:

```lua
-- WRONG, and it scores inside the budget
-- NotificationDemo.client.lua
-- This interface is client-owned and never stores authoritative game state.
-- The close image is Roblox Creator Hub asset 5577404210.
-- Connections and delayed threads are torn down with the ScreenGui.
```

Line by line:

| Line | Why it is noise |
|---|---|
| the file name | the file already has one, and a rename leaves this lying |
| "client-owned, never stores authoritative state" | true of every file here. A rule, not a fact about this one |
| "the close image is asset 5577404210" | `local CLOSE_IMAGE = "rbxassetid://5577404210"` is four lines below |
| "connections and threads are torn down" | there is a `cleanup()` function that does exactly this |

Every one restates something already in the file, so every one goes stale the
moment that thing changes — and nothing will fail when it does.

**A header line answers a question the reader cannot answer by reading the
file.** Usually that means it comes from outside the file: the game's
behaviour, an engine quirk, a constraint someone hit.

```lua
-- RIGHT
-- LT2 parents its drag helper to Workspace only while a drag is live.
-- click() drops the object when the Humanoid state reads Freefall.
```

Neither is visible from the code. Both stay true whatever you rename.

### The four forms the linter fails

`E-FILENAME` and `E-HEADERSUMMARY` catch:

- a comment that is only a file name
- a line starting `Handles...`, `Manages...`, `Creates...`, `Sets up...` — a
  docstring summary of the code beneath it
- a line starting `This script / module / interface / UI...`
- architecture boilerplate: `client-owned`, `server-authoritative`,
  `never stores authoritative`, `client-side only`
- `connections / threads / tweens are torn down / cleaned up / disconnected`

It deliberately does **not** try to catch "the close image is asset 5577404210"
by pattern, because that shape collides with a legitimate header line — the
origin of a magic number. `-- 1.2 is the failure time LT2 waits before
dropping` contains a constant that is also in the code, and it earns its line.
The difference is whether the comment adds a *source or reason*. Restating what
a named constant already says does not.

### The test

Delete the header. Does a competent reader now have to open another file, run
the game, or ask you something to understand this one? If not, the header was
not carrying anything.

---

## 2. Provenance is the loudest tell

```lua
-- WRONG
-- Based on the uploaded Dragger.client.luau.
--
-- Source-established behavior:
--   script.Dragger starts beneath the LocalScript.
--
-- Because of that, this version retrieves the BodyPosition from moveDrag's
-- captured upvalue instead of searching for it.
```

Every line of that is addressed to somebody who was in the conversation. The
file is opened six months later by somebody who was not.

**Where it goes instead:** the reply. "I read the dragger source — it unparents
the part between drags, so the script reads the BodyPosition off `moveDrag`'s
upvalue" is a useful sentence *to the user*. In the file it is noise.

What survives into the file is the one fact the code cannot show:

```lua
-- RIGHT
-- LT2 unparents the drag part between drags, so the DataModel cannot be
-- searched for it. moveDrag holds the live BodyPosition as an upvalue.
```

One sentence, no history, no audience of one.

The linter flags: `based on the uploaded`, `the supplied source`, `the dump
shows`, `source-established`, `as requested`, `per your`, `you provided`, `this
version`, `note that`, `I have`, and their neighbours.

---

## 2a. Editing someone's file is its own failure mode

Everything above applies to writing a file. Changing one adds a second habit,
and it is the one users report most: a working script comes back correct and
covered in a running commentary about the repair.

```lua
-- WRONG
-- Fixed: the nil check was missing here.
local humanoid = character:FindFirstChildWhichIsA("Humanoid")

-- Changed the tween to Quad; Linear looked mechanical.
local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

-- Removed the old polling loop - see below.
-- while true do task.wait(0.1) ... end
```

Those three comments are addressed to the person who asked for the fix, in the
ten minutes after they asked. **The diff already says all of it**, in a place
that stays correct when the next edit lands. A comment does not: six edits
later `-- Fixed: the nil check was missing here` is describing a nil check that
somebody has since deleted.

The linter flags a comment that **begins** with an edit verb — `Fixed:`,
`Changed`, `Updated the`, `Added a`, `Removed`, `Renamed`, `New:`, `Was:` — and
the phrases `in this fix`, `previously this`, and `kept for backwards
compatibility`.

It deliberately does not flag the same words mid-sentence, because those are
usually facts:

| Fires | Does not fire |
|---|---|
| `-- Added the fallback path.` | `-- The part is no longer parented while idle.` |
| `-- Fixed: missing nil check.` | `-- Roblox now uses ScreenInsets; IgnoreGuiInset predates it.` |
| `-- Previously this looped forever.` | `-- Retries once; the remote drops the first call after a teleport.` |

The right-hand column earns its place because each line is true about the game
or the engine regardless of who edited what. That is the test.

### The rest of the edit discipline

| Rule | Why |
|---|---|
| **Touch the smallest region that fixes it** | A diff that also reflows 200 lines cannot be reviewed, so it gets approved unread |
| **Do not reformat lines you did not change** | Same reason. Whitespace churn hides the one real line |
| **Do not rename things you were not asked to** | A rename is a separate change with separate risk |
| **Do not delete a comment you do not understand** | It may be the only record of a bug somebody already hit |
| **Leave no commented-out old version** | That is what version control is |
| **Do not bump a version number in the header** | Nothing keeps it true |

### What to say instead

The narration is not worthless — it is in the wrong place. It belongs in the
reply, once, in past tense, and it should be shorter than the diff:

> The nil check was the crash: `FindFirstChildWhichIsA` returns nil during the
> respawn frame. I moved the guard above the connection rather than inside the
> callback, so it runs once instead of every frame.

That sentence does the job the three comments were trying to do, for the one
person who needs it, at the one time they need it.

### When a comment about the change *is* right

One case: the change is surprising and the reason will not survive in anyone's
memory. Then the comment records **the constraint, not the edit**.

```lua
-- RIGHT
-- Runs on PreSimulation, not Heartbeat: the drag goal is read by the physics
-- step, and Heartbeat lands after it by one frame.
RunService.PreSimulation:Connect(step)
```

No `Changed from`, no `Fixed`. Somebody reading this in a year learns why the
line is what it is, and never needs to know it used to be something else.

---

## 3. What a comment is allowed to say

A comment earns its line by containing a fact **not in the code**. In practice
that is one of five things:

| Allowed | Example |
|---|---|
| Where a magic number came from | `-- 0.35s is the fire rate the source showed.` |
| A workaround for an engine quirk | `-- Reversed: knockback removes entries mid-iteration.` |
| An ordering requirement | `-- Must run before the Heartbeat loop binds.` |
| An invariant the types cannot say | `-- Callers never hold this past the frame.` |
| A deliberate deviation | `-- Activated, not MouseButton1Click: gamepad.` |

Everything else is deleted. In particular:

```lua
-- WRONG, all four
-- Executor capability checks          <- a label, not a fact
-- Get the player                      <- restates the line
-- Loop through the players            <- restates the line
-- pcall returns a boolean first       <- explains the language
```

**The test:** cover the code with your hand. If the comment still tells you
something, keep it. If you need the code to understand the comment, the comment
is restating it.

---

## 3a. The clause, not the comment, is the unit

`E-RESTATE` scores a comment as one block, which a four-line comment can pass by
dilution: one load-bearing line and three of restatement average out under the
threshold.

```lua
-- WRONG. Line one is real. Lines two and three are the code, spelled twice.
-- LT2 rebuilds the dragger between drags, so the panel must reparent first.
-- Create the tween info for the panel.
-- Then play the tween on the panel.
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local tween = TweenService:Create(panel, tweenInfo, { GroupTransparency = 0 })
tween:Play()
```

```lua
-- RIGHT
-- LT2 rebuilds the dragger between drags, so the panel must reparent first.
```

**A four-line comment with one load-bearing line is one line long.** `E-CLAUSE`
splits each comment on sentence and connective boundaries, skips any clause
carrying a cause or a contrast, and fails the rest when three-quarters of their
content words appear as identifiers in the six code lines below.

The same test applies to a clause hiding inside one sentence. "Reversed, because
knockback removes entries mid-iteration" is one clause doing work. "Loop through
the targets in reverse, so we iterate backwards" is one clause doing work and
one repeating it.

---

## 4. Defensive code: check once, at the boundary

This is where generated Luau gets fattest, and the fix is a rule with a number
in it.

### The one-guard pattern

```lua
-- WRONG: 38 lines
local missing = {}
if typeof(getgenv) ~= "function" then
    table.insert(missing, "getgenv")
end
if typeof(getsenv) ~= "function" then
    table.insert(missing, "getsenv")
end
-- ... five more ...
if #missing > 0 then
    error("MyScript: executor is missing: " .. table.concat(missing, ", "), 2)
end
```

```lua
-- RIGHT: 5 lines, and the calls get faster because they are now locals
local getsenv, getupvalues, setconstant =
    getsenv, debug.getupvalues, debug.setconstant

assert(getsenv and getupvalues and setconstant, "needs getsenv and debug access")
```

Bind what you use at the top. Assert once. The list of names in the `local` line
*is* the capability list, and it cannot drift out of step with the code the way
a hand-written check list can.

### What to check, and what never to check

| Situation | Check? |
|---|---|
| An executor function you are about to call | **Yes** — once, in the bind above |
| A remote's arguments, before `FireServer` | **Yes** — the server will reject silently otherwise |
| Data coming back from a DataStore or HTTP | **Yes** — it genuinely can be anything |
| A user-facing function's arguments | **Yes** — `error(msg, 2)`, one line |
| A value you assigned three lines above | **No** |
| That `Instance.new` returned an Instance | **No** |
| That a closure you just fetched is a closure | **No** — the call that needs it will say so |
| That a deterministic property write succeeded | **No** — let type/access errors surface at their source |
| An `:IsA` on something the path already proves | **No** |

### `pcall` wraps a boundary, not a statement

```lua
-- WRONG: this wrapper replaces the useful engine error without recovery.
local forceOk, forceError = pcall(function()
    bodyPosition.MaxForce = Vector3.one * DRAG_FORCE
end)
if not forceOk then
    error("could not set MaxForce: " .. tostring(forceError), 2)
end
```

```lua
-- RIGHT
bodyPosition.MaxForce = Vector3.one * DRAG_FORCE
```

`pcall` is for things that cross out of your control: a DataStore call, an HTTP
request, `require` of somebody else's module, `getsenv` on a script that may be
gone, a decompile. Properties, constructors and arithmetic can raise on invalid
inputs or access. Do not catch those deterministic errors merely to hide them.
When an external lifecycle boundary can fail, explain the recovery and check
the result; a capability's existence alone does not guarantee a call succeeds.

**Let the engine's error stand.** `Players.LocalPlayer.PlayerGui.ItemDraggingGUI`
already fails with `ItemDraggingGUI is not a valid member of PlayerGui`, which
names the exact missing child. Three hand-written `FindFirstChild` checks with
three hand-written messages produce a worse error in more lines.

### Never write a rollback for something that cannot fail

If step two cannot raise, step one needs no undo path. A rollback branch that
cannot execute is a branch that has never been tested, sitting in the file
looking load-bearing.

---

## 5. Message wording

Twelve words. One clause. Name the value.

```lua
-- WRONG
error("MyScript: PlayerGui was not found; execute after the game finishes loading", 2)
error("MyScript: found 3 copies of the constant; refusing to patch an ambiguous build", 2)

-- RIGHT
error("no PlayerGui", 2)
error(("ambiguous: %d candidate constants"):format(count), 2)
```

The second clause is always advice, and advice in an error string is a guess
about why it failed. The reader has the stack trace; you do not.

**A prefix repeated three times is a constant.** If fifteen messages start with
`"LT2 Hard Dragger: "`, that is a string that was typed fifteen times and will
be edited in fourteen places.

```lua
local LOG_PREFIX = "[dragger] "
error(LOG_PREFIX .. "no PlayerGui", 2)
```

**No `print` on success.** Shipped code is quiet when it works. A script that
announces `"enabled | force=170000"` on every execute is training its user to
ignore the output window, which is where the next real warning will appear.

---

## 6. Names, mechanically

Three checks that need no taste:

1. **Would the name fit unchanged in another project?** Then it is generic.
   Flagged: `data`, `temp`, `obj`, `val`, `info`, `stuff`, `payload`, `cfg`,
   `ctx`, `helper`, `manager`, `util`, `handler`, `res`, `ret`.
   `local ok, result = pcall(...)` is exempt — it is the house idiom.
2. **Is it an abbreviation?** Spell it out. Flagged: `plr`, `chr`, `pos`, `cnt`,
   `tbl`, `str`, `num`, `idx`, `btn`, `txt`, `dmg`, `lvl`, `amt`, `inst`.
   `id`, `ui`, `hp`, `npc`, `cframe` are read as words and are fine.
3. **Does it end in a digit?** `data2`, `handleClick2` encode edit history, not
   meaning. Name the difference.

Working from decompiled source adds a fourth, and it is the one that matters
most there: **the decompiler's names are not names.** `v14`, `u3`, `p1` are slot
numbers the decompiler printed because the real names were compiled away.
Carrying them into your script means nobody — including you next week — can read
it. `E-DECOMPNAME` fails on every one.

Rename each from what the source proved it holds: `v14` that gets
`:FireServer("Combat")` called on it is `combatRemote`.

**And no further than that.** If the source only showed `v14` being fired with
one string argument and never showed what the server does with it, the honest
name is `combatRemote`, not `damageRemote` — the second claims something the
dump never established, and the next reader will believe it. A name that is a
lie costs more than a name that is obviously provisional; where the source
established nothing, `unknownRemote` is a better name than a confident wrong
one, and it tells the next reader exactly what to go and find out.

---

## 6a. One API per job, counted

`E-LAYERCHAIN` counts the **value layers** a file reaches into. They are
different objects reached by different mechanisms, not alternative routes to one
object:

| Layer | Functions |
|---|---|
| upvalue | `debug.getupvalues`, `debug.setupvalue` |
| constant | `debug.getconstants`, `debug.setconstant` |
| environment | `getsenv`, `getrenv`, `getfenv`, `setfenv` |
| heap | `getgc`, `filtergc`, `getinstances`, `getloadedmodules` |
| hook | `hookfunction`, `hookmetamethod`, `replaceclosure` |
| connection | `getconnections`, `firesignal`, `replicatesignal` |

Two rules, both failing as errors:

- **An `or` between two layers on one line.** `local reach = getsenv or getgc`
  is not a fallback; it is two different lookups, and after a game update the
  script silently takes the other branch and reports success.
- **Three or more layers in one file.** Two is a hook plus a read. Three is
  guessing, and the fix is to go back to the dump.

`W-EXECSURFACE` warns past five distinct executor functions in one file.
Aliases for the same function - `getcustomasset` and `getsynasset`, `gethui` and
`get_hidden_gui` - count once, because two names for one call is not two places
to look.

Full reasoning, with the layer-to-call table:
`roblox-executor/references/technique/source-to-api.md`.

---

## 7. What this is not

This is not a disguise, and it is not a style preference. Each rule above is a
readability or correctness cost on its own:

- The 330-line version of the dragger restored a hardcoded `1.2` on unload
  instead of the value it read. The 50-line version captured it, because there
  was room to see the bug.
- Ten capability checks drift; one bind cannot.
- `pcall` around a property write turns a typo into a warning.
- A repeated literal prefix is fourteen future edits.

**Shorter is not the goal.** Fewer unexamined lines is. Write the code the task
needs, then delete everything that is talking rather than working.

---

## Related references
- `slop-rewrite.md` — a full 330-line script cut to 50, line by line, with scores
- `naming.md` — the reasoning behind row 9
- `diagnostics.md` — the reasoning behind rows 5, 6 and 7
- `code-signature.md` — matching an existing file, the nine-tell catalogue
- `roblox-executor/references/technique/source-to-api.md` — picking one API from
  what the source proves, instead of a fallback chain
- `roblox-ui/references/anti-slop-catalog.md` — the interface equivalent
