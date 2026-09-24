# Environment (sUNC)

## getgenv
```lua
function getgenv(): table
```
Returns the executor's global environment table, shared across all executor-made threads.

> Each Actor is a separate VM with its **own** `getgenv`. Values do not cross. See `../technique/actors-parallel.md`.

## getrenv
```lua
function getrenv(): table
```
Returns the Roblox global environment. Changes affect the game as well.

## getreg
```lua
function getreg(): table
```
Returns the Luau registry table. `debug.getregistry()` is the same surface.

## getgc
```lua
function getgc(include_tables?: boolean): table
```
Returns non-dead garbage-collectable values — functions and userdatas, plus tables when `include_tables` is true.

> Holding a strong reference to the result prevents collection and causes noticeable memory growth. Do not retain the returned table. Prefer `filtergc`.

---

## filtergc

Fine-tuned retrieval of specific garbage-collected values. **The primary tool for locating a game's internal functions and config tables** — see `../technique/value-persistence.md` for the workflow.

```lua
export type AnyFunction = (...any) -> (...any)
export type AnyTable = { [any]: any }

declare filtergc:
    ((filterType: "function", filterOptions: FunctionFilterOptions, returnOne: true) -> AnyFunction?) &
    ((filterType: "function", filterOptions: FunctionFilterOptions, returnOne: false?) -> (AnyFunction | {AnyFunction})) &
    ((filterType: "table", filterOptions: TableFilterOptions, returnOne: true) -> AnyTable?) &
    ((filterType: "table", filterOptions: TableFilterOptions, returnOne: false?) -> {AnyTable})
```

| Parameter | Type | Description |
|---|---|---|
| `filterType` | `"function"` \| `"table"` | What to search for |
| `filterOptions` | see below | Matching criteria |
| `returnOne?` | boolean | `true` returns the first match; otherwise a table of matches |

### FunctionFilterOptions

| Key | Type | Description | Default |
|---|---|---|---|
| `Name` | `string?` | Filters out functions which don't match this name | `nil` |
| `IgnoreExecutor` | `boolean?` | Filters out functions created inside the executor | **`true`** |
| `Hash` | `string?` | Filters by function hash via `getfunctionhash` | `nil` |
| `Constants` | `{any}?` | Includes functions containing the matching constants in the list | `nil` |
| `Upvalues` | `{any}?` | Includes functions containing the matching upvalues in the list | `nil` |

```lua
local upvalue = 5
local function dummy_function()
    upvalue += 1
    print(game.Players.LocalPlayer)
end

local retrieved = filtergc("function", {
    Constants = { "print", "game", "Players", "LocalPlayer", 1 },
    Upvalues = { 5 },
    IgnoreExecutor = false
}, true)

print(retrieved == dummy_function) -- Output: true
```

### TableFilterOptions

| Key | Type | Description | Default |
|---|---|---|---|
| `Keys` | `{any}?` | Also includes tables containing **all** the specified keys | `nil` |
| `Values` | `{any}?` | Only includes tables containing **all** the specified values | `nil` |
| `KeyValuePairs` | `{[any]: any}?` | Only includes tables containing **all** these key-value pairs | `nil` |
| `Metatable` | `table?` | Only includes tables whose metatable matches | `nil` |

```lua
local dummy_table = { ["dummy_key"] = "dummy_value" }
local retrieved = filtergc("table", {
    KeyValuePairs = { ["dummy_key"] = "dummy_value" },
}, true)
print(retrieved == dummy_table) -- Output: true
```

### Practical notes
- Values must still be **referenced by a live thread** to be findable. Already-collected tables are gone.
- `Constants` and `Hash` **do not apply to C functions**.
- Start with two distinctive constants, then narrow. Over-specifying returns nothing and tells you nothing about why.
- `IgnoreExecutor` defaults to `true` — set it `false` only when deliberately searching your own closures.

---

## Instance cache

Executor-side Instance reference management. Used both to hold references safely and to defeat identity-based detection (`../recon/detection-surface.md`).

```lua
function cache.invalidate(object: Instance): ()
```
Deletes `object` from the Instance cache, invalidating that reference.

