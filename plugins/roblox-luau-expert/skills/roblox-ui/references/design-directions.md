# Design directions — fully specified

`gui-design.md` describes directions in prose and tells you to pick one. That is
the right instruction for someone with design judgement and the wrong one for a
model without it: "pick a direction" resolves to "pick nothing", and nothing
looks like every other generated interface.

So this file resolves it. **Six complete directions, every value stated.** Copy
one into `library/src/Tokens.luau` and the whole interface inherits it.

**Direction 1, Slate, is the default.** When the user expresses no preference,
use Slate rather than inventing a palette. Inventing is where grey-on-grey comes
from.

Every contrast ratio below is computed, not estimated, and
`node tools/bin/lint-ui-directions.mjs` recomputes them from this file. A wrong
number here fails the build.

---

## How to read the ramp

Nine neutral steps, `neutral[0]` through `neutral[8]`.

| Slot | Role |
|---|---|
| `neutral[0]` | page — the furthest-back surface |
| `neutral[1]` | sunken — insets, wells, track backgrounds |
| `neutral[2]` | base — the ordinary panel |
| `neutral[3]` | raised — a control, or a panel on a panel |
| `neutral[4]` | overlay — modals, menus, the one thing on top |
| `neutral[5]` | muted text, disabled text, decorative strokes |
| `neutral[6]` | secondary text |
| `neutral[7]` | hairlines and dividers on the text side |
| `neutral[8]` | primary text |

On a **light** direction the ramp runs the other way perceptually — `neutral[0]`
is the lightest — but the slot meanings are identical, so component code never
changes when the direction does. That is the entire point of the indirection.

**The steps are deliberately uneven.** Even 10-point increments are catalog tell
R4. Page-to-base is a larger jump than base-to-raised in every direction here.

---

## Palette: Slate

`default` · dark · general purpose · the one to use when nothing was specified

A cool neutral ramp with a single desaturated teal. Reads as competent and
unremarkable in the good sense — it never fights the game behind it.

| Slot | RGB | Checked against | Ratio |
|---|---|---|---|
| `neutral[0]` | `9, 10, 13` | — | — |
| `neutral[1]` | `19, 21, 26` | — | — |
| `neutral[2]` | `31, 34, 41` | — | — |
| `neutral[3]` | `44, 48, 57` | — | — |
| `neutral[4]` | `63, 68, 79` | — | — |
| `neutral[5]` | `118, 125, 139` | `neutral[2]` | `3.85:1` |
| `neutral[6]` | `150, 157, 170` | `neutral[2]` | `5.84:1` |
| `neutral[7]` | `205, 210, 219` | — | — |
| `neutral[8]` | `243, 245, 248` | `neutral[2]` | `14.58:1` |
| `accent.dim` | `28, 88, 74` | — | — |
| `accent.base` | `46, 160, 127` | `neutral[0]` | `6.08:1` |
| `accent.bright` | `72, 201, 162` | `neutral[2]` | `7.70:1` |

| Property | Value |
|---|---|
| Spacing unit | 4 |
| Radius | control `6`, panel `10`, pill `UDim.new(0.5, 0)` |
| Type scale | 12 / 14 / 16 / 20 / 28 |
| Body font | `Enum.Font.GothamMedium` |
| Emphasis font | `Enum.Font.GothamBold` |
| Display font | `Enum.Font.GothamBlack` |
| Depth | `UIShadow`, blur 6 / 18 / 40 by level |
| Stroke policy | Inner 1px on panels only; controls get fill separation, not borders |
| Text on accent | `neutral[0]` |
| Accent as text | `accent.bright` |

---

## Palette: Paper

light · information-dense · tycoons, plugins, admin tools, anything read rather
than watched

High contrast, borders instead of shadows, one confident blue. The direction to
reach for when the interface is mostly text and numbers, because dark UI loses a
lot of legibility at small sizes over a bright 3D scene.

