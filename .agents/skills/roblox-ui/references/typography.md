# Typography and text

Type is the fastest tell in a Roblox interface. Default `SourceSans` at
`TextScaled = true` in a box that happens to be 41 pixels tall reads as
generated before anyone reads a word of it.

Three things separate deliberate type from default type: a **scale** you chose,
a **face** you chose, and boxes that **fit the text** rather than the text
squeezing into the box.

---

## `FontFace`, not `Font`

`TextLabel.Font` (the `Enum.Font` one) is `[Hidden]` in the dump — it no longer
appears in the properties panel — and is limited to the built-in enum. It still
works from a script; it is simply the legacy surface. `FontFace` is the live one
and is strictly more capable: it carries weight and style, and it can reference
any font asset.

```lua
label.FontFace = Font.new(
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Medium,
    Enum.FontStyle.Normal
)

-- Weight and style are mutable after construction, which is how you get a
-- bold state without swapping the whole face.
label.FontFace = Font.fromEnum(Enum.Font.Gotham)   -- bridge from legacy code
```

`Font` constructors: `Font.new(family, weight?, style?)`, `Font.fromEnum`,
`Font.fromName`, `Font.fromId`. `Enum.FontWeight` runs `Thin` through `Heavy`
(nine steps); `Enum.FontStyle` is `Normal` or `Italic`.

**Gotham everywhere is itself a tell** — it is the Studio default family and
reads as "nobody chose this". Pick a display face for headings and a readable
face for body, and let the pairing say something about the product.

---

## A type scale, and the `TextScaled` argument

`TextScaled = true` sizes text to fill its box. Every label then ends up a
different size, decided by its container. That is the precise opposite of a type
scale, and it is catalogued as **R2 · P0** in `anti-slop-catalog.md`.

Define four or five steps and use them:

```lua
Tokens.type = {
    title    = 28,
    subtitle = 20,
    body     = 15,
    caption  = 13,
    micro    = 11,
}
```

Four defined steps beat twelve ad-hoc `TextSize` values, and they survive a
re-skin because they live in one table.

**The narrow legitimate uses of `TextScaled`:**

- A **badge or counter** whose box is fixed and whose content is one to three
  glyphs — `"99+"` in a circle.
- A single **hero number** that is meant to dominate its panel.

Both are cases where the box is the design and the text serves it. Pair either
with a `UITextSizeConstraint` so it cannot scale past legibility:

```lua
local constraint = Instance.new("UITextSizeConstraint")
constraint.MaxTextSize = 18
constraint.MinTextSize = 10
constraint.Parent = badgeLabel
```

Everywhere else, set an explicit `TextSize` from the scale and let the container
adapt with `AutomaticSize`.

---

## Fit the box to the text

`AutomaticSize` grows a `GuiObject` to its content. This is what stops
localisation from breaking a layout — a button sized to fit `"OK"` clips
`"Confirmer l'achat"`.

```lua
button.AutomaticSize = Enum.AutomaticSize.X
button.Size = UDim2.fromOffset(0, 36)     -- Y fixed, X computed

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = button

local minimum = Instance.new("UISizeConstraint")
minimum.MinSize = Vector2.new(88, 36)     -- never smaller than a touch target
minimum.Parent = button
```

**`AutomaticSize` fights an explicit `Size` on the same axis.** Setting
`AutomaticSize = X` and then writing a non-zero `Size.X` gives you whichever
the engine resolved last. Zero the axis you are automating.

Two read-only properties tell you what actually happened:

- `TextLabel.TextBounds` — the measured size of the rendered text.
- `TextLabel.TextFits` — `false` when the text is being clipped or squeezed.

`TextFits` is the cheapest possible layout assertion. In a debug build, warn on
it and you will find every overflowing label before a player does.

---

## Measuring before you lay out

Sometimes you need the size *before* the instance exists — deciding a toast's
height, placing a tooltip so it does not run off-screen, sizing a virtualised
row. `TextService:GetTextBoundsAsync` is the supported way.

```lua
local TextService = game:GetService("TextService")

local params = Instance.new("GetTextBoundsParams")
params.Text = message
params.Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
params.Size = Tokens.type.body
params.Width = availableWidth        -- wrap width; omit for a single line

local bounds = TextService:GetTextBoundsAsync(params)   -- Vector2, YIELDS
```

It **yields**. Two consequences the signature does not spell out:

- Anything you captured before the call must be re-validated after it. The frame
  you were sizing may have been destroyed.
- Do not call it per-item in a loop over a hundred rows on one frame. Measure
  one representative row, or cache by `(text, size, width)`.

The older `TextService:GetTextSize(text, size, font, frameSize)` takes an
`Enum.Font` and does not yield. It cannot express weight or a custom family, so
it silently mismeasures anything using `FontFace`.

