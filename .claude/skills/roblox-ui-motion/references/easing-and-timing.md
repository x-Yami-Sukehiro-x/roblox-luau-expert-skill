# Easing and timing

Roblox's easing set is fixed and cannot be extended — there is no cubic-bezier input.
Verified against dump `0.738.0.7381393`:

**`Enum.EasingStyle`** — `Linear`, `Sine`, `Back`, `Quad`, `Quart`, `Quint`,
`Bounce`, `Elastic`, `Exponential`, `Circular`, `Cubic`
**`Enum.EasingDirection`** — `In`, `Out`, `InOut`

Because the set is fixed, the useful skill is **choosing by intent**, not inventing
curves.

---

## Direction is a meaning, not a preference

| The element is… | Direction | Reads as |
|---|---|---|
| entering, appearing, responding to input | `Out` | arrives fast, settles — responsive |
| leaving, dismissing, closing | `In` | accelerates away — gets out of the way |
| moving between two states, no clear start or end | `InOut` | a transition, symmetric |

`Out` on entry is the single most important one. It front-loads the movement, so the
element is *mostly where it is going* within the first third of the duration. That is
what makes an interface feel fast even when the numbers are identical.

`In` on exit for the mirror reason: the viewer has already understood the element, so
it should get out of the way rather than linger.

---

## Style, by how much character you want

| Style | Character | Use for |
|---|---|---|
| `Sine` | barely there | subtle fades, colour, opacity — the safest default |
| `Quad` | gentle | general UI movement |
| `Cubic` | firmer | panels, drawers, anything with weight |
| `Quart` / `Quint` | sharp | fast, snappy, small elements |
| `Exponential` | very sharp | dramatic entrances, near-instant starts |
| `Circular` | mechanical | progress, meters, things that should feel measured |
| `Back` | small overshoot | one accent moment — a reward popup, not a menu |
| `Linear` | none | **only** for continuous loops, spinners, marquees |
| `Bounce` | heavy | almost never in UI |
| `Elastic` | heaviest | almost never in UI |

**`Linear` is wrong for anything that starts and stops.** Real things accelerate.
`Linear` is correct only for motion with no start or end — a rotating spinner, a
scrolling ticker.

**`Bounce` and `Elastic` are almost always wrong.** They read as playful exactly once
and as slow every time after, because they extend the tail of the animation without
adding information. If a UI wants character, `Back` with a small overshoot on entry is
the restrained version of the same idea.

---

## Duration bands

There is no single correct number. Duration should scale with **distance travelled**
and **how much of the screen changes** — a tooltip and a full-screen panel should not
share a value.

Bands that hold up in practice:

| Band | Range | For |
|---|---|---|
| Instant | 0.06 – 0.10s | hover, press, focus — state feedback on an element already on screen |
| Short | 0.12 – 0.20s | small elements entering, tooltips, toasts, dropdowns |
| Medium | 0.20 – 0.32s | panels, drawers, tab switches, modals |
| Long | 0.35 – 0.50s | full-screen transitions, scene changes |
| Deliberate | 0.5s+ | reward moments and celebrations only |

**Exits take about 70–80% of the matching entry.** If a panel enters over 0.28s, it
leaves over about 0.20s.

Two rules that matter more than the exact numbers:

- **Anything responding to a direct input must feel immediate.** Above roughly 0.1s
  for press feedback, the control feels laggy. This is the one place to be strict.
- **Nothing that happens frequently should be slow.** A menu opened forty times a
  session at 0.5s is twenty seconds of waiting.

---

## Delay and repeat

```lua
TweenInfo.new(
    0.24,                            -- duration
    Enum.EasingStyle.Cubic,
    Enum.EasingDirection.Out,
    0,                               -- repeatCount, -1 = forever
    false,                           -- reverses
    0                                -- delayTime
)
```

`TweenInfo` is immutable — build a new one to change anything. That makes them ideal
as frozen constants:

```lua
local MOTION = table.freeze({
    press   = TweenInfo.new(0.08, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    enter   = TweenInfo.new(0.22, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    exit    = TweenInfo.new(0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
    move    = TweenInfo.new(0.24, Enum.EasingStyle.Quad,  Enum.EasingDirection.InOut),
})
```

Naming them by **intent** rather than by shape (`enter`, not `cubicOut220`) is what
keeps the mapping consistent as the UI grows, and makes a global retune one edit.

`repeatCount = -1` with `reverses = true` is the correct way to build a pulsing
attention loop — not a `while` loop firing tweens.

---

## `TweenService:GetValue`

```lua
TweenService:GetValue(alpha: number, easingStyle: Enum.EasingStyle,
                      easingDirection: Enum.EasingDirection) -> number
```

Maps `alpha` in 0–1 through an easing curve. This is how you apply Roblox easing to
something `TweenService:Create` cannot animate — a value you are computing, a
non-property, several instances driven from one clock, or a custom interpolation.

```lua
local elapsed = 0
local DURATION = 0.3

local connection
connection = RunService.PreRender:Connect(function(dt)
    elapsed += dt
    local alpha = math.clamp(elapsed / DURATION, 0, 1)
    local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

    for index, item in items do
        item.Position = start[index]:Lerp(goal[index], eased)
    end

    if alpha >= 1 then connection:Disconnect() end
end)
```

Note this is a per-frame Luau loop — it costs more than a `Tween`, which the engine
evaluates natively. Use it when you need the control, not by default.

---

## Common failures

**One `TweenInfo` for the whole file.** The catalog tell R12. Entering, leaving and
moving are different events.

**Not checking `PlaybackState`.** `Tween.Completed` fires on `Cancelled` too:

```lua
tween.Completed:Connect(function(state)
    if state ~= Enum.PlaybackState.Completed then return end
    ...
end)
```

**Two tweens on one property.** Starting the newer tween cancels the older one.
Keep a handle and one owner per property; ignore cancelled or obsolete completion
callbacks. See [TweenService](https://create.roblox.com/docs/reference/engine/classes/TweenService).

**Using `Visible` as a fade.** A boolean cannot produce a gradual fade. Animate
transparency or scale, then set `Visible = false` on completion so the element
stops taking input.

**Chaining with `task.wait(duration)`** instead of `Completed`. Drifts under load and
desynchronises from the actual tween.

**Tweening `Size`/`Position` inside a `UIListLayout`.** Forces a layout pass for every
sibling every frame. Animate `UIScale.Scale` or transparency instead where possible.
