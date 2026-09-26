# Changelog

## 5.10.0 — 2026-09-26

Twelve new skills, a register checker that names what to move and catches
the bug its own fix tends to cause, five tested assets and a copy rule. The
skill list still fits the hosts' start-up budget: 46 skills in 6,976 of 7,000
characters.

### The register limit

- **`check-registers`** (and its Python port) reports two new findings.
  `I-LOCALS`: when the main chunk is the function that is full, its
  top-level locals by family, largest first, including how many library
  elements are never used again. `W-SCOPE`: a name declared `local` in the
  file but read or written as a global elsewhere, which is what a local
  moved into a `do` block turns into; it compiles and is nil at runtime.
  Both ports agree on every Luau file in the repository.
- **`roblox-register-budget`**: why generated scripts hit the 200-local
  limit (a local per toggle, per setting, per remote, per feature), the
  shape to write from the first line, counting without a compiler, the fix
  in order, and why `loadstring(source)()` reports the compile error as
  `attempt to call a nil value`. `references/hub-rewrite.md` is measured:
  a 224-line hub with 199 top-level locals peaks at 206 registers and fails
  two toggles later; the rewrite has 9 top-level locals and peaks at 16.
- Known failures K19, K20 and K24 in the attempt ledger's shared list.

### Executor scripts from the game's code

- **`roblox-executor-planning`**: the plan in five lines before code
  (effect, evidence, mechanism, writers, check) and a pre-mortem table.
- **`roblox-decompiled-features`**: seven feature archetypes, each with the
  evidence it needs, the one call, pacing, stop and the check that proves
  it; `assets/action-loop.luau` repeats a game action at the source's own
  cooldown (8 behaviour assertions).
- **`roblox-feature-recommendations`**: code shapes in a dump and what each
  suggests, genre words as searches rather than suggestions, and the
  combinations of proven facts that make the strongest features.
- **`roblox-runtime-probes`**: `assets/remote-spy.luau` logs the game's own
  remote calls for a window through one pass-through hook that a rerun
  reuses (12 assertions); `assets/table-finder.luau` prints every table
  holding the source's keys without running a metamethod (14 assertions).
- **`roblox-executor-quality`**: the premium bar in twelve checks, each with
  a way to see it; `assets/feature-registry.luau` refuses two owners of one
  property, reports a failed start with its reason and stops what it began
  (10 assertions); resolving targets so a game update fails loudly.

### UI, UX and words

- **`roblox-ui-from-scratch`**: a whole screen from a one-line request, with
  three worked briefs.
- **`roblox-ux-design`**: flows written before layout, and a structure in
  which nothing is built where clipping happens; common flows written out.
- **`roblox-ui-ux-review`**: ranked formatting, UI and UX fixes, with each
  linter code translated into the player's consequence and the smallest fix.
- **`roblox-script-feedback`**: when a script needs notices, status and saved
  settings; `assets/settings-file.luau` for scripts without a hub (13
  assertions: types checked per field, an unreadable file kept aside, a
  failed write reported, session-only without file access).
- **`roblox-copy-craft`**: words on every surface, from labels to commit
  messages. `lint-luau-slop` and `roblox_lint.py` add `W-HYPE` for marketing
  words in `Text`, `Title`, `Description`, `Content`, `Subtitle`,
  `PlaceholderText` and `Name` strings.
- **`roblox-ai-mistakes`**: where models' mistakes come from, the ten that
  cost most, and a catalogue by area with the linter code or test for each.
- Known failures K21 to K23.

### Loading and tooling

- Every description rewritten with trigger words first; the router's
  symptom table and skill map name all 46 skills and fell from 20,031 to
  about 18,700 characters.
- `run-recipe-tests`, `check-all` and `build-portable` find each skill's
  assets by folder, so a new skill's scripts are tested, linted and packed
  without being listed.
- `auto-update.mjs` skips the publish while `.git/publish-hold` exists, so a
  release spanning several scheduled passes is not published half-finished.
- `docs/ROADMAP.md` lists what comes next, including a bytecode-header
  register count to sit beside the listing's peak line.

## 5.9.0 — 2026-09-26

Seven new skills, HubKit (a tested UI library for script hubs), and new
references in four existing skills. The skill list still fits the hosts'
start-up budget: 34 skills in 6,496 of 7,000 characters.

### Added — HubKit and `roblox-hub-library`

- **`library/hub-kit/`**, a script hub UI library in the shape of WindUI,
  written for this stack: `Core/` (New, Theme, Trove, Signal, Motion, Drag,
  Config, Mount, Icons), `Themes/` (Midnight, Daylight, Ember),
  `Components/` (Window, Tab, Section, Popup, Dialog, Notifications,
  OpenButton, SettingsTab) and `Elements/` (a registry, a shared Row, and
  Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Paragraph,
  Divider). Windows are scale-sized between 300 x 240 and 760 x 540 with a
  compact mode, a draggable Open chip replaces the menu key on touch
  screens, configs detect `writefile` and say when saving is off, and one
  trove per window makes unload complete.
- `example/Example.luau` builds a demo hub with every element; it runs in an
  executor from the repository or in Studio from a pasted ModuleScript.
- `tools/bin/build-hub-kit.mjs` bundles the folder into `dist/HubKit.luau`,
  resolving each `require(script...)` the way Rojo lays the folder out and
  refusing any it cannot resolve. `--check` keeps the bundle from trailing
  the sources.
- `tools/tests/hub-kit.test.mjs`: the bundle is current and compiles, every
  theme's text pairs meet 4.5:1, every icon id is one already verified, 95
  behaviour assertions on the kit (elements, popups, search, configs,
  themes, notifications, drag clamping, compact mode, and input connections
  counted back to zero after unload) and 12 on the example (respawn, rerun,
  unload restoring what it changed). Two deliberate breakages were run
  against it; both failed the suite.
- **`roblox-hub-library`**: when to use HubKit, WindUI, Rayfield or no
  library; the four decisions that make a library (registry, shared row,
  theme roles, one trove); eight things every hub gets right; an audit for
  improving an existing hub; the hub-specific tells of generated UI.

### Added — skills

- **`roblox-executor-scripting`**: the order an expert works in, from the
  effect and its owner to the regression matrix; script shapes; a tested
  multi-game loader that routes by `game.GameId` and survives a start that
  errors (`assets/hub-loader.luau`, 8 behaviour assertions); remote calls
  from call sites and what survives serialisation; cross-executor checks.
- **`roblox-improve`**: evidence-first reviews of code, features and UI,
  with a four-part gate against false alarms, three severities, and feature
  suggestions grounded in the game's loop or the hub's purpose.
- **`roblox-debugging`**: exact error, reproduce, which side runs it, one
  probe per hypothesis; an error catalogue, the does-nothing tree and probe
  snippets.
- **`roblox-npc-ai`**: PathfindingService followers that handle blocked
  paths, jump waypoints and the 8-second `MoveTo` timeout, server ownership,
  state machines, sight checks, and one budgeted scheduler for many NPCs.
- **`roblox-combat`**: client intent, server decision; hit tests by weapon
  type with shapecasts and spatial queries, bounded lag tolerance, one
  damage path, projectile stepping, and hit feedback by tier.
- **`roblox-chat`**: TextChatService commands, channels, tags, system
  messages and bubbles, and filtering every string a player types.

### Added — references in existing skills

- `roblox-game-security/references/admin-commands.md`: admin commands
  without a backdoor, and `Players:BanAsync` from Roblox's reference.
- `roblox-ui/references/localization-and-accessibility.md`: translatable
  text, growing containers, larger text, colour and motion.
- `roblox-monetization/references/policy-compliance.md`: which
  `PolicyService` fields gate paid random items, trading, ads and
  subscriptions, failing closed.
- `roblox-executor/references/ui/ui-libraries.md` points at HubKit.

### Changed

- Every description rewritten again to fit seven more skills; the router's
  skill map, symptom table and path list name all 34, and every existing
  skill's Works with section names the new partners.
- `check-all.mjs` runs 31 gates: the kit's UI, slop and format rubrics, its
  tests, and the loader's recipe test are new.
- `build-portable.mjs` carries the new skills and the loader into the GPT's
  workflow pack.

### Sources reviewed

`nonlooped/roblox-suite` (MIT) and `andrian-syh/roblox-best-practices-skill`
(MIT) were used as leads for NPC and review material, re-checked against the
dump and Roblox's creator-docs; one claimed API (`Path.CalculationSecondsTimeout`)
is not in the dump and was left out. `gamedev-skills/awesome-gamedev-agent-skills`
(Apache-2.0) contributed the feedback-tier model. WindUI (MIT) informed the
folder layout only. `brockmartin/roblox-game-skill` and `zilibobi/roblox-skills`
state no licence and were not used.

## 5.8.0 — 2026-09-25

Every skill now reaches the model on every host, the skills hand work to
each other, two gaps are filled from vetted public sources, and the style
picker and designer fit phones, tablets and notched screens.

### Fixed — skills that could be dropped

OpenAI caps the start-up skill list at 2% of the context window or 8,000
characters and shortens descriptions, then drops skills, when it runs over;
Claude Code shares about 1% of its context the same way. The 25 descriptions
totalled 15,787 characters, and `roblox-ui-components` broke the Agent Skills
limit of 1,024 on its own.

- Every description rewritten with its trigger words first: 27 skills now
  total 6,474 characters.
- `tools/bin/lint-skills.mjs`, a new gate: frontmatter to the specification,
  a 7,000-character budget, SKILL.md under 500 lines, a **Works with**
  section naming at least two real skills, and a router that names them all.
  The plugin build runs it on the copies it packs.
- The router gains a skill map: which skills to open together for each kind
  of task, and every skill's path, so a host that trims the list still
  reaches every skill. Its API-verification detail moved to
  `references/verifying-apis.md` and its delivery pass was condensed,
  bringing it from 22,787 to 18,729 characters.

- Codex reads user skills from `~/.agents/skills`, which OpenAI's skill
  documentation lists; `~/.codex/skills`, where `install.ps1` put the Codex
  entry, is not in that list. The installer now also writes the entry skill
  to `~/.agents/skills/roblox-luau-expert-skill`, pointing at the bundle,
  which stays where an existing clone of it may live.

### Added

- **`roblox-studio-mcp`**: checking work in real Studio through its built-in
  MCP server. The `studio_id` and `datamodel_type` rules, the
  read-edit-playtest-console loop, what each other skill can verify there
  (screen captures on emulated devices, clicking real controls, reading live
  state on both sides), and the safety rules for an agent with command-bar
  privilege. Sourced from Roblox's MCP page and MSayib/roblox-dev-skill (MIT).
