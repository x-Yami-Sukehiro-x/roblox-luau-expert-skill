---
name: roblox-luau-language
description: The Luau language - types, --!strict, generics, metatables, OOP, buffer, closures, compiler limits. Use for type errors.
---

# Luau — the language

Luau is Lua 5.1 plus a gradual type system, a different GC, a faster VM, and a
handful of syntax extensions. Most "Lua" advice transfers; the places it does
not are where the bugs live.

## Load a reference when

| Question | File |
|---|---|
| type errors, generics, refinements, `--!strict` | `references/type-system.md` |
| "too many local variables", "Out of local registers", won't compile, or a script growing past a few hundred lines | `references/compiler-limits.md`; measure with `node tools/bin/check-registers.mjs`; write long scripts to the shape in `roblox-register-budget` |
| classes, inheritance, `__index`, `setmetatable` | `references/oop-and-metatables.md` |
| `table.*`, `string.*`, `buffer`, `vector`, `os.clock` | `references/stdlib.md` |

---

## Type checking modes

One comment on the first line of the file:

```lua
--!strict     -- infer and enforce everywhere; unannotated gaps are errors
--!nonstrict  -- the default; unknown types silently become `any`
--!nocheck    -- no type checking at all
--!native     -- compile this script to machine code (orthogonal to the above)
```

**Recommendation.** New ModuleScripts get `--!strict`. It costs a few
annotations and catches an entire class of nil bug at author time. Existing
files get `--!strict` only when you are willing to fix what it surfaces —
turning it on and then papering over the errors with `:: any` is worse than
leaving it off, because it looks checked and is not.

`--!native` is a performance switch, not a typing switch. It only pays off in
numeric hot loops, it increases memory, and it silently falls back to the
interpreter for constructs it cannot compile. Measure before and after; see
`roblox-performance`.

---

## Types, briefly

```lua
local name: string = "sword"
local count: number? = nil                 -- optional: number | nil
local ids: { number } = {}                 -- array
local byName: { [string]: Item } = {}       -- map
local pos: Vector3 = Vector3.zero

type Item = {                               -- table type
    id: string,
    damage: number,
    tags: { string }?,
}

export type Weapon = Item & { reloadTime: number }   -- intersection, re-exportable

type Result = "ok" | "failed"               -- singleton union

local function apply<T>(items: { T }, fn: (T) -> ()): ()   -- generic
    for _, item in items do fn(item) end
end
```

**`::` is a cast, `:` is an annotation.** They are not interchangeable:

```lua
local part = workspace:FindFirstChild("Door") :: BasePart   -- cast: trust me
local part: BasePart? = workspace:FindFirstChild("Door")    -- annotation: the truth
```

The cast silences the checker. The annotation keeps the `?` and forces you to
handle nil. Prefer the annotation. Reach for `::` only where you genuinely know
something the checker cannot, and where being wrong is a loud runtime error
rather than a silent one.

**Refinement** is how you earn a non-optional type:

```lua
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then
    humanoid.Health = 100      -- refined to Humanoid inside the branch
end

if part:IsA("BasePart") then
    part.Anchored = true       -- IsA refines too
end
```

`any` disables checking. `unknown` requires you to narrow before use — it is the
safe version of `any` and the right type for "value from outside", such as a
remote argument. `never` is the empty type; seeing it usually means a
contradiction in your annotations.

Full treatment including type packs, variadics and generic constraints:
`references/type-system.md`.

---

## Syntax Luau adds

```lua
-- string interpolation (backticks)
local msg = `{player.Name} dealt {damage} damage`

-- compound assignment
coins += 50
label.Text ..= " (max)"

-- continue
for _, item in items do
    if item.expired then continue end
    process(item)
end

-- generalized iteration: no pairs/ipairs needed
for key, value in someTable do end
for index, value in someArray do end

-- if-then-else expression
local label = if health > 0 then "alive" else "dead"

-- number literals
local mask = 0b1010_0000
local big  = 1_048_576

-- floor division
local tiles = distance // TILE_SIZE
```

Generalized iteration on an array yields `index, value` in order, the same as
`ipairs`, and stops at the first nil. On a mixed table the array part comes
first. It is faster than both `pairs` and `ipairs`, and it is the default choice
in modern Luau.

**`const` bindings do not exist.** They are an unimplemented RFC, in upstream
Luau as well as in Roblox's build — this is not a case of Roblox lagging
behind. Use `local` and, where immutability matters at runtime,
`table.freeze`.

Roblox *does* lag upstream Luau on genuinely shipped features, so the general
rule still applies: check the version stamp in `tools/api-dump/version.txt` and
verify in Studio before relying on anything recent.

---

## Truthiness — the one that catches everyone

Only `nil` and `false` are falsy. `0`, `""`, `{}` and `NaN` are all **truthy**.

```lua
if not count then ... end          -- does NOT run when count is 0
if count == nil or count == 0 then ... end   -- what you meant
```

