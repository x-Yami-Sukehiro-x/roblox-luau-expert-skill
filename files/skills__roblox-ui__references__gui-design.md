# Roblox GUI — Visual Craft

Style, spacing, typography, motion, responsiveness. **Structure lives in `gui-architecture.md`** — tokens, config persistence, search, changelogs, states. Read that first when starting a new GUI; this file is what makes it look good once the bones are right.

> **No house style.** This file teaches craft and gives hard numbers. The style directions near the end are *options*, deliberately plural. Pick per project. Never default to one of them.

---

## Core rules

1. **Scale over Offset** for Size/Position so UI adapts across phone, tablet, desktop, console. Offset only for things that should not scale: hairline strokes, icon padding, minimum control heights.
2. **Mobile-first.** Design for the smallest target first, then expand. Test with Studio's Device Emulator (Test → Device) in portrait *and* landscape.
3. **Respect safe areas.** The topbar inset is not a constant, so never hardcode one — read `GuiService.TopbarInset` (a `Rect`) or `GuiService:GetInsetArea(insets)` at runtime. Choose which insets apply with `ScreenGui.ScreenInsets`, which supersedes the older boolean `IgnoreGuiInset`. Set `ClipToDeviceSafeArea` for notches and home indicators.
4. **`.Activated`, not `MouseButton1Click`.** Activated fires for mouse, touch, gamepad A, and keyboard Enter. Using the mouse-only event is the single most common reason a GUI is broken on mobile.
5. **Minimum touch target 44 px** effective size. Apple and Google both land on ~44; smaller controls get mis-tapped.
6. **Text contrast at least 4.5:1** against its background. Add a 1–2 px dark `UIStroke` on text overlaying 3D scenes.
7. **`ResetOnSpawn = false`** for persistent menus and HUDs. True only when the UI should genuinely rebuild on death.
8. **Never communicate by color alone.** Pair color state with an icon, label, or shape change.

---

## Containers

| Container | Parent | Use |
|---|---|---|
| ScreenGui | PlayerGui (or `gethui()` for executor scripts) | HUDs, menus, overlays |
| SurfaceGui | BasePart | World-space UI on parts |
| BillboardGui | BasePart / Attachment | Floating nametags, health |

```lua
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screenGui.Parent = player:WaitForChild("PlayerGui")
```

---

## Sizing, positioning, spacing

```lua
-- Responsive size, truly centred
frame.Size = UDim2.fromScale(0.85, 0.7)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)

-- Padding from tokens, never magic numbers
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, Theme.padPanel)
padding.PaddingBottom = UDim.new(0, Theme.padPanel)
padding.PaddingLeft = UDim.new(0, Theme.padPanelX)
padding.PaddingRight = UDim.new(0, Theme.padPanelX)
padding.Parent = frame

-- Vertical stack
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, Theme.gapDefault)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = frame
```

**Constraints that prevent breakage:**
- `UIAspectRatioConstraint` — stops distortion on extreme aspect ratios (ultrawide, tall phones).
- `UISizeConstraint` — min/max in pixels, so a scale-sized panel never becomes unusably small or absurdly large.
- `AutomaticSize = Enum.AutomaticSize.Y` — content-driven height instead of guessing.

**Spacing rhythm matters more than any individual value.** Pull every gap and pad from the spacing scale in `gui-architecture.md`. Mixed arbitrary values (12, 14, 15, 16) are one of the strongest tells of machine-generated UI.

---

## Typography

- Prefer modern `FontFace` over the legacy `Font` enum.
- **Use a real type scale** — title / subtitle / body / caption, on a consistent ratio. Four defined steps beat twelve ad-hoc `TextSize` values.
- `TextScaled = true` + `UITextSizeConstraint` for adaptive text. Fixed `TextSize` becomes unreadable on phones.
- **Pair intentionally:** a display face for titles, a clean readable face for body. Do not ship default SourceSans everywhere.
- **Tabular figures for numbers** that update in place — counters, timers, prices. Proportional digits make numbers jitter as they change.
- Honour `PreferredTextSize` — the player's accessibility text-size setting should feed your type tokens.

---

## Icons and images

```lua
local icon = Instance.new("ImageLabel")
icon.BackgroundTransparency = 1              -- always, on pure icons
icon.Image = "rbxassetid://1234567890"
icon.ScaleType = Enum.ScaleType.Fit
icon.Size = UDim2.fromScale(0.12, 0.12)
icon.Parent = button

-- 9-slice for scalable panels/borders
icon.ScaleType = Enum.ScaleType.Slice
icon.SliceCenter = Rect.new(10, 10, 40, 40)
```

Tint with `ImageColor3` from your tokens rather than shipping recoloured copies. Use high-resolution sources and check on high-DPI devices.

---

## Appearance modifiers

