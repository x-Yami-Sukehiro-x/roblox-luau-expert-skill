# library/

Working Luau you can drop into a project. Every file is also the worked example
that a reference file points at, so reading them is a second route into the same
material.

```
Tokens.luau            the three-tier design spine — edit this to re-skin everything
Layout.luau            the eight modifier constructors, with the wrong defaults fixed
Motion.luau            tweens by intent, springs via SmoothDamp, one reduced-motion switch
Toast.luau             notification system: queue, dedup, pause, spring reflow, teardown
Components/
  Button.luau          four weights, all six states, gamepad-reachable
  Divider.luau         hairline rules and labelled section breaks
  Panel.luau           layered strokes and a native UIShadow, from Tokens.elevation
  Toggle.luau          a switch whose knob moves, so it is not colour-only
  Slider.luau          drag tracked globally, quantised, keyboard and D-pad reachable
  Dropdown.luau        menu parented to the ScreenGui, opens upward when it must
  TabBar.luau          one sliding indicator, pages built once and toggled
  Modal.luau           three ways out, and focus on the safe action
```

| File | Explained in |
|---|---|
| `Tokens.luau` | `roblox-ui/references/gui-architecture.md` |
| `Motion.luau` | `roblox-ui-motion/` (all three references) |
| `Toast.luau` | `roblox-ui-components/references/toasts.md` |
| `Components/Button.luau` | `roblox-ui-components/references/component-states.md` |
| `Components/Divider.luau` | `roblox-ui-components/references/outlines-and-dividers.md` |
| `Components/Panel.luau` | `roblox-ui-components/references/shadows-and-elevation.md` |
| `Layout.luau` | `roblox-ui/references/build-order.md` |
| `Components/Toggle.luau` | `roblox-ui/references/blueprints.md` (B2) |
| `Components/Slider.luau` | `roblox-ui/references/blueprints.md` (B2) |
| `Components/Dropdown.luau` | `roblox-ui/references/blueprints.md` (B2) |
| `Components/TabBar.luau` | `roblox-ui/references/blueprints.md` (B6) |
| `Components/Modal.luau` | `roblox-ui/references/blueprints.md` (B5) |

---

## Install

**Rojo** — map the folder into `ReplicatedStorage`:

```json
{
  "ReplicatedStorage": {
    "UI": { "$path": "library" }
  }
}
```

```lua
local UI = ReplicatedStorage:WaitForChild("UI")
local Toast = require(UI.Toast)
local Button = require(UI.Components.Button)
```

**By hand** — drag `library/` into `ReplicatedStorage`, rename it `UI`. The
`script.Parent` requires resolve as long as the folder structure is preserved.

The modules require each other by relative path (`script.Parent.Motion`), so keep
`Components/` where it is or fix the two requires at the top of each component.

---

## Use

```lua
local Toast = require(UI.Toast)

Toast.success("Purchased Dragon Sword")
Toast.error("Could not reach the server")

-- Repeats collapse into a count instead of stacking:
for _ = 1, 40 do
    Toast.push({ message = "+1 Coin", severity = "success", key = "coin" })
end
-- one toast, "+1 Coin (x40)"
```

```lua
local Button = require(UI.Components.Button)

local confirm = Button.primary("Confirm", function()
    print("clicked")
end)
confirm.instance.Parent = panel

confirm:setBusy(true)     -- disables and shows a loading label
confirm:setEnabled(false) -- Interactable = false
confirm:destroy()         -- disconnects everything
```

```lua
local Layout = require(UI.Layout)

-- The root every menu starts from: centred, bounded, padded, stacked.
local root = Layout.panelRoot(screenGui)
Layout.label(root, "Settings", "title")

local list = Layout.scroller(root, 8)
Layout.fill(list)          -- absorbs whatever the header and footer leave
```

```lua
local Toggle = require(UI.Components.Toggle)
local Slider = require(UI.Components.Slider)

local music = Toggle.new(true, function(on) soundGroup.Volume = if on then 0.6 else 0 end)
music.instance.Parent = row

local sensitivity = Slider.new(
    { min = 0.1, max = 3, step = 0.1, initial = 1 },
    function(value) camera.Sensitivity = value end
)

-- `silent` restores a saved config without re-firing every handler.
music:set(savedConfig.music, true)
sensitivity:set(savedConfig.sensitivity, true)
```

```lua
local Modal = require(UI.Components.Modal)

Modal.confirm(screenGui, {
    title = "Sell Crate",
    message = "This gives you 250 Gems. The crate is gone.",
    confirmText = "Sell for 250 Gems",
    destructive = true,
}, function(confirmed)
    if confirmed then sellRemote:FireServer() end
end)
```

```lua
local Motion = require(UI.Motion)

Motion.play(panel, "enter", { GroupTransparency = 0 })

-- Spring: use whenever the target can change mid-flight.
local follow = Motion.spring(highlight, "Position", 0.12)
follow:setTarget(UDim2.fromScale(0.5, 0))   -- safe to call again immediately
```

---

## Re-skinning

Edit `Tokens.luau` and nothing else. No other file in this folder contains a colour
literal — that is the point of the tiering, and it is what makes a theme change one
edit instead of forty.

The `PRIMITIVE` table at the top is the only place raw values live. `SEMANTIC` gives
them meaning (`surface.raised`, `text.muted`), and components read only from there.

The neutral ramp has **deliberately uneven steps** — the jump from page to panel is
larger than panel to control, so surfaces actually separate. Evenly spaced greys are
catalog tell R4.

---

## What these are not

Not a UI framework. There is no reactivity, no component tree, no diffing. They are
plain Instance code, because for most Roblox UI that is the right amount of
machinery — see the framework survey in `roblox-ui/SKILL.md` for when it is not.

If you are already on Fusion, Vide or React-lua, read these for the *behaviour*
(the toast queue, the state matrix, the spring reflow) and reimplement in your
framework's idiom rather than mixing paradigms.

---

## Caveats

- **Client-side only.** Everything here builds `GuiObject`s and belongs in a
  `LocalScript` context.
- **`Toast.luau` assumes `Players.LocalPlayer`.** For a Studio plugin, replace
  `ensureContainer` with one that parents into your `DockWidgetPluginGui`.
- **`Panel.new` needs no shadow asset.** It uses `UIShadow`, which follows the
  panel's corner radius on its own. Depth comes from `Tokens.elevation`; pass
  `depth` to override the level implied by `elevation`.
- **Fonts** default to Gotham in `Tokens.luau`. That is the Roblox default and
  catalog tell R7 — change it to something the game chose.
- **`Dropdown` needs a `ScreenGui` ancestor.** Its menu is parented there rather
  than to the control, so it is not clipped by a scrolling list. Without one it
  warns and does not open.
- **`Modal.confirm` binds Escape and gamepad B** through `ContextActionService`
  and unbinds on close. Do not open two at once; the second overwrites the
  first's binding.
- **Six directions ship as data**, not just the one in `Tokens.luau`. Every RGB
  value, font, radius and type scale is in
  `roblox-ui/references/design-directions.md`, contrast-verified by
  `tools/bin/lint-ui-directions.mjs`.
