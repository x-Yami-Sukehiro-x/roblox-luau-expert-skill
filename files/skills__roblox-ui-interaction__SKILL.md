---
name: roblox-ui-interaction
description: Making every Roblox UI control respond on PC, phone and gamepad - Activated, touch press states, 44 px hit areas, selection and focus, menus versus character input. Use for "the button does nothing" or "can't click on mobile".
---

# Every control, every input

A control works when a player on a mouse, a phone and a controller can each
find it, operate it, and see that it responded. Most broken UI works on one of
the three. Build for all three from the first line, then prove each.

## The contract for one control

| Need | Mouse and keyboard | Touch | Gamepad |
|---|---|---|---|
| act | `Activated` (also Enter) | `Activated` | `Activated` (A button) |
| pressed look | `InputBegan` / `InputEnded` | the same, `UserInputType.Touch` | `SelectionGained` plus A held |
| hover or focus look | `MouseEnter` / `MouseLeave` | none: nothing may depend on it | `SelectionGained` / `SelectionLost` |
| extra information | a tooltip after a delay | a long press (`TouchLongPress`) | the tooltip on selection |
| reach | pointer | a 44 x 44 hit area, clear of the thumbstick and jump button | a selection path from the opening control |
| undo a press | release outside | drag off before lifting | B cancels or closes |

`MouseButton1Click`, `MouseButton1Down` and `Button1Down` never fire on a
phone. `Activated` fires for every input and hands over the `InputObject` that
caused it. `AutoButtonColor = false`, and the six states come from
`../roblox-ui-components/references/component-states.md`.

## Hit area is not the visual

A 24 px icon is a 44 px button: put the icon in a transparent
`ImageButton` or `TextButton` that owns the input, sized 44 x 44 after every
`UIScale`. Rows are buttons across their full width. Two targets closer than
8 px apart get mis-tapped; space them or merge them.

## When a control does not respond

Work down the ladder; each rung is one question with a check. Full detail,
with the fix for each: `references/blocked-input.md`.

1. **Did the handler connect?** A connection made to a template before
   `Clone`, or to a GUI that `ResetOnSpawn` replaced after a death, is gone.
2. **Is it a button?** A `Frame` or `ImageLabel` never fires `Activated`.
3. **Is something on top of it?** A transparent full-screen `Frame` with
   `Active = true`, an invisible `TextButton` scrim left behind, a sibling
   with a higher `ZIndex`, a `ScreenGui` with a higher `DisplayOrder`.
4. **Is it switched off?** `Interactable = false` on it or an ancestor,
   `Visible = false` anywhere up the chain, `GuiState` reading
   `NonInteractable`.
5. **Is the tap outside what is drawn?** A parent with `ClipsDescendants`
   (or a `ScrollingFrame`) stops input outside its rectangle, so the part of
   a button hanging past it does not respond.
6. **Is a gesture winning?** A button inside a `ScrollingFrame` loses taps
   that move a few pixels, because the frame takes them as a scroll.
7. **Is the game taking the input first?** `ContextActionService` bindings at
   a higher priority, or a TextBox that still has focus.

## Menus and the character

Decide, per screen, what happens to the game underneath while it is open:

- **An executor hub or small HUD panel**: the character keeps moving. Only
  the panel's own controls take input.
- **A full menu, shop or dialog**: stop movement and actions while it is
  open. Bind a sink with `ContextActionService:BindActionAtPriority` above
  the default controls for the movement and action inputs, return
  `Enum.ContextActionResult.Sink`, and unbind on close.
- **First person or a locked mouse**: a visible `TextButton` with
  `Modal = true` inside the open menu frees the cursor while the menu is up.

Keyboard shortcuts respect `gameProcessedEvent`: return when it is true, so
typing in chat or a TextBox never fires them. Escape and gamepad B close the
top-most panel and return focus to the control that opened it.

## Gamepad

Opening a menu with a gamepad selects its first control
(`GuiService.SelectedObject`); closing restores the previous selection.
Every control is `Selectable`, the order follows the layout (`SelectionOrder`
where it does not), a modal keeps selection inside itself with
`SelectionGroup`, and the focused control shows a ring that is not clipped
(`../roblox-ui/references/clipping.md`). Details and the focus trap:
`../roblox-ui/references/input-surfaces.md`.

## Proving it

Static checks catch the event and size mistakes:
`node tools/bin/lint-roblox-ui.mjs` (`E-MOUSEONLY`, `W-TOUCH`, `W-STATES`,
`E-AUTOBUTTON`). Behaviour needs the matrix in `references/input-matrix.md`:
fire each control's real signals in the Luau mocks, and walk each input in
Studio's device emulator with a controller or the keyboard's gamepad keys.
Report which rows ran and which were not checked.

| Need | File |
|---|---|
| a control that does not respond, rung by rung | `references/blocked-input.md` |
| the per-input test matrix, in mocks and in Studio | `references/input-matrix.md` |
| input models, gestures, gamepad focus trap, safe areas | `../roblox-ui/references/input-surfaces.md` |
| the six states and how each looks | `../roblox-ui-components/references/component-states.md` |
| long press and selection tooltips | `../roblox-ui-tooltips/SKILL.md` |
| everything on screen on every device | `../roblox-ui-viewport/SKILL.md` |

## Works with

- `roblox-ui-viewport`: controls reachable on every screen size.
- `roblox-ui-components`: state visuals for each input.
- `roblox-ui-tooltips`: long press and selection instead of hover.
- `roblox-studio-mcp`: clicking the real controls in a playtest.
