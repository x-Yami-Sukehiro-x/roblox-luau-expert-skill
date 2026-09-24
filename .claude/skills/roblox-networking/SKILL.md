---
name: roblox-networking
description: Client-server communication in Roblox — RemoteEvent, RemoteFunction, UnreliableRemoteEvent, BindableEvent, what actually replicates across the boundary, network ownership, remote argument validation and rate limiting, buffer serialization and bandwidth, latency compensation, BanAsync, and cross-server work with MessagingService, TeleportService and MemoryStoreService including the TeleportData trust boundary. Use for "doesn't show for other players", "it resets", remote design, replication questions, or reducing network traffic.
---

# Networking and replication

Almost every confusing Roblox bug is a boundary bug. Answer "which side owns
this value" first and the rest usually follows.

Deep reference: `references/replication-model.md` — what crosses the wire, at
what rate, and at what cost in bytes.

---

## Load a reference when

| Need | File |
|---|---|
| what replicates, deferred signals, streaming, physics rates | `references/replication-model.md` |
| MessagingService, teleports, reserved servers, MemoryStore | `references/cross-server.md` |

---

## The one fact that explains most bugs

**Property writes do not replicate client to server.** Ever. Not for any
property, on any instance.

What *does* travel upward is a short, closed list:

1. **Physics** for assemblies the client has network ownership of — CFrame and
   velocity, at ~20 Hz.
2. **Character position and Motor6D transforms** — a special case of (1),
   because a player owns their own character.
3. **Remote calls** — `FireServer`, `InvokeServer`.
4. A small set of engine signals via `replicatesignal` (executor-side concern).

Everything else — `Size`, `Transparency`, `WalkSpeed`, attributes, instances
created on the client, values stashed in the character — stays local.

Downward (server to client) is different: the server replicates instance
creation, destruction, and property changes automatically, subject to
`StreamingEnabled` and per-instance replication rules.

This single fact answers:

- *"I set WalkSpeed on the client and the server still sees 16"* — correct, it
  never left the client.
- *"I made a part on the client and other players can't see it"* — correct,
  client-created instances are local.
- *"My change gets reset"* — the server replicated its own value over yours.

---

## Choosing the right remote

| Class | Direction | Delivery | Use for |
|---|---|---|---|
| `RemoteEvent` | both | reliable, ordered | almost everything |
| `UnreliableRemoteEvent` | both | **unreliable, unordered** | high-frequency state where the newest value wins |
| `RemoteFunction` | client→server safely; server→client **never** | reliable, blocking | request/response the caller must wait for |
| `BindableEvent` / `BindableFunction` | same side only | in-process | decoupling within one context; **not** networking |

**`UnreliableRemoteEvent`** is the right choice for anything you would happily
drop: cosmetic position updates, aim direction, footstep dust. It skips
retransmission, so a lost packet costs nothing and a slow client does not build
a queue. It has a smaller size limit than `RemoteEvent` and does **not**
guarantee ordering — never use it for anything stateful or incremental.

**Never call `RemoteFunction:InvokeClient` from the server.** The thread blocks
until the client replies, and a client that never replies — or an exploiter who
deliberately stalls — hangs that thread permanently. There is no timeout
parameter. Use two events plus a server-side deadline. See
`roblox-luau-expert/references/common-mistakes.md` entry 12.

**`BindableEvent` is not a remote.** Firing one does not cross the boundary. It
also **deep-copies tables** passed through it and drops metatables and
functions, which surprises people using it as an in-process event bus.

---

## Remote handler shape

Every server handler does the same four things before it does any work.

```lua
local COOLDOWN = 0.35
local MAX_REACH = 12
local lastUse: { [Player]: number } = {}

PurchaseRemote.OnServerEvent:Connect(function(player: Player, itemId: unknown)
    -- 1. TYPE. Arguments are whatever the client sent, regardless of annotation.
    if typeof(itemId) ~= "string" then return end
    if #itemId > 64 then return end

    -- 2. EXISTENCE / OWNERSHIP. Does this player have any right to this?
    local item = ITEM_CATALOG[itemId]
    if not item then return end
    if item.requiresLevel > getLevel(player) then return end

    -- 3. RATE. There is no engine-level rate limit on FireServer.
    local now = os.clock()
    if lastUse[player] and now - lastUse[player] < COOLDOWN then return end
    lastUse[player] = now

    -- 4. The server computes the outcome. The client supplied intent only.
    grantItem(player, item)
end)

Players.PlayerRemoving:Connect(function(player)
    lastUse[player] = nil          -- or this table grows forever
end)
```

Notes that matter:

- **Annotate untrusted arguments `unknown`, not the shape you hope for.** Types
  are erased at runtime; an annotation validates nothing. `unknown` at least
  forces the narrowing.
- **Do not reason about positional `nil`s.** Trailing `nil` arguments are
  truncated, and `nil` holes inside a table argument are lost, so an argument
  list is not a reliable shape. Whether a *leading* `nil` shifts the rest is
  not something the API dump can settle and is not worth depending on either
  way. **Pass a single table** and validate its fields by name. That removes
  the whole question.
