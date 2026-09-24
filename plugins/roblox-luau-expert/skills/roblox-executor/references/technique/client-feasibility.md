# Client Feasibility vs Server Authority (Exploit Scripting Guide)

When a user asks for an exploit / executor script, **always determine first** whether the requested feature is client-feasible or requires server authority (and is therefore impossible or only partially possible from an executor).

## Core Reality

- Executors inject and run code **only on the client**.
- The client is completely untrusted. Exploiters can modify any LocalScript, fire any RemoteEvent with arbitrary arguments, change local properties, and read anything replicated to them.
- The server is the single source of truth for all meaningful game state.
- Scripts in `ServerScriptService` and contents of `ServerStorage` are **never** visible or executable by the client/exploiter.

## What Is Client-Feasible (can be done in an executor script)

These only affect the local player’s view or local simulation:

- Local character modifications (walkspeed, jumppower, hipheight, transparency, local noclip via collision groups / CanCollide)
- Local camera / FOV / lighting changes
- Local GUI injection (Dex, Infinite Yield style menus, ESP via Drawing library or BillboardGuis)
- Firing RemoteEvents / RemoteFunctions with crafted arguments (if the server doesn’t validate)
- Reading ReplicatedStorage, Workspace (replicated parts), PlayerGui, LocalPlayer
- Hooking local metamethods / namecall (with executor APIs)
- Local animation playing, sound playing, particle effects for self
- Client-side aimbot / silent aim that only affects local input or local raycasts (visual only unless server accepts bad data)
- Teleporting **own** character locally (will usually be corrected by server if server-authoritative movement is enabled)
- Moving parts you have **network ownership** of — physics is the one property-like path that replicates upward (`replication-exploitation.md`)
- `replicatesignal(signal, ...)` on the small set of engine signals that support it — a genuine client→server channel alongside remotes
- Running code inside an **Actor** VM to reach anti-cheat isolated there (`actors-parallel.md`) — still client-side

## What Requires Server Authority (cannot be reliably done from client/executor)

These will either do nothing visible to others, get corrected, or simply fail:

- Changing another player’s health, position, inventory, or currency permanently
- Granting items, gamepasses, or developer products without server validation
- Deleting or modifying server-owned map geometry that is not network-owned by the client
- Bypassing server-side cooldowns, rate limits, or ownership checks
- Writing to DataStores or any server-only service
- Executing code inside ServerScriptService / ServerStorage
- Making changes that must replicate to other players (unless the server accepts a remote and applies them)
- True godmode / immortality against a properly validated damage system
- Server-side ban evasion or manipulating BanAsync results

## Decision Checklist (use this when the user requests a feature)

1. Does the change need to be seen by other players or persist after rejoin?  
   → Almost always needs the server. Client-only = visual / local only.

2. Does it involve currency, inventory, damage, progression, or match outcome?  
   → Server must validate. Client request alone is not enough.

3. Is the target instance in ServerStorage / ServerScriptService or marked non-replicated?  
   → Client cannot touch it.

4. Does the game use modern Server Authority / BindToSimulation for movement?  
   → Local speed/fly/noclip will be corrected or rejected.

5. Is there a RemoteEvent the client can fire that the server trusts without checks?  
   → Possible to abuse, but only because the game is insecure. Prefer telling the user the proper (validated) way and the insecure shortcut separately.

## Practical Response Pattern

When the user asks for something:

- **Client-feasible**: Provide a clean executor-compatible LocalScript / executor snippet, note any visual-only limitations, and mention detection risk.
- **Server-authoritative / impossible from client**: Clearly state “This cannot be done from an executor because the server owns that state.” Then optionally show:
  - What a secure server implementation looks like, **or**
  - The insecure remote-firing pattern that only works if the game fails to validate (with a warning).

## Common Examples

