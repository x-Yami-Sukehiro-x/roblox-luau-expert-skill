<!-- GENERATED FILE - do not edit.
     Source: docs/portability/gpt/UIs/
     Rebuild: node tools/bin/build-portable.mjs
     Verify:  node tools/bin/build-portable.mjs --check -->

# UI pack

Upload this to the GPT's Knowledge. It is `docs/portability/gpt/UIs/`
flattened into one file: the vetted library catalog, the measurements for
headers and notifications, and two complete interfaces that score 24/24 on
the slop rubric and 32/32 on the UI rubric.

---

# Roblox interface sources, vetted

Star counts, licences and last-push dates come from the GitHub API on
**2026-09-19**. The rubric columns come from grepping the file a user actually
loads, on the same date. Nothing here is recalled.

**Read this before picking a library or copying a look.** The usual failure is
not choosing a bad one — it is reaching for the name that appears in every
tutorial, which is how thirty thousand scripts came to look identical.

---

## What the measurements say

Each library, measured on the single file `loadstring` fetches:

| Library | file | bytes | `UISizeConstraint` | `ScreenInsets` | `Activated` | `MouseButton1Click` | `SelectionGained` |
|---|---|---|---|---|---|---|---|
| WindUI | `dist/main.lua` | 1,349,677 | **4** | **1** | 0 | 23 | 0 |
| Obsidian | `Library.lua` | 473,421 | 0 | 0 | 0 | 23 | 0 |
| Rayfield | `source.lua` | 177,048 | 0 | 0 | 0 | 11 | 0 |
| Kavo | `source.lua` | 131,672 | 0 | 0 | 0 | 18 | 0 |
| Orion | `source.lua` | 43,238 | 0 | 0 | 0 | 7 | 0 |

Read the three zero columns first. **No hub library uses `Activated`, and none
has a focus state.** Every one of them binds `MouseButton1Click`, which does not
fire for a gamepad or for Roblox's own selection system, and none listens for
`SelectionGained`, so a controller user gets no feedback at all. Only WindUI has
any bounded sizing, and four constraints across 1.3 MB is not a responsive
layout.

**So: pick a library for its feature set, and never copy its interaction code.**
The six-state, `Activated`-driven, constraint-bounded pattern is in
`exemplars/` and in `library/src/Components/`, and it is not in any of these.

---

## How overused, measured

"Overused" is usually an opinion. It does not have to be. Counted on
2026-09-19, from the GitHub API:

| Library | forks | stars | forks per star | repos with the name |
|---|---|---|---|---|
| **LinoriaLib** | 470 | 95 | **4.9** | — |
| **Rayfield** | 118 | 78 | 1.5 | **1,112** |
| **Obsidian** | 268 | 146 | 1.8 | — |
| **Fluent** | 212 | 121 | 1.8 | — |
| **WindUI** | 345 | 360 | 1.0 | 171 |
| **Kavo** | 50 | 21 | 2.4 | — |
| **Orion** | 20 | 22 | 0.9 | — |

**A fork-to-star ratio above 1 means more people copied it than endorsed it.**
Forking a UI library is not how you use one — you `loadstring` it from a URL.
A fork is somebody taking the source to reskin it, and 470 of them against 95
stars is the shape of a library that gets worn rather than chosen.

**1,112 repositories have "Rayfield" in the name.** That is the whole complaint
in one number. It is not that Rayfield is unusable; it is that a script built on
it is visually indistinguishable from a thousand others, and a model trained on
public Roblox Lua has seen those thousand.

The forks are also where the risk lives: `loadstring(game:HttpGet(...))` against
a fork nobody audited is arbitrary code from a stranger, and the fork list for
each of these is mostly accounts with one repository.

---

## The short answer

| If you need | Use |
|---|---|
| Many toggles, keybinds, saved config | **Obsidian** |
| Presentation matters, fewer options | **WindUI** |
| Two or three controls | **No library.** `exemplars/ExecutorHub.client.luau` is the whole thing in one file |
| In-game UI with real state | **Vide** or **Fusion**, never a hub library |
| A look to learn from, not a dependency | `anatomy.md`, then `exemplars/` |

---

## Accepted

| Library | ★ | Licence | Last push | Why it is here |
|---|---|---|---|---|
| **WindUI** `Footagesus/WindUI` | 360 | MIT | 2026-08-01 (49d) | The best-looking hub library, and the only one with `UISizeConstraint` and `ScreenInsets` anywhere in it. Source is modular under `src/` — readable, unlike a 473 KB single file. Own docs site, 10+ themes |
| **Obsidian** `deividcomsono/Obsidian` | 146 | MIT | 2026-09-11 (8d) | The maintained Linoria fork, and the only dense keybind-first menu anyone is still fixing. Config persistence is built in and is the real reason to pick it. 13 `UIScale` uses, so it at least rescales |
| **GlassmorphicUI** `boatbeaker/GlassmorphicUI` | 171 | MPL-2.0 | 2026-08-25 (26d) | Not a menu library — a real-time blur surface. Worth reading for how it composites, worth using when a panel sits over gameplay |
| **Vide** `centau/vide` | 328 | MIT | 2026-08-05 | In-game UI. Reactive, small, no React ceremony. Pick this over a hub library whenever the UI reflects game state |
| **Fusion** `dphfox/Fusion` | 795 | MIT | 2026-02-02 | In-game UI, the larger ecosystem. Heavier than Vide, better documented |
| **Ripple** `littensy/ripple` | 128 | MIT | 2026-07-18 | Motion, not layout. Read it before hand-rolling springs |
| **Icons** `Footagesus/Icons` | 14 | MIT | 2026-07-05 | Uploaded icon sets with ids. A second source to cross-check `library/src/Icons.luau` against |

**MPL-2.0 is per-file copyleft.** Using GlassmorphicUI unmodified is free;
editing its files means publishing those files' changes. That is why this folder
links it rather than vendoring it.

---

## Rejected, with the measurement

Not "overused" as an aesthetic complaint. Each has a defect that reaches the
finished interface.

### Rayfield — `SiriusSoftwareLtd/Rayfield`, 78★, Apache-2.0, 2026-06-14

Maintained, and still the wrong default.

