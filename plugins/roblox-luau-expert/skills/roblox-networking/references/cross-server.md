# Cross-server: messaging, teleports and shared state

Everything in `roblox-networking` up to here is one server talking to its own
clients. This file is servers talking to each other, where the trust boundary
moves and the failure modes change.

---

## Three mechanisms, three jobs

| Need | Use |
|---|---|
| Tell other servers something happened | `MessagingService` |
| Move players between places or servers | `TeleportService` |
| Shared state several servers read and write | `MemoryStoreService` |

They are not interchangeable. `MessagingService` is fire-and-forget with no
storage; `MemoryStoreService` is storage with no notification.

---

## `MessagingService`

```lua
local MessagingService = game:GetService("MessagingService")

MessagingService:PublishAsync("GlobalAnnouncement", {      -- YIELDS
    text = "Boss spawned in server " .. game.JobId,
    at = os.time(),
})

local connection = MessagingService:SubscribeAsync("GlobalAnnouncement", function(message)
    -- message.Data is what was published; message.Sent is a timestamp.
    announce(message.Data.text)
end)                                                        -- YIELDS
```

Both calls yield and both can throw — wrap them and check the result.

### What it does not promise

- **No delivery guarantee.** A message can be dropped. Never make one the only
  path for something that must happen.
- **No ordering guarantee.** Two publishes can arrive in either order.
- **The publisher receives its own message.** Guard with `game.JobId` if you do
  not want to act twice locally.
- **Rate limits and a size cap apply**, scaled by player count. A per-kill
  broadcast on a busy game will hit them.

### The shape that survives

Treat messaging as a **cache-invalidation hint**, not a data channel:

```lua
-- Publish: "something changed", not the change itself.
MessagingService:PublishAsync("ClanUpdated", { clanId = clanId })

-- Subscribe: re-read the truth from durable storage.
MessagingService:SubscribeAsync("ClanUpdated", function(message)
    refreshClanFromDataStore(message.Data.clanId)
end)
```

A dropped message then costs a stale cache until the next refresh, rather than a
lost mutation. Pair it with a periodic reconciliation pass so a drop heals.

`SubscribeAsync` returns an `RBXScriptConnection`. Disconnect it on shutdown
like any other.

---

## `TeleportService`

```lua
local TeleportService = game:GetService("TeleportService")

local options = Instance.new("TeleportOptions")
options.ShouldReserveServer = false
options:SetTeleportData({ fromLobby = true })

local ok, err = pcall(function()
    return TeleportService:TeleportAsync(placeId, { player }, options)   -- YIELDS
end)

if not ok then
    warn(("[Teleport] failed for %s: %s"):format(player.Name, tostring(err)))
    -- The player is still here. Tell them, and let them retry.
end
```

`TeleportAsync` and `ReserveServerAsync` are the live calls. These are all
`[Deprecated]`: `Teleport`, `ReserveServer`, `TeleportPartyAsync`,
`TeleportToPlaceInstance`, `TeleportToPrivateServer`, `TeleportToSpawnByName`.
Most tutorials still use them.

### Teleports fail, and you must handle it

`TeleportService.TeleportInitFailed(player, teleportResult, errorMessage, placeId, teleportOptions)`
fires when a teleport could not start. Without a handler the player is left
standing in the old place with a frozen loading screen and no idea why.

```lua
TeleportService.TeleportInitFailed:Connect(function(player, result, message)
    if result == Enum.TeleportResult.Flooded then
        task.wait(2)
        retryTeleport(player)
    else
        showError(player, message)
    end
end)
```

Retry with backoff on `Flooded`, and surface anything else.

### Reserved servers

```lua
local code, privateServerId = TeleportService:ReserveServerAsync(placeId)   -- YIELDS

local options = Instance.new("TeleportOptions")
options.ReservedServerAccessCode = code
TeleportService:TeleportAsync(placeId, players, options)
```

The access code is a **secret**. Anyone holding it can join that server. Keep it
server-side; never send it to a client. On arrival,
`game.PrivateServerId` and `game.PrivateServerOwnerId` identify the instance.

