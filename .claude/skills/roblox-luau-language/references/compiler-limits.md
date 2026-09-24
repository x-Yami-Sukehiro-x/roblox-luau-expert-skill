# Luau Compiler Limits — Registers, Locals, Upvalues, Constants, Instructions

Four **different** compile errors, four **different** fixes. Identify which one you hit before refactoring — grouping locals into a table does nothing for the instruction limit, and splitting a function does nothing for the constant limit.

---

## The limits

From `luau-lang/luau`, `Compiler/src/Compiler.cpp`:

```cpp
static const uint32_t kMaxRegisterCount = 255;
static const uint32_t kMaxUpvalueCount = 200;
static const uint32_t kMaxLocalCount = 200;
static const uint32_t kMaxInstructionCount = 1'000'000'000;
```

Documented per-function limits from `luau.org/compatibility`:

| Limit | Value | Note |
|---|---|---|
| Local variables | **200** | Includes function arguments |
| Upvalues | **200** | Up from 60 in Lua 5.1 |
| Registers | **255** | Locals + temporaries |
| Constants | **2^23** | Up from 2^18 in Lua 5.1 |
| Jump distance | **2^23** | The limit that actually bites: a single `if`/loop body cannot need a longer jump |
| Nested functions | **2^15** | Down from 2^18 in Lua 5.1 |
| Stack depth | **20,000** Lua calls / thread | 200 C calls per C thread — so `pcall` / `coroutine.resume` nesting caps at 200 |

> The `kMaxInstructionCount` constant quoted above (`1'000'000'000`) and the
> `2^23` in this table measure different things. The billion is a ceiling on
> the total instructions the compiler will emit before it gives up; `2^23` is
> how far a single jump can reach, which is what a very long `if` body or loop
> runs into first. Only the second is realistically reachable.

**All of these are per function, not per script.** A 10,000-line script is fine if every individual function stays under. The Luau team's own warning applies: code sitting close to any limit is fragile, because codegen evolves.

---

## The four errors

| Error text | Raised by | What it means | Fix |
|---|---|---|---|
| `Out of local registers when trying to allocate <name>: exceeded limit 200` | local allocation | Too many **concurrently live** locals in one function | Tables, `do` blocks, split the function |
| `Out of upvalue registers when trying to allocate <name>: exceeded limit 200` | `getUpval` | A closure captures more than 200 outer locals | Pass parameters instead of capturing; group captures into one table |
| `Exceeded constant limit; simplify the code to compile` | `checkConstant` | Too many distinct literals in one function | Move data out to a ModuleScript or a decoded string |
| `Exceeded function instruction limit; split the function into parts to compile` | `compileFunction` | One function body is too long | Split into several functions |

Historical note: the compiler enforced 255 instead of 200 for locals since launch — a bug, fixed so the documented limit is now the real one. Old code that compiled before may now fail.

---

## Predicting it before you compile

There is no compiler flag for this. Use the counting rules.

**What consumes a local slot:**

- Every `local x` — one slot each.
- **Function parameters** — count toward the same 200.
- `for i, v in pairs(t) do` — **two** locals per loop, plus the internal iterator state.
- `for i = 1, 10 do` — one visible local, plus internal control registers.
- `local a, b, c = f()` — three.
- `local function name()` — one (the name), plus its own separate 200-budget inside.

**The rule people miss:** the main chunk of a script **is itself a function**. Top-level `local` declarations in a single-file executor script count exactly like locals inside any other function, against the same 200. A long flat script with no functions is the most common way to hit this.

**Symptoms that you are approaching it:**

- A single function over ~300 lines with no inner functions.
- Generated code — GUI-to-Lua converters emitting `local frame1 = ...`, `local frame2 = ...`.
- A config block written as dozens of individual `local` lines.
- A network/event library generating many handler functions in one scope.
- Long `if/elseif` chains where each branch declares its own locals at function scope.

Practical working ceiling: keep functions under **~80 meaningful locals**. That leaves headroom for temporaries, which share the 255-register budget.

---

## Register lifetime — why `do` blocks work

A local occupies a register **only while it is in scope**. When a scope closes, the compiler pops its locals and reuses those register slots.

So the ceiling is **concurrent live locals, not total locals declared**. A function declaring 500 locals across ten sequential `do ... end` blocks — 50 live at a time — compiles fine.

```lua
local result
do
    local tempA = computeA()
    local tempB = computeB()
    local tempC = computeC()
    result = tempA + tempB + tempC
end
-- tempA / tempB / tempC slots are free again here

do
    local other = computeD()   -- reuses one of the freed slots
    result += other
end
```

