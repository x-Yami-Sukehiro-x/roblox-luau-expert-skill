# Exemplars

Two complete files. Not fragments, not a library — the whole thing, from the
token block to the teardown, in one file a reader can paste and run.

They exist because rules do not transfer to a weak model and examples do. When a
model is asked for a hub and has never seen a correct one, it produces the
average of every tutorial it saw, and the average is Rayfield.

## What they score

Measured on 2026-09-19, by running the commands, not by reading the files:

| File | `lint-luau-slop.mjs` | `lint-roblox-ui.mjs` | `verify-asset-ids.mjs` | `verify_api.py --scan` |
|---|---|---|---|---|
| `ExecutorHub.client.luau` | **24/24** | **32/32** | 6 ids, 0 bad | 0 invented |
| `GameMenu.client.luau` | **24/24** | **32/32** | 3 ids, 0 bad | 0 invented |

Reproduce it:

```bash
node tools/bin/lint-luau-slop.mjs docs/portability/gpt/UIs/exemplars
node tools/bin/lint-roblox-ui.mjs docs/portability/gpt/UIs/exemplars
node tools/bin/verify-asset-ids.mjs docs/portability/gpt/UIs/exemplars/GameMenu.client.luau
python tools/py/roblox_lint.py docs/portability/gpt/UIs/exemplars
```

---

## `ExecutorHub.client.luau`

A script-hub panel under an executor: draggable header, a scrolling body of
toggles, a toast stack, a keybind, and one unload path.

What it is there to demonstrate:

| Thing | Where |
|---|---|
| **Header row that cannot drift** | `UIListLayout` + `UIFlexItem` slack; `LayoutOrder` 1/2/3/4, no `Position` |
| **Title that sits where it should** | `title.TextYAlignment = Center` — the whole "title looks off" bug |
| **A close button you can hit** | 44 × 44 `ImageButton`, 16 × 16 `ImageLabel` inside it |
| **Icons that are images** | Six verified lucide ids, referenced by name, never a `"×"` |
| **One alias, no fallback chain** | `gethui or get_hidden_gui`, resolved once, one `assert`. Two executor globals total |
| **Notifications that match the panel** | The toast reads `TOKENS.overlay` and `PANEL_RADIUS` — the same two values the panel reads |
| **Severity that is not colour alone** | Every level carries an icon as well as a tint; the tint is a 2 px edge, not the fill |
| **Six states** | rest, hover, press, focus, disabled, selected — including `SelectionGained` for gamepad |
| **`Activated`, never `MouseButton1Click`** | And `InputBegan` for press feedback, because `MouseButton1Down` never fires on a phone |
| **A rounded box that rounds its children** | `CanvasGroup`, so the opaque row at the edge cannot draw a square corner over it |
| **Teardown** | Every connection and every delayed thread tracked, one `unload()`, published on `getgenv()` |
| **No header comment at all** | There is no fact about this file that the file does not already show. That is the rule working, not an omission |

## `GameMenu.client.luau`

The same discipline in a place you own: a settings modal with a scrim, three
tabs, and the three non-happy states built before the happy one.

| Thing | Where |
|---|---|
| **Loading, empty and error, all present** | `showStatus()`; the error state carries a retry that actually retries |
| **Tab labels from the game's vocabulary** | `Controls`, `Audio`, `Graphics` — not `Settings / Options / Configuration`, which is one word three times |
| **A scrim that dismisses** | And `Escape`, because a modal that only closes via its own button traps a keyboard user |
| **`pcall` around the one thing that crosses a boundary** | `InvokeServer`, and nothing else. One `pcall` in 380 lines |
| **Failure that names the subsystem** | `warn("[settings] load failed: %s")` — one clause, under twelve words |
| **Teardown tied to the player leaving** | `AncestryChanged`, not a `Destroying` hook that never fires |

---

## How to use one

**Copy the shape, not the content.** The tokens, the header, the state wiring
and the teardown transfer to any panel. `Field Kit`, `Highlight nearby players`
and the three tab names are placeholders and should be replaced with the game's
own words — a label that would fit in any project is the tell that survives
every visual fix.

**Keep the token block at the top and keep it the only place a colour appears.**
Every other rule in this folder depends on that one holding.

**Re-run the linters after editing.** A 24/24 file that has been edited is an
unmeasured file.
