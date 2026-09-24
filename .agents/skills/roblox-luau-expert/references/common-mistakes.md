# Common mistakes — ranked defect catalog

Ordered by how much damage they do in production, not by how often they are
talked about. Each entry: the symptom you will actually observe, the cause, the
wrong code, the right code, and how to detect it before a player does.

Consult this before writing non-trivial code and when reviewing.

---

## 1. Connections that are never disconnected

**Symptom** — server memory climbs steadily across rounds. Handlers fire two,
then three, then eight times for one action. Ghost damage from a weapon the
player dropped ten minutes ago.

**Cause** — `:Connect()` returns an `RBXScriptConnection`. The signal holds a
reference to your closure, and the closure holds everything it captured. The
usual trap: connections are cleaned up when *the instance the signal belongs to*
is destroyed — and `Player` objects are **not** destroyed when a player leaves.
Neither is the character model, unless you destroy it. So every
`player.CharacterAdded:Connect` you make and never drop is permanent.

```lua
-- WRONG: a new connection every respawn, none ever released
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid").Died:Connect(function()
            handleDeath(player)
        end)
    end)
end)
```

```lua
-- RIGHT: one owner per player, torn down on leave
local connectionsByPlayer: { [Player]: { RBXScriptConnection } } = {}

local function trackPlayer(player: Player)
    local owned = {}
    connectionsByPlayer[player] = owned

    table.insert(owned, player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
        if not humanoid then return end
        -- Dies with the character, so it needs no manual teardown.
        humanoid.Died:Connect(function()
            handleDeath(player)
        end)
    end))
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(player)
    for _, connection in connectionsByPlayer[player] or {} do
        connection:Disconnect()
    end
    connectionsByPlayer[player] = nil
end)
```

Better still: one `Trove` or `Janitor` per player, `:Destroy()` on leave. See
`roblox-architecture`.

**Detect** — log `collectgarbage("count")` every 30 s. A leak climbs
monotonically with no plateau. Studio's Memory tab under *LuauHeap* shows which
closures are retained. `getconnections` on the signal (executor side) shows the
duplicate count directly.

---

## 2. Trusting the client with anything that matters

**Symptom** — a player has currency, items, or kill counts the game never
granted. Damage numbers that do not match any weapon.

**Cause** — the remote handler used a client-supplied value as truth.

```lua
-- WRONG: the client says how much damage it did
DamageRemote.OnServerEvent:Connect(function(player, target, amount)
    target.Humanoid:TakeDamage(amount)
end)
```

```lua
-- RIGHT: the client says what it did; the server decides what that means
local WEAPON_DAMAGE = { Sword = 25, Axe = 40 }
local MAX_REACH_STUDS = 12

DamageRemote.OnServerEvent:Connect(function(player, target)
    if typeof(target) ~= "Instance" or not target:IsA("Model") then return end

    local attacker = player.Character
    local weapon = attacker and attacker:FindFirstChildOfClass("Tool")
    local damage = weapon and WEAPON_DAMAGE[weapon.Name]
    if not damage then return end

    local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
    local attackerRoot = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not (targetHumanoid and targetRoot and attackerRoot) then return end

    if (targetRoot.Position - attackerRoot.Position).Magnitude > MAX_REACH_STUDS then
        return
    end
    if isOnCooldown(player, "swing") then return end
    setCooldown(player, "swing", 0.4)

    targetHumanoid:TakeDamage(damage)
end)
```

The shape that generalises: **the client sends intent, never outcome.**

**Detect** — read every `OnServerEvent` handler and ask what happens if each
argument is a hostile value of the wrong type, out of range, or referencing
something the player does not own. See `roblox-game-security`.

---

## 3. Not re-validating after a yield

**Symptom** — `attempt to index nil with 'Character'` in code that "obviously"
already checked. Data written for a player who left. Errors that only appear
under load.

**Cause** — every `task.wait`, `WaitForChild`, `:GetAsync`, `:InvokeClient`,
`:LoadAsync` and remote round-trip is a suspension point. The world changes
across it.

