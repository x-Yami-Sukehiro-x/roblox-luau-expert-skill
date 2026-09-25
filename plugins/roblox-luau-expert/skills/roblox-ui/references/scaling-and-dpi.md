# Scaling, viewports and DPI

Scale-versus-offset answers *how a frame relates to its parent*. It does not
answer *how big the whole interface should be on this screen*. Those are
different problems and conflating them is why UI that "uses scale everywhere"
still looks wrong on a phone and comically small on a 4K monitor.

- **Scale vs offset** — layout within a parent. See `responsive-and-surfaces.md`.
- **This file** — the global size of the interface itself.

---

## The one control you actually have

`UIScale.Scale` multiplies a subtree's size *and* its offset values, including
`UIPadding`, `UICorner` radii and `UIStroke.Thickness` when they are in offset.
That is the only sanctioned way to resize an entire interface as a unit.

```lua
local scaler = Instance.new("UIScale")
scaler.Scale = 1
scaler.Parent = root          -- one per ScreenGui, at the top
```

Put **one** `UIScale` at the root of each `ScreenGui` and drive it. Do not
sprinkle them: nested `UIScale` instances multiply, and tracking down why a
button is 0.72x its intended size across three ancestors is miserable.

> `UIScale` is also the cheapest thing to animate — it does not touch layout the
> way tweening `Size` does. `roblox-ui-motion` uses it for press feedback.

---

## What is NOT available to you

Several `GuiService` members look like exactly the API you want and are
`{RobloxScript}` — CoreScript only. A `LocalScript` calling one errors:

| Member | Status |
|---|---|
| `GuiService:GetResolutionScale()` | `RobloxScript` — unreachable |
| `GuiService:GetRawScreenScale()` | `RobloxScript` — unreachable |
| `GuiService:GetEffectiveUIScaleHundredths()` | `RobloxScript` — unreachable |
| `GuiService:SetUIScaleMultiplier()` | `RobloxScript` — unreachable |
| `GuiService.DisplayScalingMode` | `RobloxScript` — unreachable |
| `CanvasGroup.ResolutionScale` | `RobloxScript` — unreachable |

Guides that recommend these are describing the CoreGui implementation, not
something your game can call. Verify with
`node tools/bin/verify-api.mjs GuiService.GetResolutionScale` before believing
any of them.

**What you do get**, all readable from a normal `LocalScript`:

| Member | Type | Use |
|---|---|---|
| `Camera.ViewportSize` | `Vector2` | The real pixel viewport. The input to everything below |
| `GuiService.ViewportDisplaySize` | `Enum.DisplaySize` | `Small` / `Medium` / `Large` — a coarse device bucket |
| `GuiService:IsTenFootInterface()` | `boolean` | Console on a TV. Sit-back distance, not screen size |
| `GuiService.PreferredTextSize` | `Enum.PreferredTextSize` | `Medium` / `Large` / `Larger` / `Largest` — the player's accessibility setting |
| `GuiService.TopbarInset` | `Rect` | Exact reserved area at the top |
| `GuiService:GetInsetArea(insets)` | `Rect` | The area a given `Enum.ScreenInsets` mode leaves you |

---

## The reference-viewport formula

Design against one reference resolution, then scale by how far the real viewport
departs from it. This is the whole technique.

```lua
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local REFERENCE = Vector2.new(1280, 720)   -- what the design was drawn at
local MIN_SCALE, MAX_SCALE = 1, 1.6

local camera = workspace.CurrentCamera

local function computeScale(): number
    local viewport = camera.ViewportSize

    -- Fit on BOTH axes: taking the larger ratio would overflow the short edge.
    local raw = math.min(viewport.X / REFERENCE.X, viewport.Y / REFERENCE.Y)

    -- A tall phone reports a small X ratio and would shrink everything to
    -- unreadability. Bias toward the height on portrait aspect ratios.
    if viewport.X < viewport.Y then
        raw = viewport.Y / REFERENCE.Y * 0.75
    end

    return math.clamp(raw, MIN_SCALE, MAX_SCALE)
end

local function apply()
    scaler.Scale = computeScale()
end

apply()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
```

Three things make this correct rather than a formula someone pasted:

- **`math.min` of the two ratios, not `max`.** Taking the larger one overflows
  the short edge, which is how UI ends up cropped in landscape on a tablet.
- **Clamps at both ends, and the bottom clamp is 1.** Unclamped, a 4K monitor
  gets 3x UI and an old phone gets 0.4x. A floor below 1 is the same mistake
  made quietly: at 0.7, 12 px text renders at 8.4 px and a 44 px button at
  31 px on every phone. Let `UIScale` grow the interface on large screens and
  let scale sizes with a `UISizeConstraint` fit the phone
  (`../../roblox-ui-viewport/SKILL.md`); `python tools/py/viewport_fit.py`
  prints both numbers per device.
