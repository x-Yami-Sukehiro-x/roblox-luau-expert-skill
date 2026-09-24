# Luau type system

Gradual typing: annotations are optional, checked where present, and erased at
runtime. **No annotation validates anything at runtime.** A `RemoteEvent`
handler annotated `(player: Player, amount: number)` still receives whatever the
client sent. Types are an author-time tool; validation is a separate job.

---

## Modes

```lua
--!strict      infer everywhere, report every mismatch
--!nonstrict   default; unresolved types become `any` and stop propagating errors
--!nocheck     off
```

`--!strict` is worth it in ModuleScripts, where the type surface is the API. It
is worth less in a 40-line Script that wires three connections together.

Turning `--!strict` on and then silencing the results with `:: any` is a net
negative — the file now claims to be checked. Either fix the errors or leave the
mode alone.

---

## Annotations

```lua
local health: number = 100
local target: Player? = nil
local names: { string } = {}
local scores: { [Player]: number } = {}

local function damage(target: Humanoid, amount: number): boolean
    if target.Health <= 0 then return false end
    target:TakeDamage(amount)
    return true
end

-- function type
type Handler = (player: Player, payload: { [string]: any }) -> ()

-- variadic
local function sum(...: number): number end

-- multiple returns
local function tryLoad(key: string): (boolean, PlayerData?) end
```

Table types support optional fields and index signatures together:

```lua
type Config = {
    name: string,
    volume: number?,          -- optional field
    [string]: any,            -- index signature; loosens everything, use sparingly
}
```

---

## Unions and intersections

```lua
type Shape = "circle" | "square"                -- singleton union
type Id = string | number
type Nullable = Instance?                        -- sugar for Instance | nil

type Named = { name: string }
type Aged = { age: number }
type Person = Named & Aged                       -- intersection: has both
```

A union must be narrowed before you can use member-specific behaviour:

```lua
local function describe(id: string | number): string
    if type(id) == "string" then
        return id:upper()          -- refined to string
    end
    return tostring(id)            -- refined to number
end
```

Singleton unions are the cheapest way to make illegal states unrepresentable:

```lua
type RoundState = "lobby" | "starting" | "active" | "ending"
local state: RoundState = "lobby"
state = "activated"    -- type error, caught at author time
```

---

## Generics and type packs

```lua
local function first<T>(items: { T }): T?
    return items[1]
end

local function map<T, U>(items: { T }, fn: (T) -> U): { U }
    local out = {}
    for i, v in items do out[i] = fn(v) end
    return out
end

-- generic type alias
type Result<T> = { ok: true, value: T } | { ok: false, error: string }
```

**Type packs** are generic over *lists* of types — needed for wrappers that pass
arguments and returns through unchanged:

```lua
local function retry<A..., R...>(
    fn: (A...) -> R...,
    attempts: number,
    ...: A...
): R...
    -- ...
end
```

`A...` is an argument pack, `R...` a return pack. This is how `task.spawn` and
`pcall` are typed. Without them, a wrapper degrades to `...any` and loses every
call-site check.

---

## Refinements

Luau narrows types along control flow. The forms that work:

```lua
-- nil check
if humanoid then humanoid.Health = 100 end

-- early return
if not humanoid then return end
humanoid.Health = 100                        -- refined after the guard

-- type()
if type(value) == "table" then ... end

-- typeof() — Roblox datatypes as well as Lua types
if typeof(value) == "Vector3" then ... end

-- IsA
if instance:IsA("BasePart") then instance.Anchored = true end

-- assert
local part = assert(workspace:FindFirstChild("Door"), "Door missing")

-- equality against a singleton
if state == "active" then ... end
```

Refinements are **lost across a yield or a function boundary**:

```lua
if humanoid then
    task.wait(1)
    humanoid.Health = 100     -- still typed Humanoid, but may be destroyed now
end
```

The checker keeps the refinement; reality does not. This is exactly why
"re-validate after every yield" is a rule rather than a suggestion — the type
system will not remind you.

---

## `any`, `unknown`, `never`

| Type | Meaning | Use it for |
|---|---|---|
| `any` | checking off | escape hatch, third-party boundaries |
| `unknown` | some value, narrow before use | remote arguments, `JSONDecode` output |
| `never` | no value can have this type | exhaustiveness checks |

`unknown` is the correct type for anything crossing a trust boundary, because it
forces the narrowing you should be doing anyway:

```lua
Remote.OnServerEvent:Connect(function(player: Player, payload: unknown)
    if typeof(payload) ~= "table" then return end
    local amount = (payload :: { amount: unknown }).amount
    if typeof(amount) ~= "number" then return end
    if amount ~= amount or amount < 0 or amount > 1000 then return end   -- NaN and range
    ...
end)
```

`never` powers exhaustiveness over a singleton union:

```lua
type State = "lobby" | "active" | "ending"

local function tick(state: State)
    if state == "lobby" then return
    elseif state == "active" then return
    elseif state == "ending" then return
    end
    local exhaustive: never = state    -- errors if a new state is added
end
```

---

## Exported types and module boundaries

```lua
-- ItemTypes.luau
export type Rarity = "common" | "rare" | "legendary"
export type Item = { id: string, rarity: Rarity, damage: number }
return {}
```

```lua
-- consumer
local ItemTypes = require(ReplicatedStorage.ItemTypes)
type Item = ItemTypes.Item

local function equip(item: Item) end
```

A module that exports types but has no runtime surface still needs a `return`.
`return {}` is idiomatic. A ModuleScript with no `return` errors at require time
— see `roblox-architecture`.

---

## Roblox-specific typing notes

**Instance types are real types.** `Part`, `Humanoid`, `ScreenGui` and the rest
come from the API and support refinement through `IsA`.

**`FindFirstChild` returns `Instance?`**, not the concrete class. Two correct
shapes:

```lua
local humanoid = character:FindFirstChildOfClass("Humanoid")   -- Humanoid?
local root = character:FindFirstChild("HumanoidRootPart")
if root and root:IsA("BasePart") then ... end
```

The cast `:: BasePart` skips the check. It is fine after a `WaitForChild` you
control, and dangerous on anything a player or another script can rename.

**`WaitForChild` returns `Instance`**, not `Instance?`, even with a timeout — the
type lies about the timeout case. Always branch on nil anyway:

```lua
local gui = playerGui:WaitForChild("MainMenu", 10)
if not gui then return end
```

**`:GetService()` is typed per service name.** `game:GetService("Players")`
yields `Players`, so no cast is needed.

**Attributes and `GetAttribute` return `any`.** Narrow them:

```lua
local level = part:GetAttribute("Level")
if typeof(level) ~= "number" then return end
```

**luau-lsp needs a sourcemap** to know your DataModel layout. Without it,
`ReplicatedStorage.Modules.Combat` is untyped. See `roblox-toolchain`.

---

## Where the type system does not help

It does not check remote payloads, DataStore contents, `JSONDecode` output,
`GetAttribute`, `require` of a dynamic path, or anything an exploiter sends.
Every one of those is a runtime validation job. Annotating them `unknown` is the
honest move; annotating them with the shape you hope for is how exploitable
handlers get written.
