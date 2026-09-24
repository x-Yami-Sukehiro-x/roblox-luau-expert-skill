# Slider values

A slider without a number makes the player guess, and a number that jitters,
lies about its step or hides under a thumb is worse. The readouts are H3, H4
and H5 in `../../roblox-ui-components/assets/tooltips.luau`:

```lua
local readout = createSliderValue({
	track = track,
	thumb = thumb,
	min = 16,
	max = 100,
	format = function(value)
		return `{math.round(value)} speed`
	end,
}, "H3")

-- The slider's own drag code calls these.
readout.setDragging(true)
readout.update(value)
readout.setDragging(false)
```

The readout only displays. The slider owns the value and the drag.

## Which readout

| The player needs | Code |
|---|---|
| a number while choosing, out of the way otherwise | H3 |
| the exact value at a glance, always | H4 |
| the range and the value together | H5 |

Two sliders side by side should use the same readout.

## Formatting

- **Round to the step.** A 1-step walk speed shows `32`, never `32.4871`.
  Snap the value first, then format the snapped value, so the number and the
  thumb agree.
- **Say the unit** in the game's words: `32 speed`, `80%`, `1.5x`, `90°`.
- **Fixed decimals** for fractional steps: `string.format("%.1f", value)`, so
  the label does not change width as the value moves.
- **Percent sliders** store 0 to 1 and show 0 to 100.

## Dragging

- Read the position from `UserInputService.InputChanged` while dragging, not
  from the thumb's own events, so the drag continues when the pointer leaves
  the thumb. Accept `MouseMovement` and `Touch`.
- Update the display every change, but commit (save, fire a remote) on
  release. A remote per frame is a rate-limit problem and a lag spike.
- Clamp before formatting; H3 clamps its own display to `min` and `max`.
- The whole track is the touch target: a tap on the track jumps the thumb.
  Keep the track row at least 44 px tall even when the bar is 6 px.

## Typing an exact value

For a wide range (0 to 1000), make the readout a `TextBox`: tapping it selects
the number, Enter or `FocusLost` parses it, clamps it, snaps it to the step and
moves the thumb. Reject text that is not a number by restoring the last good
value rather than showing an error.

## Gamepad and keyboard

A selected slider moves one step on left and right and ten steps with the
shoulder buttons. Bind with `ContextActionService` while the slider is
selected, and unbind on `SelectionLost`.