- **Check for NaN and infinity** on any number used in a comparison:
  `if n ~= n or n == math.huge then return end`. Every comparison against NaN
  is false, so `not (n > 100)` passes.
- **Bound string lengths.** An unbounded string is a memory attack.
- **Instances passed through remotes may be destroyed or not owned.** Re-check
  `:IsDescendantOf(workspace)` and ownership.

---

## Network ownership

The owner of an assembly simulates it locally and replicates the result upward.

```lua
part:SetNetworkOwner(player)   -- that client simulates it
part:SetNetworkOwner(nil)      -- server simulates it
part:GetNetworkOwner()
part:SetNetworkOwnershipAuto()
```

- **Anchored parts have no owner** — `SetNetworkOwner` errors on them.
- **A player owns their own character.** This is why movement feels responsive,
  and why movement cheating exists: the client is genuinely authoritative over
  its own character's physics until the server disagrees.
- **Give ownership for feel, take it back for authority.** A projectile the
  shooter owns feels instant to them and laggy to everyone else. A projectile
  the server owns is fair and feels delayed to the shooter. Choose per feature,
  and say which you chose.

---

## Bandwidth

Approximate wire cost per value, useful for sizing payloads and rate limits:

| Payload | Bytes |
|---|---|
| Empty remote call | ~9 |
| number | 9 |
| string | length + 2 |
| Vector3 | 13 |
| CFrame, axis-aligned | 14 |
| CFrame, rotated | 20 |

A table costs its contents plus per-key overhead — keys are sent as strings.
`{ x = 1, y = 2, z = 3 }` is meaningfully more expensive than a `Vector3`.

### Reduce traffic in this order

1. **Send less often.** Batch per frame or per tick instead of per event. One
   remote carrying twenty updates beats twenty remotes.
2. **Send smaller types.** `Vector3` over three numbers. An id over a name. An
   index into a shared catalog over the item table.
3. **Send buffers.** For a fixed-layout, high-frequency message, a `buffer` is
   dramatically smaller than a table because there are no key names on the wire.

```lua
-- 9 bytes rather than a keyed table
local b = buffer.create(9)
buffer.writeu8(b, 0, ACTION_FIRE)
buffer.writef32(b, 1, direction.X)
buffer.writef32(b, 5, direction.Z)
CombatRemote:FireServer(b)
```

Hand-counted offsets rot. For a real protocol use a library that generates the
layout from a schema — **ByteNet** or **Blink**. Both produce typed
send/receive functions and handle batching. See `roblox-toolchain`.

---

## Replication controls worth knowing

- **`StreamingEnabled`** means the client may not have an instance the server
  does. Client code must treat "not there yet" as normal. See
  `roblox-engine-api`.
- **Last write wins within a frame.** Setting a property five times in one frame
  replicates once, with the final value. Loops that thrash a property gain
  nothing.
- **`ReplicatedFirst`** loads before anything else — for loading screens only.
- **`ServerStorage` and `ServerScriptService` never replicate.** Anything a
  client must not see goes there. `ReplicatedStorage` is visible to every
  client, including a decompiler — never put secrets or unearned item data in
  it.

---

## Latency compensation

Two honest options, and a wrong one.

**Client prediction plus server reconciliation.** The client acts immediately
and the server corrects. Correct and responsive; the cost is that you must
handle the correction visibly and gracefully. The engine now offers first-class
support via `RunService:SetPredictionMode`, `GetPredictionStatus`,
`IsResimulating` and the `Rollback` / `Misprediction` events — verify each
signature before use, this surface is newer than most documentation.

**Server authority with visual feedback.** The client plays the animation
immediately but the outcome waits for the server. Simple, fair, and feels fine
for anything that is not twitch combat.

**The wrong one: trusting the client to avoid the round trip.** It is not
latency compensation, it is an exploit with good ergonomics.

For hit registration, the defensible middle ground is client-reported *aim* with
server-side validation of plausibility: is the target within range, in line of
sight, alive, and was the shot within the shooter's rate of fire? Accept the
shot or reject it — never accept a client-reported *result*.

---

## Enforcement

```lua
local Players = game:GetService("Players")

Players:BanAsync({
    UserIds = { userId },
    Duration = 86400,              -- seconds; -1 for permanent
    DisplayReason = "Exploiting",  -- shown to the player
    PrivateReason = "speed 200 sustained 30s, telemetry id 4471",
    ExcludeAltAccounts = false,
    ApplyToUniverse = true,
})
Players:UnbanAsync({ UserIds = { userId }, ApplyToUniverse = true })
```

Both yield — wrap in `pcall` and re-validate afterwards. `BanAsync` persists and
covers alts; `Player:Kick` does not and is a speed bump at best.

Ban on evidence you would be comfortable showing the player, and log the
`PrivateReason` with enough detail to review a false positive later. See
`roblox-game-security` for what evidence is actually reliable.