| Slot | RGB | Checked against | Ratio |
|---|---|---|---|
| `neutral[0]` | `255, 255, 255` | — | — |
| `neutral[1]` | `247, 247, 245` | — | — |
| `neutral[2]` | `237, 237, 233` | — | — |
| `neutral[3]` | `224, 224, 219` | — | — |
| `neutral[4]` | `199, 199, 193` | — | — |
| `neutral[5]` | `124, 124, 117` | `neutral[2]` | `3.58:1` |
| `neutral[6]` | `92, 92, 86` | `neutral[2]` | `5.73:1` |
| `neutral[7]` | `52, 52, 48` | — | — |
| `neutral[8]` | `24, 24, 22` | `neutral[2]` | `15.15:1` |
| `accent.dim` | `20, 66, 130` | — | — |
| `accent.base` | `29, 94, 184` | `neutral[0]` | `6.28:1` |
| `accent.bright` | `58, 128, 222` | — | — |

| Property | Value |
|---|---|
| Spacing unit | 4 |
| Radius | control `4`, panel `8` |
| Type scale | 12 / 14 / 16 / 22 / 30 |
| Body font | `Enum.Font.BuilderSansMedium` |
| Emphasis font | `Enum.Font.BuilderSansBold` |
| Display font | `Enum.Font.Merriweather` |
| Depth | Borders. `UIShadow` only on the single topmost overlay |
| Stroke policy | 1px `neutral[4]` on every panel; that is this direction's structure |
| Text on accent | `neutral[0]` |
| Accent as text | `accent.base` |

**`accent.bright` is hover and decoration only on Paper.** It measures `3.36:1`
against `neutral[2]` — below the 4.5 body-text floor. Text uses `accent.base`.

---

## Palette: Neon

dark · high energy · arcade games, executor hubs, anything that wants to look
built rather than defaulted

Near-black with a saturated violet. The failure mode is obvious — glow on
everything — so the discipline is that the accent appears on **exactly the
interactive things**, and depth comes from the ramp rather than from light.

| Slot | RGB | Checked against | Ratio |
|---|---|---|---|
| `neutral[0]` | `4, 5, 9` | — | — |
| `neutral[1]` | `13, 15, 24` | — | — |
| `neutral[2]` | `24, 28, 42` | — | — |
| `neutral[3]` | `38, 44, 62` | — | — |
| `neutral[4]` | `56, 64, 88` | — | — |
| `neutral[5]` | `104, 116, 148` | `neutral[2]` | `3.65:1` |
| `neutral[6]` | `138, 150, 180` | `neutral[2]` | `5.74:1` |
| `neutral[7]` | `198, 206, 224` | — | — |
| `neutral[8]` | `238, 242, 250` | `neutral[2]` | `15.11:1` |
| `accent.dim` | `92, 36, 150` | — | — |
| `accent.base` | `168, 96, 240` | `neutral[0]` | `5.43:1` |
| `accent.bright` | `186, 124, 248` | `neutral[2]` | `5.92:1` |

| Property | Value |
|---|---|
| Spacing unit | 4 |
| Radius | control `8`, panel `14` |
| Type scale | 12 / 14 / 17 / 22 / 32 |
| Body font | `Enum.Font.GothamMedium` |
| Emphasis font | `Enum.Font.GothamBold` |
| Display font | `Enum.Font.Michroma` |
| Depth | `UIShadow` with the accent as shadow colour on the active element only |
| Stroke policy | 1px `accent.dim` on the focused control; `neutral[3]` elsewhere |
| Text on accent | `neutral[0]` |
| Accent as text | `accent.bright` |

---

## Palette: Ink

light · warm · RPGs, adventure, farming and crafting games

Cream and rust. The only direction here with a serif in it, and the reason it
works is restraint: the serif is for the display size and nothing else.

