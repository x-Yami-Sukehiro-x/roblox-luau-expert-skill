# Naming — what to call things

Names are the index into a codebase. When something breaks at 2am, the name is what tells you where to look. Generic names remove that index and leave you reading every function to find the one that matters.

> **The existing file wins.** Everything below is the default for *new* code. If the file you are editing already has a convention, match it — see `code-signature.md`. A correctly-styled function that looks nothing like its neighbours is worse than a slightly-off one that blends.

---

## Casing

From the official Roblox Lua style guide.

| Kind | Case | Example |
|---|---|---|
| Local variables, member values, functions | `camelCase` | `playerHealth`, `getEquippedTool` |
| Class / enum-like objects, **all Roblox APIs** | `PascalCase` | `PlayerController`, `ReplicatedStorage` |
| Local constants | `LOUD_SNAKE_CASE` | `MAX_STACK_SIZE`, `RELOAD_SECONDS` |
| Private members | `_camelCase` | `_pendingWrites` |

```lua
local Players = game:GetService("Players")          -- service: PascalCase
local InventoryStore = require(script.InventoryStore) -- module: PascalCase
local MAX_SLOT_COUNT = 36                            -- constant

local equippedTool = nil                             -- local data: camelCase
local function getSlotFor(itemId: string) end        -- function: camelCase
```

### The required-module ambiguity, settled

The style guide says PascalCase for class-like objects; community practice uses PascalCase for required modules and services. They agree in most cases but leave one gap. The rule:

- **PascalCase** when it is a class, module, or service — a *thing with behaviour*.
- **camelCase** when it is data — a config table, a cached lookup, a plain record.

```lua
local ProfileStore = require(Shared.ProfileStore)    -- module with behaviour
local weaponConfig = require(Shared.weaponConfig)    -- plain data table
```

### Acronyms — the rule most people get wrong

**Capitalize minimally**: `aJsonVariable`, `MakeHttpCall`, not `aJSONVariable` or `MakeHTTPCall`.

**Exception**: when the abbreviation is a *set of things* rather than a word, treat it as a full word — `anRGBValue`, `GetXYZ`. `RGB` is red-green-blue, three things; `Json` is one word said as a word.

---

## Spell words out

The style guide's line is *"Spell out words fully! Abbreviations generally make code easier to write, but harder to read."* That is a measured cost, not a preference.

From a study of 72 professional developers locating defects in real code:

- Full-word identifiers → **19% faster defect location** than single letters or abbreviations.
- **No significant difference between single letters and abbreviations.** Shortening `count` to `cnt` buys you nothing that `c` wouldn't — you pay the full readability cost for a fraction of the typing saved.
- The effect is strongest for **experienced** developers. The people best equipped to fix your code are the ones most slowed down by short names.

Second reason, from Ottinger: **short names aren't greppable.** You cannot search a codebase for `v`. You can search it for `equippedTool`.

```lua
-- Costs a reader time on every encounter
local ts, mh, dmg = ...

-- Costs the writer three seconds, once
local timestamp, maxHealth, damage = ...
```

Single letters are fine in one place: loop counters and iteration variables in short scopes. `for index, tool in tools do` is idiomatic. `local t = ...` at file scope is not.

---

## Naming grammar

### Booleans read as assertions

Prefix with `is`, `has`, `can`, or `should`. The test: put the name in an `if` and read it aloud.

<!-- lint: fragment -->
```lua
if isReloading then          -- reads as English
if reload then               -- is this a flag? a function? a count?
```

**Never negative.** `isNotValid` forces a double negative at every call site (`if not isNotValid then`). Use `isInvalid`, or better, invert to `isValid`.

### Functions are verb phrases

```lua
applyDamage(target, amount)
resolveSpawnPoint(player)
```

Boolean-returning functions read as questions, not commands:

<!-- lint: fragment -->
```lua
if isValid(input) then       -- reads as a question
if validate(input) then      -- reads as a command; what does it return?
```

### Collections are plural, elements are singular

<!-- lint: fragment -->
```lua
for tool in tools do
for slotIndex, item in inventory do
```

### Ottinger's rules, condensed

