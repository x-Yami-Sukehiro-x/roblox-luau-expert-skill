# Blueprints

Complete recipes for the surfaces that get built over and over. Every number is
stated. Assemble from these rather than inventing a layout — inventing is where
the uniform card grid comes from.

Each blueprint gives the instance tree, a property table, and working code. The
code assumes the token values from `design-directions.md`; the constants at the
top of each block are the Slate direction inlined so the blocks stand alone. In
a real project those come from `library/src/Tokens.luau` instead.

Order of use: `build-order.md` first for the procedure, this file for the shape,
`self-review.md` before delivery.

---

## B1 · The root scaffold

Every menu, shop, settings screen and hub starts here. Header / body / footer,
with the body absorbing whatever is left.

```
ScreenGui                    ResetOnSpawn = false, ScreenInsets = CoreUISafeInsets
└── Root            Frame    fromScale(0.5, 0.65), Anchor 0.5, UISizeConstraint 300..720 / 320..820
    ├── UIPadding            16 on all sides
    ├── UIListLayout         Vertical, Padding 12, SortOrder LayoutOrder
    ├── Header      Frame    LayoutOrder 1, height 44 offset
    ├── Body        Frame    LayoutOrder 2, UIFlexItem FlexMode = Fill
    └── Footer      Frame    LayoutOrder 3, height 44 offset
```

| Property | Value | Why |
|---|---|---|
| `Root.Size` | `UDim2.fromScale(0.5, 0.65)` | grows with the screen |
| `Root.AnchorPoint` | `Vector2.new(0.5, 0.5)` | centres without arithmetic |
| `UISizeConstraint.MinSize` | `Vector2.new(300, 320)` | still usable on a 390 px phone |
| `UISizeConstraint.MaxSize` | `Vector2.new(720, 820)` | not absurd on ultrawide |
| `Header` height | `44` offset | matches the minimum touch target |
| `Body` | `UIFlexItem` `FlexMode = Fill` | no height arithmetic anywhere |

```lua
local Players = game:GetService("Players")

local SURFACE_PAGE = Color3.fromRGB(9, 10, 13)
local SURFACE_BASE = Color3.fromRGB(31, 34, 41)
local TEXT_PRIMARY = Color3.fromRGB(243, 245, 248)
local PAD_PANEL = 16
local GAP_BASE = 12
local ROW_HEIGHT = 44

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screenGui.Enabled = false

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundColor3 = SURFACE_BASE
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(0.5, 0.65)
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Parent = screenGui

local bounds = Instance.new("UISizeConstraint")
bounds.MinSize = Vector2.new(300, 320)
bounds.MaxSize = Vector2.new(720, 820)
bounds.Parent = root

local corner = Instance.new("UICorner")
corner.TopLeftRadius = UDim.new(0, 10)
corner.TopRightRadius = UDim.new(0, 10)
corner.BottomLeftRadius = UDim.new(0, 10)
corner.BottomRightRadius = UDim.new(0, 10)
corner.Parent = root

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, PAD_PANEL)
padding.PaddingBottom = UDim.new(0, PAD_PANEL)
padding.PaddingLeft = UDim.new(0, PAD_PANEL)
padding.PaddingRight = UDim.new(0, PAD_PANEL)
padding.Parent = root

local stack = Instance.new("UIListLayout")
stack.FillDirection = Enum.FillDirection.Vertical
stack.SortOrder = Enum.SortOrder.LayoutOrder
stack.Padding = UDim.new(0, GAP_BASE)
stack.Parent = root

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
header.LayoutOrder = 1
header.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
title.TextSize = 20
title.TextColor3 = TEXT_PRIMARY
title.Text = "Shop"
title.Parent = header

local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundColor3 = SURFACE_PAGE
body.BorderSizePixel = 0
body.Size = UDim2.fromScale(1, 0)
body.LayoutOrder = 2
body.Parent = root

-- Fill takes whatever the header and footer leave, so no height is computed.
local flex = Instance.new("UIFlexItem")
flex.FlexMode = Enum.UIFlexMode.Fill
flex.Parent = body

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.BackgroundTransparency = 1
footer.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
footer.LayoutOrder = 3
footer.Parent = root

screenGui.Parent = player:WaitForChild("PlayerGui")
```

