# Feature catalog

How each asset works, the variants people ask for, and why the asset chose
what it did.

## Fly — `../assets/fly.luau`

`PlatformStand` stops the Humanoid fighting the constraints; a
`LinearVelocity` with no force cap sets the velocity in world space and a rigid
`AlignOrientation` keeps the body level, facing the camera's yaw.

| Variant asked for | Change |
|---|---|
| "faster" | `SPEED`, or `Features.Fly.speed` live from a slider |
| "fly where I look, no up key" | already: forward follows the camera's pitch |
| "face where I look, tilted too" | set `align.CFrame` to the camera's rotation instead of the flat heading |
| "CFrame fly" | moves the root's `CFrame` each frame; it fights physics and jitters for others. Prefer the constraint version |

Deprecated shapes to refuse: `BodyVelocity` / `BodyGyro` flight and
`Humanoid.PlatformStand` alone with `Velocity` writes.

## Noclip — `../assets/noclip.luau`

The Humanoid re-enables collision on body parts every step, so the script
switches it off in `PreSimulation`, before each physics step. It records only
the parts it switched, so accessories that were already non-colliding stay
that way on restore.

Variant: "noclip only while holding a key" is `set(true)` on `InputBegan` and
`set(false)` on `InputEnded` for that key.

## Speed — `../assets/speed.luau`

Writes `WalkSpeed` and `JumpHeight`, and a `JumpPower` of
`sqrt(2 × Workspace.Gravity × height)` so games that set `UseJumpPower` jump
the same height. Property-changed watchers write the values back when a sprint,
stun or round script changes them.

A "CFrame speed" that nudges the root forward each frame passes a WalkSpeed
check and fails every distance check; it is not safer.

## Infinite jump — `../assets/infinite-jump.luau`

`UserInputService.JumpRequest` fires on the jump key and the mobile jump
button, and repeats every frame while held. Each request sets the Jumping
state, at most once per 0.2 s, so holding the button climbs steadily instead
of launching.

## ESP — `../assets/esp.luau`

A `Highlight` per other player shows the body through walls; a `BillboardGui`
tag shows the display name and distance. Both live in `gethui()` so the game's
own scripts do not see them in `PlayerGui`. The engine renders at most 31
Highlights; the refresh gives them to the 31 nearest players.

| Variant asked for | Change |
|---|---|
| "boxes and lines" (tracers) | `Drawing` objects; see `../../roblox-executor/references/api/drawing.md` |
| "health bars" | a second `TextLabel` or `Frame` in the tag reading `Humanoid.Health` |
| "only enemies" | skip `track` when `other.Team == player.Team` |
| "items or NPCs" | the same marker on the models the game spawns; find them from the dump first |

Teammates get an outline only and enemies a fill, so the difference is not
colour alone.

## Click teleport — `../assets/click-teleport.luau`

Ctrl+click raycasts from the mouse (`GetMouseLocation` with
`ViewportPointToRay`, both in viewport space) and pivots the character 3 studs
above the hit, keeping its facing. On a phone a tap in the world does it;
`processedByUI` keeps taps on buttons out.

Teleporting to a player is the same `PivotTo` with the other root's position.
A game that validates distance per second rejects long jumps; split them into
steps only if the dump shows how the server checks.

## Anti-AFK — `../assets/anti-afk.luau`

`Player.Idled` fires after two minutes without input; the kick comes at
twenty. A `VirtualUser` right click resets the timer. `VirtualUser` is
LocalUser security, reachable from an executor and not from a game's own
LocalScript.

## Fullbright — `../assets/fullbright.luau`

Sets six `Lighting` properties (brightness, noon clock, far fog, no global
shadows, bright ambient and outdoor ambient) and writes each back when a day
and night script changes it. Unload restores the values captured at start.
An `Atmosphere` object still adds haze; set its `Density` to 0 as a seventh
captured value if asked.

## Combining into a hub

```lua
local features = getgenv().Features

features.Speed.walk = 60
features.Speed.set(true)
features.Fly.set(false)
```

A hub's own unload calls every `features.<Name>.unload()`. Toggles are T codes
and speed sliders take an H3 value; see `../../roblox-ui/SKILL.md`.