- **`roblox-game-design`**: loops at a minute, an hour and a week for eight
  genres, the first session, economy sources and sinks with cost curves and
  pacing checks, retention systems, and `AnalyticsService` onboarding,
  economy and progression events with their dump signatures.
- `roblox-game-security/references/audit-imported-assets.md`: quarantining
  Toolbox and Creator Store models, the patterns that mark a backdoor, and
  sandboxing with capabilities.
- A **Works with** section in every skill.
- `docs/ROADMAP.md`: gaps found while researching, with sources, and the
  public skills reviewed and why they were or were not used.

### Fixed — the style picker and designer on phones and tablets

- The designer opens on the device preset nearest the visitor's own screen
  (phone upright, phone sideways, tablet or computer), instead of a
  1280 x 720 computer screen shrunk to 366 px wide.
- Its templates and new windows are sized by percentage with min and max
  limits, so the starter hub fits every preset; it ran off both sides of a
  phone before. Its checks now flag any pixel-only window, with or without
  limits, since limits never shrink a pixel size.
- On phones the toolbar is one scrolling row instead of four, heights use
  `dvh` and `svh` so browser bars do not hide the bottom, content respects
  notch safe areas, controls are 44 px for fingers, fields use 16 px text so
  iOS does not zoom in, and resize handles stay 22 px at any zoom.
- The style picker pads for notches in landscape, its cards no longer force
  a 287 px minimum on narrow phones, the hub demo's "BETA" and "RightShift"
  labels no longer clip, and its fields use 16 px text on touch screens.

Measured at 280, 360, 375, 390 and 430 px wide, phone landscape, tablet in
both orientations and desktop: no horizontal overflow on either page, every
designer template inside every device preset.

## 5.7.0 — 2026-09-25

Four new skills: an attempt ledger that stops an agent retrying what already
failed, executor features that keep working in the user's game, and UI that
fits every screen and answers every input. Three new executor features and a
diagnostic script, and two new UI lint rules.

### Added — skills

- **`roblox-attempt-memory`**: every attempt is recorded in the Attempts
  section of `PROJECT_CONTEXT.md` (tried, saw, cause, instead, patterns to
  avoid, the check that proves a fix). `tools/bin/attempt-ledger.mjs` and its
  Python port `plan` a new approach against failed ones, `check` a file for a
  recorded mistake, `search` by symptom and `lint` the ledger, including two
  failed entries that describe the same approach. `known-failures.md` holds
  eighteen failures the stack has seen repeatedly (body movers, CFrame flight,
  keybinds that fire in chat, character parts read once, hooks without
  `checkcaller`, hover-only help, outer outlines in scrolling lists and more),
  checked on every file.
- **`roblox-executor-reliability`**: naming the effect and its owner, listing
  every writer of the value, holding it with the right mechanism, a
  regression matrix every feature passes, which feature owns which property
  so any combination loads in any order, and the order of questions when a
  feature "does nothing".
- **`roblox-ui-viewport`**: sizing that fits a 640 x 360 landscape phone
  after the topbar and stays bounded on 4K and ultrawide, a device matrix,
  and the fixes for content that leaves its box (long lists, long labels,
  popups at the edge, dragged windows, the on-screen keyboard, toast stacks,
  grids).
- **`roblox-ui-interaction`**: one input contract for mouse, touch and
  gamepad, hit areas, menus and the character underneath, and the ladder for
  a control that does not respond, with `GetGuiObjectsAtPosition` to find what
  covers it.
- `roblox-ui/references/weak-prompt.md`: the decisions to make from a
  one-line UI request and a twelve-row ship bar; `clipping.md`: what clips,
  what draws outside its box, and the fix for each.

### Added — executor assets

- `spectate.luau` (P, then [ and ]): follows another player's Humanoid,
  re-aimed after either player respawns, back to your current body on exit.
- `camera-unlock.luau` (Z): max and min zoom, third person in first-person
  games, and a field of view, each held against the game; a replaced camera
  is followed.
- `freecam.luau` (X): a scriptable camera steered by `MoveDirection`, so
  keyboard, gamepad and the touch thumbstick all move it; right-drag,
  touch-drag or the right stick to look; the body is anchored where it stood
  and its previous state restored.
- `feature-doctor.luau`: read-only. Prints the executor, each loaded feature
  and its state, interacting pairs, a seated or anchored body, streaming, and
  how often each watched property changed in five seconds.
- Recipe tests: 1,249 assertions over 23 files, up from 1,172 over 19.

### Added — checks

- `lint-roblox-ui.mjs` and `ui_lint.py`: `E-STROKECLIP`, an Outer or Center
  stroke cut off by a `ScrollingFrame`, `CanvasGroup` or `ClipsDescendants`
  parent it reaches the edge of; `E-MINFIT`, a top-level panel whose smallest
  size is larger than 640 x 300. Both count in existing rows (L6, H2), so
  scores stay out of 32.
- `tools/py/viewport_fit.py`: each top-level panel's size, the smallest text
  and the smallest button on eleven device profiles, after any `UIScale`.
- `check-file.mjs` and `check_file.py` run the viewport and ledger checks too.

### Fixed

- The scaling formula in `scaling-and-dpi.md` clamped `UIScale` at 0.7, which
  renders 12 px text at 8.4 px and 44 px buttons at 31 px on every phone. The
  floor is now 1: the interface grows on large screens, and phones fit through
  scale sizes and constraints.
- The hub blueprint, window sizes and examples used a 320 px minimum height,
  18 px taller than a landscape phone leaves under the topbar. They use 260.
- A focus ring is `Outer` on a panel and `Inner` inside anything that clips;
  the build order and outline reference said `Outer` everywhere.

## 5.6.2 — 2026-09-25

Style picker demos that were hidden or cut off now show in full.

- T30 (mini switch) showed no switch: its `mini` class also matched the menu
  demo's hidden `.mini` panel. It is now `tiny`.
- C15's progress bar took the fixed bottom **picks bar** styling through the
  shared `bar` class and vanished; it is now `meter`.
- H12's coach bubble ran 28 px past the bottom of its card and hid **Got it**.
  Tooltip cards are now the taller size, with the H12 target raised.
- S15's step circles overlapped the tab names; step tabs now size to their
  content with smaller circles.
- C17's chosen stars are filled, so the rating reads by shape as well as colour.
- D16 no longer draws an empty list strip under the field behind its sheet.

Every card was measured at rest, with tooltips shown and dropdowns open, and
while notifications and menus play, at 1440 and 390 px wide. What still
reaches past a card edge does so by design: D16's sheet waiting below the card,
S12's scrolling strip, and toasts sliding in from the edge.

## 5.6.1 — 2026-09-25

A Roblox-flavoured plugin icon: a yellow blocky head with a simple face,
tilted, with the green check badge. It is an original drawing, not the Roblox
logo, which is a trademark and stays out of this project. `logo.svg` is the
source; `logo.png` and `icon.png` are rendered from it.

## 5.6.0 — 2026-09-25

The plugin gets a logo and gallery screenshots, the README is reorganised
around installing and using the stack, and published commits say what changed.

### Added

- `docs/assets/`: the logo (`logo.svg`, `logo.png`), the plugin icon and two
  screenshots, of the style picker and the UI designer. The OpenAI plugin
  manifest points `composerIcon`, `logo` and `screenshots` at copies in the
  plugin's `assets/` folder.
- The README opens with the logo, star, version, build and licence badges and
  links to the picker and designer, then install steps for every host, the
  style code table and the skills; background moves lower. A star-history chart
  sits above the licence.
- The plugin's path note names `check-file.mjs` and `recipe.py`.

### Changed

- `publish-github.mjs` no longer titles every snapshot `Working tree after
  "<last local commit>"`. A message written to `.git/publish-message` is used
  once; otherwise the subject names the areas that changed, and a version bump
  becomes `Release <version>` with the changelog entry's opening paragraph.
- The picker's toggle and checkbox introductions give the current counts.

### Known issue

Two uploads named `roblox-luau-expert` exist on chatgpt.com/plugins, so every
**Upload new version** is refused with "A plugin named `roblox-luau-expert`
already exists". Removing the unused copy lets the scheduled upload task
install new versions.

## 5.5.0 — 2026-09-24

Ninety-two more picker styles and a new tooltip group, tested executor
feature scripts, one-call checks and recipe lookup for faster replies, and a
way to keep the chatgpt.com plugin current.

### Added — picker styles, 215 codes, all with tested recipes

- Toggles T21–T30 (fill, words at both ends, glow, lever, dot in a ring, edge
  stripe, rocker, status pill, hotkey chip, mini), checkboxes and choice
  groups C11–C20 (tick on the right, count, cross box, big box, checklist with
  progress, joined buttons, stars, colour dots, size buttons, plan cards).
- Dropdowns D13–D22: two-line options, recent first, opens upward, bottom
  sheet, autocomplete, grid, split button, pick then Apply, sub-menus and type
  to add.
- Menu movement M25–M36, notifications N21–N30 (player popup, percent, island,
  sticky, floating reward, objective, bell inbox, invite, captions, edge
  flash), hide and bring back O13–O20 (pull-up tab, dock, see-through, rail,
  hold to show, corner button, swipe away, hide when idle).
- Button feel P13–P22, with `attachAction` for P16–P20 (working, done,
  cooldown, press twice, shake when blocked); tab switch S13–S22 (bottom bar,
  counts, steps, folder, expanding icon, groups, bigger when chosen, More,
  arrows, accordion).
- **Tooltips H1–H12** in the new `tooltips.luau`: hover, arrow bubble, slider
  value while dragging, value on the knob, ends and value, info button, titled
  with a hotkey, follows the pointer, locked reason, press and hold, helper
  line and coach mark. Every one opens by long press on touch and by gamepad
  selection.
- The designer's style lists carry every new code, with previews for the
  shapes that differ, and sliders take an H3, H4 or H5 readout.
- `run-recipe-tests.mjs`: 1,172 assertions over nineteen files.

### Added — two skills

- **`roblox-ui-tooltips`**: which of tooltip, info button, helper line, locked
  reason or coach mark to use; delay, placement and flipping; touch and gamepad
  access; layering above scrolling frames; slider readouts, formatting and
  typing an exact value.
- **`roblox-executor-features`**: fly (`LinearVelocity` and `AlignOrientation`,
  camera-relative, works with the touch thumbstick), noclip, speed and jump,
  infinite jump, ESP (nearest 31 highlighted, labels four times a second),
  click teleport (tap on phones), anti-AFK and fullbright. Each is paste-whole,
  shares one `getgenv().Features` namespace, survives respawn, replaces itself
  on rerun and restores what it changed on unload, and is behaviour-tested.
  `feature-quality.md` is the bar for any other feature.