- **Intention-revealing** — the name says why the thing exists, not what type it is.
- **Avoid disinformation** — don't call it `toolList` if it's a dictionary keyed by id.
- **Searchable** — see above.
- **Pronounceable** — you have to discuss this code out loud with someone.
- **No encodings** — no type prefixes (`strName`, `tblItems`). The type annotation already says it.
- **No mental mapping** — the reader shouldn't have to hold "`p` means the projectile" in their head.
- **Meaningful in context, without artificial context** — inside `InventoryModule`, `addItem` is clear; `inventoryAddInventoryItem` is not.

---

## The cure for generic names: the game's own vocabulary

Domain-driven design's central naming idea is that the vocabulary of the domain belongs *in the source code itself*, not translated into programming-generic terms. For a Roblox game, the domain is the game — its features, its UI labels, how you and your colleagues talk about it.

This gives one testable question, and it is the most useful rule in this file:

> **Would this name fit unchanged in another project?**
> If yes, it is generic. If the word appears in the game's own UI, its design notes, or how the team talks about the feature, it is specific.

```lua
processData(playerInfo)       -- fits any project ever written
applyReloadPenalty(weapon)    -- exists only in this game
```

`processData` tells a reader nothing. `applyReloadPenalty` tells them there is a reload penalty, that weapons have one, and roughly where to look when it misfires.

Practical version: **use the word the game uses.** If the UI says "Stamina", the variable is `stamina`, not `energy` or `staminaValue`. If the team calls them "runs", they are `runs`, not `sessions`. Matching the game's vocabulary is also what makes the code legible to a colleague who knows the game but not the code.

---

## Generic names to recognise

These are the specific offenders cited across the code-detection literature. Knowing the list makes them easy to catch in review:

`data` · `result` · `item1` / `item2` · `data2` · `result_final` · `handleClick2` · `newFunction` · `temp` · `obj` · `val` · `helper` · `manager` · `processData` · `handleAction` · `doStuff`

**Numeric suffixes are the loudest.** `data2` means the author had two of something and did not distinguish them — the reader now has to work out the difference that the writer declined to name. Same for `Final`, `New`, `Old`, `Real` as suffixes: they encode edit history, not meaning.

`manager` and `helper` are the vaguest nouns in programming. If a module is a `Manager`, name what it manages and what it does with it.

---

## Luau's linter enforces part of this for you

Luau ships 28 lint warnings. Several catch naming and hygiene problems mechanically, with no judgement required:

| Lint | Number | Catches |
|---|---|---|
| `LocalShadow` | 4 | Locals shadowing other locals or globals — subtle bugs, usually from generic names colliding |
| `LocalUnused` | 7 | Declared and never read — dead code or a typo |
| `FunctionUnused` | 8 | Defined and never called |
| `ImportUnused` | 9 | `require` that nothing uses |
| `DuplicateLocal` | 17 | Same name twice as parameters or in one declaration |
| `GlobalUsedAsLocal` | 3 | A global only used in one function — should be local |
| `UnknownGlobal` | 1 | Reading a global that was never assigned; usually a typo |
| `PlaceholderRead` | 11 | Reading from `_`, which is meant to be write-only |

`LocalUnused`, `FunctionUnused`, and `ImportUnused` correspond directly to three of the things that mark code as machine-written — unused dependencies and dead unreferenced code. Turning them on is the cheapest quality win available.

### The `_` convention

`_` is the intentional discard. The linter special-cases it and won't warn where another name would:

```lua
local _, character = getPlayerAndCharacter()   -- deliberately ignoring the first
```

Silence a genuinely-unused local by prefixing it: `_unusedParam`. Do not read from `_` — that is what `PlaceholderRead` flags.

---

## Roblox-specific notes

- **Services** keep their engine name: `local Players = game:GetService("Players")`. Don't alias to `plrs`.
- **Instances** — name the variable for the role, not the class: `spawnPad`, not `part1`. If the Instance in Studio is well-named, reuse that name.
- **Remotes** — name the *action*, not the mechanism: `RequestPurchase`, not `PurchaseRemoteEvent`. The class is already in the type.
- **`player` vs `character`** — never interchange these. `player` is the `Player` object; `character` is the `Model`. Mixing them is a top source of nil errors, and the names are the only guard.
- **Type definitions** are PascalCase and describe the shape: `type InventorySlot = { itemId: string, count: number }`.

---

## Related references
- `code-signature.md` — matching an existing file's conventions; the review pass
- `diagnostics.md` — naming inside error messages and log lines
- `roblox-architecture/SKILL.md` — script layout
- `roblox-luau-language/references/compiler-limits.md` — grouping locals into tables, which needs well-named fields