```lua
-- WRONG
local function reward(player: Player)
    task.wait(3)
    player.leaderstats.Coins.Value += 100   -- player may have left
end
```

```lua
-- RIGHT
local function reward(player: Player)
    task.wait(3)
    if not player.Parent then return end     -- left the game

    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins") :: IntValue?
    if not coins then return end

    coins.Value += 100
end
```

`player.Parent == nil` is the canonical "has left" test — `Players:GetPlayers()`
membership works too, but is O(n).

**Detect** — grep for `task.wait`, `WaitForChild`, `Async` inside functions that
take a `Player` or `Instance`, and check the next few lines re-validate.

---

## 4. DataStore written without session locking or a close handler

**Symptom** — item duplication across servers. Progress lost on a shutdown.
Rollbacks that players correctly describe as "the game ate my save".

**Cause** — three separate bugs usually shipped together: `SetAsync` where a
read-modify-write was needed, no session lock so two servers write the same
profile, and no `BindToClose` so an orderly shutdown drops the last write.

```lua
-- WRONG
local function save(player, data)
    store:SetAsync(tostring(player.UserId), data)   -- clobbers concurrent writes
end
```

```lua
-- RIGHT (raw DataStore; prefer a library — see below)
local function save(player: Player, data: PlayerData)
    local key = tostring(player.UserId)
    local ok, err = pcall(function()
        store:UpdateAsync(key, function(old)
            if old and old.version > data.version then
                return nil    -- newer data exists; abandon this write
            end
            return data
        end)
    end)
    if not ok then
        warn(("[save] %s failed: %s"):format(key, tostring(err)))
    end
    return ok
end

game:BindToClose(function()
    for _, player in Players:GetPlayers() do
        task.spawn(save, player, getData(player))
    end
    task.wait(3)   -- Studio gives ~1s, live servers ~30s
end)
```

For real player data, use a maintained library rather than rolling this:
**Lyra** or **ProfileStore/ProfileService**. They handle session locking,
retries and migrations, which is most of the difficulty. See
`roblox-data-persistence`.

**Detect** — grep for `SetAsync`. Every hit needs a justification. Then check
`BindToClose` exists at all.

---

## 5. Discarding the `pcall` success flag

**Symptom** — a nil value flows deep into the system and errors somewhere
unrelated. The real failure is invisible.

```lua
-- WRONG
local _, data = pcall(function() return store:GetAsync(key) end)
applyData(data)     -- data is the ERROR MESSAGE when the call failed
```

```lua
-- RIGHT
local ok, result = pcall(function()
    return store:GetAsync(key)
end)
if not ok then
    warn(("[load] %s failed: %s"):format(key, tostring(result)))
    return nil
end
return result
```

On failure the second return is the error, not your value. Assigning it to
`data` means you hand a string to code expecting a table.

**Detect** — grep `pcall` and confirm the first return is bound and branched on.
`local _, ` before `pcall` is always a bug.

---

## 6. Direct indexing of children that may not exist

**Symptom** — `attempt to index nil with 'Handle'`, usually only on some
clients, usually only sometimes.

**Cause** — `workspace.Map.Door.Handle` is four separate lookups, each of which
can be nil during replication, streaming, or before the map loads.

```lua
-- WRONG
local handle = workspace.Map.Door.Handle

-- RIGHT when you know it arrives eventually
local map = workspace:WaitForChild("Map", 10)
if not map then return end
local door = map:WaitForChild("Door", 5)
if not door then return end

-- RIGHT when it is genuinely optional
local handle = workspace:FindFirstChild("Map")
    and workspace.Map:FindFirstChild("Door")
    and workspace.Map.Door:FindFirstChild("Handle")
```

**Detect** — grep for chained dot access three or more levels deep off
`workspace`, `ReplicatedStorage` or a character model.

---

## 7. `WaitForChild` with no timeout

**Symptom** — a script silently does nothing forever. No error, no warning. The
worst failure mode there is, because there is nothing to search for.

