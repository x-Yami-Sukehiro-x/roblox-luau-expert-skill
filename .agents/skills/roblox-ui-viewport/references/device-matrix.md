# Device matrix

The profiles `tools/py/viewport_fit.py` computes, and what to look at on each
when opening it in Studio. Viewport sizes are what `Camera.ViewportSize`
reports; the usable area is after `ScreenInsets = CoreUISafeInsets`.

## Profiles

| Profile | Viewport | Usable (approx.) | Input | Notes |
|---|---|---|---|---|
| small phone, landscape | 640 x 360 | 640 x 302 | touch | the fit target for `MinSize`: 640 x 300 |
| iPhone SE, landscape | 667 x 375 | 667 x 317 | touch | no notch |
| notched phone, landscape | 844 x 390 | 750 x 311 | touch | about 47 px of safe area on each long side, 21 px at the bottom |
| phone, portrait | 390 x 844 | 390 x 705 | touch | only when `StarterGui.ScreenOrientation` allows portrait |
| tablet, landscape | 1024 x 768 | 1024 x 710 | touch | scale sizes look oversized; cap with `MaxSize` |
| laptop | 1366 x 768 | 1366 x 710 | mouse | shorter than a 720 design |
| 1080p monitor | 1920 x 1080 | 1920 x 1022 | mouse | the common desktop |
| 1440p monitor | 2560 x 1440 | 2560 x 1382 | mouse | offset-only UI starts to look small |
| ultrawide | 3440 x 1440 | 3440 x 1382 | mouse | width-scaled panels stretch |
| 4K monitor | 3840 x 2160 | 3840 x 2102 | mouse | unbounded UI is absurd; offset UI is tiny |
| console on a TV | 1920 x 1080 | 1920 x 1022 | gamepad | `GuiService:IsTenFootInterface()`; read from metres away |

The insets are approximations: the topbar height and safe areas vary by
client, platform and version. For exact numbers read
`GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)` in the emulator,
and never hardcode them in the game: `ScreenInsets` places content for you.

## Opening each in Studio

**Test → Device** picks an emulated device and orientation. For each profile
that matters to the game, check in this order:

1. **The smallest phone in landscape.** The whole panel on screen, the
   primary action visible without scrolling, nothing under the thumbstick
   (bottom left) or the jump button (bottom right).
2. **The notched phone.** Nothing under the notch on either long side.
3. **Portrait**, if the game allows it. Rows wrap or stack rather than
   squeezing labels to one letter.
4. **A 1080p and a 4K window.** Panels capped by `MaxSize`, type not
   microscopic, nothing stretched across the whole width.
5. **The TV.** Focus visible on the first control when the menu opens;
   everything reachable with the D-pad.

Then open the states that draw outside the resting layout: every dropdown
open, the longest label, an error toast, the longest list scrolled to the end.

## Choosing sizes that pass

| Element | Size | Bounds |
|---|---|---|
| main menu or hub panel | `fromScale(0.5, 0.7)` | min 300 x 260, max 640 x 560 |
| settings or shop panel | `fromScale(0.55, 0.75)` | min 320 x 280, max 720 x 600 |
| modal dialog | `fromScale(0.4, 0)` with `AutomaticSize Y` | min 280 x 0, max 440 x 480; long text scrolls inside |
| toast stack | `fromScale(0.3, 0.6)` | min 240 x 80, max 320 x 480 |
| HUD element | offset, anchored to a corner inside the insets | small enough for both phone corners to stay clear |

Run the numbers before writing them in:

```bash
python tools/py/viewport_fit.py --size 0.5,0,0.7,0 --min 300,260 --max 640,560 --text 14 --button 44
```

## Text and targets after scaling

Every floor applies to the rendered size: `TextSize` times every `UIScale`
above it, and a button's box times the same. The player's text preference
(`GuiService.PreferredTextSize`, up to `Largest`) multiplies type again, so a
label that fits at `Medium` has to wrap or grow its row at `Largest`, not
overlap the next row.
