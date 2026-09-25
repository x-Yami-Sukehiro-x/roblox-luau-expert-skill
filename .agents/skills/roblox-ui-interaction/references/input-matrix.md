# Input matrix

Which input paths each kind of control must pass, how to exercise each in the
Luau mocks (`library/tests/stubs.luau`), and what to do in Studio for the
paths the mocks cannot model.

## Rows every control passes

| Path | Mock | Studio |
|---|---|---|
| act with the mouse | `button.Activated:Fire(input, 1)` | click |
| act by touch | the same `Activated`, with `UserInputType.Touch` in the input | device emulator, tap |
| act by gamepad | the same `Activated` after `SelectionGained:Fire()` | controller A, or the emulator's gamepad |
| pressed look on touch | `InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch })` then `InputEnded` | hold a finger on it |
| press cancelled | `InputBegan` then `InputEnded` with no `Activated` | press, drag off, release |
| focus look | `SelectionGained:Fire()`, then `SelectionLost:Fire()` | move selection onto it and away |
| disabled | set the disabled state, fire `Activated`: nothing changes | tap it while disabled |
| twice in a row | fire `Activated` twice: the second does the second thing, or nothing if pending | double-tap |

`Activated` is the one signal that carries the action, so firing it with each
input type proves the handler does not branch on the device. The pressed and
focus looks are separate signals and need their own rows.

## Rows by control

| Control | Extra rows |
|---|---|
| toggle | the state flips on each `Activated`; the knob, colour and label all follow; the value reaches the feature (`Features.Fly.set`) |
| slider | a touch drag moves the value; the readout (H3, H4 or H5) follows; the value is rounded to the step; gamepad left and right move one step |
| dropdown | opens on `Activated`; a choice closes it and updates the field; B or Escape closes without choosing; the list is not clipped by its panel |
| text field | focus and `FocusLost(enterPressed)`; shortcuts do not fire while focused; the field is above the on-screen keyboard |
| tab bar | each tab selects on `Activated`; selection persists; gamepad bumpers or left and right change tabs |
| modal | opening selects its first control; selection cannot leave it; B closes; focus returns to the opener |
| draggable window | dragging by touch and mouse; the close button still activates; the window stays on screen after a resize |
| list row | a tap without movement activates; a moving touch scrolls instead |

## A mock test, in the shape the recipe tests use

```lua
-- lint: fragment
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local touch = { UserInputType = Enum.UserInputType.Touch }
toggle.InputBegan:Fire(touch)
check("a finger on it shows the pressed look", toggle.BackgroundColor3 == THEME.press)
toggle.InputEnded:Fire(touch)
toggle.Activated:Fire(touch, 1)
check("a tap turns it on", state.on == true and knob.Position == ON_POSITION)
toggle.SelectionGained:Fire()
check("gamepad focus shows the ring", ring.Enabled == true)
toggle.Activated:Fire({ UserInputType = Enum.UserInputType.Gamepad1 }, 1)
check("A turns it off again", state.on == false)
```

Fire the file's own connected signals; never copy its handler into the test.
`../../roblox-ui/references/functional-proof.md` covers the rest of the
behaviour cases (failed requests, reopening, respawn, rerun, unload).

## What the mocks cannot show

The stubs model signals and property writes, not rendering or hit testing.
They cannot show a frame on top of a button, a clipped hit area, a scroll
stealing a tap, or the on-screen keyboard covering a field. Those rows are
Studio rows: walk them in the device emulator and say which were walked.
