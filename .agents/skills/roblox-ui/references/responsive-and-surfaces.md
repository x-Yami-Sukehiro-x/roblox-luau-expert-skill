# Responsive UI and the three surfaces

Game UI, executor hub UI and Studio plugin UI share primitives and share almost
nothing else. This covers the responsive rules that apply everywhere, then what
differs per surface.

---

## Scale, offset and constraints

`UDim2.new(scaleX, offsetX, scaleY, offsetY)` — scale is a fraction of the parent,
offset is absolute pixels.

**Design mobile first.** Phones have the least room; anything that fits a phone fits
everything else. The reverse is not true, and is how most Roblox menus end up
unusable on the platform most players use.

| Use | For |
|---|---|
| **scale** | panels, columns, anything that should grow with the screen |
| **offset** | borders, icon sizes, padding that must not shrink to nothing |
| `UISizeConstraint` | stop a scaled panel becoming absurd on ultrawide, or unusably small |
| `UIAspectRatioConstraint` | keep square things square — item slots, avatar frames |
| `UITextSizeConstraint` | keep scaled text legible |

```lua
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.5, 0.7)

local bounds = Instance.new("UISizeConstraint")
bounds.MinSize = Vector2.new(280, 320)
bounds.MaxSize = Vector2.new(720, 900)
bounds.Parent = panel
```

Offset is the right choice in three cases: you need pixel precision consistent across
platforms, the element is an icon at a specific resolution, or the property has no
scale support. `UIStroke.Thickness` is the classic third case — though
`StrokeSizingMode = ScaledSize` now exists, `FixedSize` is usually still what you want,
since a 1px hairline should stay 1px or it stops reading as a hairline.

**Corner radius in scale** stays proportional across devices; in offset it does not.
A constant offset radius on both a 32px button and a 600px panel is catalog tell R15.

---

## `AnchorPoint`

`AnchorPoint` (0–1) sets which point of the element `Position` refers to. Default
`(0, 0)` is the top-left.

| Goal | AnchorPoint | Position |
|---|---|---|
| centred | `(0.5, 0.5)` | `fromScale(0.5, 0.5)` |
| bottom-right | `(1, 1)` | `fromScale(1, 1)` |
| top-right | `(1, 0)` | `fromScale(1, 0)` |

Positioning by scale plus `AnchorPoint` is what keeps alignment correct across screen
sizes. Centring with offset maths breaks the moment the viewport changes.

---

## Layout containers do the arithmetic

Hand-positioned children break as soon as anything changes. Modern layout surface,
all verified:

```lua
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.Padding = UDim.new(0, Tokens.space.base)
list.SortOrder = Enum.SortOrder.LayoutOrder    -- default sorts by NAME
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Wraps = true                               -- wrap onto multiple lines
list.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
list.VerticalFlex = Enum.UIFlexAlignment.None
list.ItemLineAlignment = Enum.ItemLineAlignment.Center
list.Parent = container
```

Two properties most tutorials predate:

- **`UIListLayout.Wraps`** — items flow onto a new line instead of overflowing. This
  is what makes a horizontal row of buttons survive a narrow phone.
- **`HorizontalFlex` / `VerticalFlex`** take `Enum.UIFlexAlignment`: `None`, `Fill`,
  `SpaceAround`, `SpaceBetween`, `SpaceEvenly`. Real distribution, no spacer frames.

Per-child growth is `UIFlexItem`:

```lua
local flex = Instance.new("UIFlexItem")
flex.FlexMode = Enum.UIFlexMode.Fill    -- None | Grow | Shrink | Fill | Custom
flex.GrowRatio = 1
flex.ShrinkRatio = 1
flex.ItemLineAlignment = Enum.ItemLineAlignment.Stretch
flex.Parent = child
```

`AutomaticSize` (`X`, `Y`, `XY`) sizes a container to its contents. Combined with
`UIListLayout` and `UIPadding` it removes most manual height maths. It **fights an
explicit `Size` on the same axis** — set the other axis only.

**Always set `SortOrder = LayoutOrder`.** The default is `Name`, which sorts your rows
alphabetically and surprises everyone exactly once.

---

## The GUI inset and safe areas

```lua
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
```

`Enum.ScreenInsets`: `None`, `DeviceSafeInsets`, `CoreUISafeInsets`,
`TopbarSafeInsets`. This is the modern control and supersedes the older
`IgnoreGuiInset` boolean.

**Never hardcode the topbar height.** Roblox's own staff guidance says 36px; community
reports say 58px. Both may be right for different clients and versions. The only
correct source is runtime:

```lua
local inset = game:GetService("GuiService"):GetGuiInset()
```