```lua
-- WRONG: hangs forever if the name is misspelled or the object never arrives
local gui = playerGui:WaitForChild("MainMenu")

-- RIGHT
local gui = playerGui:WaitForChild("MainMenu", 10)
if not gui then
    warn("[ui] MainMenu never appeared under PlayerGui")
    return
end
```

Roblox does emit an "Infinite yield possible" warning after 5 s, but it is a
warning in a noisy output window, not a failure.

**Detect** — grep `WaitForChild(` and check for a second argument.

---

## 8. Assuming client property writes replicate to the server

**Symptom** — "it works on my screen but nobody else sees it", or "the server
does not know I changed it".

**Cause** — property assignment **does not** replicate client to server. What
crosses upward is a short list: physics for assemblies the client owns,
character and `Motor6D` transforms, remote calls, and `replicatesignal`. Nothing
else.

```lua
-- WRONG (LocalScript): server still sees 16
humanoid.WalkSpeed = 100
```

```lua
-- RIGHT: ask the server, let it decide
SpeedBoostRemote:FireServer()      -- server validates, then sets WalkSpeed
```

This one fact answers most "it resets" questions on both sides of the fence.
Full detail: `roblox-networking/references/replication-model.md`; the executor
angle is `roblox-executor/references/technique/replication-exploitation.md`.

---

## 9. `0` and `""` treated as falsy

**Symptom** — a branch runs when it should not. Ported logic from JavaScript or
Python that is subtly wrong.

**Cause** — in Lua only `nil` and `false` are falsy. `0`, `""`, `{}` and `NaN`
are all truthy.

```lua
-- WRONG: this branch runs when count is 0
if not count then
    return "no items"
end

-- RIGHT
if count == nil or count == 0 then
    return "no items"
end
```

The related trap: `x = value or default` silently replaces a legitimate `false`
or `0`. Use an explicit `if value == nil then` when `false`/`0` are valid.

---

## 10. `table.remove` inside a forward loop over the same table

**Symptom** — every other element is skipped. Loops "mostly work", which is
worse than failing.

```lua
-- WRONG: removing shifts everything down, then i advances past the shifted item
for i = 1, #items do
    if items[i].expired then
        table.remove(items, i)
    end
end
```

```lua
-- RIGHT: iterate backwards
for i = #items, 1, -1 do
    if items[i].expired then
        table.remove(items, i)
    end
end
```

For large tables, building a new filtered table is faster than repeated
`table.remove`, which is O(n) per call.

---

## 11. `:Destroy()` without clearing your own references

**Symptom** — memory that does not come back after cleanup that "works".

**Cause** — `Destroy` parents to nil, locks the instance and disconnects *its*
signals. It does not remove the instance from **your** table. As long as your
table holds it, it cannot be collected.

```lua
-- WRONG
activeProjectiles[id]:Destroy()          -- table still holds a dead instance

-- RIGHT
activeProjectiles[id]:Destroy()
activeProjectiles[id] = nil
```

The same applies to caches keyed by `Player` or `Instance`. If you must hold
references across lifetimes, a weak-keyed table (`setmetatable(t, {__mode="k"})`)
lets the GC do it for you.

---

## 12. `RemoteFunction:InvokeClient` on the server

**Symptom** — a server thread hangs indefinitely. One player takes down a
system for everyone.

**Cause** — the invoking thread waits for the client to return. A client that
never returns — or an exploiter who deliberately errors or stalls — blocks that
thread forever. There is no timeout parameter.

```lua
-- WRONG
local answer = AskRemote:InvokeClient(player)   -- may never return
```

```lua
-- RIGHT: two one-way events with a server-side deadline
AskRemote:FireClient(player, requestId)

local responded = false
AnswerRemote.OnServerEvent:Connect(function(fromPlayer, id, payload)
    if fromPlayer ~= player or id ~= requestId then return end
    responded = true
    handle(payload)
end)

task.delay(5, function()
    if not responded then handleTimeout(player) end
end)
```

Client-to-server `InvokeServer` is fine — the server is trusted to return.

---

## 13. Yielding inside an event handler that must stay fast

