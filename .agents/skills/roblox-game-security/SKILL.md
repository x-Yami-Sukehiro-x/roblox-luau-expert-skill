---
name: roblox-game-security
description: Defending a Roblox game - remote validation, rate limits, server authority, Toolbox backdoor audits, bans. Use for exploiters are doing X.
---

# Defending your game

The mirror of `roblox-executor`. Everything here is written from what a client
can actually do, not from what feels risky.

## Load a reference when

| Need | File |
|---|---|
| rate limiting, payload bounds, honeypots, replay, movement authority | `references/remote-hardening.md` |
| Toolbox or Creator Store models, backdoors, sandboxing an asset | `references/audit-imported-assets.md` |
| admin commands, kicks and bans that last, without a backdoor | `references/admin-commands.md` |

---

## The threat model, stated accurately

An exploiter running an executor on their client can:

- **Read every instance, property and script** the client has, including
  everything in `ReplicatedStorage`, and decompile your `LocalScript`s.
- **Call any RemoteEvent or RemoteFunction** with any arguments, at any rate,
  in any order, at any time — including remotes your UI would never fire.
- **Read and modify any client-side Luau value**: upvalues, constants, module
  tables, your "private" state.
- **Hook any client function**, including the ones your own anti-cheat uses.
- **Move their own character freely**, because the client genuinely owns its
  character's physics.
- **Delete or disable any LocalScript**, including your anti-cheat.
- **Fake anything the client reports**, including anti-cheat "all clear"
  heartbeats.

They cannot:

- Change anything on the server directly.
- Make the server accept a value it did not compute or validate.
- Read `ServerStorage` or `ServerScriptService`.
- Affect other clients except through the server.

**Everything defensive follows from that split.** Security lives on the server.
Client-side checks are telemetry, not enforcement.

---

## The authority rule

The client sends **intent**. The server computes **outcome**. Always.

| Client may say | Server must decide |
|---|---|
| "I clicked attack" | whether a hit landed, and for how much |
| "I want to buy item X" | whether they can afford it, and grant it |
| "I'm aiming here" | whether that shot is plausible |
| "I finished the obby" | never — the server tracks checkpoints |
| "My score is 5000" | never — the server owns the score |

If you can phrase a remote's payload as an outcome ("I dealt 40 damage",
"give me 100 coins", "I collected the coin"), it is exploitable as written.

---

## Remote hardening

Every handler validates four things before doing work. Full worked example in
`roblox-networking`.

1. **Type** — `typeof(x) ~= "number"` and out. Annotations are erased at
   runtime and validate nothing.
2. **Range and sanity** — including `x ~= x` for NaN and `math.huge` for
   infinity. **Every comparison involving NaN is false.** A guard written as
   `if not (amount > 0 and amount < 100) then return end` therefore *rejects*
   NaN, which is correct — but the equally common
   `if amount > 100 then return end` *accepts* it, because `NaN > 100` is
   false. Test for NaN explicitly rather than hoping the range check catches
   it.
3. **Ownership and existence** — is this instance real, alive, in the workspace,
   and actually theirs? An `Instance` argument may be anything the client can
   reference, including something it created locally.
4. **Rate** — there is no engine rate limit. `FireServer` in a `while true` loop
   is a valid client program.

Additional traps:

- **`nil` arguments collapse the argument list.** `FireServer(nil, 5)` arrives as
  `(5)`. Validate by position and type, or accept a single table.
- **Unbounded strings and tables are a memory attack.** Cap length and depth.
- **A remote in `ReplicatedStorage` is callable by anyone.** There is no such
  thing as a private remote. Naming it `_internalAdminRemote` protects nothing.
- **Deeply nested tables** cost CPU to traverse. Cap the depth you will inspect.

```lua
local function isSaneNumber(v: unknown, min: number, max: number): boolean
    return typeof(v) == "number"
        and v == v                       -- not NaN
        and v ~= math.huge and v ~= -math.huge
        and v >= min and v <= max
end
```

---

## Client-side anti-cheat: what it is actually for

A `LocalScript` anti-cheat can be read, hooked, disabled or deleted by the
person it is watching. It cannot be made secure. Anyone selling you otherwise is
selling obfuscation.

What it is genuinely good for:

- **Raising cost.** Most exploiters run scripts they did not write. A check that
  breaks a popular public script removes a large fraction of your problem for
  very little work.
- **Signal generation.** A client that stops reporting, reports impossible
  values, or whose checks vanish is *itself* a signal — evaluated **server-side**.
- **Catching accidents.** Not everything anomalous is malicious.

What it is not:

- Enforcement. Never let a client-side check decide a ban or a grant.
- A place for secrets. It is fully readable.

**Never trust a client heartbeat as proof of innocence.** Treat its absence as a
weak signal and its presence as no signal at all — forging one is trivial.

---

## Server-side sanity checks

These work because the server owns the data.

**Movement.** The server sees replicated character positions. Compare distance
travelled against elapsed time, with generous headroom for lag, teleporters,
vehicles and knockback:

```lua
local MAX_SPEED_STUDS = 32          -- above your fastest legitimate speed
local GRACE = 1.6                   -- lag, launchpads, knockback

local lastPosition: { [Player]: Vector3 } = {}
local lastCheck: { [Player]: number } = {}

local function checkMovement(player: Player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end

    local now = os.clock()
    local previous, previousAt = lastPosition[player], lastCheck[player]
    lastPosition[player], lastCheck[player] = root.Position, now
    if not previous or not previousAt then return end

    local elapsed = now - previousAt
    if elapsed <= 0 then return end

    local speed = (root.Position - previous).Magnitude / elapsed
    if speed > MAX_SPEED_STUDS * GRACE then
        flag(player, "speed", speed)     -- accumulate; do not ban on one sample
    end
end
```

**Accumulate, never act on a single sample.** One bad reading is lag. Twenty in
thirty seconds is a player. This one discipline is the difference between an
anti-cheat and a random ban generator.

**Combat.** Validate on the server: is the target alive, in range, in line of
sight (a raycast from attacker to target), and within the weapon's rate of fire?
Accept or reject the *shot*; never accept a client-reported *result*.

**Economy.** Every currency change goes through one server function that checks
the balance first. If two code paths can grant coins, one of them is
under-validated.

**Teleports and position resets.** Whitelist the legitimate ones, so a
teleporter does not read as a speed violation and a speed violation does not
hide behind "it might be a teleporter".

---

## Detection versus enforcement

Two separate systems, and conflating them is how false-positive bans happen.

**Detection** gathers evidence: flags, counters, telemetry, anomaly rates.
**Enforcement** acts: rejecting an action, kicking, banning.

Between them sits a threshold you can tune, and a log you can review. Log the
evidence for every enforcement action in enough detail to answer "why was I
banned" six weeks later.

```lua
Players:BanAsync({
    UserIds = { userId },
    Duration = 7 * 86400,
    DisplayReason = "Exploiting",
    PrivateReason = "speed>60 for 34 consecutive samples over 41s; session a7f2",
    ExcludeAltAccounts = false,
    ApplyToUniverse = true,
})
```

> The API dump types `Players:BanAsync(config: { [string]: any })` and stops
> there — it does not enumerate the config keys, so the field names above are
> **recalled, not dump-verified**. Check them against the Creator Hub before
> shipping an enforcement path. `node tools/bin/verify-api.mjs Players.BanAsync`
> confirms the function and its shape, and that is all it can confirm.

`BanAsync` persists and covers alt accounts. `Player:Kick` does not persist and
is a speed bump for enforcement — the exploiter rejoins in eight seconds. That
does not make `Kick` wrong: it is still the right call for a non-punitive
disconnect, such as ejecting a player from a broken session.

**Silent rejection beats loud banning** for most violations. Simply not applying
the invalid action, with no feedback, gives an exploiter nothing to iterate
against. A kick tells them exactly which check they tripped.

**A false positive is worse than a miss.** A banned legitimate player leaves a
review and never comes back; a missed exploiter costs you one session.

---

## Obfuscation

Client-side obfuscation raises the time cost of understanding your code. That is
its entire value, and it is real but bounded — a determined person with a
decompiler gets there.

It is worth considering for a genuinely novel client-side mechanic you want to
keep for a few weeks. It is not worth it as a substitute for server validation,
and it costs you debuggability and often performance permanently.

**Never obfuscate instead of validating.** Obfuscated code that trusts the
client is exploitable code that is also hard to fix.

---

## Things that must not be on the client

Everything in `ReplicatedStorage` is readable by every client. Move these to
`ServerStorage` or `ServerScriptService`:

- Item catalogs with drop rates or unearned items
- Admin user-id lists
- Anti-cheat thresholds
- API keys, webhook URLs, external endpoints
- Shop prices used for validation (the client may *display* a price; the server
  must own the one it charges)
- Any table the client only needs a subset of

A useful test: for each module in `ReplicatedStorage`, ask what an exploiter
gains from reading it. If the answer is anything, it is in the wrong place.

---

## Audit checklist

Run this against an existing codebase. It is ordered by how much damage each
finding does.

1. **Every `OnServerEvent` / `OnServerInvoke`** — type, range, ownership, rate.
   List them all; there are usually more than the team remembers.
2. **Every remote payload** — is any of it an outcome rather than an intent?
3. **Currency and inventory** — is there exactly one server function that grants?
4. **`ReplicatedStorage` contents** — what does reading all of it give an
   attacker?
5. **Client-side decisions** — grep the client for anything that decides rather
   than displays.
6. **`RemoteFunction:InvokeClient`** — should be zero occurrences on the server.
7. **DataStore writes** — session-locked? Otherwise duplication is available
   without any client exploit at all.
8. **Rate limits** — every handler that touches a DataStore, spawns an instance,
   or loops.
9. **Ban logic** — does any path ban on a single sample or a client-supplied
   value?
10. **Admin commands** — is the user-id check server-side, and is the list
    server-only?

For the offensive detail behind any of these — how a value is actually located
and changed on the client, what anti-cheat reconnaissance looks like, what
detection surface a hook leaves — see `roblox-executor`. Knowing the technique
is what makes the defence proportionate instead of superstitious.

## Works with

- `roblox-networking`: remote design that the validation protects.
- `roblox-monetization`: purchases granted once, on the server.
- `roblox-executor`: what a client can actually do, the threat model's source.
- `roblox-studio-mcp`: grepping imported assets for backdoors.
- `roblox-combat`: validating every hit, cooldown and projectile on the server.
- `roblox-chat`: command permissions and filtering player text.
