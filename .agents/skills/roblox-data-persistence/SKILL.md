---
name: roblox-data-persistence
description: Saving player data safely - DataStore budgets, UpdateAsync, session locking, ProfileStore and Lyra, migrations, BindToClose. Use for saves, leaderboards, lost or duplicated items.
---

# Data persistence

Data loss and duplication are the two failures players never forgive. Both come
from the same root cause: treating a DataStore like a variable rather than a
distributed, rate-limited, eventually-consistent key-value store shared across
every server running your game.

## Load a reference when

| Need | File |
|---|---|
| ProfileStore or Lyra with working code, sessions, migration | `references/profilestore-and-lyra.md` |

---

## Use a library

For player data, write the integration, not the storage layer.

| Library | ★ | License | Status |
|---|---|---|---|
| **ProfileStore** | 333 | Apache-2.0 | current; successor to ProfileService, same author |
| **ProfileService** | 326 | Apache-2.0 | mature, still widely deployed, superseded |
| **Lyra** | 151 | MIT | modern alternative, transactional multi-key updates |

They exist because session locking, retry policy, migration and graceful
shutdown are genuinely hard and identical for every game. Rolling your own means
reimplementing all four and discovering the edge cases in production.

Write raw `DataStoreService` when: the data is not per-player and not
contended (a global config), or you are building tooling, or you are learning
what the library is doing for you.

---

## DataStore semantics

```lua
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("PlayerData", "v3")
```

**The scope argument is a versioning tool.** Bumping `"v3"` gives you a clean
namespace — useful for a breaking schema change where migration is not worth it.

| Call | Semantics |
|---|---|
| `GetAsync(key)` | read; **may return cached data** for ~4 s after a write |
| `SetAsync(key, value)` | blind overwrite — loses concurrent writes |
| `UpdateAsync(key, transform)` | read-modify-write; retries on conflict |
| `RemoveAsync(key)` | delete, returns the old value |
| `IncrementAsync(key, delta)` | atomic integer increment |
| `ListKeysAsync` / `ListVersionsAsync` | enumeration |

### Bypassing the read cache

The ~4 s cache on `GetAsync` is the right default and occasionally exactly
wrong — a moderation tool reading data another server just wrote, or a test
asserting a save landed. `DataStoreGetOptions` turns it off:

```lua
local options = Instance.new("DataStoreGetOptions")
options.UseCache = false

local fresh = store:GetAsync(key, options)     -- YIELDS, and skips the cache
```

It is a **property**, `UseCache`, not a `SetUseCache` method — older guides show
the method form. Uncached reads cost budget every time, so do not make this the
default for player joins.
| `GetVersionAsync(key, version)` | read a historical version |

**`UpdateAsync` is the default choice.** Its transform runs against the current
value and re-runs if another server wrote in between. `SetAsync` has no such
protection — two servers saving the same profile means one of them silently
loses.

Returning `nil` from an `UpdateAsync` transform **cancels the write**. That is
the correct way to abandon a save that has become invalid:

```lua
local ok, err = pcall(function()
    store:UpdateAsync(key, function(old)
        if old and old.version > incoming.version then
            return nil          -- newer data exists; do not clobber it
        end
        return incoming
    end)
end)
if not ok then
    warn(("[data] save failed for %s: %s"):format(key, tostring(err)))
end
```

**The transform must be pure and fast.** It may run several times. Do not yield
inside it, do not fire remotes from it, do not mutate outside state in it.

### The full transform signature

The one-argument form above still works and is what most code uses. The current
signature carries more:

```lua
store:UpdateAsync(key, function(oldValue, keyInfo: DataStoreKeyInfo)
    -- keyInfo.Version, .CreatedTime, .UpdatedTime
    -- keyInfo:GetUserIds(), keyInfo:GetMetadata()
    local newValue = mutate(oldValue)
    local userIds = keyInfo and keyInfo:GetUserIds() or { player.UserId }
    return newValue, userIds, { schema = CURRENT_SCHEMA }
end)
```

`userIds` is not decoration. Tagging a key with the `UserId` it belongs to is
what lets Roblox answer a right-to-erasure request against your data, and it is
what the moderation tooling reads. Set it on every write of player data.

The third return is arbitrary metadata, capped separately from the value. A
schema version there means a migration can be decided without deserialising the
whole payload.

### Limits that bite

- **4 MB per key.** Serialized, including keys. Inventories grow silently until
  one day a save fails.
- **Keys are 50 characters max.** `tostring(player.UserId)` is the convention.
- **Values must be JSON-safe.** No `Instance`, no `Vector3`, no `CFrame`, no
  function, no metatable, no mixed array/dictionary table, no `NaN`/`inf`, no
  cyclic reference. Serialize datatypes to plain tables yourself.
- **Table keys become strings.** `{[1] = "a"}` returns as `{["1"] = "a"}` if the
  table is not a pure array. This silently breaks numeric-keyed lookups after a
  round trip.

### Request budgets

`DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)`
tells you how many calls remain. Exceeding it queues, then throttles, then
errors. Budgets scale with player count.

Check the budget before a bulk operation, and back off:

```lua
local function waitForBudget(requestType: Enum.DataStoreRequestType)
    while DataStoreService:GetRequestBudgetForRequestType(requestType) < 1 do
        task.wait(1)
    end
end
```

Retry with **exponential backoff**, not a tight loop — a tight retry loop
exhausts the budget it is waiting for.

```lua
local function retry<T>(attempts: number, fn: () -> T): (boolean, T | string)
    local delay = 1
    for attempt = 1, attempts do
        local ok, result = pcall(fn)
        if ok then return true, result end
        if attempt == attempts then return false, tostring(result) end
        task.wait(delay)
        delay = math.min(delay * 2, 30)
    end
    return false, "unreachable"
end
```