| Request                        | Feasible?     | Notes |
|--------------------------------|---------------|-------|
| Infinite yield / admin GUI     | Yes (local)   | Only you see it |
| Speed / fly / noclip           | Partial       | Local only; server may correct |
| Kill all / server-side kill    | No*           | Only if remote is unprotected |
| Give currency / items          | No*           | Only if remote is unprotected |
| ESP / wallhack                 | Yes (local)   | Drawing or local parts |
| Godmode                        | Partial       | Local health regen may work; real damage systems ignore it |
| Teleport other players         | No*           | Requires server |
| Modify DataStore               | No            | Server only |

\* = Only possible if the game’s remotes are insecure (no type/range/ownership/rate checks).

Always prefer accuracy over promising impossible client-side miracles. When in doubt, classify as server-authoritative and explain why.

## Analyzing Decompiled Game Code (Practical Exploit Workflow)

When the user provides decompiled scripts or remote names from a game, use this process to decide feasibility:

### 1. Locate the Remote
- Search decompiled client scripts for `:FireServer`, `:InvokeServer`, or `OnClientEvent`.
- Note the remote’s name, parent (usually ReplicatedStorage or a folder), and what arguments the legitimate client sends.

### 2. Find the Server Handler
- Server handlers are usually in ServerScriptService or a ModuleScript required by a server Script.
- Look for `OnServerEvent` / `OnServerInvoke`.
- Read the validation logic carefully.

### 3. Classification Rules from Decompiled Code

**Client-feasible / Abusable** if the server handler:
- Does little or no type checking
- Does not verify ownership (e.g. “is this tool actually equipped by this player?”)
- Does not check distance / cooldown / game state
- Directly applies damage, gives items, or sets currency from client-supplied values
- Uses the client’s reported position or damage number without recalculating

**Server-authoritative / Not feasible** if the server handler:
- Recalculates damage, rewards, or outcomes itself
- Checks `player.Character`, tool ownership, team, round state, etc.
- Has rate limiting or cooldowns stored on the server
- Rejects unexpected argument types or out-of-range values
- The important logic lives only in ServerScriptService / ServerStorage (not replicated)

### 4. Common Decompile Patterns

| Pattern in decompiled code                          | Feasibility                          | Action |
|-----------------------------------------------------|--------------------------------------|--------|
| Client sends damage number → server applies it      | Abusable (insecure game)            | Can fire remote with high number |
| Client sends “attack” → server calculates damage    | Not feasible from client            | Server owns the outcome |
| Client fires “BuyItem” with itemId only             | Depends on server checks            | Inspect currency + ownership checks |
| No remote; pure LocalScript character change        | Client-only (visual / local)        | Works for self only |
| Remote exists but handler is empty / missing        | Likely client-only or dead code     | Local effect only |
| Uses `BindToSimulation` / modern Server Authority   | Movement cheats **dead**, not merely limited | Read `workspace.AuthorityMode` — see the detection table in `replication-exploitation.md` |

### 5. Response Style When User Gives Decompiled Code

Always structure the answer as:

1. **Classification**: “This is client-feasible / partially feasible / server-authoritative.”
2. **Why** (quote or paraphrase the validation or lack of it).
3. **What an executor can actually do**:
   - Working snippet if feasible
   - Clear statement that it won’t work (or will only work visually / get corrected) if not
4. Optional: Show the secure way the game *should* have done it, for educational value.

### 6. Executor Reality Check
- Even if a remote is insecure, modern games may have additional server-side heuristics, honeypot remotes, or anti-cheat that detect abnormal firing rates or argument patterns.
- Local character property changes (WalkSpeed, CanCollide, etc.) are always possible but often get overwritten by the server’s replication or Server Authority simulation.
- True persistence (items, currency, bans, DataStore) is never client-feasible.

This analysis method lets the skill give accurate answers when the user pastes decompiled remotes or server handlers instead of guessing.

## Executor Capabilities vs Server Authority (from public executor docs)

Executors expose extra APIs (UNC / sUNC / legacy Synapse-style) that normal LocalScripts do not have. All of them still run **only on the client**.

### Commonly Available Executor APIs (client-only)
These are documented across sUNC, UNC, and historical Executor-API-Docs:

