# Debug Library (sUNC / executor)

The executor `debug` library inspects Luau functions: upvalues, bytecode
constants, nested prototypes and live stack state. Use it when source evidence
places the target there; ordinary properties and table fields need no debug API.

Read this alongside `../technique/value-persistence.md`. Changing the correct
upvalue or constant can change a local reader's behaviour. It does not establish
server acceptance or prevent a later assignment from replacing the value.

> Executor `debug.*` extends the sandboxed Roblox `debug` table. It does **not** replace `debug.info` / `debug.traceback`, which exist in normal Luau.

---

## Universal rules (read before any signature)

**1. Check the operation's target contract.** Upvalue, constant and proto
operations here require Luau closures. Guard unknown mixed candidates with
`islclosure`; do not repeat a guard when the source-backed identity proves it.
Metadata operations such as `debug.getinfo` have a different contract.

```lua
if islclosure(target) then
    local ups = debug.getupvalues(target)
end
```

**2. `func` may be a function *or* a numeric stack level.** Passing `1` means "the function that called me", `2` its caller, and so on — the same convention as `debug.info`. `getstack` / `setstack` are level-oriented by nature; the rest accept either form.

**3. Never infer a constant index from a nearby string.** Indexes can change
between executors, compiler versions and builds. Enumerate the identified
closure, establish the intended constant's role, and require a unique match.
Finding `MaxAmmo` does not establish that the next slot is its value. Capture the
original before writing; repeated equal constants are ambiguous.

**4. Upvalue indexes are local to a closure.** Enumerate with `getupvalues`,
establish role and value from the source, and stop on ambiguity. A type, repeated
number or decompiler suffix alone is not identity.

---

## Reading

### debug.getupvalue
```lua
function debug.getupvalue(func: ((...any) -> ...any) | number, index: number): any
```
Returns the upvalue at `index` in the function (or stack level) `func`. An **upvalue** is a local variable captured from an enclosing scope — the single most common place a game stores mutable config that survives resets.

### debug.getupvalues
```lua
function debug.getupvalues(func: ((...any) -> ...any) | number): {any}
```
Returns every upvalue as a table. Start here; you rarely know the index in advance.

### debug.getconstant
```lua
function debug.getconstant(func: ((...any) -> ...any) | number, index: number): any
```
Returns the constant at `index` in the function's constant table.

### debug.getconstants
```lua
function debug.getconstants(func: ((...any) -> ...any) | number): {any}
```
Returns the constant table retained by the compiler. Not every source literal
must occupy an editable slot; optimizations and instruction operands affect what
is exposed. Distinctive constants can narrow candidates, not prove identity alone.

### debug.getproto
```lua
function debug.getproto(func: ((...any) -> ...any) | number, index: number, active: boolean?): ((...any) -> ...any) | {(...any) -> ...any}
```
Returns the function prototype at `index` defined inside `func`. With `active = true`, returns the list of *live* closures created from that proto instead of the inert prototype.

Use `active = true` when you need the real closure the game is currently running (so its upvalues are populated). The inert proto has no upvalue values bound.

> sUNC caveat: protos retrieved without activation *"should not be callable; this leads to vulnerabilities."* Treat inactive protos as inspection-only — read their constants, don't call them.

### debug.getprotos
```lua
function debug.getprotos(func: ((...any) -> ...any) | number): {(...any) -> ...any}
```
Returns all nested function definitions inside `func`, whether or not they were ever assigned or called. Lets you walk a module's internal structure without executing it.

```lua
local function dummy_function()
    local function dummy_function_1() end
    local function dummy_function_2() end
end

for index, proto in debug.getprotos(dummy_function) do
    print(index, debug.info(proto, "n"))
end

-- Output:
-- 1 dummy_function_1
-- 2 dummy_function_2
```

### debug.getstack
```lua
function debug.getstack(level: ((...any) -> ...any) | number, index: number?): any
```
Returns the value in register `index` of stack frame `level`. Omit `index` to get the whole frame as a table. This reads **live locals mid-execution** — only meaningful from inside a hook or a yielded coroutine, since the frame must currently exist.

### debug.getinfo
```lua
function debug.getinfo(func: ((...any) -> ...any) | number): DebugInfo
```

