# A generated panel, scored and rewritten

A real 726-line executor script with a real interface: a draggable-item tweak
for Lumber Tycoon 2, a panel with a title and a close button, a toggle, and a
toast. It was produced by a capable model that had already been told the rules
in prose.

It scores **20/30** with ten errors. Nothing in it is stupid; every defect is a
number that looks reasonable on its own line.

```bash
node tools/bin/lint-roblox-ui.mjs LT2HardDragger.luau
```

---

## The first finding is about the linter

Before this rewrite, that command printed:

```
  score 20/20  all counted checks pass
  counts: 0 text size(s), 0 radius value(s)
```

Zero text sizes, in a file with four `TextSize` assignments. The linter matched
`x.TextSize = 16` and the file was written with the other common idiom:

```lua
local function new(className, properties, parent) ... end
local title = new("TextLabel", { TextSize = 16, ... }, header)
```

Thirty-seven GUI objects, none of them visible to the check. **It passed by
blindness**, which is worse than failing, because a passing score is evidence.

The gate now resolves construction into a model first (`tools/bin/lib/gui-model.mjs`) and
refuses to score a file it cannot read (`E-BLIND`). If a rubric ever reports
zero of something a file plainly has, that is the finding.

---

## What it found once it could see

| Code | Count | What |
|---|---|---|
| `E-DEADSIZE` | 6 | a `Size` scale that a `UIFlexItem` or a pinned constraint already decides |
| `E-DEADPAD` | 1 | a `UIPadding` with every side set to 0 |
| `E-ALIGNMENT` | 1 | `TextYAlignment.Top` on the title, inside a row the layout centres |
| `E-DEADZINDEX` | 1 | `ZIndex = 20` on an only child |
| `E-TOASTFAST` | 1 | `TOAST_LIFETIME = 0.85` |
| `W-DEFAULTTEXT` | 2 | elements parented before anything sets their `Text` |
| `W-GLYPHICON` | 1 | `Text = "×"` as the close button |
| `W-INSETBOTH` | 1 | `ScreenInsets` and `IgnoreGuiInset` both set |

### Dead sizing — six of them

```lua
-- WRONG
local title = new("TextLabel", { Size = UDim2.fromScale(0.8, 1), ... }, header)
new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, title)
```

The flex item fills the row, so `0.8` is never used. A reader's first guess
about how wide the title is comes from that number, and it is false. Same shape
four more times, plus a close button pinned to 44 × 44 by a constraint that
also states `UDim2.fromScale(0.16, 1)`.

```lua
-- RIGHT
local title = new("TextLabel", { ... }, header)  -- no Size at all
new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, title)
```

**One owner per number.** `blueprints.md` B1a has the table of which instance
owns which value in a header row.

### The title sits 14 px high

```lua
-- WRONG - this sits inside a row whose layout sets VerticalAlignment.Center
local title = new("TextLabel", { TextYAlignment = Enum.TextYAlignment.Top }, header)
```

The label's *box* is centred by the layout and its *text* is pinned to the top
of that box. Next to a centred close button in a 44 px row, that reads as a
bug — and it is the single most common "the title looks off" report.

### The close button is a font character

`"×"` is U+00D7, laid out as text: it sits on the maths axis, its weight comes
from whatever font the player resolved, and it does not match the 1 px stroke
beside it. Replaced with a verified lucide asset and the 44-with-16-inside
pattern from `roblox-ui-components/references/icons.md`.

### The notification does not match the panel

This is the one people describe as "the colours are off" without being able to
point at a line, because no single line is wrong.

| | Panel | Toast |
|---|---|---|
| fill | `COLORS.base` | `COLORS.overlay` |
| stroke | `COLORS.overlay` | `COLORS.muted` |
| stroke alpha | `0.35` | `0.45` |

Two surfaces at the same elevation, painted two ways — and the toast's border
is a *text* token. The toast was written after the panel, from the same palette,
without reference to it.

```lua
-- RIGHT: one entry, read twice. They cannot drift.
local FLOATING = table.freeze({ fill = SURFACE.base, stroke = SURFACE.edge, strokeAlpha = 0.35 })

local function floatingSurface(frame, radius)
    new("UICorner", { CornerRadius = UDim.new(0, radius) }, frame)
    new("UIStroke", { Thickness = 1, Color = FLOATING.stroke, Transparency = FLOATING.strokeAlpha }, frame)
end
```

Naming the fourth rung `edge` rather than `overlay` is the other half: a token
named for its role cannot be grabbed for the wrong job by accident.
`roblox-ui-components/references/shadows-and-elevation.md` has the ladder.

### The toast leaves before it is read

```lua
TOAST_LIFETIME = 0.85
tween(toast, OPEN):Play()          -- 0.20s
task.delay(TOAST_LIFETIME, exit)   -- 0.15s
```

The delay starts when the entrance *starts*, so the message is readable at full
opacity for 0.50 s. Whoever chose `0.85` was thinking about time on screen;
what they set was time until it begins leaving.

```lua
-- RIGHT
task.delay(ENTER.Time + TOAST_HOLD, dismiss)   -- TOAST_HOLD = 2
```

---

## What did not change

The executor half was already right. It reads the `BodyPosition` off
`moveDrag`'s upvalue, finds the `Freefall` and `FallingDown` constants by
value, captures the originals before mutating, and restores them on unload.
Every API choice is correct and there is not one fallback chain.

This matters for what the failure actually is. The model did the hard part —
reading a decompiled dump and picking exact calls — and then wrote an interface
out of plausible numbers. **Ceremony is not the only slop.** A second kind is a
value that looks considered and is not, and it survives every review that reads
for correctness, because each line is individually fine.

---

## The rewrite

584 lines, **30/30 and 20/20**, the single asset id verified against Roblox,
same behaviour. Two of those points were won late: a sharper `E-DEADSIZE`
caught `Size = UDim2.fromOffset(300, 136)` on a panel whose constraint already
pinned 136. The rewrite had the same defect it was written to remove, in the
one form the first version of the check could not see. It is longer per feature than the executor-only rewrite in
`roblox-code-craft/references/slop-rewrite.md` because an interface is genuinely
a lot of instances — the test is not length, it is whether every line is
load-bearing.

Three things it adds that the original lacked, all from the failures above:

- `Escape` and gamepad `B` close the panel, unbound in the same teardown.
- One `bindPressState` helper in place of four near-identical input blocks.
- The toast and the panel read their surface from one frozen table.

Run all three gates before delivering anything that draws:

```bash
node tools/bin/lint-roblox-ui.mjs  src/UI/Panel.luau
node tools/bin/lint-luau-slop.mjs  src/UI/Panel.luau
node tools/bin/verify-asset-ids.mjs src/UI/Panel.luau
```
