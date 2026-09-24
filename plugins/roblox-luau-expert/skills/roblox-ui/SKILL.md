---
name: roblox-ui
description: Roblox UI layout, responsiveness and design taste — recognising and removing generic AI-generated UI, ScreenGui and GuiObject layout, scale versus offset, UIListLayout with Wraps and flex alignment, UIFlexItem, StyleSheet cascade, safe areas and the GUI inset, design tokens for re-skinnable UI, config persistence for feature-heavy menus, viewport and DPI scaling with UIScale, typography and rich text, gradients including radial and conical, input across mouse, touch, gamepad and console, and the three surfaces (game HUD, executor hub, Studio plugin). Use for building or reviewing any GUI, menu, HUD, hub or script UI, when UI breaks on mobile, or when a design "looks AI-generated".
---

# Roblox UI

Before new/redesigned UI code, resolve toggle, motion and notification
preferences using `../roblox-request-intake/references/visual-choices.md`. Link
its real guide and ask once, together; preserve prior choices or a request to
decide for the user. A picked code (T2, M4, N4…) is built from
`../roblox-ui-components/references/style-recipes.md`, never from memory. For a
user who names parts in everyday words, read
`../roblox-request-intake/references/ui-words.md`.

This skill owns **layout, responsiveness and taste**. Two siblings own the rest:

- **`roblox-ui-motion`** — easing, springs, choreography, reduced motion.
- **`roblox-ui-components`** — toasts, outlines, dividers, states, the control catalog.

| Need | File |
|---|---|
| **building any UI — start here** | `references/build-order.md` |
| **which palette, which font, which radius** | `references/design-directions.md` |
| **a layout recipe for a menu, list, grid, modal, HUD** | `references/blueprints.md` |
| **checking your own work before delivering** | `references/self-review.md` |
| **working controls, real device tests, and honest evidence** | `references/functional-proof.md` |
| a generated panel scored and rewritten, with the failures named | `references/ui-rewrite.md` |
| icons, lucide asset ids, `getcustomasset`, no more `"×"` | `../roblox-ui-components/references/icons.md` |
| the notification does not match the panel | `../roblox-ui-components/references/shadows-and-elevation.md` |
| "this looks AI-generated" / design review | `references/anti-slop-catalog.md` |
| scale vs offset, flex, safe areas, game vs hub vs plugin | `references/responsive-and-surfaces.md` |
| structure that survives a re-skin — tokens, cascade, config persistence, search and changelog thresholds | `references/gui-architecture.md` |
| visual craft — spacing, contrast, style directions | `references/gui-design.md` |
| type scale, `FontFace`, rich text, measuring text, `TextScaled` | `references/typography.md` |
| UI too big or too small on a device, `UIScale`, insets, notches | `references/scaling-and-dpi.md` |
| gradients, radial and conical, depth, blur behind a modal | `references/gradients-and-depth.md` |
| mouse vs touch vs gamepad vs console, focus, gestures | `references/input-surfaces.md` |

## The four files that decide the outcome

The rest of this skill explains *why*. These four say *what*, with numbers, and
they are the ones to open first:

1. **`references/build-order.md`** — a gated procedure for constructing
   any interface. Follow it in order. Every step ends in a yes/no check that
   needs no design judgement.
2. **`references/design-directions.md`** — six complete palettes with every RGB
   value, font, radius and type scale stated, contrast verified by
   `tools/bin/lint-ui-directions.mjs`. **Slate is the default** when the user
   expressed no preference. Never invent a palette; that is where grey-on-grey
   comes from.
3. **`references/blueprints.md`** — working recipes for the root scaffold,
   settings row, scrolling list, item grid, modal, tab bar, HUD, mobile sheet and
   executor hub.
4. **`references/self-review.md`** — a countable rubric, run before delivery.
   **`tools/bin/lint-roblox-ui.mjs` counts the source checks it can decide**;
   report its actual score and denominator. A passing score does not prove
   appearance, accessibility or working interactions. Complete the separate
   device and behavior checks in `references/functional-proof.md`.