- **UICorner** — one radius language across the whole GUI. Per-corner radii are available with the newer UI capabilities for asymmetric shapes.
- **UIStroke** — thin crisp borders and text outlines. `StrokeSizingMode = ScaledSize` for responsive thickness. Keep total strokes on screen under ~300 for mobile performance.
- **UIShadow** — native drop shadows. Prefer this over the old ImageLabel-shadow hack: fewer instances, correct scaling.
- **UIGradient** — subtle depth or accent. Keep stops ≤ 6. **Animate `Offset` or `Rotation`, never rebuild `ColorSequence` per frame** — rebuilding is expensive.
- **UIPadding + UIListLayout / UIGridLayout** — never hardcode positions for lists.

---

## Input and cross-device

```lua
button.Activated:Connect(function(inputObject, clickCount)
    -- mouse, touch, gamepad A, keyboard Enter
end)
```

- `Active = true` on interactive frames.
- Full-screen modals: transparent full-size blocker Frame + `Modal = true` on focused elements.
- **Thumb zones.** On mobile, primary actions belong in the lower half where thumbs rest. Destructive actions do not belong under a resting thumb.
- Avoid dense icon-only toolbars on touch — they fail the 44 px rule and lose their tooltips.
- Test phone portrait, phone landscape, tablet, desktop, console.

---

## Motion

```lua
local TweenService = game:GetService("TweenService")
local info = TweenInfo.new(Theme.durQuick, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

TweenService:Create(panel, info, {
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 0.1,
}):Play()
```

- **0.12–0.2 s** for hover/press feedback, **0.2–0.35 s** for panels and transitions. Longer only for deliberate entrances.
- Ease out for things arriving, ease in for things leaving. Quad/Sine feel natural; Back adds character, sparingly.
- Only tweenable properties — Position, Size, transparencies, Rotation, colors. **`Text` is not tweenable.**
- **Respect `ReducedMotionEnabled`.** When set, cut durations toward zero or swap movement for a cross-fade. Wire this into your motion tokens so it is one switch, not a per-tween check.
- Every interactive element needs immediate visual feedback on press. An unresponsive-feeling button is usually a missing 120 ms tween.

---

## Performance

- **Build once, toggle `Visible`.** Destroying and recreating UI is expensive; hiding is nearly free.
- Keep hierarchies shallow — deep nesting multiplies layout computation.
- `ClipsDescendants` forces extra draw calls. Use it where needed, not by default.
- **Virtualise long lists.** Hundreds of rows should render only what fits the viewport plus a buffer, recycling instances on scroll.
- Update on a timer where a timer suffices. Once per second beats every frame for counters and stat readouts.
- Watch `AbsoluteSize` — it is zero on the first frame. Read it after `task.defer` or on the next `RenderStepped`.

---

## Structure

```
ScreenGui
└── MainContainer (centred panel or full-screen root)
    ├── Header    (title, close, search if warranted)
    ├── Nav       (tabs / sidebar)
    ├── Content   (pages or ScrollingFrame)
    └── Footer    (primary actions, status)
```

Name every meaningful instance. Use `LayoutOrder` consistently. Keep `ZIndexBehavior = Sibling`.

---

## What makes UI look AI-generated

A concrete checklist. These are the tells, in rough order of how much damage they do:

- **Uniform card grids** — everything the same size in an even grid, no hierarchy, nothing emphasised.
- **Default fonts at default sizes** — SourceSans, `TextSize = 14`, no scale.
- **One accent used everywhere** — the same blue on every button, link, border, and highlight, so nothing is actually primary.
- **Even padding with no rhythm** — the same gap between unrelated things as between related ones. Grouping should be visible in the spacing.
- **No state differentiation** — hover, active, disabled, selected all look identical or nearly so.
- **Decoration without hierarchy** — gradients, glows, and strokes applied evenly rather than to direct attention.
- **Symmetric everything** — no dominant element, no focal point, every section weighted the same.
- **Generic copy** — "Settings", "Options", "Configuration" as three separate tabs; button labels that do not say what will happen.

The fix for all of them is the same: decide what matters most on each screen and make it visibly win. Contrast in size, weight, color, and space is what reads as designed.

---

## Style directions — pick one, do not default

The token spine in `gui-architecture.md` is style-agnostic. These are sketches of directions that fit it. **They are options, not a house style.** Choose per project, and treat this list as non-exhaustive.

### Flat / editorial
High contrast, generous whitespace, strong type hierarchy, minimal ornament. Borders instead of shadows. Accent used sparingly — one or two places per screen. Reads as confident and fast. Works well for information-dense tools where clarity beats personality.

### Depth / glass
Layered translucent surfaces, soft shadows, subtle gradients suggesting elevation. Rounded, generous radii. Needs care on mobile — translucency plus many strokes gets expensive, and contrast is easy to lose. Reads as modern and premium when the contrast ratios are held.

### Brutalist / high-contrast
Hard edges or near-zero radius, heavy weights, stark color blocking, visible structure. Little or no animation. Reads as deliberate and technical. Very hard to make look generic, which is its main advantage.

### Neon / accent-driven
Dark ground, saturated accent, glow and animated gradient treatments. The direction the previous version of this file taught exclusively — see the animated-border technique below. Effective for a distinct identity; fails when the glow is applied to everything instead of to the one thing that matters.

**Whichever direction:** define the small system first — one or two accents, one radius language, one or two fonts, one elevation treatment — then apply it consistently. Consistency inside a direction is what separates designed from decorated.

