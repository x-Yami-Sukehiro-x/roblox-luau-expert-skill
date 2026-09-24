# Tooltip patterns

The tested implementation is `../../roblox-ui-components/assets/tooltips.luau`.
This file explains the decisions inside it, for adapting a tooltip to a UI the
recipe does not fit.

## Placement

Position from the target's absolute rectangle relative to the tooltip layer:

```lua
local origin = layer.AbsolutePosition
local left = target.AbsolutePosition.X - origin.X
local top = target.AbsolutePosition.Y - origin.Y
local size = bubble.AbsoluteSize
local room = layer.AbsoluteSize

local below = top + target.AbsoluteSize.Y + GAP
local y = if below + size.Y + EDGE <= room.Y then below else top - size.Y - GAP
local rightmost = math.max(EDGE, room.X - size.X - EDGE)
local x = math.clamp(left + target.AbsoluteSize.X / 2 - size.X / 2, EDGE, rightmost)
```

`GAP` is 8 and `EDGE` is 8. Centre on the target, flip above when below would
cross the bottom, then clamp sideways. The `math.max` keeps the clamp valid
when the bubble is wider than the screen.

Size the bubble from its text: `AutomaticSize = XY` on the bubble with a
`UISizeConstraint` max width of 240 and `TextWrapped = true` on the line.
Place it each time it shows, not once at creation: the target may have moved,
scrolled or resized since.

## Layering

A tooltip drawn inside the panel is clipped by any `ScrollingFrame` or
`CanvasGroup` ancestor and sits under later siblings. The recipe gives each
tooltip a `TooltipLayer` `ScreenGui` with `DisplayOrder` two above the host,
`ResetOnSpawn = false` and the host's `ScreenInsets`, so positions measured
against it land on the target; `destroy` removes it.

## Timing

| Moment | Time |
|---|---|
| pointer rests on the target | show after 0.4 s |
| pointer leaves | hide at once, fade 0.1 s |
| touch long press | show after 0.5 s, stay 1.5 s after release |
| gamepad or keyboard selection | show at once |

Every delayed show carries a ticket; leaving invalidates it, so a delay that
finishes after the pointer left never opens the bubble.

## Input

- **Mouse**: `MouseEnter`, `MouseLeave` and, for H8, `MouseMoved`.
- **Touch**: a tap fires `MouseEnter` too. Read
  `UserInputService:GetLastInputType()` (or `UserInputService.PreferredInput`)
  and ignore `MouseEnter` when it is `Touch`; open on an `InputBegan` touch
  held for 0.5 s instead, and cancel it on `InputEnded`.
- **Gamepad**: `SelectionGained` shows at once, `SelectionLost` hides.

A button that has a long-press tooltip must not also act on long press.

## Disabled controls (H9)

A control with `Active = false` or `Interactable = false` receives no input,
so its tooltip can never open. Lay a transparent `ReasonCatcher` button over
it while it is disabled; its hover or tap opens the reason with a lock icon.
Say what unlocks it: "Unlocks at level 10", not "Locked".

## Coach marks (H12)

Show once per player: store a seen flag with the player's other settings
(an attribute read on join, or the game's own save). One mark at a time,
always with a "Got it" button, and never over a control the player is
currently using.

## Anti-patterns

| Seen | Fix |
|---|---|
| tooltip only on `MouseEnter` | add long press and `SelectionGained` |
| bubble parented inside a `ScrollingFrame` | draw on the tooltip layer |
| tooltip text equals the button label | delete the tooltip |
| instructions in a tooltip | helper line (H11) or info button (H6) |
| tooltip that never hides on phones | hide 1.5 s after the touch ends |
| position set once at creation | position every time it shows |
