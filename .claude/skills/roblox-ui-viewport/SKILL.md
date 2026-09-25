---
name: roblox-ui-viewport
description: Fitting Roblox UI on every screen, phone to 4K - bounded scale sizes, safe insets, grow-only UIScale, scrolling, popups kept on screen. Use for UI cut off or not fitting.
---

# Every screen, all of the UI

A UI "works" when a player on the smallest screen it will meet can see every
part of it and reach every control. Design at 1280 x 720, then prove the two
ends: a **640 x 360 landscape phone**, which keeps about 640 x 300 once the
topbar takes its 58 px, and a **4K or ultrawide monitor**, where an unbounded
panel becomes a strip across the screen.

```bash
python tools/py/viewport_fit.py MyMenu.client.luau     # panel size, text and targets per device
node tools/bin/lint-roblox-ui.mjs MyMenu.client.luau    # E-MINFIT, E-UNBOUNDED, E-STROKECLIP
```

`check-file.mjs` runs both on any file that draws UI.

---

## The sizing model

1. **Top-level panels are sized by scale and bounded both ways.**
   `UDim2.fromScale(0.5, 0.7)` plus a `UISizeConstraint` whose `MinSize` fits
   640 x 300 and whose `MaxSize` keeps lines readable (about 560 to 720 wide).
   A panel sized only in offset has one size on every screen; that size is
   wrong on most of them.
2. **Offset is for detail**: padding, stroke thickness, icon size, row height.
   Detail should not shrink to nothing on a phone.
3. **`UIScale` only grows.** One per `ScreenGui`, driven from the viewport and
   clamped to 1 at the bottom (`../roblox-ui/references/scaling-and-dpi.md`).
   A floor of 0.7 makes 12 px text 8.4 px and a 44 px button 31 px on every
   phone. The phone is fitted by rule 1, not by shrinking everything.
4. **Content taller than its panel scrolls.** A `ScrollingFrame` with
   `AutomaticCanvasSize = Y` and `CanvasSize = UDim2.new()` holds the list; the
   panel never grows with its content past the screen.
5. **Insets come from the engine.** `ScreenInsets = CoreUISafeInsets` on every
   `ScreenGui`, never a hardcoded topbar height; `ClipToDeviceSafeArea` where
   nothing may bleed under a notch.
6. **Layout reacts.** Recompute on `Camera.ViewportSize`, `GuiService.TopbarInset`
   and `GuiService.PreferredTextSize` changes, and clamp dragged windows and
   open popups back inside after each.

Minimum floors, measured **after** every `UIScale`: text 12 px, touch
targets 44 px. `viewport_fit.py` prints both per device.

## The device pass

| Profile | Viewport | What breaks there first |
|---|---|---|
| small phone, landscape | 640 x 360 | bottom of the panel and its buttons off screen; text under 12 px |
| notched phone, landscape | 844 x 390 | content under the notch on the left or right |
| phone, portrait (if the game enables it) | 390 x 844 | a panel wider than 390; rows too cramped for their labels |
| tablet | 1024 x 768 | a scale-sized panel far too large for its content |
| laptop | 1366 x 768 | the 720-tall design loses its bottom row |
| 1080p to 4K monitors | 1920 x 1080 to 3840 x 2160 | unbounded panels; unreadably small offset-only UI |
| ultrawide | 3440 x 1440 | a panel stretched to a thin strip; left and right items far apart |
| console on a TV | 1920 x 1080 | type set for a monitor unreadable from a sofa; nothing focused |

Profiles, their insets, and how to open each in Studio's device emulator:
`references/device-matrix.md`.

## Things that leave their box

A panel that fits can still lose content inside it. Each of these has one
fix, in `references/overflow.md`:

- a list longer than its frame, and the last row unreachable;
- a label longer than its space: wrap for sentences, truncate for names, with
  the full text reachable;
- a dropdown, tooltip or context menu past the screen edge: open the other
  way or clamp;
- a dragged window left off-screen after a resize or rotation;
- a text field hidden under the on-screen keyboard;
- a toast stack taller than the screen: cap the count.

Outlines, shadows and focus rings cut off by a clipping parent are the same
problem one level down: `../roblox-ui/references/clipping.md`.

## Reporting

State which profiles were computed (`viewport_fit.py`), which were opened in
the emulator, and which were not checked. A computed fit says the panel's box
is on screen; it does not show that the layout inside it looks right.

| Need | File |
|---|---|
| each device profile, its insets and the emulator steps | `references/device-matrix.md` |
| content leaving its box, and the fix for each case | `references/overflow.md` |
| outlines, shadows and rings cut off by a parent | `../roblox-ui/references/clipping.md` |
| the scale formula and text-size preference | `../roblox-ui/references/scaling-and-dpi.md` |
| buttons that do not respond on touch or gamepad | `../roblox-ui-interaction/SKILL.md` |

## Works with

- `roblox-ui`: the sizing rules in the build order.
- `roblox-ui-interaction`: targets that stay 44 px after scaling.
- `roblox-studio-mcp`: screen captures on emulated devices.
- `roblox-ui-components`: popups drawn above the panel that would clip them.
