# Anti-Cheat Reconnaissance — finding it, fingerprinting it, silencing it

`detection-surface.md` covers **not being seen**. This file covers **seeing them**: locating a game's client-side anti-cheat, identifying it durably, and neutralising its reporting path rather than fighting each individual check.

Workflow this file assumes: run the passive recon script → hand back the JSON → get a targeted answer. Do not guess at a bypass before the recon output exists.

---

## Where anti-cheat hides, and what finds it

| Hiding technique | What finds it |
|---|---|
| Ordinary LocalScript in `StarterPlayerScripts` | `getscripts()` / `getrunningscripts()` |
| `script.Parent = nil` | **`getnilinstances()`** |
| Script Instance destroyed after it started running | **`getgc(true)` / `filtergc`** — the closures outlive the Instance |
| Inside an `Actor` (separate Luau VM) | `getactors()` + `run_on_actor` → `../technique/actors-parallel.md` |
| Logic inside a required ModuleScript | `getloadedmodules()`, then `debug.getprotos` |
| Checks bound to render step | `getrendersteppedlist()` — `getconnections` does **not** see these |
| Obfuscated / stripped names | `debug.getconstants` — strings survive minification |

**The two middle rows are the point.** Destroying the script Instance is the standard hiding technique, and it defeats Dex and `getscripts` completely — while defeating neither `getgc` nor `filtergc`. A running closure is reachable from the garbage collector regardless of whether its script still exists in the DataModel.

So: **an empty `getscripts` result is not evidence there is no anti-cheat.** It usually means the opposite.

---

## Fingerprinting — what to record and hand back

### getscripthash
```lua
function getscripthash(script: BaseScript | ModuleScript): string?
```
SHA-384 hex of the script's **raw encrypted, compressed bytecode** — hashed as stored, without decryption or decompression. Returns `nil` when the script has no bytecode.

```lua
local Animate = game.Players.LocalPlayer.Character:FindFirstChild("Animate")
print(getscripthash(Animate))                    -- 384-bit hex string
print(getscripthash(Instance.new("LocalScript"))) -- nil
```

Stable for identical scripts, changes when the script changes. Two uses:
- **Identify** — the hash is the thing to report and to search for.
- **Detect updates** — store it; a changed hash means the anti-cheat was updated and every constant index and offset you relied on must be re-verified.

### getfunctionhash
```lua
function getfunctionhash(func: function): string
```
SHA-384 over a function's instructions and constants. Identifies a specific function even when its name is stripped. Also the check anti-cheats run on *their own* functions to notice tampering — see the chokepoint section.

### debug.getconstants — the durable identity
Names get stripped and minified. **String constants generally survive**, because the code needs them at runtime. This is why locating by constant beats locating by name, and it is exactly how the public Adonis bypass finds its target.

```lua
if islclosure(fn) then
    for i, k in debug.getconstants(fn) do
        if typeof(k) == "string" then print(i, k) end
    end
end
```

---

## The passive recon script

Read-only. Enumerates, hashes, reads constants, counts connections. **Installs no hooks, fires nothing, probes nothing, writes nothing into game state.** Every executor call is feature-detected so a missing function degrades the report rather than erroring out.

Output goes to a JSON file plus a console summary. Hand the JSON back for analysis.