**Symptom** — `.Touched` fires late or misses. Input feels laggy. Physics
handlers back up under load.

**Cause** — Roblox resumes a yielded handler on a later frame, and other
handlers on the same signal queue behind it.

```lua
-- WRONG
part.Touched:Connect(function(hit)
    task.wait(1)                -- blocks this signal's dispatch
    applyEffect(hit)
end)

-- RIGHT
part.Touched:Connect(function(hit)
    task.spawn(function()
        task.wait(1)
        applyEffect(hit)
    end)
end)
```

`.Touched` additionally fires many times per contact — debounce it, or the
`task.spawn` above becomes a thread flood.

---

## 14. Deprecated APIs that still "work"

**Symptom** — none immediately. That is the problem: they are removed or
degraded later, and they are slower or less correct now.

| Deprecated | Use |
|---|---|
| `wait()` / `spawn()` / `delay()` | `task.wait` / `task.spawn` / `task.delay` |
| `BodyVelocity` / `BodyPosition` / `BodyGyro` | `LinearVelocity` / `AlignPosition` / `AlignOrientation` |
| `FindPartOnRay` and its variants | `WorldRoot:Raycast` with `RaycastParams` |
| `FindPartsInRegion3*` | `WorldRoot:GetPartBoundsInBox` with `OverlapParams` |
| Legacy `Chat` service | `TextChatService` |
| `Instance:Remove()` | `Instance:Destroy()` |
| `Player:Kick` as enforcement | `Players:BanAsync` (persists) |

`task.wait` is not merely a rename: `wait()` is throttled and drifts, and
returns delta time from a different clock.

**Superseded but not deprecated** — a separate category, do not conflate them.
`RunService.Stepped`, `.RenderStepped` and `.Heartbeat` carry **no**
`[Deprecated]` flag in the dump. `PreSimulation`, `PreRender` and
`PostSimulation` are the current names for the same points in the frame, and are
what new code should use, but the old names are not scheduled for removal and
existing code using them is not defective. Claiming otherwise in a review is a
false positive.

The globals `wait`, `spawn` and `delay` are Luau globals rather than class
members, so `verify-api.mjs` will not find them — they are absent from the class
dump by design, not missing.

Full generated list: `verified/deprecated-apis.md` (700 entries). Never answer
from memory here — grep it.

---

## 15. Recommending an API the calling script cannot reach

**Symptom** — the code errors on the property access itself, or silently reads
nothing.

**Cause** — the API exists but is gated. `Workspace.AuthorityMode` is the
canonical case: real, documented, and `RobloxScript`-only. A `Script` or
`LocalScript` cannot read it. An executor at an elevated identity can — which is
exactly why it shows up in exploit references and misleads people into using it
in game code.

```powershell
node tools/bin/verify-api.mjs AuthorityMode
#   Property Workspace.AuthorityMode: Enum.AuthorityMode {RobloxScript}
#     SECURITY RobloxScript  A normal Script or LocalScript CANNOT touch this.
```

**Detect** — grep `verified/security-tagged-apis.md` before handing over any API
you have not used recently.

---

## 16. Overflowing a Luau compiler limit

**Symptom** — the script will not compile at all, with one of four distinct
errors: too many local variables (200), too many upvalues (255), too many
registers, or too many constants / instructions.

**Cause** — usually a long flat script with one local per config value, or a
hook capturing dozens of upvalues.

The fix is nearly always the same: group into a table, so 60 locals become 1.
Full treatment including which error maps to which limit:
`roblox-luau-language/references/compiler-limits.md`.

---

## 17. Instance-keyed tables that outlive the instances

**Symptom** — memory grows with total players seen, not concurrent players.

```lua
-- WRONG: never cleared
local scores: { [Player]: number } = {}
Players.PlayerAdded:Connect(function(p) scores[p] = 0 end)

-- RIGHT
Players.PlayerRemoving:Connect(function(p) scores[p] = nil end)
```

Every `[Player]` or `[Instance]` keyed table needs a matching removal, or a weak
`__mode = "k"` metatable.

