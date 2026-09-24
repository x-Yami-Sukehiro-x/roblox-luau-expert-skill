# Rebuilding a UI from a picture

The user sends a screenshot of a UI they like ("make mine look like this") or a
mock-up they drew. The failure is a build that shares the reference's colours
and nothing else: different proportions, different spacing, a generic layout
wearing its palette. The fix is to measure the picture before writing any
code, write the measurements down, build from the measurements, then compare.

---

## 1. Inventory

List every element in the picture, top to bottom, left to right, as a tree:

```text
Window (dark panel, rounded)
├── Header: title "Blox Hub", badge "BETA", minimise, close
├── Sidebar: 5 tabs with icons, the first selected
└── Content
    ├── Search field with icon
    ├── Section heading "FARMING"
    └── 4 rows: toggle, toggle, slider, dropdown
```

Name each part with the words in `roblox-request-intake/references/ui-words.md`
and each control with its picker code when one matches (a sliding pill switch
is T1, a pill tab marker is S5). Codes carry tested implementations; matching
a code is better than inventing a lookalike.

## 2. Measure

Find one thing whose real size you know and derive the scale from it:

- A row or button that is clearly a touch target: about 44 px.
- The screenshot's width, if it is a full Roblox window: 1280, 1366 or 1920.
- The Roblox top bar, if visible: about 58 px tall.

Then write down, in real pixels: the window's width and height, the sidebar
width, row height, the gaps between rows and groups, the window padding, the
corner radii, the icon sizes and every distinct text size. Round each to the
nearest value on the scales (spacing 4/8/12/16/24/32, text 12/14/16/20/28) and
say where you rounded: "measured 13 px, using 12".

## 3. Colours

Sample the flat areas, not the edges: page behind the window, window, raised
rows, borders, primary text, secondary text, accent, and any status colours.
Map each sample to a token role (`build-order.md`), not to a literal in the
code. If two samples are within a few steps of each other, they are one token.

Check the text contrast of the result (4.5:1). A reference that fails it is
matched in hue, with the text token lifted until it passes, and the reply
says so.

## 4. Type

Identify the font by its shape and name the nearest Roblox family:

| Looks like | Use |
|---|---|
| Geometric, round letters (Gotham, Montserrat) | `Gotham` family (`Font.fromEnum(Enum.Font.GothamMedium)` and the Bold/Black faces) |
| Neutral grotesque (Inter, Arial) | `BuilderSans` or `Arial` |
| Rounded, friendly | `FredokaOne`, `Nunito` |
| Monospace, console | `RobotoMono`, `Code` |
| Chunky display, cartoon | `LuckiestGuy`, `Bangers` |

Check every face you name exists with
`node tools/bin/verify-api.mjs Enum.Font.<Name>`. Weights come from
`Font.new(Font.fromEnum(Enum.Font.Gotham).Family, Enum.FontWeight.Bold)`.

## 5. Icons

Name each icon by what it depicts, then find it in
`roblox-ui-components/references/icon-ids.txt` by name or tag. Use the content
id from the file. If the reference uses a custom or branded icon with no Lucide
equivalent, use the closest meaning (`icon-meaning.md`) and list it as a
difference.

## 6. What a picture cannot show

Hover, press and focus colours, animations, what happens on a phone, and the
content of other tabs. Do not claim them. Build them from the defaults (six
states, M1, N1) or the user's picker codes, and list them in the reply as
decided, not seen.

## 7. Write the spec, then build

Before code, one block the user can check:

```text
Window 560 x 380, radius 10, padding 16, surface (19,21,26), border (44,48,57)
Sidebar 140 wide, tabs 44 tall, gap 4, selected: pill (46,160,127) at 15%
Rows 44 tall, gap 8, radius 6, raised (31,34,41)
Text: title 20 Bold, rows 14 Medium, section 12 Bold caps muted
Icons: home, user, swords, eye, settings (16 px, secondary text colour)
Controls: T1 toggles, D1 dropdown, slider plain
```

Then build the tree from the spec with the recipes, in `build-order.md` order.

## 8. Compare

Put the result next to the reference, element by element, and report every
difference that remains, with its reason:

| Element | Reference | Built | Why |
|---|---|---|---|
| Close icon | custom X | Lucide `x` | same meaning, uploaded and checked |
| Title font | a paid font | Gotham Bold | nearest Roblox face |

"Pixel perfect" is not a claim to make: fonts, antialiasing and screen scale
differ between a screenshot and Roblox.

---

## Someone else's game

Recreate the layout, proportions and feel. Do not copy a game's logo, name,
artwork or uploaded images: rebuild them with the user's own names and icons
from `icon-ids.txt`, and say that you did.
