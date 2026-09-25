# Localization and accessibility

Many Roblox players do not read English first, and some need larger text,
see fewer colours, or feel sick from motion. None of this is extra
work if the UI is built for it from the start; all of it is a rewrite later.

## Text that can be translated

- **Leave `AutoLocalize` on** (`GuiBase2d.AutoLocalize`, true by default) for
  static labels. Roblox's automatic translation and the localization table
  translate them without code.
- **Build dynamic strings from keys, not concatenation.** "You have " .. n ..
  " coins" cannot be translated, because word order differs by language.
  Use a key with a parameter and `Translator:FormatByKey`:

```lua
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local ok, translator = pcall(LocalizationService.GetTranslatorForPlayerAsync, LocalizationService, Players.LocalPlayer)
local function coinsText(amount: number): string
	if ok then
		return translator:FormatByKey("CoinsOwned", { amount })
	end
	return `You have {amount} coins`
end
```

  `GetTranslatorForPlayerAsync` yields and can fail, so the source language
  is the fallback, stated once.
- **Leave room for longer words.** German and Portuguese labels often run about
  a third longer than English. Size text containers with `AutomaticSize` or
  enough slack, never to the English string's exact width.
- **Never put words in images.** They cannot be translated or filtered.
- **Player-typed text is filtered, not translated** (`roblox-chat`).

## Readable by more players

- **Text size.** 12 px is the floor after scaling; body text is 14 or 16.
  `GuiService.PreferredTextSize` reports when a player asked Roblox for
  larger text; a UI with `AutomaticSize` containers can scale its type up
  for Large and above without clipping.
- **Contrast.** Text at 4.5:1 or better on its surface; large text and icons
  at 3:1. The palettes in this stack are checked by
  `node tools/bin/lint-ui-directions.mjs`.
- **Never colour alone.** A toggle's knob moves; an error has an icon and
  words as well as red; a selected tab changes weight as well as colour.
- **Motion.** Honour `GuiService.ReducedMotionEnabled`: entrances and
  exits land in one frame, nothing idles, no camera shake. `roblox-ui-motion`
  has the switch.
- **Input.** Every action reachable by touch, mouse, keyboard and gamepad,
  with 44 px targets and visible focus (`roblox-ui-interaction`).
- **Timing.** A toast stays at least 1.5 seconds; nothing that must be read
  disappears on a timer shorter than that.

## Checklist

- [ ] Static text left to `AutoLocalize`; dynamic text through keys.
- [ ] Containers grow with text; nothing sized to the English width.
- [ ] No words baked into images.
- [ ] 12 px floor, contrast pairs checked, nothing colour-only.
- [ ] Reduced motion honoured; focus visible; 44 px targets.
