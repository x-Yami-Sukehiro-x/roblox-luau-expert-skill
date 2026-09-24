# Shadows, depth and elevation

Depth in a flat interface is a **system**, not a decoration. If every panel has
the same shadow, the shadow communicates nothing — it is just a grey smear that
makes the screen look muddier. Depth earns its place only when the amount of it
maps to how far above the page a surface is meant to sit.

---

## `UIShadow` is first-party now

For years the only way to get a soft shadow was a 9-slice `ImageLabel` behind
the panel. `UIShadow` replaces that: fewer instances, correct scaling, no asset
to ship, and it follows the parent's corner radius automatically.

```lua
local shadow = Instance.new("UIShadow")
shadow.Color = Color3.new(0, 0, 0)
shadow.Transparency = 0.75
shadow.BlurRadius = UDim.new(0, 18)
shadow.Offset = UDim2.fromOffset(0, 6)
shadow.Spread = UDim2.fromOffset(0, 0)
shadow.Parent = panel
```

| Property | Type | What it does |
|---|---|---|
| `BlurRadius` | `UDim` | Softness. The single most important value |
| `Offset` | `UDim2` | Displacement. Almost always `(0, +y)` — light comes from above |
| `Spread` | `UDim2` | Grows the shadow shape before blurring |
| `Color` | `Color3` | See below; pure black is usually wrong |
| `Transparency` | number | 0 opaque, 1 invisible |
| `Inset` | boolean | Renders *inside* the parent — an inner shadow |
| `ShowBehindParent` | boolean | Whether the parent occludes it |
| `Mode` | `Enum.ApplyShadowMode` | `Shape` follows the frame; `Text` shadows the glyphs |
| `ZIndex` | number | Order among siblings of the same parent |
| `Enabled` | boolean | Toggle without destroying |

Two of these are the interesting ones.

**`Inset = true`** gives an inner shadow, which is what a pressed button, a
recessed track, or an input field that reads as "carved in" actually needs.
Nobody reaches for it because the 9-slice hack could not do it.

**`Mode = Enum.ApplyShadowMode.Text`** shadows the glyphs rather than the box.
That is a legible drop shadow on text over a 3D scene, without the halo you get
from a thick contextual `UIStroke`.

```lua
local textShadow = Instance.new("UIShadow")
textShadow.Mode = Enum.ApplyShadowMode.Text
textShadow.BlurRadius = UDim.new(0, 3)
textShadow.Offset = UDim2.fromOffset(0, 1)
textShadow.Transparency = 0.5
textShadow.Parent = nameplate
```

---

## An elevation scale

The point of a scale is that a reader can tell two surfaces apart *without
being told which is on top*. Four levels is enough for any game UI.

```lua
Tokens.elevation = {
    -- level        blur   y-offset  transparency
    flush   = { blur =  0, y = 0, alpha = 1.00 },  -- no shadow; sits on the page
    raised  = { blur =  6, y = 2, alpha = 0.86 },  -- cards, list rows
    floating= { blur = 18, y = 6, alpha = 0.75 },  -- panels, dropdowns
    overlay = { blur = 40, y =14, alpha = 0.62 },  -- modals, the topmost thing
}
```

```lua
local function applyElevation(frame: GuiObject, level: string)
    local e = Tokens.elevation[level]
    local shadow = frame:FindFirstChildOfClass("UIShadow")

    if e.blur == 0 then
        if shadow then shadow.Enabled = false end
        return
    end

    if not shadow then
        shadow = Instance.new("UIShadow")
        shadow.Parent = frame
    end

    shadow.Enabled = true
    shadow.Color = Tokens.color.shadow
    shadow.BlurRadius = UDim.new(0, e.blur)
    shadow.Offset = UDim2.fromOffset(0, e.y)
    shadow.Transparency = e.alpha
end
```

Blur and offset rise together, and transparency **falls** as they rise. A
higher surface casts a larger, softer, slightly stronger shadow. Raising blur
while keeping the shadow faint produces fog rather than height.

**Only one thing on screen should be at `overlay`.** If a modal and a dropdown
are both at the top level, neither reads as the top level.

---

## Surface, border and shadow move together

An elevation is not just a shadow. It is **three values that change as one**:
the fill, the border, and the shadow. Pick any surface on screen and the other
two follow from it.

```lua
Tokens.layer = {
    raised   = { fill = Tokens.surface.base,    stroke = Tokens.surface.raised,  elevation = "raised" },
    floating = { fill = Tokens.surface.raised,  stroke = Tokens.surface.overlay, elevation = "floating" },
    overlay  = { fill = Tokens.surface.overlay, stroke = Tokens.surface.overlay, elevation = "overlay" },
}
```

The border of a surface is the **next rung up**, never a text colour. Text
tokens are tuned for contrast against a fill; used as a line they read as a
highlight, because that is what they were built to be.

### Two surfaces at the same height look the same

This is the rule generated UI breaks most visibly, and it is what people mean
when they say a notification "doesn't match".

A toast and a panel are both floating. They are peers. So they take the same
fill, the same border, the same radius and the same shadow — and they differ
only in *position and lifetime*. If the toast is a lighter grey with a brighter
outline, the player reads two different applications on one screen, and no
amount of matching the accent colour fixes it.

A worked failure, from a real generated script:

| | Panel | Toast | |
|---|---|---|---|
| fill | `surface.base` | `surface.overlay` | two rungs apart |
| stroke | `surface.overlay` | `text.muted` | a text token used as a line |
| stroke alpha | `0.35` | `0.45` | no reason for the difference |
| radius | `10` | `10` | the only thing that matched |