**Environment**
- `getgenv()` – executor’s global environment
- `getrenv()` – Roblox’s LocalScript environment
- `getgc()` / `filtergc` – inspect garbage-collected objects
- `getreg()` – Lua registry

**Closures / Hooking**
- `hookfunction(old, new)` – replace a function
- `hookmetamethod(object, metamethod, hook)`
- `newcclosure(fn)` – wrap as C closure (helps avoid some detections)
- `checkcaller()` – detect if the current call originates from the executor
- `clonefunction`, `restorefunction`, `isexecutorclosure`, `islclosure`, `iscclosure`

**Instances / Signals**
- `getconnections(signal)` – list connections on an event
- `firesignal` / enable/disable connections
- `getinstances()`, `getnilinstances()`
- `fireclickdetector`, `fireproximityprompt`, `firetouchinterest`

**Other**
- `loadstring` (when supported)
- Drawing library, mouse simulation, clipboard, file system (executor-dependent)
- `sethiddenproperty` / `gethiddenproperty` (where implemented)

### Important Limitations (still client-only)
Even with the above APIs:

- You cannot read or execute scripts inside `ServerScriptService` or `ServerStorage`.
- You cannot write to DataStores, MemoryStores, or any server-only service.
- Hooking a RemoteEvent’s `OnServerEvent` is impossible — that callback lives on the server.
- You can only hook the **client-side** side of remotes (`FireServer` / `InvokeServer` namecalls, or the local `OnClientEvent`).
- `firetouchinterest`, `fireclickdetector`, etc. only simulate the client’s input; the server still decides whether to accept the result.
- Character property changes (WalkSpeed, CanCollide, Health, etc.) remain local unless the server replicates or accepts them.
- Modern Server Authority / `BindToSimulation` will correct illegal movement even if you change local physics properties.

### Practical Decision Rule for Executor Scripts
When the user asks for a feature:

1. If it can be achieved with the APIs above **plus** normal client objects → treat as client-feasible.
2. If it requires changing server state, other players’ data, or bypassing a validated remote → classify as server-authoritative / not feasible from an executor.
3. If the game’s decompiled code shows a remote that blindly trusts client arguments → it may be abusable **only because the game is insecure**, not because the executor has server power.

Always state the distinction clearly so the user understands whether the script will work for everyone, only visually for themselves, or not at all.

## Advanced Environment Functions for Anti-Cheat Awareness

When dealing with more sophisticated client anti-cheats:

- Use `getactors()` (if the executor supports it) to discover parallel VMs. Some ACs isolate checks inside Actors. Injecting into one requires `run_on_actor` plus a comm channel — full pattern in `actors-parallel.md`.
- Use `getrunningscripts()`, `getscripts()`, `getloadedmodules()` to locate anti-cheat LocalScripts / ModuleScripts.
- Use `getcallingscript()` inside hooks to ignore or specially handle calls originating from known AC scripts.
- Prefer the cleanest hook that works: `hookmetamethod` with `newcclosure` and a
  `checkcaller` guard first, and fall back to heavier techniques only when that
  fails. Selection order is in `technique/function-selection.md`.
- Remember: even Actor-injected code remains client-side. No environment function turns a server-validated system into a client-controlled one.

Always check for function existence before use:
```lua
if typeof(getactors) == "function" then
    for _, actor in getactors() do
        -- inspect
    end
end
```

## Handling Client-Side Modifications That Get Reset (Weapons, Attributes, Stats)

This is one of the most common user complaints: “I set ammo/damage/WalkSpeed to infinite but the game resets it” or “it only shows locally”.

> **Full playbook: `value-persistence.md`.** The section below is the summary; that file has the layer ladder, the `filtergc` search forms, and the reset-source triage.

### The root cause, stated once

**Roblox does not replicate properties from client to server.** The only client→server channels are physics data for assemblies you have network ownership of, character/Motor6D transforms, RemoteEvent/RemoteFunction calls, and `replicatesignal`.

Writing `Tool.Damage = math.huge` on the client changes a number **the server never reads**. It was never going to work for other players and was never going to persist. That is not a bug in the script.