Use these defaults to spend less time choosing numbers and more time arranging
the user's content. They do not decide the player's task, the most useful
grouping, or whether the screen is clear. Preserve an established project design
and make those content decisions before selecting a blueprint.

Then: `references/anti-slop-catalog.md` before reviewing a GUI, and
`references/gui-architecture.md` before writing one. Architecture decides whether
you can change your mind later; design decides whether it looks good now.

Working code lives in `library/src/` at the plugin root — `Tokens.luau`,
`Motion.luau`, `Toast.luau`, `Components/`.

---

## Scale versus offset — the decision that breaks mobile

`UDim2.new(scaleX, offsetX, scaleY, offsetY)`. Scale is a fraction of the
parent; offset is absolute pixels.

- **Scale for layout** — panels, columns, anything that should grow with the
  screen.
- **Offset for detail** — border thickness, icon size, padding that should not
  shrink to nothing on a phone.

```lua
-- panel: half the width, capped so it does not become absurd on ultrawide
panel.Size = UDim2.fromScale(0.5, 0.7)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(720, 900)
constraint.MinSize = Vector2.new(280, 320)
constraint.Parent = panel
```

Pure-offset UI is the single most common reason a menu is unusable on a phone.
Pure-scale UI is why text becomes illegible on small screens. Use both, with
`UISizeConstraint` and `UITextSizeConstraint` as the guard rails.

`UIAspectRatioConstraint` keeps square things square across every screen — the
right tool for item slots and avatar frames.

---

## Layout containers

Let the engine do the arithmetic. Hand-positioned children break the moment
anything changes.

```lua
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Parent = container
```

- `UIListLayout` — rows or columns. Set `SortOrder = LayoutOrder` and give each
  child a `LayoutOrder`; the default sorts by name, which surprises everyone.
- `UIGridLayout` — fixed-size cells. `CellSize` in offset makes it non-responsive;
  pair with `UIAspectRatioConstraint` or compute cell size from
  `AbsoluteSize`.
- `UIPadding` — inner spacing. Prefer it to margin frames.
- `UIFlexItem` — flexbox-style growth inside a `UIListLayout`. `FlexMode` of
  `None`, `Grow`, `Shrink`, `Fill` or `Custom` lets one child absorb remaining
  space instead of hard-coding sizes, with `GrowRatio` / `ShrinkRatio`.
- `UICorner`, `UIStroke`, `UIGradient` — appearance modifiers, no layout effect.

Two `UIListLayout` properties most tutorials predate, both verified:

- **`Wraps`** (boolean) — items flow onto a new line rather than overflowing. This
  is what makes a horizontal button row survive a narrow phone.
- **`HorizontalFlex` / `VerticalFlex`** take `Enum.UIFlexAlignment`: `None`, `Fill`,
  `SpaceAround`, `SpaceBetween`, `SpaceEvenly`. Real distribution, no spacer frames.
  `ItemLineAlignment` controls cross-axis alignment within a line.

Full layout treatment, including the three surfaces:
`references/responsive-and-surfaces.md`.

`AutomaticSize` (`X`, `Y`, `XY`) sizes a frame to its content. Combined with
`UIListLayout` and `UIPadding` it removes most manual height arithmetic. It
fights an explicit `Size` on the same axis — set the other axis only.

---

## StyleSheet cascade

Roblox has a native CSS-like cascade: `StyleSheet`, `StyleRule`, `StyleLink`,
`StyleDerive`, and `StyleQuery` for conditional rules. It lets you change every
button in the game by editing one rule instead of walking the tree.

This is the engine-level version of the token spine described in
`references/gui-architecture.md`. Use whichever fits the project, but use one of
them — the alternative is hard-coded colours scattered across forty files, which
is what makes a re-skin a rewrite.

---

## Safe areas and the GUI inset

```lua
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
```