**The one thing that makes this reusable:** the body's height is never
calculated. `UIFlexItem` with `FlexMode = Fill` means adding a subtitle to the
header cannot break the layout.

---

## B1a · The header row — title and close

The inside of B1's `Header`. It is four instances and it is got wrong more
often than anything else in a panel, always the same three ways.

```
Header          Frame    LayoutOrder 1, UISizeConstraint pins height to 44
├── UIListLayout         Horizontal, VerticalAlignment Center, Padding 8, SortOrder LayoutOrder
├── Title       TextLabel   LayoutOrder 1, UIFlexItem Fill, TextXAlignment Left, TextYAlignment Center
└── Close       ImageButton LayoutOrder 2, UISizeConstraint pins 44 x 44
    └── Glyph   ImageLabel  16 x 16, AnchorPoint 0.5, Position fromScale(0.5, 0.5)
```

### One owner per number

Every size in that tree is decided by exactly one thing. This is the rule the
`L1` rubric row counts, and it is why the tree has no `fromScale` in it at all.

| Number | Decided by | So do not also set |
|---|---|---|
| Header height, 44 | its `UISizeConstraint` | a `Size` scale on Y |
| Title width | the `UIFlexItem` `Fill` | a `Size` scale on X |
| Close width and height, 44 | its `UISizeConstraint` | a `Size` scale at all |
| The 8 px between them | `UIListLayout.Padding` | a `UIPadding`, or a margin frame |
| Glyph position | `AnchorPoint` + `Position` 0.5 | a `UIPadding` on the button |

If two things could decide a number, one of them is going to be wrong later and
nobody will know which. `Size = UDim2.fromScale(0.16, 1)` on a button pinned to
44 × 44 is not harmless — it is a reader's first guess about how wide the
button is, and it is false.

### The three failures

**1. The title sits high.** The row centres its children, and then the title
sets `TextYAlignment = Enum.TextYAlignment.Top`. The label's *box* is centred;
its *text* is pinned to the top of that box. In a 44 px row with 16 px type
that is about 14 px of drift, and it reads as a bug without looking like one.

> Inside a row the layout centres, text is centred too. `TextYAlignment.Top`
> belongs in a multi-line block, not in a header.

**2. The close button is a glyph.** `Text = "×"` lands on the maths axis rather
than the optical centre, and its weight comes from the font.
`roblox-ui-components/references/icons.md` has the id and the 44-with-16-inside
pattern.

**3. The close button is 28 px.** The visual can be 28. The **button** is 44,
with the visual centred inside it. Shrinking the hit area to match the art is
the single most common touch-target failure, and it is invisible on a mouse.

### The tree

```lua
local header = Instance.new("Frame")
header.Name = "Header"
header.LayoutOrder = 1
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
header.Parent = root

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerLayout.Padding = UDim.new(0, 8)
headerLayout.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 1
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamMedium
title.Text = "Settings"
title.TextColor3 = TEXT_PRIMARY
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.Parent = header

local titleFlex = Instance.new("UIFlexItem")
titleFlex.FlexMode = Enum.UIFlexMode.Fill
titleFlex.Parent = title

local close = Instance.new("ImageButton")
close.Name = "Close"
close.LayoutOrder = 2
close.AutoButtonColor = false
close.BackgroundTransparency = 1
close.Image = ""
close.Parent = header

local closeBounds = Instance.new("UISizeConstraint")
closeBounds.MinSize = Vector2.new(ROW_HEIGHT, ROW_HEIGHT)
closeBounds.MaxSize = Vector2.new(ROW_HEIGHT, ROW_HEIGHT)
closeBounds.Parent = close

local closeGlyph = Instance.new("ImageLabel")
closeGlyph.BackgroundTransparency = 1
closeGlyph.Image = Icons.x
closeGlyph.ImageColor3 = TEXT_SECONDARY
closeGlyph.Size = UDim2.fromOffset(16, 16)
closeGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
closeGlyph.Position = UDim2.fromScale(0.5, 0.5)
closeGlyph.Parent = close
```

`close.Size` is never set. The constraint decides it, the layout places it, and
there is no second number to contradict the first.

### Escape closes it

A panel with a close button and no keyboard path is unfinished. One binding,
torn down with the panel:

