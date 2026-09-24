# UI behavior and evidence

Use while building a complete interface and again before delivery. A linter
checks source patterns. A screenshot checks one rendered state. Neither proves
that a control does what its label promises.

## Connect the screen to the task

Before construction, name the primary action, the value it reads or changes,
and the source that owns that value. For each control, know its trigger, effect,
feedback and unavailable reason. A short working note is enough; do not turn
this into a second specification when the source already establishes it.

- Group by what the player does: equip an item, adjust audio, choose a target.
  Do not create equal-size cards or tabs merely to fill space.
- Preserve names, units, prices and callback shapes established by supplied
  source. A polished button with an invented remote is a broken feature.
- Use real content lengths and values before judging the layout. A longest
  item name, a zero balance and a large balance reveal defects placeholders hide.
- A one-shot button has no persistent selected meaning. Tabs, toggles and
  selected rows do. Account for all six interaction states without inventing a
  sticky selection for actions that have none; loading is additional state.
- If integration is unavailable, label the deliverable as a UI prototype and
  make its unavailable behavior explicit. Never report a purchase, save or
  executor effect as successful because only the display changed.

## Keep asynchronous work attached to its owner

A view can close, an item can change, or another request can start while a
callback yields. Checking only `Parent` does not cover a hidden or reused view.

Track the view lifetime and the current request. On return, apply a result only
if it still belongs to that view and item. Clear the owning request's pending
state on success and failure; an old completion must not unlock a newer request.
Check both transport success and the response shape proven by the source.

Pending controls must prevent repeat submission and show what is happening.
UI disabling does not provide server validation or purchase idempotency. Do not
automatically retry a purchase or other write after an ambiguous response unless
the source establishes a safe retry contract. A read-only refresh can offer Retry.

## Exercise the behavior that actually exists

Trace each control through **activation → state write → every dependent view**.
A quality choice must update its selected appearance and any summary showing that
choice. One shared render function called after state changes keeps these views
consistent. Check the initial render too: declaring an open function does not
open the panel. Compare the claimed starting state with the actual entry point.
Exercise each distinct choice, toggle twice, close and reopen, then compare all
displayed values with state. Do not count a callback's existence as a test pass.

When Roblox is unavailable but standalone Luau is available, execute the actual
generated file with a small mock of the engine surface it uses. The bundled
`library/tests/stubs.luau` is a starting point, not a complete Roblox emulator.
Extend only missing engine operations; never replace the script's callback or
copy its state logic into a passing test. Trigger its actual connected signals
and assert resulting text, selected state and visibility. Queue tween completion
until after listeners attach. Report mock limitations separately from results.
If no usable runtime exists, report behavior as untested rather than inferred.

Test the applicable rows; do not add features merely to exercise this table.
Use local sample data for view states and a non-production test path for writes.

| Case | Observable result |
|---|---|
| Primary action succeeds | The intended callback runs once; displayed state matches its confirmed result |
| Rapid repeated activation | At most one request is pending per action; the control recovers |
| Request fails or rejects | A meaningful reason appears; the allowed next action works |
| Close, then reopen during a delay | No stale response changes the newly opened view or hides it |
| Select another item during a delay | A result for the old item cannot update the new item's row |
| Empty list and search with no matches | The messages distinguish no owned items from a filter hiding them |
| Long list and longest label | Last row is reachable; labels wrap or truncate intentionally; actions remain visible |
| Drag off and release, or cancel touch | No stuck press or drag; another finger cannot finish the first finger's gesture |
| Keyboard/gamepad navigation | All actions are reachable; focus is visible, stays in a modal, returns to its opener |
| Reopen, respawn, or executor rerun | Behavior matches intended persistence; one UI and one set of active callbacks |
| Unload/destroy | Owned listeners, tweens and tasks stop; captured values are restored where required |

## Inspect the rendered UI

Use the four viewports in `self-review.md`. Also test phone landscape when the
UI supports it and text input with the on-screen keyboard when it has a field.
Inspect the longest label, empty/error content, and an open dropdown or modal,
not only the first screen. Check the final visible touch area after `UIScale`;
a nominal 44 px button scaled down is no longer a 44 px target.

Navigate with touch and gamepad rather than inferring support from event names.
Keep essential text legible when disabled; reasons cannot rely on hover or hue.
Verify focus remains visible on selected controls. With reduced motion enabled,
opening, closing and selection must still reach the same final state.

## Report evidence without upgrading it

Keep three kinds of evidence separate:

1. **Source checks:** exact commands, outputs, unresolved warnings and APIs the
   scanner could not resolve. A score is not a percentage of runtime correctness.
2. **Rendered review:** actual viewports and states inspected, with screenshots
   when the environment supports capture. A mockup is not a Roblox render.
3. **Behavior tests:** action taken and observed result. Code reading is not an
   executed test; a supplied manual test plan is not an observed pass.

When Studio or the executor is unavailable, finish source checks and provide the
smallest relevant manual test. State which visual/runtime checks remain untested.
For a reported regression, reproduce the specific sequence first and preserve
that case with its evidence in the project's existing test or context record.