### Added — faster replies

- `node tools/bin/check-file.mjs <file>` (Python: `tools/py/check_file.py`)
  runs slop, format, UI, API, compile and register checks in parallel, in
  about half a second, with one line per check.
- `python tools/py/recipe.py T21 M28 H3 fly` prints each code's row, the call
  and the files to paste, once each, instead of reading the style pack.
- `roblox-reply-craft/references/fast-path.md`: the request-to-files route for
  the common requests, and where reply time goes.
- The GPT instructions name both tools; they are 100 characters shorter.

### Added — the chatgpt.com plugin

`node tools/bin/web-plugin-update.mjs --status` builds the plugin ZIP and says
whether its version was uploaded; `--record` notes an upload. A scheduled
browser task uses it to upload each new version through "Upload new version".

### Changed

- The UI linter applies the ScreenGui rules (size bound, `ResetOnSpawn`,
  insets) only to a `ScreenGui`, not to a `BillboardGui` or `SurfaceGui`.
- The picker's section links scroll sideways on a phone instead of taking four
  rows of the screen.

## 5.4.0 — 2026-09-24

A drag-and-drop UI designer, twice as many picker styles, working replays,
knowledge for building good screens without being told how, and three new
guards: the local-register budget, evidence-only feature ideas from a dump,
and replies that paste cleanly.

### Added — the UI designer

`docs/visual-guide/designer.html`, hosted beside the picker as `designer.html`.
Drag windows, cards, rows, columns, grids, scroll lists, text, buttons, inputs,
icons and every picker control onto a Roblox screen (computer, laptop, tablet
and phone sizes, with or without the top bar). Move and resize with snapping
and centre guides, edit every property (position and size in scale or pixels,
anchor, automatic size, colours from the chosen direction, corners, outline,
gradient, padding, list and grid layouts, fill, min and max size, aspect,
text font, weight, size and alignment), reorder in Layers, undo and redo.
Seven starting screens: script hub, settings, shop, HUD, main menu, daily
reward, empty. The icon browser holds 1,559 Lucide icons already uploaded to
Roblox, each id checked as a real image. Checks flag small text and targets,
low contrast, long text, filler words, off-screen parts, pixel-only windows,
off-scale padding and too many radii or text sizes, with one-click fixes.

**Copy for AI** exports `roblox-ui-design` v1: real Roblox property values, a
`THEME` of only the colours used, modifiers, controls with their style code,
and a `Does` line per control. `roblox-ui/references/design-spec.md` tells a
model to build it exactly and wire `Does`. Paste a design back in to keep
editing; export and import are exact inverses.

### Added — picker styles, 123 codes, all with tested recipes

- Toggles T11–T20, checkboxes and choice groups C1–C10 (new
  `checkboxes.luau`), dropdowns D1–D12 including search fields, multi-select,
  a player picker and a command palette (new `dropdowns.luau`).
- Menu movement M13–M24, notifications N11–N20 (new `announcements.luau` for
  achievement, announcer, snackbar and feed), hide and bring back O6–O12,
  button feel P4–P12, tab switch S4–S12.
- `run-recipe-tests.mjs`: 705 assertions over ten recipes, up from 262 over six.

### Fixed — replays

Menu movement, notifications and hide-and-bring-back demos stopped replaying:
Web Animations were handed `var()` easings, which throw, and some demos were
never reset. Every demo now uses literal easings, resets before it plays, and
was checked in a browser.

### Added — knowledge for good UI without direction

In `roblox-ui/references/`: `screen-archetypes.md` (twelve whole screens with a
hero, skeleton, states and phone variant), `layout-ux.md` (sizes that are not
too small or big, which tab layout for how many tabs, and a five-change
procedure for improving an existing UI), `crisp-ui.md` (blurry icons, soft
CanvasGroups, clipped dropdowns and other broken UI, each with its cause),
`image-to-ui.md` (measure, spec, build, compare from a screenshot) and
`ui-copy.md` (lengths and filler words for labels, descriptions and
notifications). `roblox-ui-components/references/icon-meaning.md` maps tabs and
features to icons with their ids; `icon-ids.txt` lists all 1,559
(`tools/bin/update-icons.mjs` regenerates and re-verifies it).

### Added — the local-register budget

`tools/bin/check-registers.mjs` (Python: `tools/py/register_budget.py`)
compiles a file at `-O0` and reports each function's peak register use, where
it peaks and its upvalues, failing a function at 160 or more before it reaches
"Out of local registers". Compile errors come back with the limit named and the
fix. `compiler-limits.md` now lists six compiler errors, measured behaviour
from Luau 0.739 (constant locals fold away at `-O1`, 190 locals plus a
71-argument call fails), and a write-under-budget playbook: handles in the main
chunk, one table per family, one local function per tab. Gate and parity pair
added.

### Added — feature ideas from a dump

`dump_index.py --inventory` lists what a dump shows: remotes the client fires
with their call sites, prompts, clicks and touches, tunable numbers in client
code, tags and attributes, and the engine routes. `feature-ideas.md` turns it
into suggestions that each cite a line, say what the dump cannot show, and
never offer server-owned values.

### Added — `roblox-reply-craft`, the nineteenth skill

Faster replies (read less, write less, check once), code blocks that paste
(one whole file per block, no line numbers, entities or blank-line runs),
short file names, and replies without filler.

### Changed

- P0: the check list compiles with `check-registers`; the final script is
  pasted whole in one block; over 150 locals in a function means tables.
- The picker: a designer card in the header, a one-row picks bar on phones, an
  answer box that shows every line.
- Plugin 5.4.0 with nineteen skills and the designer.

`check-all.mjs`: 24 gates.

## 5.3.0 — 2026-09-23

More styles to point at, open and close picked separately, a whole-window hide
and bring-back, and an executor workflow that searches the dump properly and
asks the live game instead of guessing when the dump does not have the feature.

### Added — more picker styles, each with a tested recipe

- Toggles T7–T10: switch with an icon knob, switch with ON/OFF words, status
  light with a word, round tick.
- Menu movement M7–M12: drawer from the right, sheet up from the bottom,
  drop-down from the top, zoom settle, a springy rise with one overshoot, and
  rows arriving one after another. `createPresenter(panel, style, { closeStyle })`
  takes a separate closing style, so "pop in, fade out" is M3 to open and M1 to
  close; the picker has an opening and a closing pick and replays the pair.
- Notifications N7–N10: top-right stack, a one-line status under the top bar, a
  progress toast that turns into a result (`progress(message).done(...)`), and
  a toast with an action button (`action(message, label, onAction)`).
- Hide and bring back O1–O5, `roblox-ui-components/assets/windows.luau`: close
  to a launcher, shrink into the launcher, fold to the title bar, slide to an
  edge tab, and a first-open intro card. Every choice leaves something on
  screen to bring the window back, because a keybind alone strands a phone
  player.

`run-recipe-tests.mjs` now runs 262 assertions over six UI recipes, up from
148 over five. The picker page gained the same styles, an opening/closing pair
card, a Hide & bring back section, and saves picks in a new format.

### Added — searching a dump for a feature

`tools/py/dump_index.py` indexes a decompiled dump (`.lua`, `.luau`, `.txt`
files or folders, and the script sources inside a saveinstance `.rbxlx` /
`.rbxmx`): every remote call with its argument count and the line that
defines its receiver, listeners, instance names, attributes, tags, requires and
failed-decompile regions. `--feature "auto farm"` expands the words into
synonyms, ranks every hit by what kind of code it is in, lists the remote calls
inside the matching functions, and ends with FOUND, PARTIAL or NOT FOUND.
Fly, noclip, speed, jump, ESP, teleport and aim are marked as engine routes:
their absence from a dump is expected, and the output names the engine members
to build on. `roblox-executor/references/technique/feature-search.md` is the
procedure around it: restate the feature as a mechanism, index, four search
passes, an evidence table, and a verdict that decides the reply.

### Added — the runtime probe, instead of guessed names

When the verdict is PARTIAL or NOT FOUND, the reply sends
`roblox-executor/assets/runtime-probe.luau` with the `KEYWORDS` line the
indexer printed, and builds nothing for that feature. The probe only reads. It
writes `feature-probe.txt` with every remote (matches starred), matching client
scripts and their hashes, `getgc` closures whose constants match, tables with a
matching key (read with `next`, so no metamethod runs), the player's
attributes, leaderstats and humanoid values, and the decompiled source of the
matching scripts. The user sends the file back and the search runs again over
it. A new P0 rule says to search first and never write code that guesses names.

### Changed — the GPT and plugin carry everything

- The GPT gets a seventh knowledge file, `roblox-ui-style-picker.html`, so it
  can hand the picker over as a download when the hosted link does not open.
- `workflow-pack.md` now carries `feature-search.md` and the runtime probe in
  full; `style-pack.md` carries every new recipe.
- The OpenAI plugin puts the picker in
  `skills/roblox-request-intake/assets/` and its router names
  `dump_index.py` and the picker's path.

### Changed — public repository, licensed, nothing private in it

- The style picker is public at
  <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>, deployed
  from `docs/visual-guide/index.html` by `.github/workflows/plugin.yml`. The
  earlier hosted copy could only be opened by its owner.
- Licensed under the PolyForm Strict License 1.0.0 (`LICENSE.md`): noncommercial
  use only, no changes, no redistribution. `NOTICE.md` lists the third-party
  files that keep their own licenses. The plugin manifests no longer say MIT.
- `.gitignore` keeps the version briefs, GPT test transcripts, local Claude
  config, and secret or editor files out of the repository; the GPT package no
  longer carries the briefs either.

### Gates

`check-all.mjs` adds the indexer tests (6), and the slop and format rubrics
over the executor assets. The probe has its own behaviour test (10 checks)
against a stubbed game and executor.

## 5.2.0 — 2026-09-23

A user who does not know UI words can now point at what they want, and a pick
is built from one tested implementation instead of from memory.

### Added — the Roblox UI style picker

`docs/visual-guide/index.html`, also hosted at
<https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>. Playable, labeled examples:
six toggles (T1–T6), seven menu movements (M0–M6), six notification styles
(N1–N6), three button feels (P1–P3), three tab switches (S1–S3), and a hub
window whose parts are numbered W1–W22 so "make W3 bigger" replaces hunting for
the word "close button". The user presses **Copy my picks** and pastes a
summary. The previous guide had three toggles, four movements and three
notification styles and was reachable only by unpacking the GPT archive.

### Added — a tested recipe behind every code