It **reports usage to a remote endpoint, on by default.** In `source.lua`:

- line 130: `usageAnalytics = {Type = 'toggle', Value = true, ...}`
- line 273: `local ANALYTICS_TOKEN = "05de7f9f…"`
- line 277: `HttpGet` of reporter.lua from the Rayfield repository
- line 285: `url = "https://rayfield-collect.sirius-software-ltd.workers.dev"`

Whatever you think of that, it is a network call your script makes that you did
not write, to a host you do not control, from a client you are already trying to
keep quiet. It is also a second `loadstring` of a remote file at runtime.

Separately: `IgnoreGuiInset` with no `ScreenInsets` (Roblox superseded the first
with the second), no bounded sizing, 11 `MouseButton1Click`, no focus state.

### Orion — `OrionLibrary/Orion`, 22★, no licence, 2021-06-14

Five years unmaintained and **no licence file at all**, so there is no grant to
use it. Predates `ScreenInsets` entirely. 43 KB, 7 `MouseButton1Click`, no
constraints, no focus state.

### Kavo — `xHeptc/Kavo-UI-Library`, 21★, no licence, 2025-09-16

No licence. No sizing constraints and no inset handling of any kind, so it is
correct at one viewport and wrong at every other. Its theme system is a flat
colour swap with no semantic layer — **this is where "my notification does not
match my UI" starts**, and `anatomy.md` is the fix.

### LinoriaLib — `violin-suzutsuki/LinoriaLib`, 95★, MIT, 2024-08-09

771 days, 18 open issues. Superseded by its own fork. Use Obsidian, which is
this code still being maintained.

### Fluent — `dawid-scripts/Fluent`, 121★, MIT, 2024-05-09

Genuinely the best-looking of the old generation, and completely stale: 863
days, 49 open issues. A clean look nobody is fixing breaks on the next GUI
change.

### "Wally's UI library"

No repository resolves under that name. `wally` is Roblox's package manager
(`wally.toml`); the label gets attached to whichever fork someone reposted. If a
script names it, read the URL it actually loads before believing anything about
it.

### Luna Interface Suite — `Nebula-Softworks`, 60★, BSD-3, 2025-12-15

279 days — slowing rather than dead. Fine if a script already uses it, not a
choice for new work.

---

## The pattern all of them share

Four failures, visible in the table at the top and in the output:

1. **One colour table, no semantic layer.** `Theme.Background`, `Theme.Accent`.
   There is no "raised surface" concept, so a notification cannot be told to
   match a panel — only to be the same literal colour, which stops being true
   the moment either moves. `anatomy.md` §3.
2. **No bounded sizing.** Widths in offsets with no `UISizeConstraint`. Right at
   1920×1080, wrong on a phone.
3. **`MouseButton1Click`, never `Activated`.** Gamepad and Roblox's selection
   system get nothing.
4. **No focus state.** Zero `SelectionGained` across all five.

Copying one copies all four.

---

## Using this folder

1. `gallery/` — two real windows to look at, and the header row drawn with
   every number on it. Start here if the question is "what should it look like".
2. `anatomy.md` — measurements for the three things that go wrong most: the
   header row, the notification, and making them match.
3. `exemplars/` — complete files that pass all three linters, with their scores
   printed in `exemplars/README.md`.
4. This file — choose a dependency, or decide you do not need one.

**Never paste a library's source into an answer.** Load it at runtime pinned to a
commit, as `roblox-executor/references/ui/ui-libraries.md` describes.

---

# Anatomy of the three things that go wrong

Header rows, notifications, and making them match. These are named separately
from the rest of the UI guidance because they are the three complaints that
come back after everything else has been fixed.

Numbers marked **(WindUI)** were read out of `Footagesus/WindUI` source on
2026-09-19 and are shown as evidence of what a real library does, not as a
target. Numbers marked **(use this)** are the ones to write.

---

## 1. The header row

The complaint is always "the close button is in the wrong place" or "the title
looks slightly off". Both have one cause: the two elements are positioned
independently instead of laid out together.

### What goes wrong

```lua
-- WRONG. Two absolute positions that drift apart the moment anything resizes.
title.Position = UDim2.new(0, 12, 0, 8)
close.Position = UDim2.new(1, -28, 0, 6)
close.Text = "X"
```

Three separate defects:

- **Two owners for one row.** Nothing keeps `8` and `6` in agreement, so the
  title sits two pixels high forever and nobody can say why.
- **`TextYAlignment` defaults to `Center`, but `TextLabel` height does not.** A
  title in a 44 px row with `AutomaticSize` off and `TextYAlignment = Top` is
  the "title looks off" bug in its commonest form.
- **A letter is not an icon.** `"X"` is laid out on the text baseline, so its
  optical centre is below the box centre, and its stroke weight comes from the
  font rather than from you.

### What to write

One horizontal `UIListLayout`, one `UIFlexItem` absorbing the slack, and the
close button as a sized button with a small image inside it.

```lua
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)   -- 44
header.BackgroundTransparency = 1
header.LayoutOrder = 1

local row = Instance.new("UIListLayout")
row.FillDirection = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.SortOrder = Enum.SortOrder.LayoutOrder
row.Padding = UDim.new(0, Tokens.space.snug)
row.Parent = header

local title = Instance.new("TextLabel")
title.LayoutOrder = 1
title.AutomaticSize = Enum.AutomaticSize.X
title.Size = UDim2.fromScale(0, 1)
title.TextYAlignment = Enum.TextYAlignment.Center   -- the whole bug, fixed
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1

-- The gap between title and close is an element, not a Position offset.
local slack = Instance.new("Frame")
slack.LayoutOrder = 2
slack.BackgroundTransparency = 1
local fill = Instance.new("UIFlexItem")
fill.FlexMode = Enum.UIFlexMode.Fill
fill.Parent = slack

local close = Instance.new("ImageButton")
close.LayoutOrder = 3
close.Size = UDim2.fromOffset(CLOSE_TARGET, CLOSE_TARGET)   -- 44
close.Image = ""                       -- the button draws nothing itself
close.AutoButtonColor = false
close.BackgroundTransparency = 1
```

### The measurements