The Roblox topbar occupies the top of the screen. On phones, notches and rounded
corners take more. `Enum.ScreenInsets` (`CoreUISafeInsets`, `DeviceSafeInsets`,
`None`, `TopbarSafeInsets`) controls what your GUI treats as usable.

`GuiService:GetGuiInset()` returns the current inset if you need to compute
around it.

Test on a phone-shaped viewport, not just a resized Studio window. Studio's
Device Emulator is the fast path.

---

## Cross-device input

Detect capability, not device:

```lua
local UserInputService = game:GetService("UserInputService")

local function isTouchPrimary(): boolean
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

UserInputService.LastInputTypeChanged:Connect(function(inputType)
    -- adapt hints live; many players switch mid-session
end)
```

Many desktops report `TouchEnabled`. `LastInputType` is the honest signal for
"what is this person using right now".

Touch targets need **44 px minimum**, and hover states do not exist — anything
that only reveals on hover is invisible on a phone. `ContextActionService` with
`createTouchButton = true` gives you a mobile button for free from the same
binding as the keyboard key. See `roblox-engine-api`.

---

## Framework survey

Status verified 2026-09-09. **Maintenance matters more than stars here** — half the
tutorials online recommend a project that has not been touched in two years.

| Library | ★ | Last push | Model | Use when |
|---|---|---|---|---|
| **Fusion** | 795 | 219d | reactive state graph | declarative UI in pure Luau |
| **Vide** | 323 | 35d | reactive, lighter than Fusion | Fusion's model with less surface |
| **Iris** | 348 | 5d | immediate mode (Dear ImGui) | debug panels and internal tools, **not** player UI |
| **Charm** | 253 | 79d | atomic state | state management, pairs with any renderer |
| **ui-labs** | 189 | 27d | storybook | previewing components in isolation |
| **flipbook** | 125 | 0d | storybook | the other storybook; both are active |
| **React-lua** | 568 | **474d** | React, ported | large ecosystem, but going stale — check before adopting |
| ~~**Roact**~~ | 625 | **archived** | — | **do not start here.** Still the top search result; superseded by React-lua |

**Plain Instance code is a legitimate choice.** For a HUD with six elements a
declarative framework is overhead. Frameworks earn their place when UI state gets
complex enough that manual updates drift out of sync with the data.

For animation, do **not** reach for `roact-spring` (74★, 800 days stale). Roblox
ships `TweenService:SmoothDamp`, a first-party critically damped spring — see
`roblox-ui-motion`.

Iris in particular is for *your* tools, not your players — an immediate-mode
debug panel is enormously useful and should never ship in a player-facing menu.

---

## Performance

- **`ScreenGui.Enabled = false` beats destroying and rebuilding.** Rebuilding a
  menu on every open is a per-open allocation spike.
- **Reuse rows.** For a leaderboard or inventory, pool the frames and rewrite
  their contents rather than destroying and recreating them.
- **Avoid per-frame UI writes.** Update on change, or throttle to ~10 Hz. A
  health bar does not need 60 updates a second.
- **`UIStroke` and `UIGradient` are not free** at high counts. Hundreds of
  stroked frames cost real render time.
- **Deep hierarchies cost layout passes.** Flatten where it does not hurt
  clarity.
- **Preload images** with `ContentProvider:PreloadAsync` before a menu opens, or
  the first frame shows empty boxes.

---

## Non-happy states

The states that get skipped and then reported as bugs:

- **Loading** — before data arrives. Not a blank panel.
- **Empty** — zero items. Say why and what to do about it.
- **Error** — the request failed. Say so and offer a retry.
- **Too many** — the list is long enough to need search or paging. The
  thresholds for when a search field or a changelog becomes warranted are in
  `references/gui-architecture.md`.
- **Disabled / locked** — the feature exists but is unavailable. Show the
  requirement.
- **Offline / kicked** — the connection went away mid-interaction.

Designing only the happy path is the most common UI defect, and it is always
found by a player rather than by you.
