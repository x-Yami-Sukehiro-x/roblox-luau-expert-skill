# Clipping: outlines, rings, shadows and popups cut off

Something drawn outside its element's box disappears wherever an ancestor
clips. The element is fine; its parent is cutting it. Find the clipping
ancestor first, then pick the fix that keeps the drawing inside it.

## What clips

| Ancestor | Clips to | Note |
|---|---|---|
| `ScrollingFrame` | its own rectangle, always | every scrolling list clips its rows |
| `CanvasGroup` | its own rectangle, always | and its rounded corner, if it has a `UICorner` |
| any `GuiObject` with `ClipsDescendants = true` | its rectangle, not its rounded corner | also blocks input outside that rectangle |
| the screen | the viewport, and the safe area with `ClipToDeviceSafeArea` | `../../roblox-ui-viewport/SKILL.md` |

## What draws outside its box

| Drawing | How far outside | Fix inside a clipping parent |
|---|---|---|
| `UIStroke` with `BorderStrokePosition = Outer` (the default) | its full `Thickness` | `BorderStrokePosition = Inner`, or `UIPadding` on the parent of at least the thickness |
| `UIStroke` with `Center` | half the thickness | the same |
| a focus ring (an extra `UIStroke` or frame around the control) | ring thickness plus any gap | `Inner` ring inside lists; padding the list by the ring |
| a 9-slice shadow image larger than its card | the shadow's spread | shadows on cards inside a list sit inside the row's padding, or use `UIShadow` on the list's own frame |
| a press or hover `UIScale` above 1 | the grown amount | padding for the growth (4 px covers a 1.04 scale on a 200 px row), or scale down on press instead |
| a badge or count bubble offset past the corner | its overhang | pad the parent, or move the badge inside the corner |
| a dropdown list, tooltip or context menu | its whole body | draw it in its own `ScreenGui` above the host (`../../roblox-ui-viewport/references/overflow.md`) |
| text descenders in a row exactly `TextSize` tall | a few pixels of g, j, p, y | rows at least `TextSize + 8` tall; never `ClipsDescendants` on a text row |

## The two cases that ship most often

**A list of outlined rows.** Rows are full width in a `ScrollingFrame`; each
has the default Outer `UIStroke`. The first row loses its top edge, every row
loses both sides. `lint-roblox-ui.mjs` reports it as `E-STROKECLIP`.

```lua
local THEME = { border = Color3.fromRGB(44, 48, 57) }

local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 44)

local outline = Instance.new("UIStroke")
outline.Color = THEME.border
outline.Thickness = 1
outline.BorderStrokePosition = Enum.BorderStrokePosition.Inner
outline.Parent = row
```

**A focus ring on a control inside a scrolling panel.** Gamepad focus lands on
a toggle at the edge of the list; the ring is half drawn, and the player
cannot tell what is focused. Either the ring is `Inner`, or the list's
`UIPadding` is at least the ring's thickness on every side.
`build-order.md` step 8 calls for an `Outer` ring, which is right for a
control standing on a panel and wrong inside anything that clips.

## Rounded corners are a different problem

A `UICorner` rounds its own element, not its children, and
`ClipsDescendants` clips to the rectangle. Square children poke out of a
rounded box (`E-CORNERBLEED`). The fix is a `CanvasGroup` holding the
`UICorner`, or insetting the children by the radius:
`../../roblox-ui-components/references/outlines-and-dividers.md`.

## Checking for it

1. `node tools/bin/lint-roblox-ui.mjs <file>`: `E-STROKECLIP`, `E-CORNERBLEED`,
   `E-SCROLLCORNER`.
2. In Studio, give focus to the first and last row of every list with a
   gamepad or keyboard navigation, and look at all four edges of the ring.
3. Open every popup from a control near each edge of its panel.
4. Hover and press controls at the edge of a list; a growing press effect
   must not lose its edge.
