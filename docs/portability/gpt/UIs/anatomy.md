# Anatomy of the three things that go wrong

Header rows, notifications, and making them match. These are named separately
from the rest of the UI guidance because they are the three complaints that
come back after everything else has been fixed.

Numbers marked **(WindUI)** were read out of `Footagesus/WindUI` source on
2026-09-19 and are shown as evidence of what a real library does, not as a
target. Numbers marked **(use this)** are the ones to write.

---

## 1. The header row

The complaint is always "the close button is in the wrong place" or "the title
looks slightly off". Both have one cause: the two elements are positioned
independently instead of laid out together.

### What goes wrong

```lua
-- WRONG. Two absolute positions that drift apart the moment anything resizes.
title.Position = UDim2.new(0, 12, 0, 8)
close.Position = UDim2.new(1, -28, 0, 6)
close.Text = "X"
```

Three separate defects:

- **Two owners for one row.** Nothing keeps `8` and `6` in agreement, so the
  title sits two pixels high forever and nobody can say why.
- **`TextYAlignment` defaults to `Center`, but `TextLabel` height does not.** A
  title in a 44 px row with `AutomaticSize` off and `TextYAlignment = Top` is
  the "title looks off" bug in its commonest form.
- **A letter is not an icon.** `"X"` is laid out on the text baseline, so its
  optical centre is below the box centre, and its stroke weight comes from the
  font rather than from you.

### What to write

One horizontal `UIListLayout`, one `UIFlexItem` absorbing the slack, and the
close button as a sized button with a small image inside it.

```lua
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)   -- 44
header.BackgroundTransparency = 1
header.LayoutOrder = 1

local row = Instance.new("UIListLayout")
row.FillDirection = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.SortOrder = Enum.SortOrder.LayoutOrder
row.Padding = UDim.new(0, Tokens.space.snug)
row.Parent = header

local title = Instance.new("TextLabel")
title.LayoutOrder = 1
title.AutomaticSize = Enum.AutomaticSize.X
title.Size = UDim2.fromScale(0, 1)
title.TextYAlignment = Enum.TextYAlignment.Center   -- the whole bug, fixed
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1

-- The gap between title and close is an element, not a Position offset.
local slack = Instance.new("Frame")
slack.LayoutOrder = 2
slack.BackgroundTransparency = 1
local fill = Instance.new("UIFlexItem")
fill.FlexMode = Enum.UIFlexMode.Fill
fill.Parent = slack

local close = Instance.new("ImageButton")
close.LayoutOrder = 3
close.Size = UDim2.fromOffset(CLOSE_TARGET, CLOSE_TARGET)   -- 44
close.Image = ""                       -- the button draws nothing itself
close.AutoButtonColor = false
close.BackgroundTransparency = 1
```

### The measurements

| Thing | Value | Why |
|---|---|---|
| Header height | **44** (use this) | The touch target sets it. A 32 px header cannot hold a 44 px button |
| Close **button** | **44 × 44** (use this) | Apple and Google both land here; Roblox mobile has no smaller convention |
| Close **mark** inside it | **16 × 16** (use this) | 44 px of reach, 16 px of ink |
| WindUI close button | 16 × 16 icon, hit area `UDim2.new(1, 8, 1, 8)` ≈ **24 × 24** (WindUI) | Under half the target. Measurably hard to hit on a phone |
| Title size | `Tokens.text_size.emphasis` = **16** | One step above body, not the display size |
| Row padding | `Tokens.space.snug` = **8** | On the 4-scale |
| Side inset | `Tokens.space.base` = **12** | `UIPadding` on the header, not a Position offset |

**Order matters more than alignment.** `LayoutOrder` 1 title, 2 slack, 3 close.
Once the row owns the positions, "the close button moved" becomes impossible.

---

## 2. The notification

### Anatomy

