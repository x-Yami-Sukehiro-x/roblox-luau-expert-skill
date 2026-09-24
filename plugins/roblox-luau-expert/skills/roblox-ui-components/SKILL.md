---
name: roblox-ui-components
description: Building individual Roblox UI components properly — toast and notification systems with queueing, stacking and reflow; outlines with UIStroke BorderStrokePosition and layered strokes; 9-slice panels and shadows; dividers and separation without lines; interaction states (rest, hover, press, focus, disabled, selected) plus loading; native UIShadow and an elevation scale; draggable and resizable windows with UIDragDetector; ScrollingFrame configuration and virtualised long lists; a catalog covering buttons, toggles, sliders, dropdowns, modals, tooltips, tabs, progress and text input; tested recipes for every style-picker code (T1–T30 toggles, C1–C20 checkboxes, D1–D22 dropdowns including search fields, M0–M36 menu motion, N1–N30 notifications, O1–O20 hide and bring back, P1–P22 button feel, S1–S22 tabs, H1–H12 tooltips and slider values); and which Lucide icon means what, with 1,559 verified Roblox ids. Use when building or reviewing any specific UI control, notification, popup or panel, or when the user picked a style code.
---

# UI components

Layout is `roblox-ui`. Motion is `roblox-ui-motion`. This is the individual controls
and the details that make them feel built rather than assembled.

| Need | File |
|---|---|
| **a user picked a code such as T2, M4 or N4** | `references/style-recipes.md` |
| notifications, toasts, popups | `references/toasts.md` |
| icons, lucide asset ids, `getcustomasset`, drawing a glyph without one | `references/icons.md` |
| which icon means Combat, Visuals, Shop, Teleports; icon ids for 1,559 Lucide icons | `references/icon-meaning.md`, `references/icon-ids.txt` |
| borders, strokes, shadows, dividers, separation | `references/outlines-and-dividers.md` |
| hover / press / focus / disabled / selected / loading | `references/component-states.md` |
| button, toggle, slider, dropdown, modal, tooltip, tabs, progress, input | `references/catalog.md` |
| `UIShadow`, elevation, inner shadows, blur behind a modal | `references/shadows-and-elevation.md` |
| draggable windows, title bars, resize handles, `UIDragDetector` | `references/windows-and-drag.md` |
| `ScrollingFrame` configuration, scroll-to-item, long lists | `references/scrolling-and-virtualisation.md` |

Working implementations: `library/src/Components/`, `library/src/Toast.luau`.
Tested single-file recipes for every visual-guide code: `assets/`.

---

## The rule that covers most of it

**A component is its states, not its appearance.** Most Roblox controls ship with a
default look and a hover colour, and nothing else. That is the catalog tell R13, and
it is what makes UI feel like a mockup rather than software.

Six states, every interactive element:

| State | Driven by | Missing it means |
|---|---|---|
| default | — | — |
| hover | `MouseEnter` / `MouseLeave` | feels dead on desktop |
| press | `InputBegan` / `InputEnded` | feels broken on touch |
| focus | `SelectionGained` / `SelectionLost` | **unusable on gamepad** |
| disabled | `Interactable = false` | people click dead controls |
| selected | current tab, toggle value or row | current choice is lost when focus moves |

Loading is an additional state for asynchronous work. Selected has a meaning on
tabs and toggles; a one-shot action does not acquire sticky selection. Account
for each state and implement the meaningful ones without adding fake behavior.

Full treatment with the correct event wiring in `references/component-states.md`.

---

## Use `Activated`, not `MouseButton1Click`

```lua
button.Activated:Connect(function(inputObject: InputObject, clickCount: number)
    ...
end)
```

`GuiButton.Activated` fires for mouse, touch **and** gamepad. `MouseButton1Click`
fires for a mouse only, which is why so many Roblox menus are unusable on console.
`Activated` also carries `clickCount`, so double-click is free.

`GuiObject.Interactable = false` is the correct way to disable a control — it stops
input without changing `Visible` or `Active` semantics, and without you having to
disconnect anything.

---

## Composition over configuration

A component with eighteen constructor options is harder to use than three components.
Prefer:

```lua
Button.primary(text, onClick)
Button.secondary(text, onClick)
Button.ghost(text, onClick)
```

over `Button.new({ variant = "primary", size = "md", icon = nil, loading = false, ... })`.

Three button weights is enough for almost every game — primary (one per view),
secondary, and ghost. A destructive action gets its own treatment and never sits
mirrored next to the primary. See catalog tell R10.

---

## Every component reads tokens, never literals

```lua
-- WRONG: a re-skin means finding every literal
frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

-- RIGHT
frame.BackgroundColor3 = Tokens.surface.raised
```

This is the difference between changing a theme in one file and changing it in forty.
The three-tier spine (primitive → semantic → component) is in
`roblox-ui/references/gui-architecture.md`; the working version is
`library/src/Tokens.luau`.

---

## Components must clean up

Every component that connects a signal, starts a tween, or spawns a thread owes a
teardown. A menu rebuilt on every open that never disconnects is the single most
common Roblox memory leak — see `roblox-performance`.

```lua
function Button.new(...)
    local trove = Trove.new()
    trove:Add(button.Activated:Connect(onClick))
    trove:Add(button)                        -- destroyed with the trove

    return { instance = button, destroy = function() trove:Destroy() end }
end
```

Return a `destroy`, or take a Trove as a parameter. A component with no teardown path
is a leak with a nice appearance.

---

## Surface differences

The same component behaves differently depending on where it lives.

**Game UI** — must not cover the topbar or mobile controls; obeys `ScreenInsets` and
`GuiService:GetGuiInset()`; needs gamepad focus for console players.

**Executor hub UI** — dense lists of toggles and keybinds, every control bound to a
persisted flag so state survives re-execution, and parented via `gethui()` rather than
`PlayerGui`. See `roblox-executor/references/ui/ui-libraries.md`.

**Studio plugin UI** — lives in a `DockWidgetPluginGui` and must match the user's
Studio theme via `Enum.StudioStyleGuideColor`, or it looks broken in light mode.

Per-surface detail: `roblox-ui/references/responsive-and-surfaces.md`.
