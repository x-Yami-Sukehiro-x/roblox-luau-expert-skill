# Improving an existing hub

The user has a hub and wants it better. Most of the value is in finding the
three things that matter and fixing them without breaking the forty that work.

## Order of work

1. **Read before judging.** Which library does it use (WindUI, Rayfield,
   Obsidian, Linoria, its own)? Which parts are the library's and which are
   the user's? Library code is fixed upstream or left alone; the user's code
   is where fixes go.
2. **Measure.** Run `node tools/bin/check-file.mjs <hub.luau>` (or
   `python tools/py/check_file.py`). Quote the counts; they are the evidence
   the reply rests on.
3. **Run the audit below** and write each failure as: where, what happens to
   the player, the fix.
4. **Rank** with `roblox-improve`: anything that loses the player's input,
   leaks, or breaks on a phone comes before anything that looks dated.
5. **Fix the top three in place**, the smallest region each, and repost the
   whole file. Say what the rest of the list is and offer it.

Before a second round on the same complaint, read the attempt ledger
(`roblox-attempt-memory`); a hub that "still doesn't work" after a fix is a
different cause, not the same fix again.

## The audit

| Check | How to see it | Usual fix |
|---|---|---|
| Runs twice cleanly | Execute it twice: two windows, or doubled callbacks | A `getgenv()` session handle that unloads the previous run |
| Unloads completely | Unload, then press its keybinds and move the mouse | One Trove; `OnUnload` switches features off |
| Opens on a phone | Hide it on a touch device with no keyboard | An on-screen Open chip, draggable, tap to reopen |
| Fits 640 x 360 | Studio Device Emulator, landscape phone | Scale sizing, a `UISizeConstraint`, a compact layout |
| Buttons fire on touch and gamepad | `MouseButton1Click` in the source | `Activated` |
| No clicks through the window | Click empty window space while click-teleport is on | `Active = true` on the root frame |
| Menu key ignores chat | Type the key's letter in chat | Check `gameProcessed` before toggling |
| Keybind capture does not also toggle | Rebind to the menu key | A capturing flag the menu key respects |
| Dropdown not clipped | Open the last dropdown on a long page | The list in its own ScreenGui, clamped on screen |
| Config honesty | Run where `writefile` is missing | Detect once; say saving is off |
| Config actually restores | Save with Fly on, rejoin, load | `Set` runs the Callback on load |
| No UI work per frame | `RenderStepped` or `while true do` driving UI | Input and property events |
| Text legible | TextSize under 12, `TextScaled` on sentences | 12 px floor, the type scale |
| Colour not the only signal | Toggle on and off look alike in greyscale | Move the knob; add a check or weight change |
| One accent colour | Count distinct accent colours | One accent role in the theme |

## Library-specific notes

- **Any third-party library**: check the two things libraries most often
  leave to the hub, before assuming either works: how a hidden window comes
  back on a phone, and whether loading a saved config runs the callbacks.
  Test both in the user's executor; if one fails, add the missing piece in
  the hub's code rather than patching the library's source.
- **Linoria and Obsidian** keep values in `Toggles` and `Options` tables.
  Their config system is the reason to use them; do not replace it.
- **A home-made library** with a helper per element (`makeToggle`,
  `makeSlider`) usually repeats hover and focus code in every helper and
  misses it in two. Move the shared parts into one Row, as HubKit does.

## What not to change

Do not rename the user's flags (it breaks their saved configs), change the
menu key default, restyle what they did not complain about, or move them to
a different library. The diff is the changelog; keep it small enough that
the user can see what changed.