---

## 18. `:GetChildren()` in a hot loop

**Symptom** — frame time spikes proportional to child count.

**Cause** — `GetChildren` allocates a new table every call. In a
`Heartbeat`/`PostSimulation` loop over 200 parts that is 200 table allocations
per frame, all immediately garbage.

Cache the list and update it on `ChildAdded`/`ChildRemoved`, or use
`CollectionService` tags with `GetInstanceAddedSignal`.

---

## 19. Rate limits ignored on remotes

**Symptom** — one client can spam a remote thousands of times per second and
either exhaust a DataStore budget or lock up a server loop.

Every `OnServerEvent` handler that does real work needs a per-player cooldown.
There is no engine-level rate limit; `FireServer` is unbounded from the client.

```lua
local lastFired: { [Player]: number } = {}

local function allow(player: Player, minInterval: number): boolean
    local now = os.clock()
    if lastFired[player] and now - lastFired[player] < minInterval then
        return false
    end
    lastFired[player] = now
    return true
end
```

Clear `lastFired[player]` on `PlayerRemoving` — see mistake 17.

---

## 20. Assuming `Character` exists on `PlayerAdded`

**Symptom** — `attempt to index nil with 'HumanoidRootPart'` at join, sometimes.

**Cause** — `PlayerAdded` fires before the character spawns. It may also already
have spawned if your script loaded late.

```lua
-- RIGHT: handles both orders
local function onCharacter(character: Model) end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        onCharacter(player.Character)
    end
end)
```

The same both-orders pattern applies to `PlayerAdded` itself in a script that
may load after players have joined.

---

## 21. Writing to the DataModel from a parallel context

**Symptom** — "Attempted to call a function that is not thread-safe" or silent
inconsistency inside an `Actor`.

**Cause** — parallel Luau permits reads but not most writes.
`verified/parallel-safety.md` lists what the engine explicitly marks `Safe` and
`Unsafe`; anything unmarked is not a promise either way.

Working rule: compute in parallel, `task.synchronize()` before touching the
DataModel. See `roblox-performance`.

---

## 22. Executor — hooking without `checkcaller`

**Symptom** — your own script triggers the anti-cheat you installed the hook to
dodge, or your hook recurses into itself and stack-overflows.

```lua
-- RIGHT shape
local original
original = hookfunction(target, newcclosure(function(...)
    if checkcaller() then
        return original(...)      -- our own call; pass through untouched
    end
    return original(...)
end))
```

Full rules including the upvalue limit on hooks and C-closure restrictions:
`roblox-executor/references/api/closures.md`.

---

## 23. Executor — using a function without feature detection

**Symptom** — the script dies on line 1 for most of its users.

Executor support varies per executor and per update. There is no universal
surface.

```lua
if typeof(getrendersteppedlist) ~= "function" then
    warn("your executor lacks getrendersteppedlist; skipping ESP")
    return
end
```

Report honestly when a function is missing rather than writing a fallback that
silently does nothing.

---

## 24. Executor — hardcoding upvalue or constant indexes

**Symptom** — the script works today and breaks after the game updates.

Indexes shift whenever the target function is recompiled. Search by value or by
name and act on what you find:

```lua
for i, v in debug.getupvalues(fn) do
    if v == 25 then debug.setupvalue(fn, i, 9999) end
end
```

---

## 25. Over-engineering a small script

**Symptom** — 400 lines, five modules, an event bus and a dependency injector,
to make a door open.

Roblox codebases rot from premature abstraction more often than from missing
abstraction. No interface without two real implementations. No module without a
second caller. No config table for a value used once.

`roblox-code-craft/references/code-signature.md` covers the tells and the
review pass.

---

## Quick review pass

When reviewing Roblox code, these five catch most of the damage:

1. Every `OnServerEvent` handler — does it validate type, range, ownership, rate?
2. Every `:Connect` — who disconnects it?
3. Every `pcall` — is the first return checked?
4. Every yield — is there a re-validation after it?
5. Every Roblox API you do not recognise — `verify-api.mjs`.