| Slot | RGB | Checked against | Ratio |
|---|---|---|---|
| `neutral[0]` | `250, 246, 238` | — | — |
| `neutral[1]` | `242, 236, 224` | — | — |
| `neutral[2]` | `230, 222, 206` | — | — |
| `neutral[3]` | `214, 203, 182` | — | — |
| `neutral[4]` | `186, 171, 145` | — | — |
| `neutral[5]` | `122, 108, 84` | `neutral[2]` | `3.83:1` |
| `neutral[6]` | `96, 82, 62` | `neutral[2]` | `5.66:1` |
| `neutral[7]` | `61, 50, 36` | — | — |
| `neutral[8]` | `31, 25, 18` | `neutral[2]` | `13.02:1` |
| `accent.dim` | `110, 40, 18` | — | — |
| `accent.base` | `150, 58, 28` | `neutral[0]` | `6.67:1` |
| `accent.bright` | `196, 88, 46` | — | — |

| Property | Value |
|---|---|
| Spacing unit | 4 |
| Radius | control `4`, panel `6` |
| Type scale | 12 / 14 / 16 / 22 / 34 |
| Body font | `Enum.Font.BuilderSansMedium` |
| Emphasis font | `Enum.Font.BuilderSansBold` |
| Display font | `Enum.Font.Merriweather` |
| Depth | 1px `neutral[4]` border plus a 2px `neutral[3]` outer bevel |
| Stroke policy | Bevelled: inner light, outer dark. No `UIShadow` |
| Text on accent | `neutral[0]` |
| Accent as text | `accent.base` |

**`accent.bright` is decoration only on Ink** — `3.28:1` against `neutral[2]`.

---

## Palette: Glass

dark · translucent · HUDs and overlays that sit on top of live 3D

Built to be readable over a moving scene. Higher surface steps than the other
dark directions, because translucency eats separation. The cost is real — see
the warning below.

| Slot | RGB | Checked against | Ratio |
|---|---|---|---|
| `neutral[0]` | `10, 12, 18` | — | — |
| `neutral[1]` | `22, 26, 36` | — | — |
| `neutral[2]` | `36, 42, 56` | — | — |
| `neutral[3]` | `54, 62, 80` | — | — |
| `neutral[4]` | `78, 88, 110` | — | — |
| `neutral[5]` | `128, 140, 166` | `neutral[2]` | `4.25:1` |
| `neutral[6]` | `168, 180, 204` | `neutral[2]` | `6.88:1` |
| `neutral[7]` | `214, 222, 238` | — | — |
| `neutral[8]` | `246, 249, 255` | `neutral[2]` | `13.61:1` |
| `accent.dim` | `16, 86, 120` | — | — |
| `accent.base` | `34, 140, 180` | `neutral[0]` | `5.10:1` |
| `accent.bright` | `86, 190, 225` | `neutral[2]` | `6.73:1` |

| Property | Value |
|---|---|
| Spacing unit | 4 |
| Radius | control `10`, panel `16` |
| Type scale | 13 / 15 / 17 / 22 / 30 |
| Body font | `Enum.Font.BuilderSansMedium` |
| Emphasis font | `Enum.Font.BuilderSansBold` |
| Display font | `Enum.Font.Jura` |
| Depth | `UIShadow` on everything translucent, or it floats with no anchor |
| Stroke policy | 1px `neutral[6]` at transparency `0.6` — a light edge, not a border |
| Text on accent | `neutral[0]` |
| Accent as text | `accent.bright` |

**Translucent panels need `BackgroundTransparency` near `0.15`, not `0.5`.** Past
about `0.25` the measured contrast above no longer holds, because the scene
behind starts contributing. If the HUD sits over gameplay, keep it at `0.15` and
get the glass read from the stroke and the shadow instead.

**`accent.base` measures `3.74:1` on `neutral[2]`** — use `accent.bright` for any
accent-coloured text on Glass.

---

## Palette: Console

dark · monospace · debug panels, dev tools, internal instrumentation

Green-black and amber. This is a *tool* direction — it should look like
something an engineer left running, and it should never ship to players.