`roblox-ui-components/assets/` holds five single-file recipes (toggles, menus,
toasts, notices, press-and-tabs) and `references/style-recipes.md` says what
each code builds, to the pixel and the second. `tools/bin/run-recipe-tests.mjs`
runs 148 behaviour assertions against the engine stubs — activation, focus
surviving hover loss, disabled rows, a close interrupted by a reopen, a dragged
window keeping its place, error toasts that stay, hover pause, dedup, queue
drain, alert answering once. Every recipe scores 24/24, 8/8 and 32/32 on the
slop, format and UI rubrics, and its asset ids were checked against Roblox.
Four new gates in `check-all.mjs` keep it that way.

Writing the toast recipe found a layout bug the stubs cannot see: a time-left
bar parented inside the card's `UIListLayout` would be laid out as a row item.
The row now lives in its own frame.

### Added — plain words for UI parts

`roblox-request-intake/references/ui-words.md` maps "the X", "the bar you
drag", "the dark background behind the popup" and "make it pop" to parts and
changes. `visual-choices.md` maps everyday answers to codes.

### Changed — the library toast uses image icons

`library/src/Toast.luau` marked severity with the text glyphs `i`, `+`, `!`
and `x`, which the stack's own rules forbid. It now uses the verified lucide
images from `Icons.luau`.

### Added — the OpenAI plugin

OpenAI retires custom GPTs on 11 December 2026. `tools/bin/build-openai-plugin.mjs`
builds a portable plugin with all eighteen skills, the checkers, the library
and the picker; `.agents/plugins/marketplace.json` lists it for Codex and the
ChatGPT desktop app. The Python and Node checkers now find the skills in the
plugin layout (`skills/`) as well as `.claude/skills/`.

### Changed — the GPT reads its knowledge in full

The live GPT had two of its five knowledge files, and a custom GPT's retrieval
returns fragments (the editor reports a 16,384-token budget). The instructions
now tell it to read the needed files in full with Code Interpreter and name what
it read, link the hosted picker, build picked codes from their recipes, and save
confirmed picks and corrections to memory when memory is available. A new
knowledge file, `style-pack.md`, carries the picker question, the word map, the
code contract and all five recipes in one retrievable place.

## 5.1.0 — 2026-09-20

The executor workflow now separates source evidence from runtime identity.
Decompiler labels are not upvalue indices, first matches are not unique targets,
and absent client logic does not prove server ownership. Source contracts carry
unknown arguments explicitly; rerun and unload preserve captured values and
respect newer owners.

UI guidance now distinguishes selected controls from one-shot actions, loading
from selection, and static lint from rendered or behavioral evidence. A focused
functional pass covers delayed results, repeated activation, close/reopen,
focus, touch and teardown. Tween replacement guidance follows the engine's
cancellation behavior; decorative idle pulses are removed.

A task contract carries confirmed decisions and corrections across chats through
an explicit project record. It does not claim automatic GPT memory. The direct
GPT workflow pack exposes the source-reading and UI workflows alongside the
existing UI examples and full archive. Portable package tests exercise stale
source detection, corrupt archives and preservation of the last good package.
The aggregate validation command reports skips and partial checks honestly.

The v5.0 historical claim below about zero changed counts is superseded: equal
counts do not prove equal behavior or layout. Diff review and runtime/visual
evidence cover changes that counters cannot measure.

## 5.0.0 — 2026-09-19

Four things the GPT kept doing that the rules already forbade, and the reason
each rule was not holding.

### Added — the rules can now run where the model runs

`tools/py/roblox_lint.py` and `tools/py/ui_lint.py` are ports of
`lint-luau-slop.mjs` and `lint-roblox-ui.mjs`. Standard-library Python, no
dependencies, one file each.

This is the root cause of most of the rest. A custom GPT's Code Interpreter is
a Python sandbox with no Node, so every instruction saying **run the counter**
was advice the host could not take — and a rule a model cannot execute is a
rule it can only claim to have followed. The stack had been writing that
instruction since v3.

The ports are not trusted, they are compared. `tools/bin/lint-parity.mjs` runs
every Luau file in the repository through both implementations of both linters
and fails on any difference in code, line or message. It found a real bug on
its first run: `lint-luau-slop.mjs` computed `W-MAGIC` line numbers from an
index into a *different* string, so every line number drifted by the length of
the string literals above it.

`tools/py/verify_api.py` answers the same questions offline, from the generated
flat indexes rather than the dump:

```bash
python tools/py/verify_api.py Humanoid.WalkSpeed      # exists, deprecated, gated
python tools/py/verify_api.py Enum.EasingStyle.Quad   # real enum item
python tools/py/verify_api.py --scan Script.luau      # every name this file establishes
```

`--scan` resolves each local the file binds to a class and checks every member
read off it, walking the inheritance chain. Its first version flagged `toast.gap`
and `Enum.HorizontalAlignment.Center` as invented APIs; the shipped version has
zero false positives across all sixteen hand-written files in `library/`, and
prints which receivers it resolved so what it did **not** check is visible.

### Added — three new ground-truth indexes

`enum-index.txt` (633 enums, 3,634 items), `class-hierarchy.txt` (921 classes)
and `gui-classes.txt`, all generated from the dump.

The enum one closes a real hole: `Humanoid.SuperJump` was falsifiable by grep
and `Enum.EasingStyle.Smooth` was not. The hierarchy one closes its mirror —
`api-index.txt` lists a member against the class that **declares** it, so
`Workspace.Raycast` is absent from it and `WorldRoot.Raycast` is not, and a
grep without the chain reports a real API as invented.

### Added — a claim needs a command

New P0 section, plus delivery-checklist §6a and a `--compare` mode on both
linters.

The reported failure: "completely redesign the UI" comes back as a new file and
a reply saying it was redesigned, and it was not. That claim was unfalsifiable
from the reply, so the user found out by opening Studio — which is the job they
had delegated.

```bash
node tools/bin/lint-roblox-ui.mjs --compare old.luau new.luau
```

prints elements, type scale, radii, spacing set, palette and connections, before
against after, and then how many moved. **`0 of them structural` means the
layout, the type scale and the palette are identical**, and the word is not
available. `lint-luau-slop.mjs --compare` does the same for score, comments,
header, capability checks, `pcall`s, value layers and executor surface.

### Added — three counted rules that prose was not carrying

- **`E-CLAUSE`.** `E-RESTATE` scored a comment as one block, so a four-line
  comment with one load-bearing line and three of restatement passed by
  dilution. The clause is the unit now: a four-line comment with one
  load-bearing line is one line long.
- **`E-DECOMPNAME`.** `v14`, `u3`, `p1` surviving into delivered code. The rule
  existed in prose in three places and nothing counted it.
- **`E-LAYERCHAIN` and `W-EXECSURFACE`.** "One API per job" is the executor
  half's central rule and was entirely uncounted. `E-LAYERCHAIN` fails on an
  `or` between two value layers on one line, and on a third layer anywhere in
  the file. Alias spellings of one function — `getcustomasset or getsynasset` —
  count once, because two names for one call is not two places to look.

The score is out of 24 now, not 22. Everything the stack ships still scores
full marks.

### Added — docs/portability/gpt/UIs/

A vetted library catalog, the anatomy of the three things that go wrong, and two
complete interfaces.

Every row in the catalog was measured on 2026-09-19 — the GitHub API for stars,
licence and last push, and `grep` over the single file each library's users
actually `loadstring`. Across WindUI `dist/main.lua`, Obsidian `Library.lua` and
the `source.lua` of Rayfield, Kavo and Orion — 2.2 MB of Lua — there are **zero**
uses of `Activated`, **zero** of `SelectionGained`, and four `UISizeConstraint`,
all in WindUI.

That is why a model that learned Roblox UI from public hub scripts produces
interfaces with no focus state, no bounded sizing and no gamepad path: five
independent sources agree, and agreement is what consensus looks like from the
inside. It is one mistake copied four times.

Rayfield is rejected on evidence rather than taste: `usageAnalytics` defaults to
true, and `source.lua` fetches and executes a reporter from its own repository
which posts to a Cloudflare Worker. Line numbers are in the catalog.

`exemplars/ExecutorHub.client.luau` and `exemplars/GameMenu.client.luau` are the
positive half — one hub panel, one settings modal, each complete in one file.
Both score **24/24** on the slop rubric and **32/32** on the UI rubric, both are
gated by `check-all.mjs` so they cannot rot, and every asset id in them was
verified against Roblox. Neither has a header comment, which is the rule
working rather than an omission.

`build-portable.mjs` flattens the folder into `knowledge/ui-pack.md`, because a
GPT retrieves a markdown file without deciding to unpack a zip first.

### Changed — the GPT instructions field is full

7,994 of 8,000 characters. Fitting the claim gate, the clause rule, the
decompiler-name rule and the Python commands meant moving the full runtime rules
to P1 and leaving a five-line summary in P0.

The rule that decided which section moved: **P0 keeps what a model gets wrong
without it.** Server authority is in every Roblox tutorial ever written and a
model arrives already believing it. The comment budget, the UI order and
one-API-per-job are not, and it does not.

### Changed — three public skills mined, the rest declined

`shut-up-and-code` supplied the per-clause test. `verification-before-completion`
supplied the claim gate, narrowed from "evidence before claims" to something
checkable: a command in the same reply. `evolutionary-naming` supplied the rule
that a confident wrong name costs more than an obvious placeholder, which is
what decides how far to rename a decompiled `v14`.

Everything else was declined with a reason, in `docs/SOURCES.md`. The test
applied: does it change what a file looks like when it ships, in a way something
here can check? The web design skills are right about slop and specific about
HTML; Roblox has no cascade.

### Fixed

- `lint-luau-slop.mjs` reported `W-MAGIC` line numbers from the wrong string,
  drifting by the combined length of the string literals above the number.
  Found by the parity gate on its first run.
- `check-all.mjs` is fourteen gates, and now covers the exemplars and the
  Python ports.

## 4.4.0 — 2026-09-19

Both of these came out of running the v4.3 GPT against a five-word prompt and
reading what it produced.

### Fixed — the rubric could not see through a helper either

v4.3 taught the UI gate to read `new("Frame", { ... }, parent)`. The test file
used a different helper shape:

```lua
local function addFlexFill(parent)
    local flex = Instance.new("UIFlexItem")
    flex.Parent = parent
end
addFlexFill(title)
```

The modifier's parent is the **parameter**, so nothing linked it to `title`,
and three dead `Size` values passed. `expandAttachers` now replays these at
each call site with the call's literal arguments substituted, and marks the
helper's own copy a template so one `addCorner` does not read as a radius of
its own.

Two more fell out of it. Property values now continue past a newline while
brackets are open — `corner.CornerRadius = UDim.new(\n 0,\n radius\n)` was
being stored as `UDim.new(`. And `E-DEADSIZE` now checks offsets, not only
scales: an offset under a flex fill is never idiomatic filler.