```lua
--!nocheck
-- Passive anti-cheat reconnaissance. Read-only.
-- Adjust KEYWORDS to the game before running; the defaults are generic.

local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local Players     = game:GetService("Players")

local OUT_PATH = "ac_recon.json"

local KEYWORDS = {
    "anti", "cheat", "detect", "guard", "secure", "protect",
    "report", "flag", "ban", "kick", "violation", "suspicious",
    "exploit", "hack", "integrity", "validate", "sanity",
}

local SIGNAL_NAMES = { "Heartbeat", "Stepped", "RenderStepped", "PreSimulation", "PostSimulation" }

-- Probe the global env, not the getgenv() table: several executors expose
-- functions on the Roblox globals only, and an indexed probe reports them
-- missing. Feature detection that under-reports is worse than none.
local has = function(name) return typeof((getfenv or getgenv)()[name]) == "function" end
local function try(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local report = {
    generatedAt   = os.time(),
    placeId       = game.PlaceId,
    gameId        = game.GameId,
    executor      = has("identifyexecutor") and select(1, identifyexecutor()) or "unknown",
    capabilities  = {},
    scripts       = {},
    nilInstances  = {},
    actors        = {},
    modules       = {},
    gcCandidates  = {},
    connections   = {},
    renderStepped = {},
    notes         = {},
}

-- Record which discovery functions this executor actually has.
for _, name in {
    "getscripts", "getrunningscripts", "getloadedmodules", "getnilinstances",
    "getactors", "getgc", "filtergc", "getscripthash", "getfunctionhash",
    "getconnections", "getrendersteppedlist", "getsenv", "islclosure",
} do
    report.capabilities[name] = has(name)
end

local function score(path, constants, isNil, connCount)
    local s, hits = 0, {}
    local lower = string.lower(path or "")
    for _, kw in KEYWORDS do
        if string.find(lower, kw, 1, true) then
            s += 3
            table.insert(hits, "path:" .. kw)
        end
    end
    for _, c in constants or {} do
        if typeof(c) == "string" then
            local lc = string.lower(c)
            for _, kw in KEYWORDS do
                if string.find(lc, kw, 1, true) then
                    s += 2
                    table.insert(hits, "const:" .. c)
                    break
                end
            end
        end
    end
    if isNil then s += 4; table.insert(hits, "nil-parented") end
    if connCount and connCount > 0 then s += connCount end
    return s, hits
end

-- 1. Scripts, running and otherwise
if has("getscripts") then
    for _, s in try(getscripts) or {} do
        local ok, path = pcall(function() return s:GetFullName() end)
        local entry = {
            path      = ok and path or "<unreachable>",
            class     = s.ClassName,
            hash      = has("getscripthash") and try(getscripthash, s) or nil,
            nilParent = s.Parent == nil,
            actor     = try(function() return s:FindFirstAncestorOfClass("Actor") end) ~= nil,
        }
        entry.score, entry.hits = score(entry.path, nil, entry.nilParent, nil)
        table.insert(report.scripts, entry)
    end
end

-- 2. Nil-parented instances: the classic hiding spot
if has("getnilinstances") then
    for _, inst in try(getnilinstances) or {} do
        if inst:IsA("LuaSourceContainer") then
            table.insert(report.nilInstances, {
                name  = inst.Name,
                class = inst.ClassName,
                hash  = has("getscripthash") and try(getscripthash, inst) or nil,
            })
        end
    end
end

-- 3. Actors: separate VMs, invisible to main-VM hooks
if has("getactors") then
    for _, actor in try(getactors) or {} do
        local ok, path = pcall(function() return actor:GetFullName() end)
        table.insert(report.actors, ok and path or "<unreachable>")
    end
    if #report.actors > 0 then
        table.insert(report.notes,
            "Actors present. Checks inside them are invisible from the main VM - see actors-parallel.md")
    end
end

-- 4. Loaded modules
if has("getloadedmodules") then
    for _, m in try(getloadedmodules) or {} do
        local ok, path = pcall(function() return m:GetFullName() end)
        local entry = {
            path = ok and path or "<unreachable>",
            hash = has("getscripthash") and try(getscripthash, m) or nil,
        }
        entry.score, entry.hits = score(entry.path, nil, false, nil)
        if entry.score > 0 then table.insert(report.modules, entry) end
    end
end

-- 5. GC sweep: finds closures whose script Instance no longer exists
if has("filtergc") and has("islclosure") then
    for _, kw in { "Detected", "detected", "Flagged", "Violation", "AntiCheat", "Kick" } do
        local found = try(filtergc, "function", { Constants = { kw }, IgnoreExecutor = true }, false)
        for _, fn in (typeof(found) == "table" and found or { found }) do
            if typeof(fn) == "function" and islclosure(fn) then
                local consts = try(debug.getconstants, fn) or {}
                local strings = {}
                for _, c in consts do
                    if typeof(c) == "string" and #c < 64 then table.insert(strings, c) end
                end
                local src = try(function() return debug.info(fn, "s") end)
                local entry = {
                    matchedKeyword = kw,
                    source         = src,
                    name           = try(function() return debug.info(fn, "n") end),
                    hash           = has("getfunctionhash") and try(getfunctionhash, fn) or nil,
                    nups           = try(function() return debug.info(fn, "u") end),
                    constants      = strings,
                }
                entry.score, entry.hits = score(src or "", consts, false, nil)
                table.insert(report.gcCandidates, entry)
            end
        end
    end
end

-- 6. Connection census on the usual polling signals
if has("getconnections") then
    for _, signalName in SIGNAL_NAMES do
        local signal = RunService[signalName]
        if signal then
            local conns = try(getconnections, signal) or {}
            local lua, foreign = 0, 0
            for _, c in conns do
                if c.LuaConnection then lua += 1 else foreign += 1 end
            end
            report.connections[signalName] = { total = #conns, lua = lua, foreign = foreign }
        end
    end
    local idled = try(function() return getconnections(Players.LocalPlayer.Idled) end)
    if idled then report.connections.Idled = { total = #idled } end
end

-- 7. BindToRenderStep callbacks: getconnections cannot see these
if has("getrendersteppedlist") then
    for _, entry in try(getrendersteppedlist) or {} do
        table.insert(report.renderStepped, tostring(entry))
    end
end

-- Rank and emit
table.sort(report.scripts, function(a, b) return (a.score or 0) > (b.score or 0) end)
table.sort(report.gcCandidates, function(a, b) return (a.score or 0) > (b.score or 0) end)

local encoded = HttpService:JSONEncode(report)
if typeof(writefile) == "function" then
    pcall(writefile, OUT_PATH, encoded)
end

print(("[recon] executor=%s scripts=%d nil=%d actors=%d modules=%d gc=%d")
    :format(report.executor, #report.scripts, #report.nilInstances,
            #report.actors, #report.modules, #report.gcCandidates))
print(("[recon] written to %s"):format(OUT_PATH))
for i = 1, math.min(5, #report.scripts) do
    local s = report.scripts[i]
    print(("  #%d [%d] %s"):format(i, s.score or 0, s.path))
end
```

