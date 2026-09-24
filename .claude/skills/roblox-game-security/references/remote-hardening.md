# Remote hardening

The main skill states the four checks every remote handler owes: type, range and
sanity, ownership and existence, rate. This file is the implementation of the
one that gets skipped — **rate** — plus the patterns around it.

There is no engine-level rate limit on remotes. `FireServer` in a `while true`
loop is entirely legal and the server will process every call.

---

## What unbounded remotes actually cost

Three separate failures, in increasing order of how much they hurt:

1. **The handler's work, multiplied.** A remote that does a raycast now does ten
   thousand.
2. **DataStore budget.** A remote that saves burns your request budget for every
   player, so *other* players' saves start failing.
3. **The server.** Enough calls with large enough arguments and it drops.

A rate limiter is not about stopping a clever exploit. It is about the floor
under how bad a single client can make things.

---

## A token bucket

A per-call cooldown — "at most one every 0.5s" — is easy and wrong for anything
a player legitimately does in bursts. A token bucket allows the burst and still
bounds the sustained rate.

```lua
--!strict
local Players = game:GetService("Players")

export type Bucket = {
    tokens: number,
    lastRefill: number,
    capacity: number,
    refillPerSecond: number,
}

local RateLimit = {}

local buckets: { [Player]: { [string]: Bucket } } = {}

-- capacity is the burst allowance; refillPerSecond is the sustained rate.
function RateLimit.check(player: Player, name: string, capacity: number, refillPerSecond: number): boolean
    local forPlayer = buckets[player]
    if not forPlayer then
        forPlayer = {}
        buckets[player] = forPlayer
    end

    local bucket = forPlayer[name]
    local now = os.clock()

    if not bucket then
        bucket = { tokens = capacity, lastRefill = now, capacity = capacity, refillPerSecond = refillPerSecond }
        forPlayer[name] = bucket
    end

    -- Refill lazily rather than on a timer: no thread, no work when idle.
    local elapsed = now - bucket.lastRefill
    bucket.tokens = math.min(bucket.capacity, bucket.tokens + elapsed * bucket.refillPerSecond)
    bucket.lastRefill = now

    if bucket.tokens < 1 then
        return false
    end

    bucket.tokens -= 1
    return true
end

-- Player objects are not collected on leave, so this table would grow forever.
Players.PlayerRemoving:Connect(function(player)
    buckets[player] = nil
end)

return RateLimit
```

Lazy refill is the part worth copying: no `Heartbeat` loop, no per-player timer,
and a player who is idle costs nothing at all.

```lua
UseAbility.OnServerEvent:Connect(function(player, abilityId)
    if not RateLimit.check(player, "UseAbility", 3, 1) then
        return                      -- burst of 3, then 1 per second
    end
    ...
end)
```

**Also limit globally.** Per-player limits still allow forty players to combine
into forty times the load on a shared resource. For anything that touches a
DataStore or a cross-server service, add a server-wide bucket alongside the
per-player one.

---

## What to do on a violation

| Response | When |
|---|---|
| **Ignore silently** | The default. Cheap, gives away nothing |
| **Ignore and count** | Better. Feeds detection without acting on one sample |
| **Kick** | Only for something that cannot happen legitimately |
| **Ban** | Only from an accumulated pattern, never one event |

**Silence is the right default.** Sending an error back tells the exploiter
exactly where the boundary is, which is free information for tuning an attack.
A legitimate client that hits the limit has a bug you want to fix anyway, and
you will find it in the logs rather than from the error.

Never ban on a single sample. Latency, lag spikes and legitimate burst input all
produce readings that look like cheating for one frame. See the detection notes
in the main skill: accumulate, threshold, then act.

---

## Payload size

Type-checking an argument does not bound it. `string` includes a ten-megabyte
string; `table` includes one nested a thousand deep.

```lua
local MAX_MESSAGE = 200

local function validMessage(value: unknown): string?
    if type(value) ~= "string" then return nil end
    if #value > MAX_MESSAGE then return nil end
    if utf8.len(value) == nil then return nil end   -- invalid UTF-8
    return value
end
```

