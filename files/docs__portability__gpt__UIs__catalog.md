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