**Adjust `KEYWORDS` to the game before running.** The defaults are generic; a game's anti-cheat may be named after the game, a person, or nothing at all — in which case the `gcCandidates` and connection census carry the signal instead of the name matching.

### If it comes back empty

That is a result, not a failure. Read it in this order:

1. **`capabilities` all false** → the executor lacks the discovery functions. Nothing here will work; that is an executor limitation, not a hidden anti-cheat.
2. **Scripts found but nothing scores** → the anti-cheat is named neutrally. Fall back to the connection census (an unusual number of `Heartbeat` connections is itself a signal) and to `getsenv` on suspicious scripts.
3. **`actors` non-empty** → run the enumeration *inside* the Actor. See `../technique/actors-parallel.md`; the main VM genuinely cannot see in.
4. **Everything empty** → the game may have only server-side checks, which no client recon will find and no client script can bypass. Say so rather than escalating.

Passive scanning is where this file stops. If it is inconclusive, the next step is targeted hooking using the patterns in `../api/closures.md` and `../templates/script-templates.md` — chosen deliberately, not sprayed.

---

## Reading the results

| Finding | What it means | Next step |
|---|---|---|
| High-scoring script path | Named anti-cheat, probably not obfuscated | `getsenv(script)` for its environment, `decompile` if supported |
| Nil-parented LuaSourceContainer | Deliberately hidden | Hash it; find its closures via `filtergc` |
| `gcCandidates` with report-shaped constants | You likely have the reporting function | Go to the chokepoint section below |
| Many `Heartbeat` / `Stepped` Lua connections | Polling checks | Identify each before disabling any — blanket-disabling breaks the game |
| `Idled` connection present | AntiAFK detection watching `.Connected` | `:Disable()`, never `:Disconnect()` |
| `renderStepped` entries | Per-frame checks invisible to `getconnections` | Inspect before touching |
| Actors present | Isolated VM | `run_on_actor` + comm channel |