### `TeleportData` is not trusted input

This is the part that costs games their economy.

```lua
local data = player:GetJoinData().TeleportData
```

`TeleportData` is carried with the player and is **not signed**. Treat it exactly
like a `RemoteEvent` argument: a hint about intent, never an authority about
value.

```lua
-- WRONG - a duplication bug with extra steps
local data = player:GetJoinData().TeleportData
grantItems(player, data.inventory)

-- RIGHT - carry an identifier, load the truth
local data = player:GetJoinData().TeleportData
if type(data) == "table" and type(data.matchId) == "string" then
    local match = MatchStore:load(data.matchId)   -- server-side truth
    if match then joinMatch(player, match) end
end
```

Carry ids, flags and preferences. Never carry currency, inventory, stats or
permissions. `roblox-data-persistence` names teleport-carried inventory as a top
duplication cause, and this is the mechanism.

Validate the shape too — `GetJoinData()` can return an empty table, and
`TeleportData` can be `nil` or any type.

### Saving before you teleport

A teleport takes the player out of this server. If their data has not been saved
and the session lock released, the destination server will either read stale
data or block on the lock.

Save, release, **then** teleport. With ProfileStore or Lyra that is the session
end; with a raw DataStore it is an explicit save whose result you check. Never
teleport optimistically after firing a save you did not wait for.

---

## `MemoryStoreService`

Fast, shared, **temporary**. The right place for state several servers coordinate
on and nobody needs after the event ends.

```lua
local MemoryStoreService = game:GetService("MemoryStoreService")

local map = MemoryStoreService:GetHashMap("ActiveRaids")
local queue = MemoryStoreService:GetQueue("Matchmaking", 30)      -- invisibility timeout
local sorted = MemoryStoreService:GetSortedMap("WeeklyLeaders")
local counter = MemoryStoreService:GetDistributedCounter("PlayersOnline")
```

| Structure | Use |
|---|---|
| `GetHashMap` | Keyed shared state. The general-purpose default |
| `GetQueue` | Work handed between servers — matchmaking, jobs |
| `GetSortedMap` | Ranked or ordered shared state |
| `GetDistributedCounter` | A number several servers increment |

`GetHashMap` is the one most guides omit and most problems want.

**Everything expires.** Items carry a TTL and MemoryStore is not durable
storage. Anything that must survive belongs in a DataStore.

**Queue invisibility timeout.** `GetQueue(name, invisibilityTimeout)` — when a
server reads an item, it becomes invisible to others for that many seconds. If
the reader finishes, it removes the item; if the reader dies, the item reappears
and someone else takes it. Set it longer than the work takes, or two servers
will process the same match.

**Quotas are per-universe and scale with player count.** The request budget is
roughly `1000 + 100 * players` per minute, items are capped at 32 KB, and the
partition has a size limit. A per-frame counter increment will exhaust it.

---

## Choosing, in one table

| Question | Answer |
|---|---|
| Must it survive a server restart? | DataStore |
| Do other servers need to know *now*? | `MessagingService`, plus durable storage |
| Do other servers need to *read* it? | `MemoryStoreService` |
| Is it about moving a player? | `TeleportService` |
| Is it money, items or permissions crossing a boundary? | Server-side storage, keyed by an id the player carries |

---

## Checklist

- [ ] `MessagingService` used for hints, never as the only path for a mutation.
- [ ] Subscribers re-read durable state rather than trusting the payload.
- [ ] Own-`JobId` messages filtered where double-handling matters.
- [ ] `TeleportInitFailed` handled, with backoff on `Flooded`.
- [ ] `TeleportAsync` / `ReserveServerAsync`, not the `[Deprecated]` forms.
- [ ] Reserved-server access codes never leave the server.
- [ ] `TeleportData` carries ids only, and its shape is validated.
- [ ] Data saved and the session released before teleporting.
- [ ] MemoryStore used only for state that may expire.
- [ ] Queue invisibility timeout exceeds the work duration.
- [ ] Cross-server calls are inside `pcall` with the result checked.
