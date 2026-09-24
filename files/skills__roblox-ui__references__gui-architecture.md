# GUI Architecture — the parts that decide whether it can be revamped

`gui-design.md` covers craft: spacing, typography, motion, responsiveness. **This file covers structure** — the decisions that determine whether the look can change later without a rewrite, and whether the GUI behaves like a real product.

> **Guidance, not a template.** Nothing here prescribes a visual style, and no snippet is meant to be pasted. These are architectural patterns to compose from. A GUI built on them can be re-skinned entirely by editing one table.

---

## 1. The token spine — three tiers

The single most valuable structural decision. Adapted from the DTCG design-token model, which exists precisely so a theme can be swapped without touching component code.

```
Primitive   raw values, never referenced by widgets
              Palette.blue600  = Color3.fromRGB(37, 99, 235)
              Space.s4         = 16
              Radius.md        = 12

Semantic    intent, not appearance — THIS is the layer a revamp edits
              Theme.actionPrimary  = Palette.blue600
              Theme.surfaceRaised  = Palette.slate800
              Theme.textMuted      = Palette.slate400
              Theme.gapDefault     = Space.s4

Component   what widget code actually reads
              Button.bg        = Theme.actionPrimary
              Button.padding   = Theme.gapDefault
              Panel.radius     = Radius.md
```

**The rule, stated once:**
- Widgets read **component** tokens. Never a raw `Color3`, never a magic number.
- A re-skin edits the **semantic** layer. Point `actionPrimary` somewhere else and every button, focus ring, and active tab follows.
- **Primitives** rarely change — they are the raw material, not the design.

This is what makes "I got bored of my GUI" a one-table edit instead of a rewrite. It is also why dark/light theming is nearly free: swap semantic aliases, leave primitives alone.

### Apply the same three tiers to everything, not just color

| Axis | Primitive | Semantic |
|---|---|---|
| Space | `s1..s8` on a consistent step (4 / 8 / 12 / 16 / 24 / 32...) | `gapTight`, `gapDefault`, `padPanel` |
| Radius | `none`, `sm`, `md`, `lg`, `pill` | `radiusControl`, `radiusPanel` |
| Type | size ramp + weight set + family pair | `titleLg`, `body`, `caption`, `numeric` |
| Motion | duration + easing constants | `durQuick`, `durPanel`, `easeStandard` |
| Elevation | stroke/shadow recipes | `elevRaised`, `elevOverlay` |

A GUI whose spacing comes from `Theme.gapDefault` everywhere reads as designed. One with `12`, `14`, `15`, `16` scattered through it reads as assembled — this is a large part of what makes UI look machine-generated.

### Non-prescriptive by construction

The structure above is style-agnostic. Any palette, any radius language, any type pairing drops into it. Flat, glassy, brutalist, editorial — same spine, different semantic table. **Choose the style per project; keep the spine constant.**

---

## 2. Roblox's native cascade — StyleSheet / StyleRule / StyleQuery

Roblox has its own CSS-like styling system: `StyleSheet` containing `StyleRule` objects, selected by class and by `CollectionService` tag, cascading onto instances. Where available, **this is the token layer** — theming and responsive variation without branching in Lua.

`StyleQuery` applies rules conditionally on:

| Condition | Use |
|---|---|
| `MinSize` / `MaxSize` | Breakpoint-style layout changes |
| `AspectRatioRange` | Portrait vs landscape handling |
| `ViewportDisplaySize` | Device-class targeting |
| `PreferredInput` | Touch vs mouse vs gamepad affordances |
| `PreferredTextSize` | Respect the player's text-size accessibility setting |
| Accessibility flags | e.g. reduced motion |

Two things follow:

- **Responsive rules move out of Lua.** Instead of reading `ViewportSize` and branching, declare rules per condition.
- **Accessibility becomes declarative.** `PreferredTextSize` and reduced-motion feed your type and motion tokens directly.

**Availability caveat:** StyleSheet/StyleRule and parts of StyleQuery have rolled out progressively, and some pieces sit behind beta capability flags. Feature-detect, and keep the Lua token table as the fallback path — the two are compatible, since the token table can supply the values the rules reference. In executor contexts especially, do not assume availability; the Lua table always works.

---

## 3. Config persistence — "execute once, everything is already on"

The goal: a user runs the script and their previous toggles, sliders, keybinds and dropdowns are already applied — no re-toggling.

