# Interaction states

Six interaction states, with loading handled separately. A tab can be selected
and focused while a request is pending; these are not mutually exclusive labels.

| State | Driven by | Visible treatment |
|---|---|---|
| rest | no transient interaction | the baseline |
| hover | `MouseEnter` / `MouseLeave` | background one step up |
| press | `InputBegan` / release or cancellation | darker fill, optional small scale down |
| focus | `SelectionGained` / `SelectionLost` | a visible ring independent of selected state |
| disabled | availability and pending state | inert appearance with a readable reason |
| selected | the current tab, toggle value or chosen row | a marker or label as well as accent |

One-shot actions such as Close do not need sticky selection. State accounting
must reflect the control's meaning; never invent a selected value solely to
satisfy a linter. Loading is additional state for work that may yield, not a
replacement for selected.

## State has one owner

Use one render function to derive appearance from current state. Event callbacks
change state and call it; they do not each write a different fill directly.

1. Derive availability from the actual requirement and pending work.
2. Choose fill with precedence disabled, press, hover, selected, rest.
3. Draw focus independently so a selected tab still shows where gamepad input goes.
4. Keep the selected marker independent of transient hover and press.
5. Render every affected property on every path. An early disabled return must
   not leave an old focus ring, press scale or spinner behind.

Set `AutoButtonColor = false` for custom styling. Own the current appearance
tween, cancel it before replacing it, and stop it before applying a disabled
appearance. A cancelled animation's completion must not apply stale state.

`GuiObject.GuiState` is read-only and reports `Idle`, `Hover`, `Press` and
`NonInteractable`. It can drive transient appearance or cross-check input state.
It does not describe application selection, gamepad focus or pending requests.
Do not interpret `NonInteractable` as proof that a request was cancelled.

`GuiButton.Selected` is a boolean property; keep it synchronized with the
application's selected value when using it. Do not use focus as that value.

## Input and activation

Use `GuiButton.Activated` for mouse, touch and gamepad activation. Keep press
feedback separate from executing the action; executing from both `InputBegan`
and `Activated` submits twice.

- Track the input that began a pointer press. Clear it on its matching release,
  cancellation, leaving the active hit area, hiding, disabling or destruction.
  Another finger's release must not terminate the original touch.
- A release can happen outside the control. When tracking pointer input, use a
  scoped `UserInputService.InputEnded` connection for that release and clean it
  up. A `MouseLeave` reset alone does not handle touch cancellation.
- If manually styling gamepad press, account for `Enum.KeyCode.ButtonA` on the
  focused control as well as mouse and touch. Do not activate unrelated controls.
- Store every connection and disconnect it at the owning component's teardown.
  A live global input listener must also stop when its gesture ends.

The clickable object must be a `TextButton` or `ImageButton` with at least a
44 px effective hit area. A transparent parent `Frame` does not enlarge the
child button's activation target. Put the small icon inside the full-size button.

## Disabled and loading

Set `Interactable = false` to disable engine interaction. Keep the action's own
availability/pending guard as well, because other code may call the same action.
Restore availability from current requirements, not unconditionally to `true`.

Use a restrained disabled surface and retain legible text. Show a requirement
such as `Requires level 10` beside the control or through an accessible details
action; a hover-only tooltip cannot explain a disabled control on touch.

For an asynchronous action:

1. Validate current availability and set pending before the first yield.
2. Disable repeat activation and show immediate textual feedback. A delayed
   spinner is optional and must be cancelled if work finishes before it appears.
3. Call the source-proven function or remote with its exact arguments. For a
   remote, distinguish a call that returned from an operation the server accepted.
4. After the yield, check the component lifetime and request/item identity.
   A non-nil `Parent` is insufficient when a panel was hidden or reused.
5. Clear only this request's pending state. Render a confirmed result or a useful
   failure and recovery path; an old result must not unlock newer pending work.

Disabling the button does not provide server validation or purchase idempotency.
Do not auto-retry an ambiguous write unless its contract makes retries safe.
See `../../roblox-ui/references/functional-proof.md` for the test cases.

## Focus and gamepad

Make actionable controls selectable and define a predictable reading order with
`SelectionOrder` or explicit `NextSelection*` neighbors where automatic navigation
fails. Give focus to a usable control when opening for keyboard/gamepad input.

`GuiService.SelectedObject` reads and sets current gamepad selection. Save the
opener before moving into a modal, keep navigation in the active modal, and
restore the opener on close if it is still visible and usable. Otherwise choose
the next usable control or clear selection; never leave it on an invisible item.
Do not let a delayed close from an old view overwrite a newer modal's focus.

`SelectionImageObject` takes a **GuiObject**, not a `UIStroke`. Use a frame or
image containing the focus styling when assigning that property, or control a
stroke on the button through the focus events. Ensure the ring is not clipped.

Focus is not hover and is not selected. Test navigation with the mouse unused,
including entering and leaving dropdowns, modals and scrolling lists.

## Motion and final check

Use the project's motion tokens; the default press response is 0.08 s Quad Out.
A `UIScale` around 0.97 can support press feedback, but the hit target must remain
usable. Respect reduced motion without omitting the final state change.

- Exercise rest, hover, press, focus and disabled; selected where meaningful.
- Press, drag outside and release. Cancel a touch. Disable during a press.
- Focus a selected tab, then navigate away; selection must persist.
- Activate rapidly, fail the request, close during the delay, then reopen.
- Destroy the component; no owned listener, tween or delayed update may survive.

The source linter cannot prove these sequences. Record which ones ran and which
remain untested.
