---
name: roblox-combat
description: Fair Roblox combat that feels good - server-validated hits, shapecast hitboxes, cooldowns, damage, projectiles, lag tolerance, hit feedback. Use for weapons, abilities and PvP.
---

# Combat

Combat has two customers who want opposite things. The player wants every
hit to land the instant they swing. The server has to refuse hits that did
not happen, because the client is the exploiter's. The pattern that serves
both:

1. **The client acts at once**: animation, sound, a hit spark where it
   thinks it hit. Nothing that matters.
2. **The client sends intent**: "I swung", "I fired from here in this
   direction", with the time. Never "I did 40 damage to Bob".
3. **The server decides**: cooldown, state, range, line of sight, then the
   hit test, then damage from server-side stats.
4. **The server tells everyone** the result, and the other clients draw it.

## Hit detection

| Weapon | Server test | Notes |
|---|---|---|
| Hitscan gun | `Workspace:Raycast` from a validated origin | One ray per shot |
| Sword, fist | `Workspace:Blockcast` or `Workspace:Spherecast` along the swing | A swept shape catches what a single box between frames misses |
| Area attack | `Workspace:GetPartBoundsInBox` or `GetPartBoundsInRadius` | With `OverlapParams` so only characters count |
| Slow projectile | Server steps it with raycasts each frame | Clients draw their own copy |
| `Touched` | Avoid for damage | Fires late, misses fast parts, fires many times per contact |

[hit-detection.md](references/hit-detection.md) has a validated melee hit
and a hitscan shot.

## What the server checks, cheapest first

1. Argument types and shapes (`roblox-game-security`).
2. Rate: the weapon's cooldown on the server clock (`os.clock()`), per
   player and per weapon.
3. State: alive, not stunned, holding the weapon it claims.
4. Origin: the claimed muzzle or hand is near where the server has the
   character, within a named tolerance.
5. Range and line of sight from that origin.
6. The hit test itself.

A check the server skips is a check the exploiter does not have to pass.

## Latency

At 150 ms of ping, the target the attacker saw is where it was 150 ms ago.
An exact server check refuses honest hits; no check accepts impossible ones.
Pick one, name the number, and keep it bounded:

- **Tolerance**: widen range and hitbox by a fixed allowance (a few studs).
  Simple, and enough for most melee.
- **Rewind**: keep each character's recent positions (a quarter to half a
  second) and test against where the target was at the attacker's time.
  Cap how far back, or a lag switch buys unlimited reach.

`Player:GetNetworkPing()` and `Workspace:GetServerTimeNow()` give the
numbers to work with.

## Damage

One server function applies damage, so armour, team checks, kill credit and
logging live in one place. `Humanoid:TakeDamage(amount)` respects a
`ForceField` (spawn protection); setting `Humanoid.Health` directly does
not. Credit the kill once, on the server, when health reaches zero.

## Projectiles

Pool projectile parts, move all live projectiles from one loop, and replicate
a small spawn message (origin, direction, speed, id) so clients simulate the
visuals themselves. Cosmetic tracers and impacts go over an
`UnreliableRemoteEvent`; damage never does.
[weapons-and-projectiles.md](references/weapons-and-projectiles.md) has
the loop.

## Feel

A hit that is correct but silent feels like a miss. Layer small responses
scaled to how big the moment is: a sound and a spark for a light hit; a
flash, a short camera nudge and a damage number for a heavy one; a brief
pause of the attacker's animation for a finishing blow. All of it on the
client, none of it in the simulation.
[game-feel.md](references/game-feel.md) has the tiers and the camera shake.

## Works with

- `roblox-game-security`: remote validation and rate limits behind every hit.
- `roblox-networking`: replication, ownership and unreliable remotes for effects.
- `roblox-engine-api`: raycasts, shapecasts, spatial queries and Humanoid health.
- `roblox-vfx-animation`: attack animations, markers and hit effects.
- `roblox-npc-ai`: enemies that attack and take damage through the same pipeline.
- `roblox-audio`: layered hit sounds.
- `roblox-performance`: pooling and one loop for many projectiles.