For tables, bound both **width and depth** before you walk them:

```lua
local function shallowCount(t: { [any]: any }, limit: number): boolean
    local n = 0
    for _ in t do
        n += 1
        if n > limit then return false end
    end
    return true
end
```

Counting with `#` does not work on a dictionary and lies about arrays with
holes. Iterate with a bound, and bail early rather than after.

A recursive validator with no depth cap is itself the vulnerability: a
deliberately deep table turns your validation into the stack overflow.

`UnreliableRemoteEvent` has a hard payload limit — exceeding it fails silently
rather than erroring, which is its own trap. Keep those payloads small by design.

---

## Honeypot remotes

A remote nothing legitimate ever fires is a high-signal detector: the only way
it gets called is by something enumerating `ReplicatedStorage`.

```lua
local honeypot = Instance.new("RemoteEvent")
honeypot.Name = "AdminGrantItem"        -- plausible enough to be tempting
honeypot.Parent = ReplicatedStorage.Remotes

honeypot.OnServerEvent:Connect(function(player, ...)
    Telemetry.record(player, "honeypot", { name = honeypot.Name })
end)
```

Two rules:

- **It must do nothing.** A honeypot that grants anything is a vulnerability.
- **It is a signal, not a verdict.** Some players run tools that enumerate
  remotes out of curiosity. Weight it, do not act on it alone.

Do not overdo it. A dozen fake remotes is clutter your own team has to reason
about, and an exploiter who notices the pattern learns more than you do.

---

## Replay and ordering

A remote call can be captured and re-sent. If the same call twice is harmful —
claiming a reward, applying a one-shot effect — the server must recognise the
repeat.

The cheapest correct approach is the one the receipt handler uses: **make the
operation idempotent on a server-known identifier**, rather than trying to
detect the replay.

```lua
-- The server knows which quests are unclaimed. A replayed claim finds the
-- quest already claimed and does nothing. No nonce needed.
local function claim(player: Player, questId: string)
    local profile = profiles[player]
    if not profile or not profile:IsActive() then return end

    local quest = profile.Data.quests[questId]
    if not quest or quest.claimed or not quest.complete then
        return
    end

    quest.claimed = true
    grantReward(profile.Data, quest.reward)
end
```

Reach for a nonce only when the operation genuinely has no server-side state to
key on — which is rarer than it first appears, and usually a sign the design put
authority in the wrong place.

---

## Server-authoritative movement

The offensive side of this stack spends a long section on why server-authoritative
physics defeats speed and teleport cheats outright, and the defensive advice has
historically been "sanity-check positions", which is a much weaker tool.

`RunService:BindToSimulation` and the prediction surface
(`SetPredictionMode`, `GetPredictionStatus`, `IsResimulating`, `Rollback`,
`Misprediction`) exist for this. Adopting them means the server simulates and
the client predicts, so a client that claims an impossible position is simply
corrected rather than detected.

That is a large architectural commitment and it is not free. The honest position:

- **If you are building a competitive game where movement decides outcomes**,
  this is the answer and sanity checks are a stopgap.
- **If movement is not the thing being cheated**, position sanity checks with an
  accumulator are proportionate and much cheaper.

Verify each member of that surface before use — it is newer than most
documentation, and `roblox-executor/references/technique/replication-exploitation.md`
describes precisely what it changes from the attacker's side.

---

## Checklist

- [ ] Every remote handler has a rate limit, not just the obvious ones.
- [ ] Limits allow legitimate bursts (token bucket, not a flat cooldown).
- [ ] Shared resources have a server-wide limit as well as per-player.
- [ ] Rate-limit state is cleared on `PlayerRemoving`.
- [ ] Violations are silent by default and counted, not answered.
- [ ] String length and UTF-8 validity bounded; table width and depth bounded.
- [ ] Validators cannot be made to recurse without limit.
- [ ] Repeatable operations are idempotent on server-known state.
- [ ] Honeypots do nothing and only contribute signal.
- [ ] Movement authority chosen deliberately, not defaulted to.