Reflow when the inset changes rather than measuring once at startup. The event most
guides reach for here, `GuiService.SafeZoneOffsetsChanged`, is `{RobloxScript}` in the
dump — a normal LocalScript cannot connect to it. Watch the properties instead:

```lua
local GuiService = game:GetService("GuiService")

GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(reflow)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(reflow)
```

`GuiService.TopbarInset` is a `Rect` and is the exact answer to the 36-versus-58
question above.

Mobile virtual controls occupy the **bottom-left and bottom-right**. Anything placed
there is either unreadable or steals touches. Notches and rounded corners take more
off the top on modern phones, which is what `DeviceSafeInsets` handles.

Test with Studio's Device Emulator (**Test → Device**), in both portrait and landscape,
not just by resizing the window.

---

## Cross-device input

Detect capability, not device — many desktops report `TouchEnabled`:

```lua
local UserInputService = game:GetService("UserInputService")

local function touchIsPrimary(): boolean
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

UserInputService.LastInputTypeChanged:Connect(function(inputType)
    -- players switch mid-session; adapt hints live
end)
```

- **44px minimum touch target.** A 24px icon needs a 44px button containing it;
  a transparent parent frame does not enlarge a child button's hit area.
- **Hover does not exist on touch.** Anything revealed only on hover is invisible on a
  phone — tooltips especially.
- **Gamepad needs focus.** `Selectable`, `SelectionOrder`, `NextSelection*`, a custom
  `SelectionImageObject`, and `GuiService.SelectedObject` set on open and cleared on
  close. Without it the menu is unusable on console, not merely degraded. See
  `roblox-ui-components/references/component-states.md`.

---

## Surface 1 — game UI

Everything above applies. Plus:

- **Never cover the topbar or the mobile controls.**
- **`ResetOnSpawn = false`** on any `ScreenGui` that should survive respawn. The
  default is `true`, which silently destroys your HUD on death.
- **`DisplayOrder`** layers `ScreenGui`s against each other; `ZIndex` only orders
  within one.
- **`StreamingEnabled`** means instances may be absent — client UI code must treat
  "not there yet" as normal, not an error. See `roblox-engine-api`.
- Preload images with `ContentProvider:PreloadAsync` before a menu opens, or the first
  frame shows empty boxes.

---

## Surface 2 — executor hub UI

Dense lists of toggles and keybinds, opened and closed constantly, re-executed often.

- **Choose one supported parent mechanism** from the target executor's verified
  contract and feature-detect it once. If the script requires `gethui()`, report
  it missing instead of silently switching to `CoreGui`. No GUI parent provides
  a security boundary.
- **Every control writes to a persisted flag** so state survives re-execution. The
  flag-registry and autoload ordering is in `gui-architecture.md`; that is the
  "execute once and everything is already on" behaviour.
- **Search once the feature count grows**, changelog once updates are frequent —
  thresholds in `gui-architecture.md`.
- **A single unload path** that disconnects everything, restores hooks, removes
  Drawing objects and destroys the GUI. A hub that needs a rejoin to remove is broken,
  and leftover hooks are a detection surface.
- Toasts belong here too — `roblox-ui-components/references/toasts.md`, anchored
  bottom-right rather than over the game's own HUD.

Library comparison and current maintenance status:
`roblox-executor/references/ui/ui-libraries.md`.

---

## Surface 3 — Studio plugin UI

```lua
local widget = plugin:CreateDockWidgetPluginGuiAsync(
    "MyPluginWidget",
    DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 320, 400, 260, 300)
)
widget.Title = "My Plugin"
```

**`Plugin:CreateDockWidgetPluginGui` (without `Async`) is `[Deprecated]`.** Use the
`Async` form — most plugin tutorials still show the old one.

**Match the Studio theme or the plugin looks broken in light mode:**

```lua
local Studio = settings().Studio

local function applyTheme()
    local theme = Studio.Theme
    frame.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    label.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
end

applyTheme()
Studio.ThemeChanged:Connect(applyTheme)
```

`Enum.StudioStyleGuideColor` covers the full Studio palette — `MainBackground`,
`Titlebar`, `Dropdown`, `Tooltip`, `MainText`, `SubText`, `Border`, `Button` and many
more. `StudioStyleGuideModifier` gives the `Hover`, `Pressed`, `Disabled` and
`Selected` variants, which is the plugin equivalent of the six-state matrix.

Hardcoding your own colours here is the plugin version of catalog tell R4 — it will
look wrong for half your users on day one.

Plugin widgets are resizable by the user, so **everything must be layout-driven**.
Fixed offsets that look right at the default size break the moment the widget is
dragged wider.
