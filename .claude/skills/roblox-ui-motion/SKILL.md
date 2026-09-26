---
name: roblox-ui-motion
description: Animating Roblox UI - easing, durations, TweenService, springs, reduced motion. Use for opening, closing, janky tweens.
---

# UI motion

For new or redesigned UI with unresolved motion preferences, use
`roblox-request-intake/references/visual-choices.md`: show the interactive guide
and ask in everyday words. Match an existing choice instead of asking again.
The preference chooses the visible effect; this skill chooses implementation,
interruption handling and reduced-motion behavior. Each menu code M0–M36 has a
tested presenter in `../roblox-ui-components/assets/menus.luau`, specified in
`../roblox-ui-components/references/style-recipes.md`.

Motion in Roblox goes wrong in three predictable ways: one `TweenInfo` used for
everything, tweens fighting each other over the same property, and tweens used for
things that need to be interruptible.

| Need | File |
|---|---|
| which easing, how long | `references/easing-and-timing.md` |
| interruptible motion, drag, hover tracking | `references/springs-and-smoothdamp.md` |
| enter/exit, stagger, orchestration, reduced motion | `references/choreography.md` |

Working implementation: `library/src/Motion.luau`.

---

## The first decision: tween or spring

**Tween** when the motion has a defined start, end and duration, and nothing will
interrupt it. A panel sliding in. A progress bar filling. A fade.

**Spring** when the target can change while the motion is running. Hover tracking, a
dragged element, a value that updates from the server, anything following the mouse.

This is the decision most Roblox UI gets wrong. A tween restarted mid-flight
**discards its velocity and snaps** — the element jerks because the new tween starts
from rest. A damped spring carries velocity through the target change, which is the
entire reason well-made UI feels physical.

Roblox ships a first-party spring and almost nobody uses it:

```lua
TweenService:SmoothDamp(current, target, velocity, smoothTime, maxSpeed?, dt?)
    -> (newValue, newVelocity)
```

Verified ungated and `{Safe}` in parallel contexts. It is critically damped, so it
settles without overshoot. Full treatment in `references/springs-and-smoothdamp.md`.

You do **not** need a third-party spring library. The obvious candidate,
`roact-spring`, has not been touched in over two years.

---

## Intent to easing

Roblox's easing set is fixed: `Linear`, `Sine`, `Back`, `Quad`, `Quart`, `Quint`,
`Bounce`, `Elastic`, `Exponential`, `Circular`, `Cubic`, each with `In`, `Out` or
`InOut`.

Map by **what the motion means**, not by taste:

| The element is… | Direction | Why |
|---|---|---|
| entering, appearing, responding to a tap | **`Out`** | arrives fast, settles gently — feels responsive |
| leaving, dismissing, closing | **`In`** | accelerates away; needs less of the viewer's attention |
| moving between two states with no clear start or end | **`InOut`** | symmetric, reads as a transition rather than an arrival |

**Exits are shorter than entries.** An element arriving is information; an element
leaving is already understood.

`Bounce` and `Elastic` are almost always wrong for UI. They read as playful exactly
once and as slow every time after. If a UI genuinely wants character, `Back` with a
small overshoot on entry is the restrained version.

---

## The traps

**`Tween.Completed` fires with a `PlaybackState`.** It fires on `Cancelled` too. Code
that chains the next step in `Completed` without checking runs that step when the
tween was cancelled.

```lua
tween.Completed:Connect(function(state)
    if state ~= Enum.PlaybackState.Completed then return end
    -- genuinely finished
end)
```

**A newer tween on the same property cancels the earlier tween.** Its completion
listener can still run with `Cancelled`, so stale callbacks are the hazard. Keep
one owner per animated property and check completion state and the current view
lifetime before chaining or hiding. Roblox documents this replacement behavior in
[TweenService](https://create.roblox.com/docs/reference/engine/classes/TweenService).

**A tween holds a reference to its target.** Cancel it before destroying the instance,
or track it in a Trove. See `roblox-architecture`.

**Fade a subtree with `CanvasGroup`, not N tweens.** `GroupTransparency` fades every
descendant as one composited layer — one tween instead of one per element, and no
half-faded children at different rates.

```lua
local group = Instance.new("CanvasGroup")
group.GroupTransparency = 1
group.Size = UDim2.fromScale(1, 1)
group.BackgroundTransparency = 1
group.Parent = parentFrame          -- nothing renders until it is in the tree

TweenService:Create(group, TweenInfo.new(0.18), { GroupTransparency = 0 }):Play()
```

`CanvasGroup` renders its children to a texture, so it is not free. Use it for panels
that fade as a unit, not for every frame.

**Use `Visible` as the final visibility switch.** Animate transparency or size
for the transition, then set `Visible = false` at the end so the element stops
consuming input and layout. A boolean transition cannot produce a gradual fade.

---

## Reduced motion

Some players get motion sick, and some just want the menu open now. Roblox exposes a
real player setting for this:

```lua
local GuiService = game:GetService("GuiService")

local function reducedMotion(): boolean
    return GuiService.ReducedMotionEnabled
end

GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
    Motion.setReducedMotion(GuiService.ReducedMotionEnabled)
end)
```

`GuiService.ReducedMotionEnabled` is `[Hidden] [ReadOnly]` but **readable from a
normal LocalScript** — verified. There is **no `ReducedMotionChanged` event**; use
`GetPropertyChangedSignal`, which every property has.

Do not reach for `UserGameSettings.ReducedMotion` — it is `{RobloxScript}`-gated and
unreachable from game code.

Honour it by **collapsing duration to zero, not by removing the state change** — the
element still appears, it just does not travel. `library/src/Motion.luau` gates every
helper on one flag so this is a single switch rather than an audit.

`GuiService.PreferredTransparency` is the companion signal — a player who has reduced
transparency should not be given a glass panel they cannot read through. Same read
pattern.

---

## Performance

- Tweens are evaluated by the engine, not your script. A hundred simultaneous tweens
  is cheaper than a hundred per-frame Luau loops.
- A `SmoothDamp` loop **is** per-frame Luau. Run it on `PreRender` for visual smoothness,
  stop the loop when the value has settled, and do not leave it running for
  off-screen UI.
- Animating `Size` or `Position` on an element inside a `UIListLayout` forces a layout
  pass every frame for every sibling. Animate a `UIScale` or the element's
  transparency instead where you can.
- `UIScale.Scale` is the cheapest way to animate apparent size — it does not re-run
  layout the way `Size` does.

## Works with

- `roblox-ui-components`: the recipes that carry the motion.
- `roblox-ui-interaction`: press feedback on touch and gamepad too.
- `roblox-performance`: nothing animating when idle.
