# Style recipes: what each guide label builds

The visual guide (hosted at <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>,
offline copy `docs/visual-guide/index.html`) shows every option with a code:
**T** toggles, **C** checkboxes and choice groups, **D** dropdowns (including
search fields), **M** menu movement (opening and closing can differ), **N**
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

If the user gave no answer and asked you to decide, use **T1 + C1 + D1 + M1 +
N1 + O1 + P1 + S1**; for an executor hub use **N4** instead of N1, **D2** for a
list longer than about eight options and **D10** to pick a player. Say which
you used, once.

## Toggles — `../assets/toggles.luau`

`createToggle(parent, label, style, initial, onChanged, details?)` returns
`{ row, set, get, setEnabled, destroy }`. `details` is
`{ description = "...", icon = "rbxassetid://..." }`, read by T19 and T20. Every row is 44 px tall so the whole
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
| T11 | "thin line with a big knob", "Android switch" | thin rail switch | rail 36×14, knob 20 overhangs it and slides |
| T12 | "outline switch", "empty until on" | outline switch | 44×24 outlined track; a 14 px muted knob grows to 18 and fills with accent |
| T13 | "big switch" | big switch | track 56×32, knob 26, for a row that is the whole screen's point |
| T14 | "chip that lights up", "tag with a tick" | tick chip | the row is a pill; on shows a 16 px tick and the accent fill |
| T15 | "power button" | power button | 32 px round power icon button and an `ON` / `OFF` word |
| T16 | "stretchy switch", "knob stretches" | stretchy switch | T1 whose knob stretches to 26×18 mid-travel and back, 0.06 s |
| T17 | "tick and cross in the track" | icons in the track | track 56×28 with a 14 px tick and cross; the knob covers the one that is off |
| T18 | "key you push", "keyboard key" | push key | 52×36 key cap on a base; on sinks 4 px and reads `ON` |
| T19 | "switch with a description" | described row | 56 px row: label and a 12 px description on the left, T1 on the right |
| T20 | "icon, name and switch" | icon row switch | 16 px icon before the label (from `details.icon`), T1 on the right |

Pressing the half of T4 that is already chosen leaves the value alone. T5 and
T14 are the only styles where the row colour carries state; the word or tick
does too.

## Checkboxes and choice groups — `../assets/checkboxes.luau`

One box: `createCheckbox(parent, label, style, initial, onChanged, details?)`
returns `{ row, set, get, setEnabled, destroy }`. A group:
`createCheckGroup(parent, names, style, initial, onChanged, details?)` returns
`{ frame, set, selected, destroy }` and calls `onChanged(selectedNames)`.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| C1 | "tick that draws in" | draw-in tick | 22 px box; the tick reveals left to right as the box fills |
| C2 | "outline tick", "no fill" | outline tick | box stays outlined; the tick and edge take the accent |
| C3 | "box on the right" | box on the right | label left, box right, like a settings row |
| C4 | "select all" | select-all group | header box shows a dash for some, a tick for all; rows below |
| C5 | "cross it off", "to-do list" | to-do line | ticking strikes the label through and mutes it |
| C6 | "tick pops" | pop tick | the tick pops 0.6 → 1 with one small overshoot |
| C7 | "card you tick", "option with a description" | card choice | a raised card with the label and `details.description`, edge turns accent |
| C8 | "radio buttons", "pick one" | radio group | round markers; exactly one chosen; the only choice cannot be cleared |
| C9 | "chips", "tags to pick" | chip group | 44 px pills that wrap onto more lines |
| C10 | "tiles with icons" | icon tiles | 88×88 tiles, icon from `details.icons[name]` (default package), tick badge |

## Dropdowns and search fields — `../assets/dropdowns.luau`

`createDropdown(parent, style, spec)` with `spec = { label, options, chosen?,
onChanged, host? }` returns `{ root, get, set, setOptions, open, close, destroy
}`. An option is a string or `{ text, display?, detail?, icon?, image?, group?,
colour? }`. The list opens in its own `ScreenGui` one `DisplayOrder` above the
host, so no `ScrollingFrame` clips it; a tap outside closes it. Lists show five
rows and scroll; an empty list says "No matches" or "Nothing to choose yet".

