# Detection Surface & Hook Hygiene

Two separate layers, constantly conflated:

| Layer | What it is | Can Luau touch it? |
|---|---|---|
| **Hyperion** (Byfron) | Process/memory integrity, runs before your code exists | **No** |
| **In-game anti-cheat** | LocalScripts and ModuleScripts inside the place | Yes |

Everything in this skill is in-VM Luau, downstream of injection. It operates entirely in the second layer. Nothing here defeats Hyperion — that fight is won or lost by the executor before a single line of your script runs. What this file covers is staying invisible to the *game's* checks and not breaking your own hooks.

> **Finding the anti-cheat is the other half of this.** `anticheat-recon.md` has the passive discovery script, fingerprinting via `getscripthash` / `getfunctionhash` / `debug.getconstants`, and the chokepoint technique — silence the one reporting function rather than fighting every check.

---

## Hyperion context (2026)

Enough to answer questions accurately, not enough to act on:

- Periodic memory-page scans cross-referencing executable pages against a whitelist; unapproved executable pages have execute permission revoked, crashing any thread that enters them.
- Randomly placed trap pages and execution verification — brute-force decryptors trip them and the process terminates.
- Manual PEB traversal via `gs:[0x60]` to verify loaded modules against a whitelist, catching module stomping.
- Thousands of localized polymorphic integrity checks (~2,963 distinct hashing loops identified) using dynamic prime constants and randomized bitwise operations, mutating per build — static patching and emulation are impractical.

Practical consequence for the user: **executor stability is an executor problem.** Claimed bypasses circulate constantly, are rarely verified, and are typically short-lived. Per-game bans are the live day-to-day risk, and that risk is what the rest of this file addresses.

---

## In-game detection checks and their counters

| Check the game runs | Counter |
|---|---|
| Poll `conn.Connected` on a known signal (the standard AntiAFK / `Player.Idled` pattern) | **`conn:Disable()`** — the callback stops firing but `.Connected` stays `true`. `:Disconnect()` flips it and is trivially caught. |
| `__tostring` metamethod trap on a config table | Index or iterate the table. Never `print` / `tostring` / `warn` it. Traps fire on stringification, not access. |
| Identity check — `inst == game.CoreGui`, or a weak table keyed by protected instances | **`cloneref(inst)`** — behaves identically, fails `==`. Made for exactly this. |
| `getfunctionhash` / bytecode integrity on a watched game function | Prefer `debug.setupvalue` / `debug.setconstant` over `hookfunction` on that function. Editing an upvalue does not change the function's bytecode hash. |
| Property unexpectedly scriptable | Use `gethiddenproperty`, not `setscriptable`. sUNC warns directly: *"Games may check whether certain properties are unexpectedly accessible, which can lead to detections."* |
| `debug.info(f, "n")` name fingerprinting | `debug.setname(f, name)` *(Potassium; not in sUNC)* |
| Instance-cache identity comparison | `cache.invalidate` / `cache.replace` / `cache.iscached` |
| Scanning `CoreGui` / `PlayerGui` for injected UI | `gethui()` — a hidden container intended as the alternative to both |
| Counting children of a service, or `GetDescendants` sweeps | Parent to `gethui()`; keep Drawing objects instead of Instances where possible |
| Remote fired with impossible arguments or at an impossible rate | Match the legitimate client's argument shapes and cadence. Argument *validity* is checked far more often than argument *origin*. |
| **Asset-ID scanning** — known tool IDs matched via `ContentProvider:PreloadAsync` interception (Dex `5642383285`, Infinite Yield `1204397029`, Hydroxide `4702850565`); some also flag any asset with `Creator.CreatorTargetId ~= 1` | Don't load fingerprinted assets; keep UI out of `CoreGui` via `gethui()` |
| **Stack-depth probing** — recurse to ~16,379 frames then trigger a metamethod; a hook adding stack frames overflows early and reveals itself | `newcclosure` changes the stack accounting; the probe is itself a locatable client script |
| **Environment-poisoning scan** — `getfenv()` walked across stack levels 0–20 inside a forced error, hunting executor functions leaked into a visible environment | A proper `hookmetamethod` replaces the function pointer and leaks no environment. Catches pasted/naive hooks, not correctly-wrapped ones |
| **Self-integrity check on its own reporter** — `debug.info` / `getfunctionhash` on the function your hook replaced | Cache the metadata and pre-hook `debug.info` (from `getrenv()`) *before* hooking the target — full method in `anticheat-recon.md` |

