# The element contract

Every HubKit element returns a handle with the same shape, so hub code never
needs to know which element it holds. A library built from this skill should
keep the same contract, even under different names.

## The handle

| Member | What it is |
|---|---|
| `Get()` | the current value (absent on Button, Paragraph, Divider) |
| `Set(value)` | changes the value, redraws, fires `Changed` and runs the Callback |
| `Changed` | a Signal; `Changed:Connect(function(value) ... end)` |
| `SetTitle(text)`, `SetDescription(text?)` | rewrites the row's two lines |
| `SetDisabled(disabled)` | `Interactable` off, title muted, no hover |
| `Destroy()` | releases the row and everything it connected |
| `Frame` | the row instance, for layout tricks the kit does not cover |
| `Encode`, `Decode` | optional; how a flagged value is saved and loaded |

## When a Callback runs

- **On every `Set`, even to the same value.** Loading a config calls `Set` on
  each flag, and a saved "Fly on" must start fly even when the toggle's
  Default was already on.
- **Not when the element is created**, with one exception: a Toggle built
  with `Default = true` runs its Callback once, deferred, because a switch
  shown on must mean the feature is on. A Slider's Default is only a number
  on screen; writing it to the game on creation would overwrite a value the
  game set (a WalkSpeed of 20 reset to 16).
- **During a drag**, a Slider calls back on every snapped step. A
  ColorPicker calls back when the drag ends, because a colour change often
  rebuilds something (an ESP) and sixty rebuilds a second is a stall.
- **For a Keybind**, when the bound key is pressed and the press was not
  consumed by the game (typing in chat). `Mode = "Hold"` also calls back with
  `false` on release.

## Values and how they are saved

| Element | Value | Saved as |
|---|---|---|
| Toggle | boolean | boolean |
| Slider | number, snapped to `Step`, clamped to `Min`..`Max` | number |
| Dropdown | string or nil; an array in `Values` order for `Multi` | string or array |
| Input | string; number when `Numeric` | string |
| Keybind | `Enum.KeyCode` or nil | the KeyCode's Name |
| ColorPicker | Color3 | six hex digits |

Decoding a KeyCode walks `Enum.KeyCode:GetEnumItems()` for the saved name, so
an unknown name loads as no key rather than erroring.

## States

`Row.button` draws five states for every button row; the element draws the
sixth, *selected*, its own way.

| State | How it shows |
|---|---|
| rest | the `raised` role |
| hover | `hover`, 0.12 s |
| press | `stroke`, the next step up |
| focus (keyboard, gamepad) | a 2 px inner ring in `focus` |
| disabled | `Interactable = false`, 40% transparent, muted title |
| selected | Toggle: knob moves and track turns `accent`. Dropdown: the value in the slot. Tab: filled, bold, accent icon |

Selected is never colour alone: the knob moves, the text changes weight, or
a check mark appears.

## Adding an element

A Stepper (minus, value, plus) as the worked case:

1. Add the module to `src/Elements/` with `Stepper.new(container, options)`.
2. Build on `Row.button(container, options)` if the whole row does one thing,
   or `Row.frame(container, options)` if it holds controls of its own. Put
   the controls in `row.slot`, or in `row.below` for a stacked element.
3. Give the handle `Get` and `Set`; in `Set`, redraw, then
   `self.Changed:Fire(value)`, then the Callback.
4. Connect everything through `row.trove:connect(...)`, including theme
   changes if the element colours anything by state.
5. Add one line to `REGISTRY` in `library/hub-kit/src/Elements/init.luau`. Every Tab and
   Section now has `:Stepper({...})`; Flag, config and search come free.
6. Add assertions to `library/hub-kit/tests/hub-kit.luau`: value, Callback, Flag, disabled,
   destroy. Rebuild the bundle and run the tests.

What an element must not do: create its own ScreenGui (use `Popup`), connect
to `RunService` for anything but an active drag, colour anything with a
literal instead of a role, or call a Callback from inside `new`.
