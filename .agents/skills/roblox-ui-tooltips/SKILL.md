---
name: roblox-ui-tooltips
description: Roblox tooltips and helper text - hover and long-press tips, locked reasons, slider readouts (H codes). Use for hover text, why is it locked.
---

# Tooltips and slider values

A tooltip is the most over-used and least reachable piece of Roblox UI: a
phone has no hover, a gamepad has no pointer, and a `ScrollingFrame` clips
anything drawn inside it. Decide first whether the words belong in a tooltip
at all.

Each H code has a tested implementation in
`../roblox-ui-components/assets/tooltips.luau`, specified in
`../roblox-ui-components/references/style-recipes.md`. Paste the recipe and
change only its `THEME`; the picker at
<https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/> shows every
code working.

| Need | File |
|---|---|
| placement, flipping, timing, touch and gamepad, layering | `references/tooltip-patterns.md` |
| slider numbers: which readout, formatting, units, typing a value | `references/slider-values.md` |

---

## Which one

| The words are | Use | Code |
|---|---|---|
| a name for an icon-only button | hover tooltip | H1, H2 |
| a slider's current number | drag value, value on the knob, or ends and value | H3, H4, H5 |
| something the player needs before choosing | an info button | H6 |
| a feature with a hotkey | titled tooltip | H7 |
| about a point on a map or chart | follows the pointer | H8 |
| why a control is locked | locked reason | H9 |
| a preview the player asks for deliberately | press and hold | H10 |
| a rule for a text field, or its error | helper line | H11 |
| a one-time pointer at something new | coach mark | H12 |

**Anything the player must know to play is never a hover.** It is a helper
line (H11), an info button (H6) or the label itself. A tooltip that repeats
the button's own label is noise: delete it.

If the user has not picked, use **H1** for icon-only buttons and **H3** for
sliders, and say so once.

---

## Rules every tooltip follows

1. **Reachable three ways.** Mouse hover after a rest, a 0.5 s long press on
   touch, and gamepad selection (`SelectionGained`). A tap on a phone fires a
   fake `MouseEnter`; ignore it when `UserInputService:GetLastInputType()` is
   `Touch` so a tap does not open a tooltip and trigger the button at once.
2. **Delay in, instant out.** Show after 0.4 s at rest so passing over a row of
   buttons shows nothing; hide the moment the pointer leaves.
3. **Its own layer.** Draw in a separate `ScreenGui` above the host
   (`DisplayOrder` + 2), positioned from the target's `AbsolutePosition`.
   Inside a `ScrollingFrame` or a `CanvasGroup` it is clipped.
4. **Never off screen.** 8 px from the control, below by default, flipped above
   when there is no room, and clamped 8 px from each side edge.
5. **One at a time.** Leaving or losing selection hides a tooltip, so moving
   to the next control closes the last one.
6. **Short.** About twelve words, in the game's vocabulary: "Collects drops
   within 30 studs", not "This toggle enables the auto collect feature".
7. **The project's tokens.** The recipe's bubble is the darkest neutral with
   the overlay edge and the 6 px control radius, so it reads above any panel;
   recolour it through `THEME` only. A tooltip that looks like a different app
   reads as a bug.
8. **Teardown.** Every tooltip returns `destroy`; the hub's unload calls it.

---

## Slider values in one screen

- **H3** while dragging only: the default. The number is where the eye is.
- **H4** always on the knob: when the exact value matters at a glance
  (field of view, volume).
- **H5** ends and value: when the range itself is information (a 16 to 100
  walk speed).

Format with the unit the game uses (`"32 speed"`, `"80%"`, `"1.5x"`), round to
the slider's step, and let the player tap the number to type an exact value
when the range is wide. Details: `references/slider-values.md`.

---

## Checks before it ships

- Run the callbacks on the final file: hover, long press, `SelectionGained`,
  a tap on the button, and `destroy` (`../roblox-ui/references/functional-proof.md`).
- Resize to 390 × 844: the bubble stays on screen at every edge.
- `node tools/bin/check-file.mjs <file>` runs every file-level gate at once.

## Works with

- `roblox-ui-interaction`: touch and gamepad access for every hint.
- `roblox-ui-components`: sliders and controls the readouts attach to.
- `roblox-ui-viewport`: flipping at screen edges.
