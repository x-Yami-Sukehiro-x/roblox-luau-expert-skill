---
name: roblox-hub-library
description: Script hub UI libraries like WindUI or Rayfield - windows, tabs, elements, themes, configs, mobile - from HubKit. Use for any hub UI.
---

# Building a script hub UI library

A hub library is the part of a script hub the player touches: the window,
the tabs, every toggle and slider, the notifications, the saved settings.
Players judge a hub by it before any feature runs. This skill is for three
jobs, in this order of frequency:

1. **Build a hub UI** for someone's features: use a library, usually HubKit.
2. **Improve an existing hub** (theirs, or one built on WindUI, Rayfield,
   Obsidian or Linoria): audit it, rank what is wrong, fix the smallest thing
   that matters most.
3. **Build a library** from scratch, or extend one with a new element.

The worked example for all three is **HubKit** in `library/hub-kit/` at the
plugin root: 33 ModuleScripts in folders, a one-file bundle, an example hub
that uses every element, and 107 headless behaviour assertions. Read its
`README.md` first; it is the contract this skill refers to.

## Decide what you are building

| The request | The answer |
|---|---|
| "Make a hub for these features" | HubKit, bundled, with the user's features wired to elements. Paste `library/hub-kit/example/Example.luau` as the shape |
| "Use WindUI / Rayfield / Obsidian" | That library. Its API, not HubKit's; `roblox-executor/references/ui/ui-libraries.md` has status and loading |
| "Improve my hub", a pasted hub script | [improve-existing-hub.md](references/improve-existing-hub.md), then fix in place |
| "Make my own UI library", "like WindUI" | HubKit's folder layout and [architecture.md](references/architecture.md), adapted to their name and style |
| "Add a colour picker to my library" | [element-contract.md](references/element-contract.md), "Adding an element" |
| Two or three toggles | No library. A ScreenGui with three rows is fifty lines |

Never port a working hub to a different library for looks. Fix the look in
the library it uses.

## The architecture, in one screen

```
init            HubKit:CreateWindow, :Notify, :SetTheme, :Unload
Core/           New, Theme, Trove, Signal, Motion, Drag, Config, Mount, Icons
Themes/         palettes by role; every text role 4.5:1 on its surfaces
Components/     Window, Tab, Section, Popup, Dialog, Notifications, OpenButton, SettingsTab
Elements/       init (the registry), Row (shared layout and states), one file per element
```

Four decisions make it a library rather than a script:

- **A registry, not methods written per container.** `library/hub-kit/src/Elements/init.luau`
  gives every Tab and Section `:Toggle`, `:Slider` and the rest from one
  table, and does what every element needs once: register the `Flag`, make
  the row searchable, undo both on destroy.
- **One Row for every element.** Title, description, control slot, 44 px
  minimum height and five of the six states live in `Row.luau`, so a new
  element cannot forget the focus ring or the disabled look.
- **Colours are roles, not values.** `New("Frame", { Theme = {
  BackgroundColor3 = "surface" } })` binds the property to a role, so a
  theme switch recolours what is already on screen.
- **Everything is owned by a Trove.** A window's trove holds every
  connection, instance and popup it made; `Unload` is one `clean()`, and the
  test suite proves it by counting input connections back to zero.

## What every hub gets right

Ranked by how often a hub fails on it. Each links to where HubKit does it.

1. **Input on every device.** `Activated`, never `MouseButton1Click`; 44 px
   rows; a draggable **Open** chip when the window is hidden, because a phone
   has no RightShift; D-pad steps a selected slider through
   `ContextActionService`; the menu key ignores typing (`gameProcessed`).
   `roblox-ui-interaction` has the full contract.
2. **Fits every screen.** Size by scale, `UISizeConstraint` from 300 x 240 to
   760 x 540, and a compact mode below 520 px that folds the sidebar to icons.
   Popups live in their own ScreenGui and are clamped on screen.
   `roblox-ui-viewport` has the numbers.
3. **Unload and rerun.** One unload path, an `OnUnload` signal for the hub's
   own features, and a `getgenv()` handle so running the script twice replaces
   the first hub instead of stacking two.
4. **Honest configs.** Feature-detect `writefile` and friends once; without
   them, say saving is off. `Set` runs the Callback, so loading a config starts
   the saved features.
5. **Nothing hover-only.** Descriptions are a second line under the title, not
   a tooltip a touch screen never shows.
6. **The window never passes clicks to the game.** The root frame is
   `Active`; otherwise a press on the hub fires the game's click handlers,
   and a click-teleport feature teleports the player.
7. **No per-frame work.** Drag and sliders follow input events. A hub that
   runs `RenderStepped` for its UI costs frame time in every game it runs in.
8. **Protected parent with a Studio fallback.** `gethui()` when present,
   `PlayerGui` otherwise, so the same file is testable in Studio.

## What makes a hub look generated

The hub-specific tells, and what replaces each, are in
[hub-anti-slop.md](references/hub-anti-slop.md). The short list: a fake
loading screen with a progress bar that measures nothing, rainbow or animated
gradient borders, emoji or font glyphs as icons, a different accent colour
per tab, 10 px text, a "Made by" watermark over content, a notification on
every toggle, and a key system that gates nothing.

## Building a library from scratch

Order matters; each step is testable before the next exists.

1. `Core/` first: Signal, Trove, Theme, New, Motion. No UI yet.
2. One palette with every role, and a contrast check for each text pair.
3. `Row` and one element (Toggle), with a test that activates it.
4. The registry, then the other elements one at a time, each with tests.
5. Window, Tab, Section; then Popup, Dialog, Notifications, OpenButton.
6. The bundler, the example, and the README with the element table.

Run after every step: `node tools/bin/lint-roblox-ui.mjs`,
`node tools/bin/lint-luau-slop.mjs` and `node tools/bin/lint-luau-format.mjs`
on the folder, then the behaviour tests.

## Delivering a hub library

A library is folders, and folders do not paste into a chat. Deliver:

- the **folder tree** with every file, each in its own code block under its
  path, as in the Elements folder of `library/hub-kit/src`;
- the **bundle**, one file, for executors (`node tools/bin/build-hub-kit.mjs`
  for HubKit; for their own library, the same resolver or darklua, see
  [architecture.md](references/architecture.md));
- the **example** that uses every element, and how to run it in an executor
  and in Studio;
- what was checked and what was not. The stubs prove callbacks and state;
  only Roblox proves pixels.

## Checks

```bash
node tools/bin/build-hub-kit.mjs --check
node --test tools/tests/hub-kit.test.mjs
node tools/bin/lint-roblox-ui.mjs library/hub-kit/src
node tools/bin/check-file.mjs <their-hub.luau>
```

## Works with

- `roblox-ui`: layout, palettes and the countable rubric every hub is held to.
- `roblox-ui-components`: tested recipes when the user picks style codes for the hub's controls.
- `roblox-ui-interaction`: the input contract behind rows, sliders, keybinds and the Open chip.
- `roblox-ui-viewport`: the size bounds, compact mode and popup clamping.
- `roblox-ui-motion`: the three timings and Reduce Motion.
- `roblox-executor-features`: the tested features a hub's toggles switch on and off.
- `roblox-executor-scripting`: loaders, game routing and rerun safety around the UI.
- `roblox-executor`: `gethui`, file functions and library loading.
- `roblox-improve`: ranking what to fix first in an existing hub.
- `roblox-code-craft`: the ceremony budget for the hub's own code.
