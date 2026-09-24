<!-- GENERATED FILE - do not edit.
     Source: .claude/skills/ (source paths below)
     Rebuild: node tools/bin/build-portable.mjs
     Verify:  node tools/bin/build-portable.mjs --check -->

# Style pack

Read this before building or restyling UI. It holds the style picker question, the everyday words users say, what each picked code (T1-T30, C1-C20, D1-D22, M0-M36, N1-N30, O1-O20, P1-P22, S1-S22, H1-H12) builds, and the tested recipe for every code in full. Recolour a recipe only through its THEME block.

## Source: .claude/skills/roblox-request-intake/references/visual-choices.md

# Ask with examples, not design vocabulary

For new UI or a requested visual redesign, offer one grouped preference question
when toggle, motion or notification styles are unresolved. Do not ask again if
the user already chose, supplied a reference, asked you to decide, or wants an
existing interface matched. A bug fix does not need a style questionnaire.

## The guide and its link

The guide is the **Roblox UI style picker**: playable, labeled examples of
thirty toggles (T1–T30), twenty checkboxes and choice groups (C1–C20),
twenty-two dropdowns and search fields (D1–D22), thirty-seven menu movements
(M0–M36) picked separately for opening and closing, thirty notification styles
(N1–N30), twenty ways to hide and bring back the whole UI (O1–O20), twenty-two
button feels (P1–P22), twenty-two tab switches (S1–S22), twelve tooltips and
slider values (H1–H12) and a window diagram that numbers its parts (W1–W22). A second page, the **UI designer**
(<https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/designer.html>),
lets the user lay out a whole screen and copy it; build that export with
`../../roblox-ui/references/design-spec.md`. The user picks,
presses **Copy my picks**, and pastes a summary such as
`Opening: M3 — Gentle pop`.

- **Hosted link:** <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>. Use this
  exact URL. It is a public GitHub Pages site that anyone can open, rebuilt
  from `docs/visual-guide/index.html` on every push.
- **Offline copy:** `docs/visual-guide/index.html` in this repository, the GPT
  knowledge file `roblox-ui-style-picker.html`, and the plugin's
  `skills/roblox-request-intake/assets/roblox-ui-style-picker.html`. Offer it
  when the user says the hosted link does not open or asks for the file. In a
  GPT, find the knowledge file under `/mnt/data/` with Code Interpreter (or
  extract it from the ZIP), verify it exists, and link the real attachment:
  "Download and open this in your browser". Elsewhere, attach or give the path.
- Never invent another URL, and never claim a private page is public.
- If neither link is available, describe the options in plain words below; do
  not pretend the user saw an animation, and do not stall unrelated work.

## The question

Ask once, in one message, with the link first:

> Before I build it: open the style picker (link) and pick the toggle, how the
> menu opens and closes, and the notification you like — then paste your picks
> here. Or just describe it in your own words, or say "choose for you". My
> suggestion is **T1 + M1 + N1 + O1** (for a script hub, **N4** for
> notifications). If you'd rather arrange the whole screen yourself, use the UI
> designer and paste what it copies.

**The question is the final reply of the turn**, with the hosted link written
out in it. Hosts such as ChatGPT fold progress notes away, so a link placed in
an early note and followed by "checking the guidance…" is a link the user never
sees. Stop there: build nothing until they answer or say "choose for you".
Ask through the host's question tool where available. Source inspection and
the task contract can happen in the same turn, before the question. If the
preference is optional and no answer arrives, use the stated default and never
claim it was the user's choice. Record picks in `PROJECT_CONTEXT.md` or the
portable context record, and carry them into every later edit of that UI.

## Reading the answer

Each code has one exact build in
`../../roblox-ui-components/references/style-recipes.md`, with a tested recipe
in `../../roblox-ui-components/assets/`. Build from the recipe; recolour only
through its `THEME` block.

Users also answer in their own words. Map them, say the mapping back in one
clause, and ask only if two readings produce different work:

| They say | Code |
|---|---|
| little sliding pill, iPhone switch | T1 |
| boxy / square switch | T2 |
| checkbox, square with a tick | T3 |
| two buttons, off and on side by side | T4 |
| button that lights up, stays pressed | T5 |
| eye icon, icon that switches | T6 |
| switch with a tick in the circle | T7 |
| switch with ON / OFF written in it | T8 |
| little light that turns on | T9 |
| round tick, circle checkbox | T10 |
| thin line with a big knob, Android switch | T11 |
| empty outline switch that fills when on | T12 |
| big switch | T13 |
| chip or tag that lights up with a tick | T14 |
| power button | T15 |
| switch whose knob stretches | T16 |
| tick and cross inside the switch | T17 |
| keyboard key you push down | T18 |
| switch with a line of description under the name | T19 |
| icon, name, then the switch | T20 |
| switch that fills with colour | T21 |
| Off and On written either side | T22 |
| switch that glows, neon | T23 |
| up and down like a light switch | T24 |
| dot inside a circle | T25 |
| stripe on the side lights up | T26 |
| I and O rocker, power strip switch | T27 |
| small ON / OFF pill | T28 |
| switch that shows its hotkey | T29 |
| small or tiny switch | T30 |
| tick that draws itself in | C1 |
| outline tick, box stays empty | C2 |
| checkbox on the right side | C3 |
| select all box above a list | C4 |
| crossed off like a to-do list | C5 |
| tick that pops in | C6 |
| cards you tick, with a description | C7 |
| radio buttons, pick only one | C8 |
| chips or tags you pick | C9 |
| tiles with icons you pick | C10 |
| just a tick at the end, no box | C11 |
| checkbox with a number | C12 |
| red X box, ignore list | C13 |
| big checkbox, easy to tap | C14 |
| quest list with a progress bar | C15 |
| buttons stuck together, pick several | C16 |
| star rating | C17 |
| colour dots or circles | C18 |
| S M L size buttons | C19 |
| pick one card with details | C20 |
| normal dropdown | D1 |
| dropdown you can type in to search | D2 |
| pick several from a list | D3 |
| pick several, shown as little tags | D4 |
| search bar with results under it | D5 |
| list that opens in place, pushes things down | D6 |
| arrows either side to cycle | D7 |
| list with headings | D8 |
| list with icons | D9 |
| pick a player, with their picture | D10 |
| big search box in the middle, command palette | D11 |
| colour picker, colour swatches | D12 |
| list with a description under each | D13 |
| recent picks at the top | D14 |
| list that opens upward | D15 |
| list that slides up from the bottom, phone style | D16 |
| finishes the word as I type, Tab to complete | D17 |
| grid of tiles instead of a list | D18 |
| button with a little arrow to change it | D19 |
| pick several then press Apply | D20 |
| menu inside a menu, folders | D21 |
| add my own option | D22 |
| no animation, just appear | M0 |
| fade, gently appears | M1 |
| slides up a little | M2 |
| little pop, zooms in a bit | M3 |
| slides in from the side | M4 |
| opens out of the button | M5 |
| bouncy, springy | M6 |
| slides in from the right | M7 |
| comes up from the bottom, phone sheet | M8 |
| drops down from the top | M9 |
| zooms in toward me | M10 |
| bounces up a little | M11 |
| rows come in one by one | M12 |
| slides in a little from the left | M13 |
| slides in a little from the right | M14 |
| drops in a little | M15 |
| swings or tilts in | M16 |
| rolls down, unrolls | M17 |
| stretches open sideways | M18 |
| darkens the game and pops | M19 |
| rises and grows | M20 |
| drops and bounces | M21 |
| jelly, wobbly | M22 |
| snappy, instant but smooth | M23 |
| slow fade | M24 |
| spins in, twirls | M25 |
| slides in from the corner, diagonal | M26 |
| opens like a curtain from the left | M27 |
| starts as a circle and grows | M28 |
| bounces up from below | M29 |
| slides in and wobbles | M30 |
| zooms from far away | M31 |
| drops in tilted and straightens | M32 |
| each row pops in | M33 |
| smooth long glide | M34 |
| pops and pulses, heartbeat | M35 |
| shrinks away into the middle | M36 |
| message at the bottom | N1 |
| message near the top | N2 |
| next to what I changed | N3 |
| popups stacked in the corner, like most script hubs | N4 |
| bar across the top that stays | N5 |
| popup in the middle, "are you sure" | N6 |
| popups in the top corner | N7 |
| one small line at the top that swaps | N8 |
| loading, then done | N9 |
| popup with an undo button | N10 |
| popups in the bottom left | N11 |
| small pill message | N12 |
| message with a title | N13 |
| coloured strip on the side | N14 |
| achievement, "unlocked!" card | N15 |
| big text in the middle of the screen | N16 |
| countdown | N17 |
| snackbar with a button | N18 |
| cards stacked on top of each other | N19 |
| kill feed, activity feed | N20 |
| popup with the player's picture | N21 |
| loading bar popup with a percent | N22 |
| pill at the top that opens, dynamic island | N23 |
| popup that stays until I close it | N24 |
| +250 coins floats up | N25 |
| quest step done, objective complete | N26 |
| notification bell with a number | N27 |
| party invite with Accept and Decline | N28 |
| subtitles, captions | N29 |
| screen edges flash red | N30 |
| close it and a button brings it back | O1 |
| shrink into the button, minimise | O2 |
| fold up to the title bar | O3 |
| a tab on the side to pull it back | O4 |
| loading screen before the hub | O5 |
| floating bubble I can move around | O6 |
| tab on the right side | O7 |
| tab at the top to pull it down | O8 |
| small pill with the name | O9 |
| reminds me which key opens it | O10 |
| asks hide or unload before closing | O11 |
| goodbye screen when it closes | O12 |
| a tab at the bottom to pull it up | O13 |
| icons at the bottom like a taskbar, dock | O14 |
| see-through, ghost mode while I play | O15 |
| keep only the side icons | O16 |
| only shows while I hold a key | O17 |
| round button in the corner | O18 |
| swipe it off the screen | O19 |
| hides itself when I stop | O20 |
| changes colour when pressed | P1 |
| pushes in, clicky | P2 |
| lifts on hover | P3 |
| ripple where I click | P4 |
| glowing edge | P5 |
| fills up from the side | P6 |
| squishy | P7 |
| underline appears | P8 |
| shine sweeps across | P9 |
| hold to confirm | P10 |
| arrow that moves | P11 |
| pops when clicked | P12 |
| outline that fills on hover | P13 |
| icon spins, refresh button | P14 |
| shimmer, shiny hover | P15 |
| shows it is working after a click | P16 |
| turns into Done with a tick | P17 |
| cooldown timer before I can press again | P18 |
| press twice to be sure | P19 |
| shakes when I can't | P20 |
| bouncy hover | P21 |
| tilts when pressed | P22 |
| line under the tab | S1 |
| pill behind the tab | S2 |
| just highlight the tab | S3 |
| side menu with a bar | S4 |
| side menu with a pill | S5 |
| tabs with icons | S6 |
| icons only down the side | S7 |
| tabs inside a box, segmented | S8 |
| pages slide | S9 |
| pages fade | S10 |
| dot under the tab | S11 |
| tabs that scroll sideways | S12 |
| tabs at the bottom, like a phone app | S13 |
| numbers on the tabs | S14 |
| step 1, step 2, wizard | S15 |
| tabs like folders | S16 |
| icons that show a name when picked | S17 |
| sidebar with group headings | S18 |
| chosen tab gets bigger | S19 |
| extra tabs under More | S20 |
| left and right arrows, one page at a time | S21 |
| sections that fold open, accordion | S22 |
| words when I hover | H1 |
| speech bubble pointing at the button | H2 |
| number pops up when I drag a slider | H3 |
| number on the slider knob | H4 |
| min and max under the slider | H5 |
| little i button to tap | H6 |
| tooltip with a title and the hotkey | H7 |
| tooltip follows my mouse | H8 |
| tells me why it is locked | H9 |
| press and hold to see | H10 |
| hint under a text box | H11 |
| points at something new, Got it | H12 |

Mixed answers are normal: "T1 but square" is T2; "M2 with less movement" is M2
at 8 px; "like N4 but at the top" is N7. "Pop in, fade out" is opening M3 and
closing M1 — one presenter with a separate `closeStyle`. For names of
window parts and words like "cleaner" or "make it pop", use `ui-words.md`.
Never ask someone to choose Cubic versus Quint or supply spring constants.

## Preserve function while changing style

Keep callbacks, selected values, keyboard/gamepad focus and touch activation
independent of the skin. Selected is persistent for a toggle or tab, not a
one-shot button. Hover must not erase focus, and refresh must not erase the
active state. An action button updates its own appearance, not a different
toggle's knob. Test focus on the launcher, close, each choice and toggle
separately.

One current owner per animated property; rapid open/close cannot let a stale
completion hide a new view. Cancel active animations on unload. Reduced motion
overrides the chosen style and still applies the final state. The guide
communicates intent; it does not prove Roblox geometry, engine timing or
accessibility behavior.

Notifications use the panel's surface entry. Show what happened with text and
an icon, queue bursts, bound the visible count, reflow smoothly and keep
primary controls clear. Time lifetime from arrival, pause for interaction, and
keep actionable errors until dismissed or resolved. Test a long message, a rapid
burst, dismissal during entrance, reflow and unload with pending timers.

---

## Source: .claude/skills/roblox-request-intake/references/ui-words.md

# UI words people use, and what they mean

Users describe interfaces by what they see, not by class names. Read the
description, pick the matching part, and say back the interpretation in one
short clause: "the X in the corner — the close button — is now 44 px". Ask only
when two readings would produce different work. Never correct the user's word.

The guide's "Point at it" diagram numbers these parts, so a user can answer
"W3" instead of finding a word.

## Parts of a window

| Code | They might say | It is | Build notes |
|---|---|---|---|
| W1 | "the bar at the top", "top part" | header | one horizontal row: title, slack, controls |
| W2 | "the name at the top", "the heading" | title | largest type, `TextYAlignment Center` |
| W3 | "the X", "exit button", "close thing" | close button | 44×44 button, 16 px image mark |
| W4 | "the dash", "hide button", "make it small" | minimise button | same size as close; collapses to the launcher |
| W5 | "the bit you grab to move it", "drag bar" | drag handle | whole header drags; grip icon optional |
| W6 | "the side menu", "list on the left" | sidebar / tab rail | vertical tabs; selection persists |
| W7 | "the pages", "sections", "categories" | tabs | see S1–S12 |
| W8 | "the little titles", "group names" | section heading | 12 px caption, muted, above a group |
| W9 | "on/off thing", "switch", "tick" | toggle | see T1–T30; a plain checkbox is C1–C20 |
| W10 | "the bar you drag", "number bar", "range" | slider | shows its value; arrow keys and gamepad step it |
| W11 | "list that opens", "picker", "choose one" | dropdown | closes on outside tap; long lists scroll; see D1–D12 |
| W12 | "the button" | button | label names the action: `Teleport to spawn` |
| W13 | "key box", "hotkey", "bind" | keybind chip | shows the key; press to rebind; Escape cancels |
| W14 | "search bar", "find box" | search box | filters as they type; clear button; D5 or D11 |
| W15 | "typing box", "where I put the name" | text box | placeholder, focus ring, inline error (N3) |
| W16 | "popup message", "alert", "notification" | toast / notice | see N1–N20 |
| W17 | "the hint when I hover" | tooltip | H1–H12; never the only place information lives; phones have no hover |
| W18 | "scroll thing" | scrollbar | thin, only where content overflows |
| W19 | "dark background behind the popup" | backdrop / scrim | dims the game; a tap on it cancels |
| W20 | "button that opens the menu", "toggle UI button" | launcher | stays on screen when the window is closed |
| W21 | "colour wheel", "pick a colour" | colour picker | preview swatch plus hex or RGB entry |
| W22 | "little tag", "badge", "label pill" | badge | status word plus colour, never colour alone |

## Words about how it looks or feels

| They say | Usually means | Do |
|---|---|---|
| "cleaner", "less cluttered" | fewer elements, more space | remove borders on inner blocks, widen spacing one step, merge duplicate labels |
| "make it pop" | contrast, not more colour | one accent element, larger title, darker page behind a lighter panel |
| "more modern" | restraint and consistent radius | two radii, one accent, no gradients on every surface |
| "rounder" | corner radius | raise panel radius, keep controls smaller than panels |
| "smoother" | motion that does not jump | Out easing, interruption continuity, no restart snaps; ask only if unclear |
| "snappier", "faster" | shorter motion | 0.12 to 0.20 s; M1 or M0 |
| "less busy" | fewer things moving at once | fade content, move only the container |
| "bouncy", "springy" | a settle, not a cartoon | M6, one overshoot |
| "glassy", "blurry background" | translucency | Roblox GUI has no backdrop blur; a translucent surface over a darker scrim is the honest version, and say so |
| "glow", "neon" | an accent edge | accent `UIStroke` on the one focal element, not everywhere |
| "like Apple" | quiet, pill switches, soft fades | T1, M1, P1, S2 |
| "like a game menu" | bold, big type, press feedback | P2, S1, larger title |
| "match my UI", "same style as this" | reuse their tokens | read their colours, radii and fonts from the provided script first |
| "the colours are off", "doesn't match" | surfaces or toasts using other values | one token entry per surface; toasts share the panel's entry |
| "it's too big on my phone" | fixed offsets or missing size bounds | `UISizeConstraint` with both bounds; test at 390×844 |
| "the title looks off" | vertical alignment | header row `VerticalAlignment Center`, title `TextYAlignment Center` |

## When the words do not match anything here

Describe the two closest readings in plain words and offer the guide:

> Do you mean the bar across the top of the window, or the message that pops up
> at the top of the screen? The guide's "Point at it" picture numbers both —
> W1 and N2.

---

## Source: .claude/skills/roblox-ui-components/references/style-recipes.md

# Style recipes: what each guide label builds

The visual guide (hosted at <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>,
offline copy `docs/visual-guide/index.html`) shows every option with a code:
**T** toggles, **C** checkboxes and choice groups, **D** dropdowns (including
search fields), **M** menu movement (opening and closing can differ), **N**
notifications, **O** how the whole UI hides and comes back, **P** press feel,
**S** tab switch, **H** tooltips and slider values, and **W** for the parts
of a window. When a user answers
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
N1 + O1 + P1 + S1**, H1 on buttons that need a word and H3 on sliders; for an executor hub use **N4** instead of N1, **D2** for a
list longer than about eight options and **D10** to pick a player. Say which
you used, once.

## Toggles — `../assets/toggles.luau`

`createToggle(parent, label, style, initial, onChanged, details?)` returns
`{ row, set, get, setEnabled, destroy }`. `details` is
`{ description = "...", icon = "rbxassetid://...", key = "F" }`: T19 reads
`description`, T20 `icon`, T29 `key`. Every row is 44 px tall so the whole
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
| T21 | "switch that fills up" | fill switch | T1 track; the accent fill widens behind the knob as it travels |
| T22 | "Off and On either side" | words at both ends | `Off`, the T1 track, `On`; the chosen word takes the text colour, the other goes muted |
| T23 | "switch that glows", "neon switch" | glow switch | T1 with a 2 px accent `UIStroke` named `Glow` on the track while on |
| T24 | "wall light switch" | up-down lever | upright track 24×40; knob y 19 → 3, so up is on |
| T25 | "dot in a circle" | dot in a ring | 22 px ring; a 10 px dot grows inside on a `UIScale` 0 → 1 |
| T26 | "stripe on the side" | edge stripe | 4×24 stripe on the row's left edge lights accent; a `Status` word says ON / OFF |
| T27 | "I and O switch", "power strip switch" | rocker | a two-sided cap marked O and I; the pressed side sinks and darkens |
| T28 | "little ON OFF pill" | status pill | a pill at the row end: `ON` on the dim accent, `OFF` on the raised surface |
| T29 | "shows the keybind" | switch with hotkey | a key chip (`details.key`, default `F`) before a T1 switch |
| T30 | "small switch", "tiny toggle" | mini switch | track 32×18, knob 14, x 2 → 16; the row stays 44 px |

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
| C11 | "just a tick at the end" | tick on the right | no box; a 16 px tick appears at the end of the chosen row |
| C12 | "checkbox with a number" | box with a count | C1 box plus a muted count at the row end from `details.count` |
| C13 | "X box", "ignore list" | cross box | the box fills with the danger colour and shows a cross, for exclusions |
| C14 | "large checkbox", "easy to tap" | big tick box | 32 px box, 20 px tick |
| C15 | "quest list with a bar" | checklist with progress | a `Progress` header, "n of m done" and a filling bar; ticked rows strike through |
| C16 | "buttons stuck together" | joined buttons | multi-select segments in one `CanvasGroup` track; each chosen segment fills and ticks |
| C17 | "stars", "rate it out of five" | star rating | pick one; every star up to the chosen index lights |
| C18 | "colour circles" | colour dots | 32 px dots from `details.colours[name]`; the chosen one gets a ring and a tick |
| C19 | "S M L", "small medium large" | size buttons | 64×36 cells; a `Marker` block slides to the chosen one |
| C20 | "pick one card" | plan cards | radio cards with a line each from `details.descriptions[name]` |

C8, C17, C18, C19 and C20 choose exactly one; the rest choose any number.

## Dropdowns and search fields — `../assets/dropdowns.luau`

`createDropdown(parent, style, spec)` with `spec = { label, options, chosen?,
onChanged, host? }` returns `{ root, get, set, setOptions, open, close, destroy
}`. An option is a string or `{ text, display?, detail?, icon?, image?, group?,
colour?, children? }`. D19 calls `spec.onRun(chosen)` from its main half; D22
calls `spec.onCreate(text)` before choosing the new option. The list opens in its own `ScreenGui` one `DisplayOrder` above the
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
| D13 | "list with descriptions" | two-line options | 56 px rows: the option and a muted `detail` line under it |
| D14 | "recent at the top" | recent first | the last three picks under RECENT, then ALL |
| D15 | "list goes up" | opens upward | the list prefers the space above the field |
| D16 | "phone style list" | bottom sheet | the list slides up from the bottom edge and dims the game behind it |
| D17 | "finishes the word for me" | autocomplete | the rest of the first match shows as ghost text; Tab accepts it |
| D18 | "tiles to pick from" | grid | options as 72 px tiles in three columns, icon over the name |
| D19 | "run it or change it" | split button | the main half runs the choice (`onRun`); the chevron half opens the list |
| D20 | "Apply button" | pick then apply | ticks wait in the list; only Apply changes the value, closing discards them |
| D21 | "menu inside a menu" | sub-menus | an option with `children` opens its own list with a Back row |
| D22 | "add my own option" | type to add | typing a new name offers `Add "name"`; picking it calls `onCreate` |


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
| M25 | "spins into place" | spin in | the M5 grow with a quarter turn, −90° → 0, one overshoot; leaves turning 45° |
| M26 | "comes in at an angle" | diagonal slide | 24 px from the lower left with the fade; leaves 12 px |
| M27 | "wipes in from the left" | curtain | width unfolds from the left edge, keeping that edge still |
| M28 | "starts as a circle" | grow from a circle | a 48 px circle at the centre grows into the panel while its corner eases to 10 px |
| M29 | "bounces up from below" | bounce up | 40 px rise on Bounce Out, 0.45 s |
| M30 | "wobbly slide" | jelly slide | 48 px from the left on Elastic Out, 0.5 s |
| M31 | "zooms from far away" | zoom from far | `UIScale` 0.5 → 1 on the settle timing, one overshoot |
| M32 | "falls and straightens" | tilt and drop | 24 px drop tilted 8°, straightens on the settle timing |
| M33 | "each row pops in" | rows pop | the M12 cascade with each row's `RowScale` 0.9 → 1 |
| M34 | "smooth long slide" | glide | 120 px from the right, 0.5 s Quint Out; out 0.3 s Quint In |
| M35 | "heartbeat" | heartbeat pop | the M3 pop, then two 1.04 beats of 0.12 s |
| M36 | "shrinks away to the middle" | collapse to centre | opens with a 0.9 grow; closes shrinking to 0.5 |

Every style needs a way back: when the window closes, a launcher button (W20)
stays on screen. A keybind alone strands a phone player. Reopening during a
close continues from where the panel is, and a stale close can never hide the
reopened panel. A panel dragged while open keeps its new
position. With reduced motion every style becomes a 0.08 s fade. A `UIScale`
used for screen-size scaling belongs on a parent frame, not on the panel.

## Notifications — `../assets/toasts.luau`, `../assets/notices.luau` and `../assets/announcements.luau`

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
| N21 | "someone joined", "popup with their picture" | player popup | `notifier.player(message, userId)`: a 32 px round headshot leads the toast |
| N22 | "loading bar popup" | progress with percent | `notifier.percent(message)` returns `{ set(fraction), done(message, severity?) }`; a bar and a percent |
| N23 | "dynamic island" | island | `announcements.createIsland(screen).show(text, more?)`: a pill under the top bar that opens on hover or tap |
| N24 | "popup that does not go away" | sticky toast | `notifier.sticky(message, severity?)`: no timer, a 44 px dismiss button |
| N25 | "+250 coins floats up" | floating reward | `announcements.floatText(anchor, text, icon?)`: rises 40 px from the anchor and fades |
| N26 | "quest step done" | objective complete | `announcements.createObjectives(screen).complete(text)`: a tick card at the right edge |
| N27 | "notification bell" | bell with a count | `announcements.createInbox(screen)`: `push(text)`, `unread()`; a bell with a badge opens the list |
| N28 | "party invite" | invite | `notifier.invite(message, onAccept, onDecline?)`: Decline and Accept buttons, leaves after 10 s |
| N29 | "subtitles" | captions | `announcements.createCaptions(screen).say(text, name?)`: one line near the bottom, speaker first |
| N30 | "screen flashes red" | edge flash | `announcements.flashEdges(screen, severity?)`: gradient strips pulse on all four edges |

The stacked styles (N1, N2, N4) show three at a time, queue up to ten, collapse
a repeated `key` into `×2`, pause while hovered and reflow with a spring when a
middle toast leaves. Put the `ScreenGui` on `ScreenInsets = CoreUISafeInsets`
and `ResetOnSpawn = false`. N6 is only for something the player must answer:
its dim layer counts a tap outside as Cancel, and gamepad focus starts on the
safe choice.

## Hiding and bringing back the whole UI — `../assets/windows.luau`

`createWindow({ panel, launcher, header, body, rail, dock, opener, keyName }, style)` returns
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
| O13 | "a tab at the bottom" | pull-up tab | slides down out of view; a tab at the bottom brings it up |
| O14 | "dock", "taskbar" | dock | shrinks into its icon in a `Dock` bar; pass one `dock` to share it between windows |
| O15 | "ghost mode", "see through while I play" | see-through | goes to 0.8 transparency with `Interactable = false`; an eye button makes it solid |
| O16 | "keep only the side icons" | shrink to the rail | the width folds to `rail`; a button beside it expands the rest |
| O17 | "only while I hold a key" | hold to show | shown only while `keyName` (default LeftAlt) or the on-screen "Hold to show" button is held |
| O18 | "floating action button" | corner button | shrinks into a round button in the bottom-right corner |
| O19 | "swipe it away" | swipe away | drag the header sideways past 120 px to send it off that side; the tab waits there |
| O20 | "hides when I stop" | hides when idle | fades after 8 s without input over the screen; any input brings it back |

## Press feel — `../assets/press-and-tabs.luau`

`attachPress(button, style, onHold?)` returns a cleanup function. P4, P8, P9,
P10 and P11 draw inside the button, so they need a button with no
`UIListLayout`; P14 spins the button's child named `Icon`.

The P16 to P20 styles are about what an action does, not how the button
moves: `attachAction(button, style, { run, seconds?, confirmText?, allowed? })`
returns a cleanup function. `run(finish)` does the work and calls
`finish(true)` or `finish(false)`; P18 reads `seconds`, P19 `confirmText`,
P20 `allowed`.

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
| P13 | "outline button" | outline fill | outlined at rest; the fill comes in on hover and deepens on press |
| P14 | "refresh button" | icon spin | the `Icon` child turns a full circle on press |
| P15 | "shiny hover" | shimmer | a `Shimmer` gradient drifts across only while hovered |
| P16 | "loading after click" | working | `attachAction`: reads "Working…" and cannot be pressed until `finish` |
| P17 | "turns green with a tick" | done state | `attachAction`: "Done" or "Failed" for 1.2 s, then the label returns |
| P18 | "timer before I can press again" | cooldown | `attachAction`: a draining `CooldownLayer` and "label 4s" until ready |
| P19 | "click again to be sure" | press twice | `attachAction`: the first press asks "Press again to confirm" for 3 s |
| P20 | "wiggles if I can't" | shake when blocked | `attachAction`: when `allowed()` is false it shakes ±4° and does not run |
| P21 | "grows with a bounce" | bouncy hover | `UIScale` 1.06 on hover with a Back overshoot back |
| P22 | "tilts when I press it" | tilt on press | `Rotation` −2° while held |

## Tab switch — `../assets/press-and-tabs.luau`

`createTabs(parent, names, style, onSelect, options?)` returns `{ select,
selected, destroy }`. `options = { icons, pages, counts, groups, visible }`: S6, S7, S13 and S17
read `icons`; S9, S10 and S22 turn `pages`; S14 reads `counts`, S18 `groups`
and S20 `visible` (how many tabs show before More). The selected tab persists; focus and hover never change it.

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
| S13 | "tabs at the bottom", "like a phone app" | bottom tab bar | 56 px bar of icon-over-name tabs; a 2 px line on top of the chosen one |
| S14 | "numbers on the tabs" | tabs with counts | S1 with a `Count` badge from `counts[name]` |
| S15 | "step 1, step 2" | numbered steps | numbered circles; steps before the chosen one show a tick |
| S16 | "tabs like folders" | folder tabs | the chosen tab takes the page's surface and joins it by 6 px |
| S17 | "icons that show a name when picked" | expanding icon | icons only; the chosen one widens to show its name |
| S18 | "sidebar with headings" | grouped side list | S4 under `{group}Heading` labels from `groups` |
| S19 | "chosen tab gets big" | bigger when chosen | the chosen tab's name goes to 20 px; nothing slides |
| S20 | "too many tabs" | more menu | the first `visible` tabs show; the rest open from a More button |
| S21 | "one page at a time" | arrows between pages | one name with previous and next buttons that wrap |
| S22 | "accordion" | sections that open | each tab is a heading; its page opens under it, one at a time |

## Tooltips and slider values — `../assets/tooltips.luau`

The words that explain a control. Every style is readable without a mouse:
hover styles open on a 0.5 s long press on a phone and on gamepad selection.
Full guidance is `../../roblox-ui-tooltips/SKILL.md`.

`createTooltip(target, style, { text, title?, keyHint?, host? })` returns
`{ setText, setDisabled, show, hide, destroy }` and draws in its own
`TooltipLayer` two `DisplayOrder`s above the host, so nothing clips it.
`createSliderValue({ track, thumb, min, max, format? }, style)` returns
`{ update(value), setDragging(on), destroy }`.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| H1 | "words when I hover" | hover tooltip | after 0.4 s at rest, 8 px under the control; flips above near the bottom, never crosses a side edge |
| H2 | "speech bubble" | bubble with arrow | H1 above the control with an `Arrow` pointing at it |
| H3 | "number pops up when I drag" | drag value | `createSliderValue(parts, "H3")`: the formatted value floats 8 px over the thumb only while dragging |
| H4 | "number on the knob" | value on the knob | `createSliderValue(parts, "H4")`: a `ValueTag` rides the thumb always |
| H5 | "min and max under it" | ends and value | `createSliderValue(parts, "H5")`: `Min` and `Max` under the ends, `Value` after the track |
| H6 | "little i button" | info button | `createInfoButton(parent, text, order?)`: a 44 px button; tap opens, a tap elsewhere or Escape closes |
| H7 | "tooltip with a title" | titled tooltip | bold `title`, a 12 px line and a `keyHint` chip |
| H8 | "follows my mouse" | follows the pointer | sits 16 px right and below the pointer and follows it |
| H9 | "why is it locked" | locked reason | `setDisabled(true)` lays a `ReasonCatcher` over the control; tap or hover says why, with a lock |
| H10 | "hold to see" | press and hold | nothing on hover; shows after a 0.5 s hold, hides on release |
| H11 | "hint under the box" | helper line | `createHelperText(parent, text, order)`: a 12 px hint that `setError(message)` turns into the error with an icon |
| H12 | "points at something new" | coach mark | `showCoachMark(target, text, onDone)`: a ring on the target and a bubble with Got it; returns `dismiss` |

A tooltip names what the control does in the game's words and stays under
about twelve words. Anything the player must know to play is H11 or H6, never
a hover.

## Window parts — the W codes

The guide's "Point at it" diagram numbers the parts of a hub window so a user
can say "make W3 bigger" instead of hunting for the word. The names and the
everyday words for each are in
`../../roblox-request-intake/references/ui-words.md`.

---

## Source: .claude/skills/roblox-ui-components/references/icon-meaning.md

# Which icon means what

A tab labelled **Visuals** with a `star` beside it, **Settings** with a
`wrench` and **Misc** with a `sparkles`: each icon is a real image, and none
of them tells the player anything. The icon is a second label. When it names a
different thing from the words, the player reads two answers and trusts
neither.

This file picks the icon from the meaning. Every icon here is in
`icon-ids.txt`, uploaded to Roblox and checked as a real image; the content id
is copied from there, not recalled.

---

## The rules