Together those made radii and spacing resolve for the first time on
helper-built files. **It then caught two dead sizes in the v4.3 rewrite** —
`Size = UDim2.fromOffset(300, 136)` on a panel whose constraint already pinned
136.

### Added — the header budget now covers content, not just length

Four lines of nothing scored inside the four-line cap:

```lua
-- NotificationDemo.client.lua
-- This interface is client-owned and never stores authoritative game state.
-- The close image is Roblox Creator Hub asset 5577404210.
-- Connections and delayed threads are torn down with the ScreenGui.
```

The file name, a rule every file here follows, a restatement of the constant
below, and a description of the teardown function. Every one goes stale when
the thing it describes changes, and nothing fails when it does.

`E-FILENAME` and `E-HEADERSUMMARY` fail a comment that is only a file name, one
starting `Handles`/`Manages`/`Creates`/`This script`, architecture boilerplate
(`client-owned`, `server-authoritative`), and `connections are torn down`.

It deliberately does not pattern-match "the close image is asset 5577404210",
because that shape collides with a header line that earns its place — the
origin of a magic number. `anti-slop-code.md` §1a carries that distinction.

Comment runs keep their per-line text now, so each offending line is named
rather than the run being reported once.

### Added — a rounded box does not round its children

Reported as "the accent bar is pointing out of my rounded notification". It is
not a bug in the bar. Roblox's `UICorner` documentation:

> Input, but not descendants, will be clipped to the round corner area.

A full-height strip at the container's edge keeps its square corner and draws
over the rounded one. **`ClipsDescendants` does not rescue it** — that clips to
the rectangle, so setting it looks like a fix and changes nothing.

`E-CORNERBLEED` fails an opaque child that fills an axis inside a rounded
container that is not a `CanvasGroup` and has no `UIPadding`. `E-SCROLLCORNER`
fails `UICorner` on a `ScrollingFrame`, which Roblox documents as unsupported.

The fix is a `CanvasGroup`, and the same docs say why: "UICorner and UIGradient
under a CanvasGroup will also apply to the whole group." `outlines-and-dividers.md`
carries the three conditions that come with it — `ZIndexBehavior = Sibling`,
the texture-memory cap that renders a blank panel when exceeded, and static
sizes.

### Changed

- The UI rubric is out of **32**; the slop rubric out of **22**.
- P0 gains the header-content rule and the rounding rule, at **7,968** of
  8,000. `[P0] Vague and non-technical requests` had already gone; its one
  binding sentence is now a bullet under the runtime rules.
- `evals/triggers.md` gains twelve rows across headers and rounded containers,
  including two that must produce **no** finding.

## 4.3.0 — 2026-09-19

**v4.2 counted the ceremony. The UI gate was counting nothing.**

The same model that produced the v4.2 test case produced a 726-line successor
with a real interface, and `lint-roblox-ui.mjs` reported **20/20, all counted
checks pass** — while printing `0 text size(s)` about a file with four of them.

The file used a `new("Frame", { ... }, parent)` helper. The linter matched
`x.Prop = v` and `Instance.new("Literal")`, so all thirty-seven of its GUI
objects were invisible. It did not fail to find the defects; it never looked.

**A gate that passes because it could not read the file is worse than no gate,
because a score is evidence.**

### Added — a model of what the file builds

`tools/bin/lib/gui-model.mjs` resolves construction before anything is
counted. Two forms — `Instance.new("Class")` with later property writes, and
`helper("Class", { ... }, parent)` with any helper name — become one list of
elements with their class, parent, properties and lines.

It walks constructions and assignments in **source order** against a live
binding table. A file with `local layout = ...` in four functions has four
layouts; the previous pass folded all four into the first, which both hid real
findings and invented false ones.

It also resolves named numeric constants, so `UDim.new(0, GAP_BASE)` counts the
same as `UDim.new(0, 8)`. Without that the rubric was strictest on the code
that names its numbers and blindest to the code that sprays them.

`E-BLIND` fires when a file names GUI classes and resolves no construction. It
refuses to score rather than scoring what it cannot see.

### Added — five rubric rows for numbers nothing reads

The rubric is out of **30** now. C1–C10 ask whether the design language is
consistent; L1–L5 ask whether the code says what it means.

| Row | Catches |
|---|---|
| L1 | a `Size` scale a `UIFlexItem Fill` or a pinned constraint already decides; a `UIPadding` of 0 |
| L2 | `TextYAlignment.Top` inside a centred row; `ZIndex` on an only child |
| L3 | a text element parented before anything sets its `Text` |
| L4 | a font glyph used as an icon; an unverified asset id |
| L5 | a notification lifetime under 1.5 s; `ScreenInsets` and `IgnoreGuiInset` both set |

On the generated panel: **20/30, ten errors.** On `library/src`: 13 files,
30/30, no findings.

Calibrating it removed one check and fixed two parser bugs. A stroke-consistency
check fired on four hand-written components where the difference was a focus
ring, a shadow or a real elevation change — so whether two surfaces sit at the
same height stays in the reference, where judgement lives. `E-DEADZINDEX` now
skips `list.ZIndex = panel.ZIndex`, which inherits a stacking context rather
than claiming an order, and skips parents the file did not build.

**It found two real defects in the library once it could resolve constants:**
dropdown rows at 34 px and tab buttons at 40 px, both under the 44 px floor
the stack's own H4 gate states. Both raised.

### Added — asset ids, checked against Roblox

`tools/bin/verify-asset-ids.mjs` asks the thumbnail service about every id in a
file. Three cases that are identical in source come back distinct:

| Verdict | Means |
|---|---|
| `Completed`, `/Image/` | real, and it is an image |
| `Completed`, `/UnknownImage/` | the id exists and is not an image — renders blank |
| `Error`, `/BrokenImage/` | no such asset |

`rbxassetid://1234567890`, the placeholder every model reaches for, is the
middle case. An invented id compiles, runs, raises nothing, and shows an empty
square; only the asset service knows. The tool exits **2** when it cannot reach
Roblox, because a gate that passes when it could not check is the first failure
again.

`library/src/Icons.luau` ships 81 lucide icons — the set uploaded at
`icons.rest` — and `check-all.mjs` re-verifies every one on each run.

### Added — the craft references behind the rows

- `roblox-ui-components/references/icons.md` — why `"×"` is not an icon, the
  verified table, `ImageColor3` and the 44-with-16-inside pattern,
  `getcustomasset` for executors (PNG not SVG), and how to draw a cross when
  there is no id.
- `roblox-ui/references/ui-rewrite.md` — the generated panel scored, every
  finding shown before and after, and what did **not** change.
- `roblox-ui/references/blueprints.md` gains **B1a**, the header row: one owner
  per number, and the three ways a title and close button go wrong.
- `shadows-and-elevation.md` gains the surface/border/shadow triple and the
  rule that peers look the same — the countable form of "the notification
  doesn't match my UI".
- `toasts.md` gains the 1.5 s floor and the arithmetic behind most sub-second
  toasts: the timer starts when the entrance starts, not when it ends.

### Added — narrating the edit

`lint-luau-slop.mjs` gains `E-EDITNOTE`. Handed a working file and asked to
change it, models return it covered in `-- Fixed:`, `-- Changed the`,
`-- Previously this`. The diff already says that, in a place that stays correct
when the next edit lands.

Only the comment-initial position counts, so facts survive: `-- Added the
fallback path` fires, `-- The part is no longer parented while idle` does not.
`anti-slop-code.md` §2a has the edit discipline and what to say in the reply
instead.

### Changed — the portable rules

P0 gains the header row, the icon rule, the peer-surface rule, one-owner-per-
number and the edit-narration rule. The 8,000-character Instructions cap meant
finding room: **7,953 now.**

Two things moved to P1, on the same principle both times — **the rule is P0,
the lookup is not**. The executor layer-to-call mapping became a table in P1
while "one API per job, a fallback chain is a confession the source was not
read" stayed. The palette's sixteen RGB triples moved to P1 while "one palette,
one token block, no colour literal anywhere else" stayed.

`[P0] Vague and non-technical requests` was cut to its one binding sentence —
**translate, decide, build, state; one clarifying question maximum** — and the
list of what to decide rather than ask became `[P1] What to decide rather than
ask`. Claude, Codex and Cursor still receive every tier in full; only the GPT's
Instructions field is capped.

### Fixed

- `library/src/Components/Dropdown.luau` rows were 34 px.
- `library/src/Components/TabBar.luau` buttons were 40 px.
- `library/src/Toast.luau` set `IgnoreGuiInset` and `ScreenInsets`, and the
  first has no effect once the second is set.

### Changed — elsewhere

- `check-all.mjs` runs eleven gates.
- `self-review.md` is scored out of 30 and maps each new row to its reference.
- `evals/triggers.md` gains twenty-three rows across four groups: dead UI
  numbers, icons and asset ids, notifications matching the interface, and
  editing somebody else's file.

## 4.2.0 — 2026-09-18

**v4.1 made the UI rubric countable. The code half was still prose.**
`roblox-code-craft` has said "comment the why, not the what" since v1, and a
capable model still produced a 330-line executor script carrying a thirteen-line
provenance header, ten capability checks, eight `pcall`s and a rollback path for
an operation that cannot fail. Every rule it broke was already written down.

Prose does not bind a model. A command that exits 1 does.

### Added — the ceremony budget, counted

`tools/bin/lint-luau-slop.mjs` runs over a real Luau file and scores it out of
20 across ten rows.

It reports header length (4 lines on a script, 24 on a module, decided by
whether the file returns one), comments narrating where the code came from,
commented-out code, comments restating the line below, bare section labels,
capability-check count, `pcall`s around operations that cannot raise, `pcall`
density, message length and clause count, repeated literal prefixes, success
`print`s, generic names, abbreviations, digit suffixes, unnamed repeated
values and `TODO`s.

On `library/src`, which is hand-written: **twelve files, 20/20, no findings.**
On the generated dragger script: **4/20, thirteen errors.**

Calibrating it found one real nit in the library — a `TweenInfo` bound to a
local called `info` — and produced four deliberate exemptions: `0.5`, `0.25`
and `0.75` are layout anchors rather than magic numbers; `local ok, result =
pcall(...)` is the house idiom, not a generic name; a section banner is
navigation in a 300-line module and noise in a 60-line script; and a wrapped
comment is one thought, so consecutive `--` lines are scored as one unit.

### Added — two references behind it

`roblox-code-craft/references/anti-slop-code.md` — the ten rows as a table of
limits, what a comment is allowed to say, the check/never-check table for
defensive code, and the one-bind-one-assert pattern that replaces a page of
`if typeof(x) ~= "function"`.