Rayfield, WindUI and Linoria's SaveManager converge on the same architecture. Take the architecture, not any one API.

### a) State lives in a registry, not on the widget

Every stateful element gets a unique **flag** (Rayfield calls it `Flag`, Linoria the index name). State is stored in a global registry keyed by that flag — Linoria's `Toggles` / `Options`, Rayfield's `Rayfield.Flags`.

**Why this matters:** state that lives in a registry survives UI rebuilds, tab switches, and re-execution, because it was never stored in the UI in the first place. State stored on the Frame dies with the Frame.

Flags must be unique. Duplicates silently overwrite each other in the saved file.

### b) The reactive pair — `OnChanged` and `SetValue`

```
element:OnChanged(fn)   -- user changed it → run the feature
element:SetValue(v)     -- code changed it → UI updates AND the callback fires
```

This pair is the entire mechanism behind "features re-enable themselves". Loading a config is nothing more than iterating saved flags and calling `SetValue` on each. Because `SetValue` fires the callback, the feature turns itself back on as a side effect. No separate "apply config" code path exists — which means it cannot drift out of sync with the toggles.

Design the registry so this holds. If `SetValue` does not fire callbacks, config loading silently restores the *visual* state without re-enabling anything, which is the most common bug in home-rolled config systems.

### c) Autoload marker

Linoria's approach: a plain `autoload.txt` in the settings folder naming which config to load, read by `LoadAutoloadConfig()` at startup. Simple and effective — one small file answers "which of my saved configs should apply right now".

Give the user a way to set and clear it from the UI. Without that, autoload is a trap: a bad saved state applies on every execute with no obvious way out.

### d) Scope configs per game

```
SetFolder("MyHub")          -- the hub
SetSubFolder(placeId)       -- this specific place
```

Settings for one game must not leak into another. Keying by `game.PlaceId` (or `game.GameId` to share across places in one universe) is the difference between a hub that feels tailored and one that applies a fishing-game config to a shooter.

### e) Ignore lists

`SetIgnoreIndexes{...}` / `IgnoreThemeSettings()`. Never persist:

- The menu open/close keybind — a bad save locks the user out of their own UI.
- Transient runtime state (current target, session counters).
- Anything whose stale value would be actively harmful on next execute.

### f) Storage

JSON via `HttpService:JSONEncode` / `JSONDecode` with `writefile` / `readfile`. Conventional layout:

```
{Executor}/workspace/<Hub>/config/<name>.json
{Executor}/workspace/<Hub>/settings/autoload.txt
```

Guard every filesystem call — see `roblox-executor/references/api/misc.md`:

```lua
if not isfolder(dir) then makefolder(dir) end

local data
if isfile(path) then
    local ok, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(path))
    end)
    data = ok and decoded or nil
end
data = data or defaults   -- corrupt file falls back, never errors out
```

A corrupt config must degrade to defaults, not throw. Users delete files, executors truncate writes, and a config crash on startup makes the whole script look broken.

### g) Load order

**Build every element first. Load the config last.** `SetValue` on a flag whose element does not exist yet either errors or silently no-ops. Linoria's example places `LoadAutoloadConfig()` at the very bottom of the script for exactly this reason.

### h) Dependency boxes

Linoria's pattern: show or hide elements based on another element's state — the aimbot options only appear when aimbot is on. Keeps a dense menu legible and is worth implementing early, because retrofitting visibility rules onto a flat menu is tedious.

Related: a `Risky` marker on features with elevated detection risk, so the UI itself communicates what `roblox-executor/references/recon/detection-surface.md` says about them.

---

## 4. When a search mechanism is warranted

Judgement, not a widget. Thresholds:

| Feature count | Navigation |
|---|---|
| Under ~15 | Tabs alone. Search is overhead nobody uses. |
| **~15–40** | **Add search.** Scanning tabs to find one toggle has become the slow path. |
| Over ~40 | Search **plus** categories. Search alone leaves no map of what exists. |
| Any dropdown over ~10 options | Make that dropdown searchable (Linoria supports `Searchable = true` natively) |

### Implementation notes

