# Outlines, shadows and separation

"Add a border" is the default answer to every grouping problem and it is usually the
wrong one. This covers what the stroke API can actually do, when a line is the right
tool, and the ways to separate things without drawing one.

All properties verified against dump `0.738.0.7381393`.

---

## `UIStroke` — the full surface

Most code uses `Thickness` and `Color` and nothing else. The rest is where the
interesting results are.

| Property | Type | Notes |
|---|---|---|
| `Thickness` | `number` | pixels, or scaled — see `StrokeSizingMode` |
| `Color` | `Color3` | |
| `Transparency` | `number` | independent of the parent's |
| `ApplyStrokeMode` | `Enum.ApplyStrokeMode` | `Contextual` \| `Border` |
| `BorderStrokePosition` | `Enum.BorderStrokePosition` | `Outer` \| `Center` \| `Inner` |
| `BorderOffset` | `UDim` | extra offset from the border |
| `LineJoinMode` | `Enum.LineJoinMode` | `Round` \| `Bevel` \| `Miter` |
| `StrokeSizingMode` | `Enum.StrokeSizingMode` | `FixedSize` \| `ScaledSize` |
| `ZIndex` | `number` | layer multiple strokes |
| `Enabled` | `boolean` | toggle without destroying |

### `BorderStrokePosition` is the one people miss

`Outer` (the default) draws the stroke **outside** the element's bounds, which makes
the element visually larger than its `Size` and misaligns it against neighbours in a
`UIListLayout`.

`Inner` draws inside the bounds. Use it when the element must stay exactly its
declared size — which is almost always true inside a layout.

`Center` straddles, splitting the thickness.

For a focus ring that should sit *outside* without disturbing layout, `Outer` is
correct, unless an ancestor clips: inside a `ScrollingFrame`, a `CanvasGroup` or
a `ClipsDescendants` parent the outside half is cut off
(`../../roblox-ui/references/clipping.md`, lint code `E-STROKECLIP`). For a card
border in a list, `Inner`.

### `ApplyStrokeMode`

On a `TextLabel` or `TextButton`, `Contextual` (the default) outlines the **glyphs**.
`Border` outlines the element's rectangle instead.

This is why "I added a UIStroke to my button and the text got an outline" happens. On
a text element, set `ApplyStrokeMode = Border` when you want a box.

You can have both — two `UIStroke` children, one `Contextual` for the text and one
`Border` for the box, ordered by `ZIndex`.

### Layered strokes

`UIStroke.ZIndex` means multiple strokes compose. A thick dark outer stroke plus a
thin bright inner stroke reads as a bevelled edge, and costs two instances:

```lua
local outer = Instance.new("UIStroke")
outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outer.BorderStrokePosition = Enum.BorderStrokePosition.Outer
outer.Thickness = 3
outer.Color = Tokens.stroke.shadow
outer.ZIndex = 0
outer.Parent = panel

local inner = Instance.new("UIStroke")
inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inner.BorderStrokePosition = Enum.BorderStrokePosition.Inner
inner.Thickness = 1
inner.Color = Tokens.stroke.highlight
inner.ZIndex = 1
inner.Parent = panel
```

### Gradient strokes

A `UIGradient` parented **to the `UIStroke`** gradients the stroke itself,
independently of the fill:

```lua
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Tokens.accent.base, Tokens.accent.dim)
gradient.Rotation = 90
gradient.Parent = stroke        -- the stroke, not the frame
```

Animating that `Rotation` is the honest version of the "animated gradient border"
effect — one tween on one property, no per-frame Luau.

### `StrokeSizingMode`

`FixedSize` keeps the thickness in pixels regardless of element size. `ScaledSize`
scales it with the parent. The official design guidance that "UIStroke supports only
offset" predates `ScaledSize` — it is real and verified.

For most UI `FixedSize` is correct: a 1px hairline should stay 1px on every screen, or
it stops reading as a hairline.

---

## `UICorner` — per-corner radii

