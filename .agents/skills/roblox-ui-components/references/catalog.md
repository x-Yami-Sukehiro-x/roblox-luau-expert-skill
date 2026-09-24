# Component catalog

Per-component decisions and traps. Every one assumes the six states from
`component-states.md` — they are not repeated here.

---

## Button

Three weights is enough for almost any game:

| Weight | Look | Rule |
|---|---|---|
| **primary** | filled, accent | **one per view.** Two primaries means neither is |
| **secondary** | outlined or neutral fill | the alternatives |
| **ghost** | text only, no fill | low-stakes, dense toolbars |

Destructive actions get their own treatment — never mirrored next to the primary with
the same shape and size, or people confirm the wrong thing.

Traps:

- Text buttons need `UIPadding`, not a fixed `Size` — a button sized to fit "OK" will
  clip "Confirm purchase" after localisation. Use `AutomaticSize = X` with padding and
  a `UISizeConstraint` for the minimum.
- Icon-only buttons need an accessible label somewhere — a tooltip at minimum.
- Put the icon and label in a `UIListLayout` with `FillDirection = Horizontal` and
  `VerticalAlignment = Center` rather than positioning by hand.

---

## Toggle / switch

The state must be readable **without** colour — colour-blind players and anyone
glancing. Move the knob; do not just recolour the track.

- Animate the knob with a spring, not a tween: the player can toggle again mid-motion.
  See `roblox-ui-motion/references/springs-and-smoothdamp.md`.
- The whole row is the hit target, not just the switch.
- Label on the left, control on the right, consistently.
- A toggle applies immediately. If it needs a Save button, it is a form field, not a
  toggle.

In hub UI every toggle writes to a persisted flag so state survives re-execution —
`roblox-ui/references/gui-architecture.md`.

Twenty tested looks, T1–T20, are in `../assets/toggles.luau` (`style-recipes.md`).

---

## Checkbox and choice group

A checkbox is for choices confirmed later or several at once; a toggle is for a
setting that applies now. One of several is a radio group (C8), never several
toggles that switch each other off.

- The whole row is the target, 44 px tall; the box is 22.
- Ticked shows a tick image, not only a fill.
- A group with "select all" shows a dash when some are chosen (C4).
- Chips (C9) wrap onto more lines rather than scrolling sideways.

Ten tested looks, C1–C10, are in `../assets/checkboxes.luau`.

---

## Slider

The fiddliest control to get right on touch.

```lua
-- drag maths: convert absolute mouse X to a 0-1 alpha along the track
local function alphaFromInput(track: Frame, x: number): number
    return math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
end
```

- Track the drag on `UserInputService.InputChanged` **globally**, not on the knob —
  otherwise the drag dies the moment the pointer leaves the knob.
- Release on `InputEnded` globally too, or a release outside the window leaves the
  slider stuck in drag.
- Show the value. A slider with no number is guesswork.
- **Snap to steps** where the value is discrete, and snap the *displayed* value too.
- The knob needs a 44px hit area even if it is drawn smaller.
- Support keyboard/gamepad: focused, arrow keys should nudge by one step.

---

## Dropdown / select

- Above ~8 options it needs a search field. Above ~15 it is the wrong control — use a
  list panel. See the search thresholds in
  `roblox-ui/references/gui-architecture.md`.
- The open list must render above everything: parent it to a high-`ZIndex` overlay
  container, not inside the row, or it clips against the parent `ScrollingFrame`.
- Close on: selection, click-outside, `Escape`, and the panel closing. Click-outside
  is the one that gets missed — a full-screen transparent `TextButton` behind the list
  is the standard trick.
- Show the current selection in the closed state, not a placeholder.
- Multi-select needs checkboxes and an explicit close; single-select closes on pick.
- An empty list says so ("No matches"), not a blank panel.

Twelve tested looks, D1–D12 (search, multi-select, player picker, palette), are in
`../assets/dropdowns.luau`; each opens its list in its own `ScreenGui` layer.

---

## Modal / dialog

Match the shape to the weight of the question — catalog tell R17 is the reflexive
centred box with two identical buttons.

- **Dim the background** and block input beneath it. A modal that does not block is a
  panel.
- **`Escape` closes**, and so does clicking the scrim — unless the action is
  destructive, where accidental dismissal is worse than friction.
- **Focus the primary action on open**; set `GuiService.SelectedObject`, and restore
  focus to whatever opened it on close.
- Destructive confirmations: make the confirming button distinct and the safe option
  the default focus.
