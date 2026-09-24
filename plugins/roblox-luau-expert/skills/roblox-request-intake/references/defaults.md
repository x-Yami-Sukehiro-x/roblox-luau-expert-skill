# The default table

Every decision an under-specified request leaves open, already made.

**These are defaults, not mandates.** An explicit instruction from the user
overrides any row. An existing convention in the project overrides any row. What
they must not do is turn technical details into a questionnaire. Unresolved
toggle and animation preferences use the grouped visual-choice question in
`visual-choices.md`; otherwise decide and state the default.

---

## Project shape

| Question | Default | Override when |
|---|---|---|
| UI framework | **Plain Instance code.** No Fusion, no React-lua, no Roact | The project already uses one — then match it exactly |
| State management | Plain tables and a module | Already using Charm or similar |
| Networking pattern | `RemoteEvent` for fire-and-forget, `RemoteFunction` only when the client genuinely needs a return value | — |
| Data persistence | `DataStoreService` with session locking, through one module | Project already has ProfileStore or Lyra — use theirs |
| Signals | Roblox `BindableEvent`, or a plain callback table | Project vendors a Signal library |
| Cleanup | A local table of connections with one teardown function | Project uses Trove or Janitor — use theirs |
| Build tooling | None. Plain Studio scripts | A `default.project.json` exists — then Rojo layout |
| Types | `--!strict` on new module files, `--!nonstrict` on scripts that touch untyped legacy code | — |

Why plain Instance code as the default: it runs in an empty baseplate with no
install step, it is readable by someone who has never used a package manager,
and it is the only option that cannot be broken by a dependency the user does
not know they have.

---

## File placement

Decided by what the code does, never asked.

| The code | Type | Parent |
|---|---|---|
| Builds or drives UI | `LocalScript` | `StarterPlayerScripts` |
| Reads player input | `LocalScript` | `StarterPlayerScripts` |
| Runs on the character (tools, welds) | `LocalScript` | `StarterCharacterScripts` |
| Owns currency, inventory, damage, progression | `Script` | `ServerScriptService` |
| Saves or loads data | `Script` | `ServerScriptService` |
| Shared helper used by both sides | `ModuleScript` | `ReplicatedStorage` |
| Server-only helper | `ModuleScript` | `ServerScriptService` |
| Shows before the game loads | `LocalScript` | `ReplicatedFirst` |
| Lives on a part in the world | `Script` | inside the part |
| Executor script | one file | run through the executor; no Studio placement |

Folder names inside those, when more than about three files exist:
`Modules`, `Services`, `Controllers`, `Remotes`, `UI`.

---

## Naming

| Thing | Case | Example |
|---|---|---|
| Local variables and functions | `camelCase` | `dropCount`, `refreshRow` |
| Modules, classes, services | `PascalCase` | `InventoryService` |
| Constants | `LOUD_SNAKE_CASE` | `MAX_STACK` |
| Private fields | `_camelCase` | `_pending` |
| Instances | `PascalCase`, named for role | `PurchaseButton` |
| Remotes | `PascalCase` verb phrase | `RequestPurchase` |

**Take domain nouns from the user's own words.** If they say gems, the code says
`gems` — not `currency`, not `coins`. This is the difference between code that
belongs to their game and code that was clearly written for a generic one.

---

## UI defaults

Full specification in `roblox-ui` reference `design-directions.md`. The summary:

| Question | Default |
|---|---|
| Direction | **Direction 1, "Slate"** — the named default in `design-directions.md` |
| Root | `ScreenGui`, `ResetOnSpawn = false`, `ZIndexBehavior = Sibling`, `ScreenInsets = CoreUISafeInsets` |
| Panel size | `UDim2.fromScale(0.5, 0.65)` with `UISizeConstraint` min `(300, 320)` max `(720, 820)` |
| Anchor | `Vector2.new(0.5, 0.5)` at `UDim2.fromScale(0.5, 0.5)` |
| Spacing unit | 4. Gaps drawn from 4 / 8 / 12 / 16 / 24 / 32 |
| Type scale | 12 / 14 / 16 / 20 / 28, `TextScaled = false` |
| Corner radius | 6 on controls, 10 on panels |
| Accent uses | Three to five in the whole interface |
| Touch target | 44 px minimum on any tappable element |
| Open motion | 0.20 s Cubic Out; close 0.15 s Cubic In |
| Press feedback | 0.08 s, and a visible scale or colour change |
| Toggle key | `RightShift` for menus, `RightControl` for executor hubs |
| Font | `Enum.Font.GothamMedium` body, `GothamBold` emphasis |

---

## Behaviour defaults

Things to build without being told, because their absence is what gets reported
as a bug later.

- **Every list has an empty state** with a sentence saying why it is empty.
- **Every network call has a failure path** the user can see.
- **Every interactive control has six states**: rest, hover, press, focus,
  disabled, selected.
- **Every yield is followed by re-validation** — player still present, instance
  still parented.
- **Every connection has a teardown path.**
- **Every remote handler validates its arguments** — type, range, ownership,
  rate.
- **Every `pcall` result is checked.**
- **Mobile works.** Scale for layout, offset for detail, 44 px targets.
- **Nothing hides behind hover only.** Hover does not exist on touch.

---

## Numbers to use when none are given

Picking a plausible number beats asking. State it as an assumption.

| Thing | Default |
|---|---|
| Starting currency | 0 |
| Max inventory slots | 50 |
| Leaderboard length | 100 |
| Autosave interval | 120 s |
| Data store retry attempts | 3, with backoff |
| Rate limit on a remote | 10 calls per 10 s per player |
| Toast lifetime | 4 s, 6 s for errors |
| Cooldown on a click action | 0.5 s |
| Respawn delay | Roblox default; do not change unless asked |
| Walkspeed | 16 — the engine default. Changing it is a gameplay decision |

---

## What never gets defaulted

Ask once, because no assumption is recoverable:

- **Genre**, for "make me a game".
- **Which fields to save**, for "add saving".
- **Which game**, for an executor script.
- **The actual script or error text**, when asked to fix something not provided.

Visual style preferences: offer the guide as described in `visual-choices.md`.
Everything else: decide, build, state.