Every individual value is defensible. Together they describe two different
elevations for two things that are at the same elevation, so the toast looks
like it was pasted in from somewhere else. It was: it was written later, from
the same palette, without reference to the panel.

The fix is not to hand-match the numbers. It is to stop writing numbers at the
call site:

```lua
-- Both of these are floating. Neither states a colour.
local function asLayer(frame: GuiObject, name: string)
    local layer = Tokens.layer[name]
    frame.BackgroundColor3 = layer.fill

    local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Color = layer.stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.35
    stroke.Parent = frame

    applyElevation(frame, layer.elevation)
end

asLayer(panel, "floating")
asLayer(toast, "floating")
```

Now the two cannot drift, because there is one place that says what floating
looks like. Matching by hand works until the third surface.

### When two surfaces *should* differ

Different elevation is a real reason, and the checklist below is the test:

| Differs because | Legitimate |
|---|---|
| One is a dropdown open over its own trigger | yes — `floating` over `raised` |
| One is a modal and the other is the page behind it | yes — `overlay` over `raised` |
| A focus ring, which is an accent, not a border | yes — it is a different job |
| A shadow colour, which is not a border at all | yes |
| One was written on Tuesday and one on Thursday | no |

Whether two surfaces sit at the same height is a design question, so no linter
decides it. The one thing that is always wrong is a **text token used as a
`UIStroke.Color`** — and the way to never do it by accident is the `Tokens.layer`
table above, where no call site picks a colour.

---

## Shadow colour

Pure black shadows are the giveaway. Real shadows take colour from what they
fall on, and on a coloured background a black shadow reads as dirt.

```lua
-- Tint the shadow toward the background's hue, darkened.
Tokens.color.shadow = Color3.fromRGB(12, 10, 22)     -- on a cool dark surface
```

On a saturated brand colour, tint further toward that hue. The rule of thumb:
take the surface colour, drop lightness hard, keep some of the hue. Never
`Color3.new(0, 0, 0)` unless the background is genuinely neutral.

---

## Depth without shadows

Shadow is one of four tools and usually not the first one to reach for.

| Tool | Reads as | Cost |
|---|---|---|
| **Value step** | The reliable one. A lighter surface on a darker page | Free |
| **Border** | A crisp `UIStroke` at low contrast | Free |
| **Shadow** | Physical height | One instance, some fill rate |
| **Blur behind** | Glass, focus | A `BlurEffect` on `Lighting` — global |

**A value step is the strongest and cheapest signal.** Two surfaces two or three
percent apart in lightness separate cleanly with no shadow at all, and the
result survives being screenshotted, compressed and viewed on a bad phone
screen. Reach for shadow when you need *height* specifically — something that
floats over content it must not be confused with.

For borders and dividers, see `outlines-and-dividers.md`. Briefly: layer strokes
rather than thickening one, and use `Enum.BorderStrokePosition.Inner` when the
stroke must not grow the element's footprint.

---

## Blur behind a modal

`BlurEffect` is a **post-process effect on `Lighting`** — it blurs the whole 3D
scene, not a UI subtree. There is no per-frame backdrop blur in Roblox UI.

```lua
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local function openModal()
    scrim.Visible = true
    TweenService:Create(blur, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { Size = 18 }):Play()
end

local function closeModal()
    local out = TweenService:Create(blur, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Size = 0 })
    out.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            scrim.Visible = false
        end
    end)
    out:Play()
end
```

Three things that go wrong with this:

- **It is global and it is shared.** If two systems each create a `BlurEffect`,
  they stack. Own exactly one, created once, and tween its `Size`.
- **Leaving it on.** A blur that survives the modal closing makes the game look
  broken and the player will not know why. Tween it to `0` and only hide the
  scrim on `Completed` — see the `PlaybackState` trap in `roblox-ui-motion`.
- **It blurs the world, not the UI.** Anything already on screen in `PlayerGui`
  stays sharp. That is usually what you want, but it means blur alone does not
  separate a modal from the HUD behind it. Pair it with a translucent scrim.

`DepthOfFieldEffect` (`FocusDistance`, `InFocusRadius`, `NearIntensity`,
`FarIntensity`) is the subtler cousin — good for a cinematic pause screen, too
slow and too situational for a menu that opens fifty times a session.

Both cost fill rate on low-end devices. Gate them:

```lua
if GuiService.ReducedMotionEnabled then blur.Size = 0 end
```

---

## Common failures

**Shadow on everything.** If a card, a button, a tooltip and a divider all cast
one, the interface has no hierarchy and looks soft everywhere. Most elements
should be `flush`.

**Shadow with no offset.** `Offset = (0, 0)` and a large blur produces a glow,
not a shadow. Glows read as "selected" or "magical"; if you did not mean either,
give it a downward offset.

**Shadow instead of contrast.** A shadow does not make low-contrast text
readable. Fix the contrast.

**Stacking a stroke and a shadow at full strength.** Pick one to carry the edge.
A crisp border plus a heavy shadow reads as a sticker.

**Animating `BlurRadius` per frame.** It is a render-target operation. Animate
`Transparency` or the element's `UIScale` instead, and change blur only on
discrete state changes.

---

## Checklist

- [ ] `UIShadow`, not a 9-slice `ImageLabel` behind the frame.
- [ ] Elevation comes from a named scale, not per-component numbers.
- [ ] Blur, offset and strength move together across the scale.
- [ ] Exactly one element at the top level.
- [ ] Shadow colour tinted toward the background hue, not pure black.
- [ ] A value step tried before a shadow.
- [ ] One shared `BlurEffect`, tweened to zero on close, hidden on `Completed`.
- [ ] `Inset` used for pressed and recessed surfaces.
- [ ] `ApplyShadowMode.Text` for glyph shadows over 3D, not a thick stroke.