- **Reacts to `ViewportSize`, not to a one-time read at startup.** Players
  resize windows, rotate phones, and open Studio's device emulator.

---

## Do not scale text with the interface

Scaling type by viewport is not the same as respecting the player's text-size
setting, and only one of those is accessibility.

`GuiService.PreferredTextSize` is `[ReadOnly]` and reflects a system setting the
player chose deliberately. Honour it *on top of* your layout scale:

```lua
local TEXT_MULTIPLIER = {
    [Enum.PreferredTextSize.Medium] = 1.0,
    [Enum.PreferredTextSize.Large] = 1.15,
    [Enum.PreferredTextSize.Larger] = 1.3,
    [Enum.PreferredTextSize.Largest] = 1.5,
}

local function textScale(): number
    return TEXT_MULTIPLIER[GuiService.PreferredTextSize] or 1
end

GuiService:GetPropertyChangedSignal("PreferredTextSize"):Connect(rebuildType)
```

If your layout cannot survive text 50% larger, the layout is the defect. Use
`AutomaticSize` on the containers that hold text so they grow rather than clip.

---

## Device buckets, and when they are the wrong tool

`GuiService.ViewportDisplaySize` gives `Small` / `Medium` / `Large`. It is a
reasonable switch for **layout shape** — one column versus three — and a bad one
for **sizing**, because a "Large" bucket spans a laptop and a 4K display.

```lua
-- Right: pick a layout for the bucket, a scale from the viewport.
local columns = if GuiService.ViewportDisplaySize == Enum.DisplaySize.Small then 1 else 3

-- Wrong: sizing from the bucket, which quantises a continuous problem.
local padding = if GuiService.ViewportDisplaySize == Enum.DisplaySize.Small then 8 else 24
```

`GuiService:IsTenFootInterface()` is a different axis entirely. It reports a
console rendering to a television, where the player is metres away. Ten-foot UI
needs **larger type and bigger touch-equivalent targets even though the screen is
huge** — the opposite of what a viewport-size heuristic would conclude.

---

## Insets: the topbar is not 36 pixels

Two numbers circulate for the Roblox topbar and both are quoted as fact. Neither
is safe to hardcode: it varies by client, platform and version.

```lua
local inset = GuiService.TopbarInset          -- a Rect, exact, ReadOnly
local usableTop = inset.Max.Y

-- Or ask what a given inset mode leaves you:
local area = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
```

Prefer letting the engine do it. Set `ScreenGui.ScreenInsets` and the engine
positions your content inside the safe region:

| `Enum.ScreenInsets` | Meaning |
|---|---|
| `None` | Full bleed. You are responsible for everything |
| `DeviceSafeInsets` | Avoid notches, home indicators, rounded corners |
| `CoreUISafeInsets` | Also avoid the Roblox topbar and controls |
| `TopbarSafeInsets` | Topbar only |

`ScreenGui.IgnoreGuiInset` is the older boolean. It still works, but it is a single
on/off switch where `ScreenInsets` selects *which* insets apply, so it cannot
express "avoid the notch but not the topbar". Prefer `ScreenInsets` in new code.

> `[LoadOnly]` is a **serialization** flag, not a scriptability one: the property is
> read from the file format and not written back. It says nothing about whether a
> script can assign it — `Instance.Parent` carries the same flag. In practice it
> marks a legacy property kept for file compatibility and superseded by a newer
> one, which is the reason to prefer the successor.

Add `ScreenGui.ClipToDeviceSafeArea` when content must not bleed under a notch
even visually.

React to changes rather than measuring once:

```lua
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(reflow)
```

> `GuiService.SafeZoneOffsetsChanged` is the event most guides name here. It is
> `{RobloxScript}` — a normal LocalScript cannot connect to it.

---

## Testing

Studio's Device Emulator (**Test → Device**) is the only cheap way to see this
working. The presets worth checking, in order of how often they break things:

1. A small phone in **portrait** — the tightest constraint, and the one most
   designs are never tested against.
2. The same phone in **landscape** — different aspect, virtual controls now in
   the corners you were using.
3. A tablet — where `math.max` bugs surface.
4. Console / ten-foot — where type set for a monitor becomes unreadable.

---

## Checklist

- [ ] Exactly one `UIScale` per `ScreenGui`, at the root.
- [ ] Scale derived from `Camera.ViewportSize`, clamped at both ends.
- [ ] Recomputed on `ViewportSize` change, not read once at startup.
- [ ] `ScreenInsets` set; no hardcoded topbar height anywhere.
- [ ] `PreferredTextSize` honoured, and the layout survives `Largest`.
- [ ] Device bucket used for layout shape, viewport for sizing.
- [ ] Ten-foot checked separately from screen size.
- [ ] No call to any `{RobloxScript}` scale API.