1. **The icon names the same thing as the label.** Read the label, find its
   row below, use that icon. No row fits? Search `icon-ids.txt` by the label's
   words (its third column is Lucide's search tags):
   `grep -i "	.*fishing" icon-ids.txt`. Use the name whose tags contain the
   player's word, not the one that looks nicest.
2. **One icon per meaning, one meaning per icon.** Two tabs never share an
   icon. If **Combat** has `swords`, **Kill aura** in the Combat tab uses
   `skull` or no icon at all.
3. **One family, one weight, one size.** Every icon in an interface comes from
   `icon-ids.txt` (Lucide, 2 px strokes). Mixing in a filled emoji-style icon
   or a different set makes the odd one look broken. Size: 16 in rows and
   fields, 20 in tabs and headers, 24 on HUD buttons.
4. **Tabs and toggles keep their words.** Icon-only is for the four controls
   everyone knows (close, minimise, back, search) and a HUD button on screen
   often enough to be learned. A sidebar collapsed to icons shows the name on
   hover on a computer and never collapses on a phone, where nothing hovers.
5. **The icon takes the text colour of its row**, secondary when resting,
   primary or accent when selected. An icon is never the only thing that shows
   state.
6. **No brand logos.** Lucide has none, so a Discord or YouTube button uses
   `message-circle` or `link` with the name written beside it. Never write an
   id for a logo you did not upload.
7. **Nothing decorative.** An icon on every row of a settings list, each
   different and none meaningful, is noise. Put icons on tabs, on actions and
   on the first field of a search; leave plain settings rows plain.

---

## Picking for a tab list

Read the labels together first. A set of tabs is one decision:

| Tabs | Icons |
|---|---|
| Main, Player, Combat, Visuals, Misc, Settings | `home`, `user`, `swords`, `eye`, `package`, `settings` |
| Farm, Teleports, Pets, Shop, Settings | `sprout`, `map-pin`, `paw-print`, `shopping-cart`, `settings` |
| Shop, Inventory, Quests, Rewards | `shopping-cart`, `backpack`, `scroll-text`, `gift` |

If two tabs want the same icon, the labels overlap. **Settings** and
**Options** both want `settings`; that is one tab under two names, and the
fix is to rename one (`ui-copy.md`), not to find a second gear.

---

## The table

The first icon is the default. "Also fits" are real alternatives for when the
default is already taken. Copy content ids from here or from `icon-ids.txt`.

### Hub tabs

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Main, Home, General | main page, start, overview | `home` | `rbxassetid://109841253338329` | `layout-dashboard` |
| Player, Local player, Character | me, my character, movement settings | `user` | `rbxassetid://114567720540659` | `user-round` |
| Combat, Fighting, PvP | fight, attack, kill aura | `swords` | `rbxassetid://99199363807265` | `sword`, `crosshair` |
| Visuals, ESP, Render | see players, highlights, wallhack | `eye` | `rbxassetid://127234874352422` | `scan` |
| Farming, Auto farm | grind, collect, auto | `sprout` | `rbxassetid://100976494216154` | `tractor`, `coins` |
| Teleports, Locations, Waypoints | go to, places, map | `map-pin` | `rbxassetid://137091405832737` | `navigation`, `map` |
| Movement | speed, fly, jump | `footprints` | `rbxassetid://80792036653047` | `move`, `wind` |
| World, Server, Environment | lighting, time, map settings | `globe` | `rbxassetid://125685532120024` | `server` |
| Misc, Other, Extra | everything else | `package` | `rbxassetid://106101842173393` | `ellipsis`, `boxes` |
| Settings, Options, Config | change the hub itself | `settings` | `rbxassetid://106205298246017` | `sliders`, `settings-2` |
| Keybinds, Controls | keys, hotkeys | `keyboard` | `rbxassetid://121978468376124` | `mouse` |
| Theme, Appearance | colours, look | `palette` | `rbxassetid://127369887384101` | `paintbrush` |
| Credits, About, Info | who made it, version | `info` | `rbxassetid://120620848266512` | `heart` |
| Updates, Changelog, News | what's new | `megaphone` | `rbxassetid://139746713205639` | `newspaper` |
| Logs, Console, History | output, messages | `scroll-text` | `rbxassetid://93551675076113` | `file-text` |
| Scripts, Games list, Hub games | supported games | `gamepad-2` | `rbxassetid://99293705721130` | `joystick` |
| Webhook, Discord alerts | send to a server, notify | `webhook` | `rbxassetid://110638252405523` | `bell-ring` |

### Game screens

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Shop, Store | buy things | `shopping-cart` | `rbxassetid://79435149356304` | `store` |
| Inventory, Backpack, Items | my stuff | `backpack` | `rbxassetid://76143965140765` | `package` |
| Pets | companions, eggs | `paw-print` | `rbxassetid://97578437331341` | `egg` |
| Eggs, Hatching, Crates | open, roll, gacha | `egg` | `rbxassetid://103880404435578` | `gift` |
| Quests, Missions, Tasks | objectives, to-do | `scroll-text` | `rbxassetid://93551675076113` | `list-checks` |
| Daily reward, Login bonus | claim, streak | `calendar-check` | `rbxassetid://116665691227418` | `gift` |
| Rewards, Gifts, Free items | claim, bonus | `gift` | `rbxassetid://87706885156127` | `party-popper` |
| Codes, Redeem | promo code | `ticket` | `rbxassetid://126875062984266` | `key` |
| Leaderboard, Rankings | top players | `trophy` | `rbxassetid://113055182645565` | `medal` |
| Stats, Profile numbers | levels, progress | `bar-chart-3` | `rbxassetid://130626786024244` | `activity` |
| Trading | swap with players | `arrow-left-right` | `rbxassetid://112517617090898` | `repeat` |
| Friends, Party, Team | invite, group | `users` | `rbxassetid://85332511060401` | `user-plus` |
| Chat, Messages | talk | `message-circle` | `rbxassetid://74163263000218` | — |
| Rebirth, Prestige | reset for bonus | `refresh-cw` | `rbxassetid://106497040962250` | `repeat` |
| Upgrades, Boosts | improve, level up | `arrow-up-to-line` | `rbxassetid://135365442561417` | `zap` |
| Gamepasses, VIP, Premium | paid perks | `crown` | `rbxassetid://92253403464658` | `gem` |
| Currency: coins, cash | money | `coins` | `rbxassetid://117341212186115` | `wallet` |
| Currency: gems, diamonds | premium currency | `gem` | `rbxassetid://125353572203968` | — |
| Emotes, Dances | animations | `smile` | `rbxassetid://129431925610335` | `party-popper` |
| Music, Radio | songs, sound | `music` | `rbxassetid://132132095360900` | `radio` |
| Map, Areas, Worlds | zones, islands | `map` | `rbxassetid://131325044235094` | `compass` |
| Achievements, Badges | milestones | `medal` | `rbxassetid://97534791863003` | `trophy` |
| Help, Tutorial, How to play | guide | `help-circle` | `rbxassetid://71693802872044` | `book-open` |

### Features and toggles

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Aimbot, Aim assist, Lock on | aim, target | `crosshair` | `rbxassetid://83752373575368` | `target`, `locate-fixed` |
| Walk speed, Speed | run faster | `gauge` | `rbxassetid://128279962545721` | `zap` |
| Fly | flight | `plane` | `rbxassetid://123931033451986` | `feather` |
| Noclip, Walk through walls | ghost mode | `ghost` | `rbxassetid://132705178126217` | — |
| Infinite jump, Jump power | jump higher | `arrow-up-to-line` | `rbxassetid://135365442561417` | — |
| God mode, No damage | invincible | `shield` | `rbxassetid://106509993556171` | `shield-check` |
| Anti-AFK, Stay online | keep active | `timer` | `rbxassetid://120164083411828` | `clock` |
| Auto clicker, Auto click | click for me | `mouse-pointer-click` | `rbxassetid://81854854241463` | — |
| Kill aura, Auto attack | hit everything near | `swords` | `rbxassetid://99199363807265` | `skull` |
| Auto collect, Magnet | grab drops | `coins` | `rbxassetid://117341212186115` | `hand-coins` |
| Auto fish | fishing | `fish` | `rbxassetid://114555142566431` | — |
| Auto mine | mining, ore | `pickaxe` | `rbxassetid://111300940329486` | — |
| Auto chop, Wood | trees | `axe` | `rbxassetid://84931585672806` | `tree-pine` |
| Fullbright, No fog | see in the dark | `sun` | `rbxassetid://139232691165198` | `lightbulb` |
| Player ESP, Names, Tracers | see players | `eye` | `rbxassetid://127234874352422` | `scan` |
| Item or chest ESP | see items | `box` | `rbxassetid://117371753006597` | `package` |
| Server hop, Rejoin | new server | `server` | `rbxassetid://105706502741449` | `refresh-cw` |
| Unload, Destroy script | turn it all off | `power` | `rbxassetid://89331085993646` | `log-out` |

### Window and field controls

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Close | the X | `x` | `rbxassetid://116396312853810` | — |
| Minimise, Hide | the dash | `minus` | `rbxassetid://95070996149109` | — |
| Back | previous page | `chevron-left` | `rbxassetid://102314312897830` | — |
| Dropdown arrow | open the list | `chevron-down` | `rbxassetid://71457658246709` | — |
| Search | find | `search` | `rbxassetid://72296609649861` | — |
| Refresh, Reload | update the list | `refresh-cw` | `rbxassetid://106497040962250` | `rotate-cw` |
| Locked | not yet available | `lock` | `rbxassetid://119765975153029` | — |
| Unlocked | available | `lock-open` | `rbxassetid://71186154315213` | `unlock` |
| Copy | copy text | `copy` | `rbxassetid://116378866141355` | — |
| Delete | remove | `trash-2` | `rbxassetid://126010725826757` | — |
| Save | keep settings | `save` | `rbxassetid://122894934359450` | — |
| Success notification | done | `check-circle` | `rbxassetid://105979545056636` | — |
| Warning notification | careful | `alert-triangle` | `rbxassetid://112102474509324` | — |
| Error notification | failed | `x-circle` | `rbxassetid://111132030834422` | — |
| Info notification | note | `info` | `rbxassetid://120620848266512` | — |
---

## When the user names an icon

"Use a sword for combat": check the name exists
(`grep -P "^sword\t" icon-ids.txt`) and use its id. If the word is not a Lucide
name ("a diamond"), search the tags column and offer the closest match by name:
`gem` for diamond, `crown` for VIP. If nothing matches, say so and use the
nearest row above; never invent an id.

---

## Source: .claude/skills/roblox-ui-tooltips/SKILL.md

---
name: roblox-ui-tooltips
description: Tooltips and the words around a control in Roblox UI — hover tooltips, bubbles with arrows, slider value readouts while dragging, values on the knob, min and max labels, info buttons, titled tooltips with a hotkey, pointer-following labels, locked-button reasons, press-and-hold hints, helper and error lines under a field, and first-time coach marks. Covers which one to use, delay and hide timing, placement and edge flipping, touch and gamepad access so nothing is hover-only, layering above scrolling frames, text length, and the tested H1-H12 recipes. Use for any tooltip, hover text, slider number, "what does this do", "why can't I press this", "add a hint", or a picked H code.
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

---

## Recipe: .claude/skills/roblox-ui-components/assets/announcements.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

export type Severity = "info" | "success" | "warning" | "error"

local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	tile = Color3.fromRGB(28, 88, 74),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	action = Color3.fromRGB(72, 201, 162),
	outline = Color3.fromRGB(9, 10, 13),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
	caption = Color3.fromRGB(9, 10, 13),
}

local ICON = {
	trophy = "rbxassetid://113055182645565",
	bell = "rbxassetid://84691420588185",
	done = "rbxassetid://88244323237265",
}

local ENTER = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local ARRIVE = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SWEEP = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local INSTANT = TweenInfo.new(0)