---

## Gradient borders

The default build order prohibits rotating decoration and idle loops. A selected
or premium element can use a static token-driven gradient if the project's
direction calls for it; it still needs a label or marker that conveys selection.

Animate `UIGradient.Rotation` or `Offset` only for an explicitly requested effect,
with one owned tween, a hide/teardown path and a reduced-motion alternative.
Read `../../roblox-ui-motion/references/choreography.md` before implementing it.
Do not rebuild the `ColorSequence` every frame, and do not turn a request for
"polish" into permission to animate every border.

---

## Panel pattern — token-driven

Note that no color, radius, or spacing value is literal. That is the point: this same function produces any of the style directions above depending on the token table.

```lua
local function createPanel(parent)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(0.8, 0.75)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.BackgroundColor3 = Theme.surfaceRaised
    panel.BorderSizePixel = 0
    panel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Theme.radiusPanel)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = Theme.strokeThin
    stroke.Color = Theme.borderSubtle
    stroke.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, Theme.padPanel)
    padding.PaddingBottom = UDim.new(0, Theme.padPanel)
    padding.PaddingLeft = UDim.new(0, Theme.padPanelX)
    padding.PaddingRight = UDim.new(0, Theme.padPanelX)
    padding.Parent = panel

    return panel
end
```

---

## Common mistakes

- Large Offset values in layout → breaks on mobile.
- Fixed `TextSize` with no `TextScaled` → unreadable on phones.
- `MouseButton1Click` only → dead on touch and gamepad.
- Ignoring `ResetOnSpawn` → UI vanishes on death.
- Reading `AbsoluteSize` on the first frame → zero.
- Overlapping clickables without `ZIndex` / `Active` discipline.
- Heavy `UIGradient` on many objects, or rebuilding `ColorSequence` per frame.
- Hardcoded hex values scattered through widget code → makes a revamp a rewrite.
- No hover/press feedback → feels broken even when it works.

---

## Avatar preview — ViewportFrame

Standard pattern for profile cards, inventories, friend lists, avatar editors.

### Required structure

```
ViewportFrame
└── WorldModel          -- REQUIRED for Humanoid joints, accessories, animations
    └── CharacterModel
Camera (set as ViewportFrame.CurrentCamera)
```

**Never parent a Humanoid character directly under ViewportFrame** without a WorldModel — accessories and animations break, and the head can clip or disappear.

### Creating the model

**From UserId (cleanest for any player):**
```lua
local Players = game:GetService("Players")
local description = Players:GetHumanoidDescriptionFromUserIdAsync(userId)
local model = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
```

**Cloning the local character:**
```lua
local character = player.Character or player.CharacterAdded:Wait()
character.Archivable = true
local model = character:Clone()
character.Archivable = false

for _, descendant in model:GetDescendants() do
    if descendant:IsA("BaseScript") then
        descendant:Destroy()
    end
end
```

### Setup

```lua
local function createAvatarViewport(parent: Instance, userId: number?): ViewportFrame
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.Parent = parent

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport

    local camera = Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local model = buildModel(userId)   -- one of the two methods above
    if not model then return viewport end

    model.Parent = worldModel
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local head = model:FindFirstChild("Head")

    if root then
        root.CFrame = CFrame.new(0, 0, 0)
    end

    if head then
        local lookAt = head.Position
        camera.CFrame = CFrame.new(lookAt + Vector3.new(0, 0.2, -2.2), lookAt)
        camera.FieldOfView = 40      -- tighter FOV reads as a portrait
    else
        camera.CFrame = CFrame.new(0, 2, 5)
    end

    return viewport
end
```

**Full-body variant** — pull back and raise:
```lua
camera.CFrame = CFrame.new(Vector3.new(0, 1.5, 6), Vector3.new(0, 1.2, 0))
camera.FieldOfView = 50
```

### Polish and pitfalls

- **Idle animation** — load an Animation on the model's Humanoid and `:Play()` looped.
- **Slow orbit** — gently rotate the model or orbit the camera. Respect reduced motion.
- **Lighting** — set `viewport.Ambient`, `LightColor`, `LightDirection`. ViewportFrame lighting is limited: no shadows, no post-processing.
- **Cleanup** — destroy the model and camera when the GUI closes.
- **Performance** — limit simultaneous animated ViewportFrames, especially on mobile. Static poses for list items.

Pitfalls: missing WorldModel; forgetting to strip scripts from clones; camera not aimed at the Head for portraits; using `Workspace.CurrentCamera` instead of a dedicated one; forgetting `Archivable = true` before cloning.

Place the ViewportFrame inside a container using the same tokens as everything else — same radius, same stroke, same padding — so it reads as part of the design rather than bolted on.

---

## Related references
- `gui-architecture.md` — tokens, StyleSheet cascade, config persistence, search, changelogs, states
- `roblox-luau-language/references/compiler-limits.md` — large single-file GUIs hit the 200-local limit fast
- `roblox-executor/references/recon/detection-surface.md` — `gethui()` and avoiding GUI enumeration in executor contexts