### Why it happens
1. **Server authority / replication** – The server owns the real value and periodically (or on every relevant event) writes the correct value back to the client.
2. **Local anti-cheat loops** – A LocalScript continuously sets the property back to the “legal” value.
3. **Attribute vs Property** – Many modern games store weapon data in `Attributes` or in a ModuleScript table, not in the Instance property you are writing.
4. **The change is purely visual** – You modified a client-only copy; the server never received or accepted a remote that would make the change real.

### Correct Technique Selection

| Goal | Preferred approach | Fallback if reset still occurs |
|------|--------------------|--------------------------------|
| Make a property *look* correct to the game’s own LocalScripts | `__index` spoof (return fake value on read) | Also block `__newindex` so the game cannot overwrite your spoof table |
| Stop the game from writing the real value | `__newindex` hook that ignores or redirects the write | Disable the specific connection that does the reset (`getconnections`) |
| Change a value the server actually uses | Find and fire the correct RemoteEvent with validated-looking arguments | Impossible if the server fully recalculates / owns the value |
| Hidden / non-replicated properties | `sethiddenproperty` / `gethiddenproperty` (when supported) | Combine with metamethod spoof |
| Value lives in a ModuleScript table | Hook the ModuleScript’s functions or the table’s `__index`/`__newindex` | Locate with `filtergc("table", {KeyValuePairs = …})` and write the field directly |
| **Value is a Luau upvalue or bytecode constant** | **`debug.setupvalue` / `debug.setconstant`** — changes what the game's own code reads | Locate the owning closure with `filtergc("function", {Constants = …, Upvalues = …})` |

### Practical Patterns

**1. Spoof on read + protect on write (classic for WalkSpeed, JumpPower, Ammo display)**
```lua
local Spoof = {
    WalkSpeed = 50,
    JumpPower = 100,
    -- add weapon attributes here if they are normal properties
}

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and typeof(self) == "Instance" then
        if Spoof[key] ~= nil and (self:IsA("Humanoid") or self:IsA("Tool") or self:IsA("NumberValue")) then
            return Spoof[key]
        end
    end
    return oldIndex(self, key)
end))

local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
    if not checkcaller() and Spoof[key] ~= nil then
        -- optionally update Spoof[key] = value if you want the game’s write to become the new spoof
        return -- block the write
    end
    return oldNewIndex(self, key, value)
end))
```

**2. When the game resets via a loop or connection**
```lua
-- Find and disable the resetter
for _, conn in getconnections(RunService.Heartbeat) do -- or Stepped, or a specific Bindable
    if getcallingscript and getcallingscript() then
        -- inspect or disable selectively
        conn:Disable()
    end
end
```

**3. Attributes (modern games)**
```lua
-- Attributes are not normal properties; use :GetAttribute / :SetAttribute
-- Spoofing them usually requires hooking namecall for "GetAttribute" / "SetAttribute"
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() then
        if method == "GetAttribute" then
            local attr = ...
            if attr == "Ammo" or attr == "Damage" then
                return math.huge -- or desired value
            end
        elseif method == "SetAttribute" then
            local attr, value = ...
            if attr == "Ammo" or attr == "Damage" then
                return -- block or redirect
            end
        end
    end
    return old(self, ...)
end))
```

**4. Decision flow the skill must follow**
1. Ask / determine: is the value a normal property, an Attribute, or data inside a ModuleScript?
2. Is the reset coming from a LocalScript loop or from server replication?
3. If only client-side visual is needed → Tier-1/2 metamethod spoof.
4. If the server must accept the change → look for an insecure remote; otherwise state clearly that it is server-authoritative and cannot be done from an executor.
5. Never promise “infinite ammo that works for everyone” unless the remote is proven insecure.

### Key Expert Rules
- Client-side property/attribute changes that the server does not accept will **always** be temporary or visual-only.
- The right tool is the one that matches *where the game stores and validates the value*.
- Combine spoofing (`__index`) with write protection (`__newindex`) and, when necessary, connection disabling.
- Always still classify the overall feature as client-feasible or server-authoritative first.
