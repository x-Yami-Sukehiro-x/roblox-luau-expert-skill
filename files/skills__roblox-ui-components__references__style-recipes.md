# Style recipes: what each guide label builds

The visual guide (hosted at <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>,
offline copy `docs/visual-guide/index.html`) shows every option with a code:
**T** toggles, **M** menu movement (opening and closing can differ), **N**
notifications, **O** how the whole UI hides and comes back, **P** press feel,
**S** tab switch, and **W** for the parts of a window. When a user answers
"T2 + M4 + N4", that answer is a contract. This file says exactly what each code
builds and which tested recipe builds it.

The recipes live beside this file in `../assets/`. Each is one self-contained
file with its own `THEME` block, so a single-file LocalScript or executor script
can paste the part it needs above the UI build. Every recipe is run by
`node tools/bin/run-recipe-tests.mjs` against the engine stubs and scores full
marks on the slop, format and UI rubrics.

## Rules for using a recipe

1. **Paste the recipe, do not rewrite it.** Copy the recipe's functions into
   the script unchanged and call them. The label means these numbers: a "T2"
   built as a pill, or an "M3" that bounces three times, is not what the user
   chose. On 23 September 2026 a lighter model that rewrote the recipes instead
   of pasting them shipped a toast slide-in that never moved, a tab underline
   that blinked instead of sliding, a focus ring drawn on the whole panel, and
   error toasts that vanished after three seconds.
2. **Recolour only through `THEME`.** Replace its values with the project's
   palette, or the user's named colour. Keep sizes, timings and state logic.
3. **Keep one owner per animated property.** The recipes already cancel and
   ticket their own tweens; do not add a second tween on the same property.
4. **Reduced motion is built in.** Each recipe reads
   `GuiService.ReducedMotionEnabled` and keeps the final state without travel.
5. **Prove the wiring on the final file.** A recipe proves itself, not your
   adaptation. After adapting, run the callbacks against the real script
   (`../../roblox-ui/references/functional-proof.md`).

If the user gave no answer and asked you to decide, use **T1 + M1 + N1 + O1 +
P1 + S1**; for an executor hub use **N4** instead of N1. Say which you used,
once.

## Toggles — `../assets/toggles.luau`

`createToggle(parent, label, style, initial, onChanged)` returns
`{ row, set, get, setEnabled, destroy }`. Every row is 44 px tall so the whole
row is the touch target, and each style shows state by shape or words as well
as colour.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| T1 | "little sliding pill", "iPhone switch" | sliding switch | track 44×24 pill, knob 18, knob x 3 → 23, 0.12 s Quad Out |
| T2 | "boxy switch", "square slider" | square switch | as T1, track radius 6, knob radius 4 |
| T3 | "checkbox", "square with a tick" | tick box | box 22×22 radius 6, 2 px edge, tick image 16 grows 0.8 → 1 |
| T4 | "two buttons", "Off / On buttons" | segmented choice | group 112×36, indicator slides behind the chosen word; each half is its own button |
| T5 | "button that lights up", "stays pressed" | lit row | whole row takes the dim accent, edge turns accent, `ON` / `OFF` word |
| T6 | "eye icon", "icon that switches" | icon toggle | 32 px badge, 16 px eye / eye-off image, badge fills with accent |
| T7 | "tick in the circle", "switch with a check" | knob icon switch | T1 track; a 12 px tick (on) or cross (off) image inside the knob |
| T8 | "switch with words in it", "ON OFF slider" | word switch | track 56×24 pill, `ON` / `OFF` inside on the side the knob left, knob x 3 → 35 |
| T9 | "little light", "dot that turns on" | status light | 8 px dot plus `ON` / `OFF` word at the end of the row |
| T10 | "round tick", "circle checkbox" | round tick | T3 in a 22 px circle, tick 14 grows 0.6 → 1 |

Pressing the half of T4 that is already chosen leaves the value alone. T5 is
the only style where the row colour carries state; its word does too.

## Menu movement — `../assets/menus.luau`

`createPresenter(panel, openStyle, { closeStyle = ..., rows = ... })` takes the
window's outermost `CanvasGroup` and returns `{ open, close, isOpen, destroy }`.
Opening and closing are picked separately: "open with M3, close with M1" is
`createPresenter(panel, "M3", { closeStyle = "M1" })`. Entrances use Out easing;
exits use In easing and travel less.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| M0 | "just appear", "no animation" | instant | `Visible` only |
| M1 | "fade in", "gently appears" | fade | `GroupTransparency` 1 → 0, 0.20 s Cubic Out; out 0.15 s Cubic In |
| M2 | "slides up a little" | short rise | starts 12 px low with the fade; leaves 8 px low |
| M3 | "little pop" | gentle pop | `UIScale` 0.96 → 1 with the fade; leaves at 0.98 |
| M4 | "slides in from the side" | side drawer | from its own width + 24 px off the left, 0.28 s Out; out 0.20 s In; opaque |
| M5 | "opens out of the button" | grow from origin | `AnchorPoint` on the side facing the launcher; `UIScale` 0.9 → 1 with the fade; leaves at 0.95 |
| M6 | "bouncy but not cartoony" | settle | `UIScale` 0.94 → 1, 0.32 s Back Out: one small overshoot, no repeat |
| M7 | "slides in from the right" | right drawer | M4 mirrored: from its own width + 24 px off the right |
| M8 | "comes up from the bottom", "like a phone sheet" | bottom sheet | from its own height + 24 px below, 0.28 s Out; out 0.20 s In; opaque |
| M9 | "drops down from the top" | top drop | M8 from above |
| M10 | "zooms in toward me" | zoom settle | `UIScale` 1.06 → 1 with the fade; leaves at 1.03 |
| M11 | "bounces up a little" | springy rise | 24 px rise on 0.32 s Back Out, one overshoot; leaves 8 px low |
| M12 | "the rows come in one by one" | cascade | M2-style 8 px rise, then each row (a `CanvasGroup` in `rows`) fades in 0.03 s apart, 0.25 s cap |