| Slot | RGB | Checked against | Ratio |
|---|---|---|---|
| `neutral[0]` | `6, 7, 6` | — | — |
| `neutral[1]` | `13, 15, 13` | — | — |
| `neutral[2]` | `24, 28, 24` | — | — |
| `neutral[3]` | `36, 42, 36` | — | — |
| `neutral[4]` | `54, 62, 54` | — | — |
| `neutral[5]` | `106, 120, 106` | `neutral[2]` | `3.70:1` |
| `neutral[6]` | `136, 152, 136` | `neutral[2]` | `5.66:1` |
| `neutral[7]` | `196, 210, 196` | — | — |
| `neutral[8]` | `232, 240, 232` | `neutral[2]` | `14.83:1` |
| `accent.dim` | `92, 64, 8` | — | — |
| `accent.base` | `190, 140, 30` | `neutral[0]` | `6.69:1` |
| `accent.bright` | `240, 190, 80` | `neutral[2]` | `10.00:1` |

| Property | Value |
|---|---|
| Spacing unit | 4 |
| Radius | control `2`, panel `2` |
| Type scale | 12 / 13 / 14 / 18 / 24 |
| Body font | `Enum.Font.RobotoMono` |
| Emphasis font | `Enum.Font.RobotoMono` |
| Display font | `Enum.Font.RobotoMono` |
| Depth | None. Flat surfaces, 1px dividers |
| Stroke policy | 1px `neutral[4]` everywhere — the grid *is* the design here |
| Text on accent | `neutral[0]` |
| Accent as text | `accent.bright` |

Monospace throughout means hierarchy has to come from size, weight and colour
alone. That is a constraint, not an excuse to skip it.

---

## Status colours

Shared across every direction. They mean the same thing everywhere, so they do
not get re-themed.

| Status | RGB | Use |
|---|---|---|
| info | `88, 141, 214` | neutral notification |
| success | `72, 178, 112` | completed, granted, saved |
| warning | `214, 158, 62` | degraded, nearly out, will expire |
| danger | `208, 88, 82` | failed, destructive, blocked |

**Never the only signal.** Every status colour is paired with an icon or a word,
because a meaningful fraction of players cannot distinguish red from green.

---

## Applying a direction

One edit, in `library/src/Tokens.luau`, to the `PRIMITIVE` table:

```lua
local PRIMITIVE = {
    neutral = {
        [0] = Color3.fromRGB(9, 10, 13),
        [1] = Color3.fromRGB(19, 21, 26),
        [2] = Color3.fromRGB(31, 34, 41),
        [3] = Color3.fromRGB(44, 48, 57),
        [4] = Color3.fromRGB(63, 68, 79),
        [5] = Color3.fromRGB(118, 125, 139),
        [6] = Color3.fromRGB(150, 157, 170),
        [7] = Color3.fromRGB(205, 210, 219),
        [8] = Color3.fromRGB(243, 245, 248),
    },
    accent = {
        dim = Color3.fromRGB(28, 88, 74),
        base = Color3.fromRGB(46, 160, 127),
        bright = Color3.fromRGB(72, 201, 162),
    },
    unit = 4,
}
```

Then the radius, font and type-scale rows from the direction's property table.
Nothing else in the library holds a colour literal, so that is the whole re-skin.

---

## Choosing between them

| The project is | Use |
|---|---|
| unspecified | **Slate** |
| a simulator, fighting game, obby, anything action | Slate or Neon |
| a tycoon, tower defence, anything with numbers to read | Paper |
| an RPG, farming, crafting, medieval anything | Ink |
| a HUD drawn over live gameplay | Glass |
| an executor hub or script UI | Neon or Slate |
| a Studio plugin | Paper |
| a debug or admin panel | Console |
| already themed | **match the project.** Read its existing colours first |

If the user names a colour — "make it purple", "we're a green brand" — keep the
chosen direction's ramp and structure and substitute only the accent. Re-check
the two ratios that matter: text on the accent, and the accent as text on
`neutral[2]`. `tools/bin/lint-ui-directions.mjs` will do the arithmetic.