| Code | People say | What it is | Exact build |
|---|---|---|---|
| D1 | "normal dropdown" | classic | field shows the choice; list below, or above when there is no room |
| D2 | "dropdown you can type in" | search dropdown | the field is a text box; typing filters, Enter picks the first match |
| D3 | "pick several" | multi-select | ticks in the list; the field says "3 chosen" |
| D4 | "pick several, show them" | multi with chips | chosen options become removable chips in the field |
| D5 | "search bar" | search bar | a search field whose results list appears while typing |
| D6 | "opens in place", "accordion" | inline list | the list pushes content down instead of floating |
| D7 | "arrows either side" | cycle | previous and next arrows step through the options, wrapping |
| D8 | "grouped list" | grouped | options under headings from `group` |
| D9 | "list with icons" | icon list | a 16 px icon from `icon` before each option and in the field |
| D10 | "pick a player" | player picker | every other player with a headshot; updates as they join and leave |
| D11 | "command palette", "big search box" | palette | a centred search panel; type to filter, Enter runs the first match |
| D12 | "colour picker", "swatches" | swatches | options with `colour` shown as swatches |


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
| M13 | "slides in a little from the left" | slide from left | 24 px from the left with the fade; leaves 12 px left |
| M14 | "slides in a little from the right" | slide from right | M13 mirrored |
| M15 | "drops in" | drop in | 12 px from above with the fade; leaves 8 px up |
| M16 | "swings in", "tilts in" | swing | rotates from −4° with the M3 pop and settles; leaves at 2° |
| M17 | "rolls down", "unrolls" | roll down | height unfolds from the top edge, 0.24 s Out; folds 0.18 s In |
| M18 | "stretches open sideways" | stretch open | width unfolds from the centre, same timing as M17 |
| M19 | "dims the game and pops" | dim and pop | M3 plus a scrim at 50 % behind it; needs `scrim` in the options |
| M20 | "rises and grows" | rise and grow | 24 px rise with `UIScale` 0.9 → 1 on the drawer timing |
| M21 | "drops and bounces" | drop and bounce | 40 px drop on Bounce Out, 0.45 s |
| M22 | "jelly", "wobbly pop" | jelly pop | `UIScale` 0.8 → 1 on Elastic Out, 0.5 s |
| M23 | "snappy", "quick" | snap | 0.10 s in, 0.08 s out, a tiny scale |
| M24 | "slow fade" | slow fade | fade only, 0.35 s in, 0.25 s out, Sine |

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
| N11 | "popups bottom left" | bottom-left stack | `createNotifier(screen, "N11")`: N4 anchored bottom left |
| N12 | "small pill message" | pill toast | `createNotifier(screen, "N12")`: a one-line pill, top centre |
| N13 | "title and message" | titled toast | `createNotifier(screen, "N13")`, `push(message, severity, key, title)` |
| N14 | "coloured strip on the side" | coloured edge | `createNotifier(screen, "N14")`: a 4 px severity strip on the left edge |
| N15 | "achievement", "unlocked!" | achievement card | `announcements.showAchievement(screen, title, detail, icon?)`: trophy card with a shine sweep, holds 4 s |
| N16 | "big text in the middle" | announcer | `announcements.createAnnouncer(screen).show(message)`: 28 px outlined text, centre |
| N17 | "countdown" | countdown toast | `notifier.countdown(message, seconds, onZero?)`: warning style, a draining time bar, does not pause on hover |
| N18 | "snackbar" | snackbar | `announcements.createSnackbar(screen)`: one bar at the bottom, 4 s, 6 s with an action |
| N19 | "cards stacked on each other" | stacked cards | `createNotifier(screen, "N19")`: a deck that peeks 8 px and spreads on hover |
| N20 | "activity feed", "kill feed" | feed | `announcements.createFeed(screen).push(text, severity?)`: up to 6 lines, each fades after 4 s |

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
| O6 | "floating bubble", "button I can move" | floating bubble | the window shrinks into a draggable round bubble (`bubbleIcon`); a tap, not a drag, opens it |
| O7 | "tab on the right side" | right edge tab | O4 on the right edge |
| O8 | "pull-down tab at the top" | top tab | slides up off the top; a tab hangs down to pull it back |
| O9 | "small pill with the name" | title pill | the window becomes a pill showing `title`; tap to restore |
| O10 | "tells me the key to open it" | key reminder | a chip "Press `keyName` to open" that collapses to the key after 5 s |
| O11 | "asks before closing" | ask first | close asks Hide, Unload script or Cancel; unload calls `onUnload` |
| O12 | "goodbye screen" | outro card | `playOutro(screen, title, onDone)`: the O5 card on the way out, 0.8 s hold |