local ACHIEVEMENT_HOLD = 4
local SNACK_HOLD = 4
local SNACK_ACTION_HOLD = 6
local FEED_HOLD = 4
local FEED_LINES = 6
local FEED_DIM = 0.2
local OBJECTIVE_HOLD = 3
-- N26 sits a third of the way down the right edge, clear of the corner stacks.
local OBJECTIVE_HEIGHT = 0.3
local FLOAT_RISE = 40
local FLOAT_TIME = 1
local INBOX_KEEP = 20
local CAPTION_DIM = 0.4
local EDGE_DEPTH = 0.18
local EDGE_PEAK = 0.45
local FLASH_IN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_OUT = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLOAT = TweenInfo.new(FLOAT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function readingTime(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.clamp(2 + words * 0.3, 3, 8)
end

local function tween(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
	local playing = TweenService:Create(target, motion(timing), goals)
	playing:Play()
	return playing
end

local function round(target: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
end

local function outline(target: GuiObject)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = target
end

local function pad(target: GuiObject, vertical: number, horizontal: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, vertical)
	padding.PaddingBottom = UDim.new(0, vertical)
	padding.PaddingLeft = UDim.new(0, horizontal)
	padding.PaddingRight = UDim.new(0, horizontal)
	padding.Parent = target
end

local function line(parent: GuiObject, gap: number, direction: Enum.FillDirection): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

local function words(name: string, text: string, size: number, bold: boolean): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	return label
end

-- N15: a card that drops in at the top centre, a light passes across it once,
-- and it leaves after four seconds. Returns a dismiss that is safe to repeat.
local function showAchievement(
	screen: ScreenGui,
	title: string,
	detail: string,
	icon: string?
): () -> ()
	local gone = false

	local card = Instance.new("CanvasGroup")
	card.Name = "Achievement"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundColor3 = THEME.surface
	card.GroupTransparency = 1
	card.Parent = screen
	round(card, 10)
	outline(card)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(400, math.huge)
	bounds.Parent = card

	-- The layout lives one level down so the sweeping light is free to move.
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AutomaticSize = Enum.AutomaticSize.XY
	content.BackgroundTransparency = 1
	content.Parent = card
	pad(content, 12, 12)
	line(content, 12, Enum.FillDirection.Horizontal)

	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.LayoutOrder = 1
	tile.Size = UDim2.fromOffset(48, 48)
	tile.BackgroundColor3 = THEME.tile
	tile.BorderSizePixel = 0
	tile.Parent = content
	round(tile, 6)

	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Glyph"
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromOffset(24, 24)
	glyph.BackgroundTransparency = 1
	glyph.Image = icon or ICON.trophy
	glyph.ImageColor3 = THEME.action
	glyph.Parent = tile

	local column = Instance.new("Frame")
	column.Name = "Words"
	column.LayoutOrder = 2
	column.AutomaticSize = Enum.AutomaticSize.XY
	column.BackgroundTransparency = 1
	column.Parent = content
	line(column, 4, Enum.FillDirection.Vertical)

	local heading = words("Title", title, 16, true)
	heading.LayoutOrder = 1
	heading.Parent = column

	local note = words("Detail", detail, 12, false)
	note.LayoutOrder = 2
	note.TextColor3 = THEME.textMuted
	note.Parent = column

	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Position = UDim2.fromScale(-0.5, 0)
	shine.Size = UDim2.fromScale(0.5, 1)
	shine.BackgroundColor3 = THEME.text
	shine.BorderSizePixel = 0
	shine.Parent = card

	local band = Instance.new("UIGradient")
	band.Rotation = 20
	band.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	band.Parent = shine

	local function dismiss()
		if gone then
			return
		end
		gone = true
		tween(card, EXIT, { Position = UDim2.new(0.5, 0, 0, 8) })
		tween(card, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
			card:Destroy()
		end)
	end

	local reduced = GuiService.ReducedMotionEnabled
	card.Position = UDim2.new(0.5, 0, 0, if reduced then 16 else 0)
	tween(card, ARRIVE, { Position = UDim2.new(0.5, 0, 0, 16), GroupTransparency = 0 })
	shine.Visible = not reduced
	tween(shine, SWEEP, { Position = UDim2.fromScale(1, 0) })
	task.delay(ACHIEVEMENT_HOLD, dismiss)
	return dismiss
end

-- N16: large words in the middle of the screen for a moment that matters to
-- everyone, such as a round starting. A new line replaces the one showing.
local function createAnnouncer(screen: ScreenGui)
	local ticket = 0

	local banner = words("Announcement", "", 28, true)
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.35)
	banner.TextXAlignment = Enum.TextXAlignment.Center
	banner.TextTransparency = 1
	banner.Visible = false
	banner.Parent = screen

	-- The world behind is any colour, so the words carry their own dark edge.
	local rim = Instance.new("UIStroke")
	rim.Color = THEME.outline
	rim.Thickness = 2
	rim.Transparency = 1
	rim.Parent = banner

	local grow = Instance.new("UIScale")
	grow.Parent = banner

	local function show(message: string)
		ticket += 1
		local mine = ticket
		banner.Text = message
		banner.Visible = true
		grow.Scale = if GuiService.ReducedMotionEnabled then 1 else 0.9
		tween(grow, ENTER, { Scale = 1 })
		tween(banner, ENTER, { TextTransparency = 0 })
		tween(rim, ENTER, { Transparency = 0 })
		task.delay(readingTime(message), function()
			if mine ~= ticket then
				return
			end
			tween(rim, EXIT, { Transparency = 1 })
			tween(banner, EXIT, { TextTransparency = 1 }).Completed:Once(function()
				if mine == ticket then
					banner.Visible = false
				end
			end)
		end)
	end

	return {
		show = show,
		destroy = function()
			ticket += 1
			banner:Destroy()
		end,
	}
end

-- N18: one bar at the bottom with an optional action on its right. A new
-- message replaces the old one; the action runs once and closes the bar.
local function createSnackbar(screen: ScreenGui)
	local ticket = 0
	local onAction: (() -> ())? = nil
	local connections: { RBXScriptConnection } = {}

	local bar = Instance.new("CanvasGroup")
	bar.Name = "Snackbar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.AutomaticSize = Enum.AutomaticSize.Y
	bar.Size = UDim2.new(1, -32, 0, 0)
	bar.BackgroundColor3 = THEME.surface
	bar.GroupTransparency = 1
	bar.Visible = false
	bar.Parent = screen
	round(bar, 10)
	outline(bar)
	pad(bar, 4, 16)
	line(bar, 12, Enum.FillDirection.Horizontal)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(560, math.huge)
	bounds.Parent = bar

	local message = words("Message", "", 14, false)
	message.LayoutOrder = 1
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.Size = UDim2.fromScale(0, 0)
	message.TextWrapped = true
	message.Parent = bar

	local grow = Instance.new("UIFlexItem")
	grow.FlexMode = Enum.UIFlexMode.Fill
	grow.Parent = message

	local action = Instance.new("TextButton")
	action.Name = "Action"
	action.LayoutOrder = 2
	action.AutoButtonColor = false
	action.AutomaticSize = Enum.AutomaticSize.X
	action.Size = UDim2.fromOffset(0, 44)
	action.BackgroundTransparency = 1
	action.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	action.TextSize = 14
	action.TextColor3 = THEME.action
	action.Text = ""
	action.Visible = false
	action.Parent = bar

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.action
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = action

	local function hide()
		ticket += 1
		local mine = ticket
		onAction = nil
		tween(bar, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
			if mine == ticket then
				bar.Visible = false
			end
		end)
	end

	local function show(text: string, actionLabel: string?, run: (() -> ())?)
		ticket += 1
		local mine = ticket
		message.Text = text
		onAction = run
		action.Text = actionLabel or ""
		action.Visible = actionLabel ~= nil and run ~= nil
		if not bar.Visible then
			bar.Visible = true
			bar.Position = UDim2.new(0.5, 0, 1, if GuiService.ReducedMotionEnabled then -16 else 0)
		end
		tween(bar, ENTER, { Position = UDim2.new(0.5, 0, 1, -16), GroupTransparency = 0 })
		task.delay(if action.Visible then SNACK_ACTION_HOLD else SNACK_HOLD, function()
			if mine == ticket then
				hide()
			end
		end)
	end

	table.insert(connections, action.Activated:Connect(function()
		local run = onAction
		hide()
		if run then
			run()
		end
	end))
	table.insert(connections, action.MouseEnter:Connect(function()
		action.TextColor3 = THEME.text
	end))
	table.insert(connections, action.MouseLeave:Connect(function()
		action.TextColor3 = THEME.action
	end))
	table.insert(connections, action.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, action.SelectionLost:Connect(function()
		ring.Enabled = false
	end))

	return {
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			bar:Destroy()
		end,
	}
end

-- N20: short lines stacking in the top-right corner, newest at the bottom, each
-- fading after four seconds. Six at most; a seventh pushes the oldest out.
local function createFeed(screen: ScreenGui)
	local count = 0
	local lines: { CanvasGroup } = {}

	local feed = Instance.new("Frame")
	feed.Name = "Feed"
	feed.AnchorPoint = Vector2.new(1, 0)
	feed.Position = UDim2.new(1, -16, 0, 16)
	feed.AutomaticSize = Enum.AutomaticSize.Y
	feed.Size = UDim2.fromOffset(280, 0)
	feed.BackgroundTransparency = 1
	feed.Parent = screen
	line(feed, 4, Enum.FillDirection.Vertical).HorizontalAlignment = Enum.HorizontalAlignment.Right

	local function remove(entry: CanvasGroup)
		local index = table.find(lines, entry)
		if not index then
			return
		end
		table.remove(lines, index)
		tween(entry, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
			entry:Destroy()
		end)
	end

	local function push(text: string, severity: Severity?)
		count += 1
		if #lines >= FEED_LINES then
			remove(lines[1])
		end

		local entry = Instance.new("CanvasGroup")
		entry.Name = "Line"
		entry.LayoutOrder = count
		entry.AutomaticSize = Enum.AutomaticSize.XY
		entry.BackgroundColor3 = THEME.surface
		entry.BackgroundTransparency = FEED_DIM
		entry.GroupTransparency = 1
		round(entry, 6)
		pad(entry, 4, 8)
		line(entry, 8, Enum.FillDirection.Horizontal)

		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.LayoutOrder = 1
		dot.Size = UDim2.fromOffset(8, 8)
		dot.BackgroundColor3 = THEME[severity or "info"]
		dot.BorderSizePixel = 0
		dot.Parent = entry
		round(dot, 4)

		local label = words("Text", text, 14, false)
		label.LayoutOrder = 2
		label.Parent = entry

		entry.Parent = feed
		table.insert(lines, entry)
		tween(entry, ENTER, { GroupTransparency = 0 })
		task.delay(FEED_HOLD, remove, entry)
	end

	return {
		push = push,
		destroy = function()
			table.clear(lines)
			feed:Destroy()
		end,
	}
end

local function pill(target: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = target
end

local function glyph(name: string, image: string, size: number, colour: Color3): ImageLabel
	local picture = Instance.new("ImageLabel")
	picture.Name = name
	picture.Size = UDim2.fromOffset(size, size)
	picture.BackgroundTransparency = 1
	picture.Image = image
	picture.ImageColor3 = colour
	return picture
end

-- N23: a small pill under the top bar with the short line; hovering or
-- tapping it opens the detail underneath, and it closes itself again.
local function createIsland(screen: ScreenGui)
	local ticket = 0
	local connections: { RBXScriptConnection } = {}

	local island = Instance.new("CanvasGroup")
	island.Name = "Island"
	island.AnchorPoint = Vector2.new(0.5, 0)
	island.Position = UDim2.new(0.5, 0, 0, 8)
	island.AutomaticSize = Enum.AutomaticSize.XY
	island.BackgroundColor3 = THEME.caption
	island.GroupTransparency = 1
	island.Visible = false
	island.Parent = screen
	pill(island)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(120, 0)
	bounds.MaxSize = Vector2.new(360, math.huge)
	bounds.Parent = island

	-- The words have their own frame so the tap target can lie over them
	-- without being placed by their layout.
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AutomaticSize = Enum.AutomaticSize.XY
	content.BackgroundTransparency = 1
	content.Parent = island
	pad(content, 8, 16)
	local stack = line(content, 4, Enum.FillDirection.Vertical)
	stack.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local short = words("Short", "", 14, true)
	short.LayoutOrder = 1
	short.Parent = content

	local detail = words("Detail", "", 12, false)
	detail.LayoutOrder = 2
	detail.TextColor3 = THEME.textMuted
	detail.Visible = false
	detail.Parent = content

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Size = UDim2.fromScale(1, 1)
	hit.Parent = island

	local function expand(open: boolean)
		detail.Visible = open and detail.Text ~= ""
	end

	table.insert(connections, hit.MouseEnter:Connect(function()
		expand(true)
	end))
	table.insert(connections, hit.MouseLeave:Connect(function()
		expand(false)
	end))
	table.insert(connections, hit.Activated:Connect(function()
		expand(not detail.Visible)
	end))

	local function show(text: string, more: string?)
		ticket += 1
		local mine = ticket
		short.Text = text
		detail.Text = more or ""
		expand(false)
		island.Visible = true
		tween(island, ENTER, { GroupTransparency = 0 })
		task.delay(readingTime(`{text} {more or ""}`), function()
			if mine ~= ticket then
				return
			end
			tween(island, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
				if mine == ticket then
					island.Visible = false
				end
			end)
		end)
	end

	return {
		show = show,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			island:Destroy()
		end,
	}
end

-- N25: "+250 coins" rises from the thing that earned it and fades away. The
-- label lives on the anchor's ScreenGui, so a list or a clip cannot cut it off.
local function floatText(anchor: GuiObject, text: string, icon: string?)
	local screen = anchor:FindFirstAncestorWhichIsA("ScreenGui")
	assert(screen, "floatText needs an anchor inside a ScreenGui")

	local x = anchor.AbsolutePosition.X - screen.AbsolutePosition.X + anchor.AbsoluteSize.X / 2
	local y = anchor.AbsolutePosition.Y - screen.AbsolutePosition.Y

	local reward = Instance.new("Frame")
	reward.Name = "Reward"
	reward.AnchorPoint = Vector2.new(0.5, 1)
	reward.Position = UDim2.fromOffset(x, y)
	reward.AutomaticSize = Enum.AutomaticSize.XY
	reward.BackgroundTransparency = 1
	reward.Parent = screen
	line(reward, 4, Enum.FillDirection.Horizontal)

	if icon then
		local picture = glyph("Icon", icon, 20, THEME.warning)
		picture.LayoutOrder = 1
		picture.Parent = reward
	end

	local amount = words("Amount", text, 20, true)
	amount.LayoutOrder = 2
	amount.TextColor3 = THEME.warning
	amount.Parent = reward

	local rim = Instance.new("UIStroke")
	rim.Color = THEME.outline
	rim.Thickness = 2
	rim.Parent = amount

	tween(reward, FLOAT, { Position = UDim2.fromOffset(x, y - FLOAT_RISE) })
	tween(amount, FLOAT, { TextTransparency = 1 })
	tween(rim, FLOAT, { Transparency = 1 }).Completed:Once(function()
		reward:Destroy()
	end)
end

-- N26: a compact card slides in at the right edge with a tick when a step of
-- a quest is done; a newer one replaces it.
local function createObjectives(screen: ScreenGui)
	local ticket = 0

	local card = Instance.new("CanvasGroup")
	card.Name = "Objective"
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(1, 0, OBJECTIVE_HEIGHT, 0)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundColor3 = THEME.surface
	card.GroupTransparency = 1
	card.Visible = false
	card.Parent = screen
	round(card, 10)
	outline(card)
	pad(card, 12, 12)
	line(card, 12, Enum.FillDirection.Horizontal)

	local tick = glyph("Tick", ICON.done, 20, THEME.success)
	tick.LayoutOrder = 1
	tick.Parent = card

	local column = Instance.new("Frame")
	column.Name = "Words"
	column.LayoutOrder = 2
	column.AutomaticSize = Enum.AutomaticSize.XY
	column.BackgroundTransparency = 1
	column.Parent = card
	line(column, 4, Enum.FillDirection.Vertical)

	local caption = words("Caption", "Objective complete", 12, false)
	caption.LayoutOrder = 1
	caption.TextColor3 = THEME.textMuted
	caption.Parent = column

	local step = words("Step", "", 14, true)
	step.LayoutOrder = 2
	step.Parent = column

	local function complete(text: string)
		ticket += 1
		local mine = ticket
		step.Text = text
		card.Visible = true
		local start = if GuiService.ReducedMotionEnabled then -16 else 24
		card.Position = UDim2.new(1, start, OBJECTIVE_HEIGHT, 0)
		local rest = UDim2.new(1, -16, OBJECTIVE_HEIGHT, 0)
		tween(card, ARRIVE, { Position = rest, GroupTransparency = 0 })
		task.delay(OBJECTIVE_HOLD, function()
			if mine ~= ticket then
				return
			end
			tween(card, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
				if mine == ticket then
					card.Visible = false
				end
			end)
		end)
	end

	return {
		complete = complete,
		destroy = function()
			ticket += 1
			card:Destroy()
		end,
	}
end

-- N27: a bell with an unread count; tapping it opens the saved messages,
-- newest first, and marks them read. Nothing interrupts play.
local function createInbox(screen: ScreenGui)
	local unread = 0
	local messages: { string } = {}
	local connections: { RBXScriptConnection } = {}

	local bell = Instance.new("ImageButton")
	bell.Name = "Inbox"
	bell.AnchorPoint = Vector2.new(1, 0)
	bell.Position = UDim2.new(1, -16, 0, 16)
	bell.Size = UDim2.fromOffset(44, 44)
	bell.AutoButtonColor = false
	bell.BackgroundColor3 = THEME.surface
	bell.Image = ""
	bell.Parent = screen
	round(bell, 10)
	outline(bell)

	local mark = glyph("Bell", ICON.bell, 20, THEME.text)
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Parent = bell

	local badge = words("Badge", "", 12, true)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(1, 0)
	badge.BackgroundColor3 = THEME.error
	badge.BackgroundTransparency = 0
	badge.Visible = false
	badge.Parent = bell
	pill(badge)
	pad(badge, 0, 4)

	local panel = Instance.new("Frame")
	panel.Name = "Messages"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 68)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.Size = UDim2.fromOffset(280, 0)
	panel.BackgroundColor3 = THEME.surface
	panel.Visible = false
	panel.Parent = screen
	round(panel, 10)
	outline(panel)
	pad(panel, 8, 12)
	line(panel, 4, Enum.FillDirection.Vertical)

	local function paint()
		badge.Text = if unread > 9 then "9+" else tostring(unread)
		badge.Visible = unread > 0
	end

	local function draw()
		for _, child in panel:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for index, text in messages do
			local row = words(`Message{index}`, text, 14, false)
			row.LayoutOrder = index
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.Size = UDim2.fromScale(1, 0)
			row.TextWrapped = true
			row.Parent = panel
		end
		if #messages == 0 then
			local empty = words("Empty", "No messages yet", 12, false)
			empty.TextColor3 = THEME.textMuted
			empty.Parent = panel
		end
	end

	local function push(text: string)
		table.insert(messages, 1, text)
		if #messages > INBOX_KEEP then
			table.remove(messages)
		end
		if panel.Visible then
			draw()
		else
			unread += 1
			paint()
		end
	end

	table.insert(connections, bell.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			unread = 0
			paint()
			draw()
		end
	end))
	table.insert(connections, bell.MouseEnter:Connect(function()
		bell.BackgroundColor3 = THEME.edge
	end))
	table.insert(connections, bell.MouseLeave:Connect(function()
		bell.BackgroundColor3 = THEME.surface
	end))

	return {
		push = push,
		unread = function()
			return unread
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			bell:Destroy()
			panel:Destroy()
		end,
	}
end

-- N29: one subtitle line near the bottom centre, the speaker's name first;
-- a new line replaces the old one.
local function createCaptions(screen: ScreenGui)
	local ticket = 0

	local strip = Instance.new("Frame")
	strip.Name = "Caption"
	strip.AnchorPoint = Vector2.new(0.5, 1)
	strip.Position = UDim2.new(0.5, 0, 1, -96)
	strip.AutomaticSize = Enum.AutomaticSize.XY
	strip.BackgroundColor3 = THEME.caption
	strip.BackgroundTransparency = 1
	strip.Visible = false
	strip.Parent = screen
	round(strip, 6)
	pad(strip, 8, 12)
	line(strip, 8, Enum.FillDirection.Horizontal)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(640, math.huge)
	bounds.Parent = strip

	local speaker = words("Speaker", "", 16, true)
	speaker.LayoutOrder = 1
	speaker.TextColor3 = THEME.action
	speaker.Parent = strip

	local said = words("Line", "", 16, false)
	said.LayoutOrder = 2
	said.TextWrapped = true
	said.Parent = strip

	local function say(text: string, name: string?)
		ticket += 1
		local mine = ticket
		speaker.Text = name or ""
		speaker.Visible = name ~= nil
		said.Text = text
		strip.Visible = true
		tween(strip, ENTER, { BackgroundTransparency = CAPTION_DIM })
		task.delay(readingTime(text), function()
			if mine == ticket then
				strip.Visible = false
				strip.BackgroundTransparency = 1
			end
		end)
	end

	return {
		say = say,
		destroy = function()
			ticket += 1
			strip:Destroy()
		end,
	}
end

-- N30: the screen's edges flash the severity colour for a moment, for danger
-- the player must notice without reading, such as low health.
local function flashEdges(screen: ScreenGui, severity: Severity?)
	local colour = THEME[severity or "error"]
	local frame = Instance.new("Frame")
	frame.Name = "EdgeFlash"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = screen

	-- Each edge is a strip whose gradient fades toward the middle of the screen;
	-- the rotation points the opaque end at the edge.
	local across, down = UDim2.fromScale(1, EDGE_DEPTH), UDim2.fromScale(EDGE_DEPTH, 1)
	local sides = {
		{ name = "Top", size = across, at = UDim2.fromScale(0, 0), turn = 90 },
		{ name = "Bottom", size = across, at = UDim2.fromScale(0, 1 - EDGE_DEPTH), turn = -90 },
		{ name = "Left", size = down, at = UDim2.fromScale(0, 0), turn = 0 },
		{ name = "Right", size = down, at = UDim2.fromScale(1 - EDGE_DEPTH, 0), turn = 180 },
	}
	local strips: { Frame } = {}
	for _, side in sides do
		local strip = Instance.new("Frame")
		strip.Name = side.name
		strip.Size = side.size
		strip.Position = side.at
		strip.BackgroundColor3 = colour
		strip.BackgroundTransparency = 1
		strip.BorderSizePixel = 0
		strip.Parent = frame

		local fade = Instance.new("UIGradient")
		fade.Rotation = side.turn
		fade.Transparency = NumberSequence.new(0, 1)
		fade.Parent = strip
		table.insert(strips, strip)
	end

	for index, strip in strips do
		tween(strip, FLASH_IN, { BackgroundTransparency = EDGE_PEAK }).Completed:Once(function()
			local out = tween(strip, FLASH_OUT, { BackgroundTransparency = 1 })
			if index == #strips then
				out.Completed:Once(function()
					frame:Destroy()
				end)
			end
		end)
	end
end

return {
	showAchievement = showAchievement,
	createAnnouncer = createAnnouncer,
	createSnackbar = createSnackbar,
	createFeed = createFeed,
	createIsland = createIsland,
	floatText = floatText,
	createObjectives = createObjectives,
	createInbox = createInbox,
	createCaptions = createCaptions,
	flashEdges = flashEdges,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/checkboxes.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local THEME = {
	row = Color3.fromRGB(31, 34, 41),
	rowHover = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	mark = Color3.fromRGB(243, 245, 248),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(118, 125, 139),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
	swatchRed = Color3.fromRGB(208, 88, 82),
	swatchGold = Color3.fromRGB(214, 158, 62),
	swatchGreen = Color3.fromRGB(72, 178, 112),
	swatchBlue = Color3.fromRGB(88, 141, 214),
	swatchPurple = Color3.fromRGB(150, 110, 214),
}

local ICON = {
	check = "rbxassetid://86817768619372",
	dash = "rbxassetid://95070996149109",
	tile = "rbxassetid://106101842173393",
	cross = "rbxassetid://116396312853810",
	star = "rbxassetid://72669221096319",
}

-- C18's colours when the caller names none.
local DEFAULT_SWATCHES = {
	Red = THEME.swatchRed,
	Gold = THEME.swatchGold,
	Green = THEME.swatchGreen,
	Blue = THEME.swatchBlue,
	Purple = THEME.swatchPurple,
}

local STATE_MOTION = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DRAW_MOTION = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_MOTION = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local NO_MOTION = TweenInfo.new(0)

export type BoxStyle = "C1" | "C2" | "C3" | "C5" | "C6" | "C7" | "C11" | "C12" | "C13" | "C14"
type FirstGroups = "C4" | "C8" | "C9" | "C10"
export type GroupStyle = FirstGroups | "C15" | "C16" | "C17" | "C18" | "C19" | "C20"

-- C7 reads `description`, C12 `count`; C10 reads `icons`, C18 `colours` and C20
-- `descriptions`, each keyed by item name.
export type CheckDetails = {
	description: string?,
	count: number?,
	icons: { [string]: string }?,
	colours: { [string]: Color3 }?,
	descriptions: { [string]: string }?,
}

export type Checkbox = {
	row: TextButton,
	set: (value: boolean) -> (),
	get: () -> boolean,
	setEnabled: (enabled: boolean) -> (),
	destroy: () -> (),
}

export type CheckGroup = {
	frame: Frame,
	set: (name: string, on: boolean) -> (),
	selected: () -> { string },
	destroy: () -> (),
}

-- Before the row is parented there is nothing on screen to animate, so the
-- first paint assigns directly instead of easing in from the defaults.
local function animate(instance: Instance, goals: { [string]: any }, timing: TweenInfo?)
	if not instance:IsDescendantOf(game) then
		for property, goal in goals do
			(instance :: any)[property] = goal
		end
		return
	end
	local chosen = if GuiService.ReducedMotionEnabled then NO_MOTION else timing or STATE_MOTION
	TweenService:Create(instance, chosen, goals):Play()
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function newFrame(name: string, size: UDim2, colour: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	return frame
end

local function newIcon(name: string, size: number, image: string): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.Image = image
	icon.ImageColor3 = THEME.mark
	return icon
end

local function newLabel(name: string, text: string, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	return label
end

-- Returns the modifiers too, so a style can reshape the row without searching it.
local function row(name: string, height: number): (TextButton, UICorner, UIListLayout, UIPadding)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = false
	button.Text = ""
	button.Size = UDim2.new(1, 0, 0, height)
	button.BackgroundColor3 = THEME.row
	button.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = button

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = button
	return button, corner, layout, padding
end

local function fill(target: GuiObject)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = target
end

-- Hover, press and focus are separate flags, so losing hover never clears
-- focus and a repaint keeps both.
local function watchStates(
	button: GuiButton,
	connections: { RBXScriptConnection },
	paint: (hovered: boolean, pressed: boolean) -> ()
)
	local hovered, pressed = false, false
	local ring = Instance.new("UIStroke")
	ring.Name = "FocusRing"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		hovered = true
		paint(hovered, pressed)
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint(hovered, pressed)
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressed = true
			paint(hovered, pressed)
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		pressed = false
		paint(hovered, pressed)
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
end

local function surface(hovered: boolean, pressed: boolean): Color3
	return if pressed then THEME.row elseif hovered then THEME.rowHover else THEME.row
end

-- The 22 px box every square style shares; the styles differ in how the tick
-- arrives, whether the box fills, and which side of the label it sits on.
local function newBox(order: number, radius: UDim): (Frame, UIStroke)
	local box = newFrame("Box", UDim2.fromOffset(22, 22), THEME.row)
	box.LayoutOrder = order
	round(box, radius)

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.edge
	outline.Thickness = 2
	outline.Parent = box
	return box, outline
end

-- C1: the tick is uncovered left to right by a clipping strip, like a pen stroke.
local function drawSkin(button: TextButton): (boolean) -> ()
	local box, outline = newBox(0, UDim.new(0, 6))
	box.Parent = button

	local reveal = newFrame("Reveal", UDim2.fromOffset(0, 16), THEME.row)
	reveal.AnchorPoint = Vector2.new(0, 0.5)
	reveal.Position = UDim2.new(0, 3, 0.5, 0)
	reveal.BackgroundTransparency = 1
	reveal.ClipsDescendants = true
	reveal.Parent = box

	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.Position = UDim2.fromScale(0, 0)
	tick.Parent = reveal

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(reveal, { Size = UDim2.fromOffset(if on then 16 else 0, 16) }, DRAW_MOTION)
	end
end

-- C2: the box never fills; the outline and the tick take the accent.
local function outlineSkin(button: TextButton): (boolean) -> ()
	local box, outline = newBox(0, UDim.new(0, 6))
	box.BackgroundTransparency = 1
	box.Parent = button

	local tick = newIcon("Tick", 16, ICON.check)
	tick.ImageColor3 = THEME.focus
	tick.Parent = box

	return function(on: boolean)
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end
end

-- C3, C5 and C6 share a filled box with a fading tick; `order` puts the box
-- before (0) or after (2) the label.
local function filledSkin(button: TextButton, order: number): ((boolean) -> (), Frame, ImageLabel)
	local box, outline = newBox(order, UDim.new(0, 6))
	box.Parent = button

	local tick = newIcon("Tick", 16, ICON.check)
	tick.Parent = box

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end,
		box,
		tick
end

-- C5: a to-do line; ticking it strikes the words through and mutes them.
local function strikeSkin(button: TextButton, label: TextLabel, text: string): (boolean) -> ()
	local paintBox = filledSkin(button, 0)
	label.RichText = true
	return function(on: boolean)
		paintBox(on)
		label.Text = if on then `<s>{text}</s>` else text
		label.TextColor3 = if on then THEME.textMuted else THEME.text
	end
end

-- C6: the box pops from 85 % with one small overshoot when ticked.
local function popSkin(button: TextButton): (boolean) -> ()
	local paintBox, box = filledSkin(button, 0)
	local scale = Instance.new("UIScale")
	scale.Parent = box
	return function(on: boolean)
		paintBox(on)
		if on and box:IsDescendantOf(game) and not GuiService.ReducedMotionEnabled then
			scale.Scale = 0.85
			TweenService:Create(scale, POP_MOTION, { Scale = 1 }):Play()
		end
	end
end

-- C7: a card with a title, one short line, and a round tick badge in its corner.
local function cardSkin(button: TextButton, label: TextLabel, description: string): (boolean) -> ()
	button.Size = UDim2.new(1, 0, 0, 64)
	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = button

	local column = newFrame("Labels", UDim2.fromScale(0, 1), THEME.row)
	column.LayoutOrder = 1
	column.BackgroundTransparency = 1
	column.Parent = button
	fill(column)

	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.Padding = UDim.new(0, 4)
	stack.Parent = column

	label.Size = UDim2.new(1, 0, 0, 16)
	label.Parent = column

	local detail = newLabel("Description", description, 12)
	detail.LayoutOrder = 2
	detail.Size = UDim2.new(1, 0, 0, 16)
	detail.FontFace = Font.fromEnum(Enum.Font.Gotham)
	detail.TextColor3 = THEME.textMuted
	detail.Parent = column

	local badge = newFrame("Badge", UDim2.fromOffset(24, 24), THEME.row)
	badge.LayoutOrder = 2
	round(badge, UDim.new(0.5, 0))
	badge.Parent = button

	local ring = Instance.new("UIStroke")
	ring.Color = THEME.edge
	ring.Thickness = 2
	ring.Parent = badge

	local tick = newIcon("Tick", 14, ICON.check)
	tick.Parent = badge

	return function(on: boolean)
		animate(edge, { Color = if on then THEME.accent else THEME.edge })
		animate(badge, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(ring, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end
end

-- C11: no box at all; a tick appears at the right end of a chosen row.
local function rightTickSkin(button: TextButton, label: TextLabel): (boolean) -> ()
	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 2
	tick.ImageColor3 = THEME.focus
	tick.Parent = button

	return function(on: boolean)
		tick.ImageTransparency = if on then 0 else 1
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

-- C12: a filled box plus a count at the end of the row, such as matching items.
local function countSkin(button: TextButton, count: number): (boolean) -> ()
	local paintBox = filledSkin(button, 0)
	local badge = newLabel("Count", tostring(count), 12)
	badge.LayoutOrder = 2
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.Size = UDim2.fromScale(0, 1)
	badge.TextColor3 = THEME.textMuted
	badge.Parent = button

	return function(on: boolean)
		paintBox(on)
		badge.TextColor3 = if on then THEME.text else THEME.textMuted
	end
end

-- C13: an exclude list; the chosen box fills red with a cross, not a tick.
local function crossSkin(button: TextButton, label: TextLabel): (boolean) -> ()
	local box, outline = newBox(0, UDim.new(0, 6))
	box.Parent = button

	local cross = newIcon("Cross", 16, ICON.cross)
	cross.Parent = box

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.danger else THEME.row })
		animate(outline, { Color = if on then THEME.danger else THEME.edge })
		animate(cross, { ImageTransparency = if on then 0 else 1 })
		label.TextColor3 = if on then THEME.textMuted else THEME.text
	end
end

-- C14: a thumb-sized 32 px box for touch-first screens.
local function bigBoxSkin(button: TextButton): (boolean) -> ()
	local box = newFrame("Box", UDim2.fromOffset(32, 32), THEME.row)
	box.LayoutOrder = 0
	round(box, UDim.new(0, 6))
	box.Parent = button

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.edge
	outline.Thickness = 2
	outline.Parent = box

	local tick = newIcon("Tick", 20, ICON.check)
	tick.Parent = box

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end
end

local function createCheckbox(
	parent: GuiObject,
	labelText: string,
	style: BoxStyle,
	initial: boolean,
	onChanged: (boolean) -> (),
	details: CheckDetails?
): Checkbox
	local value = initial
	local enabled = true
	local connections: { RBXScriptConnection } = {}

	local button = row(labelText, 44)
	local label = newLabel("Label", labelText, 14)
	label.LayoutOrder = 1
	label.Size = UDim2.fromScale(0, 1)
	label.Parent = button
	fill(label)

	local paintValue: (boolean) -> ()
	if style == "C1" then
		paintValue = drawSkin(button)
	elseif style == "C2" then
		paintValue = outlineSkin(button)
	elseif style == "C3" then
		paintValue = filledSkin(button, 2)
	elseif style == "C5" then
		paintValue = strikeSkin(button, label, labelText)
	elseif style == "C6" then
		paintValue = popSkin(button)
	elseif style == "C7" then
		local description = if details and details.description then details.description else ""
		paintValue = cardSkin(button, label, description)
	end

	if style == "C11" then
		paintValue = rightTickSkin(button, label)
	elseif style == "C12" then
		paintValue = countSkin(button, if details and details.count then details.count else 0)
	elseif style == "C13" then
		paintValue = crossSkin(button, label)
	elseif style == "C14" then
		paintValue = bigBoxSkin(button)
	end

	local function paintRow(hovered: boolean, pressed: boolean)
		animate(button, { BackgroundColor3 = surface(hovered, pressed) })
		if style ~= "C5" and style ~= "C13" then
			label.TextColor3 = if enabled then THEME.text else THEME.textMuted
		end
	end
	watchStates(button, connections, paintRow)

	local function set(next: boolean)
		if not enabled or next == value then
			return
		end
		value = next
		paintValue(value)
		onChanged(value)
	end
	table.insert(connections, button.Activated:Connect(function()
		set(not value)
	end))

	paintRow(false, false)
	paintValue(value)
	button.Parent = parent

	return {
		row = button,
		set = set,
		get = function()
			return value
		end,
		setEnabled = function(next: boolean)
			enabled = next
			button.Active = next
			button.Interactable = next
			paintRow(false, false)
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			button:Destroy()
		end,
	}
end

type Item = {
	button: TextButton,
	paint: (on: boolean) -> (),
}

-- C8: a ring with a dot for the one chosen option.
local function radioItem(button: TextButton): (boolean) -> ()
	local socket = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	socket.LayoutOrder = 0
	round(socket, UDim.new(0.5, 0))
	socket.Parent = button

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.edge
	outline.Thickness = 2
	outline.Parent = socket

	local dot = newFrame("Dot", UDim2.fromOffset(10, 10), THEME.accent)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	round(dot, UDim.new(0.5, 0))
	dot.Parent = socket

	return function(on: boolean)
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(dot, { BackgroundTransparency = if on then 0 else 1 })
	end
end

-- C9: a pill that fills and shows a tick; the label keeps its words.
local function chipItem(button: TextButton, corner: UICorner): (boolean) -> ()
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 44)
	corner.CornerRadius = UDim.new(0.5, 0)

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = button

	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 0
	tick.ImageColor3 = THEME.focus
	tick.Parent = button

	return function(on: boolean)
		tick.Visible = on
		edge.Color = if on then THEME.accent else THEME.edge
		animate(button, { BackgroundColor3 = if on then THEME.accentDim else THEME.row })
	end
end

-- C10: a square tile with an icon over its name, ticked in the corner.
local function tileItem(
	button: TextButton,
	layout: UIListLayout,
	label: TextLabel,
	image: string
): (boolean) -> ()
	button.Size = UDim2.fromOffset(88, 88)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2.new(1, 0, 0, 16)
	label.TextSize = 12

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = button

	local glyph = newIcon("Glyph", 24, image)
	glyph.AnchorPoint = Vector2.zero
	glyph.LayoutOrder = 0
	glyph.ImageColor3 = THEME.textMuted
	glyph.Parent = button

	local badge = newFrame("Badge", UDim2.fromOffset(20, 20), THEME.accent)
	badge.AnchorPoint = Vector2.new(0, 1)
	badge.Position = UDim2.new(1, -4, 0, 4)
	round(badge, UDim.new(0.5, 0))
	badge.Parent = glyph

	local tick = newIcon("Tick", 12, ICON.check)
	tick.Parent = badge

	return function(on: boolean)
		badge.Visible = on
		edge.Color = if on then THEME.accent else THEME.edge
		animate(glyph, { ImageColor3 = if on then THEME.focus else THEME.textMuted })
		animate(button, { BackgroundColor3 = if on then THEME.accentDim else THEME.row })
	end
end

-- C16 and C19 sit in one rounded track; the CanvasGroup rounds the segments,
-- because a UICorner on the track would not round its children. The segments
-- live in their own row so C19's marker can sit behind them outside the layout.
local function newTrack(frame: Frame): (CanvasGroup, Frame)
	local track = Instance.new("CanvasGroup")
	track.Name = "Track"
	track.AutomaticSize = Enum.AutomaticSize.X
	track.Size = UDim2.fromOffset(0, 36)
	track.BackgroundColor3 = THEME.edge
	track.BorderSizePixel = 0
	round(track, UDim.new(0, 6))
	track.Parent = frame

	local segments = newFrame("Segments", UDim2.fromOffset(0, 36), THEME.row)
	segments.AutomaticSize = Enum.AutomaticSize.X
	segments.BackgroundTransparency = 1
	segments.ZIndex = 2
	segments.Parent = track

	local line = Instance.new("UIListLayout")
	line.FillDirection = Enum.FillDirection.Horizontal
	line.SortOrder = Enum.SortOrder.LayoutOrder
	line.Parent = segments
	return track, segments
end

-- C16: joined buttons for picking several; each chosen one fills and ticks.
local function segmentItem(button: TextButton, corner: UICorner): (boolean) -> ()
	corner:Destroy()
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 36)
	button.BackgroundColor3 = THEME.row

	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 0
	tick.ImageColor3 = THEME.focus
	tick.Parent = button

	return function(on: boolean)
		tick.Visible = on
		animate(button, { BackgroundColor3 = if on then THEME.accentDim else THEME.row })
	end
end

-- C17: star buttons; the rating is how many are lit, set by the parent group.
local function starItem(button: TextButton, label: TextLabel, corner: UICorner): (boolean) -> ()
	corner:Destroy()
	button.Size = UDim2.fromOffset(44, 44)
	button.BackgroundTransparency = 1
	label.Visible = false

	local star = newIcon("Star", 24, ICON.star)
	star.AnchorPoint = Vector2.zero
	star.LayoutOrder = 0
	star.ImageColor3 = THEME.edge
	star.Parent = button

	return function(lit: boolean)
		animate(star, { ImageColor3 = if lit then THEME.swatchGold else THEME.edge })
	end
end

-- C18: round colour dots; the chosen dot gets a ring and a tick.
local function swatchItem(
	button: TextButton,
	label: TextLabel,
	corner: UICorner,
	colour: Color3
): (boolean) -> ()
	corner.CornerRadius = UDim.new(0.5, 0)
	button.Size = UDim2.fromOffset(44, 44)
	button.BackgroundColor3 = colour
	label.Visible = false

	local ring = Instance.new("UIStroke")
	ring.Name = "Ring"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.mark
	ring.Thickness = 3
	ring.Parent = button

	local tick = newIcon("Tick", 20, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 0
	tick.Parent = button

	return function(on: boolean)
		ring.Enabled = on
		tick.Visible = on
	end
end

-- C19: equal-width segments for one choice, such as S, M and L; the marker
-- behind the chosen one is placed by the parent group.
local function sizeItem(button: TextButton, label: TextLabel, corner: UICorner): (boolean) -> ()
	corner:Destroy()
	button.Size = UDim2.fromOffset(64, 36)
	button.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Center

	return function(on: boolean)
		label.TextColor3 = if on then THEME.mark else THEME.textMuted
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

-- C4, C8, C9 and C10 own several options at once. C4 adds a "Select all"
-- header whose box shows none, some (a dash) or all (a tick).
local function createCheckGroup(
	parent: GuiObject,
	names: { string },
	style: GroupStyle,
	initial: { string },
	onChanged: (selected: { string }) -> (),
	details: CheckDetails?
): CheckGroup
	local connections: { RBXScriptConnection } = {}
	local chosen: { [string]: boolean } = {}
	local items: { [string]: Item } = {}
	for _, name in initial do
		chosen[name] = true
	end

	local frame = newFrame("Choices", UDim2.fromScale(1, 0), THEME.row)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = frame
	if style == "C9" or style == "C10" or style == "C18" then
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Wraps = true
	elseif style == "C17" then
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
	end

	-- One choice at a time; the rest pick several.
	local single = style == "C8"
		or style == "C17"
		or style == "C18"
		or style == "C19"
		or style == "C20"
	local holder: GuiObject = frame
	local marker: Frame? = nil
	if style == "C16" or style == "C19" then
		local track, segments = newTrack(frame)
		holder = segments
		if style == "C19" then
			local slide = newFrame("Marker", UDim2.fromOffset(64, 36), THEME.accent)
			slide.ZIndex = 1
			slide.Parent = track
			marker = slide
		end
	end

	local function selected(): { string }
		local list = {}
		for _, name in names do
			if chosen[name] then
				table.insert(list, name)
			end
		end
		return list
	end

	local paintHeader: (() -> ())? = nil

	-- C17 lights every star up to the chosen one; C19 slides its marker there.
	local function repaint()
		local rating = 0
		for index, name in names do
			if chosen[name] then
				rating = index
			end
		end
		for index, name in names do
			local item = items[name]
			if style == "C17" then
				item.paint(index <= rating)
			else
				item.paint(chosen[name] == true)
			end
		end
		if marker then
			marker.Visible = rating > 0
			animate(marker, { Position = UDim2.fromOffset((math.max(rating, 1) - 1) * 64, 0) })
		end
		if paintHeader then
			paintHeader()
		end
	end

	local function set(name: string, on: boolean)
		if not items[name] or (chosen[name] == true) == on then
			return
		end
		if single then
			if not on then
				return
			end
			table.clear(chosen)
		end
		chosen[name] = if on then true else nil
		repaint()
		onChanged(selected())
	end

	if style == "C4" then
		local header = row("SelectAll", 44)
		header.LayoutOrder = 0
		header.Parent = frame
		local paintBox, _, mark = filledSkin(header, 0)

		local title = newLabel("Label", "Select all", 14)
		title.LayoutOrder = 1
		title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		title.Size = UDim2.fromScale(0, 1)
		title.Parent = header
		fill(title)

		paintHeader = function()
			local count = #selected()
			paintBox(count > 0)
			mark.Image = if count == #names then ICON.check else ICON.dash
		end
		watchStates(header, connections, function(hovered, pressed)
			animate(header, { BackgroundColor3 = surface(hovered, pressed) })
		end)
		table.insert(connections, header.Activated:Connect(function()
			local everything = #selected() == #names
			for _, name in names do
				chosen[name] = if everything then nil else true
			end
			repaint()
			onChanged(selected())
		end))
	end

	-- C15: a heading that counts what is done, over a bar that fills with it.
	if style == "C15" then
		local header = newFrame("Progress", UDim2.new(1, 0, 0, 32), THEME.row)
		header.LayoutOrder = 0
		header.BackgroundTransparency = 1
		header.Parent = frame

		local summary = newLabel("Summary", "", 12)
		summary.Size = UDim2.new(1, 0, 0, 16)
		summary.TextColor3 = THEME.textMuted
		summary.Parent = header

		local bar = newFrame("Bar", UDim2.new(1, 0, 0, 4), THEME.edge)
		bar.Position = UDim2.fromOffset(0, 24)
		round(bar, UDim.new(0.5, 0))
		bar.Parent = header

		local done = newFrame("Fill", UDim2.fromScale(0, 1), THEME.accent)
		round(done, UDim.new(0.5, 0))
		done.Parent = bar

		paintHeader = function()
			local count = #selected()
			summary.Text = `{count} of {#names} done`
			animate(done, { Size = UDim2.fromScale(if #names > 0 then count / #names else 0, 1) })
		end
	end

	for index, name in names do
		local button, corner, rowLayout, padding = row(name, 44)
		button.LayoutOrder = index
		local label = newLabel("Label", name, 14)
		label.LayoutOrder = 1
		label.Size = UDim2.fromScale(0, 1)
		label.Parent = button

		local paint: (boolean) -> ()
		if style == "C4" then
			padding.PaddingLeft = UDim.new(0, 32)
			fill(label)
			paint = filledSkin(button, 0)
		elseif style == "C8" then
			fill(label)
			paint = radioItem(button)
		elseif style == "C9" then
			label.AutomaticSize = Enum.AutomaticSize.X
			paint = chipItem(button, corner)
		elseif style == "C10" then
			local icons = if details and details.icons then details.icons else {}
			paint = tileItem(button, rowLayout, label, icons[name] or ICON.tile)
		elseif style == "C15" then
			fill(label)
			paint = strikeSkin(button, label, name)
		elseif style == "C16" then
			label.AutomaticSize = Enum.AutomaticSize.X
			paint = segmentItem(button, corner)
		end
		if style == "C17" then
			paint = starItem(button, label, corner)
		elseif style == "C18" then
			local colours = details and details.colours or DEFAULT_SWATCHES
			paint = swatchItem(button, label, corner, colours[name] or THEME.edge)
		elseif style == "C19" then
			fill(label)
			paint = sizeItem(button, label, corner)
		elseif style == "C20" then
			local descriptions = details and details.descriptions or {}
			paint = cardSkin(button, label, descriptions[name] or "")
		end

		items[name] = { button = button, paint = paint }
		-- Chips, tiles and segments fill when chosen, so hover must not paint over
		-- that; stars, swatches and sizes never take a row surface at all.
		local filledWhenChosen = style == "C9" or style == "C10" or style == "C16"
		local bare = style == "C17" or style == "C18" or style == "C19"
		watchStates(button, connections, function(hovered, pressed)
			if not bare and not (filledWhenChosen and chosen[name]) then
				animate(button, { BackgroundColor3 = surface(hovered, pressed) })
			end
		end)
		table.insert(connections, button.Activated:Connect(function()
			set(name, if single then true else not chosen[name])
		end))
		button.Parent = holder
	end

	repaint()
	frame.Parent = parent

	return {
		frame = frame,
		set = set,
		selected = selected,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			frame:Destroy()
		end,
	}
end

return {
	createCheckbox = createCheckbox,
	createCheckGroup = createCheckGroup,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/dropdowns.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

type FirstSix = "D1" | "D2" | "D3" | "D4" | "D5" | "D6"
type SecondSix = "D7" | "D8" | "D9" | "D10" | "D11" | "D12"
type LaterStyles = "D13" | "D14" | "D15" | "D16" | "D17" | "D18" | "D19" | "D20" | "D21" | "D22"
export type DropdownStyle = FirstSix | SecondSix | LaterStyles

-- `text` is the value handed to onChanged; `display` is what the row shows
-- when it should differ (D10 shows a display name for a unique username).
-- D8 reads `group`, D9 and D18 `icon`, D12 `colour`, D13 `detail` and D21
-- `children`; D10 fills `image` itself.
export type Choice = {
	text: string,
	display: string?,
	detail: string?,
	icon: string?,
	image: string?,
	group: string?,
	colour: Color3?,
	children: { string | Choice }?,
}

-- `label` names what the field is for and is its placeholder. `host` is the
-- ScreenGui the list opens above; by default the field's own ScreenGui. D19
-- calls `onRun` with the chosen value; D22 calls `onCreate` with a new one.
export type DropdownSpec = {
	label: string,
	options: { string | Choice },
	chosen: { string }?,
	onChanged: (chosen: { string }) -> (),
	onRun: ((chosen: string) -> ())?,
	onCreate: ((text: string) -> ())?,
	host: ScreenGui?,
}

export type Dropdown = {
	root: Frame,
	get: () -> { string },
	set: (chosen: { string }) -> (),
	setOptions: (options: { string | Choice }) -> (),
	open: () -> (),
	close: () -> (),
	destroy: () -> (),
}

local THEME = {
	field = Color3.fromRGB(31, 34, 41),
	fieldHover = Color3.fromRGB(44, 48, 57),
	surface = Color3.fromRGB(44, 48, 57),
	rowHover = Color3.fromRGB(63, 68, 79),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	scrim = Color3.fromRGB(0, 0, 0),
}

local ICON = {
	chevronDown = "rbxassetid://71457658246709",
	chevronLeft = "rbxassetid://102314312897830",
	chevronRight = "rbxassetid://101007429951147",
	check = "rbxassetid://86817768619372",
	search = "rbxassetid://72296609649861",
	plus = "rbxassetid://101123124881873",
}

local ROW = 44
local TWO_LINE_ROW = 56
local GRID_CELL = 72
local GRID_COLUMNS = 3
local RECENT_LIMIT = 3
local SCRIM_TRANSPARENCY = 0.5
local VISIBLE_ROWS = 5
local LIST_GAP = 4
local SUGGESTIONS = 6
local PALETTE_WIDTH = 480
local OPEN = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SHUT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

-- The styles that let the player pick several at once.
local MULTI = { D3 = true, D4 = true, D20 = true }

-- The styles whose field is a text box the player types into.
local TYPED = { D2 = true, D5 = true, D17 = true, D22 = true }

-- Rich text treats these as markup; a typed "<" must show as itself.
local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function animate(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
	local chosen = if GuiService.ReducedMotionEnabled then INSTANT else timing
	local tween = TweenService:Create(target, chosen, goals)
	tween:Play()
	return tween
end

local function round(target: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
end

local function outline(target: GuiObject): UIStroke
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = target
	return edge
end

local function pad(target: GuiObject, vertical: number, horizontal: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, vertical)
	padding.PaddingBottom = UDim.new(0, vertical)
	padding.PaddingLeft = UDim.new(0, horizontal)
	padding.PaddingRight = UDim.new(0, horizontal)
	padding.Parent = target
end

local function lineUp(target: GuiObject, direction: Enum.FillDirection, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = target
	return layout
end

local function fill(target: GuiObject)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = target
end

local function newText(name: string, text: string, size: number, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	return label
end

local function newIcon(name: string, image: string, size: number, order: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.LayoutOrder = order
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.Image = image
	icon.ImageColor3 = THEME.textMuted
	return icon
end

local function toChoice(option: string | Choice): Choice
	return if type(option) == "string" then { text = option } else option
end

-- Case-insensitive, and plain: a player typing "[" must not break the search.
local function matches(choice: Choice, query: string): boolean
	if query == "" then
		return true
	end
	local haystack = string.lower(`{choice.display or choice.text} {choice.detail or ""}`)
	return haystack:find(query:lower(), 1, true) ~= nil
end

local function playerChoices(): { Choice }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player ~= Players.LocalPlayer then
			table.insert(list, {
				text = player.Name,
				display = player.DisplayName,
				detail = `@{player.Name}`,
				image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=48&h=48`,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.text:lower() < b.text:lower()
	end)
	return list
end

-- One interactive row or field: hover, press and focus each change something
-- the player can see, and focus survives the pointer leaving.
local function watch(
	button: GuiButton,
	connections: { RBXScriptConnection },
	rest: () -> Color3
)
	local ring = Instance.new("UIStroke")
	ring.Name = "FocusRing"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		button.BackgroundColor3 = THEME.rowHover
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		button.BackgroundColor3 = rest()
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			button.BackgroundColor3 = THEME.field
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		button.BackgroundColor3 = rest()
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
end

local function newBox(name: string, placeholder: string, order: number): TextBox
	local box = Instance.new("TextBox")
	box.Name = name
	box.LayoutOrder = order
	box.Size = UDim2.fromScale(0, 1)
	box.BackgroundTransparency = 1
	box.ClearTextOnFocus = false
	box.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	box.TextSize = 14
	box.TextColor3 = THEME.text
	box.PlaceholderColor3 = THEME.textMuted
	box.PlaceholderText = placeholder
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Text = ""
	fill(box)
	return box
end

local function createDropdown(parent: GuiObject, style: DropdownStyle, spec: DropdownSpec): Dropdown
	local connections: { RBXScriptConnection } = {}
	local rowConnections: { RBXScriptConnection } = {}
	local choices: { Choice } = {}
	local chosen: { string } = table.clone(spec.chosen or {})
	local query = ""
	local isOpen = false
	local ticket = 0
	local multi = MULTI[style] == true

	local root = Instance.new("Frame")
	root.Name = spec.label
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.fromScale(1, 0)
	root.BackgroundTransparency = 1
	lineUp(root, Enum.FillDirection.Vertical, LIST_GAP)

	local function isChosen(text: string): boolean
		return table.find(chosen, text) ~= nil
	end

	local function choiceFor(text: string, within: { string | Choice }?): Choice?
		for _, option in within or choices do
			local choice = toChoice(option)
			if choice.text == text then
				return choice
			end
			local nested = if choice.children then choiceFor(text, choice.children) else nil
			if nested then
				return nested
			end
		end
		return nil
	end

	-- D14 remembers the last few picks; D20 holds picks until Apply; D21 keeps
	-- the path of open sub-menus.
	local recent: { string } = {}
	local pending: { string }? = nil
	local trail: { Choice } = {}

	-- The field. Most styles are one button; the typed styles hold a TextBox,
	-- D7 holds two arrows, and D4 grows to fit its chips.
	local field: GuiObject
	local fieldButton: TextButton? = nil
	local box: TextBox? = nil
	local value: TextLabel? = nil
	local lead: ImageLabel? = nil
	local swatch: Frame? = nil
	local chips: Frame? = nil
	local chevron: ImageLabel? = nil

	local ghost: TextLabel? = nil
	if TYPED[style] then
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, ROW)
		field = frame
		if style == "D5" then
			local glass = newIcon("Search", ICON.search, 16, 0)
			glass.Parent = frame
		end
		local entry = newBox("Search", spec.label, 1)
		entry.Parent = frame
		box = entry

		-- D17 shows the rest of the first match behind the typing, in grey.
		if style == "D17" then
			local hint = newText("Ghost", "", 14, 0)
			hint.Size = UDim2.fromScale(1, 1)
			hint.RichText = true
			hint.TextColor3 = THEME.textMuted
			hint.Parent = entry
			ghost = hint
		end
	elseif style == "D7" or style == "D19" then
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, ROW)
		field = frame
	else
		local button = Instance.new("TextButton")
		button.AutoButtonColor = false
		button.Text = ""
		button.Size = UDim2.new(1, 0, 0, ROW)
		field = button
		fieldButton = button
		if style == "D4" then
			button.AutomaticSize = Enum.AutomaticSize.Y
		end
	end
	field.Name = "Field"
	field.LayoutOrder = 1
	field.BackgroundColor3 = THEME.field
	field.Parent = root
	round(field, 6)
	outline(field)
	pad(field, if style == "D4" then 4 else 0, if style == "D7" or style == "D19" then 0 else 12)
	lineUp(field, Enum.FillDirection.Horizontal, 8)

	if style == "D9" or style == "D10" or style == "D11" then
		local image = if style == "D11" then ICON.search else ""
		local icon = newIcon("Lead", image, if style == "D10" then 24 else 16, 0)
		icon.Parent = field
		lead = icon
	elseif style == "D12" then
		local chip = Instance.new("Frame")
		chip.Name = "Swatch"
		chip.LayoutOrder = 0
		chip.Size = UDim2.fromOffset(20, 20)
		chip.BorderSizePixel = 0
		chip.Parent = field
		round(chip, 6)
		swatch = chip
	end

	if style == "D4" then
		local holder = Instance.new("Frame")
		holder.Name = "Chips"
		holder.LayoutOrder = 1
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.Size = UDim2.fromScale(0, 0)
		holder.BackgroundTransparency = 1
		holder.Parent = field
		fill(holder)
		lineUp(holder, Enum.FillDirection.Horizontal, 4).Wraps = true
		chips = holder
	elseif not box then
		local label = newText("Value", spec.label, 14, 1)
		if style == "D7" then
			label.TextXAlignment = Enum.TextXAlignment.Center
		end
		label.Parent = field
		fill(label)
		value = label
	end

	if style ~= "D5" and style ~= "D7" and style ~= "D11" then
		local mark = newIcon("Chevron", ICON.chevronDown, 16, 2)
		mark.Parent = field
		chevron = mark
	end

	-- D19: the value is a button that runs it; only the arrow opens the list.
	local runButton: TextButton? = nil
	local moreButton: TextButton? = nil
	if style == "D19" then
		local run = Instance.new("TextButton")
		run.Name = "Run"
		run.LayoutOrder = 1
		run.AutoButtonColor = false
		run.Text = ""
		run.Size = UDim2.fromScale(0, 1)
		run.BackgroundColor3 = THEME.field
		run.Parent = field
		round(run, 6)
		pad(run, 0, 12)
		lineUp(run, Enum.FillDirection.Horizontal, 8)
		fill(run)
		if value then
			value.Parent = run
		end
		runButton = run

		local more = Instance.new("TextButton")
		more.Name = "More"
		more.LayoutOrder = 2
		more.AutoButtonColor = false
		more.Text = ""
		more.Size = UDim2.fromOffset(ROW, ROW)
		more.BackgroundColor3 = THEME.field
		more.Parent = field
		round(more, 6)
		local centre = lineUp(more, Enum.FillDirection.Horizontal, 0)
		centre.HorizontalAlignment = Enum.HorizontalAlignment.Center
		if chevron then
			chevron.Parent = more
		end
		moreButton = more
	end

	-- The list: under the field for D6; for the rest, a layer of its own above
	-- the host ScreenGui, so no ScrollingFrame clips it and no ZIndex fight
	-- hides it. The list sits inside a full-screen catcher: a tap outside the
	-- list lands on the catcher and closes it, and the list is Active, so a
	-- tap on it never reaches the catcher.
	local list = Instance.new("CanvasGroup")
	list.Name = "List"
	list.BackgroundColor3 = THEME.surface
	list.GroupTransparency = 1
	list.Visible = false
	round(list, 10)
	outline(list)
	pad(list, LIST_GAP, LIST_GAP)
	lineUp(list, Enum.FillDirection.Vertical, LIST_GAP)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(160, 0)
	bounds.MaxSize = Vector2.new(PALETTE_WIDTH, 320)
	bounds.Parent = list

	local layer: ScreenGui? = nil
	local catcher: TextButton? = nil
	local paletteBox: TextBox? = nil
	if style == "D6" then
		list.LayoutOrder = 2
		list.AutomaticSize = Enum.AutomaticSize.Y
		list.Size = UDim2.fromScale(1, 0)
	else
		local overlay = Instance.new("ScreenGui")
		overlay.Name = "DropdownLayer"
		overlay.ResetOnSpawn = false
		overlay.Enabled = false
		layer = overlay

		local shield = Instance.new("TextButton")
		shield.Name = "Catcher"
		shield.AutoButtonColor = false
		shield.Text = ""
		shield.Selectable = false
		shield.BackgroundTransparency = 1
		shield.Size = UDim2.fromScale(1, 1)
		shield.Parent = overlay
		catcher = shield

		list.Active = true
		if style == "D11" then
			list.AnchorPoint = Vector2.new(0.5, 0)
			list.Position = UDim2.new(0.5, 0, 0.2, 0)
			list.AutomaticSize = Enum.AutomaticSize.Y
			list.Size = UDim2.fromOffset(PALETTE_WIDTH, 0)
			local strip = Instance.new("Frame")
			strip.Name = "SearchRow"
			strip.LayoutOrder = 0
			strip.Size = UDim2.new(1, 0, 0, ROW)
			strip.BackgroundTransparency = 1
			strip.Parent = list
			pad(strip, 0, 8)
			lineUp(strip, Enum.FillDirection.Horizontal, 8)
			newIcon("Search", ICON.search, 16, 0).Parent = strip
			local entry = newBox("Search", `{spec.label}…`, 1)
			entry.Parent = strip
			paletteBox = entry
		end
	end

	list.Parent = if catcher then catcher else root

	-- D20 commits nothing until this is pressed.
	local applyButton: TextButton? = nil
	if style == "D20" then
		local apply = Instance.new("TextButton")
		apply.Name = "Apply"
		apply.LayoutOrder = 2
		apply.AutoButtonColor = false
		apply.Size = UDim2.new(1, 0, 0, ROW)
		apply.BackgroundColor3 = THEME.accent
		apply.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		apply.TextSize = 14
		apply.TextColor3 = THEME.text
		apply.Text = "Apply"
		apply.Parent = list
		round(apply, 6)
		applyButton = apply
	end

	local rows = Instance.new("ScrollingFrame")
	rows.Name = "Rows"
	rows.LayoutOrder = 1
	rows.Size = UDim2.fromScale(1, 0)
	rows.BackgroundTransparency = 1
	rows.BorderSizePixel = 0
	rows.ScrollBarThickness = 4
	rows.ScrollBarImageColor3 = THEME.edge
	rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rows.CanvasSize = UDim2.new()
	rows.Parent = list
	if style == "D18" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(1 / GRID_COLUMNS, -LIST_GAP, 0, GRID_CELL)
		grid.CellPadding = UDim2.fromOffset(LIST_GAP, LIST_GAP)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = rows
	else
		lineUp(rows, Enum.FillDirection.Vertical, 0)
	end

	local refreshField: () -> ()
	local rebuild: () -> ()
	local close: () -> ()

	local function report()
		spec.onChanged(table.clone(chosen))
	end

	local function remember(text: string)
		local at = table.find(recent, text)
		if at then
			table.remove(recent, at)
		end
		table.insert(recent, 1, text)
		if #recent > RECENT_LIMIT then
			table.remove(recent)
		end
	end

	local function choose(text: string)
		local level = if #trail > 0 then trail[#trail].children else nil
		local picked = choiceFor(text, level)
		if style == "D21" and picked and picked.children then
			table.insert(trail, picked)
			rebuild()
			return
		end

		if style == "D20" and pending then
			local at = table.find(pending, text)
			if at then
				table.remove(pending, at)
			else
				table.insert(pending, text)
			end
			rebuild()
			return
		end
		if style == "D14" then
			remember(text)
		end

		if multi then
			local at = table.find(chosen, text)
			if at then
				table.remove(chosen, at)
			else
				table.insert(chosen, text)
			end
			refreshField()
			rebuild()
			report()
			return
		end
		chosen = { text }
		if style == "D5" and box then
			box.Text = text
		end
		refreshField()
		close()
		report()
	end

	local function visibleChoices(): { Choice }
		local shown = {}
		local level: { string | Choice } = choices
		if #trail > 0 then
			level = trail[#trail].children or {}
		end
		for _, option in level do
			local choice = toChoice(option)
			if matches(choice, query) then
				table.insert(shown, choice)
			end
		end
		if style == "D5" and #shown > SUGGESTIONS then
			return { table.unpack(shown, 1, SUGGESTIONS) }
		end
		return shown
	end

	-- `name` and `onPick` let D14, D21 and D22 add rows that are not options:
	-- a repeat of a recent pick, a way back, a way to create one.
	local function addRow(
		choice: Choice,
		order: number,
		name: string?,
		onPick: (() -> ())?
	): TextButton
		local row = Instance.new("TextButton")
		row.Name = name or choice.text
		row.LayoutOrder = order
		row.AutoButtonColor = false
		row.Text = ""
		row.Size = UDim2.new(1, 0, 0, if style == "D13" then TWO_LINE_ROW else ROW)
		row.BackgroundColor3 = THEME.surface
		row.BackgroundTransparency = 0
		row.Parent = rows
		round(row, 6)
		pad(row, 0, if style == "D18" then 4 else 12)
		local rowLayout = lineUp(
			row,
			if style == "D18" then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
			if style == "D18" then 4 else 12
		)
		if style == "D18" then
			rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		end

		local picked = isChosen(choice.text)
		if pending then
			picked = table.find(pending, choice.text) ~= nil
		end
		if multi then
			local tickBox = Instance.new("Frame")
			tickBox.Name = "Box"
			tickBox.LayoutOrder = 0
			tickBox.Size = UDim2.fromOffset(20, 20)
			tickBox.BackgroundColor3 = if picked then THEME.accent else THEME.field
			tickBox.BorderSizePixel = 0
			tickBox.Parent = row
			round(tickBox, 6)
			local tick = newIcon("Tick", ICON.check, 16, 0)
			tick.ImageColor3 = THEME.text
			tick.ImageTransparency = if picked then 0 else 1
			tick.Parent = tickBox
		elseif choice.colour then
			local chip = Instance.new("Frame")
			chip.Name = "Swatch"
			chip.LayoutOrder = 0
			chip.Size = UDim2.fromOffset(20, 20)
			chip.BackgroundColor3 = choice.colour
			chip.BorderSizePixel = 0
			chip.Parent = row
			round(chip, 6)
		elseif choice.icon or choice.image then
			local size = if choice.image or style == "D18" then 24 else 16
			newIcon("Icon", choice.image or choice.icon or "", size, 0).Parent = row
		end

		local words = newText("Label", choice.display or choice.text, 14, 1)
		words.Parent = row
		if style == "D18" then
			words.TextSize = 12
			words.TextXAlignment = Enum.TextXAlignment.Center
			words.Size = UDim2.new(1, 0, 0, 16)
		elseif style == "D13" then
			-- Two lines: the label over its detail, both left aligned.
			local column = Instance.new("Frame")
			column.Name = "Lines"
			column.LayoutOrder = 1
			column.Size = UDim2.fromScale(0, 1)
			column.BackgroundTransparency = 1
			column.Parent = row
			fill(column)
			lineUp(column, Enum.FillDirection.Vertical, 4)

			words.Size = UDim2.new(1, 0, 0, 16)
			words.Parent = column
			local under = newText("Detail", choice.detail or "", 12, 2)
			under.Size = UDim2.new(1, 0, 0, 16)
			under.TextColor3 = THEME.textMuted
			under.Parent = column
		else
			fill(words)
		end
		if choice.children then
			newIcon("Deeper", ICON.chevronRight, 16, 3).Parent = row
		end

		if choice.detail and style ~= "D13" and style ~= "D18" then
			local extra = newText("Detail", choice.detail, 12, 2)
			extra.AutomaticSize = Enum.AutomaticSize.X
			extra.TextColor3 = THEME.textMuted
			extra.Parent = row
		end
		if picked and not multi then
			local tick = newIcon("Tick", ICON.check, 16, 3)
			tick.ImageColor3 = THEME.focus
			tick.Parent = row
		end

		watch(row, rowConnections, function()
			return THEME.surface
		end)
		table.insert(rowConnections, row.Activated:Connect(function()
			if onPick then
				onPick()
			else
				choose(choice.text)
			end
		end))
		return row
	end

	local function addNote(name: string, text: string, order: number)
		local note = newText(name, text, 12, order)
		note.Size = UDim2.new(1, 0, 0, if name == "Empty" then ROW else 24)
		note.TextColor3 = THEME.textMuted
		note.Parent = rows
		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, 12)
		inset.Parent = note
	end

	function rebuild()
		for _, connection in rowConnections do
			connection:Disconnect()
		end
		table.clear(rowConnections)
		for _, child in rows:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local shown = visibleChoices()
		local order, group = 0, nil
		if style == "D14" and query == "" and #recent > 0 then
			order += 1
			addNote("RECENT", "RECENT", order)
			for _, text in recent do
				local choice = choiceFor(text)
				if choice then
					order += 1
					addRow(choice, order, `Recent {text}`)
				end
			end
			order += 1
			addNote("ALL", "ALL", order)
		end

		if #trail > 0 then
			order += 1
			local above = trail[#trail]
			local back = { text = "Back", display = `Back to {above.display or above.text}` }
			addRow(back, order, "Back", function()
				table.remove(trail)
				rebuild()
			end)
		end
		for _, choice in shown do
			if style == "D8" and choice.group and choice.group ~= group then
				group = choice.group
				order += 1
				local heading = (choice.group :: string):upper()
				addNote(heading, heading, order)
			end
			order += 1
			addRow(choice, order)
		end

		-- D22: nothing matches exactly, so offer to add what was typed.
		local exact = choiceFor(query) ~= nil
		if style == "D22" and query ~= "" and not exact then
			order += 1
			local typed = query
			local offer = { text = typed, display = `Add "{typed}"`, icon = ICON.plus }
			addRow(offer, order, "Create", function()
				table.insert(choices, { text = typed })
				if spec.onCreate then
					spec.onCreate(typed)
				end
				choose(typed)
			end)
		elseif #shown == 0 then
			addNote("Empty", if #choices == 0 then "Nothing to choose yet" else "No matches", 1)
		end

		if style == "D18" then
			local lines = math.clamp(math.ceil(order / GRID_COLUMNS), 1, 3)
			rows.Size = UDim2.new(1, 0, 0, lines * (GRID_CELL + LIST_GAP))
		else
			local height = if style == "D13" then TWO_LINE_ROW else ROW
			rows.Size = UDim2.new(1, 0, 0, math.clamp(order, 1, VISIBLE_ROWS) * height)
		end
	end

	-- D4: one chip per chosen value, or the label while nothing is chosen.
	local function drawChips(holder: Frame)
		for _, child in holder:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for index, text in chosen do
			local chip = newText(text, text, 12, index)
			chip.AutomaticSize = Enum.AutomaticSize.X
			chip.Size = UDim2.fromOffset(0, 32)
			chip.BackgroundTransparency = 0
			chip.BackgroundColor3 = THEME.accentDim
			chip.Parent = holder
			round(chip, 6)
			pad(chip, 0, 8)
		end
		if #chosen == 0 then
			local hint = newText("Placeholder", spec.label, 14, 0)
			hint.AutomaticSize = Enum.AutomaticSize.X
			hint.Size = UDim2.fromOffset(0, 32)
			hint.TextColor3 = THEME.textMuted
			hint.Parent = holder
		end
	end

	function refreshField()
		local first = choiceFor(chosen[1] or "")
		if value then
			local text = if #chosen == 0 then spec.label
				elseif multi and #chosen > 1 then `{#chosen} selected`
				elseif first then first.display or first.text
				else chosen[1]
			value.Text = text
			value.TextColor3 = if #chosen == 0 then THEME.textMuted else THEME.text
		end
		if lead and style ~= "D11" then
			lead.Image = if first then first.image or first.icon or "" else ""
			lead.Visible = first ~= nil
		end
		if swatch then
			swatch.BackgroundColor3 = if first and first.colour then first.colour else THEME.field
		end
		if chips then
			drawChips(chips)
		end
	end

	-- Places the floating list under the field, or above it when the screen
	-- has no room below. The layer copies the host's inset settings, so a
	-- position measured against the layer lands where the field is.
	local function place(overlay: ScreenGui)
		if style == "D11" then
			return
		end
		local extra = if applyButton then ROW + LIST_GAP else 0
		local height = rows.Size.Y.Offset + LIST_GAP * 2 + extra
		-- D16 is a sheet along the bottom edge instead of a list at the field.
		if style == "D16" then
			list.AnchorPoint = Vector2.new(0.5, 1)
			list.Size = UDim2.fromOffset(math.min(overlay.AbsoluteSize.X, PALETTE_WIDTH), height)
			list.Position = UDim2.new(0.5, 0, 1, 0)
			return
		end
		local top = field.AbsolutePosition - overlay.AbsolutePosition
		local below = top.Y + field.AbsoluteSize.Y + LIST_GAP
		local above = top.Y - height - LIST_GAP
		local fits = below + height <= overlay.AbsoluteSize.Y
		-- D15 opens upward whenever there is room, for fields near the bottom.
		local y = if style == "D15" and above >= 0 then above elseif fits then below else above
		list.Size = UDim2.fromOffset(field.AbsoluteSize.X, height)
		list.Position = UDim2.fromOffset(top.X, y)
	end

	local function open()
		if isOpen or style == "D7" then
			return
		end
		isOpen = true
		ticket += 1
		if style == "D20" then
			pending = table.clone(chosen)
		end
		rebuild()

		local overlay = layer
		if overlay then
			local host = spec.host or field:FindFirstAncestorWhichIsA("ScreenGui")
			assert(host, "the dropdown must be inside a ScreenGui before it opens")
			overlay.DisplayOrder = host.DisplayOrder + 1
			overlay.ScreenInsets = host.ScreenInsets
			overlay.Parent = host.Parent
			overlay.Enabled = true
			place(overlay)
		end
		list.Visible = true
		animate(list, OPEN, { GroupTransparency = 0 })

		if style == "D16" and catcher then
			catcher.BackgroundColor3 = THEME.scrim
			animate(catcher, OPEN, { BackgroundTransparency = SCRIM_TRANSPARENCY })
			list.Position = UDim2.new(0.5, 0, 1, list.Size.Y.Offset)
			animate(list, OPEN, { Position = UDim2.new(0.5, 0, 1, 0) })
		end
		if chevron then
			animate(chevron, OPEN, { Rotation = 180 })
		end
		if paletteBox then
			paletteBox:CaptureFocus()
		end
		if UserInputService.GamepadEnabled then
			GuiService.SelectedObject = rows:FindFirstChildWhichIsA("GuiButton")
		end
	end

	function close()
		if not isOpen then
			return
		end
		isOpen = false
		ticket += 1
		local mine = ticket
		local overlay = layer
		if chevron then
			animate(chevron, SHUT, { Rotation = 0 })
		end
		pending = nil
		table.clear(trail)
		if style == "D16" and catcher then
			animate(catcher, SHUT, { BackgroundTransparency = 1 })
			animate(list, SHUT, { Position = UDim2.new(0.5, 0, 1, list.Size.Y.Offset) })
		end
		animate(list, SHUT, { GroupTransparency = 1 }).Completed:Once(function()
			if mine == ticket then
				list.Visible = false
				if overlay then
					overlay.Enabled = false
				end
			end
		end)
		if paletteBox then
			paletteBox.Text = ""
		end
	end

	local function toggle()
		if isOpen then
			close()
		else
			open()
		end
	end

	local function setOptions(options: { string | Choice })
		table.clear(choices)
		for _, option in options do
			table.insert(choices, toChoice(option))
		end
		if isOpen then
			rebuild()
		end
		refreshField()
	end

	-- D7: arrows step through the options and wrap at either end.
	local function step(by: number)
		if #choices == 0 then
			return
		end
		local at = 1
		for index, choice in choices do
			if choice.text == chosen[1] then
				at = index
			end
		end
		local nextIndex = (at - 1 + by) % #choices + 1
		chosen = { choices[nextIndex].text }
		refreshField()
		report()
	end

	if style == "D7" then
		for index, direction in { -1, 1 } do
			local arrow = Instance.new("ImageButton")
			arrow.Name = if direction < 0 then "Previous" else "Next"
			arrow.LayoutOrder = if index == 1 then 0 else 2
			arrow.Size = UDim2.fromOffset(ROW, ROW)
			arrow.AutoButtonColor = false
			arrow.BackgroundColor3 = THEME.field
			arrow.Image = ""
			arrow.Parent = field
			round(arrow, 6)

			local image = if direction < 0 then ICON.chevronLeft else ICON.chevronRight
			newIcon("Mark", image, 16, 0).Parent = arrow
			local centre = lineUp(arrow, Enum.FillDirection.Horizontal, 0)
			centre.HorizontalAlignment = Enum.HorizontalAlignment.Center
			watch(arrow, connections, function()
				return THEME.field
			end)
			table.insert(connections, arrow.Activated:Connect(function()
				step(direction)
			end))
		end
	end

	if fieldButton then
		watch(fieldButton, connections, function()
			return THEME.field
		end)
		table.insert(connections, fieldButton.Activated:Connect(toggle))
	end
	if runButton and moreButton then
		for _, button in { runButton, moreButton } do
			watch(button, connections, function()
				return THEME.field
			end)
		end
		table.insert(connections, moreButton.Activated:Connect(toggle))
		table.insert(connections, runButton.Activated:Connect(function()
			if spec.onRun and chosen[1] then
				spec.onRun(chosen[1])
			end
		end))
	end
	if applyButton then
		table.insert(connections, applyButton.Activated:Connect(function()
			if pending then
				chosen = table.clone(pending)
			end
			refreshField()
			close()
			report()
		end))
	end
	if catcher then
		table.insert(connections, catcher.Activated:Connect(close))
	end

	-- Typing filters; Enter picks the first match, as a search box would.
	local typing = box or paletteBox
	if typing then
		local entry = typing
		-- D17: the grey rest of the first option that starts with the typing.
		local function suggest()
			local hint = ghost
			if not hint then
				return
			end
			local lowered = query:lower()
			for _, choice in visibleChoices() do
				local word = choice.display or choice.text
				if query ~= "" and word:lower():sub(1, #query) == lowered then
					local rest = escape(word:sub(#query + 1))
					hint.Text = `<font transparency="1">{escape(query)}</font>{rest}`
					return
				end
			end
			hint.Text = ""
		end

		table.insert(connections, entry:GetPropertyChangedSignal("Text"):Connect(function()
			query = entry.Text
			suggest()
			if style == "D5" and query == "" then
				close()
				return
			end
			if isOpen then
				rebuild()
				if layer then
					place(layer)
				end
			elseif entry.Text ~= "" and style ~= "D11" then
				open()
			end
		end))
		table.insert(connections, entry.FocusLost:Connect(function(enterPressed: boolean)
			if not enterPressed then
				return
			end
			local first = visibleChoices()[1]
			if first then
				choose(first.text)
			end
		end))
		if style == "D2" or style == "D17" or style == "D22" then
			table.insert(connections, entry.Focused:Connect(open))
		end
	end

	table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject)
		if isOpen and input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
		-- D17: Tab accepts the grey completion.
		local entry = box
		if style == "D17" and entry and input.KeyCode == Enum.KeyCode.Tab and entry:IsFocused() then
			local first = visibleChoices()[1]
			if first then
				entry.Text = first.display or first.text
			end
		end
	end))

	if style == "D10" then
		table.insert(connections, Players.PlayerAdded:Connect(function()
			setOptions(playerChoices())
		end))
		-- A chosen player who leaves is no longer a valid target.
		table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
			task.defer(function()
				setOptions(playerChoices())
				if isChosen(player.Name) then
					table.remove(chosen, table.find(chosen, player.Name) :: number)
					refreshField()
					report()
				end
			end)
		end))
		setOptions(playerChoices())
	else
		setOptions(spec.options)
	end
	root.Parent = parent

	return {
		root = root,
		get = function()
			return table.clone(chosen)
		end,
		set = function(next: { string })
			chosen = table.clone(next)
			refreshField()
			if isOpen then
				rebuild()
			end
		end,
		setOptions = setOptions,
		open = open,
		close = close,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			for _, connection in rowConnections do
				connection:Disconnect()
			end
			list:Destroy()
			if layer then
				layer:Destroy()
			end
			root:Destroy()
		end,
	}
end

return createDropdown
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/menus.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

type FirstStyles = "M0" | "M1" | "M2" | "M3" | "M4" | "M5" | "M6"
type SecondStyles = "M7" | "M8" | "M9" | "M10" | "M11" | "M12"
type LaterStyles = "M13" | "M14" | "M15" | "M16" | "M17" | "M18"
type LastStyles = "M19" | "M20" | "M21" | "M22" | "M23" | "M24"
type NewerStyles = "M25" | "M26" | "M27" | "M28" | "M29" | "M30"
type NewestStyles = "M31" | "M32" | "M33" | "M34" | "M35" | "M36"
type EarlyStyles = FirstStyles | SecondStyles | LaterStyles | LastStyles
export type MenuStyle = EarlyStyles | NewerStyles | NewestStyles

-- `scrim` is the full-screen frame M19 dims behind the panel.
export type PresenterOptions = {
	closeStyle: MenuStyle?,
	rows: { CanvasGroup }?,
	scrim: GuiObject?,
}

export type Presenter = {
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	destroy: () -> (),
}

local MOTION = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	drawerIn = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	drawerOut = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	settle = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	reduced = TweenInfo.new(0.08, Enum.EasingStyle.Linear),
	unfold = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	fold = TweenInfo.new(0.18, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	bounce = TweenInfo.new(0.45, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	jelly = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
	snapIn = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	snapOut = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	slowIn = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	slowOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	glide = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	glideOut = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	-- Out to the peak and back, twice: the two beats of M35.
	beat = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true),
}

-- How dark M19's scrim gets: half the game still shows through.
local SCRIM_TRANSPARENCY = 0.5

-- The sizes a panel pops from and shrinks to, shared by the styles built on
-- the gentle pop (M3) and the grow from a button (M5).
local POP_IN, POP_OUT = 0.96, 0.98
local GROW_IN, GROW_OUT = 0.9, 0.95

-- M31 starts from half size, M36 shrinks to it; M35 beats to 104 %; M28
-- starts as a 48 px circle; M33's rows pop from 90 %.
local HALF = 0.5
local BEAT = 1.04
local CIRCLE = 48
local ROW_POP = 0.9

type Pose = {
	enter: (size: Vector2) -> Vector2,
	exit: (size: Vector2) -> Vector2,
	enterScale: number,
	exitScale: number,
	enterRotation: number,
	exitRotation: number,
	fades: boolean,
	enterTiming: TweenInfo,
	exitTiming: TweenInfo,
	fadeTiming: TweenInfo,
	scaleTiming: TweenInfo?,
	settlePosition: boolean,
	settleScale: boolean,
	unfold: "X" | "Y" | "L" | "circle" | "none",
	dims: boolean,
}

local function still(): Vector2
	return Vector2.zero
end

local function pose(overrides: { [string]: any }): Pose
	local base = {
		enter = still,
		exit = still,
		enterScale = 1,
		exitScale = 1,
		enterRotation = 0,
		exitRotation = 0,
		fades = true,
		enterTiming = MOTION.enter,
		exitTiming = MOTION.exit,
		fadeTiming = MOTION.enter,
		settlePosition = false,
		settleScale = false,
		unfold = "none",
		dims = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return (base :: any) :: Pose
end

-- Where each style starts when opening and where it goes when closing, as an
-- offset from the resting position. Exits travel less than entrances; the
-- drawers and sheets leave the way they came and stay opaque while moving.
local POSE: { [string]: Pose } = {
	M1 = pose({}),
	M2 = pose({
		enter = function()
			return Vector2.new(0, 12)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
	M3 = pose({ enterScale = POP_IN, exitScale = POP_OUT }),
	M4 = pose({
		enter = function(size: Vector2)
			return Vector2.new(-(size.X + 24), 0)
		end,
		exit = function(size: Vector2)
			return Vector2.new(-(size.X + 24), 0)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M5 = pose({ enterScale = GROW_IN, exitScale = GROW_OUT }),
	M6 = pose({ enterScale = 0.94, exitScale = POP_OUT, settleScale = true }),
	M7 = pose({
		enter = function(size: Vector2)
			return Vector2.new(size.X + 24, 0)
		end,
		exit = function(size: Vector2)
			return Vector2.new(size.X + 24, 0)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M8 = pose({
		enter = function(size: Vector2)
			return Vector2.new(0, size.Y + 24)
		end,
		exit = function(size: Vector2)
			return Vector2.new(0, size.Y + 24)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M9 = pose({
		enter = function(size: Vector2)
			return Vector2.new(0, -(size.Y + 24))
		end,
		exit = function(size: Vector2)
			return Vector2.new(0, -(size.Y + 24))
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M10 = pose({ enterScale = 1.06, exitScale = 1.03 }),
	M11 = pose({
		enter = function()
			return Vector2.new(0, 24)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
		settlePosition = true,
	}),
	M12 = pose({
		enter = function()
			return Vector2.new(0, 8)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
	M13 = pose({
		enter = function()
			return Vector2.new(-24, 0)
		end,
		exit = function()
			return Vector2.new(-12, 0)
		end,
	}),
	M14 = pose({
		enter = function()
			return Vector2.new(24, 0)
		end,
		exit = function()
			return Vector2.new(12, 0)
		end,
	}),
	M15 = pose({
		enter = function()
			return Vector2.new(0, -12)
		end,
		exit = function()
			return Vector2.new(0, -8)
		end,
	}),
	M16 = pose({
		enterRotation = -4,
		exitRotation = 2,
		enterScale = POP_IN,
		exitScale = POP_OUT,
		settleScale = true,
	}),
	M17 = pose({
		unfold = "Y",
		fades = false,
		enterTiming = MOTION.unfold,
		exitTiming = MOTION.fold,
	}),
	M18 = pose({
		unfold = "X",
		fades = false,
		enterTiming = MOTION.unfold,
		exitTiming = MOTION.fold,
	}),
	M19 = pose({ enterScale = POP_IN, exitScale = POP_OUT, dims = true }),
	M20 = pose({
		enter = function()
			return Vector2.new(0, 24)
		end,
		exit = function()
			return Vector2.new(0, 12)
		end,
		enterScale = GROW_IN,
		exitScale = GROW_OUT,
		enterTiming = MOTION.drawerIn,
	}),
	M21 = pose({
		enter = function()
			return Vector2.new(0, -40)
		end,
		exit = function()
			return Vector2.new(0, -12)
		end,
		enterTiming = MOTION.bounce,
	}),
	M22 = pose({ enterScale = 0.8, exitScale = GROW_OUT, scaleTiming = MOTION.jelly }),
	M23 = pose({
		enterScale = POP_OUT,
		exitScale = POP_OUT,
		enterTiming = MOTION.snapIn,
		exitTiming = MOTION.snapOut,
		fadeTiming = MOTION.snapIn,
	}),
	M24 = pose({
		enterTiming = MOTION.slowIn,
		exitTiming = MOTION.slowOut,
		fadeTiming = MOTION.slowIn,
	}),
	M25 = pose({
		enterRotation = -90,
		exitRotation = 45,
		enterScale = GROW_IN,
		exitScale = GROW_OUT,
		settleScale = true,
	}),
	M26 = pose({
		enter = function()
			return Vector2.new(-24, 24)
		end,
		exit = function()
			return Vector2.new(-12, 12)
		end,
	}),
	M27 = pose({
		unfold = "L",
		fades = false,
		enterTiming = MOTION.unfold,
		exitTiming = MOTION.fold,
	}),
	M28 = pose({
		unfold = "circle",
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.fold,
	}),
	M29 = pose({
		enter = function()
			return Vector2.new(0, 40)
		end,
		exit = function()
			return Vector2.new(0, 12)
		end,
		enterTiming = MOTION.bounce,
	}),
	M30 = pose({
		enter = function()
			return Vector2.new(-48, 0)
		end,
		exit = function()
			return Vector2.new(-12, 0)
		end,
		enterTiming = MOTION.jelly,
	}),
	M31 = pose({ enterScale = HALF, exitScale = GROW_IN, settleScale = true }),
	M32 = pose({
		enter = function()
			return Vector2.new(0, -24)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
		enterRotation = 8,
		exitRotation = -4,
		settlePosition = true,
	}),
	M33 = pose({
		enter = function()
			return Vector2.new(0, 8)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
	M34 = pose({
		enter = function()
			return Vector2.new(120, 0)
		end,
		exit = function()
			return Vector2.new(40, 0)
		end,
		enterTiming = MOTION.glide,
		exitTiming = MOTION.glideOut,
		fadeTiming = MOTION.glide,
	}),
	M35 = pose({ enterScale = POP_IN, exitScale = POP_OUT }),
	M36 = pose({ enterScale = GROW_IN, exitScale = HALF }),
}

local ROW_STEP = 0.03
local ROW_BUDGET = 0.25

-- `panel` is the window's outermost CanvasGroup, placed by Position rather than
-- by a parent layout. For M5, set its AnchorPoint on the side facing the button
-- that opens it: UIScale grows the panel out of its anchor. A UIScale used for
-- screen-size scaling belongs on a parent frame, not on the panel. M12 needs
-- the rows it reveals, each a CanvasGroup; so does M33. M17, M18, M27 and M28
-- resize the panel, so its contents must be sized in offset or they squash
-- instead of being revealed. M28 reshapes the panel's own UICorner.
local function createPresenter(
	panel: CanvasGroup,
	style: MenuStyle,
	options: PresenterOptions?
): Presenter
	local closeStyle: MenuStyle = style
	if options and options.closeStyle then
		closeStyle = options.closeStyle
	end
	local rows: { CanvasGroup } = if options and options.rows then options.rows else {}
	local scrim: GuiObject? = if options then options.scrim else nil
	if style == "M19" or closeStyle == "M19" then
		assert(scrim, "M19 needs options.scrim")
		scrim.BackgroundTransparency = 1
		scrim.Visible = false
	end

	local scale = Instance.new("UIScale")
	scale.Name = "OpenScale"
	scale.Parent = panel

	local corner = panel:FindFirstChildWhichIsA("UICorner")
	local restingCorner = if corner then corner.CornerRadius else UDim.new()

	local home = panel.Position
	local fullSize = panel.Size
	local phase: "closed" | "opening" | "open" | "closing" = "closed"
	local ticket = 0
	local running: { Tween } = {}

	panel.Visible = false
	panel.GroupTransparency = 1
	scale.Scale = 1

	local function stop()
		for _, tween in running do
			tween:Cancel()
		end
		table.clear(running)
	end

	local function play(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
		local tween = TweenService:Create(target, timing, goals)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function shifted(offset: Vector2): UDim2
		return home + UDim2.fromOffset(offset.X, offset.Y)
	end

	-- A folded size, and the position that keeps the right part still: the top
	-- for a roll (Y), the centre for a stretch (X), the left edge for a curtain
	-- (L), and the centre for a circle.
	local function folded(axis: "X" | "Y" | "L" | "circle"): (UDim2, UDim2)
		local anchor, pixels = panel.AnchorPoint, panel.AbsoluteSize
		if axis == "Y" then
			local size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 0)
			return size, shifted(Vector2.new(0, -anchor.Y * pixels.Y))
		elseif axis == "circle" then
			local dx = (0.5 - anchor.X) * (pixels.X - CIRCLE)
			local dy = (0.5 - anchor.Y) * (pixels.Y - CIRCLE)
			return UDim2.fromOffset(CIRCLE, CIRCLE), shifted(Vector2.new(dx, dy))
		end
		local size = UDim2.new(0, 0, fullSize.Y.Scale, fullSize.Y.Offset)
		local keep = if axis == "L" then -anchor.X else 0.5 - anchor.X
		return size, shifted(Vector2.new(keep * pixels.X, 0))
	end

	local function dim(show: boolean, timing: TweenInfo)
		if not scrim then
			return
		end
		scrim.Visible = true
		play(scrim, timing, { BackgroundTransparency = if show then SCRIM_TRANSPARENCY else 1 })
	end

	-- Every tween checks the ticket it was started with, so a close that is
	-- interrupted by a reopen can never hide the panel it no longer owns.
	local function settleWhen(tween: Tween, onSettled: () -> ())
		local mine = ticket
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				onSettled()
			end
		end)
	end

	-- M12 fades the rows in one by one; M33 also pops each from 90 %. A row sits
	-- in a layout, so it can grow but never travel.
	local function revealRows(pops: boolean)
		local step = math.min(ROW_STEP, ROW_BUDGET / math.max(#rows, 1))
		local mine = ticket
		for index, row in rows do
			row.GroupTransparency = 1
			local grow = row:FindFirstChild("RowScale") :: UIScale?
			if pops and not grow then
				local created = Instance.new("UIScale")
				created.Name = "RowScale"
				created.Parent = row
				grow = created
			end
			if grow then
				grow.Scale = if pops then ROW_POP else 1
			end
			task.delay(step * (index - 1), function()
				if mine ~= ticket or not row.Parent then
					return
				end
				play(row, MOTION.enter, { GroupTransparency = 0 })
				if grow then
					play(grow, MOTION.settle, { Scale = 1 })
				end
			end)
		end
	end

	local function open()
		if phase == "open" or phase == "opening" then
			return
		end
		ticket += 1
		stop()
		local fromClosed = phase == "closed"
		phase = "opening"
		panel.Visible = true

		if style == "M0" then
			panel.Position, scale.Scale, panel.GroupTransparency = home, 1, 0
			phase = "open"
			return
		end
		if GuiService.ReducedMotionEnabled then
			panel.Position, panel.Size, scale.Scale, panel.Rotation = home, fullSize, 1, 0
			dim(true, MOTION.reduced)
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 0 }), function()
				phase = "open"
			end)
			return
		end

		local chosen = POSE[style]
		if fromClosed then
			panel.Position = shifted(chosen.enter(panel.AbsoluteSize))
			scale.Scale = chosen.enterScale
			panel.Rotation = chosen.enterRotation
			panel.GroupTransparency = if chosen.fades then 1 else 0
			if chosen.unfold ~= "none" then
				panel.Size, panel.Position = folded(chosen.unfold)
			end
			if chosen.unfold == "circle" and corner then
				corner.CornerRadius = UDim.new(0.5, 0)
			end
		end

		local moveTiming = if chosen.settlePosition then MOTION.settle else chosen.enterTiming
		local growTiming = if chosen.settleScale
			then MOTION.settle
			else chosen.scaleTiming or chosen.enterTiming
		local move = play(panel, moveTiming, { Position = home, Size = fullSize })
		play(panel, chosen.fadeTiming, { GroupTransparency = 0 })
		play(scale, growTiming, { Scale = 1 })
		play(panel, growTiming, { Rotation = 0 })

		if chosen.dims then
			dim(true, MOTION.enter)
		end
		if chosen.unfold == "circle" and corner then
			play(corner, moveTiming, { CornerRadius = restingCorner })
		end
		if style == "M12" or style == "M33" then
			revealRows(style == "M33")
		end
		settleWhen(move, function()
			phase = "open"
			if style == "M35" then
				play(scale, MOTION.beat, { Scale = BEAT })
			end
		end)
	end

	local function close()
		if phase == "closed" or phase == "closing" then
			return
		end
		if phase == "open" then
			home, fullSize = panel.Position, panel.Size
		end
		ticket += 1
		stop()
		phase = "closing"

		local function hide()
			panel.Visible = false
			panel.Position, panel.Size, scale.Scale, panel.GroupTransparency = home, fullSize, 1, 1
			panel.Rotation = 0
			if corner then
				corner.CornerRadius = restingCorner
			end
			if scrim then
				scrim.Visible = false
			end
			phase = "closed"
		end

		if closeStyle == "M0" then
			hide()
			return
		end
		if GuiService.ReducedMotionEnabled then
			dim(false, MOTION.reduced)
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 1 }), hide)
			return
		end

		local chosen = POSE[closeStyle]
		play(scale, chosen.exitTiming, { Scale = chosen.exitScale })
		play(panel, chosen.exitTiming, { Rotation = chosen.exitRotation })
		if chosen.fades then
			play(panel, chosen.exitTiming, { GroupTransparency = 1 })
		end
		dim(false, chosen.exitTiming)
		if chosen.unfold ~= "none" then
			local size, position = folded(chosen.unfold)
			if chosen.unfold == "circle" and corner then
				play(corner, chosen.exitTiming, { CornerRadius = UDim.new(0.5, 0) })
			end
			settleWhen(play(panel, chosen.exitTiming, { Size = size, Position = position }), hide)
			return
		end
		local target = shifted(chosen.exit(panel.AbsoluteSize))
		settleWhen(play(panel, chosen.exitTiming, { Position = target }), hide)
	end

	return {
		open = open,
		close = close,
		isOpen = function()
			return phase == "open" or phase == "opening"
		end,
		destroy = function()
			ticket += 1
			stop()
			scale:Destroy()
		end,
	}
end

return createPresenter
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/notices.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

export type Severity = "info" | "success" | "warning" | "error"

local THEME = {
	scrim = Color3.fromRGB(9, 10, 13),
	surface = Color3.fromRGB(44, 48, 57),
	control = Color3.fromRGB(63, 68, 79),
	controlHover = Color3.fromRGB(78, 84, 97),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentHover = Color3.fromRGB(72, 201, 162),
	onAccent = Color3.fromRGB(9, 10, 13),
	focus = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	success = "rbxassetid://88244323237265",
	warning = "rbxassetid://91165848022002",
	error = "rbxassetid://106305483906363",
	close = "rbxassetid://116396312853810",
}

local ENTER = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function holdFor(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.clamp(2 + words * 0.3, 3, 8)
end

local function iconLabel(parent: GuiObject, severity: Severity, order: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.LayoutOrder = order
	icon.Size = UDim2.fromOffset(16, 16)
	icon.BackgroundTransparency = 1
	icon.Image = ICON[severity]
	icon.ImageColor3 = THEME[severity]
	icon.Parent = parent
	return icon
end

local function rowLayout(parent: GuiObject, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

-- N3: the row is always present at its full height, so showing a message never
-- pushes the controls below it down.
local function createInlineMessage(parent: GuiObject, order: number)
	local ticket = 0

	local slot = Instance.new("CanvasGroup")
	slot.Name = "InlineMessage"
	slot.LayoutOrder = order
	slot.Size = UDim2.new(1, 0, 0, 20)
	slot.BackgroundTransparency = 1
	slot.GroupTransparency = 1
	slot.Parent = parent
	rowLayout(slot, 8)

	local icon = iconLabel(slot, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 12
	text.TextColor3 = THEME.textMuted
	text.Text = ""
	text.Parent = slot

	local function clear()
		ticket += 1
		TweenService:Create(slot, motion(EXIT), { GroupTransparency = 1 }):Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		local mine = ticket
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		TweenService:Create(slot, motion(ENTER), { GroupTransparency = 0 }):Play()
		if severity ~= "error" then
			task.delay(holdFor(message), function()
				if mine == ticket then
					clear()
				end
			end)
		end
	end

	return {
		show = show,
		clear = clear,
		destroy = function()
			ticket += 1
			slot:Destroy()
		end,
	}
end

-- Hover, press and focus for the dialog buttons; the focus ring is separate
-- from the fill so a pointer leaving never hides keyboard or gamepad focus.
local function actionButton(parent: GuiObject, text: string, primary: boolean, order: number)
	local rest = if primary then THEME.accent else THEME.control
	local hover = if primary then THEME.accentHover else THEME.controlHover
	local connections: { RBXScriptConnection } = {}

	local button = Instance.new("TextButton")
	button.Name = text
	button.LayoutOrder = order
	button.AutoButtonColor = false
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 44)
	button.BackgroundColor3 = rest
	button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	button.TextSize = 14
	button.TextColor3 = if primary then THEME.onAccent else THEME.text
	button.Text = text
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = button

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	local press = Instance.new("UIScale")
	press.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hover
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		button.BackgroundColor3 = rest
		press.Scale = 1
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			press.Scale = 0.97
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		press.Scale = 1
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
	return button, connections
end

-- N5: a strip for a condition that lasts, such as "Reconnecting". It stays until
-- the condition ends or the player dismisses it.
local function createBanner(screen: ScreenGui)
	local connections: { RBXScriptConnection } = {}

	local strip = Instance.new("CanvasGroup")
	strip.Name = "Banner"
	strip.AutomaticSize = Enum.AutomaticSize.Y
	strip.Size = UDim2.fromScale(1, 0)
	strip.BackgroundColor3 = THEME.surface
	strip.GroupTransparency = 1
	strip.Visible = false
	strip.Parent = screen

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = strip

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = strip
	rowLayout(strip, 12)

	local icon = iconLabel(strip, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.Size = UDim2.new(0, 0, 0, 44)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 14
	text.TextColor3 = THEME.text
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.Text = ""
	text.Parent = strip

	local fill = Instance.new("UIFlexItem")
	fill.FlexMode = Enum.UIFlexMode.Fill
	fill.Parent = text

	local dismiss = Instance.new("ImageButton")
	dismiss.Name = "Dismiss"
	dismiss.LayoutOrder = 3
	dismiss.Size = UDim2.fromOffset(44, 44)
	dismiss.AutoButtonColor = false
	dismiss.BackgroundTransparency = 1
	dismiss.Image = ""
	dismiss.Parent = strip

	local ink = Instance.new("ImageLabel")
	ink.AnchorPoint = Vector2.new(0.5, 0.5)
	ink.Position = UDim2.fromScale(0.5, 0.5)
	ink.Size = UDim2.fromOffset(16, 16)
	ink.BackgroundTransparency = 1
	ink.Image = ICON.close
	ink.ImageColor3 = THEME.textMuted
	ink.Parent = dismiss

	local ticket = 0
	local function hide()
		ticket += 1
		local mine = ticket
		local fade = TweenService:Create(strip, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				strip.Visible = false
			end
		end)
		fade:Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		strip.Visible = true
		TweenService:Create(strip, motion(ENTER), { GroupTransparency = 0 }):Play()
	end

	table.insert(connections, dismiss.Activated:Connect(hide))
	return {
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			strip:Destroy()
		end,
	}
end

-- N8: one short status line in a compact bar under the top bar. A new message
-- replaces the old one instead of stacking; anything the player must act on
-- belongs in N4 or N6, not here.
local function createCapsule(screen: ScreenGui)
	local ticket = 0

	local capsule = Instance.new("CanvasGroup")
	capsule.Name = "Capsule"
	capsule.AnchorPoint = Vector2.new(0.5, 0)
	capsule.Position = UDim2.new(0.5, 0, 0, 12)
	capsule.AutomaticSize = Enum.AutomaticSize.X
	capsule.Size = UDim2.fromOffset(0, 36)
	capsule.BackgroundColor3 = THEME.surface
	capsule.GroupTransparency = 1
	capsule.Visible = false
	capsule.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = capsule

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = capsule

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = capsule
	rowLayout(capsule, 8)

	local icon = iconLabel(capsule, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 14
	text.TextColor3 = THEME.text
	text.Text = ""
	text.Parent = capsule

	local grow = Instance.new("UIScale")
	grow.Scale = 1
	grow.Parent = capsule

	local function hide(mine: number)
		local fade = TweenService:Create(capsule, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				capsule.Visible = false
			end
		end)
		fade:Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		local mine = ticket
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		if not capsule.Visible then
			capsule.Visible = true
			grow.Scale = 0.9
		end
		TweenService:Create(capsule, motion(ENTER), { GroupTransparency = 0 }):Play()
		TweenService:Create(grow, motion(ENTER), { Scale = 1 }):Play()
		task.delay(holdFor(message), function()
			if mine == ticket then
				hide(mine)
			end
		end)
	end

	return {
		show = show,
		destroy = function()
			ticket += 1
			capsule:Destroy()
		end,
	}
end

export type AlertSpec = {
	title: string,
	body: string,
	confirmText: string,
	cancelText: string,
}

-- N6: only for something the player must answer. The dim layer is a button so
-- a tap outside the dialog counts as Cancel instead of reaching the game; the
-- dialog is its sibling and Active, so a tap inside it never reaches the dim.
local function confirmAlert(
	screen: ScreenGui,
	spec: AlertSpec,
	onChoice: (confirmed: boolean) -> ()
)
	local connections: { RBXScriptConnection } = {}
	local answered = false

	local scrim = Instance.new("TextButton")
	scrim.Name = "AlertScrim"
	scrim.AutoButtonColor = false
	scrim.Text = ""
	scrim.Selectable = false
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = THEME.scrim
	scrim.BackgroundTransparency = 1
	scrim.ZIndex = 10
	scrim.Parent = screen

	local dialog = Instance.new("CanvasGroup")
	dialog.Name = "Alert"
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.Size = UDim2.fromScale(0.9, 0)
	dialog.BackgroundColor3 = THEME.surface
	dialog.GroupTransparency = 1
	dialog.Active = true
	dialog.ZIndex = 11
	dialog.Parent = screen

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(400, math.huge)
	bounds.Parent = dialog

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = dialog

	local pop = Instance.new("UIScale")
	pop.Scale = 0.96
	pop.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 24)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = dialog

	local column = Instance.new("UIListLayout")
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = dialog

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.fromScale(1, 0)
	title.BackgroundTransparency = 1
	title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	title.TextSize = 20
	title.TextColor3 = THEME.text
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = spec.title
	title.Parent = dialog

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.LayoutOrder = 2
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.fromScale(1, 0)
	body.BackgroundTransparency = 1
	body.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	body.TextSize = 14
	body.TextColor3 = THEME.textMuted
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.Text = spec.body
	body.Parent = dialog

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.LayoutOrder = 3
	actions.Size = UDim2.new(1, 0, 0, 44)
	actions.BackgroundTransparency = 1
	actions.Parent = dialog
	rowLayout(actions, 8).HorizontalAlignment = Enum.HorizontalAlignment.Right

	local cancel, cancelConnections = actionButton(actions, spec.cancelText, false, 1)
	local confirm, confirmConnections = actionButton(actions, spec.confirmText, true, 2)
	table.move(cancelConnections, 1, #cancelConnections, #connections + 1, connections)
	table.move(confirmConnections, 1, #confirmConnections, #connections + 1, connections)

	local function answer(confirmed: boolean)
		if answered then
			return
		end
		answered = true
		for _, connection in connections do
			connection:Disconnect()
		end
		if GuiService.SelectedObject == confirm or GuiService.SelectedObject == cancel then
			GuiService.SelectedObject = nil
		end
		TweenService:Create(scrim, motion(EXIT), { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(dialog, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function()
			dialog:Destroy()
			scrim:Destroy()
		end)
		fade:Play()
		onChoice(confirmed)
	end

	table.insert(connections, confirm.Activated:Connect(function()
		answer(true)
	end))
	table.insert(connections, cancel.Activated:Connect(function()
		answer(false)
	end))
	table.insert(connections, scrim.Activated:Connect(function()
		answer(false)
	end))

	TweenService:Create(scrim, motion(ENTER), { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(dialog, motion(ENTER), { GroupTransparency = 0 }):Play()
	TweenService:Create(pop, motion(ENTER), { Scale = 1 }):Play()
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = cancel
	end
end

return {
	createInlineMessage = createInlineMessage,
	createBanner = createBanner,
	createCapsule = createCapsule,
	confirmAlert = confirmAlert,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/press-and-tabs.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

type FirstPress = "P1" | "P2" | "P3" | "P4" | "P5" | "P6"
type LaterPress = "P7" | "P8" | "P9" | "P10" | "P11" | "P12"
export type PressStyle = FirstPress | LaterPress | "P13" | "P14" | "P15" | "P21" | "P22"
-- The styles that change what the button says or whether it can be pressed.
export type ActionStyle = "P16" | "P17" | "P18" | "P19" | "P20"

-- `run` does the button's work and calls `finish` when it is done; P17 shows
-- whether it worked. P18 waits `seconds` before the next press; P19 asks with
-- `confirmText`; P20 refuses with a shake while `allowed` returns false.
export type ActionSpec = {
	run: (finish: (ok: boolean) -> ()) -> (),
	seconds: number?,
	confirmText: string?,
	allowed: (() -> boolean)?,
}
type FirstTabs = "S1" | "S2" | "S3" | "S4" | "S5" | "S6"
type SecondTabs = "S7" | "S8" | "S9" | "S10" | "S11" | "S12"
type LaterTabs = "S13" | "S14" | "S15" | "S16" | "S17" | "S18" | "S19" | "S20" | "S21" | "S22"
export type TabStyle = FirstTabs | SecondTabs | LaterTabs

local THEME = {
	control = Color3.fromRGB(44, 48, 57),
	controlHover = Color3.fromRGB(63, 68, 79),
	controlPressed = Color3.fromRGB(31, 34, 41),
	track = Color3.fromRGB(19, 21, 26),
	edge = Color3.fromRGB(118, 125, 139),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
	-- A UIGradient multiplies the fill, so P6 paints white and lets it choose.
	white = Color3.fromRGB(255, 255, 255),
}

local ICON = {
	arrow = "rbxassetid://134908902120212",
	tab = "rbxassetid://89644754139307",
	check = "rbxassetid://86817768619372",
	previous = "rbxassetid://102314312897830",
	next = "rbxassetid://101007429951147",
	open = "rbxassetid://71457658246709",
}

local QUICK = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPRING_BACK = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SWEEP = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SHINE = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local RIPPLE = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOLD = TweenInfo.new(1, Enum.EasingStyle.Linear)
local DRAIN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Plays forward then back: one quick pop that returns to rest on its own.
local POP = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SPIN = TweenInfo.new(RIPPLE.Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
-- Turns for as long as the pointer stays; cancelled when it leaves.
local SHIMMER = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
-- Three quick wiggles that end where they started.
local SHAKE = TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true)
local PAGE_OUT = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local PAGE_IN = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local INSTANT = TweenInfo.new(0)

local RIPPLE_SPREAD = 2.5
local RIPPLE_START = 0.75
local HOLD_FILL = 0.5
local NUDGE = 4
local PAGE_SHIFT = 24
local TILT = -2
local SHAKE_ANGLE = 4
local RESULT_HOLD = 1.2
local CONFIRM_WINDOW = 3
local DEFAULT_COOLDOWN = 3

local function animate(instance: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
	local chosen = if GuiService.ReducedMotionEnabled then INSTANT else timing
	local tween = TweenService:Create(instance, chosen, goals)
	tween:Play()
	return tween
end

-- The scale a style shows for each pointer state: most never scale, P2 presses
-- in, P3 lifts on hover and settles on press, P7 squashes and springs back.
local SCALE = {
	P2 = { rest = 1, hover = 1, pressed = 0.97 },
	P3 = { rest = 1, hover = 1.02, pressed = 0.98 },
	P7 = { rest = 1, hover = 1, pressed = 0.94 },
	P21 = { rest = 1, hover = 1.06, pressed = 0.98 },
}
local FLAT = { rest = 1, hover = 1, pressed = 1 }

-- The effects that add children need a button whose own layout would not
-- grab them: a plain text button, or one whose content sits in a child frame.
local function needsBare(button: GuiButton, style: string)
	local layout = button:FindFirstChildOfClass("UIListLayout")
	assert(not layout, `{style} needs a button with no UIListLayout`)
end

-- A clipped layer that matches the button's corners, for effects that must
-- stay inside its shape; a CanvasGroup rounds what ClipsDescendants cannot.
local function layer(button: GuiButton, style: string, name: string): CanvasGroup
	needsBare(button, style)
	local group = Instance.new("CanvasGroup")
	group.Name = name
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundTransparency = 1
	group.Parent = button

	local shape = button:FindFirstChildOfClass("UICorner")
	if shape then
		shape:Clone().Parent = group
	end
	return group
end

local function newFrame(name: string, colour: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	return frame
end

-- `onHold` is P10's action: it runs when the fill completes, never on a tap.
local function attachPress(button: GuiButton, style: PressStyle, onHold: (() -> ())?): () -> ()
	local connections: { RBXScriptConnection } = {}
	local made: { Instance } = {}
	local hovered, pressed = false, false
	button.AutoButtonColor = false

	local size = Instance.new("UIScale")
	size.Name = "PressScale"
	size.Parent = button
	table.insert(made, size)

	local rim = Instance.new("UIStroke")
	rim.Name = "LiftEdge"
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = if style == "P5" or style == "P12" then THEME.accent else THEME.edge
	rim.Thickness = if style == "P5" or style == "P12" then 2 else 1
	rim.Transparency = 1
	rim.Parent = button
	table.insert(made, rim)

	local sweep: UIGradient? = nil
	if style == "P6" then
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Sweep"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.accentDim),
			ColorSequenceKeypoint.new(0.499, THEME.accentDim),
			ColorSequenceKeypoint.new(0.5, THEME.control),
			ColorSequenceKeypoint.new(1, THEME.control),
		})
		gradient.Offset = Vector2.new(-0.5, 0)
		gradient.Parent = button
		table.insert(made, gradient)
		sweep = gradient
	end

	-- P13 starts as an outline; P14 needs the icon it spins; P15 a gradient to turn.
	if style == "P13" then
		rim.Color = THEME.accent
		rim.Transparency = 0
		button.BackgroundTransparency = 1
	end
	local spinner: GuiObject? = nil
	if style == "P14" then
		local found = button:FindFirstChild("Icon")
		assert(found and found:IsA("GuiObject"), "P14 needs a child named Icon")
		spinner = found
	end
	local shimmer: UIGradient? = nil
	local turning: Tween? = nil
	if style == "P15" then
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Shimmer"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.controlHover),
			ColorSequenceKeypoint.new(0.5, THEME.accentDim),
			ColorSequenceKeypoint.new(1, THEME.controlHover),
		})
		gradient.Enabled = false
		gradient.Parent = button
		table.insert(made, gradient)
		shimmer = gradient
	end

	local underline: Frame? = nil
	local shine: Frame? = nil
	local ripples: CanvasGroup? = nil
	local fill: Frame? = nil
	local arrow: ImageLabel? = nil
	if style == "P8" then
		needsBare(button, style)
		local line = newFrame("Underline", THEME.accent)
		line.AnchorPoint = Vector2.new(0.5, 1)
		line.Position = UDim2.fromScale(0.5, 1)
		line.Size = UDim2.fromOffset(0, 2)
		line.Parent = button
		table.insert(made, line)
		underline = line
	elseif style == "P9" then
		local group = layer(button, style, "ShineLayer")
		table.insert(made, group)

		local band = newFrame("Shine", THEME.white)
		band.Position = UDim2.fromScale(-0.5, 0)
		band.Size = UDim2.fromScale(0.4, 1)
		band.Rotation = 15
		band.BackgroundTransparency = 0.85
		band.Parent = group
		shine = band
	elseif style == "P4" then
		ripples = layer(button, style, "RippleLayer")
		table.insert(made, ripples)
	elseif style == "P10" then
		assert(onHold, "P10 needs onHold")
		local group = layer(button, style, "HoldLayer")
		table.insert(made, group)

		local bar = newFrame("HoldFill", THEME.accent)
		bar.Size = UDim2.fromScale(0, 1)
		bar.BackgroundTransparency = HOLD_FILL
		bar.Parent = group
		fill = bar
	elseif style == "P11" then
		needsBare(button, style)

		local mark = Instance.new("ImageLabel")
		mark.Name = "Arrow"
		mark.AnchorPoint = Vector2.new(1, 0.5)
		mark.Position = UDim2.new(1, -12, 0.5, 0)
		mark.Size = UDim2.fromOffset(16, 16)
		mark.BackgroundTransparency = 1
		mark.Image = ICON.arrow
		mark.ImageColor3 = THEME.text
		mark.Parent = button
		table.insert(made, mark)
		arrow = mark
	end

	local function paint()
		local steps = SCALE[style] or FLAT
		local timing = if pressed then QUICK else RELEASE
		if style == "P13" then
			animate(button, timing, {
				BackgroundTransparency = if hovered or pressed then 0 else 1,
				BackgroundColor3 = if pressed then THEME.accent else THEME.accentDim,
			})
		elseif not sweep then
			local colour = if pressed then THEME.controlPressed
				elseif hovered then THEME.controlHover
				else THEME.control
			animate(button, timing, { BackgroundColor3 = colour })
		end
		local scale = if pressed then steps.pressed elseif hovered then steps.hover else steps.rest
		local springing = (style == "P7" and not pressed and size.Scale < 1)
			or (style == "P21" and hovered and not pressed)
		animate(size, if springing then SPRING_BACK else timing, { Scale = scale })
		if style == "P22" then
			animate(button, timing, { Rotation = if pressed then TILT else 0 })
		end

		if style == "P3" or style == "P5" then
			local lit = if style == "P5" then hovered or pressed else hovered and not pressed
			animate(rim, timing, { Transparency = if lit then 0 else 1 })
			rim.Color = if style == "P5" and pressed then THEME.focus
				elseif style == "P5" then THEME.accent
				else THEME.edge
		end
		if sweep then
			local filled = if hovered or pressed then 0.5 else -0.5
			animate(sweep, SWEEP, { Offset = Vector2.new(filled, 0) })
		end
		if underline then
			animate(underline, SWEEP, { Size = UDim2.new(if hovered then 1 else 0, 0, 0, 2) })
		end
		if arrow then
			local inset = if hovered then -12 + NUDGE else -12
			animate(arrow, RELEASE, { Position = UDim2.new(1, inset, 0.5, 0) })
		end
	end

	local function rippleAt(input: InputObject)
		local group = ripples
		if not group or GuiService.ReducedMotionEnabled then
			return
		end
		local spot = input.Position
		local corner = button.AbsolutePosition
		local reach = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * RIPPLE_SPREAD
		local wave = newFrame("Ripple", THEME.white)
		wave.AnchorPoint = Vector2.new(0.5, 0.5)
		wave.Position = UDim2.fromOffset(spot.X - corner.X, spot.Y - corner.Y)
		wave.Size = UDim2.fromOffset(0, 0)
		wave.BackgroundTransparency = RIPPLE_START
		wave.Parent = group

		local circle = Instance.new("UICorner")
		circle.CornerRadius = UDim.new(0.5, 0)
		circle.Parent = wave

		local spread = animate(wave, RIPPLE, {
			Size = UDim2.fromOffset(reach, reach),
			BackgroundTransparency = 1,
		})
		spread.Completed:Once(function()
			wave:Destroy()
		end)
	end

	local holding: Tween? = nil
	local function startHold()
		local bar, run = fill, onHold
		if not bar or not run then
			return
		end
		local tween = TweenService:Create(bar, HOLD, { Size = UDim2.fromScale(1, 1) })
		holding = tween
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and holding == tween then
				holding = nil
				bar.Size = UDim2.fromScale(0, 1)
				run()
			end
		end)
		tween:Play()
	end
	local function drainHold()
		local tween, bar = holding, fill
		if not tween or not bar then
			return
		end
		holding = nil
		tween:Cancel()
		animate(bar, DRAIN, { Size = UDim2.fromScale(0, 1) })
	end

	table.insert(connections, button.MouseEnter:Connect(function()
		hovered = true
		paint()
		local band = shine
		if band then
			band.Position = UDim2.fromScale(-0.5, 0)
			animate(band, SHINE, { Position = UDim2.fromScale(1.1, 0) })
		end
		local gradient = shimmer
		if gradient and not GuiService.ReducedMotionEnabled then
			gradient.Enabled = true
			gradient.Rotation = 0
			turning = TweenService:Create(gradient, SHIMMER, { Rotation = 360 })
			turning:Play()
		end
	end))

	table.insert(connections, button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint()
		drainHold()
		if turning then
			turning:Cancel()
			turning = nil
		end
		if shimmer then
			shimmer.Enabled = false
		end
	end))

	if spinner then
		local icon = spinner
		table.insert(connections, button.Activated:Connect(function()
			icon.Rotation = 0
			animate(icon, SPIN, { Rotation = 360 }).Completed:Once(function()
				icon.Rotation = 0
			end)
		end))
	end
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressed = true
			paint()
			rippleAt(input)
			startHold()
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		pressed = false
		paint()
		drainHold()
	end))
	if style == "P12" then
		table.insert(connections, button.Activated:Connect(function()
			rim.Transparency = 0
			animate(rim, RIPPLE, { Transparency = 1 })
			animate(size, POP, { Scale = 1.05 })
		end))
	end

	button.BackgroundColor3 = if sweep then THEME.white else THEME.control
	size.Scale = 1
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		if holding then
			holding:Cancel()
		end
		if turning then
			turning:Cancel()
		end
		for _, instance in made do
			instance:Destroy()
		end
	end
end

-- P16 to P20 change what a text button says while its work happens, so the
-- player always knows whether pressing again does anything. Returns cleanup.
local function attachAction(button: TextButton, style: ActionStyle, spec: ActionSpec): () -> ()
	local connections: { RBXScriptConnection } = {}
	local label = button.Text
	local rest = button.BackgroundColor3
	local ticket = 0
	local busy = false
	local armed = false

	local function restore()
		ticket += 1
		busy, armed = false, false
		button.Text = label
		button.BackgroundColor3 = rest
		button.Interactable = true
	end

	-- P18: a bar across the button drains while the cooldown counts down.
	local drain: Frame? = nil
	if style == "P18" then
		local group = layer(button, style, "CooldownLayer")
		local bar = newFrame("Cooldown", THEME.white)
		bar.Size = UDim2.fromScale(0, 1)
		bar.BackgroundTransparency = HOLD_FILL
		bar.Parent = group
		drain = bar
	end

	local function countDown(left: number, mine: number)
		if mine ~= ticket then
			return
		end
		if left <= 0 then
			restore()
			return
		end
		button.Text = `{label} {left}s`
		task.delay(1, countDown, left - 1, mine)
	end

	local function finished(ok: boolean)
		if style == "P17" then
			ticket += 1
			local mine = ticket
			button.Text = if ok then "Done" else "Failed"
			button.BackgroundColor3 = if ok then THEME.accent else THEME.danger
			task.delay(RESULT_HOLD, function()
				if mine == ticket then
					restore()
				end
			end)
			return
		end
		if style == "P18" then
			ticket += 1
			local seconds = spec.seconds or DEFAULT_COOLDOWN
			local bar = drain
			if bar then
				bar.Size = UDim2.fromScale(1, 1)
				local timing = TweenInfo.new(seconds, Enum.EasingStyle.Linear)
				animate(bar, timing, { Size = UDim2.fromScale(0, 1) })
			end
			countDown(seconds, ticket)
			return
		end
		restore()
	end

	local function shake()
		button.Rotation = 0
		animate(button, SHAKE, { Rotation = SHAKE_ANGLE }).Completed:Once(function()
			button.Rotation = 0
		end)
	end

	table.insert(connections, button.Activated:Connect(function()
		if busy then
			return
		end
		local allowed = spec.allowed
		if style == "P20" and allowed and not allowed() then
			shake()
			return
		end
		if style == "P19" and not armed then
			ticket += 1
			local mine = ticket
			armed = true
			button.Text = spec.confirmText or "Press again to confirm"
			button.BackgroundColor3 = THEME.danger
			task.delay(CONFIRM_WINDOW, function()
				if mine == ticket then
					restore()
				end
			end)
			return
		end
		busy = true
		button.Interactable = style ~= "P16" and style ~= "P18"
		if style == "P16" then
			button.Text = "Working…"
		end
		spec.run(finished)
	end))

	return function()
		ticket += 1
		for _, connection in connections do
			connection:Disconnect()
		end
		button.Text = label
		button.BackgroundColor3 = rest
		button.Interactable = true
	end
end

-- S6, S7, S13 and S17 read `icons`; S9, S10 and S22 turn `pages`; S14 shows
-- `counts`; S18 puts tabs under `groups` headings; S20 shows `visible` tabs
-- (default 4) and moves the rest into More.
export type TabOptions = {
	icons: { [string]: string }?,
	pages: { [string]: CanvasGroup }?,
	counts: { [string]: number }?,
	groups: { [string]: string }?,
	visible: number?,
}

export type Tabs = {
	select: (name: string) -> (),
	selected: () -> string,
	destroy: () -> (),
}

type Marker = "line" | "pill" | "side" | "dot" | "top" | "folder" | "none"

-- What marks the chosen tab in each style.
local MARKER: { [TabStyle]: Marker } = {
	S1 = "line",
	S2 = "pill",
	S3 = "none",
	S4 = "side",
	S5 = "pill",
	S6 = "line",
	S7 = "pill",
	S8 = "pill",
	S9 = "line",
	S10 = "line",
	S11 = "dot",
	S12 = "pill",
	S13 = "top",
	S14 = "line",
	S15 = "none",
	S16 = "folder",
	S17 = "pill",
	S18 = "side",
	S19 = "none",
	S20 = "line",
	S21 = "none",
	S22 = "none",
}

-- S16's chosen tab reaches this far below the bar, joining the page under it.
local FOLDER_JOIN = 6

-- S9 and S10 move the pages too: S9 slides them toward the side the new tab is
-- on, S10 fades the old page out before the new one fades in.
local function turnPage(style: TabStyle, from: CanvasGroup?, to: CanvasGroup?, forward: boolean)
	local shift = if style ~= "S9" then 0 elseif forward then PAGE_SHIFT else -PAGE_SHIFT
	if from then
		local out = animate(from, PAGE_OUT, {
			GroupTransparency = 1,
			Position = UDim2.fromOffset(-shift, 0),
		})
		out.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and from.GroupTransparency == 1 then
				from.Visible = false
			end
		end)
	end
	if to then
		to.Visible = true
		to.GroupTransparency = 1
		to.Position = UDim2.fromOffset(shift, 0)
		animate(to, PAGE_IN, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
	end
end

local function label(
	parent: GuiObject,
	text: string,
	size: number,
	order: number,
	name: string?
): TextLabel
	local words = Instance.new("TextLabel")
	words.Name = name or "Label"
	words.LayoutOrder = order
	words.Size = UDim2.new(1, 0, 0, 16)
	words.BackgroundTransparency = 1
	words.TextSize = size
	words.Text = text
	words.Parent = parent
	return words
end

-- S6, S7, S13 and S17: the icon, with the name under it (S6, S13), beside it
-- (S17, shown only while chosen) or not at all (S7).
local function iconContent(
	cell: TextButton,
	name: string,
	image: string,
	style: TabStyle
): (ImageLabel, TextLabel?)
	cell.Text = ""
	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Glyph"
	glyph.LayoutOrder = 1
	glyph.Size = UDim2.fromOffset(20, 20)
	glyph.BackgroundTransparency = 1
	glyph.Image = image
	glyph.Parent = cell

	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.Padding = UDim.new(0, 4)
	stack.Parent = cell

	if style == "S7" then
		cell.Size = UDim2.fromOffset(44, 44)
		return glyph, nil
	end
	if style == "S17" then
		stack.FillDirection = Enum.FillDirection.Horizontal
		local caption = label(cell, name, 14, 2)
		caption.AutomaticSize = Enum.AutomaticSize.X
		caption.Size = UDim2.fromOffset(0, 16)
		return glyph, caption
	end
	return glyph, label(cell, name, 12, 2)
end

-- S15: a numbered circle before the name; a tick replaces the number once
-- the step is behind the chosen one.
local function stepContent(
	cell: TextButton,
	name: string,
	index: number
): (TextLabel, ImageLabel, TextLabel)
	cell.Text = ""
	local sequence = Instance.new("UIListLayout")
	sequence.FillDirection = Enum.FillDirection.Horizontal
	sequence.SortOrder = Enum.SortOrder.LayoutOrder
	sequence.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sequence.VerticalAlignment = Enum.VerticalAlignment.Center
	sequence.Padding = UDim.new(0, 8)
	sequence.Parent = cell

	local numeral = label(cell, tostring(index), 12, 1, "Step")
	numeral.Size = UDim2.fromOffset(24, 24)
	numeral.BackgroundTransparency = 0
	numeral.TextColor3 = THEME.text
	local disc = Instance.new("UICorner")
	disc.CornerRadius = UDim.new(0.5, 0)
	disc.Parent = numeral

	local done = Instance.new("ImageLabel")
	done.Name = "Tick"
	done.AnchorPoint = Vector2.new(0.5, 0.5)
	done.Position = UDim2.fromScale(0.5, 0.5)
	done.Size = UDim2.fromOffset(14, 14)
	done.BackgroundTransparency = 1
	done.Image = ICON.check
	done.ImageColor3 = THEME.text
	done.Parent = numeral

	local caption = label(cell, name, 14, 2)
	caption.AutomaticSize = Enum.AutomaticSize.X
	caption.Size = UDim2.fromOffset(0, 16)
	return numeral, done, caption
end

-- The marker is a sibling of the tab row, not a child of its UIListLayout, so
-- it can slide freely; its target is read from the chosen tab's geometry.
-- S4, S5 and S7 stack their tabs down the side instead of across.
local function createTabs(
	parent: GuiObject,
	names: { string },
	style: TabStyle,
	onSelect: (name: string) -> (),
	options: TabOptions?
): Tabs
	local connections: { RBXScriptConnection } = {}
	local buttons: { [string]: TextButton } = {}
	local words: { [string]: TextLabel } = {}
	local glyphs: { [string]: ImageLabel } = {}
	local current = names[1]
	local hovered: string? = nil
	local icons = if options and options.icons then options.icons else {}
	local pages = if options and options.pages then options.pages else {}
	local counts = if options and options.counts then options.counts else {}
	local groups = if options and options.groups then options.groups else {}
	local limit = if options and options.visible then options.visible else 4
	local vertical = style == "S4"
		or style == "S5"
		or style == "S7"
		or style == "S18"
		or style == "S22"
	local marker = MARKER[style]
	local scrolls = style == "S12"
	local stacked = style == "S6" or style == "S13"
	-- S15 steps and S21's arrows need the order; S20's extra tabs live in More.
	local circles: { [string]: TextLabel } = {}
	local ticks: { [string]: ImageLabel } = {}
	local overflow: { [string]: boolean } = {}
	local moreButton: TextButton? = nil
	local moreList: Frame? = nil

	local bar: Frame | ScrollingFrame
	if scrolls then
		local scroller = Instance.new("ScrollingFrame")
		scroller.ScrollingDirection = Enum.ScrollingDirection.X
		scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
		scroller.CanvasSize = UDim2.fromScale(0, 1)
		scroller.CanvasPosition = Vector2.zero
		scroller.ScrollBarThickness = 0
		scroller.BorderSizePixel = 0
		bar = scroller
	else
		bar = Instance.new("Frame")
	end
	bar.Name = "Tabs"
	bar.Size = if vertical
		then UDim2.fromScale(1, 1)
		else UDim2.new(1, 0, 0, if stacked then 56 else 44)
	bar.BackgroundColor3 = THEME.track
	bar.BackgroundTransparency = if style == "S8" then 0 else 1
	bar.Parent = parent

	if style == "S8" then
		local sunk = Instance.new("UICorner")
		sunk.CornerRadius = UDim.new(0, 6)
		sunk.Parent = bar
	end

	local mark = newFrame("Marker", if marker == "pill" then THEME.controlHover else THEME.accent)
	mark.Visible = marker ~= "none"
	mark.ZIndex = 1
	mark.Parent = bar

	local markCorner = Instance.new("UICorner")
	markCorner.CornerRadius = if marker == "dot" then UDim.new(0.5, 0)
		elseif marker == "pill" then UDim.new(0, 6)
		else UDim.new(0, 0)
	markCorner.Parent = mark

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = if scrolls then UDim2.fromScale(0, 1) else UDim2.fromScale(1, 1)
	row.AutomaticSize = if scrolls then Enum.AutomaticSize.X else Enum.AutomaticSize.None
	row.BackgroundTransparency = 1
	row.ZIndex = 2
	row.Parent = bar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection[if vertical then "Vertical" else "Horizontal"]
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, if vertical then 4 else 0)
	layout.Parent = row

	if style == "S8" then
		local inset = Instance.new("UIPadding")
		inset.PaddingTop = UDim.new(0, 4)
		inset.PaddingBottom = UDim.new(0, 4)
		inset.PaddingLeft = UDim.new(0, 4)
		inset.PaddingRight = UDim.new(0, 4)
		inset.Parent = row
	end

	local function moveMarker(instant: boolean)
		local tab: GuiObject = buttons[current]
		if overflow[current] and moreButton then
			tab = moreButton
		end
		local origin = bar.AbsolutePosition
		local canvas = if scrolls then (bar :: ScrollingFrame).CanvasPosition else Vector2.zero
		local x = tab.AbsolutePosition.X - origin.X + canvas.X
		local y = tab.AbsolutePosition.Y - origin.Y + canvas.Y
		local width, height = tab.AbsoluteSize.X, tab.AbsoluteSize.Y
		local position, size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
		if marker == "line" then
			position, size = UDim2.fromOffset(x, y + height - 2), UDim2.fromOffset(width, 2)
		elseif marker == "side" then
			size = UDim2.fromOffset(3, height)
		elseif marker == "dot" then
			position = UDim2.fromOffset(x + width / 2 - 3, y + height - 8)
			size = UDim2.fromOffset(6, 6)
		elseif marker == "top" then
			size = UDim2.fromOffset(width, 2)
		elseif marker == "folder" then
			size = UDim2.fromOffset(width, height + FOLDER_JOIN)
		end
		animate(mark, if instant then INSTANT else SLIDE, { Position = position, Size = size })
	end

	local function paint()
		local at = table.find(names, current) or 1
		for name, tab in buttons do
			local chosen = name == current
			local colour = if chosen or name == hovered then THEME.text else THEME.textMuted
			local weight = if chosen then Enum.Font.GothamBold else Enum.Font.GothamMedium
			tab.TextColor3 = colour
			tab.FontFace = Font.fromEnum(weight)

			local caption = words[name]
			if caption then
				caption.TextColor3 = colour
				caption.FontFace = Font.fromEnum(weight)
				-- S17 names only the chosen tab; the rest show just their icon.
				if style == "S17" then
					caption.Visible = chosen
				end
			end
			local glyph = glyphs[name]
			if glyph then
				glyph.ImageColor3 = if chosen then THEME.focus else colour
				if style == "S22" then
					glyph.Rotation = if chosen then 180 else 0
				end
			end

			if style == "S19" then
				tab.TextSize = if chosen then 20 else 14
			elseif style == "S21" then
				tab.Visible = chosen
			elseif style == "S22" and pages[name] then
				pages[name].Visible = chosen
			end
			-- S15: steps before this one are done and show a tick.
			local numeral, done = circles[name], ticks[name]
			if numeral and done then
				local index = table.find(names, name) or 0
				numeral.BackgroundColor3 = if index <= at then THEME.accent else THEME.controlHover
				numeral.Text = if index < at then "" else tostring(index)
				done.Visible = index < at
			end
		end
	end

	local function select(name: string)
		if name == current or not buttons[name] then
			return
		end
		local before = table.find(names, current) or 0
		local after = table.find(names, name) or 0
		if style ~= "S22" then
			turnPage(style, pages[current], pages[name], after > before)
		end
		if moreList then
			moreList.Visible = false
		end
		current = name
		paint()
		moveMarker(false)
		if scrolls then
			local scroller = bar :: ScrollingFrame
			local tab = buttons[name]
			local canvas = scroller.CanvasPosition.X
			local left = tab.AbsolutePosition.X - scroller.AbsolutePosition.X + canvas
			local visible = scroller.AbsoluteSize.X
			local target = math.clamp(left - (visible - tab.AbsoluteSize.X) / 2, 0, math.huge)
			animate(scroller, SLIDE, { CanvasPosition = Vector2.new(target, 0) })
		end
		onSelect(name)
	end

	-- S20: tabs past the limit wait in a list under a More tab.
	if style == "S20" and #names > limit then
		local more = Instance.new("TextButton")
		more.Name = "More"
		more.LayoutOrder = limit + 1
		more.AutoButtonColor = false
		more.BackgroundTransparency = 1
		more.Size = UDim2.fromScale(0, 1)
		more.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		more.TextSize = 14
		more.TextColor3 = THEME.textMuted
		more.Text = "More"
		more.Parent = row
		local share = Instance.new("UIFlexItem")
		share.FlexMode = Enum.UIFlexMode.Fill
		share.Parent = more
		moreButton = more

		local list = newFrame("MoreList", THEME.control)
		list.AnchorPoint = Vector2.new(1, 0)
		list.Position = UDim2.new(1, 0, 1, 4)
		list.AutomaticSize = Enum.AutomaticSize.Y
		list.Size = UDim2.fromOffset(160, 0)
		list.Visible = false
		list.ZIndex = 3
		list.Parent = bar
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, 6)
		round.Parent = list
		local column = Instance.new("UIListLayout")
		column.SortOrder = Enum.SortOrder.LayoutOrder
		column.Parent = list
		moreList = list

		table.insert(connections, more.Activated:Connect(function()
			list.Visible = not list.Visible
		end))
	end

	local lastGroup: string? = nil
	for index, name in names do
		-- S18: a heading above the first tab of each group.
		local section = groups[name]
		if style == "S18" and section and section ~= lastGroup then
			lastGroup = section
			local heading = label(row, section:upper(), 12, index * 2 - 1, `{section}Heading`)
			heading.TextColor3 = THEME.textMuted
			heading.TextXAlignment = Enum.TextXAlignment.Left
		end

		local tab = Instance.new("TextButton")
		tab.Name = name
		tab.LayoutOrder = if style == "S18" or style == "S22" then index * 2 else index
		tab.AutoButtonColor = false
		tab.BackgroundTransparency = 1
		tab.TextSize = 14
		tab.Text = name
		local spare = moreList
		if style == "S20" and index > limit and spare then
			overflow[name] = true
			tab.Size = UDim2.new(1, 0, 0, 44)
			tab.Parent = spare
		else
			tab.Parent = row
		end

		if overflow[name] then
			tab.TextXAlignment = Enum.TextXAlignment.Left
			local inset = Instance.new("UIPadding")
			inset.PaddingLeft = UDim.new(0, 12)
			inset.Parent = tab
		elseif vertical then
			tab.Size = UDim2.new(1, 0, 0, 44)
			tab.TextXAlignment = Enum.TextXAlignment.Left
			local inset = Instance.new("UIPadding")
			inset.PaddingLeft = UDim.new(0, 16)
			inset.Parent = tab
		elseif scrolls then
			tab.AutomaticSize = Enum.AutomaticSize.X
			tab.Size = UDim2.fromScale(0, 1)
			local inset = Instance.new("UIPadding")
			inset.PaddingLeft = UDim.new(0, 16)
			inset.PaddingRight = UDim.new(0, 16)
			inset.Parent = tab
		else
			tab.Size = UDim2.fromScale(0, 1)
			local share = Instance.new("UIFlexItem")
			share.FlexMode = Enum.UIFlexMode.Fill
			share.Parent = tab
		end

		-- S14: a count in the tab's top corner, placed outside any layout.
		local count = counts[name]
		if style == "S14" and count then
			local badge = Instance.new("TextLabel")
			badge.Name = "Count"
			badge.AnchorPoint = Vector2.new(1, 0)
			badge.Position = UDim2.new(1, -4, 0, 4)
			badge.AutomaticSize = Enum.AutomaticSize.X
			badge.Size = UDim2.fromOffset(16, 16)
			badge.BackgroundColor3 = THEME.accent
			badge.FontFace = Font.fromEnum(Enum.Font.GothamBold)
			badge.TextSize = 12
			badge.TextColor3 = THEME.text
			badge.Text = tostring(count)
			badge.Parent = tab
			local pill = Instance.new("UICorner")
			pill.CornerRadius = UDim.new(0.5, 0)
			pill.Parent = badge
		end

		if style == "S15" then
			local numeral, done, caption = stepContent(tab, name, index)
			circles[name], ticks[name], words[name] = numeral, done, caption
		end

		-- S22: each tab heads its own section, with an arrow that turns open.
		if style == "S22" then
			tab.TextXAlignment = Enum.TextXAlignment.Left
			local chevron = Instance.new("ImageLabel")
			chevron.Name = "Glyph"
			chevron.AnchorPoint = Vector2.new(1, 0.5)
			chevron.Position = UDim2.new(1, -12, 0.5, 0)
			chevron.Size = UDim2.fromOffset(16, 16)
			chevron.BackgroundTransparency = 1
			chevron.Image = ICON.open
			chevron.Parent = tab
			glyphs[name] = chevron
			local page = pages[name]
			if page then
				page.LayoutOrder = index * 2 + 1
				page.Parent = row
			end
		end

		if stacked or style == "S7" or style == "S17" then
			local glyph, caption = iconContent(tab, name, icons[name] or ICON.tab, style)
			glyphs[name] = glyph
			words[name] = caption
		end

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.focus
		ring.Thickness = 2
		ring.Enabled = false
		ring.Parent = tab

		buttons[name] = tab
		table.insert(connections, tab.Activated:Connect(function()
			select(name)
		end))
		table.insert(connections, tab.MouseEnter:Connect(function()
			hovered = name
			paint()
		end))
		table.insert(connections, tab.MouseLeave:Connect(function()
			if hovered == name then
				hovered = nil
			end
			paint()
		end))
		table.insert(connections, tab.SelectionGained:Connect(function()
			ring.Enabled = true
		end))
		table.insert(connections, tab.SelectionLost:Connect(function()
			ring.Enabled = false
		end))
	end

	-- S21: one tab name at a time, with arrows either side that wrap.
	if style == "S21" then
		for order, step in { -1, 1 } do
			local stepper = Instance.new("ImageButton")
			stepper.Name = if step < 0 then "Previous" else "Next"
			stepper.LayoutOrder = if order == 1 then 0 else #names + 1
			stepper.Size = UDim2.fromOffset(44, 44)
			stepper.AutoButtonColor = false
			stepper.BackgroundTransparency = 1
			stepper.Image = if step < 0 then ICON.previous else ICON.next
			stepper.ImageColor3 = THEME.textMuted
			stepper.Parent = row
			table.insert(connections, stepper.Activated:Connect(function()
				local at = table.find(names, current) or 1
				select(names[(at - 1 + step) % #names + 1])
			end))
		end
	end

	for name, page in pages do
		page.Visible = name == current
		page.GroupTransparency = if name == current then 0 else 1
	end
	table.insert(connections, bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		moveMarker(true)
	end))
	paint()
	moveMarker(true)

	return {
		select = select,
		selected = function()
			return current
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			bar:Destroy()
		end,
	}
end

return {
	attachPress = attachPress,
	attachAction = attachAction,
	createTabs = createTabs,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/toasts.luau

```lua
--!strict
-- lint: complete
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Placement = "N1" | "N2" | "N4" | "N7" | "N11" | "N12" | "N13" | "N14" | "N19"
export type Severity = "info" | "success" | "warning" | "error"

export type ProgressHandle = {
	done: (message: string, severity: Severity?) -> (),
}

export type PercentHandle = {
	set: (fraction: number) -> (),
	done: (message: string, severity: Severity?) -> (),
}

-- `title` is shown by N13 and ignored elsewhere. N17, N21, N22, N24 and N28
-- are methods that work on any placement: `countdown`, `player`, `percent`,
-- `sticky` and `invite`.
export type Notifier = {
	push: (message: string, severity: Severity?, key: string?, title: string?) -> (),
	progress: (message: string) -> ProgressHandle,
	action: (message: string, actionLabel: string, onAction: () -> ()) -> (),
	countdown: (message: string, seconds: number, onZero: (() -> ())?) -> (),
	player: (message: string, userId: number) -> (),
	percent: (message: string) -> PercentHandle,
	sticky: (message: string, severity: Severity?) -> (),
	invite: (message: string, onAccept: () -> (), onDecline: (() -> ())?) -> (),
	destroy: () -> (),
}

-- The toast reads the same surface entry as the panel it sits beside, so fill,
-- edge and radius cannot drift apart between the two.
local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	action = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	success = "rbxassetid://88244323237265",
	warning = "rbxassetid://91165848022002",
	error = "rbxassetid://106305483906363",
	close = "rbxassetid://116396312853810",
	loading = "rbxassetid://71250150569964",
}

type Look = "plain" | "pill" | "titled" | "edge" | "deck"

type Layout = {
	anchor: Vector2,
	direction: number,
	arrive: Vector2,
	timed: boolean,
	look: Look,
}

-- direction is which way the stack grows from its anchor; arrive is where a new
-- toast starts before it settles into its slot; timed stacks show a time-left bar.
local function stackAt(
	anchor: Vector2,
	direction: number,
	arrive: Vector2,
	timed: boolean,
	look: Look
): Layout
	return { anchor = anchor, direction = direction, arrive = arrive, timed = timed, look = look }
end

local BOTTOM_RIGHT = Vector2.new(1, 1)
local FROM_RIGHT = Vector2.new(24, 0)

local PLACEMENT: { [Placement]: Layout } = {
	N1 = stackAt(Vector2.new(0.5, 1), -1, Vector2.new(0, 12), false, "plain"),
	N2 = stackAt(Vector2.new(0.5, 0), 1, Vector2.new(0, -8), false, "plain"),
	N4 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "plain"),
	N7 = stackAt(Vector2.new(1, 0), 1, FROM_RIGHT, true, "plain"),
	N11 = stackAt(Vector2.new(0, 1), -1, Vector2.new(-24, 0), true, "plain"),
	N12 = stackAt(Vector2.new(0.5, 1), -1, Vector2.new(0, 12), false, "pill"),
	N13 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "titled"),
	N14 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "edge"),
	N19 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "deck"),
}

local MAX_VISIBLE = 3
local MAX_QUEUED = 10
local GAP = 8
local EDGE_INSET = 16
local MIN_HOLD = 1.5
local ACTION_HOLD = 6
-- An invite waits long enough to finish what you were doing, then goes quietly.
local INVITE_HOLD = 10
local AVATAR = 32
local SETTLE_TIME = 0.12
local SPIN_DEGREES_PER_SECOND = 360
-- N19: how far each older card peeks out, and how much smaller it is per step.
local DECK_PEEK = 8
local DECK_SHRINK = 0.05
local FADE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)

type TimedKind = "plain" | "progress" | "action" | "countdown"
type Kind = TimedKind | "player" | "percent" | "sticky" | "invite"

type Request = {
	message: string,
	severity: Severity,
	key: string?,
	title: string?,
	kind: Kind,
	actionLabel: string?,
	onAction: (() -> ())?,
	onDecline: (() -> ())?,
	seconds: number?,
	userId: number?,
	fraction: number?,
	toast: Toast?,
}

type Toast = {
	request: Request,
	count: number,
	card: CanvasGroup,
	content: Frame,
	icon: ImageLabel,
	label: TextLabel,
	timerBar: Frame?,
	percent: TextLabel?,
	dismiss: ImageButton?,
	depth: UIScale?,
	offset: Vector2,
	velocity: Vector2,
	goal: Vector2,
	height: number,
	lifetime: number,
	remaining: number,
	held: boolean,
	connections: { RBXScriptConnection },
}

local function readingTime(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.max(MIN_HOLD, math.clamp(2 + words * 0.3, 3, 8))
end

local function createNotifier(screen: ScreenGui, placement: Placement): Notifier
	local layout = PLACEMENT[placement]
	local shown: { Toast } = {}
	local waiting: { Request } = {}
	local byKey: { [string]: Toast } = {}
	local loop: RBXScriptConnection? = nil
	local spread = false

	local stack = Instance.new("Frame")
	stack.Name = "Notifications"
	stack.AnchorPoint = layout.anchor
	stack.Position = UDim2.new(
		layout.anchor.X,
		(0.5 - layout.anchor.X) * 2 * EDGE_INSET,
		layout.anchor.Y,
		(0.5 - layout.anchor.Y) * 2 * EDGE_INSET
	)
	stack.Size = UDim2.new(1, -EDGE_INSET * 2, 1, -EDGE_INSET * 2)
	stack.BackgroundTransparency = 1
	stack.Parent = screen

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(240, 0)
	bounds.MaxSize = Vector2.new(360, math.huge)
	bounds.Parent = stack

	local function place(toast: Toast)
		local anchor = layout.anchor
		toast.card.Position = UDim2.new(anchor.X, toast.offset.X, anchor.Y, toast.offset.Y)
	end

	-- Targets come from list order, never from a stored slot, so the toast under
	-- one that leaves early moves up while it may still be arriving. A closed
	-- deck (N19) piles older cards behind the newest instead.
	local function restack()
		local travelled = 0
		for index, toast in shown do
			local behind = #shown - index
			local depth = toast.depth
			if depth and not spread then
				toast.goal = Vector2.new(0, behind * DECK_PEEK * layout.direction)
				depth.Scale = 1 - behind * DECK_SHRINK
				toast.card.ZIndex = MAX_VISIBLE - behind + 1
				continue
			end
			if depth then
				depth.Scale = 1
			end
			toast.goal = Vector2.new(0, travelled * layout.direction)
			travelled += toast.height + GAP
		end
	end

	local release: (toast: Toast) -> ()
	local present: (request: Request) -> ()

	local function step(dt: number)
		for index = #shown, 1, -1 do
			local toast = shown[index]
			local goal, velocity = toast.goal, toast.velocity
			toast.offset, toast.velocity =
				TweenService:SmoothDamp(toast.offset, goal, velocity, SETTLE_TIME, nil, dt)
			place(toast)

			local request = toast.request
			if request.kind == "progress" then
				toast.icon.Rotation = (toast.icon.Rotation + dt * SPIN_DEGREES_PER_SECOND) % 360
				continue
			end
			-- A percent toast waits for its work, and a sticky one for the player.
			if request.kind == "percent" or request.kind == "sticky" then
				continue
			end
			-- A countdown tracks real time, so hovering never pauses it.
			local counting = request.kind == "countdown"
			if (toast.held and not counting) or request.severity == "error" then
				continue
			end
			toast.remaining -= dt
			local timerBar = toast.timerBar
			if timerBar then
				timerBar.Size = UDim2.new(math.max(toast.remaining / toast.lifetime, 0), 0, 0, 2)
			end
			if counting then
				toast.label.Text = `{request.message} {math.max(math.ceil(toast.remaining), 0)}s`
			end
			if toast.remaining <= 0 then
				release(toast)
				local onZero = request.onAction
				if counting and onZero then
					onZero()
				end
			end
		end
		if #shown == 0 and loop then
			loop:Disconnect()
			loop = nil
		end
	end

	function release(toast: Toast)
		local index = table.find(shown, toast)
		if not index then
			return
		end
		table.remove(shown, index)
		if toast.request.key then
			byKey[toast.request.key] = nil
		end
		for _, connection in toast.connections do
			connection:Disconnect()
		end
		restack()

		local fade = TweenService:Create(toast.card, FADE_OUT, { GroupTransparency = 1 })
		fade.Completed:Once(function()
			toast.card:Destroy()
		end)
		fade:Play()

		local nextRequest = table.remove(waiting, 1)
		if nextRequest then
			present(nextRequest)
		end
	end

	local function addDismiss(toast: Toast)
		local dismiss = Instance.new("ImageButton")
		dismiss.Name = "Dismiss"
		dismiss.LayoutOrder = 4
		dismiss.Size = UDim2.fromOffset(44, 44)
		dismiss.AutoButtonColor = false
		dismiss.BackgroundTransparency = 1
		dismiss.Image = ""
		dismiss.Parent = toast.content

		local ink = Instance.new("ImageLabel")
		ink.Name = "Ink"
		ink.AnchorPoint = Vector2.new(0.5, 0.5)
		ink.Position = UDim2.fromScale(0.5, 0.5)
		ink.Size = UDim2.fromOffset(16, 16)
		ink.BackgroundTransparency = 1
		ink.Image = ICON.close
		ink.ImageColor3 = THEME.text
		ink.Parent = dismiss

		toast.dismiss = dismiss
		table.insert(toast.connections, dismiss.Activated:Connect(function()
			release(toast)
		end))
	end

	-- The row lives in its own frame so the timer bar can sit on the card's
	-- bottom edge; a child of a UIListLayout would be placed in the row.
	local function addTimer(toast: Toast)
		local timerBar = Instance.new("Frame")
		timerBar.Name = "TimeLeft"
		timerBar.AnchorPoint = Vector2.new(0, 1)
		timerBar.Position = UDim2.fromScale(0, 1)
		timerBar.Size = UDim2.new(1, 0, 0, 2)
		timerBar.BackgroundColor3 = THEME[toast.request.severity]
		timerBar.BorderSizePixel = 0
		timerBar.Parent = toast.card
		toast.timerBar = timerBar
	end

	local function addAction(
		toast: Toast,
		actionLabel: string,
		onAction: () -> (),
		order: number?,
		name: string?
	)
		local button = Instance.new("TextButton")
		button.Name = name or "Action"
		button.LayoutOrder = order or 3
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, 44)
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1
		button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		button.TextSize = 14
		button.TextColor3 = if name == "Decline" then THEME.textMuted else THEME.action
		button.Text = actionLabel
		button.Parent = toast.content

		table.insert(toast.connections, button.Activated:Connect(function()
			onAction()
			release(toast)
		end))
	end

	-- N22: the bar on the bottom edge is the work done, not the time left.
	local function addPercent(toast: Toast)
		local number = Instance.new("TextLabel")
		number.Name = "Percent"
		number.LayoutOrder = 3
		number.AutomaticSize = Enum.AutomaticSize.X
		number.Size = UDim2.fromScale(0, 1)
		number.BackgroundTransparency = 1
		number.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		number.TextSize = 14
		number.TextColor3 = THEME.text
		number.Text = "0%"
		number.Parent = toast.content
		toast.percent = number

		local bar = Instance.new("Frame")
		bar.Name = "Done"
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.fromScale(0, 1)
		bar.Size = UDim2.new(0, 0, 0, 2)
		bar.BackgroundColor3 = THEME.info
		bar.BorderSizePixel = 0
		bar.Parent = toast.card
		toast.timerBar = bar
	end

	-- N13: a bold title over the message, both left-aligned beside the icon.
	local function addTitle(content: Frame, label: TextLabel, title: string)
		local words = Instance.new("Frame")
		words.Name = "Words"
		words.LayoutOrder = 2
		words.AutomaticSize = Enum.AutomaticSize.Y
		words.Size = UDim2.fromScale(0, 0)
		words.BackgroundTransparency = 1
		words.Parent = content

		local grow = Instance.new("UIFlexItem")
		grow.FlexMode = Enum.UIFlexMode.Fill
		grow.Parent = words

		local column = Instance.new("UIListLayout")
		column.SortOrder = Enum.SortOrder.LayoutOrder
		column.Padding = UDim.new(0, 4)
		column.Parent = words

		local heading = Instance.new("TextLabel")
		heading.Name = "Title"
		heading.LayoutOrder = 1
		heading.AutomaticSize = Enum.AutomaticSize.Y
		heading.Size = UDim2.fromScale(1, 0)
		heading.BackgroundTransparency = 1
		heading.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		heading.TextSize = 14
		heading.TextColor3 = THEME.text
		heading.TextWrapped = true
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.Text = title
		heading.Parent = words

		label.LayoutOrder = 2
		label.Size = UDim2.fromScale(1, 0)
		label.TextColor3 = THEME.textMuted
		label.Parent = words
	end

	local function build(request: Request): Toast
		local look = layout.look
		local pill = look == "pill"
		local card = Instance.new("CanvasGroup")
		card.Name = "Toast"
		card.AnchorPoint = layout.anchor
		card.AutomaticSize = if pill then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
		card.Size = if pill then UDim2.fromScale(0, 0) else UDim2.fromScale(1, 0)
		card.BackgroundColor3 = THEME.surface
		card.GroupTransparency = 1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = if pill then UDim.new(0.5, 0) else UDim.new(0, 10)
		corner.Parent = card

		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = THEME.edge
		edge.Parent = card

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.AutomaticSize = if pill then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
		content.Size = if pill then UDim2.fromScale(0, 0) else UDim2.fromScale(1, 0)
		content.BackgroundTransparency = 1
		content.Parent = card

		-- A pill is short and wide; the coloured edge (N14) needs room beside it.
		local vertical = if pill then 8 else 12
		local horizontal = if pill then 16 else 12
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, vertical)
		padding.PaddingBottom = UDim.new(0, vertical)
		padding.PaddingLeft = UDim.new(0, if look == "edge" then 16 else horizontal)
		padding.PaddingRight = UDim.new(0, horizontal)
		padding.Parent = content

		if look == "edge" then
			local strip = Instance.new("Frame")
			strip.Name = "Edge"
			strip.Size = UDim2.new(0, 4, 1, 0)
			strip.BackgroundColor3 = THEME[request.severity]
			strip.BorderSizePixel = 0
			strip.Parent = card
		end

		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.SortOrder = Enum.SortOrder.LayoutOrder
		row.Padding = UDim.new(0, 12)
		row.Parent = content

		local progress = request.kind == "progress"
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.LayoutOrder = 1
		icon.Size = UDim2.fromOffset(20, 20)
		icon.BackgroundTransparency = 1
		icon.Image = if progress then ICON.loading else ICON[request.severity]
		icon.Rotation = 0
		icon.ImageColor3 = THEME[request.severity]

		-- N21: the player's headshot in place of the severity icon.
		local userId = request.userId
		if request.kind == "player" and userId then
			icon.Name = "Avatar"
			icon.Size = UDim2.fromOffset(AVATAR, AVATAR)
			icon.Image = `rbxthumb://type=AvatarHeadShot&id={userId}&w=48&h=48`
			icon.ImageColor3 = THEME.text
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(0.5, 0)
			round.Parent = icon
		end
		icon.Parent = content

		local label = Instance.new("TextLabel")
		label.Name = "Message"
		label.LayoutOrder = 2
		label.AutomaticSize = if pill then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
		label.Size = UDim2.fromScale(0, 0)
		label.BackgroundTransparency = 1
		label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		label.TextSize = 14
		label.TextColor3 = THEME.text
		label.TextWrapped = not pill
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = if request.kind == "countdown"
			then `{request.message} {math.ceil(request.seconds or 0)}s`
			else request.message

		local title = request.title
		if look == "titled" and title then
			addTitle(content, label, title)
		else
			label.Parent = content
			if not pill then
				local fill = Instance.new("UIFlexItem")
				fill.FlexMode = Enum.UIFlexMode.Fill
				fill.Parent = label
			end
		end

		local lifetime = readingTime(request.message)
		if request.kind == "action" then
			lifetime = math.max(lifetime, ACTION_HOLD)
		elseif request.kind == "countdown" then
			lifetime = request.seconds or lifetime
		elseif request.kind == "invite" then
			lifetime = INVITE_HOLD
		end

		local toast: Toast = {
			request = request,
			count = 1,
			card = card,
			content = content,
			icon = icon,
			label = label,
			timerBar = nil,
			percent = nil,
			dismiss = nil,
			depth = nil,
			offset = Vector2.zero,
			velocity = Vector2.zero,
			goal = Vector2.zero,
			height = 48,
			lifetime = lifetime,
			remaining = lifetime,
			held = false,
			connections = {},
		}
		request.toast = toast
		if look == "deck" then
			local depth = Instance.new("UIScale")
			depth.Name = "Depth"
			depth.Parent = card
			toast.depth = depth
		end

		local actionLabel, onAction = request.actionLabel, request.onAction
		local inviting = request.kind == "invite"
		if actionLabel and onAction then
			local order, name = if inviting then 4 else 3, if inviting then "Accept" else nil
			addAction(toast, actionLabel, onAction, order, name)
		end
		if inviting then
			addAction(toast, "Decline", request.onDecline or function() end, 3, "Decline")
		end
		if request.kind == "percent" then
			addPercent(toast)
		elseif request.severity == "error" or request.kind == "sticky" then
			addDismiss(toast)
		elseif (layout.timed or request.kind == "countdown" or inviting) and not progress then
			addTimer(toast)
		end

		table.insert(toast.connections, card.MouseEnter:Connect(function()
			toast.held = true
			if look == "deck" then
				spread = true
				restack()
			end
		end))
		table.insert(toast.connections, card.MouseLeave:Connect(function()
			toast.held = false
			if look == "deck" then
				spread = false
				restack()
			end
		end))
		local resized = card:GetPropertyChangedSignal("AbsoluteSize")
		table.insert(toast.connections, resized:Connect(function()
			toast.height = card.AbsoluteSize.Y
			restack()
		end))
		return toast
	end

	function present(request: Request)
		local toast = build(request)
		table.insert(shown, toast)
		if request.key then
			byKey[request.key] = toast
		end
		restack()
		toast.offset = toast.goal + layout.arrive
		place(toast)
		toast.card.Parent = stack
		TweenService:Create(toast.card, FADE_IN, { GroupTransparency = 0 }):Play()
		if not loop then
			loop = RunService.PreRender:Connect(step)
		end
	end

	local function enqueue(request: Request)
		if #shown < MAX_VISIBLE then
			present(request)
			return
		end
		if #waiting >= MAX_QUEUED then
			table.remove(waiting, 1)
		end
		table.insert(waiting, request)
	end

	local function push(message: string, severity: Severity?, key: string?, title: string?)
		local repeated = if key then byKey[key] else nil
		if repeated then
			repeated.count += 1
			repeated.label.Text = `{repeated.request.message} ×{repeated.count}`
			repeated.remaining = repeated.lifetime
			return
		end
		enqueue({
			message = message,
			severity = severity or "info",
			key = key,
			title = title,
			kind = "plain",
		})
	end

	-- A progress toast spins until `done`; a request still in the queue simply
	-- arrives already finished.
	local function progress(message: string): ProgressHandle
		local request: Request = { message = message, severity = "info", kind = "progress" }
		enqueue(request)
		return {
			done = function(result: string, severity: Severity?)
				request.kind = "plain"
				request.message = result
				request.severity = severity or "success"
				local toast = request.toast
				if not toast then
					return
				end
				toast.icon.Rotation = 0
				toast.icon.Image = ICON[request.severity]
				toast.icon.ImageColor3 = THEME[request.severity]
				toast.label.Text = result
				toast.lifetime = readingTime(result)
				toast.remaining = toast.lifetime
				if request.severity == "error" then
					addDismiss(toast)
				elseif layout.timed then
					addTimer(toast)
				end
			end,
		}
	end

	local function action(message: string, actionLabel: string, onAction: () -> ())
		enqueue({
			message = message,
			severity = "info",
			kind = "action",
			actionLabel = actionLabel,
			onAction = onAction,
		})
	end

	-- N17: the seconds left follow the message and the bar drains in real time;
	-- `onZero` runs once when it reaches zero, never if the notifier is destroyed.
	local function countdown(message: string, seconds: number, onZero: (() -> ())?)
		enqueue({
			message = message,
			severity = "warning",
			kind = "countdown",
			seconds = seconds,
			onAction = onZero,
		})
	end

	local function player(message: string, userId: number)
		enqueue({ message = message, severity = "info", kind = "player", userId = userId })
	end

	-- N22: `set` moves the bar and the number; `done` turns it into a result
	-- that times out like any other toast.
	local function percent(message: string): PercentHandle
		local request: Request = {
			message = message,
			severity = "info",
			kind = "percent",
			fraction = 0,
		}
		enqueue(request)
		local function show()
			local toast = request.toast
			local fraction = request.fraction or 0
			if toast and toast.percent and toast.timerBar then
				toast.percent.Text = `{math.floor(fraction * 100 + 0.5)}%`
				toast.timerBar.Size = UDim2.new(fraction, 0, 0, 2)
			end
		end
		return {
			set = function(fraction: number)
				request.fraction = math.clamp(fraction, 0, 1)
				show()
			end,
			done = function(result: string, severity: Severity?)
				request.kind = "plain"
				request.message = result
				request.severity = severity or "success"
				local toast = request.toast
				if not toast then
					return
				end
				toast.icon.Image = ICON[request.severity]
				toast.icon.ImageColor3 = THEME[request.severity]
				toast.label.Text = result
				toast.lifetime = readingTime(result)
				toast.remaining = toast.lifetime
				if toast.percent then
					toast.percent:Destroy()
					toast.percent = nil
				end
				if toast.timerBar then
					toast.timerBar.Size = UDim2.new(1, 0, 0, 2)
				end
			end,
		}
	end

	-- N24: stays until the player closes it, whatever its severity.
	local function sticky(message: string, severity: Severity?)
		enqueue({ message = message, severity = severity or "info", kind = "sticky" })
	end

	-- N28: Accept and Decline each run once; unanswered, it leaves after ten
	-- seconds without calling either.
	local function invite(message: string, onAccept: () -> (), onDecline: (() -> ())?)
		enqueue({
			message = message,
			severity = "info",
			kind = "invite",
			actionLabel = "Accept",
			onAction = onAccept,
			onDecline = onDecline,
		})
	end

	return {
		push = push,
		progress = progress,
		action = action,
		countdown = countdown,
		player = player,
		percent = percent,
		sticky = sticky,
		invite = invite,
		destroy = function()
			if loop then
				loop:Disconnect()
				loop = nil
			end
			for _, toast in shown do
				for _, connection in toast.connections do
					connection:Disconnect()
				end
			end
			table.clear(shown)
			table.clear(waiting)
			table.clear(byKey)
			stack:Destroy()
		end,
	}
end

return createNotifier
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/toggles.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local THEME = {
	row = Color3.fromRGB(31, 34, 41),
	rowHover = Color3.fromRGB(44, 48, 57),
	track = Color3.fromRGB(63, 68, 79),
	knob = Color3.fromRGB(243, 245, 248),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(118, 125, 139),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	keyBase = Color3.fromRGB(19, 21, 26),
}

local ICON = {
	check = "rbxassetid://86817768619372",
	cross = "rbxassetid://116396312853810",
	eye = "rbxassetid://127234874352422",
	eyeOff = "rbxassetid://85207295981701",
	power = "rbxassetid://89331085993646",
	feature = "rbxassetid://109718589733073",
}

local STATE_MOTION = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NO_MOTION = TweenInfo.new(0)
-- Plays forward then back, so the knob is wide only mid-travel.
local STRETCH = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

type FirstTen = "T1" | "T2" | "T3" | "T4" | "T5" | "T6" | "T7" | "T8" | "T9" | "T10"
type SecondTen = "T11" | "T12" | "T13" | "T14" | "T15" | "T16" | "T17" | "T18" | "T19" | "T20"
type ThirdTen = "T21" | "T22" | "T23" | "T24" | "T25" | "T26" | "T27" | "T28" | "T29" | "T30"
export type ToggleStyle = FirstTen | SecondTen | ThirdTen

-- T19 reads `description`, T20 reads `icon`, T29 reads `key`; the other styles
-- ignore all three.
export type ToggleDetails = {
	description: string?,
	icon: string?,
	key: string?,
}

export type Toggle = {
	row: TextButton,
	set: (value: boolean) -> (),
	get: () -> boolean,
	setEnabled: (enabled: boolean) -> (),
	destroy: () -> (),
}

-- Before the row is parented there is nothing on screen to animate, so the
-- first paint assigns directly instead of sliding in from the default values.
local function animate(instance: Instance, goals: { [string]: any })
	if not instance:IsDescendantOf(game) then
		for property, goal in goals do
			(instance :: any)[property] = goal
		end
		return
	end
	local timing = if GuiService.ReducedMotionEnabled then NO_MOTION else STATE_MOTION
	TweenService:Create(instance, timing, goals):Play()
end

local function round(target: GuiObject, radius: UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
	return corner
end

local function newIcon(name: string, size: number, image: string): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.Image = image
	return icon
end

local function newFrame(name: string, size: UDim2, colour: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	return frame
end

-- T1 and T2 differ only in corner radius; the knob position carries the state,
-- so the track colour is never the only signal.
local function switchSkin(
	row: TextButton,
	radius: UDim,
	knobRadius: UDim,
	order: number?
): ((boolean) -> (), Frame)
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = order or 2
	round(track, radius)
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, knobRadius)
	knob.Parent = track

	local function paint(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
	return paint, track
end

local function tickSkin(row: TextButton): (boolean) -> ()
	local box = newFrame("Box", UDim2.fromOffset(22, 22), THEME.row)
	box.LayoutOrder = 0
	round(box, UDim.new(0, 6))
	box.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = box

	local tick = Instance.new("ImageLabel")
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(16, 16)
	tick.BackgroundTransparency = 1
	tick.Image = ICON.check
	tick.ImageColor3 = THEME.knob
	tick.Parent = box

	local grow = Instance.new("UIScale")
	grow.Parent = tick

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
		animate(grow, { Scale = if on then 1 else 0.8 })
	end
end

local function lightSkin(row: TextButton, label: TextLabel): (boolean) -> ()
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.LayoutOrder = 2
	status.AutomaticSize = Enum.AutomaticSize.X
	status.Size = UDim2.fromScale(0, 1)
	status.BackgroundTransparency = 1
	status.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	status.TextSize = 12
	status.Text = "OFF"
	status.Parent = row

	return function(on: boolean)
		status.Text = if on then "ON" else "OFF"
		animate(status, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

local function iconSkin(row: TextButton): (boolean) -> ()
	local badge = newFrame("Badge", UDim2.fromOffset(32, 32), THEME.track)
	badge.LayoutOrder = 0
	round(badge, UDim.new(0, 6))
	badge.Parent = row

	local glyph = Instance.new("ImageLabel")
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromOffset(16, 16)
	glyph.BackgroundTransparency = 1
	glyph.Parent = badge

	return function(on: boolean)
		glyph.Image = if on then ICON.eye else ICON.eyeOff
		animate(glyph, { ImageColor3 = if on then THEME.knob else THEME.textMuted })
		animate(badge, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T7: the knob carries the answer as a tick or a cross.
local function knobIconSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	local mark = Instance.new("ImageLabel")
	mark.Name = "Mark"
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromOffset(12, 12)
	mark.BackgroundTransparency = 1
	mark.Parent = knob

	return function(on: boolean)
		mark.Image = if on then ICON.check else ICON.cross
		mark.ImageColor3 = if on then THEME.accent else THEME.textMuted
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T8: the word sits inside the track, on the side the knob has left.
local function wordSwitchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local word = Instance.new("TextLabel")
	word.Name = "Word"
	word.AnchorPoint = Vector2.new(0, 0.5)
	word.Size = UDim2.fromOffset(28, 24)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.TextColor3 = THEME.knob
	word.Text = "OFF"
	word.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		word.Position = UDim2.new(0, if on then 4 else 24, 0.5, 0)
		animate(knob, { Position = UDim2.new(0, if on then 35 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T9: a small light plus the word, so the state never rests on the colour.
local function statusDotSkin(row: TextButton): (boolean) -> ()
	local dot = newFrame("Dot", UDim2.fromOffset(8, 8), THEME.track)
	dot.LayoutOrder = 2
	round(dot, UDim.new(0.5, 0))
	dot.Parent = row

	local word = Instance.new("TextLabel")
	word.Name = "Status"
	word.LayoutOrder = 3
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.Text = "OFF"
	word.Parent = row

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		animate(word, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		animate(dot, { BackgroundColor3 = if on then THEME.focus else THEME.track })
	end
end

-- T10: T3's tick in a circle, for lists where square boxes feel heavy.
local function roundTickSkin(row: TextButton): (boolean) -> ()
	local ring = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	ring.LayoutOrder = 0
	round(ring, UDim.new(0.5, 0))
	ring.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = ring

	local tick = Instance.new("ImageLabel")
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(14, 14)
	tick.BackgroundTransparency = 1
	tick.Image = ICON.check
	tick.ImageColor3 = THEME.knob
	tick.Parent = ring

	local grow = Instance.new("UIScale")
	grow.Parent = tick

	return function(on: boolean)
		animate(ring, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
		animate(grow, { Scale = if on then 1 else 0.6 })
	end
end

-- T11: a thin rail with a knob that overhangs it, as on Android.
local function railSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(36, 14), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(20, 20), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, {
			Position = UDim2.new(0, if on then 19 else -3, 0.5, 0),
			BackgroundColor3 = if on then THEME.accent else THEME.knob,
		})
		animate(track, { BackgroundColor3 = if on then THEME.accentDim else THEME.track })
	end
end

-- T12: a hollow track; the outline and the knob take the accent together.
local function outlineSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.row)
	track.LayoutOrder = 2
	track.BackgroundTransparency = 1
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(14, 14), THEME.textMuted)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, {
			Position = UDim2.new(0, if on then 25 else 5, 0.5, 0),
			BackgroundColor3 = if on then THEME.accent else THEME.textMuted,
		})
		animate(outline, { Color = if on then THEME.accent else THEME.track })
	end
end

-- T13: T1 at thumb size for touch-first screens.
local function bigSwitchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 32), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(26, 26), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 27 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T14: the whole row is a pill chip; a tick appears before the label when on.
local function chipSkin(row: TextButton, rowCorner: UICorner): (boolean) -> ()
	rowCorner.CornerRadius = UDim.new(0.5, 0)
	local tick = newIcon("Tick", 16, ICON.check)
	tick.LayoutOrder = 0
	tick.ImageColor3 = THEME.focus
	tick.Parent = row

	return function(on: boolean)
		tick.Visible = on
	end
end

-- T15: a round power button, with the state spelled out beside it.
local function powerSkin(row: TextButton): (boolean) -> ()
	local word = Instance.new("TextLabel")
	word.Name = "Status"
	word.LayoutOrder = 2
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.Text = "OFF"
	word.Parent = row

	local button = newFrame("Power", UDim2.fromOffset(32, 32), THEME.track)
	button.LayoutOrder = 3
	round(button, UDim.new(0.5, 0))
	button.Parent = row

	local glyph = newIcon("Glyph", 16, ICON.power)
	glyph.Parent = button

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		animate(word, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		animate(button, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		animate(glyph, { ImageColor3 = if on then THEME.knob else THEME.textMuted })
	end
end

-- T16: T1 whose knob stretches while it travels and is round again on arrival.
local function stretchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		if knob:IsDescendantOf(game) and not GuiService.ReducedMotionEnabled then
			TweenService:Create(knob, STRETCH, { Size = UDim2.fromOffset(26, 18) }):Play()
		end
	end
end

-- T17: a tick and a cross live in the track; the knob covers the one not chosen.
local function trackIconSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 28), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local yes = newIcon("Yes", 14, ICON.check)
	yes.Position = UDim2.new(0, 14, 0.5, 0)
	yes.Parent = track

	local no = newIcon("No", 14, ICON.cross)
	no.Position = UDim2.new(1, -14, 0.5, 0)
	no.ImageColor3 = THEME.textMuted
	no.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(22, 22), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.ZIndex = 2
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 31 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		yes.ImageColor3 = if on then THEME.knob else THEME.textMuted
	end
end

-- T18: a key that sinks onto its base and stays down while on.
local function keySkin(row: TextButton): (boolean) -> ()
	local key = newFrame("Key", UDim2.fromOffset(52, 36), THEME.row)
	key.LayoutOrder = 2
	key.BackgroundTransparency = 1
	key.Parent = row

	local base = newFrame("Base", UDim2.new(1, 0, 0, 32), THEME.keyBase)
	base.Position = UDim2.fromOffset(0, 4)
	base.ZIndex = 1
	round(base, UDim.new(0, 6))
	base.Parent = key

	local cap = Instance.new("TextLabel")
	cap.Name = "Cap"
	cap.Size = UDim2.new(1, 0, 0, 32)
	cap.BackgroundColor3 = THEME.rowHover
	cap.BorderSizePixel = 0
	cap.ZIndex = 2
	cap.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	cap.TextSize = 12
	cap.Text = "OFF"
	round(cap, UDim.new(0, 6))
	cap.Parent = key

	return function(on: boolean)
		cap.Text = if on then "ON" else "OFF"
		animate(cap, {
			Position = UDim2.fromOffset(0, if on then 3 else 0),
			BackgroundColor3 = if on then THEME.accent else THEME.rowHover,
			TextColor3 = if on then THEME.knob else THEME.textMuted,
		})
	end
end

-- T19: the label gains one short line underneath; the row grows to fit it.
local function describedSkin(
	row: TextButton,
	label: TextLabel,
	description: string
): (boolean) -> ()
	row.Size = UDim2.new(1, 0, 0, 56)

	local column = newFrame("Labels", UDim2.fromScale(0, 1), THEME.row)
	column.LayoutOrder = 1
	column.BackgroundTransparency = 1
	column.Parent = row

	local grow = Instance.new("UIFlexItem")
	grow.FlexMode = Enum.UIFlexMode.Fill
	grow.Parent = column

	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.Padding = UDim.new(0, 4)
	stack.Parent = column

	label.Size = UDim2.new(1, 0, 0, 16)
	label.Parent = column

	local detail = Instance.new("TextLabel")
	detail.Name = "Description"
	detail.LayoutOrder = 2
	detail.Size = UDim2.new(1, 0, 0, 16)
	detail.BackgroundTransparency = 1
	detail.FontFace = Font.fromEnum(Enum.Font.Gotham)
	detail.TextSize = 12
	detail.TextColor3 = THEME.textMuted
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextTruncate = Enum.TextTruncate.AtEnd
	detail.Text = description
	detail.Parent = column

	return (switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0)))
end

-- T20: a feature icon leads the row and takes the accent while the switch is on.
local function iconRowSkin(row: TextButton, image: string): (boolean) -> ()
	local lead = newIcon("Lead", 20, image)
	lead.AnchorPoint = Vector2.zero
	lead.Position = UDim2.fromScale(0, 0)
	lead.LayoutOrder = 0
	lead.Parent = row

	local paintSwitch = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	return function(on: boolean)
		animate(lead, { ImageColor3 = if on then THEME.accent else THEME.textMuted })
		paintSwitch(on)
	end
end

local function newWord(name: string, order: number, text: string): TextLabel
	local word = Instance.new("TextLabel")
	word.Name = name
	word.LayoutOrder = order
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.TextColor3 = THEME.textMuted
	word.Text = text
	return word
end

-- T21: the accent fills the track from the left as the knob travels.
local function fillSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local fill = newFrame("Fill", UDim2.fromScale(0, 1), THEME.accent)
	round(fill, UDim.new(0.5, 0))
	fill.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.ZIndex = 2
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(fill, { Size = UDim2.fromScale(if on then 1 else 0, 1) })
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
	end
end

-- T22: both words stay visible either side of the switch; the chosen one is lit.
local function labelledEndsSkin(row: TextButton): (boolean) -> ()
	local off = newWord("OffWord", 2, "Off")
	off.Parent = row
	local paintSwitch = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0), 3)
	local on = newWord("OnWord", 4, "On")
	on.Parent = row

	return function(value: boolean)
		paintSwitch(value)
		animate(off, { TextColor3 = if value then THEME.textMuted else THEME.text })
		animate(on, { TextColor3 = if value then THEME.focus else THEME.textMuted })
	end
end

-- T23: T1 whose track takes a soft accent glow while on.
local function glowSkin(row: TextButton): (boolean) -> ()
	local paintSwitch, track = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.Color = THEME.focus
	glow.Thickness = 2
	glow.Transparency = 1
	glow.Parent = track

	return function(on: boolean)
		paintSwitch(on)
		animate(glow, { Transparency = if on then 0.4 else 1 })
	end
end

-- T24: an upright lever; the knob rises for on, like a wall switch.
local function leverSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(24, 40), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0.5, 0)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0.5, 0, 0, if on then 3 else 19) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T25: an empty ring whose centre dot grows in, as a single-option radio.
local function dotRingSkin(row: TextButton): (boolean) -> ()
	local ring = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	ring.LayoutOrder = 0
	round(ring, UDim.new(0.5, 0))
	ring.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = ring

	local dot = newFrame("Dot", UDim2.fromOffset(10, 10), THEME.accent)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	round(dot, UDim.new(0.5, 0))
	dot.Parent = ring

	local grow = Instance.new("UIScale")
	grow.Parent = dot

	return function(on: boolean)
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(grow, { Scale = if on then 1 else 0 })
	end
end

-- T26: a stripe on the row's left edge lights, and the word says it.
local function stripeSkin(row: TextButton): (boolean) -> ()
	local stripe = newFrame("Stripe", UDim2.fromOffset(4, 24), THEME.track)
	stripe.LayoutOrder = 0
	round(stripe, UDim.new(0.5, 0))
	stripe.Parent = row

	local status = newWord("Status", 2, "OFF")
	status.Parent = row

	return function(on: boolean)
		status.Text = if on then "ON" else "OFF"
		animate(stripe, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		animate(status, { TextColor3 = if on then THEME.focus else THEME.textMuted })
	end
end

-- T27: a rocker marked O and I; the cap sits under the side that is down.
local function rockerSkin(row: TextButton): (boolean) -> ()
	local rocker = newFrame("Rocker", UDim2.fromOffset(64, 32), THEME.keyBase)
	rocker.LayoutOrder = 2
	round(rocker, UDim.new(0, 6))
	rocker.Parent = row

	local cap = newFrame("Cap", UDim2.new(0.5, -4, 1, -8), THEME.track)
	cap.AnchorPoint = Vector2.new(0, 0.5)
	cap.ZIndex = 1
	round(cap, UDim.new(0, 4))
	cap.Parent = rocker

	local marks: { TextLabel } = {}
	for index, glyph in { "O", "I" } do
		local mark = Instance.new("TextLabel")
		mark.Name = if glyph == "O" then "Off" else "On"
		mark.Position = UDim2.fromScale((index - 1) * 0.5, 0)
		mark.Size = UDim2.fromScale(0.5, 1)
		mark.BackgroundTransparency = 1
		mark.ZIndex = 2
		mark.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		mark.TextSize = 14
		mark.Text = glyph
		mark.Parent = rocker
		marks[index] = mark
	end

	return function(on: boolean)
		animate(cap, {
			Position = UDim2.new(if on then 0.5 else 0, 4, 0.5, 0),
			BackgroundColor3 = if on then THEME.accent else THEME.track,
		})
		marks[1].TextColor3 = if on then THEME.textMuted else THEME.text
		marks[2].TextColor3 = if on then THEME.knob else THEME.textMuted
	end
end

-- T28: a compact pill that reads ON or OFF, for dense feature lists.
local function pillSkin(row: TextButton): (boolean) -> ()
	local pill = Instance.new("TextLabel")
	pill.Name = "Pill"
	pill.LayoutOrder = 2
	pill.Size = UDim2.fromOffset(52, 24)
	pill.BackgroundColor3 = THEME.track
	pill.BorderSizePixel = 0
	pill.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	pill.TextSize = 12
	pill.Text = "OFF"
	round(pill, UDim.new(0.5, 0))
	pill.Parent = row

	return function(on: boolean)
		pill.Text = if on then "ON" else "OFF"
		animate(pill, {
			BackgroundColor3 = if on then THEME.accent else THEME.track,
			TextColor3 = if on then THEME.knob else THEME.textMuted,
		})
	end
end

-- T29: T1 with the feature's hotkey shown in a chip before the switch.
local function keyChipSkin(row: TextButton, keyName: string): (boolean) -> ()
	local chip = newWord("Key", 2, keyName)
	chip.BackgroundColor3 = THEME.keyBase
	chip.BackgroundTransparency = 0
	chip.Size = UDim2.fromOffset(0, 24)
	round(chip, UDim.new(0, 4))
	chip.Parent = row

	local inset = Instance.new("UIPadding")
	inset.PaddingLeft = UDim.new(0, 8)
	inset.PaddingRight = UDim.new(0, 8)
	inset.Parent = chip

	return (switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0), 3))
end

-- T30: a small switch for long, dense lists; the row stays 44 tall to tap.
local function miniSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(32, 18), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(14, 14), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 16 else 2, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T4 shows both words; each half is its own button so pressing the half that is
-- already selected leaves the value alone instead of flipping it.
local function segmentSkin(
	row: TextButton,
	choose: (boolean) -> (),
	watch: (GuiButton) -> (),
	connections: { RBXScriptConnection }
): (boolean) -> ()
	local group = newFrame("Segments", UDim2.fromOffset(112, 36), THEME.track)
	group.LayoutOrder = 2
	round(group, UDim.new(0, 6))
	group.Parent = row

	local indicator = newFrame("Indicator", UDim2.new(0.5, -4, 1, -8), THEME.accent)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.ZIndex = 1
	round(indicator, UDim.new(0, 4))
	indicator.Parent = group

	local halves: { TextButton } = {}
	for index, word in { "Off", "On" } do
		local half = Instance.new("TextButton")
		half.Name = word
		half.AutoButtonColor = false
		half.BackgroundTransparency = 1
		half.Position = UDim2.fromScale((index - 1) * 0.5, 0)
		half.Size = UDim2.fromScale(0.5, 1)
		half.ZIndex = 2
		half.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		half.TextSize = 14
		half.Text = word
		half.Parent = group
		watch(half)
		table.insert(connections, half.Activated:Connect(function()
			choose(word == "On")
		end))
		halves[index] = half
	end

	row.Selectable = false
	return function(on: boolean)
		animate(indicator, { Position = UDim2.new(if on then 0.5 else 0, 4, 0.5, 0) })
		halves[1].TextColor3 = if on then THEME.textMuted else THEME.text
		halves[2].TextColor3 = if on then THEME.text else THEME.textMuted
	end
end

local function createToggle(
	parent: GuiObject,
	labelText: string,
	style: ToggleStyle,
	initial: boolean,
	onChanged: (boolean) -> (),
	details: ToggleDetails?
): Toggle
	local value = initial
	local enabled = true
	local hovered, pressed, focused = false, false, false
	local connections: { RBXScriptConnection } = {}

	local row = Instance.new("TextButton")
	row.Name = labelText
	row.AutoButtonColor = false
	row.Text = ""
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = THEME.row
	row.BorderSizePixel = 0
	local rowCorner = round(row, UDim.new(0, 6))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = row

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.LayoutOrder = 1
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = labelText
	label.Parent = row

	local fill = Instance.new("UIFlexItem")
	fill.FlexMode = Enum.UIFlexMode.Fill
	fill.Parent = label

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Enabled = style == "T5" or style == "T14"
	edge.Parent = row

	local focusRing = Instance.new("UIStroke")
	focusRing.Name = "FocusRing"
	focusRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	focusRing.Color = THEME.focus
	focusRing.Thickness = 2
	focusRing.Enabled = false
	focusRing.Parent = row

	-- T5 and T14 light the whole row as the "on" signal, so their lit colour
	-- outranks hover; the other styles leave the row neutral.
	local function paintRow()
		label.TextColor3 = if enabled then THEME.text else THEME.textMuted
		local lit = (style == "T5" or style == "T14") and value
		local surface = if lit then THEME.accentDim
			elseif pressed then THEME.row
			elseif hovered then THEME.rowHover
			else THEME.row
		animate(row, { BackgroundColor3 = surface })
		edge.Color = if not lit then THEME.track elseif hovered then THEME.focus else THEME.accent
	end

	-- One watcher per focusable button: hover, press and focus are separate
	-- flags, so losing hover never clears focus and a refresh keeps both.
	local function watch(button: GuiButton)
		table.insert(connections, button.MouseEnter:Connect(function()
			hovered = true
			paintRow()
		end))
		table.insert(connections, button.MouseLeave:Connect(function()
			hovered, pressed = false, false
			paintRow()
		end))
		table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				pressed = true
				paintRow()
			end
		end))
		table.insert(connections, button.InputEnded:Connect(function()
			pressed = false
			paintRow()
		end))
		table.insert(connections, button.SelectionGained:Connect(function()
			focused = true
			focusRing.Enabled = focused
		end))
		table.insert(connections, button.SelectionLost:Connect(function()
			focused = false
			focusRing.Enabled = focused
		end))
	end

	local paintValue: (boolean) -> ()
	local function set(next: boolean)
		if not enabled or next == value then
			return
		end
		value = next
		paintValue(value)
		paintRow()
		onChanged(value)
	end

	if style == "T1" then
		paintValue = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	elseif style == "T2" then
		paintValue = switchSkin(row, UDim.new(0, 6), UDim.new(0, 4))
	elseif style == "T3" then
		paintValue = tickSkin(row)
	elseif style == "T4" then
		paintValue = segmentSkin(row, set, watch, connections)
	elseif style == "T5" then
		paintValue = lightSkin(row, label)
	elseif style == "T6" then
		paintValue = iconSkin(row)
	elseif style == "T7" then
		paintValue = knobIconSkin(row)
	elseif style == "T8" then
		paintValue = wordSwitchSkin(row)
	elseif style == "T9" then
		paintValue = statusDotSkin(row)
	elseif style == "T10" then
		paintValue = roundTickSkin(row)
	end

	if style == "T11" then
		paintValue = railSkin(row)
	elseif style == "T12" then
		paintValue = outlineSkin(row)
	elseif style == "T13" then
		paintValue = bigSwitchSkin(row)
	elseif style == "T14" then
		paintValue = chipSkin(row, rowCorner)
	elseif style == "T15" then
		paintValue = powerSkin(row)
	elseif style == "T16" then
		paintValue = stretchSkin(row)
	elseif style == "T17" then
		paintValue = trackIconSkin(row)
	elseif style == "T18" then
		paintValue = keySkin(row)
	elseif style == "T19" then
		local description = if details and details.description then details.description else ""
		paintValue = describedSkin(row, label, description)
	elseif style == "T20" then
		local image = if details and details.icon then details.icon else ICON.feature
		paintValue = iconRowSkin(row, image)
	end

	if style == "T21" then
		paintValue = fillSkin(row)
	elseif style == "T22" then
		paintValue = labelledEndsSkin(row)
	elseif style == "T23" then
		paintValue = glowSkin(row)
	elseif style == "T24" then
		paintValue = leverSkin(row)
	elseif style == "T25" then
		paintValue = dotRingSkin(row)
	elseif style == "T26" then
		paintValue = stripeSkin(row)
	elseif style == "T27" then
		paintValue = rockerSkin(row)
	elseif style == "T28" then
		paintValue = pillSkin(row)
	elseif style == "T29" then
		paintValue = keyChipSkin(row, if details and details.key then details.key else "F")
	elseif style == "T30" then
		paintValue = miniSkin(row)
	end

	if style ~= "T4" then
		watch(row)
		table.insert(connections, row.Activated:Connect(function()
			set(not value)
		end))
	end

	paintRow()
	paintValue(value)
	row.Parent = parent

	return {
		row = row,
		set = set,
		get = function()
			return value
		end,
		setEnabled = function(next: boolean)
			enabled = next
			row.Active = next
			row.Interactable = next
			paintRow()
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			row:Destroy()
		end,
	}
end

return createToggle
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/tooltips.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- H1 to H10 without H3 to H6 attach to a control; H3 to H5 show a slider's
-- value; H6 is its own button, H11 sits under a field and H12 points once.
export type TooltipStyle = "H1" | "H2" | "H7" | "H8" | "H9" | "H10"
export type SliderStyle = "H3" | "H4" | "H5"

-- `title` and `keyHint` are shown by H7. `host` is the ScreenGui the bubble
-- floats above; by default the target's own.
export type TooltipSpec = {
	text: string,
	title: string?,
	keyHint: string?,
	host: ScreenGui?,
}

export type Tooltip = {
	setText: (text: string) -> (),
	setDisabled: (disabled: boolean) -> (),
	show: () -> (),
	hide: () -> (),
	destroy: () -> (),
}

-- `format` turns the value into words, such as `"{value} studs"`.
export type SliderParts = {
	track: GuiObject,
	thumb: GuiObject,
	min: number,
	max: number,
	format: ((value: number) -> string)?,
}

export type SliderValue = {
	update: (value: number) -> (),
	setDragging: (dragging: boolean) -> (),
	destroy: () -> (),
}

local THEME = {
	bubble = Color3.fromRGB(9, 10, 13),
	edge = Color3.fromRGB(63, 68, 79),
	chip = Color3.fromRGB(31, 34, 41),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	focus = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	lock = "rbxassetid://119765975153029",
}

local FADE_IN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

-- A pointer resting this long means a question; passing over means nothing.
local HOVER_DELAY = 0.4
-- A finger has no hover, so a hold of this long asks instead.
local TOUCH_HOLD = 0.5
-- After a finger lifts, the answer stays long enough to read.
local TOUCH_LINGER = 1.5
local GAP = 8
local EDGE = 8
local MAX_WIDTH = 240
local CURSOR_OFFSET = 16
local ARROW = 10

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function pad(target: GuiObject, vertical: number, horizontal: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, vertical)
	padding.PaddingBottom = UDim.new(0, vertical)
	padding.PaddingLeft = UDim.new(0, horizontal)
	padding.PaddingRight = UDim.new(0, horizontal)
	padding.Parent = target
end

local function stackIn(target: GuiObject, direction: Enum.FillDirection, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = target
	return layout
end

local function words(name: string, text: string, size: number, bold: boolean): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	return label
end

local function glyph(name: string, image: string, size: number, colour: Color3): ImageLabel
	local picture = Instance.new("ImageLabel")
	picture.Name = name
	picture.Size = UDim2.fromOffset(size, size)
	picture.BackgroundTransparency = 1
	picture.Image = image
	picture.ImageColor3 = colour
	return picture
end

-- Bubbles float in a ScreenGui of their own above the host, so no list or
-- clipping frame cuts them off. The layer copies the host's insets, so
-- positions measured against it land where the target is drawn.
local function newLayer(target: GuiObject, host: ScreenGui?): ScreenGui
	local owner = host or target:FindFirstAncestorWhichIsA("ScreenGui")
	assert(owner, "a tooltip's target must be inside a ScreenGui")
	local layer = Instance.new("ScreenGui")
	layer.Name = "TooltipLayer"
	layer.ResetOnSpawn = false
	layer.DisplayOrder = owner.DisplayOrder + 2
	layer.ScreenInsets = owner.ScreenInsets
	layer.Parent = owner.Parent
	return layer
end

-- The bubble: a title (H7), the words, and a key hint chip (H7), or a lock
-- before the words for H9's reason.
local function newBubble(spec: TooltipSpec, locked: boolean): (CanvasGroup, TextLabel)
	local bubble = Instance.new("CanvasGroup")
	bubble.Name = "Bubble"
	bubble.AutomaticSize = Enum.AutomaticSize.XY
	bubble.BackgroundColor3 = THEME.bubble
	bubble.GroupTransparency = 1
	bubble.Visible = false
	bubble.ZIndex = 2
	round(bubble, UDim.new(0, 6))
	pad(bubble, 8, 12)
	stackIn(bubble, Enum.FillDirection.Vertical, 4)

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = if locked then THEME.danger else THEME.edge
	edge.Parent = bubble

	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	bounds.Parent = bubble

	local title = spec.title
	if title then
		local heading = words("Title", title, 14, true)
		heading.LayoutOrder = 1
		heading.Parent = bubble
	end

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.LayoutOrder = 2
	line.AutomaticSize = Enum.AutomaticSize.XY
	line.BackgroundTransparency = 1
	line.Parent = bubble
	stackIn(line, Enum.FillDirection.Horizontal, 8)

	if locked then
		local lock = glyph("Lock", ICON.lock, 16, THEME.danger)
		lock.LayoutOrder = 1
		lock.Parent = line
	end

	local body = words("Text", spec.text, if title then 12 else 14, false)
	body.LayoutOrder = 2
	body.TextColor3 = if title then THEME.textMuted else THEME.text
	body.Parent = line

	local keyHint = spec.keyHint
	if keyHint then
		local chip = words("Key", keyHint, 12, true)
		chip.LayoutOrder = 3
		chip.BackgroundColor3 = THEME.chip
		chip.BackgroundTransparency = 0
		round(chip, UDim.new(0, 4))
		pad(chip, 2, 6)
		chip.Parent = bubble
	end
	return bubble, body
end

-- Where a bubble of this size goes beside a rectangle: below it, or above
-- when the layer has no room below, and never past either side edge.
local function beside(
	layer: ScreenGui,
	bubble: GuiObject,
	left: number,
	top: number,
	width: number,
	height: number,
	above: boolean
): (number, number, boolean)
	local size = bubble.AbsoluteSize
	local room = layer.AbsoluteSize
	local rightmost = math.max(EDGE, room.X - size.X - EDGE)
	local x = math.clamp(left + width / 2 - size.X / 2, EDGE, rightmost)
	local below = top + height + GAP
	local over = top - size.Y - GAP
	local useAbove = if above then over >= 0 else below + size.Y > room.Y and over >= 0
	return x, if useAbove then over else below, useAbove
end

local function fade(bubble: CanvasGroup, visible: boolean)
	if visible then
		bubble.Visible = true
		TweenService:Create(bubble, motion(FADE_IN), { GroupTransparency = 0 }):Play()
		return
	end
	local out = TweenService:Create(bubble, motion(FADE_OUT), { GroupTransparency = 1 })
	out.Completed:Once(function()
		if bubble.GroupTransparency == 1 then
			bubble.Visible = false
		end
	end)
	out:Play()
end

-- H1 below the control, H2 above it with an arrow, H7 with a title and key,
-- H8 at the pointer, H9 only while disabled, H10 only while pressed. Every
-- style also answers a long press on a phone and keyboard or gamepad focus.
local function createTooltip(target: GuiObject, style: TooltipStyle, spec: TooltipSpec): Tooltip
	local connections: { RBXScriptConnection } = {}
	local layer = newLayer(target, spec.host)
	local bubble, body = newBubble(spec, style == "H9")
	bubble.Parent = layer
	local ticket = 0
	local shown = false
	local disabled = false
	local pointer: { x: number, y: number }? = nil

	local arrow: Frame? = nil
	if style == "H2" then
		local point = Instance.new("Frame")
		point.Name = "Arrow"
		point.Size = UDim2.fromOffset(ARROW, ARROW)
		point.AnchorPoint = Vector2.new(0.5, 0.5)
		point.Rotation = 45
		point.BackgroundColor3 = THEME.bubble
		point.BorderSizePixel = 0
		point.Visible = false
		point.ZIndex = 1
		point.Parent = layer
		arrow = point
	end

	-- H9 reads hovers through a transparent cover over the control, because a
	-- disabled control gets no input of its own.
	local cover: TextButton? = nil

	local function place()
		local origin = layer.AbsolutePosition
		local at = pointer
		if style == "H8" and at then
			local x = at.x - origin.X + CURSOR_OFFSET
			bubble.Position = UDim2.fromOffset(x, at.y - origin.Y + CURSOR_OFFSET)
			return
		end
		local left = target.AbsolutePosition.X - origin.X
		local top = target.AbsolutePosition.Y - origin.Y
		local size = target.AbsoluteSize
		local x, y, above = beside(layer, bubble, left, top, size.X, size.Y, style == "H2")
		bubble.Position = UDim2.fromOffset(x, y)
		local point = arrow
		if point then
			local tip = if above then y + bubble.AbsoluteSize.Y else y
			point.Position = UDim2.fromOffset(left + size.X / 2, tip)
		end
	end

	local function show()
		if disabled ~= (style == "H9") then
			return
		end
		ticket += 1
		shown = true
		place()
		fade(bubble, true)
		if arrow then
			arrow.Visible = true
		end
	end

	local function hide()
		ticket += 1
		if not shown then
			return
		end
		shown = false
		fade(bubble, false)
		if arrow then
			arrow.Visible = false
		end
	end

	local function later(seconds: number, run: () -> ())
		ticket += 1
		local mine = ticket
		task.delay(seconds, function()
			if mine == ticket then
				run()
			end
		end)
	end

	-- One set of handlers for the control, or for H9's cover in its place.
	local function listen(source: GuiObject)
		table.insert(connections, source.MouseEnter:Connect(function(x: number, y: number)
			pointer = { x = x, y = y }
			local touch = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
			if style ~= "H10" and not touch then
				later(HOVER_DELAY, show)
			end
		end))
		table.insert(connections, source.MouseMoved:Connect(function(x: number, y: number)
			pointer = { x = x, y = y }
			if shown and style == "H8" then
				place()
			end
		end))
		table.insert(connections, source.MouseLeave:Connect(hide))
		table.insert(connections, source.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			local click = style == "H10" and kind == Enum.UserInputType.MouseButton1
			if kind == Enum.UserInputType.Touch or click then
				later(TOUCH_HOLD, show)
			end
		end))
		table.insert(connections, source.InputEnded:Connect(function(input: InputObject)
			if style == "H10" or input.UserInputType ~= Enum.UserInputType.Touch then
				hide()
			else
				later(TOUCH_LINGER, hide)
			end
		end))
		table.insert(connections, source.SelectionGained:Connect(show))
		table.insert(connections, source.SelectionLost:Connect(hide))
	end

	if style == "H9" then
		local catcher = Instance.new("TextButton")
		catcher.Name = "ReasonCatcher"
		catcher.AutoButtonColor = false
		catcher.BackgroundTransparency = 1
		catcher.Text = ""
		catcher.Visible = false
		catcher.Parent = layer
		cover = catcher
		listen(catcher)
		table.insert(connections, catcher.Activated:Connect(show))
	else
		listen(target)
	end

	local function setDisabled(next: boolean)
		disabled = next
		local catcher = cover
		if catcher then
			local origin = layer.AbsolutePosition
			catcher.Position = UDim2.fromOffset(
				target.AbsolutePosition.X - origin.X,
				target.AbsolutePosition.Y - origin.Y
			)
			catcher.Size = UDim2.fromOffset(target.AbsoluteSize.X, target.AbsoluteSize.Y)
			catcher.Visible = next
		end
		if not next then
			hide()
		end
	end

	return {
		setText = function(text: string)
			body.Text = text
			if shown then
				place()
			end
		end,
		setDisabled = setDisabled,
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			layer:Destroy()
		end,
	}
end

-- H3 floats the value over the thumb while it is dragged; H4 keeps it over
-- the thumb; H5 writes the ends under the track and the value after it.
local function createSliderValue(parts: SliderParts, style: SliderStyle): SliderValue
	local format = parts.format or function(value: number): string
		return tostring(math.floor(value + 0.5))
	end
	local made: { Instance } = {}
	local dragging = false
	local current = parts.min

	local bubble: CanvasGroup? = nil
	local bubbleText: TextLabel? = nil
	local layer: ScreenGui? = nil
	if style == "H3" then
		local floating = newLayer(parts.thumb)
		table.insert(made, floating)
		local card, text = newBubble({ text = format(current) }, false)
		card.AnchorPoint = Vector2.new(0.5, 1)
		card.Parent = floating
		layer, bubble, bubbleText = floating, card, text
	end

	local tag: TextLabel? = nil
	if style == "H4" then
		local label = words("ValueTag", format(current), 12, true)
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 0, -GAP)
		label.BackgroundColor3 = THEME.bubble
		label.BackgroundTransparency = 0
		round(label, UDim.new(0, 4))
		pad(label, 2, 6)
		label.Parent = parts.thumb
		table.insert(made, label)
		tag = label
	end

	local readout: TextLabel? = nil
	if style == "H5" then
		-- The two ends of the range, under the matching end of the track.
		local function markEnd(name: string, value: number, side: number)
			local mark = words(name, format(value), 12, false)
			mark.AnchorPoint = Vector2.new(side, 0)
			mark.Position = UDim2.new(side, 0, 1, 4)
			mark.TextColor3 = THEME.textMuted
			mark.Parent = parts.track
			table.insert(made, mark)
		end
		markEnd("Min", parts.min, 0)
		markEnd("Max", parts.max, 1)
		local label = words("Value", format(current), 14, true)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.new(1, 12, 0.5, 0)
		label.Parent = parts.track
		table.insert(made, label)
		readout = label
	end

	local function place()
		local card, floating = bubble, layer
		if not card or not floating then
			return
		end
		local origin = floating.AbsolutePosition
		local thumb = parts.thumb
		local x = thumb.AbsolutePosition.X - origin.X + thumb.AbsoluteSize.X / 2
		local y = thumb.AbsolutePosition.Y - origin.Y - GAP
		card.Position = UDim2.fromOffset(x, y)
	end

	local function update(value: number)
		current = math.clamp(value, parts.min, parts.max)
		local text = format(current)
		if bubbleText then
			bubbleText.Text = text
		end
		if tag then
			tag.Text = text
		end
		if readout then
			readout.Text = text
		end
		if dragging then
			place()
		end
	end

	return {
		update = update,
		setDragging = function(next: boolean)
			dragging = next
			local card = bubble
			if card then
				if next then
					place()
				end
				fade(card, next)
			end
		end,
		destroy = function()
			for _, instance in made do
				instance:Destroy()
			end
		end,
	}
end

-- H6: an info mark with a 44 px target; a tap opens its words and a tap
-- anywhere else, or Escape, closes them. Nothing depends on hover.
local function createInfoButton(parent: GuiObject, text: string, order: number?)
	local connections: { RBXScriptConnection } = {}
	local button = Instance.new("ImageButton")
	button.Name = "Info"
	button.LayoutOrder = order or 0
	button.Size = UDim2.fromOffset(44, 44)
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Image = ""
	button.Parent = parent

	local mark = glyph("Mark", ICON.info, 16, THEME.textMuted)
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Parent = button

	local layer = newLayer(button)
	local catcher = Instance.new("TextButton")
	catcher.Name = "Catcher"
	catcher.AutoButtonColor = false
	catcher.BackgroundTransparency = 1
	catcher.Text = ""
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.Visible = false
	catcher.Parent = layer

	local bubble = newBubble({ text = text }, false)
	bubble.Parent = layer

	local function setOpen(open: boolean)
		catcher.Visible = open
		mark.ImageColor3 = if open then THEME.focus else THEME.textMuted
		if open then
			local origin = layer.AbsolutePosition
			local left = button.AbsolutePosition.X - origin.X
			local top = button.AbsolutePosition.Y - origin.Y
			local size = button.AbsoluteSize
			local x, y = beside(layer, bubble, left, top, size.X, size.Y, false)
			bubble.Position = UDim2.fromOffset(x, y)
		end
		fade(bubble, open)
	end

	table.insert(connections, button.Activated:Connect(function()
		setOpen(not catcher.Visible)
	end))
	table.insert(connections, catcher.Activated:Connect(function()
		setOpen(false)
	end))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject)
		if catcher.Visible and input.KeyCode == Enum.KeyCode.Escape then
			setOpen(false)
		end
	end))

	return {
		button = button,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			layer:Destroy()
			button:Destroy()
		end,
	}
end

-- H11: a line under a field that says what it wants, and turns into the
-- error, with an icon, when the entry is wrong.
local function createHelperText(parent: GuiObject, text: string, order: number)
	local row = Instance.new("Frame")
	row.Name = "Help"
	row.LayoutOrder = order
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.fromScale(1, 0)
	row.BackgroundTransparency = 1
	row.Parent = parent
	stackIn(row, Enum.FillDirection.Horizontal, 4)

	local warning = glyph("Alert", ICON.info, 16, THEME.danger)
	warning.LayoutOrder = 1
	warning.Visible = false
	warning.Parent = row

	local hint = words("Text", text, 12, false)
	hint.LayoutOrder = 2
	hint.TextColor3 = THEME.textMuted
	hint.Parent = row

	return {
		label = hint,
		setError = function(message: string?)
			warning.Visible = message ~= nil
			hint.Text = message or text
			hint.TextColor3 = if message then THEME.danger else THEME.textMuted
		end,
		destroy = function()
			row:Destroy()
		end,
	}
end

-- H12: shown once to point at something new, with a ring around it and a
-- button that says the player has seen it. `onDone` runs once; store it so
-- the mark never returns. Returns a dismiss that is safe to repeat.
local function showCoachMark(target: GuiObject, text: string, onDone: () -> ()): () -> ()
	local layer = newLayer(target)
	local finished = false
	local connections: { RBXScriptConnection } = {}

	local origin = layer.AbsolutePosition
	local left = target.AbsolutePosition.X - origin.X
	local top = target.AbsolutePosition.Y - origin.Y
	local size = target.AbsoluteSize

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Position = UDim2.fromOffset(left - 4, top - 4)
	ring.Size = UDim2.fromOffset(size.X + 8, size.Y + 8)
	ring.BackgroundTransparency = 1
	ring.Parent = layer
	round(ring, UDim.new(0, 10))

	local glow = Instance.new("UIStroke")
	glow.Color = THEME.focus
	glow.Thickness = 2
	glow.Parent = ring

	local bubble = newBubble({ text = text }, false)
	bubble.Parent = layer

	local gotIt = Instance.new("TextButton")
	gotIt.Name = "GotIt"
	gotIt.LayoutOrder = 4
	gotIt.AutoButtonColor = false
	gotIt.AutomaticSize = Enum.AutomaticSize.X
	gotIt.Size = UDim2.fromOffset(0, 44)
	gotIt.BackgroundColor3 = THEME.accent
	gotIt.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	gotIt.TextSize = 14
	gotIt.TextColor3 = THEME.text
	gotIt.Text = "Got it"
	gotIt.Parent = bubble
	round(gotIt, UDim.new(0, 6))
	pad(gotIt, 0, 16)

	local x, y = beside(layer, bubble, left, top, size.X, size.Y, false)
	bubble.Position = UDim2.fromOffset(x, y)
	fade(bubble, true)

	local function dismiss()
		if finished then
			return
		end
		finished = true
		for _, connection in connections do
			connection:Disconnect()
		end
		layer:Destroy()
		onDone()
	end
	table.insert(connections, gotIt.Activated:Connect(dismiss))
	return dismiss
end

return {
	createTooltip = createTooltip,
	createSliderValue = createSliderValue,
	createInfoButton = createInfoButton,
	createHelperText = createHelperText,
	showCoachMark = showCoachMark,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/windows.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

type FirstStyles = "O1" | "O2" | "O3" | "O4"
type LaterStyles = "O6" | "O7" | "O8" | "O9" | "O10" | "O11"
type NewStyles = "O13" | "O14" | "O15" | "O16" | "O17" | "O18" | "O19" | "O20"
export type WindowStyle = FirstStyles | LaterStyles | NewStyles

export type Opener = {
	open: () -> (),
	close: () -> (),
}

-- `launcher` is the on-screen button that brings the window back (O1, O2, O11).
-- O3 keeps `header` on screen and folds `body` away. `opener` is a presenter
-- from menus.luau; without one, O1 shows and hides instantly. O6 shows
-- `bubbleIcon`, O9 shows `title`, O10 names `keyName`, and O11 calls `onUnload`
-- when the player chooses to unload rather than hide. O14 puts its icon in
-- `dock` when given one, so several windows share a dock. O16 folds the window
-- down to `rail`, its tab sidebar, and hides `body`. O17 shows the window
-- while `keyName` (default LeftAlt) is held; O19 swipes by `header`.
export type WindowParts = {
	panel: CanvasGroup,
	launcher: GuiButton?,
	header: GuiObject?,
	body: CanvasGroup?,
	rail: GuiObject?,
	dock: Frame?,
	opener: Opener?,
	bubbleIcon: string?,
	title: string?,
	keyName: string?,
	onUnload: (() -> ())?,
}

export type Window = {
	show: () -> (),
	hide: () -> (),
	toggle: () -> (),
	isShown: () -> boolean,
	destroy: () -> (),
}

local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	control = Color3.fromRGB(63, 68, 79),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	onAccent = Color3.fromRGB(9, 10, 13),
	danger = Color3.fromRGB(208, 88, 82),
	focus = Color3.fromRGB(72, 201, 162),
}

local ICON = {
	pullRight = "rbxassetid://101007429951147",
	pullLeft = "rbxassetid://102314312897830",
	pullDown = "rbxassetid://71457658246709",
	menu = "rbxassetid://83047518441184",
	keyboard = "rbxassetid://121978468376124",
	pullUp = "rbxassetid://98648581502859",
	eye = "rbxassetid://127234874352422",
	hand = "rbxassetid://83088528355903",
	expand = "rbxassetid://126704485649345",
}

local MOTION = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	grow = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	shrink = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	line = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	instant = TweenInfo.new(0),
}

local MINIMISED_SCALE = 0.2
-- O15 leaves the window faint enough to play through, never fully gone.
local GHOST_TRANSPARENCY = 0.8
-- O19: how far a header drag must travel before it counts as a swipe.
local SWIPE_DISTANCE = 120
-- O20: a whole stretch this long with no input fades the window away.
local IDLE_SECONDS = 8
local INTRO_HOLD = 0.6
local OUTRO_HOLD = 0.8
local CHIP_COLLAPSE = 5
-- A press that travels further than this is a drag, not a tap.
local DRAG_SLOP = 6

local function timing(chosen: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then MOTION.instant else chosen
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function glyph(parent: GuiObject, image: string, order: number): ImageLabel
	local mark = Instance.new("ImageLabel")
	mark.Name = "Mark"
	mark.LayoutOrder = order
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromOffset(16, 16)
	mark.BackgroundTransparency = 1
	mark.Image = image
	mark.ImageColor3 = THEME.textMuted
	mark.Parent = parent
	return mark
end

-- Every return control shares one look: a raised surface, a 1 px edge that
-- becomes the focus colour under keyboard or gamepad, and a mark that brightens
-- on hover. The control starts hidden; the window shows it when it hides.
local function returnControl(
	name: string,
	size: UDim2,
	anchor: Vector2,
	position: UDim2,
	image: string,
	radius: UDim,
	connections: { RBXScriptConnection }
): (TextButton, ImageLabel)
	local control = Instance.new("TextButton")
	control.Name = name
	control.AnchorPoint = anchor
	control.Position = position
	control.Size = size
	control.AutoButtonColor = false
	control.BackgroundColor3 = THEME.surface
	control.Text = ""
	control.Visible = false
	round(control, radius)

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.edge
	ring.Parent = control

	local mark = glyph(control, image, 1)
	table.insert(connections, control.MouseEnter:Connect(function()
		mark.ImageColor3 = THEME.text
	end))
	table.insert(connections, control.MouseLeave:Connect(function()
		mark.ImageColor3 = THEME.textMuted
	end))
	table.insert(connections, control.SelectionGained:Connect(function()
		ring.Color = THEME.focus
	end))
	table.insert(connections, control.SelectionLost:Connect(function()
		ring.Color = THEME.edge
	end))
	return control, mark
end

local function row(parent: GuiObject, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

local function caption(parent: GuiObject, text: string, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Caption"
	label.LayoutOrder = order
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextSize = 14
	label.TextColor3 = THEME.text
	label.Text = text
	label.Parent = parent
	return label
end

-- O6: the window is gone and a round bubble floats where it was. The bubble
-- can be dragged anywhere; a tap without a drag brings the window back.
local function makeBubble(
	parts: WindowParts,
	connections: { RBXScriptConnection },
	onTap: () -> ()
): TextButton
	local topLeft = parts.panel.AbsolutePosition
	local bubble = returnControl(
		"Bubble",
		UDim2.fromOffset(52, 52),
		Vector2.new(0.5, 0.5),
		UDim2.fromOffset(topLeft.X + 26, topLeft.Y + 26),
		parts.bubbleIcon or ICON.menu,
		UDim.new(0.5, 0),
		connections
	)

	local pressedAt: Vector3? = nil
	local origin = bubble.Position
	local dragged = false
	table.insert(connections, bubble.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressedAt, origin, dragged = input.Position, bubble.Position, false
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		local kind = input.UserInputType
		local moving = kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch
		if not pressedAt or not moving then
			return
		end
		local travel = input.Position - pressedAt
		dragged = dragged or travel.Magnitude > DRAG_SLOP
		if dragged then
			bubble.Position = origin + UDim2.fromOffset(travel.X, travel.Y)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function()
		pressedAt = nil
	end))
	table.insert(connections, bubble.Activated:Connect(function()
		if not dragged then
			onTap()
		end
	end))
	return bubble
end

-- O10: a chip that names the key which brings the window back, and folds down
-- to its icon after a few seconds so it stops competing with the game.
local function makeKeyChip(
	parts: WindowParts,
	connections: { RBXScriptConnection }
): (TextButton, TextLabel)
	local chip, mark = returnControl(
		"KeyChip",
		UDim2.fromOffset(44, 44),
		Vector2.new(1, 1),
		UDim2.new(1, -16, 1, -16),
		ICON.keyboard,
		UDim.new(0, 10),
		connections
	)
	chip.AutomaticSize = Enum.AutomaticSize.X
	mark.AnchorPoint = Vector2.zero

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = chip
	row(chip, 8)

	local hint = caption(chip, `Show menu · {parts.keyName or "RightShift"}`, 2)
	hint.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	return chip, hint
end

-- O9: the window collapses to a pill carrying its title, in the same corner.
local function makePill(
	parts: WindowParts,
	panel: CanvasGroup,
	connections: { RBXScriptConnection }
): TextButton
	local pill, mark = returnControl(
		"TitlePill",
		UDim2.fromOffset(0, 44),
		Vector2.zero,
		UDim2.fromOffset(panel.AbsolutePosition.X, panel.AbsolutePosition.Y),
		ICON.pullDown,
		UDim.new(0.5, 0),
		connections
	)
	pill.AutomaticSize = Enum.AutomaticSize.X
	mark.AnchorPoint = Vector2.zero

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = pill
	row(pill, 8)
	caption(pill, parts.title or "Menu", 0)
	return pill
end

-- O11: a small card over the window asking whether to hide it or unload the
-- script. Returns the function that opens it.
local function makeAsk(
	panel: CanvasGroup,
	connections: { RBXScriptConnection },
	onHide: () -> (),
	onUnload: () -> ()
): (CanvasGroup, () -> ())
	local card = Instance.new("CanvasGroup")
	card.Name = "Ask"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundColor3 = THEME.surface
	card.GroupTransparency = 1
	card.Visible = false
	card.ZIndex = 10
	round(card, UDim.new(0, 10))

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = card

	local column = Instance.new("UIListLayout")
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = card

	local question = Instance.new("TextLabel")
	question.Name = "Question"
	question.LayoutOrder = 1
	question.AutomaticSize = Enum.AutomaticSize.XY
	question.BackgroundTransparency = 1
	question.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	question.TextSize = 14
	question.TextColor3 = THEME.text
	question.Text = "Hide the menu? It keeps running."
	question.Parent = card

	local choices = Instance.new("Frame")
	choices.Name = "Choices"
	choices.LayoutOrder = 2
	choices.AutomaticSize = Enum.AutomaticSize.X
	choices.Size = UDim2.fromOffset(0, 44)
	choices.BackgroundTransparency = 1
	choices.Parent = card
	row(choices, 8)

	local function close()
		local fade = TweenService:Create(card, timing(MOTION.exit), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and card.GroupTransparency == 1 then
				card.Visible = false
			end
		end)
		fade:Play()
	end

	for index, choice in { "Cancel", "Hide", "Unload script" } do
		local button = Instance.new("TextButton")
		button.Name = choice
		button.LayoutOrder = index
		button.AutoButtonColor = false
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, 44)
		button.BackgroundColor3 = if choice == "Unload script" then THEME.danger else THEME.control
		button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		button.TextSize = 14
		button.TextColor3 = if choice == "Unload script" then THEME.onAccent else THEME.text
		button.Text = choice
		button.Parent = choices
		round(button, UDim.new(0, 6))

		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, 16)
		inset.PaddingRight = UDim.new(0, 16)
		inset.Parent = button

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.focus
		ring.Thickness = 2
		ring.Enabled = false
		ring.Parent = button

		table.insert(connections, button.SelectionGained:Connect(function()
			ring.Enabled = true
		end))
		table.insert(connections, button.SelectionLost:Connect(function()
			ring.Enabled = false
		end))
		table.insert(connections, button.Activated:Connect(function()
			close()
			if choice == "Hide" then
				onHide()
			elseif choice == "Unload script" then
				onUnload()
			end
		end))
	end

	return card,
		function()
			local centre = panel.AbsolutePosition + panel.AbsoluteSize / 2
			card.Position = UDim2.fromOffset(centre.X, centre.Y)
			card.Visible = true
			TweenService:Create(card, timing(MOTION.enter), { GroupTransparency = 0 }):Play()
		end
end

-- O4, O7, O8, O13 and O19: a tab on the edge the window left by.
local function makeTab(style: WindowStyle, connections: { RBXScriptConnection }): TextButton
	if style == "O13" then
		return (
			returnControl(
				"PullTab",
				UDim2.fromOffset(64, 44),
				Vector2.new(0.5, 1),
				UDim2.fromScale(0.5, 1),
				ICON.pullUp,
				UDim.new(0, 10),
				connections
			)
		)
	end

	if style == "O8" then
		return (
			returnControl(
				"PullTab",
				UDim2.fromOffset(64, 44),
				Vector2.new(0.5, 0),
				UDim2.fromScale(0.5, 0),
				ICON.pullDown,
				UDim.new(0, 10),
				connections
			)
		)
	end
	local side = if style == "O7" then 1 else 0
	return (
		returnControl(
			"EdgeTab",
			UDim2.fromOffset(44, 64),
			Vector2.new(side, 0.5),
			UDim2.fromScale(side, 0.5),
			if style == "O7" then ICON.pullLeft else ICON.pullRight,
			UDim.new(0, 10),
			connections
		)
	)
end

-- O15, O16 and O18: one button that brings the window back. The window moves
-- O15's and O16's beside itself when it hides; O18's waits in the corner.
local function makeRestore(
	style: WindowStyle,
	parts: WindowParts,
	connections: { RBXScriptConnection }
): TextButton
	if style == "O18" then
		return (
			returnControl(
				"Corner",
				UDim2.fromOffset(56, 56),
				Vector2.new(1, 1),
				UDim2.new(1, -16, 1, -16),
				parts.bubbleIcon or ICON.menu,
				UDim.new(0.5, 0),
				connections
			)
		)
	end
	local ghost = style == "O15"
	return (
		returnControl(
			if ghost then "Solid" else "Expand",
			UDim2.fromOffset(44, 44),
			Vector2.zero,
			UDim2.new(),
			if ghost then ICON.eye else ICON.expand,
			UDim.new(0, 10),
			connections
		)
	)
end

-- O14: an icon for this window in a dock along the bottom. The dock is the
-- caller's when given, so several windows can share it.
local function makeDockIcon(
	parts: WindowParts,
	connections: { RBXScriptConnection },
	made: { Instance }
): TextButton
	local icon = returnControl(
		"DockIcon",
		UDim2.fromOffset(44, 44),
		Vector2.zero,
		UDim2.new(),
		parts.bubbleIcon or ICON.menu,
		UDim.new(0, 10),
		connections
	)
	local dock = parts.dock
	if not dock then
		local shelf = Instance.new("Frame")
		shelf.Name = "Dock"
		shelf.AnchorPoint = Vector2.new(0.5, 1)
		shelf.Position = UDim2.new(0.5, 0, 1, -16)
		shelf.AutomaticSize = Enum.AutomaticSize.X
		shelf.Size = UDim2.fromOffset(0, 44)
		shelf.BackgroundTransparency = 1
		shelf.Parent = parts.panel.Parent
		row(shelf, 8).HorizontalAlignment = Enum.HorizontalAlignment.Center
		table.insert(made, shelf)
		dock = shelf
	end
	icon.Parent = dock
	return icon
end

-- O17 on a phone: pressing and holding this shows the window, letting go hides it.
local function makePeekButton(connections: { RBXScriptConnection }): TextButton
	local peek = returnControl(
		"Peek",
		UDim2.fromOffset(0, 44),
		Vector2.new(1, 1),
		UDim2.new(1, -16, 1, -16),
		ICON.hand,
		UDim.new(0, 10),
		connections
	)
	peek.AutomaticSize = Enum.AutomaticSize.X
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = peek
	row(peek, 8)
	local hint = caption(peek, "Hold to show", 2)
	hint.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	return peek
end

local function createWindow(parts: WindowParts, style: WindowStyle): Window
	local panel = parts.panel
	local connections: { RBXScriptConnection } = {}
	local shown = panel.Visible
	local alive = true
	local ticket = 0
	local running: { Tween } = {}
	local made: { Instance } = {}

	local scale = Instance.new("UIScale")
	scale.Name = "WindowScale"
	scale.Scale = 1
	scale.Parent = panel

	local home = panel.Position
	local fullSize = panel.Size

	local function stop()
		for _, tween in running do
			tween:Cancel()
		end
		table.clear(running)
	end

	local function play(target: Instance, info: TweenInfo, goals: { [string]: any }): Tween
		local tween = TweenService:Create(target, timing(info), goals)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function afterTween(tween: Tween, finish: () -> ())
		local mine = ticket
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				finish()
			end
		end)
	end

	-- The offset that puts the panel's anchor on a control's centre, so the
	-- window visibly shrinks into the thing that will bring it back.
	local function toward(control: GuiObject): UDim2
		local target = control.AbsolutePosition + control.AbsoluteSize / 2
		local anchor = panel.AbsolutePosition + panel.AbsoluteSize * panel.AnchorPoint
		local delta = target - anchor
		return home + UDim2.fromOffset(delta.X, delta.Y)
	end

	local show: () -> ()
	local conceal: () -> ()
	local returner: GuiButton? = nil
	local chipHint: TextLabel? = nil
	local openAsk: (() -> ())? = nil

	-- O19 remembers which side the player swiped toward.
	local swipeSide = -1

	-- O2 shrinks into the launcher; O6, O14 and O18 into their own control.
	local function shrinkInto(): GuiObject?
		if style == "O2" then
			return parts.launcher
		end
		return if style == "O6" or style == "O14" or style == "O18" then returner else nil
	end

	-- Where each edge style parks the window while it is away.
	local function offscreen(): UDim2
		local size = panel.AbsoluteSize
		if style == "O7" or (style == "O19" and swipeSide > 0) then
			return home + UDim2.fromOffset(size.X + 24, 0)
		elseif style == "O8" then
			return home - UDim2.fromOffset(0, size.Y + 24)
		elseif style == "O13" then
			return home + UDim2.fromOffset(0, size.Y + 24)
		end
		return home - UDim2.fromOffset(size.X + 24, 0)
	end

	local edgeStyle = style == "O4"
		or style == "O7"
		or style == "O8"
		or style == "O13"
		or style == "O19"

	if edgeStyle then
		returner = makeTab(if style == "O19" then "O4" else style, connections)
	elseif style == "O6" then
		returner = makeBubble(parts, connections, function()
			show()
		end)
	elseif style == "O9" then
		returner = makePill(parts, panel, connections)
	elseif style == "O10" then
		local chip, hint = makeKeyChip(parts, connections)
		returner, chipHint = chip, hint
	elseif style == "O14" then
		returner = makeDockIcon(parts, connections, made)
	elseif style == "O15" or style == "O16" or style == "O18" then
		returner = makeRestore(style, parts, connections)
	elseif style == "O17" then
		returner = makePeekButton(connections)
	elseif style == "O11" then
		local onUnload = parts.onUnload
		assert(onUnload, "O11 needs parts.onUnload")
		local card, open = makeAsk(panel, connections, function()
			conceal()
		end, onUnload)
		card.Parent = panel.Parent
		table.insert(made, card)
		openAsk = open
	end

	if returner then
		if style ~= "O14" then
			returner.Parent = panel.Parent
		end
		table.insert(made, returner)
		-- The bubble taps through its drag check; the peek button holds instead.
		if style ~= "O6" and style ~= "O17" then
			table.insert(connections, returner.Activated:Connect(function()
				show()
			end))
		end
	end

	local function setReturnControl(visible: boolean)
		if parts.launcher then
			parts.launcher.Visible = visible
		end
		if returner then
			returner.Visible = visible
		end
		if chipHint then
			chipHint.Visible = true
		end
	end

	local function revealReturn()
		setReturnControl(true)
		local hint = chipHint
		if hint then
			local mine = ticket
			task.delay(CHIP_COLLAPSE, function()
				if mine == ticket then
					hint.Visible = false
				end
			end)
		end
	end

	function conceal()
		if not shown then
			return
		end
		shown = false
		ticket += 1
		stop()

		-- O15: the window stays where it is, faint and ignoring clicks.
		if style == "O15" then
			panel.Interactable = false
			play(panel, MOTION.exit, { GroupTransparency = GHOST_TRANSPARENCY })
			if returner then
				local topLeft = panel.AbsolutePosition
				returner.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
			end
			revealReturn()
			return
		end

		-- O16: only the tab rail stays, with a button to open the rest again.
		if style == "O16" then
			local rail, body = parts.rail, parts.body
			assert(rail and body, "O16 needs rail and body")
			fullSize = panel.Size
			play(body, MOTION.exit, { GroupTransparency = 1 })
			local fold = play(panel, MOTION.shrink, {
				Size = UDim2.new(0, rail.AbsoluteSize.X, fullSize.Y.Scale, fullSize.Y.Offset),
			})
			afterTween(fold, function()
				body.Visible = false
				if returner then
					local topLeft = panel.AbsolutePosition
					local beside = topLeft.X + rail.AbsoluteSize.X + 8
					returner.Position = UDim2.fromOffset(beside, topLeft.Y)
				end
				revealReturn()
			end)
			return
		end

		if style == "O3" then
			local header, body = parts.header, parts.body
			assert(header and body, "O3 needs header and body")
			fullSize = panel.Size
			local collapsed = header.AbsoluteSize.Y + 24
			play(body, MOTION.exit, { GroupTransparency = 1 })
			local fold = play(panel, MOTION.shrink, {
				Size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, collapsed),
			})
			afterTween(fold, function()
				body.Visible = false
			end)
			return
		end

		local into = shrinkInto()
		if into then
			home = panel.Position
			play(scale, MOTION.shrink, { Scale = MINIMISED_SCALE })
			play(panel, MOTION.shrink, { GroupTransparency = 1 })
			local travel = play(panel, MOTION.shrink, { Position = toward(into) })
			afterTween(travel, function()
				panel.Visible = false
				panel.Position, scale.Scale = home, 1
				revealReturn()
			end)
			return
		end

		if edgeStyle then
			if style ~= "O19" then
				home = panel.Position
			end
			local slide = play(panel, MOTION.shrink, { Position = offscreen() })
			afterTween(slide, function()
				panel.Visible = false
				panel.Position = home
				-- O19's tab waits on whichever side the window was swiped to.
				local tab = returner
				if style == "O19" and tab then
					local side = if swipeSide > 0 then 1 else 0
					tab.AnchorPoint = Vector2.new(side, 0.5)
					tab.Position = UDim2.fromScale(side, 0.5)
				end
				revealReturn()
			end)
			return
		end

		if style == "O9" or style == "O10" or style == "O20" then
			if style == "O9" and returner then
				local topLeft = panel.AbsolutePosition
				returner.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
			end
			play(scale, MOTION.exit, { Scale = 0.95 })
			local fade = play(panel, MOTION.exit, { GroupTransparency = 1 })
			afterTween(fade, function()
				panel.Visible = false
				scale.Scale = 1
				revealReturn()
			end)
			return
		end

		revealReturn()
		if parts.opener then
			parts.opener.close()
		else
			panel.Visible = false
		end
	end

	function show()
		if shown then
			return
		end
		shown = true
		ticket += 1
		stop()

		if style == "O3" or style == "O16" then
			local body = parts.body
			assert(body, `{style} needs a body`)
			setReturnControl(false)
			body.Visible = true
			play(panel, MOTION.grow, { Size = fullSize })
			play(body, MOTION.enter, { GroupTransparency = 0 })
			return
		end

		if style == "O15" then
			setReturnControl(false)
			panel.Interactable = true
			play(panel, MOTION.enter, { GroupTransparency = 0 })
			return
		end

		local from = shrinkInto()
		setReturnControl(false)
		if from then
			panel.Position = toward(from)
			scale.Scale = MINIMISED_SCALE
			panel.GroupTransparency = 1
			panel.Visible = true
			play(scale, MOTION.grow, { Scale = 1 })
			play(panel, MOTION.grow, { Position = home, GroupTransparency = 0 })
			return
		end

		if edgeStyle then
			panel.Position = offscreen()
			panel.GroupTransparency = 0
			panel.Visible = true
			play(panel, MOTION.grow, { Position = home })
			return
		end

		if parts.opener then
			parts.opener.open()
		else
			panel.Visible = true
			panel.GroupTransparency = 0
			scale.Scale = 1
		end
	end

	-- The close button's path: O11 asks first.
	local function hide()
		local ask = openAsk
		if shown and ask then
			ask()
			return
		end
		conceal()
	end

	-- The keybind's path: it never stops to ask, even for O11.
	local function toggle()
		if shown then
			conceal()
		else
			show()
		end
	end

	if parts.launcher then
		table.insert(connections, parts.launcher.Activated:Connect(show))
	end

	-- O17: shown only while the key or the peek button is held down.
	if style == "O17" then
		local peekKey = Enum.KeyCode:FromName(parts.keyName or "LeftAlt")
		local peek = returner
		if peek then
			table.insert(connections, peek.InputBegan:Connect(function(input: InputObject)
				local kind = input.UserInputType
				if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
					show()
				end
			end))
			table.insert(connections, peek.InputEnded:Connect(function()
				conceal()
			end))
		end
		table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject)
			if input.KeyCode == peekKey then
				show()
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.KeyCode == peekKey then
				conceal()
			end
		end))
	end

	-- O19: the header follows a sideways drag; far enough, and the window
	-- leaves that way. A short drag springs back.
	local header = parts.header
	if style == "O19" and header then
		local startX: number? = nil
		table.insert(connections, header.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				startX, home = input.Position.X, panel.Position
			end
		end))
		table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject)
			local kind = input.UserInputType
			local began = startX
			local pointer = kind == Enum.UserInputType.MouseMovement
			if began and (pointer or kind == Enum.UserInputType.Touch) then
				panel.Position = home + UDim2.fromOffset(input.Position.X - began, 0)
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input: InputObject)
			local began = startX
			if not began then
				return
			end
			startX = nil
			local travel = input.Position.X - began
			if math.abs(travel) >= SWIPE_DISTANCE then
				swipeSide = if travel > 0 then 1 else -1
				conceal()
			else
				play(panel, MOTION.grow, { Position = home })
			end
		end))
	end

	-- O20: one timer at a time watches for a stretch with no input at all; any
	-- input in that stretch starts a new one, and the next input after the
	-- window fades brings it back.
	if style == "O20" then
		local activity = 0
		local armed = false
		local function arm()
			if armed then
				return
			end
			armed = true
			local seen = activity
			task.delay(IDLE_SECONDS, function()
				armed = false
				if not alive then
					return
				end
				if activity ~= seen then
					arm()
				elseif shown then
					conceal()
				end
			end)
		end
		local function woke()
			activity += 1
			if not shown then
				show()
			end
			arm()
		end
		table.insert(connections, UserInputService.InputBegan:Connect(woke))
		table.insert(connections, UserInputService.InputChanged:Connect(woke))
		arm()
	end

	setReturnControl(not shown)

	return {
		show = show,
		hide = hide,
		toggle = toggle,
		isShown = function()
			return shown
		end,
		destroy = function()
			alive = false
			ticket += 1
			stop()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			scale:Destroy()
			for _, instance in made do
				instance:Destroy()
			end
		end,
	}
end

local function titleCard(screen: ScreenGui, name: string, title: string): (CanvasGroup, Frame)
	local card = Instance.new("CanvasGroup")
	card.Name = name
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundTransparency = 1
	card.GroupTransparency = 1
	card.Parent = screen

	local column = Instance.new("UIListLayout")
	column.HorizontalAlignment = Enum.HorizontalAlignment.Center
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = card

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.LayoutOrder = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextSize = 28
	label.TextColor3 = THEME.text
	label.Text = title
	label.Parent = card

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.LayoutOrder = 2
	line.Size = UDim2.fromOffset(0, 2)
	line.BackgroundColor3 = THEME.accent
	line.BorderSizePixel = 0
	line.Parent = card
	return card, line
end

-- O5 and O12: a title card that plays once, then gets out of the way. Both
-- return `skip`, which ends the card at once and runs `onDone` exactly once.
local function playCard(
	screen: ScreenGui,
	name: string,
	title: string,
	hold: number,
	onDone: () -> ()
): () -> ()
	local finished = false
	local card, line = titleCard(screen, name, title)

	local function finish()
		if finished then
			return
		end
		finished = true
		card:Destroy()
		onDone()
	end

	TweenService:Create(card, timing(MOTION.enter), { GroupTransparency = 0 }):Play()
	TweenService:Create(line, timing(MOTION.line), { Size = UDim2.fromOffset(120, 2) }):Play()
	task.delay(hold, function()
		if finished then
			return
		end
		local fade = TweenService:Create(card, timing(MOTION.exit), { GroupTransparency = 1 })
		fade.Completed:Once(finish)
		fade:Play()
	end)
	return finish
end

-- O5: before the window's first opening.
local function playIntro(screen: ScreenGui, title: string, onDone: () -> ()): () -> ()
	return playCard(screen, "Intro", title, INTRO_HOLD, onDone)
end

-- O12: after the script unloads, so the player sees that it is gone on purpose.
local function playOutro(screen: ScreenGui, title: string, onDone: () -> ()): () -> ()
	return playCard(screen, "Outro", title, OUTRO_HOLD, onDone)
end

return {
	createWindow = createWindow,
	playIntro = playIntro,
	playOutro = playOutro,
}
```