This reframing makes the fix obvious rather than a trick: **shorten lifetimes**. Declare late, scope tightly, close early.

---

## Fix 1 — group into tables (the main fix for the local/upvalue limits)

```lua
-- Burns many registers
local health = 100
local maxHealth = 100
local walkSpeed = 16
local jumpPower = 50
-- ... dozens more

-- One register
local stats = {
    health = 100,
    maxHealth = 100,
    walkSpeed = 16,
    jumpPower = 50,
}
```

### "Won't tables be slower than locals?"

Recurring worry, and the answer is **no — provided you write them the way Luau optimizes for.** From `luau.org/performance`, table field access uses inline caching, which requires:

1. **The field name is known at compile time.** `stats.health` is fast. `stats[key]` in a hot loop is not — it defeats the cache.
2. **The key set is uniform.** Tables with the same shape share cache entries. Varying which keys exist between instances defeats the optimization.
3. **Data lives directly on the table, methods on the metatable.** Field lookups that fall through a metatable are slower.

```lua
-- Fast: literal field name, uniform shape
stats.health -= damage

-- Slow in a hot loop: dynamic key defeats inline caching
local key = "health"
stats[key] -= damage
```

Collapsing locals into a table moves the naming burden onto the field names — `stats.health` has to carry what `playerHealth` used to. Name the fields as carefully as you named the locals; see `roblox-code-craft/references/naming.md`.

Written correctly the table workaround costs essentially nothing. Written as dynamic indexing in a per-frame loop it does. That distinction is the whole answer.

Also from the same page: `table.create(n)` to preallocate arrays, `table.insert` to append, and `-O2` constant-folds most builtin calls with constant arguments — so `math.floor(3.7)` in source is free at runtime.

---

## Fix 2 — split the function (the only fix for the instruction limit)

```lua
local function processDamage(data)
    -- only the locals needed for damage
end

local function processEffects(data)
    -- only the locals needed for effects
end
```

Each function gets its own 200-local, 200-upvalue, 2^23-instruction budget. This is the fix when the error says *"split the function into parts to compile"* — no amount of table-grouping reduces instruction count.

---

## Fix 3 — parameters over captured upvalues

Heavy closure capture pressures the **upvalue** limit, which is separate from locals and produces its own error.

```lua
-- Captures many outer locals as upvalues
local function makeHandler()
    return function()
        useA(a); useB(b); useC(c) -- a, b, c ... all become upvalues
    end
end

-- One upvalue
local function makeHandler(ctx)
    return function()
        useA(ctx.a); useB(ctx.b); useC(ctx.c)
    end
end
```

Passing a single context table, or passing values as parameters, relieves both limits at once.

---

## Fix 4 — move data out (the fix for the constant limit)

Large literal tables burn constants, not registers. When you hit *"Exceeded constant limit"*:

- Move the data into a **ModuleScript** and `require` it — a separate function with a fresh budget.
- For very large static datasets, store as an encoded string (`base64decode` / `JSONDecode`) and decode at runtime. Trades a little startup cost for a compilable function.

---

## Fix 5 — avoid pointless locals

```lua
-- Wasteful
local zero = 0
part.Transparency = zero

-- Better
part.Transparency = 0
```

Do not create a local to hold a literal or a single-use expression.

---

## What not to do

- **Dropping `local` to make things global.** Slower (hash lookup instead of a register), pollutes the environment, and in executor scripts leaks your state into anything that enumerates globals. It "fixes" the error by making the code worse. Luau's `GlobalUsedAsLocal` (3) and `UnknownGlobal` (1) lints flag this — see the lint table in `roblox-code-craft/references/naming.md`.
- **`_G` or a shared table as permanent architecture.** Fine as a deliberate cross-script channel; wrong as a way to dodge a limit. Use ModuleScripts.
- **Chasing the limit at all.** Hitting 200 is a structural signal, not a puzzle to outsmart.

---

## Checklist

1. **Read the error text** — it names which of the four limits you hit.
2. If a function is getting large, split it. This is the only fix for the instruction limit and helps every other.
3. Group config, stats, UI references, and related data into tables — with literal field names and uniform shapes.
4. Use `do ... end` for temporaries; shorten lifetimes rather than counting declarations.
5. Pass a context table instead of capturing many upvalues.
6. Move large literal data into ModuleScripts.
7. Prefer ModuleScripts for systems over one giant LocalScript.
8. Remember the main chunk is a function too — top-level locals count.

Tables, smaller functions, and scoped blocks solve every case cleanly and leave the code faster and more maintainable than it was.
