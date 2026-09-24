# Icons

Two things go wrong with icons in generated Roblox UI, and they are opposites.

The first is the **font glyph**: a close button whose label is `"×"`, a chevron
that is `"▼"`, a tick that is `"✓"`. It costs nothing and it looks wrong,
because a text character is laid out as text. `×` sits on the maths axis, `▼`
sits on the baseline, and neither lands on the optical centre of the 44 px box
you put it in. Its stroke weight comes from the font, so it never matches the
1 px `UIStroke` beside it, and it changes shape when the player's font
fallback differs from yours.

The second is the **invented asset id**: `Image = "rbxassetid://1234567890"`.
It compiles, it runs, nothing errors, and the icon is blank. No amount of
reading the code finds it, because the code is fine — the claim it makes about
the world is false.

Both have the same fix: use a real image asset, and prove it is real.

---

## Proving it

```bash
node tools/bin/verify-asset-ids.mjs src/UI/ShopMenu.luau
```

It asks Roblox's thumbnail service about every id in the file and separates
three cases that look identical in source:

| Verdict | What it means |
|---|---|
| image | real, moderated, renders |
| asset exists but is not an image | wrong asset type — renders blank |
| no such asset | the id was made up |

`rbxassetid://1234567890`, the placeholder every model reaches for, is the
middle case. So is `4483345998`, and so is most of what a model produces when
it "remembers" an icon id.

**Never write an asset id you did not either receive from the user or read out
of a source that lists it.** If you do not have one, say so and use the
fallback at the bottom of this file. A blank icon shipped silently is worse
than a square that admits it is a placeholder.

The tool exits 2, not 0, when it cannot reach Roblox. A gate that passes when
it could not check is the same failure as no gate.

---

## Lucide on Roblox