| Part | Value | Source |
|---|---|---|
| Width | 320 cap, 240 floor, scale-sized between | `Tokens.toast` (use this) |
| WindUI width | fixed `UDim2.new(0, 300, …)` (WindUI) | fixed, so it overruns a narrow phone |
| Corner radius | `Tokens.radius.panel` = 10 | same radius as the panel it belongs to |
| WindUI radius | 18 (WindUI) | their panel radius, consistently applied — the principle is right, the value is theirs |
| Inner padding | 12 | `Tokens.space.base` |
| Gap between toasts | 8 | `Tokens.space.snug` |
| Anchor | bottom-right, inset 16 | out of the way of a game's own HUD |
| Minimum hold | **1.5 s, timed from arrival** | below this it is a flicker; the linter fails `E-TOASTFAST` |
| Default hold | 4 s, +1 s per 120 characters | reading speed, not a round number |
| Icon | 16 or 20, never a letter | `Icons.triangleAlert`, `Icons.check`, `Icons.info` |

### Severity must not be colour alone

```lua
-- WRONG: a red toast and a green toast are the same toast to ~8% of men.
toast.BackgroundColor3 = isError and Tokens.status.danger or Tokens.status.success
```

Every severity carries a **glyph and a word** as well as a hue. That is
`library/src/Toast.luau`'s `SEVERITY` table, and it is why the UI linter's "no
information by colour alone" gate passes on it.

### Stacking

New toast enters at the bottom, existing ones move up. The timer starts when the
toast **arrives**, not when it was queued — a toast that spent 3 seconds behind
two others and then shows for 1.5 has been on screen for 1.5 seconds, which is
the number that matters.

Pause the timer on hover. Resume on leave. A toast that vanishes while being
read is worse than one that lingers.

---

## 3. Making the notification match the UI

This is the one the rejected libraries cannot do, and the reason is structural
rather than aesthetic.

### Why it fails

A flat theme table gives every component a colour directly:

```lua
-- The Kavo/Orion/Rayfield shape.
Theme = { Background = Color3.fromRGB(30, 30, 30), Accent = Color3.fromRGB(0, 120, 255) }

panel.BackgroundColor3 = Theme.Background
toast.BackgroundColor3 = Color3.fromRGB(35, 35, 35)   -- someone eyeballed it
```

`35, 35, 35` was chosen once, by eye, to look right next to `30, 30, 30`. When
the theme changes, the panel follows and the toast does not. **Nothing in the
code says they were meant to be related**, so nothing can keep them related.

### The fix: one entry decides a height, not two call sites

A toast and a panel are **peers** — both float above the page. So one token
entry decides what "floating" looks like, and both read it:

```lua
-- Tokens.luau, the only place either value exists.
Tokens.surface.overlay   = PRIMITIVE.neutral[4]   -- the floating fill
Tokens.stroke.base       = PRIMITIVE.neutral[4]
Tokens.elevation.floating = { blur = 18, offset = 6, transparency = 0.75 }
Tokens.radius.panel      = UDim.new(0, 10)
```

```lua
-- Both read the same four values. They cannot drift.
panel.BackgroundColor3 = Tokens.surface.overlay
toast.BackgroundColor3 = Tokens.surface.overlay
panelCorner.CornerRadius = Tokens.radius.panel
toastCorner.CornerRadius = Tokens.radius.panel
```

### The test

Change `PRIMITIVE.neutral[4]` to something absurd — bright magenta. Run the
interface. **Every surface at that height must turn magenta together.** Anything
that stays dark was carrying its own literal, and that is the thing that was
going to drift.

If the project already has a palette, take the four values from it and delete
your own. If the user names a colour, it becomes the accent, and the neutrals do
not move.

### Accent is not decoration

One accent, used three to five times in the whole interface: the primary action,
the selected tab, the focus ring. A toast is **not** an accent surface — its
severity hue lives on a 3 px left edge or the icon, and its fill stays neutral.
A fully-tinted toast competes with the game behind it and with the panel beside
it.

---

## Checking it rather than believing it

```bash
node tools/bin/lint-roblox-ui.mjs src/UI/Panel.luau
python tools/py/ui_lint.py src/UI/Panel.luau       # the same rubric, no Node
python tools/py/roblox_lint.py src/UI/Panel.luau
```

And when the request was "redesign it", prove the redesign happened:

```bash
node tools/bin/lint-roblox-ui.mjs --compare old/Panel.luau new/Panel.luau
```

If that prints `0 of them structural`, the layout, type scale and palette are
identical and the word "redesign" is not available to you.
