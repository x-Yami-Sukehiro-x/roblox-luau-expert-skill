# Screen archetypes: whole screens that work without being art-directed

"Make me a shop." "I need a settings menu." The user will not describe the
layout, and should not have to. Each archetype below is a complete default:
what the screen is for, its one hero, its skeleton, the parts and picker codes
it uses, the states it needs, and what changes on a phone. Build the default,
state it in one line, and let the user react to something real.

Sizes and spacing follow `layout-ux.md`; parts come from `blueprints.md`;
copy follows `ui-copy.md`; icons follow `icon-meaning.md`.

---

## Script hub

**For** switching many features on and off while playing. **Hero:** none; the
content is the point, so the window stays quiet and small.

```text
Window 560 x 380 (scale 0.5 x 0.65, 300..720 x 320..820), draggable header
├── Header 44: title 20 Bold · badge · minimise · close        (B1a)
├── Sidebar 140: tabs with icons, S4 or S5                      (B6)
└── Page: search (D11 or a search box), section headings,
          rows 44: toggles T1, sliders, dropdowns D1, keybinds  (B2)
```

States: empty search ("No features match"), a disabled row with the reason,
loading while a feature starts. Hide and bring back: O1 or the user's pick.
Notifications: N4, one line, 1.5 s. Phone: the sidebar becomes a top tab strip
(S12); the window takes 92 % of the width.

## Settings

**For** changing a few preferences once. **Hero:** the section the player
opened.

```text
Modal 420 x content, padding 16
├── Header: "Settings" · close
├── Tabs S1 along the top if there are 2-5 groups (Controls, Audio, Graphics)
└── Rows 44 grouped under headings; sliders show their value; toggles T1
    Footer: "Reset to defaults" (plain, left) — changes apply immediately
```

No Save button when every control applies at once; if something needs a
restart, say so on that row. Phone: full-width sheet from the bottom (B8).

## Shop

**For** comparing and buying. **Hero:** the item's price and buy button.

```text
Window 560 x 420
├── Header: "Shop" · coin balance (icon + number) · close
├── Tabs S8 if there are categories (Tools, Pets, Passes)
└── Grid of cards 120 x 152, gap 8                              (B4)
    card: icon 40 · name 14 Bold · "250 coins" button (accent, full width)
```

The buy button says what it costs: **Buy for 250 coins**, never "Buy" alone.
States: can't afford (button shows the shortfall, disabled with reason),
owned ("Owned", not a disabled Buy), purchase pending, purchase failed. Robux
products open Roblox's own prompt; the server grants (`roblox-monetization`).

## Inventory

**For** finding and equipping what you own. **Hero:** the selected item.

```text
Window 600 x 420
├── Header: "Inventory" · count "18 / 50" · close
├── Filter chips C9 or a search field
├── Grid of slots 72 x 72 (icon, rarity edge, equipped mark)   (B4)
└── Detail panel 200 wide: big icon, name, stats, Equip / Unequip
```

Empty state: "Nothing here yet. Items you buy or find appear here." Phone: the
detail panel becomes a sheet over the grid.

## Daily reward

**For** a one-tap claim. **Hero:** the claim button.

```text
Window 520 x 236, content centred
├── Title "Daily reward" 20 Bold
├── Row of 7 day tiles 60 x 88 (claimed · today, outlined in accent · locked)
└── Button "Claim day 4" 200 x 48, accent
```

Already claimed: the button becomes a countdown, "Next reward in 5h 12m".
The server decides the day and the grant; the client only asks.

## Main menu

**For** getting into the game. **Hero:** Play.

```text
Column 320 wide, centred over the game or a backdrop
├── Game title 28 Heavy
├── Play 52 tall, accent, full width
└── Settings, Credits 44 tall, raised
```

Nothing else competes with Play. The backdrop is the game or a slow camera
move, not a gradient.

## HUD

**For** reading at a glance while playing. **Hero:** none; the HUD must not
compete with the game.

```text
Bottom left: health chip 260 x 44 (heart icon + bar)
Top right: currency chip (coin icon + number), below the Roblox buttons
Right edge, centred: 3 icon buttons 56 x 56 (Shop, Pets, Settings)
```

Every chip is the smallest size that reads, on a surface at 10-20 %
transparency. Numbers change with a short count-up, never a bounce. Phone:
nothing under the thumb zones in the lower corners except the joystick side
the game does not use.

## Leaderboard

**For** "where am I?". **Hero:** the player's own row.

```text
Panel 360 x 420
├── Header: "Top players" · tabs S8 (Today, All time)
├── Rows 44: rank · avatar headshot 32 · name · score (right-aligned)
└── Pinned row at the bottom: the player's own rank, accent edge
```

Loading and empty states; scores formatted with separators (12,450).

## Quest tracker

**For** the next objective without opening a menu. **Hero:** the current
objective.

```text
Top right under currency: 280 wide, content height
├── Quest title 14 Bold
└── Objective rows: "Collect coins 12 / 20" with a thin progress bar
```

Collapses to its title with one tap. Completing a step: a check and a short
fade, then the next step.

## Trade window

**For** agreeing a swap safely. **Hero:** the two offers.

```text
Window 640 x 440
├── Header: "Trading with Name" · close
├── Two columns: your offer · their offer (slot grids, values)
└── Footer: status text · Ready (toggle) · Accept (disabled until both ready)
```

Any change to either offer clears both Ready states and says so. The server
validates every item and performs the swap.

## Loading screen

**For** covering the load honestly. **Hero:** the game's name.

```text
Full screen, the game's colour or art
├── Name 28 · short tip line 14
└── Progress bar 280 x 6 with a real step count, or an indeterminate bar
```

Never a percentage that is made up. Skip after assets load; fade out 0.3 s.

## Dialogue (NPC)

**For** reading and choosing a reply. **Hero:** the line being said.

```text
Bottom panel 640 wide, 24 from the bottom edge
├── Speaker name 14 Bold · portrait 48
├── Text 16, typed on at a readable speed, tap to finish
└── Reply buttons 44 tall, stacked, the game's words
```

## Confirm a purchase or a destructive action

**For** one question. **Hero:** the consequence.

```text
Modal 360 wide (B5)
├── Title that is the question: "Sell Golden Sword?"
├── One line with the consequence: "You get 120 coins. This can't be undone."
└── Buttons: "Keep it" (plain) · "Sell for 120 coins" (danger or accent)
```

The confirming button repeats the action and the amount.

---

## When the request fits none of these

Take the nearest archetype, keep its hero rule, and change the parts. State
which archetype you started from in the reply ("built like a shop: a grid of
cards with prices") so the user has a word for what they are looking at.
