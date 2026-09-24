---
name: roblox-architecture
description: Structuring a Roblox codebase — DataModel layout, ModuleScript patterns, script layout conventions, service/controller separation, dependency direction, state management, cleanup with Trove and Janitor, Promise and Signal libraries, framework survey (Knit, Flamework, Matter, roblox-ts), where UI state lives and how it reaches the view, declarative UI libraries (Fusion, Vide, React-lua), and testing seams. Use for "where should this code go", module organisation, project structure, or choosing a framework.
---

# Architecture

Roblox projects fail structurally in two directions: a single 3,000-line
`Script` that does everything, or a framework cathedral built before there was a
game. Both are avoidable with a small number of conventions.

## Load a reference when

| Need | File |
|---|---|
| where UI state lives, stores vs views, Fusion / Vide / React-lua | `references/ui-state.md` |

---

## DataModel layout

| Container | Replicates | Put here |
|---|---|---|
| `ServerScriptService` | no | server `Script`s and server-only modules |
| `ServerStorage` | no | server-only assets, unearned item definitions, secrets |
| `ReplicatedStorage` | **yes** | shared modules, remotes, assets both sides need |
| `ReplicatedFirst` | yes, first | loading screen only |
| `StarterPlayerScripts` | to owner | client controllers |
| `StarterCharacterScripts` | to owner | per-character client scripts |
| `StarterGui` | to owner | UI |
| `Workspace` | yes | the world |

**Everything in `ReplicatedStorage` is readable by every client**, including one
running a decompiler. Item drop tables, admin user-id lists, anti-cheat
thresholds and shop prices placed there are public. Shared *types* and shared
*pure functions* are fine; shared *authority data* is not.

A layout that scales:

```
ReplicatedStorage/
  Shared/            pure logic + types, no side effects, usable by both sides
  Remotes/           RemoteEvent / RemoteFunction instances
  Packages/          Wally dependencies
ServerScriptService/
  Server/
    Services/        one module per domain: Combat, Economy, Rounds
    init.server.luau bootstraps them in order
ServerStorage/
  ServerData/        catalogs, drop tables, anything clients must not read
StarterPlayer/StarterPlayerScripts/
  Client/
    Controllers/     mirrors Services, client-side
    init.client.luau
```

---

## Script layout

One order, applied everywhere, so any file is scannable in five seconds:

```lua
--!strict
-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Trove = require(ReplicatedStorage.Packages.Trove)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

-- // OBJECTS // --
local purchaseRemote = ReplicatedStorage.Remotes.Purchase

-- // CONFIGURATION // --
local PURCHASE_COOLDOWN = 0.35
local MAX_INVENTORY = 120

-- // STATE // --
local lastPurchase: { [Player]: number } = {}

-- // FUNCTIONS // --
local function canAfford(player: Player, cost: number): boolean end

-- // INITIALIZATION // --
purchaseRemote.OnServerEvent:Connect(onPurchase)
```

The value is not the comment banners — it is that **nothing runs above the
INITIALIZATION section**. When you open an unfamiliar file, everything that
actually happens is in one place at the bottom.

---

## ModuleScript patterns

**Stateless namespace** — the default. Most modules are this.

```lua
--!strict
local Damage = {}

function Damage.compute(base: number, multiplier: number): number
    return math.floor(base * multiplier)
end

return Damage
```

**Singleton service** — one instance, explicit lifecycle.

```lua
local Economy = {}
local balances: { [Player]: number } = {}

function Economy.init() end
function Economy.start() end
function Economy.getBalance(player: Player): number
    return balances[player] or 0
end

return Economy
```

**Class** — many instances with invariants. See
`roblox-luau-language/references/oop-and-metatables.md`.

Rules that prevent the usual pain:

- **`require` is cached per context.** A module runs once per side; the same
  table comes back every time. Server and client each get their own copy —
  module state is never shared across the boundary.
- **Circular requires deadlock or error.** If A needs B and B needs A, the
  shared part belongs in C. Do not solve it with a lazy `require` inside a
  function; that hides the cycle rather than removing it.
- **Never yield at module top level.** A `WaitForChild` in module scope blocks
  every other module waiting on that require. Move it into an `init` function.
- **Always `return`.** A ModuleScript with no return errors at require time. A
  types-only module returns `{}`.

---

## Two-phase startup

Ordering bugs at boot are common and hard to reproduce. Split initialization
from wiring:

```lua
local MODULES = { require(Services.Economy), require(Services.Combat), require(Services.Rounds) }

for _, module in MODULES do            -- phase 1: build state, no cross-talk
    if module.init then module.init() end
end
for _, module in MODULES do            -- phase 2: connect, call each other
    if module.start then module.start() end
end
```

`init` may not touch other modules. `start` may. That single rule removes almost
every "module A wasn't ready when B asked" bug without a dependency graph.

---

## Cleanup: Trove and Janitor

Manual `:Disconnect()` bookkeeping is where memory leaks come from. Use an
object that owns lifetimes.

