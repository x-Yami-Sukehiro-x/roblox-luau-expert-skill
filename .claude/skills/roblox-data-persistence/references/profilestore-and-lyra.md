# ProfileStore and Lyra

The main skill says to use a library rather than hand-rolling session locking,
and then shows no code. This file shows the code.

> **Provenance.** These are third-party libraries. They are not in the API dump
> and `node tools/bin/verify-api.mjs` cannot check them — the dump covers Roblox
> classes, enums and datatypes only. Signatures below were taken from each
> project's own documentation; check the version you install, because both have
> changed their API across releases. Status and adoption figures are dated in
> `docs/SOURCES.md`.

---

## Which

| | ProfileStore | Lyra |
|---|---|---|
| Licence | Apache-2.0 | MIT |
| Model | Session-locked profiles | Session-locked stores with transactions |
| Notable | The successor to ProfileService, by the same author | Built-in transactions across multiple players |
| Reach for it when | Standard per-player save data | Trades, gifting, anything that must move items between two players atomically |

**ProfileService is superseded by ProfileStore**, same author. Existing
ProfileService code is not broken, but new work should start on ProfileStore.

Either is better than a hand-rolled `UpdateAsync` wrapper, and the reason is one
feature: **session locking**. Without it, two servers can hold the same player's
data at once and the second to save wins — which is the mechanism behind most
"my items disappeared" and a good share of duplication reports.

---

## ProfileStore, end to end

```lua
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)

local TEMPLATE = {
    coins = 0,
    inventory = {},
    purchases = {},         -- the receipt ledger; see roblox-monetization
    schema = 1,
}

local store = ProfileStore.New("PlayerData", TEMPLATE)

local profiles: { [Player]: any } = {}

local function onPlayerAdded(player: Player)
    local profile = store:StartSessionAsync(`{player.UserId}`, {
        Cancel = function()
            return player.Parent ~= Players     -- they left while we waited
        end,
    })

    if not profile then
        -- Another server holds the lock and would not release it.
        player:Kick("Could not load your data. Please rejoin.")
        return
    end

    profile:AddUserId(player.UserId)       -- GDPR / right-to-erasure tagging
    profile:Reconcile()                    -- fill in keys the template gained

    profile.OnSessionEnd:Connect(function()
        profiles[player] = nil
        player:Kick("Your data was loaded on another server. Please rejoin.")
    end)

    if player.Parent ~= Players then
        profile:EndSession()               -- they left during the load
        return
    end

    profiles[player] = profile
    migrate(profile.Data)                  -- see the migration section
    replicateToClient(player, profile.Data)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)      -- players who joined before this ran
end

Players.PlayerRemoving:Connect(function(player)
    local profile = profiles[player]
    if profile then
        profile:EndSession()
        profiles[player] = nil
    end
end)
```

### The parts people leave out

**`Cancel`.** `StartSessionAsync` waits for another server to release the lock,
which can take a while. Without a cancel predicate it keeps waiting for a player
who left thirty seconds ago, holding a thread and eventually taking the lock for
nobody.

**The `player.Parent ~= Players` check after the call.** `StartSessionAsync`
yields. Everything you knew before it may be stale — this is the same
re-validate-after-yield rule as everywhere else in the stack.

**`OnSessionEnd`.** The lock can be taken away — another server steals it, or
the session ends for an internal reason. If you do not handle it, the player
keeps playing against a profile that is no longer saving, and everything they do
from that point is lost. Kick them; it is kinder than silently discarding an
hour.

**The `GetPlayers()` loop.** A script that only connects `PlayerAdded` misses
everyone who joined while it was loading. In Studio that is always you.

**`AddUserId`.** Tags the DataStore key with the owning user, which is what
makes a right-to-erasure request answerable.

**`Reconcile`.** Fills in template keys that did not exist when the profile was
created. It does not transform existing values — that is migration, below.

### Writing

`Profile.Data` is a plain table. Mutate it directly; the library saves
periodically.

```lua
local profile = profiles[player]
if not profile or not profile:IsActive() then
    return                                 -- the lock is gone; the write is lost
end

profile.Data.coins += amount
```

**`IsActive()` before every write that matters.** Writing to an inactive profile
appears to work and is discarded. In a purchase path that means taking Robux and
granting nothing — see `roblox-monetization/references/receipts.md`, which is
why the receipt ledger lives inside `Profile.Data` rather than beside it.

`Profile:Save()` forces a save; you rarely need it, and calling it after every
mutation will burn the request budget. `Profile.LastSavedData` is the last
version that actually reached the DataStore, which is useful when you need to
know whether a change has been persisted yet.

---

## Lyra

Lyra's distinguishing feature is **transactions across players**, which is
exactly the case a trade needs:

```lua
-- Both sides commit, or neither does.
local ok = store:txAsync({ playerA, playerB }, function(dataA, dataB)
    if not removeItem(dataA, itemId) then
        return false                       -- abort; nothing is written
    end
    addItem(dataB, itemId)
    return true
end)
```

Hand-rolling this is where duplication bugs come from: remove from A, then add
to B, with a server crash in between, and the item is gone — or the other order,
and the item exists twice. `roblox-data-persistence` names "a trade that granted
before it removed" as a top duplication cause, and a transaction is the fix.

Check Lyra's own documentation for the current signature; the shape above is
illustrative.

---

## Migration

Neither library migrates data for you. `Reconcile` adds missing keys; changing
the *meaning* of a key is your job.

```lua
local MIGRATIONS = {
    -- Each function moves data from version N to N+1. Never edit one after
    -- release: some player's profile is still at that version.
    [1] = function(data)
        data.inventory = data.inventory or {}
        for _, item in data.inventory do
            item.quantity = item.quantity or 1     -- quantity was added in v2
        end
    end,
    [2] = function(data)
        data.coins = math.floor(data.coins or 0)   -- coins became integral in v3
    end,
}

local function migrate(data)
    local from = data.schema or 1
    for version = from, #MIGRATIONS do
        MIGRATIONS[version](data)
    end
    data.schema = #MIGRATIONS + 1
end
```

**Never delete an old migration.** A player who has not logged in for two years
loads at their old version and walks up the whole ladder. Deleting step 1
because "nobody is on v1 any more" is how that player's save becomes corrupt.

Run the migration **after** `Reconcile`, so new template keys exist before a
migration tries to transform them.

---

## Studio

Both libraries fall back to a mock store when API access is off, which is why
data appears to work in Studio and fails on a live server. Enable
**Game Settings → Security → Enable Studio Access to API Services**, or you are
testing something other than what you ship.

Even with it on, `BindToClose` gets roughly a second in Studio versus roughly
thirty on a live server. A save path that only ever ran in Studio has never been
exercised properly.

---

## Checklist

- [ ] A library, not a hand-rolled `UpdateAsync` wrapper.
- [ ] `Cancel` predicate passed to `StartSessionAsync`.
- [ ] Player still present re-checked after the yield.
- [ ] `OnSessionEnd` handled, and the player told.
- [ ] `GetPlayers()` loop alongside `PlayerAdded`.
- [ ] `AddUserId` called.
- [ ] `Reconcile` then migrate, in that order.
- [ ] `IsActive()` checked before any write that matters.
- [ ] Migrations append-only; none ever deleted or edited after release.
- [ ] Studio API access enabled, and the save path exercised on a real server.
- [ ] Trades and transfers use a transaction, not two writes.