### From a candidate to its reporting path

```lua
-- 1. Script environment: its globals, its locals-turned-upvalues
local env = getsenv(candidateScript)
for k, v in env do print(k, typeof(v)) end

-- 2. Its internal functions, without executing them
for i, proto in debug.getprotos(someFunction) do
    print(i, debug.info(proto, "n"), table.concat(debug.getconstants(proto), ", "))
end

-- 3. The remote it reports through: look for a RemoteEvent reference
--    in the environment or in the constants of the reporting function
```

---

## The central technique — hook the chokepoint, not the checks

**Many checks, one reporting path.** An anti-cheat with thirty detections usually funnels all of them through a single function that talks to the server. Neutralising that one function silences every check at once, and it is far less work and far less conspicuous than fighting thirty checks individually.

Adonis is the well-documented public example: two modules (`Anti` and `Anti Cheat`) with different detection logic, **both reporting through one shared function named `Detected`**.

### The method

**1. Locate by constant, not by name.**

Names get stripped; strings survive. The public Adonis bypass keys on `" - On Xbox"` and `" - On mobile"` — incidental strings inside the reporter that have stayed unchanged across versions. Pick constants that are *incidental to the logic*, not ones a developer would think to rename.

```lua
local reporter = filtergc("function", {
    Constants = { " - On Xbox", " - On mobile" },   -- version-stable strings
    IgnoreExecutor = true,
}, true)
```

**2. Pre-empt the self-integrity check. This is the step most attempts miss.**

Anti-cheats inspect their own reporter. Hook it naively and `debug.info` immediately reveals a changed function — you are caught before the hook ever does anything.

So: cache the target's `debug.info` metadata *first*, then hook `debug.info` itself to return the cached values for that specific function and delegate everything else to the original.

```lua
-- Take the AUTHENTIC debug.info from the Roblox environment,
-- not the global, which may already be hooked.
local realInfo = getrenv().debug.info

-- Cache the pristine metadata before touching anything
local cached = {
    s = realInfo(reporter, "s"),
    l = realInfo(reporter, "l"),
    n = realInfo(reporter, "n"),
    a = realInfo(reporter, "a"),
    u = realInfo(reporter, "u"),
}

local oldInfo
oldInfo = hookfunction(realInfo, newcclosure(function(target, what, ...)
    if target == reporter and cached[what] ~= nil then
        return cached[what]
    end
    return oldInfo(target, what, ...)
end))
```

`getrenv()` matters here. Reading `debug.info` off the global table gets you whatever is currently installed there — possibly your own earlier hook, possibly something else's.

**3. Then neutralise the reporter — and never by erroring.**

```lua
local oldReporter
oldReporter = hookfunction(reporter, newcclosure(function(...)
    -- Yield forever: the caller waits, nothing reaches the server,
    -- and no error propagates.
    coroutine.yield()
end))
```

Returning a truthy value works where the caller expects a result. **Do not `error()`.** A thrown error from the reporting path is louder than the detection it was carrying — many anti-cheats treat an exception inside their own reporter as a detection in itself.

**4. Result:** detection logic keeps running and keeps looking alive. The reporting path is dead. Nothing about the anti-cheat's observable behaviour says it was touched.

### The four reporting shapes

Recognise which one you have; each takes a different tool.

| Shape | How it looks | Tool |
|---|---|---|
| **Shared reporter function** | Every check calls `Detected(reason)` | `hookfunction` + the `debug.info` pre-hook above |
| **Direct remote fire** | Checks call `ReportRemote:FireServer(...)` themselves | `__namecall` hook filtering that remote |
| **BindableEvent fan-in** | Checks `:Fire()` a Bindable; one listener reports | `getconnections(bindable.Event)` → `:Disable()` |
| **Queued and drained** | Checks append to a table; a timer flushes it | `debug.setupvalue` to swap the queue for a dummy, or disable the flush connection |