---

## Rich text

`TextLabel.RichText = true` enables a small markup subset inside `Text`:

```lua
label.RichText = true
label.Text = 'Reward: <b>240</b> <font color="#F2C14E">coins</font>'
```

Supported tags include `<b>`, `<i>`, `<u>`, `<s>`, `<br/>`, `<font color face size>`,
`<stroke>` and `<uc>` / `<sc>`. Nesting works; unknown tags render literally.

### The rule that matters

**Never interpolate player-controlled text into a rich-text label.**

A display name containing `<font color="#FF0000">` will render as markup. That
is not a security hole in the memory-safety sense, but it is a spoofing hole: a
player can make their name render as a system message, a moderator tag, or an
invisible string.

```lua
-- WRONG - the name is markup as far as the renderer is concerned
label.RichText = true
label.Text = ("<b>%s</b> joined"):format(player.DisplayName)

-- RIGHT - escape it
local function escapeRichText(s: string): string
    return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

label.Text = ("<b>%s</b> joined"):format(escapeRichText(player.DisplayName))
```

Escape `&` **first** — doing it after `<` would double-escape the entities you
just produced.

Separately, any text a player typed must go through
`TextService:FilterStringAsync` before another player sees it. Escaping and
filtering solve different problems and you need both.

### Rich text and animation

`MaxVisibleGraphemes` reveals text a grapheme at a time — the typewriter effect,
done correctly for multi-byte characters and emoji:

```lua
label.MaxVisibleGraphemes = 0
TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
    MaxVisibleGraphemes = utf8.len(label.ContentText) or #label.Text,
}):Play()
```

Use `ContentText` — the `[ReadOnly]` rendered string with markup already
resolved — to count graphemes. Counting `Text` would count the tags.

---

## Wrapping, truncation and direction

| Property | Values | Note |
|---|---|---|
| `TextWrapped` | boolean | Wrap at the box width |
| `TextTruncate` | `None` / `AtEnd` / `SplitWord` | `AtEnd` gives the ellipsis |
| `LineHeight` | number | Multiplier. `1.15`–`1.35` reads better than the default for body text |
| `TextDirection` | `Auto` / `LeftToRight` / `RightToLeft` | Leave on `Auto` |
| `OpenTypeFeatures` | string | Font feature tags — see below |

`TextTruncate = AtEnd` with `TextWrapped = false` is the single-line ellipsis
every list row wants. With `TextWrapped = true` it truncates the last visible
line instead.

**Tabular figures.** Numbers that change every frame — a score, a timer, a
currency counter — jitter horizontally because digits have different widths.
`OpenTypeFeatures` is the property that fixes it, if the face ships the feature:

```lua
counter.OpenTypeFeatures = "tnum"      -- tabular (fixed-width) numerals
-- OpenTypeFeaturesError is ReadOnly and non-empty when the string was rejected
```

Check `OpenTypeFeaturesError` after setting it; a silent no-op otherwise looks
like the property does nothing.

**Right-to-left.** `StarterGui.RtlTextSupport` (`Default` / `Disabled` /
`Enabled`) controls whether RTL scripts render correctly. If you localise into
Arabic or Hebrew, mirrored layout is a separate problem from mirrored text —
`TextXAlignment` and `UIListLayout` do not flip themselves.

---

## Contrast

Body text against its background needs a contrast ratio of at least **4.5:1**;
large text (roughly 18pt+ or 14pt bold) can go to **3:1**. Text over a 3D scene
has no fixed background at all, so give it a `UIStroke` rather than hoping:

```lua
local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual   -- follows the glyphs
stroke.Color = Color3.new(0, 0, 0)
stroke.Thickness = 2
stroke.Transparency = 0.35
stroke.Parent = worldLabel
```

`ApplyStrokeMode.Contextual` outlines the text itself. `Border` outlines the
label's rectangle, which is almost never what you want on text.

The legacy `TextStrokeColor3` / `TextStrokeTransparency` pair still exists but
cannot vary thickness and does not follow `UIGradient`. Prefer `UIStroke`.

---

## Checklist

- [ ] `FontFace`, not the legacy `Font` enum property.
- [ ] A named type scale; no ad-hoc `TextSize` values.
- [ ] `TextScaled` only on fixed-box badges and hero numerals, with a size constraint.
- [ ] `AutomaticSize` on anything holding localisable text, with the automated axis zeroed.
- [ ] `TextFits` checked in development.
- [ ] Player-supplied strings escaped before entering a rich-text label, and filtered before display.
- [ ] `LineHeight` raised above default for body copy.
- [ ] Changing numbers use `tnum` and the feature error is checked.
- [ ] 4.5:1 contrast, or a contextual `UIStroke` over 3D.