```lua
local ContextActionService = game:GetService("ContextActionService")

ContextActionService:BindAction("ClosePanel", function(_, state)
    if state == Enum.UserInputState.Begin then
        dismiss()
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
```

Unbind it in the same teardown that destroys the `ScreenGui`, or the next panel
inherits it.

---

## B2 · Settings row

The unit a settings screen is made of. Label on the left, control on the right,
optional description under the label.

```
Row              Frame     height 44 offset (56 with a description)
├── UIPadding              left 12, right 12
├── UIListLayout           Horizontal, VerticalAlignment Center, Padding 12
├── Text        Frame      UIFlexItem FlexMode = Fill
│   ├── Label   TextLabel  TextSize 14
│   └── Hint    TextLabel  TextSize 12, muted, optional
└── Control     Frame      fixed width, LayoutOrder 2
```

| Property | Value |
|---|---|
| Row height | `44`, or `56` when a hint is present |
| Row gap | `8` between rows in a group |
| Group gap | `24` between groups |
| Label size | `14` |
| Hint size | `12`, muted colour |
| Control width | `72` for a toggle, `160` for a slider, `140` for a dropdown |

```lua
-- lint: fragment
local function settingsRow(labelText: string, hintText: string?): Frame
    local row = Instance.new("Frame")
    row.Name = "Row"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, if hintText then 56 else 44)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = row

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 12)
    layout.Parent = row

    local text = Instance.new("Frame")
    text.Name = "Text"
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(0, 1)
    text.LayoutOrder = 1
    text.Parent = row

    local fill = Instance.new("UIFlexItem")
    fill.FlexMode = Enum.UIFlexMode.Fill
    fill.Parent = text

    local textStack = Instance.new("UIListLayout")
    textStack.FillDirection = Enum.FillDirection.Vertical
    textStack.VerticalAlignment = Enum.VerticalAlignment.Center
    textStack.SortOrder = Enum.SortOrder.LayoutOrder
    textStack.Padding = UDim.new(0, 4)
    textStack.Parent = text

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Size = UDim2.fromScale(1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(243, 245, 248)
    label.Text = labelText
    label.LayoutOrder = 1
    label.Parent = text

    if hintText then
        local hint = Instance.new("TextLabel")
        hint.Name = "Hint"
        hint.BackgroundTransparency = 1
        hint.AutomaticSize = Enum.AutomaticSize.Y
        hint.Size = UDim2.fromScale(1, 0)
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
        hint.TextSize = 12
        hint.TextColor3 = Color3.fromRGB(118, 125, 139)
        hint.Text = hintText
        hint.LayoutOrder = 2
        hint.Parent = text
    end

    return row
end
```

The 4 px gap between label and hint against the 8 px gap between rows is what
makes the pair read as one thing. Equal gaps there is catalog tell R6, and it is
the most common spacing mistake in settings screens specifically.

---

## B3 · Scrolling list with an empty state

Every list. The empty state is a sibling, not a special case inside the loop —
that is what stops it being forgotten.

```
Body             Frame
├── List         ScrollingFrame   AutomaticCanvasSize Y, ScrollBarThickness 4
│   ├── UIListLayout              Vertical, Padding 8
│   └── UIPadding                 8 on all sides
└── Empty        Frame            Visible = false, centred message
```

| Property | Value |
|---|---|
| `AutomaticCanvasSize` | `Enum.AutomaticSize.Y` — never set `CanvasSize` by hand |
| `ScrollBarThickness` | `4` |
| `ScrollBarImageTransparency` | `0.5` |
| `ElasticBehavior` | `Enum.ElasticBehavior.WhenScrollable` |
| Row gap | `8` |
| Virtualise above | ~200 rows. Below that, pooling is enough |

```lua
-- lint: fragment
local function buildList(parent: Frame): (ScrollingFrame, Frame)
    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Size = UDim2.fromScale(1, 1)
    list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollBarThickness = 4
    list.ScrollBarImageTransparency = 0.5
    list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    list.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = list

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = list

    local empty = Instance.new("TextLabel")
    empty.Name = "Empty"
    empty.BackgroundTransparency = 1
    empty.Size = UDim2.fromScale(1, 1)
    empty.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
    empty.TextSize = 14
    empty.TextColor3 = Color3.fromRGB(150, 157, 170)
    empty.TextWrapped = true
    empty.Text = "Nothing here yet. Complete a round to earn your first crate."
    empty.Visible = false
    empty.Parent = parent

    return list, empty
end
```

