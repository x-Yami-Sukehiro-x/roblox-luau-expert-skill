# Metatables, OOP, and when not to use them

Lua has no classes. It has tables and a hook (`__index`) that fires on a missed
lookup. Every "class" in Roblox is that hook plus a convention.

---

## The metamethods that matter in Roblox

| Metamethod | Fires on | Typical use |
|---|---|---|
| `__index` | read of a missing key | inheritance, lazy defaults, proxies |
| `__newindex` | write to a missing key | read-only tables, change tracking |
| `__call` | calling the table | callable objects |
| `__tostring` | `tostring(t)`, `print(t)` | debuggable objects |
| `__eq` | `==` between two tables | value equality |
| `__len` | `#t` | custom containers |
| `__iter` | generalized `for` | custom iteration |
| `__mode` | GC behaviour | weak caches (`"k"`, `"v"`, `"kv"`) |
| `__metatable` | `getmetatable` | hides/locks the metatable |

`__index` fires **only on a miss**. Once a key exists on the instance, the
metatable is never consulted for it again. That is why per-instance state must
be set in the constructor, not inherited.

`__newindex` fires only on a **new** key. Assigning to an existing key bypasses
it entirely — a common source of "my read-only table isn't read-only".

---

## The standard Roblox class pattern

```lua
--!strict
local Inventory = {}
Inventory.__index = Inventory

export type Inventory = typeof(setmetatable({} :: {
    owner: Player,
    slots: { Item },
    capacity: number,
}, Inventory))

function Inventory.new(owner: Player, capacity: number): Inventory
    return setmetatable({
        owner = owner,
        slots = {},
        capacity = capacity,
    }, Inventory)
end

function Inventory.add(self: Inventory, item: Item): boolean
    if #self.slots >= self.capacity then
        return false
    end
    table.insert(self.slots, item)
    return true
end

function Inventory.destroy(self: Inventory)
    table.clear(self.slots)
end

return Inventory
```

Two things worth copying:

- **`typeof(setmetatable(...))`** is how you get a self type that `--!strict`
  understands, without hand-writing the method signatures.
- **`function Class.method(self: Class, ...)`** rather than
  `function Class:method(...)`. Same call syntax at the call site
  (`inv:add(item)`), but the explicit `self` is typed, so the checker catches
  mistakes inside the method body. The colon form leaves `self` as `any` in many
  cases.

---

## Inheritance

```lua
local Weapon = {}
Weapon.__index = Weapon

local Sword = setmetatable({}, { __index = Weapon })
Sword.__index = Sword

function Sword.new(damage: number)
    local self = setmetatable(Weapon.new(), Sword)
    self.damage = damage
    return self
end
```

Note the two different metatables: `Sword`'s own `__index` serves instances,
while `setmetatable(Sword, { __index = Weapon })` makes `Sword` fall through to
`Weapon` for methods it does not define.

**Prefer composition.** Two levels of inheritance is usually one too many. In
Roblox specifically, most "hierarchies" are better as a table of behaviour
functions keyed by type:

```lua
local BEHAVIOURS = table.freeze({
    sword = { damage = 25, onHit = swordHit },
    bow   = { damage = 15, onHit = bowHit },
})
```

That version is data, so it can come from a config module, be tuned without a
code change, and be validated at load.

---

## Read-only tables

For constants, `table.freeze` is the correct tool — it is enforced by the VM,
cannot be bypassed, and costs nothing at read time.

```lua
local CONFIG = table.freeze({ maxPlayers = 12 })
CONFIG.maxPlayers = 20   -- error: attempt to modify a readonly table
```

`__newindex` guards are for cases where you need a *message* rather than an
error, or want to allow some writes. They are strictly weaker: the guard only
fires for new keys, and `rawset` bypasses it.

---

## Weak tables

```lua
local partData = setmetatable({}, { __mode = "k" })
partData[somePart] = { hits = 0 }
```

With weak keys, the entry disappears once nothing else references `somePart`.
This is the clean fix for instance-keyed caches that otherwise need manual
clearing on destroy.

Caveat: it is not immediate. The entry survives until a GC cycle runs. Do not
use weakness as a correctness mechanism — use it to prevent unbounded growth.

---

## `__iter`

```lua
local Inventory = {}
Inventory.__index = Inventory

function Inventory.__iter(self)
    return next, self.slots
end

for index, item in inventory do    -- works directly
    print(index, item.id)
end
```

Useful for wrappers where the interesting collection is a field rather than the
object itself.

---

## Rawget, rawset, rawequal, rawlen

These bypass metamethods:

```lua
rawget(t, k)      -- no __index
rawset(t, k, v)   -- no __newindex
rawequal(a, b)    -- no __eq
rawlen(t)         -- no __len
```

The main legitimate use is inside a metamethod, to avoid infinite recursion:

```lua
local proxy = setmetatable({}, {
    __index = function(self, key)
        local cached = rawget(self, "_cache")[key]   -- rawget avoids re-entry
        ...
    end,
})
```

They are also how an exploiter bypasses a `__newindex` guard on the client,
which is one more reason client-side "protection" tables are not security. See
`roblox-game-security`.

---

## When not to write a class

Roblox code rots from premature abstraction more often than from missing
abstraction. Skip the class when:

- There will only ever be one of it. That is a module with functions, not a
  class. `local RoundManager = {}` with plain functions is fine and clearer.
- The object has no invariants to protect. A bag of fields is a table.
- The methods do not touch `self`. Those are free functions.
- You are wrapping an Instance to add two helpers. Attributes,
  `CollectionService` tags, or a lookup table are usually lighter and survive
  replication.

A useful test: if removing the metatable and calling the functions directly
would lose nothing, there was no class there.

---

## Instances are not tables

`Instance` is engine userdata with reflected properties. You cannot
`setmetatable` an Instance, add arbitrary fields to it, or `table.freeze` it.

To attach data to an Instance, the options in order of preference:

1. **Attributes** — replicate, survive `Clone`, visible in Studio, limited to a
   fixed set of types.
2. **`CollectionService` tags** — for set membership and
   `GetInstanceAddedSignal` reactivity.
3. **A weak-keyed table** in a module — for anything richer than an attribute,
   and anything that must stay server-side.
4. **Child `Value` objects** — legacy. They replicate, but they are heavy and
   clutter the tree. Attributes replaced this use case.
