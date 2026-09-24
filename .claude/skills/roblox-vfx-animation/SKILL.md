---
name: roblox-vfx-animation
description: Roblox animation and visual effects — AnimationTrack lifecycle, Animator:LoadAnimation versus the deprecated Humanoid:LoadAnimation, animation priority weight and blending, keyframe and marker signals, ParticleEmitter configuration and Emit bursts, Beam and Trail, Highlight, attachment-driven effects, effect pooling and budgets, and replicating effects without trusting the client. Use for playing or blending animations, "the animation does not play", particle and beam effects, hit and impact effects, or anything about how a visual effect should be spawned, replicated and cleaned up.
---

# Animation and visual effects

Two systems that share a lifetime problem: both create objects that outlive the
frame that spawned them, and both leak quietly when nobody owns the cleanup.

---

## Load a reference when

| Need | File |
|---|---|
| tracks, priority, blending, markers | `references/animation.md` |
| emitters, beams, trails, highlights, pooling, replication | `references/effects.md` |

---

## Animation: the three-object chain

```
Animation          an asset id, inert on its own
  -> Animator      lives under Humanoid or AnimationController
     -> AnimationTrack   the playable, controllable instance
```

```lua
local animator = humanoid:FindFirstChildOfClass("Animator")
    or humanoid:WaitForChild("Animator", 10)

local track = animator:LoadAnimation(animation)
track.Priority = Enum.AnimationPriority.Action
track:Play(0.15)          -- fadeTime, not "delay"
```

**`Humanoid:LoadAnimation` is `[Deprecated]`.** Load through the `Animator`.
The deprecated path still works and still appears in most tutorials, which is
why animations loaded that way stop replicating correctly in some contexts and
the cause is never obvious.

**Load once, keep the track.** `LoadAnimation` on every swing allocates a new
track each time and is the usual reason a combat system's memory climbs. Cache
tracks per character and re-`Play` them.

---

## Priority decides what wins

`Enum.AnimationPriority`, low to high: `Idle` (0), `Movement` (1), `Action` (2),
`Action2` (3), `Action3` (4), `Action4` (5), `Core` (1000).

A track only visibly overrides another if its priority is at least as high. The
most common "my animation does not play" is an `Action`-priority attack losing
to nothing at all — it plays, at weight, underneath a `Movement` walk cycle that
is animating the same joints.

Set `Priority` **before** `Play`. Setting it on a playing track works but blends
awkwardly.

---

## Effects: the ownership question first

Before writing any effect code, answer one thing: **who is this for?**

| Scope | Where to create it | Why |
|---|---|---|
| Only the local player sees it | Client | Free. No bandwidth, no replication |
| Everyone must see it | Server, or a client-side reaction to a replicated event | Correctness |
| Everyone sees it, exact timing does not matter | Server fires a remote; each client builds its own | Cheapest correct option |

The third row is the one to reach for. Replicating a hundred `ParticleEmitter`
instances from the server is expensive; sending one "explosion at this position"
message and letting each client build the effect locally is not.

A client-built effect is **cosmetic only**. It must never be the thing that
decides whether damage happened.

---

## Standing rules

1. **`Animator:LoadAnimation`**, never the `[Deprecated]` `Humanoid:LoadAnimation`.
2. **Cache tracks.** One load per animation per character.
3. **Set `Priority` before `Play`.**
4. **Every effect has an owner and a death.** A Trove, a `Debris:AddItem`, or an
   explicit `Destroy` on a signal. An unparented emitter with `Rate > 0` runs forever.
5. **Disable, wait out `Lifetime`, then destroy.** Destroying an emitter
   instantly kills particles mid-flight and looks like a bug.
6. **Effects are cosmetic.** Never gate a gameplay outcome on one.
7. **Pool anything that spawns more than a few times a second.**
8. **Budget particles.** `Rate` times `Lifetime` is roughly how many are alive at
   once, per emitter, and mobile pays for every one.
