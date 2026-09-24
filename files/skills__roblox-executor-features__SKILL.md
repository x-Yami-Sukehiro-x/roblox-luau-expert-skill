---
name: roblox-executor-features
description: Tested, ready-to-paste executor feature scripts for the local character and view — fly, noclip, walk speed and jump height, infinite jump, ESP, click teleport, anti-AFK and fullbright — and the quality bar every such script must meet. Modern physics (LinearVelocity and AlignOrientation, never BodyVelocity), camera-relative movement that works on keyboard, gamepad and touch, respawn handling, one getgenv namespace, rerun-safe unload that restores what it changed, keybinds, and a set() API a hub toggle can call. Use when asked for fly, noclip, speed, jump, ESP, teleport, anti-AFK, fullbright or any "universal" script, when combining features into a hub, or when an executor script's quality, mobile support or cleanup is poor.
---

# Executor features

These eight scripts act on things the local client already owns: its own
character's physics, its own camera, its own lighting and its own view of
other players. That is why they can be generic. Anything that touches a
game's own values, remotes or systems is not generic, and follows
`roblox-executor`'s source-first workflow instead.

Scope and risk are stated once in `roblox-executor`: private and educational
use on accounts and servers you control; any executor use can be banned.

| Feature | Asset | Key | What moves |
|---|---|---|---|
| fly | `assets/fly.luau` | F, E/Space up, Q/LeftControl down | `LinearVelocity` + rigid `AlignOrientation` on the root |
| noclip | `assets/noclip.luau` | V | `CanCollide` on the character's parts, every physics step |
| speed | `assets/speed.luau` | G | `WalkSpeed`, `JumpHeight` and matching `JumpPower`, held against resets |
| infinite jump | `assets/infinite-jump.luau` | J | a jump state on each `JumpRequest`, 0.2 s apart |
| ESP | `assets/esp.luau` | H | a `Highlight` and a name and distance tag per player, in `gethui()` |
| click teleport | `assets/click-teleport.luau` | Ctrl+click, tap on a phone | `PivotTo` the clicked ground, facing kept |
| anti-AFK | `assets/anti-afk.luau` | none | a `VirtualUser` click when `Idled` fires |
| fullbright | `assets/fullbright.luau` | B | six `Lighting` properties, held against day and night scripts |

Each asset is behaviour-tested in `library/tests/recipes/` (every one covers
the effect, the toggle key, chat typing, respawn, rerun and a double unload)
and scores full marks on the slop, format, API and register gates.

---

## How to answer a feature request

1. **Paste the asset whole.** Change only the constants at the top (key,
   speed, colours). Do not rewrite the physics, the respawn handling or the
   unload; those are what the tests prove.
2. **Several features: paste each file.** They share one namespace,
   `getgenv().Features`, and each replaces its own previous session on rerun.
   A hub calls `Features.Fly.set(on)`, writes `Features.Fly.speed` or
   `Features.Speed.walk`, and calls every `unload` from its own unload.
3. **Hub UI** is `roblox-ui` with the picked style codes: a T toggle per
   feature, an H3 slider value for speeds, a P18 cooldown on teleports.
4. **Say what the server can see** (below), once, in the reply.
5. **Run the checks** on the final file: `node tools/bin/check-file.mjs <file>`
   (no Node: `python tools/py/check_file.py <file>`).

A request for a feature not in the table still meets the bar in
`references/feature-quality.md`; start from the closest asset's shape.

---

## What the server sees

The client owns its character's physics, so position and velocity from fly,
noclip, speed and teleport **replicate to everyone**. That is also why they
are the features anti-cheats watch. A server that checks distance per second,
raycasts between positions, or runs Server Authority physics corrects or
kicks; nothing in these scripts hides that. ESP, fullbright and anti-AFK are
local-only and change nothing another player sees.
→ `../roblox-executor/references/technique/replication-exploitation.md`

---

## References

| Need | File |
|---|---|
| the quality bar every feature script meets | `references/feature-quality.md` |
| how each feature works, its variants and why these choices | `references/feature-catalog.md` |
| lifetime, unload and rerun rules in full | `../roblox-executor/references/technique/lifecycle.md` |
| game-specific features from a dump | `../roblox-executor/references/technique/feature-search.md` |
