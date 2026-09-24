# Roblox UI tells: catalog

What generated Roblox UI looks like, why it converges there, and what to do instead.

Each entry is **what it looks like → why it reads as generated → the fix**, with the
Roblox primitive named. Priorities: **P0** wrecks the design or breaks on a real
device · **P1** obviously generic to anyone who plays Roblox · **P2** polish.

This catalog is **style-agnostic on purpose.** It never says "use this palette" or
"round corners to 12". It says what reads as unconsidered. Any deliberate direction
survives it — see `gui-design.md` for directions, and pick one rather than defaulting.

> Method borrowed from the `avoid-ai-design` skill's tells catalog. Its *tells* are
> web-specific (Inter, shadcn defaults, indigo gradients) and do not transfer to
> Roblox at all. The coded, severity-tiered *format* does, and it is far more
> actionable than prose.

---

## Why Roblox UI converges

Three forces, all of them mechanical:

1. **The default Instance is a grey `Frame`.** Every UI starts from the same place,
   and the path of least resistance is to add a `UICorner` and a `UIStroke` and move on.
2. **Tutorials optimise for "works", not "considered".** They demonstrate a primitive
   in isolation, so the composite result is a pile of demonstrated primitives.
3. **Studio's property pane makes uniformity the cheapest option.** Setting the same
   `UICorner` on forty elements is one multi-select; varying it deliberately is forty
   decisions.

The result is UI that is *correct* and *anonymous*. The fix is never more effects —
it is fewer, chosen.

---

## Structure and layout

### R1 · P0 · The repeated default card

Every element is a `Frame` with `UICorner` at a fixed offset radius and a 1px black
`UIStroke`. Panels, buttons, list rows, the tooltip, the modal — all the same object
with different children.

**Why it reads as generated.** Nothing has a rank. A container and a control look
identical, so the eye has no way to tell what is structure and what is interactive.

**Fix.** Give at most two or three surface levels and let them mean something —
page → panel → control. Distinguish them with **background step and spacing**, not by
adding a border to everything. Reserve the stroke for the one thing that genuinely
needs an edge (see R9 and `../../roblox-ui-components/references/outlines-and-dividers.md`).

### R2 · P0 · `TextScaled = true` everywhere

**Why.** `TextScaled` sizes text to fill its box, so every label ends up a *different*
size determined by its container. That is the precise opposite of a type scale — you
cannot have hierarchy when the box decides the size.

**Fix.** Set `TextSize` from a scale (e.g. 12 / 14 / 16 / 20 / 28), and bound it with
`UITextSizeConstraint` so it stays legible on a phone.

```lua
label.TextScaled = false
label.TextSize = 16

local bound = Instance.new("UITextSizeConstraint")
bound.MinTextSize = 12
bound.MaxTextSize = 20
bound.Parent = label
```

`TextScaled` is right for exactly one thing: a single number or word that must fill a
badge regardless of digit count.

### R3 · P0 · Offset-only sizing

**Why.** It is the single most common reason a menu is unusable on a phone. A 600px
panel is comfortable on desktop and wider than the screen on mobile.

**Fix.** Scale for layout, offset for detail, constraints as guard rails. Full
treatment in `responsive-and-surfaces.md`.

### R4 · P0 · Grey-on-grey with no hierarchy

`fromRGB(35,35,35)` page, `fromRGB(45,45,45)` panel, `fromRGB(55,55,55)` card, white
text on all three.

**Why.** Every surface is within a few percent of its neighbour, so nothing recedes
and nothing advances. The design has no foreground.

**Fix.** Make the steps mean something. A larger jump between page and panel than
between panel and card. One accent that appears **three to five times in the whole
interface**, on the things that matter, and nowhere else. Everything else neutral.

### R5 · P1 · No `UIPadding`

Text touching the edge of its container, or a list whose first row is flush with the
panel top.

**Why.** Padding is the cheapest signal that something was composed rather than
assembled. Its absence is equally loud.

**Fix.** `UIPadding` on every container that holds text or a list. Derive the values
from one base unit so they relate — see R6.

### R6 · P1 · Uniform spacing, no rhythm

One `UIListLayout.Padding` value used everywhere; the gap between a label and its
input is the same as the gap between two unrelated sections.

**Why.** Proximity is how people group things without being told. Uniform spacing
throws that channel away.

**Fix.** A base unit (4 or 8) and a small set of steps from it. **Related things
closer, unrelated things further.** A section gap should be visibly larger than a row
gap — if you have to look twice to tell, it is not doing anything.

### R14 · P2 · `ZIndex` arithmetic

Layering solved by handing out ever-larger `ZIndex` numbers, and a `ZIndex = 999`
somewhere.

**Why.** Under the default `Enum.ZIndexBehavior.Sibling`, children are ordered within
their parent — descendant order already does most of the work. Global `ZIndex` fights
are a symptom of a flat hierarchy.

**Fix.** Order by tree structure. Reserve explicit `ZIndex` for genuine overlays
(modal, tooltip, toast) and give those a named constant, not a magic number.

---

## Type and colour

### R7 · P1 · One font for everything

Gotham / GothamBold on every element — the Roblox equivalent of shipping Inter
untouched.

**Why.** It is the editor default. It is not a choice, and it reads as one not made.

**Fix.** `FontFace` with a `Font` object gives you the full family including weights.
Two families at most: one for headings, one for body — or one family used at genuinely
different weights. Let the game's tone pick it; a horror game and a pet simulator
should not share a typeface.

```lua
label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
-- or a specific weight/style of any family:
label.FontFace = Font.new("rbxasset://fonts/families/Arimo.json",
    Enum.FontWeight.Bold, Enum.FontStyle.Normal)
```

### R8 · P1 · The purple-to-blue gradient header