```lua
local corner = Instance.new("UICorner")
corner.TopLeftRadius = UDim.new(0, 8)
corner.TopRightRadius = UDim.new(0, 8)
corner.BottomLeftRadius = UDim.new(0, 0)
corner.BottomRightRadius = UDim.new(0, 0)
```

Four independent corners — the correct way to build a tab joined to its panel, a
segmented control, or a message bubble.

> The legacy `CornerRadius` property is still assignable but expresses only one
> radius for all four corners. It is marked `[NotReplicated]` in the
> current dump. The four per-corner properties are the live surface; prefer them.

Radius in **scale** (`UDim.new(0.2, 0)`) stays proportional across screen sizes;
radius in offset does not. A constant offset radius on both a 32px button and a 600px
panel is catalog tell R15.

`Scale >= 0.5` produces a pill.

### A rounded box does not round what is inside it

This is the one that gets reported as "the accent bar is pointing out of my
rounded notification", and it is not a bug in the bar.

Roblox's own `UICorner` documentation:

> Input, but not descendants, will be clipped to the round corner area.

So the container draws a rounded shape, and a child that reaches its edge draws
a **square** corner on top of it. The classic case is a severity strip down the
left of a toast:

```lua
-- WRONG: the strip is full height, so its square top-left corner sits on top
-- of the toast's rounded one.
toast.ClipsDescendants = true          -- does not help; see below
accentStrip.Size = UDim2.new(0, 4, 1, 0)
accentStrip.Parent = toast
```

**`ClipsDescendants` does not rescue it.** That clips to the rectangle, not the
curve, so setting it looks like a fix and changes nothing. If you find both
`UICorner` and `ClipsDescendants = true` on one frame, somebody believed the
clip would follow the rounding.

Four fixes, in order of preference:

| Fix | When |
|---|---|
| Make the container a **`CanvasGroup`** | anything with children at its edge |
| Put `UIPadding` on the container | the child never needs to touch the edge |
| Give the child its own matching `UICorner` | one child, and a pill reads fine |
| Inset the child and stop it short of the corners | a strip that can be shorter than full height |

The first is the real answer, and Roblox documents why:

> UIComponent visual modifiers such as UICorner and UIGradient under a
> CanvasGroup will also apply to the whole group. Note that CanvasGroup always
> has ClipsDescendants set to true and all descendants will be clipped outside
> the group's bounds.

```lua
-- RIGHT: the group is composited first, then rounded, so the strip is cut to
-- the curve along with everything else.
local toast = Instance.new("CanvasGroup")
toast.BackgroundColor3 = Tokens.layer.floating.fill

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toast
```

Three conditions on `CanvasGroup`, all from the same page, all worth knowing
before reaching for it everywhere:

- The ancestor `ScreenGui` must have `ZIndexBehavior = Sibling`, or descendants
  are not flattened and nothing is clipped to the curve.
- It costs texture memory, capped by the client's `QualityLevel`. **Over the
  cap it renders as a blank texture** — a whole panel disappears rather than
  degrading.
- It wants a static size. A frame that resizes every frame rebuilds its
  texture every frame.

So: `CanvasGroup` for the handful of surfaces that are rounded *and* have
children at the edge. Not as the default frame type.

**`UICorner` cannot be applied to a `ScrollingFrame` at all** — also
documented. Round a `Frame` around the scroller instead, and let the scroller
sit inside it with padding.

`lint-roblox-ui.mjs` fails all of this as `E-CORNERBLEED` and `E-SCROLLCORNER`.

---

## Shadows — `UIShadow` first

Full treatment, including inner shadows, text shadows and an elevation scale:
**`shadows-and-elevation.md`**. The short version:

```lua
local shadow = Instance.new("UIShadow")
shadow.BlurRadius = UDim.new(0, 18)
shadow.Offset = UDim2.fromOffset(0, 6)
shadow.Transparency = 0.75
shadow.Parent = panel          -- follows the panel's corner radius by itself
```