| Thing | Value | Why |
|---|---|---|
| Header height | **44** (use this) | The touch target sets it. A 32 px header cannot hold a 44 px button |
| Close **button** | **44 × 44** (use this) | Apple and Google both land here; Roblox mobile has no smaller convention |
| Close **mark** inside it | **16 × 16** (use this) | 44 px of reach, 16 px of ink |
| WindUI close button | 16 × 16 icon, hit area `UDim2.new(1, 8, 1, 8)` ≈ **24 × 24** (WindUI) | Under half the target. Measurably hard to hit on a phone |
| Title size | `Tokens.text_size.emphasis` = **16** | One step above body, not the display size |
| Row padding | `Tokens.space.snug` = **8** | On the 4-scale |
| Side inset | `Tokens.space.base` = **12** | `UIPadding` on the header, not a Position offset |

**Order matters more than alignment.** `LayoutOrder` 1 title, 2 slack, 3 close.
Once the row owns the positions, "the close button moved" becomes impossible.

---

## 2. The notification

### Anatomy

| Part | Value | Source |
|---|---|---|
| Width | 320 cap, 240 floor, scale-sized between | `Tokens.toast` (use this) |
| WindUI width | fixed `UDim2.new(0, 300, …)` (WindUI) | fixed, so it overruns a narrow phone |
| Corner radius | `Tokens.radius.panel` = 10 | same radius as the panel it belongs to |
| WindUI radius | 18 (WindUI) | their panel radius, consistently applied — the principle is right, the value is theirs |
| Inner padding | 12 | `Tokens.space.base` |
| Gap between toasts | 8 | `Tokens.space.snug` |
| Anchor | bottom-right, inset 16 | out of the way of a game's own HUD |
| Minimum hold | **1.5 s, timed from arrival** | below this it is a flicker; the linter fails `E-TOASTFAST` |
| Default hold | 4 s, +1 s per 120 characters | reading speed, not a round number |
| Icon | 16 or 20, never a letter | `Icons.triangleAlert`, `Icons.check`, `Icons.info` |

### Severity must not be colour alone

```lua
-- WRONG: a red toast and a green toast are the same toast to ~8% of men.
toast.BackgroundColor3 = isError and Tokens.status.danger or Tokens.status.success
```

Every severity carries a **glyph and a word** as well as a hue. That is
`library/src/Toast.luau`'s `SEVERITY` table, and it is why the UI linter's "no
information by colour alone" gate passes on it.

### Stacking

New toast enters at the bottom, existing ones move up. The timer starts when the
toast **arrives**, not when it was queued — a toast that spent 3 seconds behind
two others and then shows for 1.5 has been on screen for 1.5 seconds, which is
the number that matters.

Pause the timer on hover. Resume on leave. A toast that vanishes while being
read is worse than one that lingers.

---

## 3. Making the notification match the UI

This is the one the rejected libraries cannot do, and the reason is structural
rather than aesthetic.

### Why it fails

A flat theme table gives every component a colour directly:

```lua
-- The Kavo/Orion/Rayfield shape.
Theme = { Background = Color3.fromRGB(30, 30, 30), Accent = Color3.fromRGB(0, 120, 255) }

panel.BackgroundColor3 = Theme.Background
toast.BackgroundColor3 = Color3.fromRGB(35, 35, 35)   -- someone eyeballed it
```

`35, 35, 35` was chosen once, by eye, to look right next to `30, 30, 30`. When
the theme changes, the panel follows and the toast does not. **Nothing in the
code says they were meant to be related**, so nothing can keep them related.

### The fix: one entry decides a height, not two call sites

A toast and a panel are **peers** — both float above the page. So one token
entry decides what "floating" looks like, and both read it:

```lua
-- Tokens.luau, the only place either value exists.
Tokens.surface.overlay   = PRIMITIVE.neutral[4]   -- the floating fill
Tokens.stroke.base       = PRIMITIVE.neutral[4]
Tokens.elevation.floating = { blur = 18, offset = 6, transparency = 0.75 }
Tokens.radius.panel      = UDim.new(0, 10)
```

```lua
-- Both read the same four values. They cannot drift.
panel.BackgroundColor3 = Tokens.surface.overlay
toast.BackgroundColor3 = Tokens.surface.overlay
panelCorner.CornerRadius = Tokens.radius.panel
toastCorner.CornerRadius = Tokens.radius.panel
```

### The test

Change `PRIMITIVE.neutral[4]` to something absurd — bright magenta. Run the
interface. **Every surface at that height must turn magenta together.** Anything
that stays dark was carrying its own literal, and that is the thing that was
going to drift.

If the project already has a palette, take the four values from it and delete
your own. If the user names a colour, it becomes the accent, and the neutrals do
not move.

### Accent is not decoration

One accent, used three to five times in the whole interface: the primary action,
the selected tab, the focus ring. A toast is **not** an accent surface — its
severity hue lives on a 3 px left edge or the icon, and its fill stays neutral.
A fully-tinted toast competes with the game behind it and with the panel beside
it.

---

## Checking it rather than believing it

```bash
node tools/bin/lint-roblox-ui.mjs src/UI/Panel.luau
python tools/py/ui_lint.py src/UI/Panel.luau       # the same rubric, no Node
python tools/py/roblox_lint.py src/UI/Panel.luau
```

And when the request was "redesign it", prove the redesign happened:

```bash
node tools/bin/lint-roblox-ui.mjs --compare old/Panel.luau new/Panel.luau
```

If that prints `0 of them structural`, the layout, type scale and palette are
identical and the word "redesign" is not available to you.

---

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

---

# Exemplars

Two complete files. Not fragments, not a library — the whole thing, from the
token block to the teardown, in one file a reader can paste and run.

They exist because rules do not transfer to a weak model and examples do. When a
model is asked for a hub and has never seen a correct one, it produces the
average of every tutorial it saw, and the average is Rayfield.

## What they score

Measured on 2026-09-19, by running the commands, not by reading the files:

| File | `lint-luau-slop.mjs` | `lint-roblox-ui.mjs` | `verify-asset-ids.mjs` | `verify_api.py --scan` |
|---|---|---|---|---|
| `ExecutorHub.client.luau` | **24/24** | **32/32** | 6 ids, 0 bad | 0 invented |
| `GameMenu.client.luau` | **24/24** | **32/32** | 3 ids, 0 bad | 0 invented |