- Never put a long form in a modal. That is a page.

---

## Tooltip

- Delay ~0.4–0.6s before showing. Instant tooltips fire while the pointer is just
  passing through.
- Hide immediately on leave — no exit delay.
- **Touch has no hover.** Anything only available via tooltip is invisible on mobile;
  give it a tap target or put the information in the layout.
- Position with edge detection: flip to the other side when it would leave the screen.
  Compare against `workspace.CurrentCamera.ViewportSize`.
- Never interactive. If it needs a button, it is a popover.

---

## Tabs

- The active tab needs more than a colour change — an underline, a joined edge, or a
  raised surface. Per-corner `UICorner` radii are what join a tab to its panel.
- Animate the indicator between tabs with a **spring**, not a tween — the player can
  click a third tab mid-slide.
- Keep tab content mounted and toggle `Visible` if switching is frequent; rebuild only
  if the content is heavy. Rebuilding on every switch is a per-switch allocation
  spike.
- Above ~5 tabs, consider a sidebar.
- Left/right on a gamepad should switch tabs.

Twelve tested looks, S1–S12, are in `../assets/press-and-tabs.luau`; which layout
fits how many tabs is in `roblox-ui/references/layout-ux.md`.

---

## Progress and loading

- **Determinate** (a real percentage) whenever you know it. Indeterminate spinners
  say "something is happening" and nothing else.
- Show progress only after ~150ms — a spinner that flashes for one frame is noise.
- Animate progress with a spring so a jump from 20% to 80% is not instant, but do not
  animate so slowly the bar lags reality.
- A skeleton beats a spinner for content that has a known shape.
- Never a progress bar that reaches 100% and then waits.

---

## Text input

```lua
box.PlaceholderText = "Search items"
box.PlaceholderColor3 = Tokens.text.muted
box.ClearTextOnFocus = false        -- default true destroys the value on focus
box.MultiLine = false
box.TextEditable = true

box.FocusLost:Connect(function(enterPressed: boolean, input: InputObject)
    if enterPressed then submit(box.Text) end
end)
```

- **`ClearTextOnFocus` defaults to `true`**, which wipes the field when the player
  clicks back into it to edit. Almost always wrong; set it `false`.
- `FocusLost` gives `enterPressed` — that is your submit signal.
- **Filter anything a player typed** before showing it to anyone else, via
  `TextService:FilterStringAsync`. Platform requirement, not a suggestion. See
  `roblox-engine-api`.
- Cap length. An unbounded input is a memory and layout problem.
- Placeholder is not a label. It disappears on typing; if the field needs explaining,
  it needs a label.
- Show validation **after** the field loses focus, not on every keystroke.

---

## Scrolling list

```lua
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()       -- let AutomaticCanvasSize own it
scroll.ScrollBarThickness = 4
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
```

- `AutomaticCanvasSize` with a `UIListLayout` removes all manual canvas maths. Set
  `CanvasSize` to zero on the automatic axis or the two fight.
- Add `UIPadding` — a list flush against the scrollbar looks unfinished.
- **Pool rows** for long lists. Destroying and rebuilding on every refresh is the
  usual cause of stutter when a leaderboard updates.
- Style the scrollbar (`ScrollBarImageColor3`, `ScrollBarThickness`) or it is a
  default grey slab against your design.
- Empty state: never an empty box. Say why it is empty and what to do.

---

## Card / panel

- Two or three surface levels total. More and the hierarchy stops meaning anything.
- Separate with background step and spacing before reaching for a stroke — see
  `outlines-and-dividers.md`.
- Padding on the container, not margins on every child.
- A card that is entirely clickable should show a hover state on the **whole card**,
  not just its button.

---

## Badge / counter

- Cap the display: `99+` rather than a four-digit badge blowing the layout.
- `AutomaticSize = X` with `UIPadding` and a minimum width via `UISizeConstraint`, so
  a single digit still renders as a circle and a three-digit value stays a pill.
- Anchor to the corner of what it counts with `AnchorPoint`, and let it overhang.
- This is the one legitimate use of `TextScaled` — a number that must fill a fixed
  badge regardless of digit count.

---

## Cross-cutting

Every component in this catalog:

1. Reads **tokens**, never colour literals.
2. Implements the **six states**.
3. Uses **`Activated`**, not `MouseButton1Click`.
4. Has a **teardown** — Trove, or a returned `destroy`.
5. Is **44px minimum** on touch targets.
6. Is reachable and visible under **gamepad focus**.
7. Has an **empty / error / loading** state where it can have one.
