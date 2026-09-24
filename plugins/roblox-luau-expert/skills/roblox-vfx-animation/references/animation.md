# AnimationTrack, priority and blending

---

## The full track surface

| Member | Kind | Note |
|---|---|---|
| `Play(fadeTime?, weight?, speed?)` | Function | `fadeTime` defaults to 0.1 |
| `Stop(fadeTime?)` | Function | Same default. `Stop(0)` is a hard cut |
| `AdjustSpeed(speed?)` | Function | 0 pauses; negative plays backwards |
| `AdjustWeight(weight?, fadeTime?)` | Function | How much this track contributes |
| `GetMarkerReachedSignal(name)` | Function | Fires at an animation-editor marker |
| `GetTimeOfKeyframe(name)` | Function | Where a named keyframe sits, in seconds |
| `Priority` | `Enum.AnimationPriority` | Set before `Play` |
| `Looped` | boolean | Overrides the asset's own setting |
| `TimePosition` | number | Scrub. `[NotReplicated]`, so a client-side scrub is local |
| `Length` | number, `[ReadOnly]` | **Zero until the asset loads** |
| `Speed`, `WeightCurrent`, `WeightTarget`, `IsPlaying` | `[ReadOnly]` | Observe, do not assign |
| `DidLoop`, `Ended`, `Stopped`, `KeyframeReached` | Events | |

Note `Speed` and `WeightCurrent` are `[ReadOnly]` — change them through
`AdjustSpeed` and `AdjustWeight`, not by assignment.

**`Length` is 0 until the animation asset has downloaded.** Code that computes a
timeout or a follow-up from `track.Length` immediately after `LoadAnimation`
gets zero and fires instantly. Either preload with
`ContentProvider:PreloadAsync`, or read `Length` after the first `Play`.

---

## A track cache

```lua
--!strict
local Tracks = {}
Tracks.__index = Tracks

function Tracks.new(animator: Animator)
    return setmetatable({ _animator = animator, _byName = {} }, Tracks)
end

function Tracks:get(name: string, assetId: string, priority: Enum.AnimationPriority)
    local existing = self._byName[name]
    if existing then
        return existing
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = assetId

    local track = self._animator:LoadAnimation(animation)
    track.Priority = priority

    self._byName[name] = track
    return track
end

function Tracks:destroy()
    for _, track in self._byName do
        track:Stop(0)
        track:Destroy()
    end
    table.clear(self._byName)
end
```

Build one per character, hand it to the character's Trove, and let
`CharacterRemoving` tear it down. Tracks belong to an `Animator`, and an
`Animator` dies with its character — a cache that outlives the character holds
dead tracks.

---

## Priority, weight and why an animation "does not play"

Priority decides which track's contribution to a joint wins. Weight decides how
much of it applies. They are different levers and the failure looks the same.

Ranked causes of "the animation does not play", most common first:

1. **Priority too low.** An `Action` attack under a `Movement` walk cycle plays
   and is invisible. Raise to `Action2` or higher, or stop the competing track.
2. **The track was garbage collected.** `animator:LoadAnimation(a):Play()` as one
   expression keeps no reference. Store the track.
3. **Loaded on the wrong `Animator`.** A new character has a new `Humanoid` and a
   new `Animator`; a cached track from the previous life plays into nothing.
4. **The asset is not owned by the place owner.** Animations only load for the
   creator's own uploads or the group's. This fails silently in a team-create
   place and works in Studio for the uploader.
5. **`Play` called every frame.** Each call restarts the fade, so the animation
   perpetually blends in and never advances visibly.
6. **`AnimationId` malformed.** `rbxassetid://` plus the id, not a URL.

```lua
-- WRONG - restarts the fade every frame; the animation never progresses
RunService.Heartbeat:Connect(function()
    if moving then
        walkTrack:Play(0.2)
    end
end)

-- RIGHT - transitions are edges, not states
local function setMoving(value: boolean)
    if value == moving then return end
    moving = value
    if moving then walkTrack:Play(0.2) else walkTrack:Stop(0.2) end
end
```

---

## Blending

`AdjustWeight` is how you mix two tracks rather than swapping them. The classic
use is a directional locomotion blend or a partial-body overlay:

```lua
-- Aim overlay applied on top of whatever the legs are doing.
aimTrack.Priority = Enum.AnimationPriority.Action2
aimTrack:Play(0.1, 0)                  -- start at zero weight
aimTrack:AdjustWeight(aimAmount, 0.12) -- fade in over 0.12s
```

Weights are relative, not absolute: two tracks at weight 1 on the same joint
contribute half each. That is why fading one out raises the other's visible
influence without you touching it.

`WeightCurrent` and `WeightTarget` let you observe the fade in flight — useful
for deciding when a transition has finished, and read-only for a reason.

---

## Markers beat timers

Anything that must line up with a specific moment in an animation — the frame a
sword connects, the step a footstep sound plays on — should hang off a marker,
not `task.delay`.

```lua
local connection = swingTrack:GetMarkerReachedSignal("Impact"):Connect(function()
    swingHitbox()
end)
```

A `task.delay(0.35, ...)` desynchronises the moment anyone changes the animation
or adjusts its speed. A marker moves with the asset. `AdjustSpeed` scales the
marker's real time automatically; a hardcoded delay does not.

`GetMarkerReachedSignal` returns a signal that fires **for every play** of that
track, so connect it once when the track is cached, not per swing. Connecting
per swing is a leak that grows with combat length.

`GetTimeOfKeyframe(name)` gives the time of an editor keyframe, which is how you
compute a windup duration from the asset rather than guessing it.

---

## Stopping cleanly

```lua
track:Stop(0.15)          -- fades out over 0.15s
track:Stop(0)             -- immediate; use for death and hard interrupts
```

`Stopped` fires when the fade completes; `Ended` fires when the animation
finishes naturally. Do not use `Ended` to detect an interruption — an
interrupted track never ends.

`Animator:GetPlayingAnimationTracks()` returns everything currently playing,
which is the reliable way to clear state on death or a state change:

```lua
for _, playing in animator:GetPlayingAnimationTracks() do
    playing:Stop(0.1)
end
```

---

## Replication

Animations played through an `Animator` **on the client that owns the character**
replicate to everyone automatically. That is the intended path for player
character animation, and it means the server does not need to fire anything.

Consequences worth stating plainly:

- **A client can play any animation on its own character.** Including one you
  did not intend. Animation is cosmetic, so this is not a security problem
  unless you attached gameplay to it — which is the actual mistake.
- **NPC animations must be played on the server**, since no client owns them.
- **Never derive a hit from an animation event on the client.** The marker
  signal is a good place to *ask* the server, not to *tell* it. See
  `roblox-game-security`.

---

## Checklist

- [ ] Loaded through `Animator`, not the `[Deprecated]` `Humanoid:LoadAnimation`.
- [ ] Tracks cached, one per animation per character, destroyed with the character.
- [ ] `Priority` set before `Play`.
- [ ] `Play` and `Stop` driven by state edges, not called every frame.
- [ ] `Length` not read before the asset has loaded.
- [ ] Timing hangs off markers, not `task.delay`.
- [ ] Marker signals connected once per track, not per use.
- [ ] `GetPlayingAnimationTracks` used to clear state on death.
- [ ] No gameplay outcome derived from a client animation event.
