# Layout and UX: sizes, tab layouts, and improving an existing UI

The user will not say "increase the hierarchy contrast". They will say "it
looks off", "it's cramped", "everything is tiny on my phone", "can you make it
better". This file turns those into decisions with numbers, so a good layout
does not depend on the user knowing the words.

Pair it with `build-order.md` (the order to build in), `blueprints.md` (the
parts), `screen-archetypes.md` (whole screens) and `crisp-ui.md` (blur and
breakage).

---

## 1. Sizes: not too small, not too big

Numbers for a 1280 × 720 computer screen that also survive a 390 × 844 phone.

| Thing | Size | Too small looks like | Too big looks like |
|---|---|---|---|
| Anything tappable | 44 px tall at least, 44 wide for icon buttons | missed taps on a phone | — |
| Row (toggle, slider, dropdown) | 44 px | cramped, hard to tap | 64+: a list that looks empty |
| Body text, row labels | 14 px | squinting at 11 px | 18+: rows that look shouted |
| Secondary text, notes | 12 px, never less | unreadable on a phone | — |
| Section heading | 16 px bold | lost among rows | — |
| Window title | 20 px bold | the window has no name | 28 belongs to one hero only |
| Hero (one per screen) | 28 px | nothing leads | two heroes compete |
| Icons | 16 in rows, 20 in tabs and headers, 24 on HUD buttons | smudges | icons louder than words |
| Window | `fromScale(0.5, 0.65)`, `UISizeConstraint` 300..720 × 320..820 | text wraps everywhere | a 1000 px panel of empty space on a big monitor |
| Script hub | about 560 × 380 at 1280 × 720, sidebar 140 | tabs truncate | covers the game the player is playing |
| Confirm dialog | 360 wide, content height | buttons wrap | reads as a page, not a question |
| HUD chip | 44 tall, as narrow as its content + 24 | — | covers the game: the HUD rule is "smallest that reads" |

**Spacing**, only these values: 4, 8, 12, 16, 24, 32.

| Between | Gap |
|---|---|
| icon and its label | 8 |
| rows in a list | 8 |
| groups of rows | 16 to 24 |
| window edge and content | 16 |
| sections of a page | 24 |

**Density.** One screen does one job. A hub page shows about seven rows before
it scrolls; past twelve, split it into sections with headings or into a second
tab. Empty space around a group is what makes it read as a group.

---

## 2. Which tab layout

Pick by the number of sections and the length of their names, not by taste.
Codes are the style picker's tab styles.

| Situation | Layout | Picker codes |
|---|---|---|
| 2 to 4 views of the same list (Buy / Sell, Daily / Weekly) | Segmented control above the list | S8 |
| 3 to 5 sections, one-word names, window wider than tall | Tabs along the top | S1, S2, S3, S11 |
| 5 to 9 sections, or names longer than one word | Sidebar on the left | S4, S5 |
| A script hub | Sidebar with an icon per tab | S4 or S5 with icons, S6 |
| More than 9 sections | Sidebar with group headings and a search field | S4 + D11 |
| Sections that must fit a narrow window | Scrolling tab strip | S12 |
| An icon-only rail | Only on a computer, only with names on hover | S7 |
| Phone portrait | Tabs along the top or bottom; a sidebar becomes a top strip | S12, S2 |
| Pages that should feel like pages | Add a page turn to any of the above | S9, S10 |

Tab names follow `ui-copy.md`: one or two words, all different, the game's
own words. Tab icons follow `roblox-ui-components/references/icon-meaning.md`.

---

## 3. What reads as organised

1. **One hero.** One element per screen gets the largest type, the accent and
   the most space: the title of a menu, the price in a shop, the claim button
   on a daily reward. If you cannot say which it is, there isn't one.
2. **One left edge.** Titles, labels and section headings start on the same
   line. Controls line up on the right edge. A row is label left, control
   right, nothing floating in the middle.
3. **Group, then order.** Related controls sit together under a heading, at
   most six per group. The most-used group first; anything destructive last,
   separated, and never under the resting thumb on a phone.
4. **One surface rule.** Page, panel, raised card: three levels, each one step
   lighter (or darker) than the one under it. A border is the next step up.
5. **Same things look the same.** Every row 44 tall, every corner from the two
   radii, every toggle the same style. Variation must mean something.
6. **The primary action is obvious and alone.** One filled accent button per
   view. Secondary actions are outlined or plain.
7. **Motion explains, it does not decorate.** Things move from where they
   come from; nothing loops while idle.

---

## 4. Improving an existing UI

When the user shares their UI (code, a screenshot, or a designer export) and
asks to improve it, or says it "looks bad":

1. **Name what it is for** in one sentence. Everything else is judged against
   it.
2. **Measure before judging.** For code, run `lint-roblox-ui.mjs` and note the
   counts: text sizes, radii, spacing values, targets under 44. For a picture,
   estimate the same things against a known size (a 44 px row, a 1280 px wide
   screenshot).
3. **Walk this order**, stopping at the first level that is wrong, because
   later fixes depend on it: purpose → hero → grouping and order → alignment →
   sizes → spacing → surfaces and colour → states → phone.
4. **Report at most five changes, biggest effect first**, each written so a
   non-programmer can picture it and a programmer can apply it:

   > **The window has no clear title.** "Blox Hub" is the same size as the tab
   > names, so the eye has nowhere to start. → Title to 20 px bold; tab names
   > stay 14 px.

5. **Offer to apply them** and, when applying, change only those things.
   Report before and after counts from the linter.

### What usually needs fixing

| They say, or you see | Usually | Change |
|---|---|---|
| "looks cheap", "AI-made" | every surface the same shade, one text size, no hero | three surface levels, the type scale, one hero |
| "cramped" | spacing under 8, no padding on the window | 16 padding, 8 between rows, 24 between groups |
| "empty", "too big" | no max size, huge text | `UISizeConstraint` max, 14 px rows |
| "messy" | several left edges, centred labels | one left edge, labels left, controls right |
| "hard to use on phone" | targets under 44, hover-only actions | 44 px rows, tap states, bottom-placed primary action |
| "boring" | no accent, no motion on open | one accent on the selected tab and primary button; M1 open |
| "too much going on" | an icon on every row, three accents, gradients everywhere | icons on tabs and actions only, one accent, flat surfaces |
| "can't find anything" | ten tabs with one row each, or one tab with forty rows | regroup to 4 to 7 tabs of 4 to 12 rows |
