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