Reproduce it:

```bash
node tools/bin/lint-luau-slop.mjs docs/portability/gpt/UIs/exemplars
node tools/bin/lint-roblox-ui.mjs docs/portability/gpt/UIs/exemplars
node tools/bin/verify-asset-ids.mjs docs/portability/gpt/UIs/exemplars/GameMenu.client.luau
python tools/py/roblox_lint.py docs/portability/gpt/UIs/exemplars
```

---

## `ExecutorHub.client.luau`

A script-hub panel under an executor: draggable header, a scrolling body of
toggles, a toast stack, a keybind, and one unload path.

What it is there to demonstrate:

| Thing | Where |
|---|---|
| **Header row that cannot drift** | `UIListLayout` + `UIFlexItem` slack; `LayoutOrder` 1/2/3/4, no `Position` |
| **Title that sits where it should** | `title.TextYAlignment = Center` — the whole "title looks off" bug |
| **A close button you can hit** | 44 × 44 `ImageButton`, 16 × 16 `ImageLabel` inside it |
| **Icons that are images** | Six verified lucide ids, referenced by name, never a `"×"` |
| **One alias, no fallback chain** | `gethui or get_hidden_gui`, resolved once, one `assert`. Two executor globals total |
| **Notifications that match the panel** | The toast reads `TOKENS.overlay` and `PANEL_RADIUS` — the same two values the panel reads |
| **Severity that is not colour alone** | Every level carries an icon as well as a tint; the tint is a 2 px edge, not the fill |
| **Six states** | rest, hover, press, focus, disabled, selected — including `SelectionGained` for gamepad |
| **`Activated`, never `MouseButton1Click`** | And `InputBegan` for press feedback, because `MouseButton1Down` never fires on a phone |
| **A rounded box that rounds its children** | `CanvasGroup`, so the opaque row at the edge cannot draw a square corner over it |
| **Teardown** | Every connection and every delayed thread tracked, one `unload()`, published on `getgenv()` |
| **No header comment at all** | There is no fact about this file that the file does not already show. That is the rule working, not an omission |

## `GameMenu.client.luau`

The same discipline in a place you own: a settings modal with a scrim, three
tabs, and the three non-happy states built before the happy one.

| Thing | Where |
|---|---|
| **Loading, empty and error, all present** | `showStatus()`; the error state carries a retry that actually retries |
| **Tab labels from the game's vocabulary** | `Controls`, `Audio`, `Graphics` — not `Settings / Options / Configuration`, which is one word three times |
| **A scrim that dismisses** | And `Escape`, because a modal that only closes via its own button traps a keyboard user |
| **`pcall` around the one thing that crosses a boundary** | `InvokeServer`, and nothing else. One `pcall` in 380 lines |
| **Failure that names the subsystem** | `warn("[settings] load failed: %s")` — one clause, under twelve words |
| **Teardown tied to the player leaving** | `AncestryChanged`, not a `Destroying` hook that never fires |

---

## How to use one

**Copy the shape, not the content.** The tokens, the header, the state wiring
and the teardown transfer to any panel. `Field Kit`, `Highlight nearby players`
and the three tab names are placeholders and should be replaced with the game's
own words — a label that would fit in any project is the tell that survives
every visual fix.

**Keep the token block at the top and keep it the only place a colour appears.**
Every other rule in this folder depends on that one holding.

**Re-run the linters after editing.** A 24/24 file that has been edited is an
unmeasured file.

---

# The exemplars in full

### ExecutorHub.client.luau

