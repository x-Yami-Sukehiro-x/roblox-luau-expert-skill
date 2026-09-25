# Content that leaves its box

A panel can fit the screen and still lose what is inside it. Each case below
is one symptom, its cause, and the fix the rest of the stack uses.

## A list longer than its frame

**Symptom:** the last rows are cut off, or push the panel's footer off the
screen. **Cause:** the list is a `Frame` with a layout, or a `ScrollingFrame`
whose `CanvasSize` was set once for the rows that existed then.

```lua
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.fromScale(1, 1)
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollBarThickness = 4
list.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
list.BackgroundTransparency = 1
```

The list takes the space left by the header and footer through a
`UIFlexItem` with `FlexMode = Fill`, so the footer's buttons stay on screen
however many rows there are. `VerticalScrollBarInset` keeps the bar from
drawing over the rows' right edge. Check the last row by scrolling to the
end at the smallest profile.

## A label longer than its space

| Text | Fix |
|---|---|
| a sentence (description, error, dialog body) | `TextWrapped = true` and `AutomaticSize = Y` on the label; the row grows |
| a name or value in a fixed row | `TextTruncate = AtEnd`, and the full text in a tooltip or detail view |
| a button label | shorter words first (`../../roblox-ui/references/ui-copy.md`); then let the button grow with `AutomaticSize = X` inside a wrapping row |

Never `TextScaled` on a sentence: it shrinks the one long label until nobody
can read it, and the rows beside it no longer match. Test with the longest
real string and with `PreferredTextSize` at `Largest`.

## A popup past the screen edge

**Symptom:** the bottom of a dropdown list or the side of a tooltip is off the
screen, or cut by a scrolling panel. **Cause:** it opens in one fixed direction
inside the panel that holds its button.

1. Draw popups in their own `ScreenGui` with `DisplayOrder` above the host
   and the host's `ScreenInsets` copied, so no panel clips them
   (`roblox-ui-components/assets/dropdowns.luau` does this).
2. Measure the space below and above the button from `AbsolutePosition` and
   the screen's `AbsoluteSize`; open toward the larger one (D15 opens upward).
3. Clamp the final position so the popup's box stays inside the screen with
   an 8 px margin. Tooltips flip side the same way
   (`../../roblox-ui-tooltips/references/tooltip-patterns.md`).

## A dragged window left off-screen

**Symptom:** after rotating the phone or shrinking the window, the hub's title
bar is outside the screen and the window cannot be dragged back. **Cause:** the
position was stored in pixels and never re-checked.

- Drag with a `UIDragDetector` whose `BoundingUI` is the screen, or clamp by
  hand on every drag step.
- Keep the stored position as scale, so a smaller screen moves it
  proportionally.
- On `Camera.ViewportSize` change, clamp once more: the title bar must stay
  fully on screen.

```lua
-- lint: fragment
local function keepOnScreen(window: GuiObject, screen: GuiBase2d)
	local area = screen.AbsoluteSize
	local size = window.AbsoluteSize
	local anchor = window.AnchorPoint
	local x = math.clamp(window.AbsolutePosition.X + size.X * anchor.X, size.X * anchor.X, area.X - size.X * (1 - anchor.X))
	local y = math.clamp(window.AbsolutePosition.Y + size.Y * anchor.Y, size.Y * anchor.Y, area.Y - size.Y * (1 - anchor.Y))
	window.Position = UDim2.fromScale(x / area.X, y / area.Y)
end
```

`window.AbsolutePosition` is measured in the screen's space only when the
window is a direct child of the `ScreenGui`; a nested window subtracts its
parent's `AbsolutePosition` first.

## A text field under the on-screen keyboard

**Symptom:** on a phone, tapping a search or amount field raises the keyboard
over the field; the player types blind. **Cause:** the field sits in the lower
half of the screen, where the keyboard opens.

Put text fields in the upper half of any panel used on touch. If one has to
sit low, lift its panel while
`UserInputService.OnScreenKeyboardVisible` is true, using
`OnScreenKeyboardPosition` to find the keyboard's top, and put it back on
`FocusLost`.

## A toast stack taller than the screen

**Symptom:** a burst of notifications runs off the bottom (or top) and the
newest are never seen. **Cause:** no cap on the stack. Keep at most three
visible, queue the rest, and let a new one replace the oldest
(`roblox-ui-components/assets/toasts.luau`).

## A grid that does not reflow

**Symptom:** item slots overflow sideways on a phone, or sit in two lonely
columns on a monitor. **Cause:** a `UIGridLayout` with an offset `CellSize`.
Compute the column count from the frame's `AbsoluteSize.X` on resize and set
`CellSize` from it, with a `UIAspectRatioConstraint` on each cell to keep them
square.