### On anonymous functions

Games defensively write `local f = function() end` rather than `function f() end` specifically so the name does not survive into decompiled output. When reading decompiled anti-cheat code, expect unnamed functions — identify them by their **constants** instead (`debug.getconstants`, or `filtergc` with `Constants`).

---

## Hook hygiene — rules that cause real bugs when ignored

These are correctness requirements from the sUNC spec, not stylistic advice. Violating them produces hooks that silently fail, crash, or are detectable.

### hookfunction

```lua
function hookfunction(functionToHook, hook): originalFunction
```

- **The hook must not have more upvalues than the target function.** This is the single most common cause of "my hook errored on install". Fix by wrapping: `hookfunction(target, newcclosure(myHook))`.
- All closure pairs are supported across L / NC / C (where NC = `newcclosure`) on a compliant executor.
- Returns the original — always call through it unless you intend to block.
- `restorefunction(f)` restores to the *first* original even after several stacked hooks.

### newcclosure

```lua
function newcclosure(functionToWrap): wrapped
```

- **The returned closure must have no upvalues.**
- **Must be yieldable** — `task.wait()` inside the wrapped function has to work.
- Errors must surface as C errors, not Luau errors; the two are distinguishable.
- **Never reimplement it with `coroutine.wrap`.** That fails sUNC checks and breaks error identity. If an executor's `newcclosure` is coroutine-based, its hooks are detectable.

### getconnections

```lua
function getconnections(signal: RBXScriptSignal): {Connection}
```

- C / foreign connections have **`nil`** `Function` and `Thread`. Guard before calling.
- sUNC warns: *"Your game may crash if C connections are not properly supported."* Wrap iteration in `pcall` on unknown executors.
- `Connection` fields: `Enabled`, `ForeignState`, `LuaConnection`, `Function`, `Thread`.
- `Connection` methods: `:Fire(...)`, `:Defer(...)`, `:Disconnect()`, `:Disable()`, `:Enable()`.

```lua
for _, conn in getconnections(signal) do
    if conn.LuaConnection and conn.Function then
        conn:Disable()          -- not Disconnect
    end
end
```

### Metamethod hooks

Always gate on `checkcaller()` so the game's own calls pass through untouched:

```lua
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() then
        -- your logic
    end
    return old(self, ...)
end))
```

Forgetting the `checkcaller()` guard means your own instrumentation recurses into itself and the game breaks in ways that look like anti-cheat.

`checkcallstack(type?, level?)` (*Synapse-lineage*) is a stricter variant that also inspects the call stack — useful when a game calls into your hook indirectly.

---

## Reducing your own footprint

1. **Prefer data edits to code edits.** `debug.setupvalue` leaves the function's bytecode hash intact; `hookfunction` does not.
2. **Prefer Drawing to Instances** for overlays — no DataModel presence to enumerate.
3. **Clean up.** Store every hook, connection, and Drawing object; restore and destroy on unload. Orphaned Drawing objects and dangling hooks are both memory pressure and evidence.
4. **Search results hold references.** Retaining GC results can keep otherwise
   collectible values alive. Inspect candidates, establish identity, then release
   the search table. Do not use `returnOne` to hide ambiguous candidates.
5. **Do not touch `0x9B` (ID_LUAU_CHALLENGE) packets.** That is the anti-cheat challenge channel; blocking it is an unambiguous, immediate detection. See `../technique/raknet.md`.
6. **Match legitimate cadence.** A remote fired 200×/second when the real client fires it twice per second is caught by rate heuristics regardless of how clean the hook is.
7. **Test on an alt in a private server.** Standing advice, and it is the difference between losing an alt and losing a main.

---

## Honest framing for the user

- In-game anti-cheat can be worked around; the checks are Luau and Luau is reachable.
- Hyperion cannot be worked around from inside Luau. If the executor does not inject, no script fixes it.
- Detection and *enforcement* are separate. Many games log first and ban in waves later — "it worked and I didn't get banned" is not evidence of being undetected.