## Press feel — `../assets/press-and-tabs.luau`

`attachPress(button, style, onHold?)` returns a cleanup function. P4, P8, P9,
P10 and P11 draw inside the button, so they need a button with no
`UIListLayout`.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| P1 | "changes colour when I press" | colour shift | hover lighter over 0.12 s, press darker over 0.08 s |
| P2 | "pushes in" | press-in | P1 plus `UIScale` 0.97 while held |
| P3 | "lifts when I hover" | lift | `UIScale` 1.02 and a visible edge on hover, 0.98 on press |
| P4 | "ripple" | ripple | a circle spreads from the press point and fades, clipped by a `CanvasGroup` |
| P5 | "glows at the edge" | glow edge | a 2 px accent edge lights on hover and takes the focus colour on press |
| P6 | "fills up on hover" | fill sweep | a hard-edged gradient sweeps the dim accent across the fill on hover |
| P7 | "squishes" | squish | `UIScale` 0.94 on press, springs back past 1 once |
| P8 | "underline on hover" | underline | a 2 px line grows from the centre under the label |
| P9 | "shine across it" | shine | a tilted light band sweeps across once on hover |
| P10 | "hold to confirm" | hold | holding fills the button over 1 s, then calls `onHold`; release early cancels |
| P11 | "arrow moves" | arrow nudge | a 16 px arrow at the right edge nudges 4 px right on hover |
| P12 | "pops when clicked" | click pop | a quick 1.05 pop and an accent edge flash on click |

## Tab switch — `../assets/press-and-tabs.luau`

`createTabs(parent, names, style, onSelect, options?)` returns `{ select,
selected, destroy }`. `options = { icons = { [name] = id }, pages = { [name] =
CanvasGroup } }`: S6 and S7 read `icons`; S9 and S10 turn `pages`. The selected tab persists; focus and hover never change it.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| S1 | "a line under the tab" | underline slide | 2 px accent marker slides to the chosen tab, 0.20 s Cubic Out |
| S2 | "a pill behind the tab" | pill slide | full-height rounded marker slides behind the chosen tab |
| S3 | "just highlight it" | highlight only | colour and weight change, nothing travels |
| S4 | "side menu with a bar" | side list with bar | vertical tabs; a 3 px accent bar slides beside the chosen one |
| S5 | "side menu with a pill" | side list with pill | vertical tabs; a pill slides behind the chosen one |
| S6 | "tabs with icons" | icon tabs | icon above or beside each name, S1 marker |
| S7 | "icons only down the side" | icon rail | vertical icon buttons with a pill behind the chosen one; name on hover, computer only |
| S8 | "tabs in a box", "segmented" | segmented | tabs in a sunken track; the chosen one is raised |
| S9 | "pages slide" | page slide | S1 underline, and the page slides in from the tab's side |
| S10 | "pages fade" | page fade | S1 underline, and the page cross-fades |
| S11 | "dot under the tab" | dot marker | a 6 px dot slides under the chosen tab |
| S12 | "tabs scroll sideways" | scrolling tabs | a scrolling strip with a pill marker that scrolls the chosen tab into view |

## Window parts — the W codes

The guide's "Point at it" diagram numbers the parts of a hub window so a user
can say "make W3 bigger" instead of hunting for the word. The names and the
everyday words for each are in
`../../roblox-request-intake/references/ui-words.md`.