**Write the empty copy for this specific list.** "No items" is the generic
version and it tells the player nothing. Say why it is empty and what fills it.

---

## B4 · Item grid

Shops and inventories. The cell count adapts to width instead of being fixed,
which is what stops a six-across grid becoming one-across-and-cut-off on a phone.

```
Grid             ScrollingFrame
├── UIGridLayout                CellSize computed, CellPadding 12
└── UIPadding                   12 on all sides
```

| Width | Columns | Cell |
|---|---|---|
| under 420 | 2 | square |
| 420 to 700 | 3 | square |
| over 700 | 4 | square |

```lua
-- lint: fragment
local COLUMN_GAP = 12

local function relayout(grid: ScrollingFrame, layout: UIGridLayout)
    local width = grid.AbsoluteSize.X
    if width <= 0 then
        return -- first frame: AbsoluteSize is not populated yet
    end

    local columns = if width < 420 then 2 elseif width < 700 then 3 else 4
    local usable = width - COLUMN_GAP * (columns + 1)
    local cell = math.floor(usable / columns)

    layout.CellPadding = UDim2.fromOffset(COLUMN_GAP, COLUMN_GAP)
    layout.CellSize = UDim2.fromOffset(cell, cell)
end
```

Call `relayout` on creation and from `GetPropertyChangedSignal("AbsoluteSize")`.
Read `AbsoluteSize` after `task.defer` on the first pass — it is zero on the
frame the instance is created.

The per-cell content, top to bottom: icon at 60% of the cell, name at 14, price
at 12 in the accent, state badge top-right. Owned and unaffordable states change
the badge and the price colour, never only the border.

---

## B5 · Confirm modal

One at a time, blocking, dismissible by three routes: the cancel button, the
scrim, and Escape.

```
Modal            Frame     full screen, ZIndex above everything
├── Scrim        TextButton  full screen, black at 0.5, Text = "", absorbs clicks
└── Dialog       Frame     fromOffset(360, 200), Anchor 0.5, overlay surface
    ├── Title    TextLabel   TextSize 20
    ├── Message  TextLabel   TextSize 14, wrapped
    └── Actions  Frame       Horizontal, HorizontalFlex SpaceBetween
```

| Property | Value |
|---|---|
| Scrim colour | black at `BackgroundTransparency = 0.5` |
| Dialog size | `UDim2.fromOffset(360, 200)`, with a `UISizeConstraint` max of screen minus 32 |
| Enter motion | scale `0.96` to `1` plus fade, 0.20 s Cubic Out |
| Exit motion | 0.15 s Cubic In |
| Focus | the **safe** action, never the destructive one |
| Escape | closes, equivalent to cancel |

```lua
-- lint: fragment
local ContextActionService = game:GetService("ContextActionService")

local function bindEscape(modal: Frame, close: () -> ())
    ContextActionService:BindAction("CloseModal", function(_, state)
        if state == Enum.UserInputState.Begin then
            close()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.Escape)

    modal.Destroying:Once(function()
        ContextActionService:UnbindAction("CloseModal")
    end)
end
```

**Gamepad selection must be trapped inside the dialog.** Set
`GuiObject.NextSelectionUp` and its siblings so the focus cannot walk out to the
menu behind, and restore the previous selection on close.

---

## B6 · Tab bar

Tabs above a page container. The state change is a colour *and* a shape change,
because colour alone is not a signal everyone receives.

```
TabBar           Frame     height 44
├── Row          Frame     fills the bar
│   ├── UIListLayout       Horizontal, Padding 4
│   └── Tab      TextButton  AutomaticSize X, min width 88
└── Indicator    Frame     height 2, anchored bottom, accent, one for the whole bar
```

The indicator is a sibling of `Row`, not a child of it or of a tab. A
`UIListLayout` places every sibling it manages and ignores their `Position`, so
an indicator inside the layout cannot slide, and one per tab can only blink.

| Property | Value |
|---|---|
| Bar height | `44` |
| Tab min width | `88` |
| Tab gap | `4` |
| Selected | accent text, indicator under it, `GothamBold` |
| Unselected | secondary text, `GothamMedium` |
| Switch motion | indicator slides, 0.20 s Cubic Out. Page cross-fades, no slide |

