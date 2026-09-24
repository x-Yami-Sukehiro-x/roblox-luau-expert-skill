# UIs — interfaces worth copying, and the ones that are not

Upload this folder to the GPT's Knowledge alongside the other two files, or read
it from the archive. It answers three questions the rest of the stack answers in
prose and this folder answers with measurements:

1. **Which library, if any?** → `catalog.md`
2. **What are the actual numbers for a header, a toast, and matching them?** →
   `anatomy.md`
3. **What does a correct one look like end to end?** → `exemplars/`

```
UIs/
  README.md      this file
  catalog.md     every library, measured on 2026-09-19, with the reason for each verdict
  anatomy.md     header rows, notifications, and why a notification stops matching its panel
  exemplars/
    README.md                  what each file demonstrates, and its linter scores
    ExecutorHub.client.luau    a hub panel under an executor       24/24 slop, 32/32 UI
    GameMenu.client.luau       a settings modal in a place you own 24/24 slop, 32/32 UI
```

**The folder is `UIs`, not `UI's`.** An apostrophe in a path breaks shell
quoting and several zip tools, and this folder has to survive being unpacked by
a Python sandbox.

---

## The finding that justifies the folder

Every hub library was grepped on 2026-09-19. Across WindUI, Obsidian, Rayfield,
Kavo and Orion — 2.2 MB of Lua:

- **`Activated`: 0 uses.** All five bind `MouseButton1Click`, which does not fire
  for a gamepad or for Roblox's selection system.
- **`SelectionGained`: 0 uses.** Not one of them has a focus state.
- **`UISizeConstraint`: 4 uses, all in WindUI.** Nothing else is bounded.
- **`ScreenInsets`: 1 use, in WindUI.** Rayfield still uses the superseded
  `IgnoreGuiInset`.

So a model that learned Roblox UI from public hub scripts learned an interface
with no focus state, no bounded sizing and no gamepad path — and it learned it
from five independent sources that agree, which is exactly the shape that reads
as consensus. It is not consensus. It is one mistake copied four times.

The numbers are in `catalog.md` with the file and byte count each came from.

---

## Order of use

1. Match the project's existing UI. If there is one, this folder is a
   cross-check, not a source.
2. If there is no project UI: take the token block from an exemplar and change
   the values, not the structure.
3. Pick a library only if the feature set needs one — config persistence,
   twenty tabs, a search field. For three toggles, `ExecutorHub.client.luau` is
   already the whole program.
4. Never copy a library's interaction code. See the finding above.

---

## Before saying the UI is done

```bash
node tools/bin/lint-roblox-ui.mjs <file.luau>
node tools/bin/lint-luau-slop.mjs <file.luau>
node tools/bin/verify-asset-ids.mjs <file.luau>
```

No Node available — a custom GPT's Code Interpreter, for instance:

```bash
python tools/py/ui_lint.py <file.luau>            # the UI rubric, 32 points
python tools/py/roblox_lint.py <file.luau>        # the slop rubric, 24 points
python tools/py/verify_api.py --scan <file.luau>  # every name, against the dump
```

All three are standard-library Python and all three ship in the archive. The
first two are ports of the Node linters, and `tools/bin/lint-parity.mjs` runs
every Luau file in the repository through both implementations and fails on any
difference - so "the Python one passes" means what "the Node one passes" means.

And if the request was to **redesign** something:

```bash
node tools/bin/lint-roblox-ui.mjs --compare <before.luau> <after.luau>
```

`0 of them structural` means the layout, the type scale and the palette are
identical to what was there before. Report that number instead of the word.