The queued shape is the one people misdiagnose most: disabling the check connections does nothing if the flush loop is the thing that talks to the server, and vice versa. The recon script's connection census plus the `gcCandidates` constants usually tell you which you have.

---

## What actually flags people

Concrete, documented client-side detections. Knowing these is what turns "I keep getting flagged" into a specific answer.

### Asset-ID scanning
Known exploit-tool asset IDs are matched against loaded assets, commonly by intercepting `ContentProvider:PreloadAsync` over `CoreGui`:

| Asset ID | Tool |
|---|---|
| `5642383285` | Dex Explorer |
| `1204397029` | Infinite Yield / Reborn |
| `4702850565` | Hydroxide |

Some implementations go further and flag *any* asset whose `Creator.CreatorTargetId ~= 1` (not created by Roblox). Countered by not loading known-fingerprinted assets, and by keeping UI out of `CoreGui` — use `gethui()`.

### GUI enumeration
`CoreGui` / `PlayerGui` swept for known GUI names. Same counter: `gethui()`, and do not ship default library names.

### Stack-depth probing
Recurse to near the maximum stack depth (~16,379 frames), then trigger a metamethod. A hook that adds stack frames overflows early, revealing itself:

```lua
-- What the anti-cheat runs (paraphrased from the public version)
local Check
Check = function(n)
    if n < 16379 then Check(n + 1) else Func(workspace, "Name") end
end
local ok, err = pcall(Check, 1)
-- not ok and err:find("stack overflow")  →  hook present
```

Relies on undocumented client behaviour and is itself a client-side script that can be located and disabled. But it is real, and it catches hooks that add net stack depth. `newcclosure` changes the stack accounting, which is part of why it is not optional.

### Environment-poisoning scans
`getfenv()` walked across stack levels 0–20 inside an error handler, looking for executor functions that leaked into a visible environment. Triggered deliberately by forcing errors — calling a non-existent method, passing wrong types to builtins, arithmetic on a `newproxy`.

**Defeated by a proper `hookmetamethod`**, which replaces the function pointer directly and leaks no environment. Community assessment is that this catches naive and pasted implementations, not correctly-wrapped hooks. Another reason the `newcclosure` rules in `../api/closures.md` are correctness requirements rather than style.

### Connection `.Connected` polling
The standard AntiAFK pattern: connect to `Player.Idled`, then poll whether the connection is still alive. `:Disable()` leaves `.Connected == true`; `:Disconnect()` does not. Covered in `detection-surface.md`.

---

## Limits — state these plainly

- **In-VM Luau only.** Everything here runs after injection succeeded. None of it touches Hyperion; that is the executor's problem, not a script's.
- **Detection and enforcement are separate.** Games routinely log silently and ban in waves. "It worked and I wasn't banned" is not evidence of being undetected.
- **Hashes and constants expire.** An anti-cheat update changes both. Re-run recon after any game update rather than trusting a stored hash, index, or offset.
- **Server-side checks are invisible here and unreachable from here.** If recon finds nothing client-side, the checks may simply be on the server — in which case there is nothing to bypass, only the game's own validation doing its job. See `../technique/client-feasibility.md`.
- **Some games have no client anti-cheat at all.** An empty report can be the correct answer.

---

## Related references
- `detection-surface.md` — avoiding detection; hook hygiene; Hyperion context
- `../api/environment.md` — `filtergc` option tables, `getsenv`, `getnilinstances`, `cloneref`
- `../api/debug.md` — `getconstants`, `getprotos`, `setupvalue`, C-closure guard
- `../technique/actors-parallel.md` — reaching anti-cheat isolated in an Actor VM
- `../api/closures.md` — `hookfunction` upvalue rules, `newcclosure` requirements
- `../technique/client-feasibility.md` — when there is nothing client-side to find