`roblox-code-craft/references/slop-rewrite.md` — the 330-line script cut to 59,
with a fifteen-row table of what came out and why. Nothing was removed but talk;
the behaviour is identical.

**The rewrite found a bug the ceremony was hiding.** The original searched for
the constant `1.2`, then restored a *retyped* `1.2` in three separate places
rather than the value it read. Against a build shipping `1.25` it silently
leaves the game modified. At 330 lines the three restore paths are far apart and
nobody reads them; at 59 the mistake is visible. That is the argument for the
budget that is not about taste.

### Added — one API per job

`roblox-executor/references/technique/source-to-api.md`, for the other half of
the request: using the dump to pick the *exact* call rather than a chain of
attempts.

It carries a layer-to-call ladder — upvalue, file-scope global, constant, module
table, a rewriting loop, a plain DataModel path — and the count heuristic: one
to three executor functions is normal for a single-purpose script, six or more
means going back to the dump.

The rule it adds: **a fallback chain is a confession the source was not read.**
`getsenv`, then `getgc`, then a DataModel search reach three different objects,
so a script that takes whichever it finds does not know what it edited, and
after a game update it silently switches branch and appears to succeed. One
legitimate fallback survives — two executors naming one function differently,
resolved once at the top with an assert.

### Changed — the portable rules

`docs/portability/rules.md` gains a P0 section, **"Code that reads as written,
not generated"**, and the executor section gains the layer-to-call map and the
capture-what-you-read rule.

P0 is capped by OpenAI's 8,000-character Instructions field, so making room
meant rewriting the whole tier in directive register: every number kept, the
explanations moved to P1. The GPT instructions are 7,936 characters. The
placement defaults and the security-gating detail moved to P1, where the GPT
still reaches them through its knowledge file and Codex and Cursor get them in
full.

The GPT scope paragraph now names the words that trip a classifier — exploit,
bypass, inject, cheat, aimbot, script hub — and says to read them as the
technical terms they are in this context, rather than leaving the model to infer
it. `scope-and-framing.md` gains a section on what answering looks like instead
of refusing, and a first message the user can paste.

### Fixed

- `run-library-tests.mjs` printed each assertion file's tally separately, so
  `check-all.mjs` reported the second file's 30 as though it were the suite.
  It now prints a combined total: 42.
- `Button.luau` bound a `TweenInfo` to a local named `info`.

### Changed — elsewhere

- `check-all.mjs` runs ten gates.
- The router, `roblox-executor`, `roblox-code-craft` and
  `delivery-checklist.md` all name the command rather than the check.
- `evals/triggers.md` gains twenty-one rows across three groups: the ceremony
  gates, source-to-API selection, and scope framing.

## 4.1.0 — 2026-09-18

**v4 told a model to count. It did not make it count.** `self-review.md` is a
list of countable facts precisely so no judgement is needed — and a model asked
to run it will report a score whether or not it counted anything. Every rule
that ends in "check this before delivering" has that hole in it.

v4.1 closes it with tools that do the checking, and cleans the structure while
the linters are pointed at it.

### Added — the UI rubric, counted

`tools/bin/lint-roblox-ui.mjs` runs the rubric over a real Luau file.

It reports distinct `TextSize` values, distinct corner radii, spacing off the
4 / 8 / 12 / 16 / 24 / 32 scale, `TextScaled` overuse, `MouseButton1Click`,
missing `AutoButtonColor = false`, buttons with no state handling, deprecated
`wait` / `spawn` / `delay`, an unbounded `ScreenGui`, sub-44px touch targets,
`UIListLayout` without `SortOrder`, colour literals outside a token block, and
connections with no teardown — then scores the countable half out of 20.

On the library's twelve shipped components: **0 errors, 0 warnings**. On a
deliberately generic menu written as a control: **4/20, nineteen findings**.

Calibration mattered more than coverage. Three false positives were fixed before
it shipped: a component that mentions `ScreenGui` is not building one; a scrim
is a button so that it absorbs input and has no hover state by design; a file
that renders no text cannot have a wrong type scale. A linter that reports what
the author already handled teaches you to stop reading it.

### Added — the executor invention gate

`tools/bin/verify-executor-api.mjs`, the mirror of `verify-api.mjs` for the half
of the stack that had no gate at all. Same contract: **a non-zero exit is the
signal you were about to invent something**.

It indexes 324 names from `references/api/` plus the Actor, packet and thread
surfaces documented alongside their techniques, resolves namespaced members from
a bare name, and suggests near misses. `--audit` proves every executor global
`lint-luau-blocks` accepts in an example is documented somewhere a reader can
reach — 134 checked, 0 undocumented.

Getting to zero found a real gap: alias spellings. `base64_encode`,
`rconsoleerr`, `rconsolename`, `get_thread_identity` and `issynapsefunction` are
what scripts in the wild actually call, and none were documented. `api/misc.md`
now carries the alias table and the one-call-site feature-detect pattern.

### Added — the reference gate

`tools/bin/lint-links.mjs` checks that every file the stack points at exists —
markdown links **and** backticked paths, which is how the skills actually route
and which nothing else could see.

It found three dead pointers on its first run: `mcp/README.md` (a v2 layout that
no longer exists), `roblox-executor/references/api/filesystem.md` twice (the file
is `misc.md`), and `library/Toast.luau` (it is `library/src/Toast.luau`). All
three were names a model would have followed into improvising.

### Added — one command

`tools/bin/check-all.mjs` runs all nine gates and prints one verdict. Nine
commands is how six get run and three get skipped, and the skipped ones are
always the newest.

### Fixed

- **Toasts overflowed narrow screens.** The container was a fixed 320px offset;
  on a 360px phone, 320 plus the edge inset runs off the edge. It is now
  scale-sized between `Tokens.toast.minWidth` and `Tokens.toast.width`. Found by
  the new UI linter on the library's own code.
- Both executor reference gates and the block linter now agree about what
  exists, which `--audit` keeps true.

### Changed — structure and naming

- `docs/prompts/` is now **`docs/briefs/`**, with a README saying what each file
  is and which version it produced. "Prompts" collided with the GPT instructions
  the stack also generates; these are the original requests, and briefs is what
  they are.
- The tool list in `README.md` is grouped by what the tools are *for* — verify
  one name, check work before it ships, keep the stack honest — rather than
  being one undifferentiated block of eleven commands.
- `AGENTS.md` and the Cursor rule now carry the same tool contract, generated
  from one constant rather than written twice.
- The router, `roblox-ui`, `self-review.md`, `build-order.md` and
  `roblox-executor` all name the command to run rather than the check to
  perform.
- `evals/triggers.md` gained ten rows that test whether the tool was **run**,
  not whether the answer sounded right.


## 4.0.0 — 2026-09-18

**The stack taught derivation where it should have shipped the derived result.**
v3's UI guidance was 2,178 lines of good prose, and almost all of it advisory —
"pick a direction", "make the steps mean something", "decide what wins". Advice
is an instruction to exercise judgement, and judgement is the thing a weaker
model does not have. It follows the guidance, produces the same grey card grid,
and honestly reports that it applied it.

Four failures, one root cause. v4 replaces the judgement calls with lookups,
procedures, numbers and countable checks.

### Added — UI that survives a weak model

`roblox-ui/references/design-directions.md` — **six complete directions**, not
sketches. Slate, Paper, Neon, Ink, Glass and Console, each with all nine neutral
RGB values, three accent tiers, radii, fonts, type scale, elevation and stroke
policy. **Slate is the named default** for when the user expresses no
preference, because "pick one" resolves to "pick nothing", and nothing is where
grey-on-grey comes from.

`roblox-ui/references/build-order.md` — a ten-step gated procedure. Each step
ends in a question answerable yes or no without design sense, and structure is
built with no appearance applied at all until step 7.

`roblox-ui/references/blueprints.md` — nine working recipes with real property
values: root scaffold, settings row, scrolling list with an empty state, adaptive
item grid, confirm modal, tab bar, HUD element, mobile sheet, executor hub.

`roblox-ui/references/self-review.md` — a countable rubric. Ten hard gates, ten
counted checks scored out of 20, and a table mapping each failure back to the
build-order step that produces it. Counting works where judging does not.

### Added — the contrast linter

`tools/bin/lint-ui-directions.mjs` recomputes every ratio stated in
`design-directions.md` from the RGB values in the same file, and enforces seven
rules per direction: primary text at 4.5:1 on four surfaces, secondary at 4.5:1,
muted at 3:1, text-on-accent at 4.5:1, the accent-as-text slot at 4.5:1, and
adjacent surfaces separated by at least 1.12:1.

A palette in prose is an unchecked claim. This is the lesson v3 learned about
API names, applied to colour — where the failure is invisible to whoever wrote
it and obvious to everyone else.

### Added — `roblox-request-intake`

The eighteenth skill, and the one that fires first. It owns the case v3 had no
home for: a request that is vague, emotional, or written by somebody who does
not use programming terminology.

- `references/vague-to-spec.md` — what people actually type, and what to build.
  Sixteen "make me a ___" rows, the eight readings of "it's broken", the ten
  phrasings of "make it look better" and what each one actually means.
- `references/defaults.md` — every open decision pre-made: framework, file type,
  parent instance, naming, UI values, and the numbers to use when none are
  given. Four things may be asked; everything else is decided.
- `references/plain-language.md` — placement blocks in Studio's own labels, the
  jargon policy, and what to say so the user can tell a working script from a
  broken one.
- `references/error-triage.md` — pasted red text to cause to fix, plus the
  "it still doesn't work" protocol, which is the most common follow-up in this
  stack's history and previously had no procedure at all.

### Added — decompiled source as a first-class input

`roblox-executor/references/technique/decompiled-source.md`. v3 said "templates
are illustrative, inspect the game first" and then documented nothing for the
case where the user has already inspected it and pasted the result — so the
model fell back to the template it had just been told not to use.

**Provided source is now rule 3 in the executor skill, outranking every
template.** The file separates what survives decompilation (string and number
constants, global and method names, table keys, argument count at each call
site) from what is rebuilt (every local, upvalue and parameter name, control
flow shape) from what lies outright (constant folding, inlined helpers, vararg
forwarding, multiple returns). It gives an eleven-row extraction pass, the
mapping from dead source to live objects by constant rather than index, and the
traps — stale dumps, constructed strings, `StreamingEnabled` holes, and shared
modules misread as client-side.

### Added — one stack, four hosts