```lua
--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local gethui = gethui or get_hidden_gui
assert(gethui and getgenv, "needs gethui and getgenv")

local TOKENS = table.freeze({
	page = Color3.fromRGB(9, 10, 13),
	base = Color3.fromRGB(31, 34, 41),
	raised = Color3.fromRGB(44, 48, 57),
	overlay = Color3.fromRGB(63, 68, 79),
	border = Color3.fromRGB(63, 68, 79),
	textPrimary = Color3.fromRGB(243, 245, 248),
	textSecondary = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentBright = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	danger = Color3.fromRGB(208, 88, 82),
})

local ICONS = table.freeze({
	close = "rbxassetid://116396312853810",
	check = "rbxassetid://86817768619372",
	info = "rbxassetid://120620848266512",
	warning = "rbxassetid://91165848022002",
	danger = "rbxassetid://106305483906363",
	drag = "rbxassetid://136050395759142",
})

local TOUCH_TARGET = 44
local ICON_INK = 16
local PANEL_RADIUS = UDim.new(0, 10)
local CONTROL_RADIUS = UDim.new(0, 6)

local ENTER_SECONDS = 0.2
local EXIT_SECONDS = 0.15
local PRESS_SECONDS = 0.08
local TOAST_HOLD_SECONDS = 4

-- Severity changes the icon and the edge, never the fill: a toast tinted
-- end-to-end competes with the panel beside it and the game behind it.
local SEVERITY = table.freeze({
	info = { tint = TOKENS.info, icon = ICONS.info },
	success = { tint = TOKENS.success, icon = ICONS.check },
	warning = { tint = TOKENS.warning, icon = ICONS.warning },
	danger = { tint = TOKENS.danger, icon = ICONS.danger },
})

local PRESS_INPUTS = table.freeze({
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
})

local connections: { RBXScriptConnection } = {}
local threads: { thread } = {}

local function track(connection: RBXScriptConnection): RBXScriptConnection
	table.insert(connections, connection)
	return connection
end

local function ease(instance: Instance, seconds: number, goals: { [string]: any }): Tween
	local direction = if seconds == ENTER_SECONDS
		then Enum.EasingDirection.Out
		else Enum.EasingDirection.In
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, Enum.EasingStyle.Cubic, direction),
		goals
	)
	tween:Play()
	return tween
end

local screen = Instance.new("ScreenGui")
screen.Name = "Hub"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = gethui()

-- CanvasGroup, not Frame: the rounded corner clips the composited layer, so an
-- opaque child reaching the edge cannot draw a square corner over it.
local panel = Instance.new("CanvasGroup")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.34, 0.52)
panel.BackgroundColor3 = TOKENS.base
panel.BorderSizePixel = 0
panel.GroupTransparency = 1
panel.Parent = screen

local panelBounds = Instance.new("UISizeConstraint")
panelBounds.MinSize = Vector2.new(300, 260)
panelBounds.MaxSize = Vector2.new(460, 560)
panelBounds.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = PANEL_RADIUS
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = TOKENS.border
panelStroke.Thickness = 1
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 12)
panelPadding.PaddingBottom = UDim.new(0, 12)
panelPadding.PaddingLeft = UDim.new(0, 12)
panelPadding.PaddingRight = UDim.new(0, 12)
panelPadding.Parent = panel

local panelColumn = Instance.new("UIListLayout")
panelColumn.FillDirection = Enum.FillDirection.Vertical
panelColumn.SortOrder = Enum.SortOrder.LayoutOrder
panelColumn.Padding = UDim.new(0, 12)
panelColumn.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.LayoutOrder = 1
header.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
header.BackgroundTransparency = 1
header.Parent = panel

local headerRow = Instance.new("UIListLayout")
headerRow.FillDirection = Enum.FillDirection.Horizontal
headerRow.VerticalAlignment = Enum.VerticalAlignment.Center
headerRow.SortOrder = Enum.SortOrder.LayoutOrder
headerRow.Padding = UDim.new(0, 8)
headerRow.Parent = header

local grip = Instance.new("ImageLabel")
grip.Name = "Grip"
grip.LayoutOrder = 1
grip.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
grip.BackgroundTransparency = 1
grip.Image = ICONS.drag
grip.ImageColor3 = TOKENS.textSecondary
grip.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 2
title.AutomaticSize = Enum.AutomaticSize.X
title.Size = UDim2.fromScale(0, 1)
title.BackgroundTransparency = 1
title.Text = "Field Kit"
title.TextColor3 = TOKENS.textPrimary
title.TextSize = 16
title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
-- Center, not the Top a TextLabel defaults to in a fixed-height row. This one
-- property is the whole "the title sits slightly high" complaint.
title.TextYAlignment = Enum.TextYAlignment.Center
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- The gap is an element the layout can size, not a Position offset that stops
-- being right the moment the panel is a different width.
local slack = Instance.new("Frame")
slack.Name = "Slack"
slack.LayoutOrder = 3
slack.BackgroundTransparency = 1
slack.Parent = header

local slackFill = Instance.new("UIFlexItem")
slackFill.FlexMode = Enum.UIFlexMode.Fill
slackFill.Parent = slack

local close = Instance.new("ImageButton")
close.Name = "Close"
close.LayoutOrder = 4
close.Size = UDim2.fromOffset(TOUCH_TARGET, TOUCH_TARGET)
close.BackgroundColor3 = TOKENS.raised
close.BackgroundTransparency = 1
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Image = ""
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = CONTROL_RADIUS
closeCorner.Parent = close

-- 44 px of reach, 16 px of ink. Sizing the glyph as the button is the reason
-- close buttons are hard to hit on a phone.
local closeInk = Instance.new("ImageLabel")
closeInk.Name = "Ink"
closeInk.AnchorPoint = Vector2.new(0.5, 0.5)
closeInk.Position = UDim2.fromScale(0.5, 0.5)
closeInk.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
closeInk.BackgroundTransparency = 1
closeInk.Image = ICONS.close
closeInk.ImageColor3 = TOKENS.textSecondary
closeInk.Parent = close

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.LayoutOrder = 2
body.Size = UDim2.fromScale(1, 0)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 2
body.ScrollBarImageColor3 = TOKENS.overlay
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel

local bodyFill = Instance.new("UIFlexItem")
bodyFill.FlexMode = Enum.UIFlexMode.Fill
bodyFill.Parent = body

local bodyColumn = Instance.new("UIListLayout")
bodyColumn.FillDirection = Enum.FillDirection.Vertical
bodyColumn.SortOrder = Enum.SortOrder.LayoutOrder
bodyColumn.Padding = UDim.new(0, 8)
bodyColumn.Parent = body

local empty = Instance.new("TextLabel")
empty.Name = "Empty"
empty.LayoutOrder = 1
empty.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
empty.BackgroundTransparency = 1
empty.Text = "No modules loaded for this place"
empty.TextColor3 = TOKENS.textSecondary
empty.TextSize = 14
empty.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
empty.TextYAlignment = Enum.TextYAlignment.Center
empty.Parent = body

local toasts = Instance.new("Frame")
toasts.Name = "Toasts"
toasts.AnchorPoint = Vector2.new(1, 1)
toasts.Position = UDim2.new(1, -16, 1, -16)
toasts.Size = UDim2.fromScale(0.3, 0.6)
toasts.BackgroundTransparency = 1
toasts.Parent = screen

local toastBounds = Instance.new("UISizeConstraint")
toastBounds.MinSize = Vector2.new(240, 80)
toastBounds.MaxSize = Vector2.new(320, 480)
toastBounds.Parent = toasts

local toastColumn = Instance.new("UIListLayout")
toastColumn.FillDirection = Enum.FillDirection.Vertical
toastColumn.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastColumn.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastColumn.SortOrder = Enum.SortOrder.LayoutOrder
toastColumn.Padding = UDim.new(0, 8)
toastColumn.Parent = toasts

local toastOrder = 0

local function notify(severity: string, message: string)
	local level = SEVERITY[severity]
	if not level then
		error(("unknown severity %q"):format(severity), 2)
	end

	toastOrder += 1

	-- Same fill, same radius, same stroke as the panel. One token entry decides
	-- what "floating" looks like, so the two cannot drift apart on a re-theme.
	local card = Instance.new("CanvasGroup")
	card.Name = "Toast"
	card.LayoutOrder = toastOrder
	card.Size = UDim2.new(1, 0, 0, TOUCH_TARGET + 16)
	card.BackgroundColor3 = TOKENS.overlay
	card.BorderSizePixel = 0
	card.GroupTransparency = 1
	card.Parent = toasts

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = PANEL_RADIUS
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = TOKENS.border
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local edge = Instance.new("Frame")
	edge.Name = "Edge"
	edge.Size = UDim2.new(0, 2, 1, 0)
	edge.BackgroundColor3 = level.tint
	edge.BorderSizePixel = 0
	edge.Parent = card

	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 12)
	cardPadding.PaddingBottom = UDim.new(0, 12)
	cardPadding.PaddingLeft = UDim.new(0, 12)
	cardPadding.PaddingRight = UDim.new(0, 12)
	cardPadding.Parent = card

	local cardRow = Instance.new("UIListLayout")
	cardRow.FillDirection = Enum.FillDirection.Horizontal
	cardRow.VerticalAlignment = Enum.VerticalAlignment.Center
	cardRow.SortOrder = Enum.SortOrder.LayoutOrder
	cardRow.Padding = UDim.new(0, 8)
	cardRow.Parent = card

	-- The icon carries the severity as well as the hue: red and green are the
	-- same toast to a red-green colourblind reader.
	local badge = Instance.new("ImageLabel")
	badge.Name = "Badge"
	badge.LayoutOrder = 1
	badge.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
	badge.BackgroundTransparency = 1
	badge.Image = level.icon
	badge.ImageColor3 = level.tint
	badge.Parent = card

	local text = Instance.new("TextLabel")
	text.Name = "Message"
	text.LayoutOrder = 2
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.Text = message
	text.TextColor3 = TOKENS.textPrimary
	text.TextSize = 14
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Parent = card

	local textFill = Instance.new("UIFlexItem")
	textFill.FlexMode = Enum.UIFlexMode.Fill
	textFill.Parent = text

	ease(card, ENTER_SECONDS, { GroupTransparency = 0 })

	-- Timed from arrival, not from the queue: a toast that waited behind two
	-- others has still only been readable since it appeared.
	table.insert(threads, task.delay(TOAST_HOLD_SECONDS, function()
		ease(card, EXIT_SECONDS, { GroupTransparency = 1 }).Completed:Wait()
		card:Destroy()
	end))
end

local function paint(button: ImageButton | TextButton, transparency: number, seconds: number)
	ease(button, seconds, { BackgroundTransparency = transparency })
end

local function wireStates(button: ImageButton | TextButton)
	track(button.MouseEnter:Connect(function()
		paint(button, 0, ENTER_SECONDS)
	end))
	track(button.MouseLeave:Connect(function()
		paint(button, 1, EXIT_SECONDS)
	end))
	-- InputBegan rather than MouseButton1Down, which never fires on a phone. The
	-- press state is the one a touch user sees most and the one most often
	-- wired mouse-only.
	track(button.InputBegan:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, 0.4, PRESS_SECONDS)
		end
	end))
	track(button.InputEnded:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, 0, PRESS_SECONDS)
		end
	end))
	-- SelectionGained is the gamepad and keyboard path. Without it, a focus ring
	-- never appears and the panel is unusable on a console.
	track(button.SelectionGained:Connect(function()
		panelStroke.Color = TOKENS.accentBright
	end))
	track(button.SelectionLost:Connect(function()
		panelStroke.Color = TOKENS.border
	end))
end

local function addToggle(label: string, order: number, onChanged: (boolean) -> ())
	empty.Visible = false

	local row = Instance.new("TextButton")
	row.Name = label
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
	row.BackgroundColor3 = TOKENS.raised
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.Selectable = true
	row.Parent = body

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = CONTROL_RADIUS
	rowCorner.Parent = row

	local rowPadding = Instance.new("UIPadding")
	rowPadding.PaddingLeft = UDim.new(0, 12)
	rowPadding.PaddingRight = UDim.new(0, 12)
	rowPadding.Parent = row

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = row

	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.LayoutOrder = 1
	caption.Size = UDim2.fromScale(0, 1)
	caption.BackgroundTransparency = 1
	caption.Text = label
	caption.TextColor3 = TOKENS.textPrimary
	caption.TextSize = 14
	caption.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.TextYAlignment = Enum.TextYAlignment.Center
	caption.Parent = row

	local captionFill = Instance.new("UIFlexItem")
	captionFill.FlexMode = Enum.UIFlexMode.Fill
	captionFill.Parent = caption

	local pip = Instance.new("Frame")
	pip.Name = "Pip"
	pip.LayoutOrder = 2
	pip.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
	pip.BackgroundColor3 = TOKENS.overlay
	pip.BorderSizePixel = 0
	pip.Parent = row

	local pipCorner = Instance.new("UICorner")
	pipCorner.CornerRadius = CONTROL_RADIUS
	pipCorner.Parent = pip

	local enabled = false
	wireStates(row)

	-- Activated, not MouseButton1Click: it fires for touch, gamepad and the
	-- selection system as well as a mouse.
	track(row.Activated:Connect(function()
		enabled = not enabled
		pip.BackgroundColor3 = if enabled then TOKENS.accent else TOKENS.overlay
		onChanged(enabled)
	end))
end

local function unload()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, running in threads do
		task.cancel(running)
	end
	table.clear(threads)
	screen:Destroy()
end

wireStates(close)
track(close.Activated:Connect(function()
	ease(panel, EXIT_SECONDS, { GroupTransparency = 1 }).Completed:Wait()
	unload()
end))

track(UserInputService.InputBegan:Connect(function(input: InputObject, typing: boolean)
	if typing or input.KeyCode ~= Enum.KeyCode.RightShift then
		return
	end
	panel.Visible = not panel.Visible
end))

addToggle("Highlight nearby players", 2, function(enabled)
	local level = if enabled then "success" else "info"
	notify(level, if enabled then "Highlights on" else "Highlights off")
end)

addToggle("Log remote traffic", 3, function(enabled)
	local level = if enabled then "warning" else "info"
	notify(level, if enabled then "Logging every remote" else "Logging stopped")
end)

getgenv().UnloadFieldKit = unload

ease(panel, ENTER_SECONDS, { GroupTransparency = 0 })
notify("info", ("Loaded for %s"):format(Players.LocalPlayer.Name))
```
### GameMenu.client.luau