A `UIGradient` diagonally across the title bar, violet to blue.

**Why.** Same convergence as the web tell. It is the default "make it look designed"
move and it now signals the opposite.

**Fix.** If a gradient earns its place, make it do a job — a subtle vertical lift on a
large surface, or a single accent sweep on one element. `UIGradient.Type` also offers
`Radial` and `Conical`, which almost nobody uses and which read as deliberate for that
reason. Rotation and `TileMode` (`Enum.GradientTileMode`) are part of the vocabulary.

### R16 · P2 · Neon glow on everything

Every panel edge glowing, usually cyan or magenta.

**Why.** Glow is an emphasis tool. Applied uniformly it emphasises nothing and reads
as a filter over the whole UI.

**Fix.** At most one glowing element per screen, on the thing you want looked at.

### R15 · P2 · Constant corner radius in offset

`UICorner.CornerRadius = UDim.new(0, 8)` on a 32px button and a 600px panel alike.

**Why.** Radius should relate to the element's size. The same 8px is a soft nudge on a
panel and nearly a pill on a small button.

**Fix.** Scale radius with element size, or keep a small set of radii tied to
component tiers. Per-corner control exists — `TopLeftRadius`, `TopRightRadius`,
`BottomLeftRadius`, `BottomRightRadius` — for things like a tab joined to its panel.

> The legacy `CornerRadius` property still works, but it can only express one radius
> for all four corners. The four per-corner properties are the current surface and
> the only way to round three corners and not the fourth.

---

## Components

### R9 · P1 · Fake drop shadows

A black `Frame` at ~0.7 transparency, offset a few pixels behind the panel.

**Why.** It does not blur, so it reads as a second rectangle rather than a shadow, and
it breaks the moment the panel has rounded corners.

**Fix.** A 9-slice shadow image (`ScaleType = Slice`) scales its blur correctly at any
size. Or drop the shadow entirely — background step and spacing separate surfaces
without it. See `../../roblox-ui-components/references/outlines-and-dividers.md`.

### R10 · P1 · Every button the same weight

Confirm and Cancel identical. Buy, Settings and Exit identical.

**Why.** Button weight is how you tell someone what to do. All-equal means the UI has
no opinion.

**Fix.** Three tiers is enough: **primary** (filled, accent, one per view),
**secondary** (outlined or neutral fill), **tertiary/ghost** (text only). Destructive
actions get their own treatment and never sit adjacent to the primary as a mirror.

### R11 · P1 · Emoji as icons

🔥 💎 ⚔️ in buttons and headers.

**Why.** They render differently per platform, do not inherit colour, cannot be
sized reliably against text, and read as a placeholder for an icon set.

**Fix.** An actual icon set as `ImageLabel`s with consistent size and colour
(`ImageColor3` so they inherit state). If icons are not available, **use words** —
text is better than an emoji standing in for one.

### R13 · P2 · Missing states

A hover colour and nothing else.

**Why.** Account for rest, hover, press, focus, disabled and meaningful selection,
plus loading for asynchronous work. Missing press feels broken on touch; missing
focus makes the UI unusable on a gamepad; missing selected state loses the current
choice when focus moves.

**Fix.** `../../roblox-ui-components/references/component-states.md` covers all six
with the events that drive them.

### R17 · P2 · The centred modal

Title, one paragraph, two identical buttons, centred, 0.5 anchor, dark overlay.

**Why.** It is the shape every dialog defaults to regardless of what it is asking.

**Fix.** Match the shape to the weight of the question. A confirmation is a small
anchored prompt near the thing being confirmed. A destructive action deserves
friction — the confirming button distinct, not mirrored. A long form is not a modal.

---

## Motion

### R12 · P2 · One tween for everything

`TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)` on every
animation in the file.

**Why.** Entering, leaving and moving are different events and should not share a
curve. Uniform motion reads as a setting rather than a design.

**Fix.** Map by intent — **Out** for entering, **In** for leaving, **InOut** for
moving between states, exits shorter than entries. And for anything that can be
interrupted, use `TweenService:SmoothDamp` instead of a tween. Full treatment in
`roblox-ui-motion`.

Also common and worth its own note: `Bounce` and `Elastic` on UI. They are almost
always wrong — they say "playful" once and "slow" every time after.

---

## The positive half

Removing tells produces UI that is inoffensive. These are what make it *deliberate*:

- **One accent, used three to five times** in the entire interface, on the things that
  matter. Everything else neutral. Restraint reads as confidence.
- **A real type scale** — a handful of sizes with clear jumps, and weight doing as
  much work as size.
- **Spacing derived from one base unit**, with related things visibly closer than
  unrelated things.
- **Hierarchy from weight and space before borders.** Reach for a line only when
  proximity genuinely cannot carry the grouping.
- **States on everything interactive**, including the ones only a gamepad sees.
- **One detail that could only belong to this game.** The shape of the currency badge,
  the way the shop panel enters, the corner treatment on the tab strip. One is enough,
  and it is the entire difference between competent and memorable.
- **Motion that is orchestrated**, not scattered — things that belong together move
  together, from a shared origin.

---

## Audit pass

Reviewing an existing interface, in order:

1. Screenshot it on a phone-shaped viewport. R3 and R5 show up immediately.
2. Squint. If nothing stands out, R4 or R10.
3. Count distinct `UIStroke`s and corner radii. High counts of identical values → R1, R15.
4. Count accent-coloured elements. More than about five → the accent means nothing.
5. Tab through with a gamepad. No visible focus → R13.
6. Measure the gap between two related items and two unrelated ones. Equal → R6.
7. Grep for `TextScaled` (R2), `ZIndex = 9` (R14), and identical `TweenInfo.new(` values (R12).