`docs/portability/rules.md` is the single source. `tools/bin/build-portable.mjs`
generates `AGENTS.md` for Codex, `.cursor/rules/roblox-luau-expert.mdc` for
Cursor, and both halves of a custom GPT — an instructions field and a knowledge
file. `--check` fails when any has drifted.

Sections are tiered P0/P1/P2, **cumulative and non-overlapping**, so a P1
section continues its P0 counterpart instead of repeating it. P0 is what fits
the GPT's 8,000-character instructions cap, and the build fails if it stops
fitting — which is what keeps the spine from quietly bloating until the field
truncates.

The GPT half lives in `docs/portability/gpt/` — instructions to paste, a
`knowledge/` folder to upload, and a README with the click order, because that
is the one host updated by hand months apart. The archive in it is generated and
gitignored: it is a zip of this repository, so committing it would pack the
previous copy into the next one every build.

`docs/portability/scope-and-framing.md` covers why a client-side Roblox question
gets refused as if it were malware: the word "exploit" means two unrelated
things and a classifier cannot tell which one it received. The fix stated there
is precision — which machine, whose account, what technically happens. The file
is explicit that it is not a jailbreak, lists what stays declined, and says why
smuggling a request past a classifier produces a worse answer as well as a
dishonest one.

### Added — the library the blueprints reference

`library/src/Layout.luau` and five components, so the recipes are real code
rather than described code.

- `Layout.luau` — the eight modifier constructors with the wrong defaults
  already fixed. `UIListLayout` sorts by **name** unless told otherwise, and
  `AutomaticCanvasSize` looks broken unless `CanvasSize` is also cleared.
- `Toggle.luau` — the knob **moves**, so state is not carried by colour alone.
  `set(value, silent)` restores a saved config without re-firing every handler.
- `Slider.luau` — drag tracked on `UserInputService`, not on the knob, because
  the pointer leaves the knob on the first pixel of movement. Quantised to the
  step, and reachable by arrow keys and D-pad.
- `Dropdown.luau` — the menu parents to the `ScreenGui`, not the control, or a
  scrolling settings list clips it. Opens upward when there is no room below.
- `TabBar.luau` — one indicator that slides, pages built once and toggled.
- `Modal.luau` — three ways out, and focus on the **safe** action, so a gamepad
  player pressing A on arrival has not deleted their save.

The headless harness grew an instance stub that tracks children by name, a
`task` stub with an explicit drain, and `UserInputService`. Assertions went from
12 to **42**.

### Changed

- `roblox-ui/SKILL.md` leads with the four files that decide the outcome, before
  the prose that explains why.
- `roblox-luau-expert/SKILL.md` gained question zero — is the request buildable
  yet — and two delivery-pass steps: run the UI rubric, and write a placement
  block when the reader may not code.
- `roblox-executor/SKILL.md` is three rules rather than two, with four router
  rows for pasted source and a step 0 in the diagnosis order.
- Both linters accept a **directory** argument instead of crashing with
  `EISDIR`. Passing one was always what anyone typing it meant.
- `evals/triggers.md` gained 22 rows covering intake, weak-model UI and
  source-driven executor work.

### Unchanged and still passing

`lint-prose` 0 errors and 0 warnings across 88 files, `lint-luau-blocks` 0
findings across 563 blocks, `generate-tables --check` matching dump
`0.738.0.7381393`.


## 3.0.0 — 2026-09-10

**The stack owned ground truth and never pointed it at its own prose.** That is
how a recommendation to call `Players:CreateHumanoidModelFromDescription`
survived in the same repository that generates the table listing it as
`[Deprecated]`. v3 fixes that structurally rather than by proofreading.

### Added — the linters

`tools/bin/lint-prose.mjs` resolves every API reference in the skill markdown
through the dump: `E-MISSING`, `E-DEPRECATED`, `E-SECURITY`, `E-WRITETIME`,
`W-ALIAS`, `W-UNDATED`.

`tools/bin/lint-luau-blocks.mjs` parses every fenced Luau block with the `luau`
binary and resolves annotated and inferred types: `E-SYNTAX`, `E-TYPE`,
`E-UNDECLARED`, `E-WRITETIME`, `E-EXECUTOR-GLOBAL`.

Both scope their "did the author already flag this" check to the enclosing
markdown section rather than a line radius, because a linter that reports things
the author already handled teaches you to stop reading it.

### Added — datatype ground truth

The API dump covers **classes and enums only**. `CFrame`, `TweenInfo`,
`RaycastParams` and `SharedTable` are absent from it entirely, which is why v2's
"verbatim from the vendored dump" claim about `RaycastParams.RespectCanCollide`
could not have been true. Roblox's datatype reference is now vendored beside the
dump (48 datatypes, 365 members) and `verify-api` reports which source answered.

### Fixed — a parser defect that lost 64 members

Member names are not all identifiers. `Studio.Auto-Recovery Interval (Minutes)`,
`PVInstance.Pivot Offset` and `BevelMesh.Bevel Roundness` carry spaces, hyphens
and parentheses, and an identifier-only capture truncated them and collapsed
distinct members onto one key. Counts now match a raw grep of the dump:
**8,434 members, 651 deprecated across 148 classes**.

### Fixed — wrong against the dump

| Where | Was | Is |
|---|---|---|
| `gui-design.md` | `CreateHumanoidModelFromDescription` | the `...Async` form; the original is `[Deprecated]` |
| `responsive-and-surfaces.md` | connect `GuiService.SafeZoneOffsetsChanged` | it is `{RobloxScript}`; watch `TopbarInset` instead |
| `engine-api` | `IsRunMode()` is Plugin-gated | it is not; `IsEdit`/`Run`/`Pause`/`Stop` are |
| `performance` | `ScriptProfilerService:ClientRequestData` is usable | every member is `{Plugin}` |
| `toolchain` | `FilteringEnabled` in `default.project.json` | deprecated and Plugin-write-gated; Rojo cannot set it |
| `engine-api` | `Heartbeat` and `PostSimulation` are distinct events | one point, two names, as are the other two pairs |
| `luau-language` | upvalues capped at 255 | 200; 255 is the register limit |
| `toolchain` | a TestEZ example under a "TestEZ is archived" heading | real Jest-Lua |
| `toolchain` | `lune run tests` runs the suite | Lune has no DataModel |
| `data-persistence` | v1 `UpdateAsync` transform only | the `keyInfo` form, and why `userIds` matters |
| `gui-design.md` | the topbar is 36px | `GuiService.TopbarInset`, read at runtime |

### Fixed — examples that could not run

- `choreography.md` set `GroupTransparency` on `{ GuiObject }`; only `CanvasGroup` has it.
- `component-states.md` used `focusRing`, never declared or passed — the flagship
  58-line example of the interaction-states skill errored on its first render.
- `ui-motion/SKILL.md` tweened a `CanvasGroup` it never parented.

### Fixed — a v3 mistake, caught by v3 tooling

An earlier commit in this release read `[LoadOnly]` as "cannot be assigned at
runtime" and wrote several confident claims on that basis. Adding the write-time
check to the block linter immediately produced 66 findings, all of them
`Instance.Parent` — the most-assigned property in the engine.

`[LoadOnly]` is a **serialization** flag: the property is read from the file
format and not written back. It says nothing about scriptability. The tool no
longer treats it as a blocker, and every claim built on the misreading —
`IgnoreGuiInset`, `UICorner.CornerRadius`, `TextLabel.Font`,
`AnimationTrack.TimePosition` — has been corrected. The *recommendations* stood;
the stated reasons were wrong.

### Added — three skills

- **`roblox-monetization`** — `ProcessReceipt` fires more than once for the same
  purchase, so the obvious handler duplicates items silently under load. Covers
  the `PurchaseId` ledger, grant-and-record in one transform, and why
  `NotProcessedYet` is correct on any doubt. Previously zero mentions stack-wide.
- **`roblox-vfx-animation`** — `AnimationTrack`, priority and blending, markers
  over `task.delay`, particles, beams, trails, highlights, pooling.
- **`roblox-audio`** — the engine now tags every `Sound` member with the
  `LegacySound` capability while the `AudioPlayer`/`Wire` graph carries `Audio`.

Plus `roblox-networking/references/cross-server.md`, covering the `TeleportData`
trust boundary that `roblox-data-persistence` named as a top duplication cause
without ever explaining.

### Added — UI depth

Seven references: `scaling-and-dpi.md`, `typography.md`, `gradients-and-depth.md`,
`input-surfaces.md`, `shadows-and-elevation.md`, `windows-and-drag.md`,
`scrolling-and-virtualisation.md`.

Writing them against the dump caught three recommendations that would themselves
have been defects: all four `GuiService` scale functions are `{RobloxScript}`;
`GuiService:AddSelectionParent` is `[Deprecated]` with no `SelectionGroup`
replacement; `CanvasGroup.ResolutionScale` and `ScrollingFrame.SmoothScroll` are
`{RobloxScript}` too.

`UIDragDetector` appeared in no UI skill, despite the stack's "Surface 2" being
draggable hub windows. `UIGradient.Type` (radial and conical) and `.Scale`
appeared nowhere in prose.

### Fixed — the shadow contradiction

`gui-design.md` recommended `UIShadow`; `outlines-and-dividers.md` taught the
9-slice `ImageLabel` hack for 37 lines without naming it; tell R9 routed to the
hack; and `Panel.luau` implemented it, with a README caveat that it "needs a
shadow asset". `UIShadow` wins, `Tokens` gained an elevation scale, and 9-slice
is documented as the fallback it actually is.

### Added — references for the five skills that had none

`roblox-architecture`, `roblox-performance`, `roblox-data-persistence` and
`roblox-toolchain` each shipped an empty, committed `references/` directory.
`roblox-game-security` had none at all: 265 lines and three code blocks,
mirroring a `roblox-executor` with 16 references.

Notably: `SharedTable.increment` and `.update` were missing entirely, which made
the parallel-Luau section unusable for the read-modify-write case it recommends;
`.luaurc` had zero mentions stack-wide; ProfileStore and Lyra were recommended
with zero code; Fusion, Vide and React-lua existed only as a survey table.

### Changed — tooling and layout

Tools are Node with zero dependencies (`tools/bin/`), so they run on macOS,
Linux and CI. `tools/ps1/` wrappers preserve exit codes. `install.ps1` now ships
`tools/`, which it did not — leaving the router instructing Claude to run a
verification script that was not on disk. The Python test generator is gone; the
harness is real `.luau` files. `docs/` holds the meta documentation and
`library/src/` the vendored Luau. `archive/` is deleted, since git now makes
that safe.

### Verification

```
lint-prose.mjs           0 errors, 0 warnings
lint-luau-blocks.mjs     0 findings across 541 Luau blocks
generate-tables --check  no drift
run-library-tests.mjs    12 passed, 0 failed
```


