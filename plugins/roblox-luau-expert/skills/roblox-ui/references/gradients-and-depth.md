# Gradients

A flat fill is honest. A gradient is a claim about light, and a gradient that
does not agree with the rest of the screen about where the light is coming from
looks worse than the flat fill it replaced.

Most generated Roblox UI uses gradients the same way: a 45-degree two-stop
purple-to-blue on every panel, every button and the background. That is
catalogued in `anti-slop-catalog.md`. This file is the vocabulary for using them
deliberately instead.

---

## The full surface

```lua
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(38, 40, 58), Color3.fromRGB(28, 29, 44))
gradient.Rotation = 90                    -- degrees; 0 is left-to-right
gradient.Parent = panel
```

| Property | Type | Notes |
|---|---|---|
| `Color` | `ColorSequence` | Up to 20 keypoints. Use far fewer |
| `Transparency` | `NumberSequence` | The alpha ramp. Independent of `Color` |
| `Rotation` | number | Degrees. `0` = left to right, `90` = top to bottom |
| `Offset` | `Vector2` | Shifts the ramp. The cheap thing to animate |
| `Type` | `Enum.GradientType` | `Linear` / `Radial` / `Conical` |
| `TileMode` | `Enum.GradientTileMode` | `Clamp` / `Repeat` / `Mirror` |
| `Scale` | number | Extent of the ramp; meaning depends on `Type` |
| `Enabled` | boolean | Toggle without destroying |

`Type`, `TileMode` and `Scale` are the newer half and are absent from almost
every tutorial. They are also the three that make a gradient look designed
rather than defaulted.

> These sit behind a Studio beta for **publishing** at the time of writing.
> The properties exist in the API dump and work in Studio; check the current
> state before shipping a live experience that depends on them.

---

## `Type`

| Value | Behaviour | Where it earns its place |
|---|---|---|
| `Linear` | The classic ramp along `Rotation` | Surfaces, bars, scrims |
| `Radial` | Colour radiates outward from `Offset` | Focus, glow, a spotlit centre |
| `Conical` | Colour sweeps 0–360° around the centre | Progress arcs, loading spinners, rarity sheens |

**`Radial` is the one people miss.** A very slight radial lift on a large panel
— two or three percent lighter at the centre — makes a flat surface read as
lit rather than painted, at no instance cost. It is the difference between a
background and a *space*.

```lua
-- A panel that reads as lit from the centre, not stamped from a swatch.
gradient.Type = Enum.GradientType.Radial
gradient.Offset = Vector2.new(0, -0.2)     -- light source slightly above centre
gradient.Scale = 1.4                        -- reach past the corners
gradient.Color = ColorSequence.new(
    Color3.fromRGB(44, 46, 66),             -- centre
    Color3.fromRGB(30, 31, 47)              -- edge
)
```

**`Conical` is a progress arc without a spritesheet.** Sweep the ramp and let
the transparency stops mask everything past the current value:

```lua
gradient.Type = Enum.GradientType.Conical
gradient.Rotation = -90                     -- start the sweep at 12 o'clock
```

---

## `TileMode` and `Scale`

`Scale` controls how far the ramp extends before `TileMode` decides what happens
outside it.

| `TileMode` | Outside the ramp |
|---|---|
| `Clamp` | The edge colours extend. The default, and right most of the time |
| `Repeat` | The pattern loops |
| `Mirror` | The pattern alternates and flips, so it never seams |

`Repeat` with a small `Scale` gives you stripes, hazard tape, or a scrolling
pattern — animate `Offset` and it moves. `Mirror` is the one to use when a
repeated pattern would otherwise show a hard seam at each tile boundary.

```lua
-- A slow diagonal shimmer across a rare-item card.
gradient.Type = Enum.GradientType.Linear
gradient.TileMode = Enum.GradientTileMode.Mirror
gradient.Rotation = 30
gradient.Scale = 0.35

local sweep = TweenService:Create(
    gradient,
    TweenInfo.new(2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
    { Offset = Vector2.new(1, 0) }
)
sweep:Play()
```

---

## Performance

Roblox's own guidance on the upgraded gradients, worth following:

- **Animate `Offset`, `Rotation`, `Scale`, `TileMode` or `Type` — not `Color` or
  `Transparency`.** The geometry properties are cheap; rebuilding a
  `ColorSequence` or `NumberSequence` every frame is not.
- **Two-stop gradients, or evenly spaced stops, are faster** than many
  irregularly spaced keypoints.
- **Keep the total under roughly a thousand** live gradients. That sounds
  generous until a scrolling inventory gives every one of 400 rows two.

The per-frame version of the second rule matters most:

```lua
-- WRONG - allocates a new ColorSequence every frame
RunService.RenderStepped:Connect(function()
    gradient.Color = ColorSequence.new(shift(), base)
end)

-- RIGHT - build the ramp once, move it
gradient.Color = ColorSequence.new(shift(), base)
RunService.RenderStepped:Connect(function(dt)
    gradient.Offset = Vector2.new((gradient.Offset.X + dt * 0.2) % 1, 0)
end)
```

---

## Gradients on strokes and text

`UIGradient` applies to whatever its parent renders, which includes a `UIStroke`
and includes text.

```lua
-- A gradient border: parent the gradient to the stroke, not the frame.
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Parent = card

local edge = Instance.new("UIGradient")
edge.Rotation = 120
edge.Color = ColorSequence.new(Tokens.color.accent, Tokens.color.accentDim)
edge.Parent = stroke
```

Rotating `edge.Rotation` gives the animated-border effect without a shader. Keep
it slow and keep it to one element — see `anti-slop-catalog.md` on glow density.

On text, a gradient plus `FontFace` weight does more than a bright colour would,
and it survives on both light and dark backgrounds if the ramp stays within one
hue family.

---

## Where a gradient is the wrong answer

- **On every surface.** If the background, the panel and the button are all
  gradients, none of them reads as lit. Pick the one surface that should catch
  the light.
- **As the only difference between two states.** Hover and default must differ
  by something a colour-blind player can see — see `component-states.md`.
- **Across a hue wedge.** Purple to blue to teal in one ramp is the single most
  recognisable generated-UI signature. Stay inside a hue family and vary
  lightness; change hue only when you mean something by it.
- **To fake depth that `UIShadow` should carry.** A dark band at the bottom of a
  panel is not a shadow. See `shadows-and-elevation.md`.

---

## Checklist

- [ ] One lit surface per screen, not every surface.
- [ ] Two or three stops; more only with a reason.
- [ ] Ramp stays within a hue family unless a hue change means something.
- [ ] `Radial` considered before another 45-degree linear.
- [ ] Animation moves `Offset` / `Rotation` / `Scale`, never rebuilds sequences.
- [ ] `Mirror` used where a repeating pattern would seam.
- [ ] Gradient count bounded in scrolling lists.
- [ ] Not the sole carrier of a state change.
