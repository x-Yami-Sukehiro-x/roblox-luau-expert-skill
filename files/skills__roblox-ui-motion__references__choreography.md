# Choreography

Individually correct animations still read as generated when nothing coordinates
them. The catalog calls this scattered micro-interactions with no orchestration.
Choreography is the difference between *things that move* and *a thing that moves*.

---

## Move together, or move because of each other

Two rules cover most of it:

1. **Things that belong together move together**, with the same curve and duration.
2. **Things that cause each other move in sequence**, with the effect starting before
   the cause finishes.

The second is the one people miss. A strict sequence — panel finishes, *then* content
starts — reads as slow and mechanical. Overlapping them by starting the content at
roughly 60–70% of the container's motion reads as one coherent event.

```lua
panelTween:Play()
task.delay(PANEL_DURATION * 0.65, function()
    contentTween:Play()
end)
```

For anything more than two steps, drive it from one clock with
`TweenService:GetValue` rather than a chain of delays, so the whole sequence stays
in sync and is cancellable as a unit.

---

## Enter and exit are not mirrors

| | Enter | Exit |
|---|---|---|
| Direction | `Out` | `In` |
| Duration | full | ~70–80% of the entry |
| Distance | travels further | travels less, or just fades |
| Content | staggered in | leaves as one unit |

Content should **not** stagger out. Staggering the exit draws attention to something
the user has already dismissed. Fade the container with `CanvasGroup.GroupTransparency`
and let everything leave together.

Exit must also finish properly:

```lua
local panel: CanvasGroup = container      -- GroupTransparency is CanvasGroup-only
local exit = TweenService:Create(panel, MOTION.exit, { GroupTransparency = 1 })
exit.Completed:Connect(function(state)
    if state ~= Enum.PlaybackState.Completed then return end
    panel.Visible = false          -- stops input and layout cost
end)
exit:Play()
```

Leaving `Visible = true` on a fully transparent panel keeps it eating clicks.

---

## `UIPageLayout` — transitions the engine will run for you

Before hand-rolling a slide between screens, check whether `UIPageLayout` does
it. It animates between sibling pages and reports where it is:

```lua
local pages = Instance.new("UIPageLayout")
pages.Animated = true
pages.EasingStyle = Enum.EasingStyle.Quad
pages.EasingDirection = Enum.EasingDirection.Out
pages.TweenTime = 0.28
pages.Circular = false
pages.GamepadInputEnabled = false     -- do not steal the stick from gameplay
pages.ScrollWheelInputEnabled = false
pages.Parent = container

pages:JumpTo(settingsPage)
pages.Stopped:Connect(function(currentPage)
    focusFirstControl(currentPage)     -- move gamepad focus after the move ends
end)
```

`PageEnter` and `PageLeave` fire as the transition starts; `Stopped` fires when
it finishes and hands you the page that ended up current. `CurrentPage` is
`[ReadOnly]`.

Its limits are the reason not to force it: one easing curve for every
transition, no per-direction difference, and no spring. When enter and exit
should differ — which is the rule in the next section — drive it yourself.

The three input switches default on. A page layout that quietly consumes
scroll-wheel or gamepad input is a confusing bug to track down.

---

## Stagger

A list appearing all at once reads as a repaint. Staggered, it reads as arrival.

```lua
local STEP = 0.03          -- seconds between items
local MAX_TOTAL = 0.25     -- never let the whole stagger exceed this

-- Each item is a CanvasGroup, not a bare GuiObject: GroupTransparency exists
-- only on CanvasGroup, and it is what lets one tween fade an entire row.
local function staggerIn(items: { CanvasGroup })
    local step = math.min(STEP, MAX_TOTAL / math.max(#items, 1))

    for index, item in items do
        item.GroupTransparency = 1
        task.delay(step * (index - 1), function()
            if not item.Parent then return end       -- may have been destroyed
            TweenService:Create(item, MOTION.enter, { GroupTransparency = 0 }):Play()
        end)
    end
end
```

