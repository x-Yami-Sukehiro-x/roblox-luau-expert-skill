# A control that does not respond

Every rung is a question, the check that answers it, and the fix. Stop at the
first rung that answers yes. Asking the user for one observation per rung
beats re-sending the script with a guess.

## 1. The handler never connected, or connected to something else

| Case | Check | Fix |
|---|---|---|
| connected to a template, then cloned | the connect line runs before `:Clone()` | connect each clone after creating it; `Clone` copies properties and children, not connections |
| the GUI was rebuilt after a death | `ScreenGui.ResetOnSpawn` is true; it stops working after the first respawn | `ResetOnSpawn = false` on any GUI a script builds or keeps references into |
| the script is not running | nothing it prints appears in Output; a LocalScript placed where it never runs, such as `Workspace` or `ServerStorage` | `StarterPlayerScripts` for LocalScripts that build UI |
| two copies of the GUI | an executor script rerun without unloading; a second GUI sits on the first | the rerun unloads the previous session first (`roblox-executor/references/technique/lifecycle.md`) |
| the connection was cleaned up | a Trove or unload ran early | check what calls `Destroy` or `Disconnect`, and when |

## 2. It is not a button

`Activated` exists on `GuiButton` only: `TextButton` and `ImageButton`. A
`Frame`, `TextLabel` or `ImageLabel` with a click handler never fires. Make
the clickable area a button, with the visuals inside it.

## 3. Something is on top of it

Input goes to the top-most element under the pointer that takes input.

| On top | How it takes input | Fix |
|---|---|---|
| a transparent `Frame` covering the screen or panel | `Active = true`, or it is an invisible `TextButton` | `Visible = false` whenever the overlay is not in use, not `BackgroundTransparency = 1` |
| a dimming scrim left after closing a modal | the scrim is a button that was faded out, not hidden | hide or destroy the scrim when the modal closes |
| a sibling with a higher `ZIndex` | overlapping boxes, even where the sibling draws nothing | move it, shrink it, or lower its `ZIndex` |
| another `ScreenGui` with a higher `DisplayOrder` | a full-screen frame in the other GUI | the same fixes, in that GUI |
| a tooltip or toast | it sits over the control while shown | tooltips and toasts do not take input (`Active = false`, and labels rather than buttons) |

Two probes find the element in the way, without guessing:

```lua
-- lint: fragment
local hits = playerGui:GetGuiObjectsAtPosition(x, y)
for _, hit in hits do
	print(hit:GetFullName(), hit.ZIndex, hit.Active)
end
```

`BasePlayerGui:GetGuiObjectsAtPosition` lists every GUI object under a screen
point; anything in that list besides the control and its own children is a
candidate for rung 3. `GuiObject.GuiState` reads `Idle`, `Hover`, `Press` or
`NonInteractable`; a control that never leaves `Idle` under the pointer is not
receiving the hover at all.

## 4. It is switched off

- `Interactable = false` on the control or any ancestor stops every input
  below it. It is the right way to disable a control, and the usual reason a
  control that should be enabled is not.
- `Visible = false` anywhere up the chain hides it and stops input.
- A disabled state built by greying the colours only, with no
  `Interactable = false`, looks disabled and still fires. The reverse, a
  control left non-interactable after the reason went away, looks enabled
  and does nothing.

## 5. The press lands outside what can take it

An ancestor with `ClipsDescendants = true`, a `ScrollingFrame` or a
`CanvasGroup` stops input outside its rectangle. The part of a button that
hangs past the edge is drawn nowhere and receives nothing. A `UICorner`
clips its own element's input to the rounded shape, so the very corner of a
rounded button does not respond; keep hit areas large enough that it does
not matter.

## 6. A gesture takes it

- **Scroll versus tap.** In a `ScrollingFrame`, a touch that moves before
  lifting becomes a scroll and the button's `Activated` does not fire. Rows
  must be tall enough to tap without moving (44 px), and swipe actions on a
  row need their own handling.
- **Drag versus tap.** A draggable window's title bar is also its close
  button's parent; a drag detector or `InputBegan` drag handler on the bar
  can swallow the close tap. Keep the close button outside the drag region,
  or start a drag only after the pointer moves several pixels.
- **Long press versus tap.** A long press that opens a tooltip must not also
  activate the control on release.

## 7. The game takes the input first

- **`ContextActionService`** bindings at a higher priority sink the key or
  button before the UI's handler sees it. Check with the game's actions
  unbound, or bind the UI's action at a higher priority while it is open.
- **A focused TextBox** takes every key. Keyboard shortcuts that fire while
  a field is focused are the opposite bug: check `gameProcessedEvent`.
- **The first-person mouse lock** keeps the cursor centred, so nothing can
  be clicked. A visible `TextButton` with `Modal = true` frees it while the
  menu is open.

## Executor interfaces

A hub parented to `gethui()` competes with the game's own GUIs. A game's
full-screen loading or menu frame with a higher `DisplayOrder` covers the hub
and takes its clicks: set the hub's `DisplayOrder` high, and check rung 3
with `GetGuiObjectsAtPosition` on the game's `PlayerGui` as well as on the
hub's container.