The same trap in `or` defaults:

```lua
local enabled = settings.enabled or true     -- can never be false
local enabled = if settings.enabled == nil then true else settings.enabled
```

---

## Closures and upvalues

A closure captures variables by reference, not by value. The classic loop trap
does **not** bite in Luau, because each iteration of a `for` loop gets a fresh
binding:

```lua
for i = 1, 3 do
    task.delay(i, function() print(i) end)   -- prints 1, 2, 3 — correct
end
```

But a shared local outside the loop is shared:

```lua
local i = 0
for _ = 1, 3 do
    i += 1
    task.delay(1, function() print(i) end)   -- prints 3, 3, 3
end
```

Upvalue count is capped at **200 per function**, not 255 — 255 is the
*register* limit, which is the number people remember and the wrong one for
this error. Hooks and large callbacks hit the upvalue cap; the fix is to capture
one table instead of forty locals. See `references/compiler-limits.md`.

---

## Garbage collection

Luau uses an incremental mark-and-sweep collector. Practical consequences:

- **Instances are not collected while anything references them.** `:Destroy()`
  parents to nil, locks the instance and drops *its* signal connections — it
  does not remove it from your table. Clear your reference too.
- **Connections keep closures alive**, and closures keep everything they
  captured alive. This is the number one Roblox memory leak.
- **Weak tables** let the collector help you:
  ```lua
  local cache = setmetatable({}, { __mode = "k" })   -- weak keys
  ```
  `"k"`, `"v"` and `"kv"` are the modes. Useful for instance-keyed caches you do
  not want to hand-clear.
- `collectgarbage("count")` returns KB in use. Sample it on a timer; a leak
  climbs monotonically with no plateau.
- Do **not** call `collectgarbage("collect")` in shipped code. It stalls the VM
  and hides the actual problem.

---

## `task` versus coroutines

`task.*` schedules on the engine's task scheduler and is what you want in
Roblox. Raw coroutines are for control flow you own end to end.

```lua
task.spawn(fn, ...)       -- run now, on a new thread
task.defer(fn, ...)       -- run at the end of this resumption cycle
task.delay(n, fn, ...)    -- run after n seconds
task.wait(n)              -- yield for at least n seconds; returns actual delta
task.cancel(thread)       -- kill a scheduled thread
task.synchronize()        -- parallel Luau: return to serial execution
task.desynchronize()      -- parallel Luau: leave serial execution
```

`wait`, `spawn` and `delay` (no `task.`) are deprecated. `wait()` is throttled,
drifts under load, and has a different minimum than `task.wait()`.

`task.defer` is the tool for "do this after everything else this frame has run"
— useful for coalescing UI updates. It is **not** a yield-free `task.spawn`;
misusing it to sequence work produces ordering bugs that only appear under load.

An error inside `task.spawn` does not propagate to the caller — it surfaces in
the output as an unhandled error on that thread. Wrap in `pcall` if the caller
needs to know.

---

## Common language-level mistakes

**`#` on a table with holes is undefined.** `{1, nil, 3}` may report 1 or 3.
Never rely on `#` for a table you built with nil gaps. Track the count yourself
or use a dense array.

**`table.remove` in a forward loop skips elements.** Iterate backwards, or build
a filtered table.

```lua
for i = #items, 1, -1 do
    if items[i].expired then table.remove(items, i) end
end
```

**`table.insert` with a position is O(n).** Appending is O(1); inserting at 1 in
a loop is quadratic.

**`tick()` is deprecated and timezone-dependent.** For elapsed time use
`os.clock()` (monotonic, high resolution). For wall-clock use `os.time()` (UTC
seconds) or `DateTime`. Never subtract two `os.time()` values for sub-second
work.

**String concatenation in a loop is quadratic.** Build a table and
`table.concat` it, or use `string.format` / interpolation once.

**`string.split` returns a table, not a tuple.** And it does not accept a
pattern — it is a plain-substring split. Use `string.gmatch` for patterns.

**Lua patterns are not regex.** `%` is the escape character, not `\`. There is
no alternation. `string.match("a.b", "a.b")` matches `axb` too — escape the dot
as `%.`.

**Integer division and float equality.** All Luau numbers are doubles. `0.1 +
0.2 ~= 0.3`. Compare with an epsilon, or work in integers.

**`table.freeze` is shallow** and permanent. It is the right tool for config
tables and enum-like constants; it does not deep-freeze nested tables.

```lua
local CONFIG = table.freeze({
    maxHealth = 100,
    respawnDelay = 5,
})
```

**`table.clone` is shallow too.** Nested tables are shared with the original.

Full standard-library detail including `buffer` and `vector`:
`references/stdlib.md`.

## Works with

- `roblox-code-craft`: how typed code should read.
- `roblox-toolchain`: luau-lsp and strict checking outside Studio.
- `roblox-performance`: native code generation and allocation.
- `roblox-register-budget`: long scripts written under the 200-local limit, and the scope check after a fix.