Three things that make this correct rather than decorative:

- **Cap the total.** A fixed per-item delay on a 40-item inventory is a 1.2s wait.
  Divide the budget instead so the stagger compresses as the list grows.
- **Check view lifetime as well as `item.Parent`** inside the delayed callback.
  A closed or reused row can still have a parent; invalidate callbacks from the
  previous open before hiding or rebuilding the list.
- **Stagger 20 items at most.** Beyond that the eye reads it as noise; animate the
  container and let the contents appear.

Stagger in **reading order** — top to bottom, or outward from the element that
triggered the change. Random order looks like a glitch.

---

## Shared origin

An element should appear to come from wherever it was triggered. A tooltip grows from
the control it describes. A shop panel expands from the shop button. A context menu
opens from the cursor.

Set `AnchorPoint` toward the origin and animate `UIScale.Scale` from a partial value
rather than sliding a full-size element in:

```lua
local scale = Instance.new("UIScale")
scale.Scale = 0.92
scale.Parent = panel

panel.AnchorPoint = Vector2.new(0, 0)   -- toward the trigger
TweenService:Create(scale, MOTION.enter, { Scale = 1 }):Play()
```

Scaling from **0.9–0.95, not from 0.** Growing from nothing reads as a cartoon pop;
a small scale change plus a fade reads as arrival. This one detail separates
considered UI from templated UI more reliably than any other single choice.

Animating `UIScale.Scale` is also cheaper than animating `Size` — it does not re-run
the parent's layout.

---

## What moves, and what only fades

Not everything should travel. Movement is expensive attention.

- **Move** the container, the thing that changed, the thing being introduced.
- **Fade** everything else — supporting text, icons, background dimming, and anything
  the user is not being asked to look at.

A panel where the frame slides and the contents fade reads as one object. A panel
where every label slides independently reads as forty objects.

---

## Reduced motion

```lua
local GuiService = game:GetService("GuiService")

local reduced = GuiService.ReducedMotionEnabled
GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
    reduced = GuiService.ReducedMotionEnabled
end)
```

`GuiService.ReducedMotionEnabled` is `[Hidden] [ReadOnly]` and **readable from a
normal LocalScript**. There is no `ReducedMotionChanged` event — use
`GetPropertyChangedSignal`. `UserGameSettings.ReducedMotion` is `{RobloxScript}`-gated
and unreachable from game code.

Honouring it means **collapsing motion, not removing the change**:

| Normal | Reduced |
|---|---|
| slide + fade in over 0.22s | fade in over ~0.08s, no travel |
| staggered list | all at once |
| spring follow | snap to target |
| looping pulse | static |

The element still appears; it just does not travel. Removing the state change
entirely breaks the interface for the people who asked for less motion.

Gate this in **one place** — `library/src/Motion.luau` has a single flag every helper
respects — rather than auditing every call site later.

`GuiService.PreferredTransparency` is the companion: a player who has turned
transparency down should not be handed a glass panel they cannot read through.

---

## Attention without idle loops

Use a static unread marker, count or clear action label for an unclaimed reward.
The default build order prohibits idle pulses and rotating decoration. Attention
should follow a meaningful state change and settle when that change is shown.

If the user explicitly requests a looping effect, keep it local to that purpose,
honor reduced motion and stop it on hide or teardown. Do not infer that request
from words such as "polished" or "make it pop".

---

## Cleanup

Every animation is a resource. A tween holds its target; a spring loop holds a
connection; a `task.delay` holds a closure that will run even after the panel closes.

- Own them with a Trove or Janitor per panel lifetime (`roblox-architecture`).
- Cancel tweens before destroying the target.
- Disconnect spring loops on close, not just on destroy.
- Guard delayed callbacks with the owning view's current lifetime as well as
  instance existence. A cancelled close must never hide a subsequently reopened
  panel. Reopening invalidates earlier completion callbacks and delays.

The failure mode is a closed menu still running eleven springs, which shows up as
"the game gets slower the longer you play" rather than as an obvious bug.