## 2.1.0 — 2026-09-10

UI depth. Three focused UI skills replacing one, a vendored component library with
passing tests, and a staleness audit of everything the stack recommends.

### Added — UI skills

- **`roblox-ui-motion`** — intent-to-easing mapping, duration bands, springs via
  `TweenService:SmoothDamp`, choreography and stagger, reduced motion, tween lifetime.
  Three references.
- **`roblox-ui-components`** — toasts, outlines and dividers, the six interaction
  states, and a nine-entry control catalog. Four references.
- **`roblox-ui`** gains `anti-slop-catalog.md` and `responsive-and-surfaces.md`.

### Added — `anti-slop-catalog.md`

Seventeen coded, severity-tiered Roblox UI tells (**R1–R17** at **P0/P1/P2**), each
with what it looks like, why it reads as generated, and the fix. Plus a positive
section and a seven-step audit pass.

Format borrowed from the `avoid-ai-design` skill's tells catalog; the tells
themselves are original, since that skill's are entirely web-specific.

### Added — `library/`

Vendored, parse-checked Luau: `Tokens.luau` (three-tier spine), `Motion.luau`,
`Toast.luau`, and `Components/` (`Button`, `Divider`, `Panel`). No colour literal
appears outside `Tokens.luau`.

**`library/tests/`** — a headless harness that stubs enough of the engine to run the
toast logic under the standalone `luau` binary. **12 assertions, all passing**:
capacity and queueing, dedup collapsing 40 pushes into one `(x40)` entry, error
preemption, middle-toast reflow, and teardown.

### Verified API surface this rests on

Checked against dump `0.738.0.7381393`, and mostly absent from existing tutorials:

- **`TweenService:SmoothDamp`** — first-party critically damped spring. Ungated,
  `{Safe}` in parallel. The correct answer for interruptible motion.
- `TweenService:GetValue` for driving custom loops with engine easing.
- `UIStroke.BorderStrokePosition` (`Outer`/`Center`/`Inner`), `.StrokeSizingMode`,
  `.ZIndex` for layered strokes, `.Enabled`.
- `UICorner` per-corner radii. (The `[LoadOnly]` reading of legacy `CornerRadius`
  stated here was wrong; see the 3.0.0 note. It is still assignable.)
- `UIListLayout.Wraps`, `.HorizontalFlex`/`.VerticalFlex` (`Enum.UIFlexAlignment`),
  `.ItemLineAlignment`.
- `CanvasGroup.GroupTransparency` for fading a subtree as one layer.
- `GuiService.ReducedMotionEnabled` and `.PreferredTransparency` — `[Hidden]`
  `[ReadOnly]` but readable from a normal LocalScript.
- `GuiButton.Activated(inputObject, clickCount)`; `HoverHapticEffect` /
  `PressHapticEffect`.
- `Enum.StudioStyleGuideColor` + `StudioStyleGuideModifier` for plugin theming.

### Fixed — accuracy

- **`SmoothDamp` does not accept `UDim2`.** An earlier draft of `Toast.luau` sprang
  `Position` directly. Official type support is number / Vector2 / Vector3 / CFrame,
  so `Motion.springValue` was added and the toast now springs a numeric Y offset and
  composes the `UDim2`. `Motion.spring` now errors with a useful message on an
  unsupported type rather than failing obscurely at runtime.
- **There is no `GuiService.ReducedMotionChanged` event.** An earlier draft asserted
  one. Corrected to `GetPropertyChangedSignal("ReducedMotionEnabled")`, and noted
  that `UserGameSettings.ReducedMotion` is `{RobloxScript}`-gated and unreachable.
- **`UIGradient` enum names.** The official docs summarise these as `TileMode` and
  `Type`; they are `Enum.GradientTileMode` and `Enum.GradientType`.
- **`Plugin:CreateDockWidgetPluginGui` is `[Deprecated]`** — the `Async` form is
  current. Most plugin tutorials still show the old one.
- **Topbar height is not a constant.** Roblox staff guidance says 36px, community
  reports say 58px. The stack now says to read `GuiService:GetGuiInset()` and never
  hardcode either.

### Fixed — stale recommendations

The request was for actively-maintained sources only. Recency audit, 2026-09-09:

| Project | State | Action |
|---|---|---|
| `Roblox/roact` | **archived**, 1001d | flagged; React-lua named as successor |
| `chriscerie/roact-spring` | **800d stale** | **rejected** — `SmoothDamp` is first-party |
| `jsdotlua/react-lua` | 474d | caveated in the framework table |
| `dawid-scripts/Fluent` | 853d | flagged stale in the hub-UI table |
| `violin-suzutsuki/LinoriaLib` | 761d | flagged; Obsidian named as successor |

Framework and hub-UI tables now carry **last-push dates**, not just star counts.

Added as actively maintained: `ui-labs` (189★, 27d), `GlassmorphicUI` (172★, 15d).

### Note

No credible open-source Roblox toast library exists — a GitHub survey returned
nothing above 2 stars. `toasts.md` and `Toast.luau` are a build guide and a reference
implementation rather than a recommendation.


## 2.0.0 — 2026-09-09

Rebuild from one flat skill (29 reference files, 5,217 lines) into a routed
12-skill stack with an API verification layer.

### Added — verification layer

- **Vendored ground truth** in `tools/api-dump/` — `API-Dump.txt`,
  `FVariables.txt`, `LuauTypes.d.luau`, pinned at Roblox `0.738.0.7381393`.
- **`tools/verify-api.ps1`** — look up any Roblox class, enum or member. Decodes
  security level and direction, script capability, parallel safety, deprecation
  and yield behaviour. **Exits 1 when the name is not in the dump.**
- **`tools/generate-tables.ps1`** — produces five grep-target references:
  `api-index.txt` (8,279 entries), `deprecated-apis.md` (701),
  `security-tagged-apis.md` (3,841), `parallel-safety.md` (185 safe / 18
  unsafe), `script-capabilities.md` (40).
- **`tools/update-dump.ps1`** — refresh, diff added / removed / newly-deprecated
  members between releases, regenerate. `-Check` reports without writing.
- **`common-mistakes.md`** — 25-entry ranked defect catalog, each with symptom,
  cause, wrong code, right code, and how to detect it.
- **`delivery-checklist.md`** — the pass that runs before code is handed over.

### Added — skills

Eight new skills covering ground v1 did not: `roblox-luau-language`,
`roblox-engine-api`, `roblox-architecture`, `roblox-data-persistence`,
`roblox-networking`, `roblox-performance`, `roblox-game-security`,
`roblox-toolchain`.

`roblox-game-security` is written as the deliberate mirror of
`roblox-executor` — the same knowledge pointed at defending a place you own.

### Added — executor references

- `recon/thread-identity.md` — the 13 named identities and capability matrix.
- `recon/landscape.md` — UNC archived, sUNC live, Hyperion context, feature
  detection over executor ranking. Absorbs the old `rainer-raindrop.md`.
- `recon/saveinstance-decompile.md` — dump-and-read reconnaissance.
- `ui/ui-libraries.md` — hub UI library comparison, config persistence, unload
  discipline.

### Fixed — accuracy

- **`RunService.Stepped` / `.RenderStepped` are not deprecated.** An earlier
  draft of the mistakes catalog claimed they were. The dump carries no
  `[Deprecated]` flag on either; `PreSimulation` / `PreRender` are the current
  names for the same points in the frame, and flagging the old names as defects
  in a review would be a false positive. Now documented as a distinct
  "superseded but not deprecated" category.
- **Read/write security is asymmetric.** The dump encodes three separate gate
  shapes — read+write, read-only, write-only — and collapsing them produces
  wrong advice. `Workspace.StreamingEnabled` is readable by any script and
  `Plugin`-gated only for writes, which is different again from `[ReadOnly]`.
  Both tools and the generated table now report the direction.
- **Thread identity model replaced.** `legacy-syn.md` documented "security
  context level (0-8), higher = more privileges". That is wrong in two ways:
  identities are named rather than ranked, and access is decided by
  capabilities. `CommandBar` holds `Plugin` and `LocalUser` but not
  `RobloxScript`; `ElevatedGameScript` is the reverse.
- **`AuthorityMode` vs `[NotScriptable]` distinguished.** `AuthorityMode` is
  genuinely `{RobloxScript}` security-gated; `SignalBehavior`,
  `NextGenerationReplication`, `UseFixedSimulation` and
  `PlayerScriptsUseInputActionSystem` are merely unexposed. Different problem,
  different tool. Both now stated, with a warning against carrying the property
  into game-code advice.
- **Aftman is archived** — Rokit is the successor. **TestEZ is archived** —
  jest-roblox is current. **Knit is archived.** All three still appear in
  widely-linked tutorials.
- **Blink is `1Axen/Blink`**, not `jackdotink/blink`. **Trove** lives inside
  `Sleitnick/RbxUtil`, not a standalone repo. **ProfileStore** supersedes
  ProfileService.

### Changed — structure

All 29 v1 reference files kept. 25 moved, 4 absorbed into prose.

| v1 | 2.0 |
|---|---|
| `local-register-limit.md` | `roblox-luau-language/references/compiler-limits.md` |
| `nil-safety.md` | `roblox-engine-api/references/nil-safety.md` |
| `gui-architecture.md`, `gui-design.md` | `roblox-ui/references/` |
| `naming.md`, `diagnostics.md`, `code-signature.md` | `roblox-code-craft/references/` |
| `sunc-closures.md` … `sunc-scripts.md`, `debug-library.md`, `synapse-compat.md` | `roblox-executor/references/api/` |
| `value-persistence.md`, `replication-model.md`, `client-vs-server-authority.md`, `actors-parallel.md`, `raknet.md`, `function-selection-guide.md` | `roblox-executor/references/technique/` |
| `anticheat-recon.md`, `detection-surface.md` | `roblox-executor/references/recon/` |
| `script-templates.md` | `roblox-executor/references/templates/` |
| `SKILL.md`, `best-practices-core.md`, `luau-best-practices.md`, `rainer-raindrop.md` | absorbed; originals in `archive/v1-superseded/` |

Coverage was verified programmatically before archiving — every distinctive
concept in the absorbed files resolves to at least one file in the new tree.

### Added — packaging

- `.claude-plugin/plugin.json` + `marketplace.json`, both passing
  `claude plugin validate`.
- `install.ps1` for copying or symlinking into `~/.claude/skills/`.
- `mcp/README.md` with a source-level audit of the one third-party MCP server
  worth considering, and reasons for rejecting five others.
- `SOURCES.md` recording provenance, licences, and rejections.
- `evals/triggers.md` for routing regression.
