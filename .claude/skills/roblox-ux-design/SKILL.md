---
name: roblox-ux-design
description: UX design for Roblox UI - flows, feedback timing, error prevention, thumb reach, nothing clipped. Use for it feels confusing.
---

# UX that works before anyone reviews it

`roblox-ui` decides how a screen looks and `roblox-ui-viewport` proves it
fits. This skill decides how it behaves for a person: how they get in and
out, what each action tells them, what cannot go wrong, and a structure in
which nothing can be clipped because nothing is built where clipping happens.
`roblox-ui-ux-review` is the same knowledge pointed at a finished screen.

## Design the flow before the layout

Write the flow as a few lines before any frame exists:

```
Open:     Shop button (HUD, bottom right) or B on gamepad
Task:     pick an item -> see price and what it does -> buy
Feedback: Buy button pending while the purchase is in flight, then owned
Fail:     "Not enough coins: 120 more" on the button, not a toast
Leave:    close button, Escape or B; reopening keeps the tab and scroll
```

Rules the flow must meet:

1. **The main task in two inputs from open.** Tabs, sections and search exist
   to keep it at two, not to show off how much is there.
2. **Every action answers at once.** The control changes state the frame it
   is pressed; a slow result shows as pending on that control; the outcome
   replaces the pending state. A toast is for results that arrive somewhere
   the player is not looking (`roblox-script-feedback`).
3. **Prevent before you report.** A purchase the player cannot afford is a
   disabled button that says why, not an error after pressing it. A
   destructive action names its outcome ("Delete Sword") and asks once.
4. **Leaving is always possible**: a close control, Escape and gamepad B, and
   a way back in on touch if closing hides the only button.
5. **State survives closing**: the tab, the scroll position, a half-typed
   field. Unload is different from close; say which each control does.
6. **Primary actions where thumbs rest**: lower half on a phone, never under
   the jump button's corner, nothing destructive beside a frequent action.

Common flows written out (purchase, destructive action, settings, search and
filter, multi-step, first run) are in [flows.md](references/flows.md).

## A structure where nothing gets clipped

Clipping happens in three places: inside a `ScrollingFrame`, inside a
`CanvasGroup`, and inside any frame with `ClipsDescendants`. Things that draw
outside their own box get cut there: Outer strokes, focus rings, shadows,
press growth, badges, and every popup. The structural rule is to never build
those things inside those places:

```
ScreenGui  (ScreenInsets = CoreUISafeInsets, ResetOnSpawn = false)
  Window   (scale size + UISizeConstraint; not clipping)
    Header (title, close: one horizontal UIListLayout)
    Body   (ScrollingFrame: clips; rows inside use Inner strokes,
            UIPadding >= any overflow, no press scale past the padding)
    Footer (primary action; outside the scroll so it never scrolls away)
ScreenGui  (popups: DisplayOrder above the window)
  Dropdown list, tooltip, context menu, placed from the anchor's
  AbsolutePosition, flipped and clamped to the viewport
ScreenGui  (toasts: capped stack in a safe corner)
```

| Draws outside its box | Where it may live |
|---|---|
| Popup, dropdown list, tooltip, menu | Its own `ScreenGui`, never inside the list that opened it |
| Outer `UIStroke`, focus ring, drop shadow | Outside clipping parents; inside one, use `Inner` or pad the parent by the thickness |
| Press growth (`UIScale` above 1) | Only where the parent's padding covers the growth |
| Rounded corners over opaque children | A `CanvasGroup`, or children inset by the radius; `ClipsDescendants` clips to the rectangle |

`ZIndex` never escapes a clipping parent; a higher `ScreenGui` does.

## Text that cannot overflow

Every label has one plan for long text, chosen when it is built:

- **Wrap**: `TextWrapped = true` with `AutomaticSize = Y`, in a parent that
  scrolls or has room to grow.
- **Truncate**: `TextTruncate = AtEnd` for names and titles, with the full
  text in a tooltip.
- **Fixed**: text the script controls completely (a number with a unit).

Design with the long version: the longest item name in the game, a 20-letter
display name, a translation 40% longer than English, a count at 99,999.
`TextScaled` on a sentence is not a plan; it makes every label a different
size (`E-TEXTSCALED`).

## Checking the design without a device

```bash
node tools/bin/lint-roblox-ui.mjs <file>     # E-STROKECLIP, E-CORNERBLEED, E-MINFIT, E-UNBOUNDED, W-INSET
python tools/py/viewport_fit.py <file>       # each device's panel, text and targets
```

Then run the callbacks with the longest content in the Luau mocks and assert
the dependent labels. In Studio, `roblox-studio-mcp` captures the screen at
640 x 360; that is the only check of what is actually drawn.

## Works with

- `roblox-ui`: tokens, hierarchy and build order.
- `roblox-ui-viewport`: fit on every screen, scrolling and popup placement.
- `roblox-ui-interaction`: every control on mouse, touch and gamepad.
- `roblox-ui-ux-review`: the same rules applied to a finished screen.
- `roblox-script-feedback`: when a result earns a notification.
- `roblox-ui-from-scratch`: the flow when the request gives almost nothing.
- `roblox-copy-craft`: the words on every control and message.