```lua
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TOKENS = table.freeze({
	page = Color3.fromRGB(9, 10, 13),
	base = Color3.fromRGB(31, 34, 41),
	raised = Color3.fromRGB(44, 48, 57),
	overlay = Color3.fromRGB(63, 68, 79),
	border = Color3.fromRGB(63, 68, 79),
	textPrimary = Color3.fromRGB(243, 245, 248),
	textSecondary = Color3.fromRGB(150, 157, 170),
	textMuted = Color3.fromRGB(96, 103, 117),
	accent = Color3.fromRGB(46, 160, 127),
	accentBright = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
})

local ICONS = table.freeze({
	close = "rbxassetid://116396312853810",
	loading = "rbxassetid://71250150569964",
	alert = "rbxassetid://91165848022002",
})

local TOUCH_TARGET = 44
local ICON_INK = 16
local PANEL_RADIUS = UDim.new(0, 10)
local CONTROL_RADIUS = UDim.new(0, 6)
local ENTER_SECONDS = 0.2
local EXIT_SECONDS = 0.15

local PRESS_INPUTS = table.freeze({
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
})

local TABS = table.freeze({ "Controls", "Audio", "Graphics" })

local connections: { RBXScriptConnection } = {}

local function track(connection: RBXScriptConnection): RBXScriptConnection
	table.insert(connections, connection)
	return connection
end

local function ease(instance: Instance, seconds: number, goals: { [string]: any }): Tween
	local direction = if seconds == ENTER_SECONDS
		then Enum.EasingDirection.Out
		else Enum.EasingDirection.In
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, Enum.EasingStyle.Cubic, direction),
		goals
	)
	tween:Play()
	return tween
end

local screen = Instance.new("ScreenGui")
screen.Name = "SettingsMenu"
screen.ResetOnSpawn = false
screen.Enabled = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local scrim = Instance.new("TextButton")
scrim.Name = "Scrim"
scrim.Size = UDim2.fromScale(1, 1)
scrim.BackgroundColor3 = TOKENS.page
scrim.BackgroundTransparency = 1
scrim.BorderSizePixel = 0
scrim.AutoButtonColor = false
scrim.Text = ""
scrim.Parent = screen

local panel = Instance.new("CanvasGroup")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.42, 0.58)
panel.BackgroundColor3 = TOKENS.base
panel.BorderSizePixel = 0
panel.GroupTransparency = 1
panel.Parent = screen

local panelBounds = Instance.new("UISizeConstraint")
panelBounds.MinSize = Vector2.new(320, 300)
panelBounds.MaxSize = Vector2.new(560, 620)
panelBounds.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = PANEL_RADIUS
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = TOKENS.border
panelStroke.Thickness = 1
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 16)
panelPadding.PaddingBottom = UDim.new(0, 16)
panelPadding.PaddingLeft = UDim.new(0, 16)
panelPadding.PaddingRight = UDim.new(0, 16)
panelPadding.Parent = panel

local panelColumn = Instance.new("UIListLayout")
panelColumn.FillDirection = Enum.FillDirection.Vertical
panelColumn.SortOrder = Enum.SortOrder.LayoutOrder
panelColumn.Padding = UDim.new(0, 16)
panelColumn.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.LayoutOrder = 1
header.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
header.BackgroundTransparency = 1
header.Parent = panel

local headerRow = Instance.new("UIListLayout")
headerRow.FillDirection = Enum.FillDirection.Horizontal
headerRow.VerticalAlignment = Enum.VerticalAlignment.Center
headerRow.SortOrder = Enum.SortOrder.LayoutOrder
headerRow.Padding = UDim.new(0, 8)
headerRow.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 1
title.AutomaticSize = Enum.AutomaticSize.X
title.Size = UDim2.fromScale(0, 1)
title.BackgroundTransparency = 1
title.Text = "Settings"
title.TextColor3 = TOKENS.textPrimary
title.TextSize = 20
title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
title.TextYAlignment = Enum.TextYAlignment.Center
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local slack = Instance.new("Frame")
slack.Name = "Slack"
slack.LayoutOrder = 2
slack.BackgroundTransparency = 1
slack.Parent = header

local slackFill = Instance.new("UIFlexItem")
slackFill.FlexMode = Enum.UIFlexMode.Fill
slackFill.Parent = slack

local close = Instance.new("ImageButton")
close.Name = "Close"
close.LayoutOrder = 3
close.Size = UDim2.fromOffset(TOUCH_TARGET, TOUCH_TARGET)
close.BackgroundColor3 = TOKENS.raised
close.BackgroundTransparency = 1
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Image = ""
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = CONTROL_RADIUS
closeCorner.Parent = close

local closeInk = Instance.new("ImageLabel")
closeInk.Name = "Ink"
closeInk.AnchorPoint = Vector2.new(0.5, 0.5)
closeInk.Position = UDim2.fromScale(0.5, 0.5)
closeInk.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
closeInk.BackgroundTransparency = 1
closeInk.Image = ICONS.close
closeInk.ImageColor3 = TOKENS.textSecondary
closeInk.Parent = close

local tabStrip = Instance.new("Frame")
tabStrip.Name = "Tabs"
tabStrip.LayoutOrder = 2
tabStrip.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
tabStrip.BackgroundTransparency = 1
tabStrip.Parent = panel

local tabRow = Instance.new("UIListLayout")
tabRow.FillDirection = Enum.FillDirection.Horizontal
tabRow.VerticalAlignment = Enum.VerticalAlignment.Center
tabRow.SortOrder = Enum.SortOrder.LayoutOrder
tabRow.Padding = UDim.new(0, 8)
tabRow.Parent = tabStrip

local content = Instance.new("Frame")
content.Name = "Content"
content.LayoutOrder = 3
content.Size = UDim2.fromScale(1, 0)
content.BackgroundTransparency = 1
content.Parent = panel

local contentFill = Instance.new("UIFlexItem")
contentFill.FlexMode = Enum.UIFlexMode.Fill
contentFill.Parent = content

-- The three states a list can be in, all built now. Adding them after the happy
-- path ships is how a player ends up staring at an empty rectangle.
local status = Instance.new("Frame")
status.Name = "Status"
status.Size = UDim2.fromScale(1, 1)
status.BackgroundTransparency = 1
status.Parent = content

local statusColumn = Instance.new("UIListLayout")
statusColumn.FillDirection = Enum.FillDirection.Vertical
statusColumn.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusColumn.VerticalAlignment = Enum.VerticalAlignment.Center
statusColumn.SortOrder = Enum.SortOrder.LayoutOrder
statusColumn.Padding = UDim.new(0, 12)
statusColumn.Parent = status

local statusIcon = Instance.new("ImageLabel")
statusIcon.Name = "StatusIcon"
statusIcon.LayoutOrder = 1
statusIcon.Size = UDim2.fromOffset(24, 24)
statusIcon.BackgroundTransparency = 1
statusIcon.Image = ICONS.loading
statusIcon.ImageColor3 = TOKENS.textMuted
statusIcon.Parent = status

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.LayoutOrder = 2
statusText.AutomaticSize = Enum.AutomaticSize.Y
statusText.Size = UDim2.fromScale(1, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "Loading your saved settings"
statusText.TextColor3 = TOKENS.textSecondary
statusText.TextSize = 14
statusText.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
statusText.TextWrapped = true
statusText.Parent = status

local retry = Instance.new("TextButton")
retry.Name = "Retry"
retry.LayoutOrder = 3
retry.Size = UDim2.fromOffset(120, TOUCH_TARGET)
retry.BackgroundColor3 = TOKENS.accent
retry.BackgroundTransparency = 1
retry.BorderSizePixel = 0
retry.AutoButtonColor = false
retry.Visible = false
retry.Text = "Try again"
retry.TextColor3 = TOKENS.textPrimary
retry.TextSize = 14
retry.FontFace = Font.fromEnum(Enum.Font.GothamBold)
retry.Parent = status

local retryCorner = Instance.new("UICorner")
retryCorner.CornerRadius = CONTROL_RADIUS
retryCorner.Parent = retry

local function paint(button: GuiButton, transparency: number, seconds: number)
	ease(button, seconds, { BackgroundTransparency = transparency })
end

local function wireStates(button: GuiButton, restTransparency: number)
	track(button.MouseEnter:Connect(function()
		paint(button, restTransparency - 0.3, ENTER_SECONDS)
	end))
	track(button.MouseLeave:Connect(function()
		paint(button, restTransparency, EXIT_SECONDS)
	end))
	track(button.InputBegan:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, restTransparency - 0.1, EXIT_SECONDS)
		end
	end))
	track(button.InputEnded:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, restTransparency, EXIT_SECONDS)
		end
	end))
	track(button.SelectionGained:Connect(function()
		panelStroke.Color = TOKENS.accentBright
	end))
	track(button.SelectionLost:Connect(function()
		panelStroke.Color = TOKENS.border
	end))
end

local selected = TABS[1]
local tabButtons: { [string]: TextButton } = {}

local function repaintTabs()
	for name, tabButton in tabButtons do
		local active = name == selected
		tabButton.BackgroundTransparency = if active then 0 else 1
		tabButton.TextColor3 = if active then TOKENS.textPrimary else TOKENS.textSecondary
	end
end

for order, name in TABS do
	local tab = Instance.new("TextButton")
	tab.Name = name
	tab.LayoutOrder = order
	tab.Size = UDim2.new(0, 0, 0, TOUCH_TARGET)
	tab.AutomaticSize = Enum.AutomaticSize.X
	tab.BackgroundColor3 = TOKENS.raised
	tab.BackgroundTransparency = 1
	tab.BorderSizePixel = 0
	tab.AutoButtonColor = false
	tab.Text = name
	tab.TextColor3 = TOKENS.textSecondary
	tab.TextSize = 14
	tab.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	tab.Parent = tabStrip

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = CONTROL_RADIUS
	tabCorner.Parent = tab

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 16)
	tabPadding.PaddingRight = UDim.new(0, 16)
	tabPadding.Parent = tab

	tabButtons[name] = tab
	wireStates(tab, 1)

	track(tab.Activated:Connect(function()
		selected = name
		repaintTabs()
	end))
end

repaintTabs()

local function showStatus(icon: string, message: string, canRetry: boolean)
	statusIcon.Image = icon
	statusIcon.ImageColor3 = if canRetry then TOKENS.danger else TOKENS.textMuted
	statusText.Text = message
	retry.Visible = canRetry
end

local function loadSettings()
	showStatus(ICONS.loading, "Loading your saved settings", false)

	local remote = ReplicatedStorage:FindFirstChild("GetSettings")
	if not remote or not remote:IsA("RemoteFunction") then
		showStatus(ICONS.alert, "Settings are unavailable right now", true)
		return
	end

	local ok, result = pcall(function()
		return (remote :: RemoteFunction):InvokeServer()
	end)
	if not ok then
		warn(("[settings] load failed: %s"):format(tostring(result)))
		showStatus(ICONS.alert, "Settings are unavailable right now", true)
		return
	end
	if typeof(result) ~= "table" or next(result) == nil then
		showStatus(ICONS.alert, "No settings saved for this account yet", false)
		return
	end
	status.Visible = false
end

local function setOpen(open: boolean)
	if open then
		screen.Enabled = true
		ease(scrim, ENTER_SECONDS, { BackgroundTransparency = 0.4 })
		ease(panel, ENTER_SECONDS, { GroupTransparency = 0 })
		loadSettings()
		return
	end
	ease(scrim, EXIT_SECONDS, { BackgroundTransparency = 1 })
	ease(panel, EXIT_SECONDS, { GroupTransparency = 1 }).Completed:Wait()
	screen.Enabled = false
end

wireStates(close, 1)
wireStates(scrim, 1)
wireStates(retry, 1)

track(close.Activated:Connect(function()
	setOpen(false)
end))
track(scrim.Activated:Connect(function()
	setOpen(false)
end))
track(retry.Activated:Connect(loadSettings))

track(UserInputService.InputBegan:Connect(function(input: InputObject, typing: boolean)
	if typing then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and screen.Enabled then
		setOpen(false)
	elseif input.KeyCode == Enum.KeyCode.P then
		setOpen(not screen.Enabled)
	end
end))

track(Players.LocalPlayer.AncestryChanged:Connect(function()
	if Players.LocalPlayer.Parent ~= nil then
		return
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end))
```