| Field | Type | Description |
|---|---|---|
| `source` | string | Name of the chunk that created the function |
| `short_src` | string | Printable version of `source`, used in error messages |
| `func` | function | The function itself |
| `what` | string | `"Lua"` for a Luau function, `"C"` for a C function |
| `currentline` | number | Line the function is currently executing |
| `name` | string | Name of the function |
| `nups` | number | Number of upvalues |
| `numparams` | number | Number of declared parameters |
| `is_vararg` | number | Whether the function takes `...` |

`nups` is a cheap pre-filter: a config-holding closure has upvalues, a pure helper usually has none.

### debug.getregistry
```lua
function debug.getregistry(): {(...any) -> ...any | thread}
```
The Luau registry — every function and thread created by client-side scripts. Broader and noisier than `getgc`; prefer `filtergc` for targeted searches.

### debug.isvalidlevel
```lua
function debug.isvalidlevel(level: number): boolean
```
Whether `level` is a valid stack level. Use it to bound a stack walk instead of relying on `pcall` failures.

---

## Writing

### debug.setupvalue
```lua
function debug.setupvalue(func: ((...any) -> ...any) | number, index: number, value: any): ()
```
Replaces the upvalue at `index` with `value`. **Accepts any type** — tables and functions included, unlike `setconstant`.

```lua
local upvalue = 90
local function dummy_function()
    upvalue += 1
    print(upvalue)
end

dummy_function()                      -- Output: 91
debug.setupvalue(dummy_function, 1, 99)
dummy_function()                      -- Output: 100
```

The function's own arithmetic now operates on the replacement value. A different
assignment to the same upvalue can still overwrite it; find its writer when it
resets. The numeric slot in this self-contained demonstration is not a slot to
reuse in another closure.

> Throws on C closures.

### debug.setconstant
```lua
function debug.setconstant(func: ((...any) -> ...any) | number, index: number, value: number | string | boolean | nil): ()
```
Modifies a constant in the function's compiled bytecode.

```lua
local function dummy_function()
    print(game.Name)
end

local nameIndex
for index, constant in debug.getconstants(dummy_function) do
    if constant == "Name" then
        assert(nameIndex == nil, "Name constant is ambiguous")
        nameIndex = index
    end
end
assert(nameIndex, "Name constant not found")
debug.setconstant(dummy_function, nameIndex, "PlaceId")
dummy_function() -- Reads game.PlaceId after replacing the identified property key.
```

**Type-restricted to `number | string | boolean | nil`.** You cannot write a table or a function into a constant slot — for those you need `setupvalue`.

> Throws on C closures. And again: *"If `game` is a mutable global, constant indexes will differ."* Enumerate, never hardcode.

### debug.setstack
```lua
function debug.setstack(level: ((...any) -> ...any) | number, index: number, value: any): ()
```
Writes into a live register of stack frame `level`. Powerful and fragile — the frame must exist, and writing a type the frame doesn't expect crashes the VM. Reach for it only when a value exists solely as a local mid-call and never lands in an upvalue or constant.

### debug.setname
```lua
function debug.setname(func: (...any) -> ...any, name: string): ()
```
*Potassium; not in sUNC.* Changes a function's internal name, spoofing `debug.info(func, "n")`. Counter to anti-cheats that fingerprint functions by name. See `../recon/detection-surface.md`.

---

## Practical workflow: establish identity, then change one value

Follow `../technique/decompiled-source.md` and `../technique/source-to-api.md`.
Identify the live closure, then the particular slot or table used by the reader.
A query returning one matching constant is discovery, not proof of the callable
contract. Never patch all upvalues equal to a convenient number.

If the established upvalue is a table, changing its field reaches readers of that
same table; replacing the upvalue with a new table can break reference sharing.
Capture the original field and apply `../technique/lifecycle.md` for restoration.

---

## When debug is the wrong tool

| Situation | Use instead |
|---|---|
| Value is a plain Instance property | Direct property access; hook only for an established interception need |
| Value is an Attribute | `GetAttribute` / `SetAttribute`; hook only for an established interception need |
| Target is a C closure | `hookfunction` + `newcclosure` |
| The **server** computes the value | Nothing client-side works — see `../technique/client-feasibility.md` |
| Value is a global in an established script environment | `getsenv(script)`; file-local variables are absent |

The last row matters most: `debug.setupvalue` on a client closure changes what the *client* computes. If the server recalculates damage on its own, editing the client's copy changes only what your screen displays.