The picker's S1–S12 styles and a tested implementation are in
`../../roblox-ui-components/references/style-recipes.md`.

Pages: build all of them once, toggle `Visible`. Rebuilding a page on every tab
switch is a per-switch allocation spike and loses scroll position.

More than five tabs means the structure is wrong — group them, or use a sidebar.

---

## B7 · HUD element

Drawn over live gameplay, so the rules change: no scrim, no blocking input,
readable against anything.

| Property | Value |
|---|---|
| Parent | its own `ScreenGui` with a lower `DisplayOrder` than menus |
| `Active` | `false` on every non-interactive frame, so clicks reach the world |
| Text | a 1–2 px dark `UIStroke` on anything over the 3D scene |
| Position | corners and edges; the centre belongs to the game |
| Update rate | on change, or throttled to about 10 Hz. Never per frame for a number |
| Safe area | `ScreenInsets = CoreUISafeInsets`, plus `ClipToDeviceSafeArea` |

```lua
-- lint: fragment
local function healthBar(parent: Frame, humanoid: Humanoid): Frame
    local track = Instance.new("Frame")
    track.Name = "HealthTrack"
    track.BackgroundColor3 = Color3.fromRGB(19, 21, 26)
    track.BorderSizePixel = 0
    track.Size = UDim2.fromOffset(180, 10)
    track.Active = false
    track.Parent = parent

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.fromRGB(72, 178, 112)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(1, 1)
    fill.Active = false
    fill.Parent = track

    local function refresh()
        local maximum = math.max(humanoid.MaxHealth, 1)
        local ratio = math.clamp(humanoid.Health / maximum, 0, 1)
        fill.Size = UDim2.fromScale(ratio, 1)
    end

    humanoid.HealthChanged:Connect(refresh)
    refresh()

    return track
end
```

The bar is driven by `HealthChanged`, not by a loop. A HUD that polls every frame
is the most common avoidable cost in a Roblox client.

---

## B8 · Mobile sheet

The phone-shaped alternative to a centred panel. Slides up from the bottom,
covers most of the screen, dismissed by a drag or a tap outside.

| Property | Value |
|---|---|
| Height | `UDim2.fromScale(1, 0.72)` |
| Anchor | `Vector2.new(0.5, 1)` at `UDim2.fromScale(0.5, 1)` |
| Corners | top two only — set `TopLeftRadius` and `TopRightRadius`, leave the bottom at zero |
| Grab handle | 36 × 4 pill, centred, 8 from the top |
| Enter | spring on the Y offset, not a tween — the drag can interrupt it |
| Bottom padding | `24` plus the device inset, or the home indicator sits on the last row |

Use a sheet when `UserInputService.TouchEnabled` is true and the viewport is
narrower than about 500 px. Use the centred panel otherwise. One layout that
tries to be both is worse than two that each commit.

---

## B9 · Executor hub

Same craft, different constraints. Detailed in
`../../roblox-executor/references/ui/ui-libraries.md`; the layout facts:

| Property | Value |
|---|---|
| Parent | `gethui()` when available, else `CoreGui`, else `PlayerGui` — feature-detect |
| Size | `UDim2.fromOffset(560, 380)`, draggable, with a `UISizeConstraint` |
| Persistence | write the config to a file so toggles survive re-execution |
| Unload | one button that disconnects everything and destroys the GUI |
| Re-execution | namespace state under `getgenv()` and detect an existing instance |
| Mobile | usable at 360 px wide — a meaningful share of executor users are on phones |

A hub that cannot unload cleanly forces a rejoin, which is the most common
complaint about script UIs and the easiest to prevent.

---

## Picking a blueprint

| The request | Start from |
|---|---|
| menu, settings, shop, inventory, any panel | B1, then B2 or B3 or B4 |
| a list of anything | B3 |
| a grid of items | B4 |
| "are you sure" | B5 |
| more than one page of content | B6 |
| health, ammo, currency, objective on screen | B7 |
| phone-first, or the panel feels cramped on mobile | B8 |
| executor script UI | B9 |

Two blueprints at once is normal. A shop is B1 for the frame, B4 for the grid,
B5 for the purchase confirm and B3 for the owned-items tab.