```lua
function cache.iscached(object: Instance): boolean
```
Whether `object` exists in the Instance cache.

```lua
function cache.replace(object: Instance, newObject: Instance): ()
```
Replaces `object` in the Instance cache with `newObject`.

```lua
function cloneref<T>(object: T & Instance): T
```
Returns a reference clone that behaves identically to the original but is **not** `==` to it. Made for safely interacting with protected instances (`game.CoreGui`, `Players.LocalPlayer`) where a game uses identity comparison or weak tables to gate access.

```lua
local players = game:GetService("Players")
local original = players.LocalPlayer
local clone = cloneref(original)
print(original == clone) -- Output: false
print(clone.Name)        -- Output: Player's name (same as original)
```

```lua
function compareinstances(a: Instance, b: Instance): boolean
```
Whether `a` and `b` reference the same underlying Instance — the correct equality test once `cloneref` is in play, since `==` will report false.

---

## Instance enumeration

```lua
function getinstances(): {Instance}
function getnilinstances(): {Instance}
```
Every Instance referenced on the client, or only those not descended from a service provider. `getnilinstances` finds objects the game has parented to `nil` to hide them from `GetDescendants` sweeps.

```lua
function gethui(): Folder
```
A hidden GUI container. Use instead of `CoreGui` or `PlayerGui` for injected UI — games commonly enumerate both.

---

## Scripts

```lua
function getscripts(): {LuaSourceContainer}
function getrunningscripts(): {LuaSourceContainer}
function getloadedmodules(): {ModuleScript}
function getsenv(script: LuaSourceContainer): table
function getcallingscript(): LuaSourceContainer?
function getscriptfromthread(thread: thread): LuaSourceContainer?
```

`getsenv(script)` returns a script's environment table — read and patch its globals directly. `getcallingscript()` inside a hook attributes the call to its source script, which is how you tell an anti-cheat's write from a legitimate one.

> These reflect **the calling VM only**. Scripts under an Actor are enumerated from inside that Actor. See `../technique/actors-parallel.md`.

---

## Reflection

```lua
function gethiddenproperty(instance: Instance, property_name: string): (any, boolean)
```
Reads hidden / non-scriptable properties (`BinaryString`, `SharedString`, `SystemAddress`, and similar). Second return is whether the property was actually hidden.

```lua
local part = Instance.new("Part")
print(gethiddenproperty(part, "Name"))            -- Output: Part, false
print(gethiddenproperty(part, "DataCost"))        -- Output: 20, false
print(gethiddenproperty(part, "NetworkOwnerV3"))  -- Output: -1, true
```

`NetworkOwnerV3` is how you read network ownership from the client — see `../technique/replication-exploitation.md`.

```lua
function sethiddenproperty(instance: Instance, property_name: string, value: any): boolean
```

```lua
function isscriptable(instance: Instance, property_name: string): boolean
function setscriptable(instance: Instance, property_name: string, state: boolean): boolean | nil
```
`setscriptable` toggles whether a hidden property can be reached by normal indexing.

```lua
setscriptable(workspace, "SignalBehavior", true)
print(workspace.SignalBehavior) -- Output: Enum.SignalBehavior...
setscriptable(workspace, "SignalBehavior", false)
print(workspace.SignalBehavior) -- Throws an error
```

> sUNC warns on both counts: *"Games may check whether certain properties are unexpectedly accessible, which can lead to detections,"* and *"Not all hidden properties can be obtained using this function."* Prefer `gethiddenproperty`; do not implement `gethiddenproperty` on top of `setscriptable`.

```lua
function getthreadidentity(): number
function setthreadidentity(identity: number): ()
```
Thread security context (0–8). Higher grants more engine privileges. On older builds, `task.wait()` after setting for it to take full effect.

---

## Related references
- `debug.md` — reaching inside a located closure
- `../technique/value-persistence.md` — the workflow these functions serve
- `../technique/actors-parallel.md` — Actor VMs (`getactors`, `run_on_actor`, comm channels)
- `../recon/detection-surface.md` — which of these are detectable and how
