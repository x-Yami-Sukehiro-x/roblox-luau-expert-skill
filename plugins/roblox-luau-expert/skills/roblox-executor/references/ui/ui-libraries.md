# Script-hub UI libraries

Status verified against the live repositories. A stale library is the usual
cause of "the menu doesn't open any more" after a Roblox UI change.

| Library | ★ | License | Last push | Status |
|---|---|---|---|---|
| **Obsidian** (`deividcomsono/Obsidian`) | 141 | MIT | 2026-09-07 | **Active (2d).** Maintained Linoria fork. Dense, keybind-first, config-save built in. The usual choice for feature-heavy menus. |
| **WindUI** (`Footagesus/WindUI`) | 349 | MIT | 2026-08-01 | **Active (39d).** Window system, 10+ themes, full element set, own docs site. |
| **Rayfield** (`SiriusSoftwareLtd/Rayfield`) | 77 | — | 2026-06-14 | Maintained (87d). Heavily tutorialised, so most public scripts assume it. |
| **Luna Interface Suite** (`Nebula-Softworks`) | 58 | — | 2025-12-15 | Slowing (268d). |
| **Fluent** (`dawid-scripts/Fluent`) | 120 | — | 2024-05-09 | **Stale (853d).** Clean look, nobody is fixing it. |
| **LinoriaLib** (`violin-suzutsuki`) | 96 | — | 2024-08-09 | **Stale.** The original; superseded by Obsidian for new work. Active forks exist under other owners. |

Recency verified 2026-09-09; the day counts are from that date.

**Prefer an actively maintained one.** Roblox changes GUI behaviour often enough
that a library untouched for two years accumulates breakage.

---

## Choosing

- **Many toggles, keybinds, config persistence** → Obsidian. It was built for
  exactly this shape and its config system is the reason to pick it.
- **Presentation matters, fewer options** → WindUI. Themed, actively developed.
- **Matching an existing public script** → whatever that script already uses.
  Do not port a working hub to a different library for aesthetics.
- **Two or three toggles** → no library. A `ScreenGui` with three buttons is
  fifty lines and has no external dependency to break.

---

## Loading

```lua
local ok, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/OWNER/REPO/main/Library.lua"))()
end)
if not ok then
    warn("[ui] library failed to load: " .. tostring(Library))
    return
end
```

**Always `pcall` the load.** A raw `loadstring(HttpGet(...))()` at the top of a
script means a CDN hiccup or a moved file kills the whole hub with an unhelpful
error.

**Pin to a commit, not to `main`,** for anything you rely on. A breaking upstream
change otherwise arrives unannounced in the middle of your session:

```lua
local PINNED = "https://raw.githubusercontent.com/OWNER/REPO/a1b2c3d/Library.lua"
```

**Cache to disk** so you are not re-fetching on every execute, and so the hub
still loads when the CDN is unreachable:

```lua
local CACHE = "hub/library.lua"
local source
if isfile(CACHE) then
    source = readfile(CACHE)
else
    source = game:HttpGet(PINNED)
    if not isfolder("hub") then makefolder("hub") end
    writefile(CACHE, source)
end
local Library = loadstring(source)()
```

---

## Config persistence

The behaviour users actually want: **execute once, and every toggle is already
where they left it.** Nobody wants to re-enable eleven options after a respawn.

Obsidian and WindUI both ship config systems. The pattern underneath them, if
you are rolling your own or need to understand theirs:

1. A **flag registry** — every control writes to one table keyed by a stable
   flag name, never to a local.
2. **Save on change**, debounced, to a JSON file under a per-game folder.
3. **Autoload on execute**, applying saved values *before* the UI is built, so
   the controls render in the correct state rather than flickering.
4. **Per-game files** keyed by `game.PlaceId`, plus a shared file for global
   preferences.

The full architecture — token spine, flag registry, autoload ordering, and the
thresholds at which a search field or a changelog becomes warranted — is in
`roblox-ui/references/gui-architecture.md`. It applies to hub UIs unchanged.

For the rest of the UI surface, use the shared skills rather than re-deriving:

| Need | Where |
|---|---|
| notifications inside a hub | `roblox-ui-components/references/toasts.md` — anchor bottom-right, not over the game's HUD |
| toggle / slider / dropdown behaviour | `roblox-ui-components/references/catalog.md` |
| hover, press, focus, disabled states | `roblox-ui-components/references/component-states.md` |
| borders, dividers, panel edges | `roblox-ui-components/references/outlines-and-dividers.md` |
| animating panels and menus | `roblox-ui-motion` — and prefer `SmoothDamp` over stacked tweens |
| making it not look generic | `roblox-ui/references/anti-slop-catalog.md` |

Working implementations you can lift live in `library/src/` at the plugin root:
`Toast.luau`, `Motion.luau`, `Tokens.luau`, `Components/`.

---

## Executor-specific concerns

**Protect the GUI.** `syn.protect_gui(gui)` and equivalents reparent a
`ScreenGui` out of `PlayerGui` so a game walking `PlayerGui` does not find it.
Feature-detect; not every executor has it, and it is not a security boundary —
a game that looks harder still finds it. See `../recon/detection-surface.md`.

```lua
local gui = Instance.new("ScreenGui")
if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
    syn.protect_gui(gui)
    gui.Parent = game:GetService("CoreGui")
elseif typeof(gethui) == "function" then
    gui.Parent = gethui()
else
    gui.Parent = game:GetService("CoreGui")
end
```

`gethui()` is the modern sUNC path and should be preferred where present.

**Provide an unload path.** Every hub needs a single teardown that disconnects
every connection, restores every hook, destroys every Drawing object and removes
the GUI. A hub that requires a rejoin to remove is a broken hub — and leftover
hooks are a detection surface after you think you have stopped.

```lua
local trove = {}
local function cleanup()
    for _, fn in trove do pcall(fn) end
    table.clear(trove)
end
getgenv().UnloadHub = cleanup
```

**Namespace your `getgenv()` state** so two scripts do not collide:

```lua
local genv = getgenv()
genv.MyHub = genv.MyHub or { flags = {}, connections = {} }
```

**Drawing objects are not GUI.** They render above everything and are not
parented into the DataModel, so a game cannot find them by walking instances —
but they must be `:Destroy()`d explicitly or they persist after unload — `:Remove()`
is the deprecated `Instance` method and is not part of the Drawing surface. See
`../api/drawing.md`.
