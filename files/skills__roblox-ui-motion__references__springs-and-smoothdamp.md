# Springs and `SmoothDamp`

Tweens answer "move from A to B over T seconds". They answer it badly when **B
changes while the tween is running**, which is most of the interesting motion in a
UI: hover tracking, drag, a value pushed from the server, a list reflowing while an
item is still animating in.

Roblox ships a first-party solution that is rarely used.

---

## The API

<!-- lint: fragment -->
```lua
TweenService:SmoothDamp(
    current: any,        -- current value
    target: any,         -- where it is heading (may change every frame)
    velocity: any,       -- current velocity; you own this between calls
    smoothTime: number,  -- roughly, seconds to reach the target
    maxSpeed: number?,   -- optional clamp
    dt: number?          -- frame delta
) -> (newValue, newVelocity)
```

Verified against dump `0.738.0.7381393`: ungated, `{Safe}` in parallel contexts,
`{Basic}` capability. Works on numbers and on the vector-ish datatypes.

It is a **critically damped** spring: it converges on the target as fast as possible
without overshooting. That is what you want for UI. Overshoot is a stylistic choice
you add deliberately (`Back` easing), not a default.

---

## The idiom

The one thing to get right: **velocity is state you carry between frames.** Storing
it is what makes the motion continuous when the target changes.

```lua
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local current = frame.Position
local velocity = UDim2.new()        -- zero of the same type
local target = frame.Position
local SMOOTH_TIME = 0.12

local connection = RunService.PreRender:Connect(function(dt)
    current, velocity = TweenService:SmoothDamp(current, target, velocity, SMOOTH_TIME, nil, dt)
    frame.Position = current
end)

-- target can now change at any time; motion stays continuous
target = UDim2.fromScale(0.5, 0.5)
```

Compare with the tween version: every time `target` changes you cancel and recreate
the tween, it starts from **zero velocity**, and the element visibly jerks. The spring
does not, because `velocity` survives the change.

---

## Choosing `smoothTime`

`smoothTime` is approximately how long it takes to reach the target. Smaller is
snappier.

| `smoothTime` | Feel | For |
|---|---|---|
| 0.04 – 0.08 | immediate, barely damped | cursor followers, crosshair, aim indicators |
| 0.10 – 0.15 | snappy | hover, selection highlight, tab indicator |
| 0.18 – 0.25 | weighty | panels, drawers, camera-ish motion |
| 0.3+ | floaty | ambient movement, parallax |

`maxSpeed` clamps the peak rate. Its main use is stopping a large target change from
producing a violent snap — set it when the target can jump a long distance, leave it
`nil` otherwise.

---

## Stop the loop when it settles

A `SmoothDamp` loop is per-frame Luau. Leaving one running for every element in a
menu is a real cost. Stop when the value has effectively arrived:

```lua
local EPSILON = 0.001

local function isSettled(a: number, b: number, vel: number): boolean
    return math.abs(a - b) < EPSILON and math.abs(vel) < EPSILON
end
```

For `UDim2`/`Vector2`, compare components or magnitude. `library/src/Motion.luau`
implements this — the loop disconnects itself on settle and restarts on the next
target change, so idle UI costs nothing.

**Never leave a spring loop running for off-screen UI.** Disconnect when the
`ScreenGui` is disabled or the panel closes.

---

## What each is for

| Situation | Use |
|---|---|
| Panel slides in on open | tween — defined start and end |
| Element follows the mouse | **spring** |
| Selection highlight moves between tabs | **spring** — the user can click again mid-motion |
| Health bar reacting to damage | **spring** — damage arrives unpredictably |
| Progress bar filling to a known value | tween |
| Dragged element released | **spring** — carries the release velocity |
| Fade in/out | tween — no interruption to handle |
| List reflowing after a removal | **spring** — items may move again before settling |
| Toast entering | tween; **spring** for the reflow of the ones below it |

Rule of thumb: **if the target can change mid-flight, spring it.**

---

## Manual spring, when you want overshoot

`SmoothDamp` is critically damped by design and will not overshoot. If you
specifically want a bouncy settle, integrate a damped harmonic oscillator yourself:

```lua
-- stiffness: how hard it pulls.  damping: <1 overshoots, 1 is critical, >1 is sluggish.
local function step(current: number, target: number, velocity: number,
                    stiffness: number, damping: number, dt: number): (number, number)
    local force = (target - current) * stiffness
    local drag = velocity * damping * 2 * math.sqrt(stiffness)
    velocity += (force - drag) * dt
    return current + velocity * dt, velocity
end
```

Prefer `SmoothDamp` unless you actually want the overshoot — it is engine-side,
frame-rate independent, and one fewer thing to tune. Reach for this only for a
deliberate accent, and clamp `dt` (a frame spike with a large `dt` makes an
explicit integrator explode; `SmoothDamp` is stable).

---

## Parallel note

`SmoothDamp` is marked `{Safe}`, so it can be called from a parallel context inside an
`Actor`. The **write back to the GuiObject is not** — compute in parallel if you are
solving many springs, then `task.synchronize()` before assigning. In practice UI
rarely has enough springs to justify this; see `roblox-performance` before reaching
for it.
