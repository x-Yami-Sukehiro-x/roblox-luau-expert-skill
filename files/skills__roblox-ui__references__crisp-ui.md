# Blurry and broken UI: causes and fixes

"It looks blurry", "it's bugged", "the dropdown is cut off", "it's fine on my
PC and broken on my phone". Each of these has a small set of mechanical causes,
and none of them is fixed by changing colours. Find the row, apply the fix,
check the way the last column says.

The engine facts below come from the Roblox API reference; the member names
are checked against the vendored API dump.

---

## Blurry

| You see | Cause | Fix |
|---|---|---|
| An icon is soft or fuzzy | The image is drawn larger than the texture it was uploaded as. By default the engine smooths an image shown larger or smaller than its texture size | Show it at or below the size it was made for. For your own art, upload it at least twice the largest size it appears on screen, then set the displayed size |
| Pixel art is smeared | The same smoothing | `ResampleMode = Enum.ResamplerMode.Pixelated` keeps hard pixel edges |
| An icon is squashed or stretched | `ScaleType` is `Stretch` and the box is not the image's shape | `ScaleType = Enum.ScaleType.Fit`, or a square box with a `UIAspectRatioConstraint` |
| A 9-slice panel has soft, fat corners | `SliceScale` above 1 grows the edges as if the texture had been upscaled | Keep `SliceScale` at 1 or below; for bigger corners, upload a bigger slice image. Set `SliceCenter` to the source image's real corner size in pixels |
| A dark rim around a transparent icon | Colour hidden in the transparent pixels bleeds in when the image is scaled | Export the PNG with the transparent area filled with the icon's own edge colour, or use the `icon-ids.txt` icons, which are single-colour and tinted with `ImageColor3` |
| A whole panel goes soft, or blank on low graphics | It is inside a `CanvasGroup`. A CanvasGroup draws its children into a texture whose quality and memory are limited by the player's graphics quality; past the memory cap it draws blank; each new size makes a new texture | Use a `CanvasGroup` only for something that must fade or clip as one piece. Never wrap the whole screen or a scrolling list in one, and do not tween its `Size` |
| Text is small and soft on a phone | `TextScaled` shrank it, or a `UIScale` below 1 took 14 px text under 12 | Fixed `TextSize` from the type scale, `TextScaled = false` on any sentence, and check the phone size after `UIScale`: nothing under 12 |
| Outlined text looks blobby | A thick `UIStroke` on small text | Stroke thickness 1 on text under 20 px, or no stroke: a darker panel behind the text reads better |
| The game behind the menu stays blurry | A `BlurEffect` in `Lighting` was never set back to 0 | One shared blur, tweened to 0 on close; see `roblox-ui-components/references/shadows-and-elevation.md` |

---

## Broken

| You see | Cause | Fix |
|---|---|---|
| A dropdown list or tooltip is cut off by its panel | It is inside a `ScrollingFrame` or a `ClipsDescendants` parent, which clips anything that leaves it | Draw the list in its own `ScreenGui` with `DisplayOrder` one above the host and the host's `ScreenInsets` copied; `roblox-ui-components/assets/dropdowns.luau` does this |
| Something shows behind what it should cover | Sibling `ZIndex` values fight, or `ZIndexBehavior` differs between guis | Set `ZIndexBehavior = Enum.ZIndexBehavior.Sibling` explicitly and give overlays their own `ScreenGui` with a higher `DisplayOrder`, instead of raising `ZIndex` everywhere |
| Square corners poke out of a rounded panel | `UICorner` rounds only its own parent, and `ClipsDescendants` clips to the rectangle | A `CanvasGroup` with the `UICorner` for content that reaches the edge, or inset the children by the radius |
| A child ignores its `Position` | A `UIListLayout` or `UIGridLayout` places every child | Order with `LayoutOrder`, space with the layout's `Padding` and a `UIPadding`, take the slack with `UIFlexItem` |
| A frame grows forever or flickers | `AutomaticSize` on an axis where a child is sized by scale of that same parent | Children on an automatic axis size in offset, or fill with `UIFlexItem` |
| A list cannot scroll to the end | `CanvasSize` is a fixed guess | `AutomaticCanvasSize = Enum.AutomaticSize.Y` with `CanvasSize = UDim2.new()` and a list layout inside |
| Text runs out of its box | No wrap and no truncation | `TextWrapped = true` in a box that can grow, or `TextTruncate = Enum.TextTruncate.AtEnd` on a one-line label |
| The top of the UI hides under the Roblox top bar or a notch | Insets ignored | `ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` on the `ScreenGui` |
| The UI disappears when the player respawns | `ResetOnSpawn` is true, the default | `ResetOnSpawn = false` |
| A button does nothing when clicked | An invisible frame lies on top of it and takes the input | Find what covers it (`PlayerGui:GetGuiObjectsAtPosition`) and set `Interactable = false` or `Active = false` on the cover, or move it |
| A list jitters while something animates | A layout child's `Size` is tweened, so every sibling reflows each frame | Tween a `UIScale` inside it, or the size of an inner frame that is not a layout child |
| Right size on a computer, cut off on a phone | Offset-only sizes on the root | Scale sizes with a `UISizeConstraint` holding both bounds; `responsive-and-surfaces.md` |
| Hover colour stuck on a phone | `MouseEnter` fired from a tap with no `MouseLeave` after it | Show hover only while an input of type `MouseMovement` is over it; pressed and selected states come from `InputBegan` and `Activated` |
| A button fires twice | A second connection was made the next time the menu opened | Connect once when the UI is built, or keep and disconnect the connection when the menu closes |

---

## Before any UI leaves

Run these, in this order, and fix what they report before looking at colour:

1. `node tools/bin/lint-roblox-ui.mjs <file>` catches the layout-position,
   radius, unbounded-root, text-size and connection rows above.
2. Resize the view to 390 × 844 (Studio's Device emulator, or the UI designer's
   phone screen): nothing under 12 px, nothing cut off, no target under 44 px.
3. Open every popup inside every scrolling area and confirm it is not clipped.
4. Respawn once with the UI open.
5. For every image: shown size no larger than the size it was made for, and
   `ScaleType` right for its shape.