- **Case-normalise both sides** — `string.lower()` the query and the haystack.
- **Plain substring, not pattern** — `string.find(haystack, needle, 1, true)`. The `true` disables pattern matching; without it a user typing `(` errors the search.
- **Match aliases, not just the label.** Give each feature a keyword list so "esp" finds "Player Highlight" and "aimbot" finds "Assisted Aim". This is what separates search that helps from search that requires knowing the exact name already.
- **Debounce.** Connect `textbox:GetPropertyChangedSignal("Text")`, but do not re-filter hundreds of rows on every keystroke — coalesce with a short timer.
- **Toggle `Visible`, do not reparent.** `UIListLayout` skips invisible children and reflows for free. Reparenting thrashes layout and loses ordering.
- **Empty state.** "No features match 'xyz'" with a clear-search affordance. A blank panel reads as broken.
- **Hundreds of rows → virtualise.** Render only what fits the viewport plus a small buffer; recycle row instances on scroll.

---

## 5. When a changelog is warranted

Trigger conditions, not a fixed component.

**Add one when either is true:**
- The script is distributed to other people — they need to know what changed since they last ran it.
- A persisted version marker differs from the current version.

**Skip it when** the script is private and single-user. You already know what you changed; a changelog is noise you have to maintain.

### Pattern

```
1. Keep a versioned entry list in code:  { version = "1.4.0", date = ..., changes = { ... } }
2. Persist `lastSeenVersion` in the config file.
3. On execute, compare current version to lastSeenVersion.
4. Show only entries newer than lastSeenVersion.
5. Update the marker once shown — so it appears exactly once per update.
```

**Choosing the surface:**
- One or two lines → a notification / toast. Non-blocking, dismissible.
- A real history → a dedicated panel or tab, reachable on demand, not forced on open.
- Never a modal that blocks the UI on every execute. That is the fastest way to make an update feel like an annoyance.

Write entries as what changed for the *user* ("aimbot now respects team check"), not as commit messages ("refactor target selection").

---

## 6. Non-happy states

Usually the difference between a GUI that feels finished and one that does not. Design these before the happy path, not after.

| State | What the UI must show |
|---|---|
| **Loading** | Skeleton or spinner while the script initialises — never a blank frame |
| **Empty search** | "No features match X" + clear action |
| **Empty list** | Why it is empty and what to do about it |
| **Config load failed** | Silent fallback to defaults **plus** a notification that it happened |
| **Feature unsupported here** | Disable the control and say why — do not hide it silently, and do not let it fail on click |
| **Executor missing a function** | Feature-detect at build time; disable with a reason (see `roblox-executor/references/technique/function-selection.md`) |
| **Awaiting the game** | Character not spawned, remote not found — show the wait, do not appear frozen |

The last two matter especially in executor scripts. A toggle that does nothing because `getrendersteppedlist` is unavailable on this executor should say so, not fail quietly.

---

## 7. Lifecycle

- **Single instance.** Detect and clean up a previous execution before building — otherwise re-running stacks GUIs, hooks and connections. Track via a known key in `getgenv()`.
- **Unload path.** One function that disconnects every connection, destroys every Drawing object, restores every hook, and destroys the GUI. Write it alongside the feature, not afterwards.
- **Unload signal.** Expose something like `Library:OnUnload(fn)` and an `Unloaded` flag so feature loops can exit cleanly instead of erroring when their UI disappears.
- **Parent to `gethui()`**, not `CoreGui` or `PlayerGui` — see `roblox-executor/references/recon/detection-surface.md`.

---

## Checklist before building a GUI

1. How many features? → decides tabs vs tabs+search vs search+categories.
2. Which values must persist? → flags, registry, config folder scoped to the place.
3. Is `SetValue` wired to fire callbacks? → if not, config loading will not re-enable anything.
4. Is the token spine in place before any widget is styled? → retrofitting it later is the expensive path.
5. Are the non-happy states designed? → loading, empty, failed, unsupported.
6. Is there an unload path? → written now, not later.
7. Distributed to others? → changelog. Private? → skip it.

---

## Related references
- `gui-design.md` — visual craft, responsive rules, style directions
- `roblox-executor/references/api/misc.md` — `writefile` / `readfile` / `isfile` / `makefolder`
- `roblox-executor/references/recon/detection-surface.md` — `gethui`, avoiding GUI enumeration
- `roblox-executor/references/technique/function-selection.md` — feature-detecting executor capabilities
- `roblox-luau-language/references/compiler-limits.md` — large single-file GUIs hit the 200-local limit fast