---

## Session locking — the anti-duplication mechanism

Two servers holding the same profile is how items get duplicated: server A
loads, server B loads, A saves 10 coins, B saves the pre-A state plus its own
changes.

A session lock stores "server X owns this profile as of timestamp T" inside the
data itself. Another server that sees a live lock waits or refuses. A stale lock
(the owner crashed) is stolen after a timeout.

This is the main reason to use ProfileStore or Lyra rather than hand-rolling.
If you must implement it, the pieces are: a `jobId` + timestamp in the payload,
`UpdateAsync` for every acquire and release, a steal threshold longer than your
autosave interval, and a release on `PlayerRemoving` **and** `BindToClose`.

---

## Shutdown

```lua
game:BindToClose(function()
    if RunService:IsStudio() then return end     -- Studio gives ~1s; do not fight it

    local saving = {}
    for _, player in Players:GetPlayers() do
        table.insert(saving, task.spawn(savePlayer, player))
    end

    -- Live servers allow ~30s. Wait for the saves, with a ceiling.
    local deadline = os.clock() + 25
    while os.clock() < deadline and anyStillSaving(saving) do
        task.wait(0.1)
    end
end)
```

Without `BindToClose`, every shutdown — including routine server migrations and
your own version updates — drops the last unsaved changes for everyone online.

Also save on `PlayerRemoving`, and autosave on a timer (60–180 s is typical) so
a crash costs one interval rather than a session.

---

## Schema migration

Store a version number in every payload from day one. Retrofitting one is
painful.

```lua
local CURRENT_VERSION = 4

local MIGRATIONS: { (data: any) -> any } = {
    [1] = function(d) d.inventory = d.items; d.items = nil; return d end,
    [2] = function(d) d.settings = d.settings or DEFAULT_SETTINGS; return d end,
    [3] = function(d) d.coins = math.floor(d.coins or 0); return d end,
}

local function migrate(data: any): any
    local version = data.version or 1
    while version < CURRENT_VERSION do
        local step = MIGRATIONS[version]
        if not step then
            error(("no migration from v%d"):format(version))
        end
        data = step(data)
        version += 1
    end
    data.version = CURRENT_VERSION
    return data
end
```

Migrations run forward only, one step at a time, and must be idempotent enough
to survive a retry. Never delete an old migration — a player who has not logged
in for two years still arrives on v1.

---

## MemoryStoreService

Fast, cross-server, **temporary** storage. Not a DataStore replacement — data
expires and is not durable.

```lua
local MemoryStoreService = game:GetService("MemoryStoreService")

local queue = MemoryStoreService:GetQueue("Matchmaking", 30)   -- invisibility timeout
queue:AddAsync(playerId, 300)                                   -- expiry seconds
local items, id = queue:ReadAsync(4, false, 30)
queue:RemoveAsync(id)

local map = MemoryStoreService:GetSortedMap("Leaderboard")
map:SetAsync(userId, score, 3600)

-- MemoryStoreHashMap is the general-purpose one, and the one most guides omit.
local hash = MemoryStoreService:GetHashMap("ActiveRaids")
hash:SetAsync(raidId, state, 600)              -- value, expiry seconds
local current = hash:GetAsync(raidId)
hash:UpdateAsync(raidId, function(old) return mutate(old) end, 600)
hash:RemoveAsync(raidId)
```

Four structures: `GetHashMap` (keyed state — the default), `GetQueue` (work handed
between servers), `GetSortedMap` (ranked state), `GetDistributedCounter` (a
number several servers increment). `MemoryStoreHashMap:UpdateAsync` takes an
expiry alongside the transform, and like every `UpdateAsync` its transform may
run more than once — keep it pure.

**Quotas are per-universe and scale with player count**: roughly
`1000 + 100 x players` requests per minute, 32 KB per item. A per-frame counter
increment exhausts that.

The right tool for matchmaking queues, cross-server counters, live event state,
and rate limits shared across servers. The wrong tool for anything the player
would be upset to lose.

---

## Leaderboards

`OrderedDataStore` supports sorted range queries, which regular DataStores do
not. It only stores **integers**.

```lua
local board = DataStoreService:GetOrderedDataStore("Wins", "v1")
board:SetAsync(tostring(userId), wins)

local page = board:GetSortedAsync(false, 100)   -- descending, top 100
for rank, entry in page:GetCurrentPage() do
    print(rank, entry.key, entry.value)
end
```

Keep the leaderboard store separate from the profile store. Writing both on
every change doubles your request usage; update the board on a slower cadence.

---

## Diagnosing the two classic failures

**"Players lost progress."** In order of likelihood: no `BindToClose`; saves
happening only on `PlayerRemoving` and the server crashed; a `pcall` swallowing
the error and the code carrying on as though the save succeeded; budget
exhaustion from saving on every change; a migration that threw and was caught
silently.

**"Players duplicated items."** In order of likelihood: no session locking; a
`SetAsync` overwriting a concurrent write; a trade or transfer that granted
before it removed; a client-authoritative path that never touched the DataStore
at all. The last one is a `roblox-game-security` problem, not a data one.

**Never `pcall` a save and ignore the result.** A failed save that reports
success is how "we have backups" turns into "we have backups of the wrong data".
Log every failure with the key and the error, and count them — a rising failure
rate is the earliest signal you will get.

## Works with

- `roblox-monetization`: purchase receipts recorded in the same profile update.
- `roblox-game-design`: which balances, streaks and unlocks are saved.
- `roblox-game-security`: the server alone writes saved values.
- `roblox-studio-mcp`: save and load tested in Studio against a test store.
- `roblox-chat`: player-typed names saved raw and filtered again on load.
