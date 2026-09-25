# Several features at once

Features break each other when two of them write the same property, or when
one restores a value the other still needs. The tested assets avoid both by
owning separate properties, so any combination can be loaded and toggled in
any order.

## Who owns what

| Feature | Writes | Holds against |
|---|---|---|
| Fly | a `FlyAttachment` with `LinearVelocity` and `AlignOrientation` on the root; `Humanoid.PlatformStand` | respawn |
| Noclip | `CanCollide` on the character's parts it switched off | the Humanoid, every physics step |
| Speed | `WalkSpeed`, `JumpHeight`, `JumpPower` | game writes, respawn |
| Infinite jump | the Humanoid's state on each jump request | nothing to hold |
| ESP | its own `Highlight` and tag instances in `gethui()` | players joining, leaving, respawning |
| Click teleport | the character's pivot, once per click | nothing to hold |
| Anti-AFK | a `VirtualUser` click on `Idled` | nothing to hold |
| Fullbright | six `Lighting` properties | day and night scripts |
| Spectate | `Camera.CameraSubject` | the camera scripts, the target's respawn |
| Camera unlock | zoom distances and `CameraMode` on the player; `Camera.FieldOfView` | game writes, a replaced camera |
| Freecam | `Camera.CameraType`, the camera's `CFrame`, the root's `Anchored`, `MouseBehavior` while dragging | the camera scripts, respawn |

No property appears twice. A new feature picks properties no other feature
owns, or declares that it takes one over and what the other feature does
meanwhile.

## Pairs that interact

| Both on | What happens | Why it is acceptable |
|---|---|---|
| Fly + Freecam | the body stays anchored; fly resumes when freecam is off | neither restores the other's property |
| Spectate + Freecam | freecam's scriptable camera wins; spectating resumes after | freecam never touches `CameraSubject` |
| Speed + Fly | fly moves at its own speed; walking speed applies after landing | `PlatformStand` ignores `WalkSpeed` |
| Noclip + Fly | fly through walls | the usual combination; they share nothing |
| Click teleport + Freecam | teleports move the anchored body; the camera stays | freecam re-anchors whatever body is current |

The doctor prints these when both are on, so a player who reports "fly
stopped working" with freecam on gets the reason instead of a new fly script.

## Restore order does not matter when ownership is clean

Each feature captures its own originals when it turns on and restores only
those. Unloading fly, then freecam, then speed, or any other order, leaves
the game's values: nobody restores a value somebody else captured.

When a feature must take over another's property, it turns the other off
through its API first (`features.Fly.set(false)`), and says so in its reply,
rather than writing the property and letting the other feature's watcher
fight it every frame.

## Keys

Each asset keeps its key in a constant at the top: F fly, V noclip, G speed,
J infinite jump, H ESP, B fullbright, P spectate (with [ and ]), Z camera
unlock, X freecam (E and Q to climb), Ctrl+click teleport. Change a key
there when it collides with the game's own binding. A hub calls `set(on)` and
does not need keys at all.

## A hub over the features

A hub loads each feature file, then drives them through the namespace:

```lua
-- lint: fragment
local features = getgenv().Features

flyToggle.Activated:Connect(function()
	features.Fly.set(not features.Fly.on)
end)

speedSlider.changed = function(value: number)
	features.Speed.walk = value
	features.Speed.set(true)
end
```

The hub's own unload calls every feature's `unload`, then destroys its
window. Toggles are T codes and the slider readout an H3
(`../../roblox-ui/SKILL.md`).