[lucide](https://lucide.dev) is the icon set most Roblox UI wants: one weight,
one grid, outline style, and a name for everything. Roblox cannot render SVG,
so the icons have to exist as uploaded images.

**`https://icons.rest`** publishes 1,559 lucide icons already uploaded, free,
as a name-to-id list. Checked 2026-09-19; every id in the module below was
verified with the command above on that date.

There is also a Studio plugin, *Lucide Icons*, which inserts them for you. Use
that when working in Studio by hand; the module is for code.

### The set worth keeping in one file

`library/src/Icons.luau` is that file: 81 icons covering navigation, status,
the common controls and the game vocabulary. It is a flat table of names to
`rbxassetid://` strings, and `check-all.mjs` re-verifies every id in it against
Roblox on each run, so it cannot rot quietly.

```lua
--!strict
-- lucide icons, uploaded by icons.rest, verified 2026-09-19.
local Icons = {
    x = "rbxassetid://116396312853810",
    check = "rbxassetid://86817768619372",
    chevronDown = "rbxassetid://71457658246709",
    settings = "rbxassetid://106205298246017",
    triangleAlert = "rbxassetid://91165848022002",
    info = "rbxassetid://120620848266512",
    coins = "rbxassetid://117341212186115",
    -- ... 74 more
}

return table.freeze(Icons)
```

Reference them by name — `Icons.x`, never the number. A typo then fails as a
nil index at the call site instead of rendering a blank square that nobody
notices until a player mentions it.

Anything outside the list: look it up at `https://icons.rest`, add it to the
module, and run the verifier. Do not guess the next id from the pattern of the
ones above — they are upload ids, not a sequence.

---

## Drawing one

An icon is an `ImageLabel`, and four properties decide whether it looks
deliberate.

```lua
local icon = Instance.new("ImageLabel")
icon.BackgroundTransparency = 1
icon.Image = Icons.x
icon.ImageColor3 = Tokens.text.secondary  -- tint it; lucide ships white
icon.Size = UDim2.fromOffset(16, 16)
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
icon.Parent = button
```

| Rule | Why |
|---|---|
| `ImageColor3`, never a recoloured upload | One asset serves every state. Hover, disabled and pressed are tint changes |
| Size from the **icon scale**, not the type scale | 16 / 20 / 24. An icon next to 16 px text is 16 px |
| Centre with `AnchorPoint`, not padding | Padding centres the box; anchor centres the glyph |
| `BackgroundTransparency = 1` | Otherwise a white square, because the default is opaque |
| `ScaleType = Enum.ScaleType.Fit` if it may be non-square | Default `Stretch` distorts |

**The icon is not the hit area.** A 16 px icon lives inside a 44 px button.
Size the button, centre the icon in it, and let the icon stay small:

```lua
-- 44 px of reach, 16 px of ink.
local close = Instance.new("ImageButton")
close.Size = UDim2.fromOffset(44, 44)
close.BackgroundTransparency = 1
close.AutoButtonColor = false
close.Image = ""            -- the button draws nothing itself

local glyph = Instance.new("ImageLabel")
glyph.Image = Icons.x
glyph.Size = UDim2.fromOffset(16, 16)
glyph.AnchorPoint = Vector2.new(0.5, 0.5)
glyph.Position = UDim2.fromScale(0.5, 0.5)
glyph.BackgroundTransparency = 1
glyph.ImageColor3 = Tokens.text.secondary
glyph.Parent = close
```

---

## Executors: `getcustomasset`

In a place you control, an image has to be uploaded and moderated before it has
an id. Under an executor there is a second route: write the file to disk, then
turn it into a content string.

```lua
-- One decision, at the top, asserted once.
local getcustomasset = getcustomasset or getsynasset
assert(getcustomasset and isfile and writefile, "needs file and custom asset access")

if not isfile("icons/x.png") then
    writefile("icons/x.png", game:HttpGet("https://example.com/x.png"))
end
icon.Image = getcustomasset("icons/x.png")
```

Four things that are true and get missed:

- **`getcustomasset` takes a path relative to the executor's workspace folder,
  not an absolute path.** It returns an `rbxasset://` string, not a number.
- **It only helps for unmoderated or local art.** A lucide id from `Icons.luau`
  is simpler, is already moderated, and works in Studio too.
- **PNG or JPEG. Not SVG.** Roblox has no SVG rasteriser, so downloading a
  lucide `.svg` produces a broken image. Convert first, or use the uploaded id.
- **`getcustomasset or getsynasset` is the one fallback that is legitimate**,
  because it is two executors' names for the same function — not two different
  places to look. Resolve it once, at the top, and assert.

See `roblox-executor/references/technique/source-to-api.md` for why a longer
chain than that is a confession the source was not read.

Two files that already do all of this correctly, and are linted on every run:
`docs/portability/gpt/UIs/exemplars/ExecutorHub.client.luau` wires six verified
lucide ids by name through a 44 px button with 16 px of ink, and
`docs/portability/gpt/UIs/anatomy.md` has the measurements beside what a real
library does instead.

---

## When there is no id

Sometimes there is no verified asset and no executor. Say so, and draw the
shape. Three of them are worth having, and none needs an image:

| Shape | How |
|---|---|
| A cross | Two `Frame`s, 2 px tall, rotated `45` and `-45` |
| A chevron | One `Frame`, 2 px border on two sides, rotated `45` |
| A dot / status pip | One `Frame`, `UICorner` at `UDim.new(0.5, 0)` |

```lua
-- A close cross that matches a 1 px stroke, because you set the thickness.
for _, angle in { 45, -45 } do
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0.5, 0.5)
    bar.Position = UDim2.fromScale(0.5, 0.5)
    bar.Size = UDim2.fromOffset(14, 2)
    bar.Rotation = angle
    bar.BackgroundColor3 = Tokens.text.secondary
    bar.BorderSizePixel = 0
    bar.Parent = closeVisual
end
```

This is better than `"×"` for the reason at the top of the file: you chose the
weight, the length and the centre, so it matches the rest of the interface
instead of matching whatever font the player fell back to.

What is **not** acceptable: shipping `"×"` and calling it an icon, or shipping
an id you have not verified and letting the player discover the blank square.