```lua
local Trove = require(ReplicatedStorage.Packages.Trove)

local function setupCharacter(character: Model)
    local trove = Trove.new()

    trove:Add(character:WaitForChild("Humanoid").Died:Connect(onDied))
    trove:Add(Instance.new("Highlight"))                -- destroyed automatically
    trove:Add(task.spawn(regenLoop, character))
    trove:Add(function() print("cleanup ran") end)

    character.AncestryChanged:Once(function()
        if not character:IsDescendantOf(game) then
            trove:Destroy()
        end
    end)
end
```

Both libraries do the same job. **Trove** ships inside `Sleitnick/RbxUtil` — it is
not a standalone repo, which is a common wrong path. **Janitor**
(`howmanysmall/Janitor`, MIT) is the other common choice and supports named keys, so
you can replace one tracked item without rebuilding the set.

Status and adoption figures for both live in `docs/SOURCES.md`, dated. They are kept
out of skill prose because they rot silently.

Pick one per project. Two cleanup conventions in one codebase is worse than
either alone.

---

## Signals and Promises

**Signal** — an in-process event you own. Prefer it to `BindableEvent` for
same-context communication: no instance, no deep-copy of arguments, no
metatables stripped, no deferred-signal surprises. `GoodSignal` and the `Signal`
module in RbxUtil are the standard implementations.

**Promise** (`evaera/roblox-lua-promise`) — for async work with real error
handling and cancellation. Worth it when you have chains of yielding operations
that can each fail; overkill for a single `pcall` around a `GetAsync`.

```lua
loadProfile(player)
    :andThen(function(profile) return grantLoginBonus(profile) end)
    :andThen(function() setLoaded(player) end)
    :catch(function(err) warn("[profile]", err); player:Kick("Data failed to load") end)
```

Do not mix idioms randomly. Pick "yielding functions returning `(ok, result)`"
or "Promises" for a subsystem and stay with it.

---

## Framework survey

Honest status, because half the tutorials online recommend an archived project.

| Framework | ★ | Status | Verdict |
|---|---|---|---|
| **Knit** | 630 | **archived 2024** | Do not start new work on it. Enormous amount of existing code and tutorials use it; understand it, do not adopt it. |
| **Flamework** | 158 | active | TypeScript-first, decorator-based DI. Strong if you are already on roblox-ts. |
| **Matter** | 115 | active | ECS. Real fit for simulation-heavy games with many similar entities; a mismatch for a shop UI. |
| **ecr** | 60 | active | Leaner sparse-set ECS, pure Luau. |
| **roblox-ts** | — | active | TypeScript compiled to Luau. Genuine type safety and npm; costs you a build step and a smaller hiring pool. |

**Most games do not need a framework.** Modules with `init`/`start`, a Trove per
lifetime, and one folder per domain covers a surprising amount of ground.
Reach for a framework when you have a concrete problem it solves — cross-server
service discovery, entity-heavy simulation, a large team needing enforced
boundaries — not because the project feels like it should have one.

ECS specifically: adopt it when you have hundreds of entities sharing behaviour
and the per-entity cost matters. Adopt it for a tycoon with twelve droppers and
you have bought indirection with no return.

---

## Dependency direction

One rule prevents most tangles: **dependencies point inward, toward pure logic.**

```
Scripts (wiring, connections)
   depends on
Services / Controllers (orchestration, side effects)
   depends on
Shared logic (pure functions, types, catalogs)
```

Shared logic must not require a Service. If it does, the thing it needs is a
parameter, not a dependency.

Pure logic in the middle layer is what makes tests possible without a running
game: `Damage.compute(25, 1.5)` needs no DataModel, no player, no yield.

---

## Testing seams

`jest-roblox` (`jsdotlua/jest` on Wally) is the current test runner; `TestEZ` is
**archived**.

The seam that matters is not the framework, it is **separating computation from
effects**:

```lua
-- hard to test: reads the world, writes the world
function Combat.hit(player, target)
    local weapon = player.Character:FindFirstChildOfClass("Tool")
    target.Humanoid.Health -= WEAPONS[weapon.Name].damage
end

-- easy to test: the decision is a pure function
function Combat.resolveHit(weaponName: string, targetHealth: number): number
    local weapon = WEAPONS[weaponName]
    if not weapon then return targetHealth end
    return math.max(0, targetHealth - weapon.damage)
end
```

The second version is testable with a table of inputs and no Roblox at all. The
wiring around it stays thin enough that its correctness is visible by reading.

Test the pure layer thoroughly; smoke-test the wiring in a playtest. Mocking the
DataModel extensively usually costs more than it returns.

See `roblox-toolchain` for running tests in CI with Lune.

---

## When to split a module

Split when a file has **two reasons to change**, not when it hits a line count.
A 400-line module that owns one domain is fine. A 90-line module that owns
inventory *and* UI *and* saving is not.

Before adding an abstraction, find the second caller. If there is only one,
inline it and wait.