Every style needs a way back: when the window closes, a launcher button (W20)
stays on screen. A keybind alone strands a phone player. Reopening during a
close continues from where the panel is, and a stale close can never hide the
reopened panel. A panel dragged while open keeps its new
position. With reduced motion every style becomes a 0.08 s fade. A `UIScale`
used for screen-size scaling belongs on a parent frame, not on the panel.

## Notifications — `../assets/toasts.luau` and `../assets/notices.luau`

Every notification shares the panel's surface entry: the same fill, edge and
10 px radius. Each carries an icon image as well as a hue, holds at least
1.5 s from arrival, and stays readable for 3 to 8 s by word count. Errors stay
until dismissed and get a 44 px dismiss button with a 16 px mark.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| N1 | "message at the bottom" | bottom toast | `createNotifier(screen, "N1")`: bottom centre, stacks upward, arrives from 12 px below |
| N2 | "message near the top" | top notice | `createNotifier(screen, "N2")`: top centre, stacks downward, arrives from 8 px above |
| N3 | "next to what I changed" | inline message | `createInlineMessage(parent, order)`: a reserved 20 px row, so nothing below moves |
| N4 | "popups stacked in the corner" | corner stack | `createNotifier(screen, "N4")`: bottom right, arrives from 24 px right, 2 px time-left bar |
| N5 | "bar across the top" | banner | `createBanner(screen)`: stays while a condition lasts, such as reconnecting |
| N6 | "popup in the middle", "are you sure?" | alert | `confirmAlert(screen, spec, onChoice)`: dims the game, buttons name the action |
| N7 | "popups in the top corner" | top-right stack | `createNotifier(screen, "N7")`: N4 anchored top right, stacks downward |
| N8 | "small status at the top", "one line that swaps" | compact status | `createCapsule(screen)`: one 36 px bar under the top bar; a new message replaces the old |
| N9 | "loading, then done" | progress toast | `notifier.progress(message)` spins a loading icon until `:done(result, severity)`; a failed result stays with a dismiss button |
| N10 | "popup with an undo button" | action toast | `notifier.action(message, "Undo", onUndo)`: holds at least 6 s, the button names the action and runs it once |

The stacked styles (N1, N2, N4) show three at a time, queue up to ten, collapse
a repeated `key` into `×2`, pause while hovered and reflow with a spring when a
middle toast leaves. Put the `ScreenGui` on `ScreenInsets = CoreUISafeInsets`
and `ResetOnSpawn = false`. N6 is only for something the player must answer:
its dim layer counts a tap outside as Cancel, and gamepad focus starts on the
safe choice.

## Hiding and bringing back the whole UI — `../assets/windows.luau`

`createWindow({ panel, launcher, header, body, opener }, style)` returns
`{ show, hide, toggle, isShown, destroy }`; wire the close or minimise button
and the keybind to `hide` / `toggle`. Every style leaves a way back on screen,
because a keybind alone strands a phone player.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| O1 | "close it, button to reopen" | close to launcher | runs the chosen M close through `opener`, then shows the launcher; the launcher opens it again |
| O2 | "shrink into the button", "minimise" | minimise into launcher | `UIScale` to 0.2 while travelling to the launcher's centre, 0.24 s In; grows back 0.28 s Out |
| O3 | "fold up to the title bar" | collapse to header | body fades, panel height folds to header + 24 px; unfolds on the same button |
| O4 | "tab on the side to pull it back" | edge pull tab | slides off the left edge; a 44×64 tab with a chevron image brings it back |
| O5 | "loading screen before the hub" | intro card | `playIntro(screen, title, onDone)`: 28 px title and a 2 px accent line that grows to 120 px, 0.6 s hold, returns `skip` |

## Press feel — `../assets/press-and-tabs.luau`

`attachPress(button, style)` returns a cleanup function.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| P1 | "changes colour when I press" | colour shift | hover lighter over 0.12 s, press darker over 0.08 s |
| P2 | "pushes in" | press-in | P1 plus `UIScale` 0.97 while held |
| P3 | "lifts when I hover" | lift | `UIScale` 1.02 and a visible edge on hover, 0.98 on press |

## Tab switch — `../assets/press-and-tabs.luau`

`createTabs(parent, names, style, onSelect)` returns `{ select, selected,
destroy }`. The selected tab persists; focus and hover never change it.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| S1 | "a line under the tab" | underline slide | 2 px accent marker slides to the chosen tab, 0.20 s Cubic Out |
| S2 | "a pill behind the tab" | pill slide | full-height rounded marker slides behind the chosen tab |
| S3 | "just highlight it" | highlight only | colour and weight change, nothing travels |

## Window parts — the W codes

The guide's "Point at it" diagram numbers the parts of a hub window so a user
can say "make W3 bigger" instead of hunting for the word. The names and the
everyday words for each are in
`../../roblox-request-intake/references/ui-words.md`.