The common fake — a black `Frame` at ~0.7 transparency offset behind the panel —
does not blur, so it reads as a second rectangle, and it breaks against rounded
corners. Catalog tell R9.

### The 9-slice fallback

Before `UIShadow` existed, a **9-slice image** was the correct answer, and it
remains a reasonable one when you need a shadow shape `UIShadow` cannot produce
— a long directional cast, or a stylised drop. It scales correctly at any size
because the corners never stretch:

```lua
local shadow = Instance.new("ImageLabel")
shadow.Image = "rbxassetid://<soft shadow with transparent centre>"
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(64, 64, 192, 192)   -- from the source image
shadow.SliceScale = 1
shadow.BackgroundTransparency = 1
shadow.ImageTransparency = 0.6
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ZIndex = panel.ZIndex - 1

-- extend past the panel so the blur is visible on all sides
shadow.Size = UDim2.new(1, 48, 1, 48)
shadow.Position = UDim2.fromScale(0.5, 0.5)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Parent = panel
```

The nine regions: corners never scale, top/bottom edges scale horizontally, left/right
edges scale vertically, centre scales both. `SliceCenter` is a `Rect` of pixel offsets
into the **source image**; Studio's 9-slice editor (four draggable red lines) is the
practical way to set it.

`SliceScale` multiplies the non-stretching regions — useful for one border image
serving several sizes.

The same technique gives you crisp custom borders, frames and panel skins at any size,
which is how UI stops looking like `UICorner` + `UIStroke` on everything.

---

## Dividers

When a line **is** the right answer, it should be a hairline, not a border.

```lua
local divider = Instance.new("Frame")
divider.BackgroundColor3 = Tokens.stroke.subtle
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, 0, 0, 1)      -- full width, exactly 1px
divider.Parent = container
```

Rules:

- **1px, in offset.** A divider in scale becomes 3px on a big monitor and invisible on
  a phone.
- **Low contrast.** A divider competing with body text is too strong. Transparency
  0.4–0.7 against the surface, or a colour a step off the background.
- **Inset it** to align with the content rather than the container edge — give it
  `UIPadding` on the parent, or size it `UDim2.new(1, -32, 0, 1)`.
- **`BorderSizePixel = 0`** on the divider itself or you get a border on your border.
- In a `UIListLayout`, a divider is just another child with a `LayoutOrder`. Do not
  try to draw between items.

**Never put a divider between every row.** A list with a line between each item reads
as a table. Group with spacing and use one divider between *groups*.

---

## Separation without lines

This is the part that distinguishes designed UI from bordered-everything UI. In order
of preference:

**1. Space.** The strongest and cheapest grouping signal. Related items close,
unrelated items further apart. If a divider and extra spacing would both work, use the
spacing.

**2. Background step.** A raised surface separates itself from the page without any
edge. Two or three surface levels is plenty — page, panel, control.

**3. A heading.** A label with weight above a group does more than any line.

**4. Alignment.** Things sharing a left edge read as a set. Breaking alignment
separates without adding anything.

**5. Then a line** — for genuinely ambiguous adjacency, like a footer holding actions
against the content above it.

A useful test: **remove every divider from the design.** Whatever becomes genuinely
ambiguous gets one back. Usually that is one or two places, not fifteen.

---

## Common failures

| Symptom | Cause |
|---|---|
| Text has an unwanted outline | `ApplyStrokeMode` left `Contextual` on a text element |
| Element misaligns with siblings in a list | `BorderStrokePosition = Outer` growing it past its `Size` |
| Outline or focus ring cut off at a list's edge | an `Outer` stroke inside a clipping parent; `Inner`, or pad the parent by the thickness |
| Border looks thick on desktop, invisible on mobile | thickness in scale, or radius in scale where offset was needed |
| Shadow looks like a grey rectangle | stretched `Frame` instead of a 9-slice image |
| Border on the divider | `BorderSizePixel` left at its default |
| Corners clipped oddly on a rotated element | `UICorner` plus rotation; use a 9-slice image instead |
| Everything looks boxed in | a stroke on every element — catalog tell R1 |
