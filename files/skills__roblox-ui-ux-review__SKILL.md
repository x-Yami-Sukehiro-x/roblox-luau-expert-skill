---
name: roblox-ui-ux-review
description: Recommending formatting, UI and UX fixes for an existing script - ranked, with evidence, clipping traced. Use for clean this up.
---

# Review the user's path through the UI

Use when asked to improve formatting, review a UI, make a screen easier to use
or fix clipping. `../roblox-improve/SKILL.md` owns severity and the general
review method. This skill ties a visual observation to the task it interrupts.

An instruction to improve or fix authorizes appropriate edits. A request for
recommendations calls for ranked recommendations; do not turn it into a rewrite.
Read the existing attempt ledger before repairing a recurring defect.

## Separate evidence from judgment

Identify the intended action, available source, current screenshot dimensions
and runtime access. Read the state owner and the handlers behind that action.
Run the available checks on the current file before making a comparison.

| Evidence | Can establish | Cannot establish alone |
|---|---|---|
| Source and API verification | Handler wiring, constraints, competing writers | Actual text metrics or an input reaching the button |
| Computed viewport fit | Bounds under the calculation's assumptions | Popup contents, keyboard overlap or visual balance |
| Callbacks run in mocks | State transitions and dependent displays in that harness | Touch scroll arbitration or rendered focus |
| Screenshot | Visible overlap, truncation and emphasis at that state/size | Whether the button works or the list can scroll |
| Runtime interaction | The observed sequence in that tested environment | Every device, game state or executor |

Label a finding as observed, source-established or needing verification.
An aesthetic preference is Advisory. Never infer a leak from one screenshot
or call a sensible design variation a correctness bug.

## Inspect in the order the user experiences it

1. **Entry and recovery.** Can the user find, open, close and reopen the screen?
   Is the next useful action visible? Does an empty state explain its cause?
2. **Action and feedback.** Does activating a control change the intended state
   and every dependent display? Can they tell pending, rejected and complete
   apart? Repeated activation should not duplicate an in-flight operation.
3. **Reachability.** Check the bottom row, footer, popup, focused control and
   text field with the keyboard open. Inspect touch and gamepad separately.
4. **Layout and reading.** Follow the labels in order; compare hierarchy,
   grouping and density against the task. Long descriptions should wrap or be
   shortened before anyone shrinks the whole UI.
5. **Code presentation.** Run the format and craft checks. Point to the specific
   region whose wrapping, name or comment obscures its purpose; preserve the
   file's conventions. Do not reformat an unrelated feature as part of a UI fix.

## Trace clipping to its owner

Read `../roblox-ui-viewport/references/overflow.md` and
`../roblox-ui/references/clipping.md` for the relevant case. Record the failing
viewport, state, child bounds and clipping ancestor when observable. Inspect
these different causes before choosing a fix:

| Symptom | Distinguish before editing |
|---|---|
| Bottom actions disappear | Root minimum too tall, missing scroll area, or footer consuming the list's space |
| Last row cannot be reached | Canvas size/padding versus a sibling covering the row |
| Popup loses items | Clipping ancestor versus offscreen placement or insufficient popup scrolling |
| Stroke, focus ring or shadow is cut | Rendered extent outside the clipped child, not just its layout bounds |
| Text disappears at large text size | Fixed row height, competing size constraints, wrapping or insufficient flex space |
| Round panel has square corners | Opaque children reaching the rounded edge without appropriate masking |
| Button is visible but dead | Input coverage, disabled ancestry, disconnected handler or scroll gesture |

Raise `ZIndex` only for proven ordering trouble; it cannot escape a clipping
ancestor. Do not turn off all clipping, increase every minimum, shrink below
the text/target floors, or rebuild the menu to repair one overflow owner.
Use a popup host outside the clipped list when needed, then clamp or flip its
placement and preserve focus and dismissal. Retest after scrolling and resize.

## Turn tool findings into recommendations

A linter code is evidence, not a recommendation. Translate each into the
player's consequence and the smallest fix; the full table by area is
`../roblox-ai-mistakes/references/mistake-catalogue.md`.

| Finding | Say to the user | Smallest fix |
|---|---|---|
| `E-MINFIT` | The panel runs off a 640 x 360 phone | Lower the `UISizeConstraint` minimum; let the body scroll |
| `E-STROKECLIP` | Row outlines are cut off at the list's edges | `Inner` strokes, or pad the list by the thickness |
| `E-CORNERBLEED` | Square corners poke out of the rounded panel | A `CanvasGroup`, or inset the children |
| `E-MOUSEONLY` | The control does nothing on phone or gamepad | `Activated` |
| `E-LAYOUTPOS` | A position that the layout overrides | Remove it; order with `LayoutOrder` |
| `W-STATES`, `E-AUTOBUTTON` | Buttons do not respond to hover, press or focus | The component's six states |
| `E-TEXTSCALED` | Sentences at different sizes | Fixed sizes from the type scale |
| `W-HYPE`, `W-GENERIC` | Labels and names read as generated | Rewrite with `roblox-copy-craft` |
| Format `W-WIDTH`, clustered blocks | The file is hard to scan | Wrap at 100 columns, one blank line between blocks, in the touched region only |

Formatting is recommended for the region being changed. Reformatting a whole
working file the user did not ask about makes the real change unreadable.

## Recommend the smallest useful change

For each worthwhile finding, give: priority, file/element, triggering condition,
user-visible consequence, evidence, proposed change and a confirming check.
Rank an unreachable primary action above a spacing preference. Usually three
to five findings are enough; fewer are correct when fewer are supported.
Do not invent issues to fill a quota.

Example: "Correctness — the open dropdown's last two choices are outside its
scrolling parent in the 640 x 360 capture. Host the popup outside that clip and
limit its height to the usable area. Retest the last option after scrolling
and rotating the viewport." If only source suggests this, say so instead.

For applied changes, compare the same viewport, content and state before and
after. Run `node tools/bin/check-file.mjs --compare <before> <after>` and the
callbacks affected by the edit. Equal counts do not prove unchanged behavior.
Report measured changes, actual interactions, remaining unknowns and any
tradeoff. Never manufacture a before screenshot or a passing UX percentage.

## Works with

- `roblox-improve`: severity, false positives and recommendation scope.
- `roblox-attempt-memory`: previous failures and a regression check per fix.
- `roblox-ui-viewport`: fit and clipping causes.
- `roblox-ui-interaction`: dead controls, focus and input conflicts.
- `roblox-script-feedback`: whether feedback is useful, truthful and timely.
- `roblox-code-craft`: names, comments and minimal edits.
- `roblox-studio-mcp`: observed behavior and comparable screen captures.
- `roblox-ux-design`: the design-time rules each finding is measured against.
- `roblox-copy-craft`: rewriting labels, descriptions and notices.
