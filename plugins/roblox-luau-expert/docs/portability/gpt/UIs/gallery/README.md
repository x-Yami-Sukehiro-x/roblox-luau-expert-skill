# Gallery

Interfaces to look at, and two diagrams of the parts that go wrong. Small on
purpose — four files, under 200 KB. A folder of forty screenshots is a mood
board, and a mood board is what produces the average of everything in it.

| File | What it is | Licence |
|---|---|---|
| `windui-window.png` | WindUI's own window, from `Footagesus/WindUI` `docs/ui.png` | MIT |
| `obsidian-window.png` | Obsidian's example window, from `deividcomsono/Obsidian` `assets/Example.png` | MIT |
| `exemplar-hub.svg` | `../exemplars/ExecutorHub.client.luau` drawn from its own token values, at its 460 × 560 maximum | this repo |
| `anatomy-header.svg` | The 44 px header row with every number on it, beside the two ways it is usually built | this repo |

Both screenshots ship under the MIT licence of the repository they came from and
are reproduced here as reference. Fetched 2026-09-19.

---

## `windui-window.png` — the one to learn presentation from

Read off the image, not off the README:

**Take this:**

- **Three window controls, evenly spaced, each with real reach.** Minimise,
  maximise, close — all icon images, all on the same baseline, all the same
  size. The maximise mark is a proper four-corner bracket, not a letter.
- **A two-line title block.** `.ftgs hub` in bold over `by .ftgs` in muted
  secondary. One element carries the emphasis and the line under it does not
  compete. This is hierarchy done with two type sizes and two greys, no accent.
- **Disabled state is a word and an icon, not a tint.** The locked rows read
  `🔒 Locked` in full-strength text while the row's own label drops to about
  40%. Compare that with dimming the whole row, which is indistinguishable from
  a rendering bug.
- **Two-tier list rows.** Title on top, optional secondary line beneath, trailing
  icon right-aligned. The rows with no second line are shorter. Nothing is
  padded to a uniform height for the sake of it.
- **The content pane is its own surface.** It sits inset from the window edge
  with its own rounding — sidebar and content are different elevations, and you
  can see which one is on top.
- **Almost no colour.** Near-black page, one grey for raised, white and two
  greys for text. The screenshot contains no accent hue at all.

**Leave this:**

- Radius is large — roughly 16 on the window and 12 on rows. That reads as
  consumer-app rather than tool, which is a choice, and it is theirs. This stack
  uses 10 and 6.
- The panel body ends well above the bottom edge with a large empty area. On a
  fixed-height window that is dead space; a `UIFlexItem Fill` on the content
  frame would absorb it.
- It is 1207 × 967 in the shot. Nothing in the image shows how it behaves at
  390 × 844, and `dist/main.lua` has four `UISizeConstraint` in 1.3 MB.

## `obsidian-window.png` — the one to learn density from

**Take this:**

- **A search field in the header.** Once a menu passes roughly twenty controls,
  search stops being a nicety. It is full width and directly under the title.
- **Groupboxes with a title on the border.** Each block of controls is named,
  and the name sits in the frame edge rather than floating above it. That is how
  forty controls stay navigable.
- **The slider shows its value on the fill** — `3/5` centred on the bar. No
  separate label, no tooltip, no guessing.
- **A keybind renders as a pill** (`MB2`), which reads as a key rather than as
  text that happens to say MB2.
- **Dropdown labels sit above their field**, so nothing is truncated and the
  column scans down the left edge.
- **A left accent bar marks the selected nav row**, not just a background
  change. Two signals, one of which survives a colourblind reader.
- **Disabled controls keep their layout and lose their contrast**, and there is
  a disabled dropdown, a disabled button and a disabled value — three different
  disabled states, all drawn.

**Leave this:**

- Radius is about 4 throughout and the strokes are heavy. It is a debug
  instrument, and it looks like one. Fine for a keybind-heavy cheat menu, wrong
  for anything a player sees.
- The toggle row puts three colour swatches immediately beside the switch, which
  reads as four controls in a row rather than one control with options.
- `version: example` in a centred footer strip is chrome that never changes.

---

## What both of them do that the rejected libraries do not

Put the two screenshots side by side and the same three things are true of both:

1. **Every icon is an image**, drawn on one grid at one weight. Not a single
   `×`, `▼` or `✓` font character in either window.
2. **Every state is drawn**, including the ones that are boring to draw —
   disabled, selected, empty.
3. **The surfaces form a ladder** — page, sidebar, content, row — and you can
   name which is on top without being told.

And the same thing is true of neither: **no focus ring.** Grep both libraries
and `SelectionGained` appears zero times. A gamepad user sees nothing move.
That is the gap `exemplar-hub.svg` fills and it is the reason this folder has
its own exemplars rather than only screenshots.

---

## The diagrams

`anatomy-header.svg` is the close-button and title complaint, drawn. Three rows:
the layout that cannot drift, the two-`Position` version where the title sits
6 px high and the close is 24 px, and the version that uses a layout but pads
the gap with a fixed offset so it is right at exactly one window width.

`exemplar-hub.svg` is what `../exemplars/ExecutorHub.client.luau` actually produces, drawn
from the token values in the file rather than from memory — the 44/16 close
button, the toast that reads its fill and radius from the same two tokens the
panel does, and severity carried on a 2 px edge and an icon rather than the
whole fill.
