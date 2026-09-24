# Closures & Hooking (sUNC)

Verified against current sUNC documentation. Correctness rules in this file are requirements, not style — violating them produces hooks that fail to install, crash, or are detectable.

## checkcallstack

```lua
function checkcallstack(kind: string?, level: number?): boolean
```

A stricter `checkcaller`: it inspects further up the call stack rather than only
the immediate caller. Useful when a hook is several frames deep and the
immediate caller is your own wrapper. Availability varies more than
`checkcaller` — feature-detect it.

## checkcaller
```lua
function checkcaller(): boolean
```
Returns true if the current function was invoked from the executor's own thread. Essential inside hooks to distinguish your calls from the game's — without it your instrumentation recurses into itself.

`checkcallstack(type?: string, level?: number)` (*Synapse-lineage; executor-dependent*) is a stricter variant that also inspects the call stack, for cases where the game reaches your hook indirectly.

## clonefunction
```lua
function clonefunction(func: function): function
```
Creates and returns a new function with the exact same behaviour as the passed function.

## getfunctionhash
```lua
function getfunctionhash(func: function): string
```
Returns the hex SHA384 hash of the function's instructions and constants.

Useful in **both directions**:
- Games use it to detect that a function has been replaced or patched.
- You use it to verify a target function has not changed between client versions before relying on a hardcoded index.

Direct consequence: `debug.setupvalue` does **not** change a function's hash; `hookfunction` does. When a game hashes a function you need to influence, edit its upvalues rather than replacing it. See `debug.md`.

## hookfunction
```lua
function hookfunction<A1..., R1..., A2..., R2...>(
    functionToHook: (A1...) -> R1...,
    hook: (A2...) -> R2...
): (A1...) -> R1...
```
Hooks a function with another, returning the original unhooked function.

```lua
local function dummy_func() print("I am not hooked!") end
local function dummy_hook() print("I am hooked!") end

local old_func = hookfunction(dummy_func, dummy_hook)
dummy_func() -- Output: I am hooked!
old_func()   -- Output: I am not hooked!
```

**Rules:**
- **The hook must not have more upvalues than the target function.** This is the most common install failure. Fix by wrapping: `hookfunction(target, newcclosure(myHook))`.
- All closure pairs across L / NC / C should be supported on a compliant executor (NC = `newcclosure`).
- Always call through the returned original unless you intend to block.

## hookmetamethod
```lua
function hookmetamethod(object: any, method: string, hook: function): function
```
Hooks the specified metamethod of an object. Internally uses `hookfunction`, so the upvalue rule above applies — wrap the hook in `newcclosure`.

## newcclosure
```lua
function newcclosure<A..., R...>(functionToWrap: (A...) -> R...): (A...) -> R...
```
Wraps a Luau function into a C closure. Required for most stable hooks.

**Requirements:**
- The returned closure **must have no upvalues**.
- It **must be yieldable** — `task.wait()` inside the wrapped function has to work.
- Errors must surface as C errors, not Luau errors; the two are distinguishable and games check.
- **Never reimplement it with `coroutine.wrap`.** sUNC states this fails its checks. An executor whose `newcclosure` is coroutine-based produces detectable hooks.

```lua
local func = function(...) return ... end
local wrapped = newcclosure(func)
print(iscclosure(wrapped)) -- true
print(wrapped("Hello"))    -- Hello

local yieldFunc = newcclosure(function()
    print("Before")
    task.wait(1.5)
    print("After")
end)
yieldFunc()
```

## restorefunction
<!-- lint: fragment -->
```lua
function restorefunction(func: function)
```
Restores the **hooked target** to its first original, removing every stacked hook.
It throws if the target is not hooked. Pass the target, not the original callable
returned by `hookfunction`. This is suitable only when the script owns the whole
chain; it is not a per-script undo on a shared target. See
`../technique/lifecycle.md` and
[sUNC restorefunction](https://docs.sunc.io/Closures/restorefunction/).

## iscclosure / islclosure / isexecutorclosure
```lua
function iscclosure(func: function): boolean
function islclosure(func: function): boolean
function isexecutorclosure(func: function): boolean
```
Identify C closures, Luau closures, or executor-created closures (including those from `loadstring` / `getscriptclosure`).

Use `islclosure` while inspecting unknown mixed closures before an operation that
requires a Luau closure. Do not repeat the guard when the identified source-backed
closure already establishes that fact. Debug functions have different contracts;
check the specific entry in `debug.md` rather than assuming all reject C closures.

## loadstring
```lua
function loadstring(source: string, chunkname?: string): function?, string?
```
Compiles Luau source. On error returns nil + error message.

## getnamecallmethod / setnamecallmethod
```lua
function getnamecallmethod(): string
function setnamecallmethod(method: string): ()   -- executor-dependent
```
`getnamecallmethod` returns the name of the method that invoked `__namecall`. `setnamecallmethod` rewrites it — call only from inside a `__namecall` hook.

---

## Standard hook shape

```lua
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if not checkcaller() then
        if method == "FireServer" then
            -- inspect / modify / block
        end
    end

    return old(self, ...)   -- passthrough
end))
```

## Common pitfalls
- Forgetting `newcclosure` on the replacement → upvalue-count install failure.
- Forgetting `checkcaller()` → infinite recursion that looks like anti-cheat.
- Not returning `old(...)` → the game's call silently does nothing.
- Reimplementing `newcclosure` with coroutines → detectable, and errors have the wrong identity.
- Passing a C closure to a Luau-only debug operation → throws.
- Leaving hooks installed after unload → they outlive your script and stack on re-execution.

Detection implications of each choice: `../recon/detection-surface.md`.
