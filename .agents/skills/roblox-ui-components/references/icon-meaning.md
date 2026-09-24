# Which icon means what

A tab labelled **Visuals** with a `star` beside it, **Settings** with a
`wrench` and **Misc** with a `sparkles`: each icon is a real image, and none
of them tells the player anything. The icon is a second label. When it names a
different thing from the words, the player reads two answers and trusts
neither.

This file picks the icon from the meaning. Every icon here is in
`icon-ids.txt`, uploaded to Roblox and checked as a real image; the content id
is copied from there, not recalled.

---

## The rules

1. **The icon names the same thing as the label.** Read the label, find its
   row below, use that icon. No row fits? Search `icon-ids.txt` by the label's
   words (its third column is Lucide's search tags):
   `grep -i "	.*fishing" icon-ids.txt`. Use the name whose tags contain the
   player's word, not the one that looks nicest.
2. **One icon per meaning, one meaning per icon.** Two tabs never share an
   icon. If **Combat** has `swords`, **Kill aura** in the Combat tab uses
   `skull` or no icon at all.
3. **One family, one weight, one size.** Every icon in an interface comes from
   `icon-ids.txt` (Lucide, 2 px strokes). Mixing in a filled emoji-style icon
   or a different set makes the odd one look broken. Size: 16 in rows and
   fields, 20 in tabs and headers, 24 on HUD buttons.
4. **Tabs and toggles keep their words.** Icon-only is for the four controls
   everyone knows (close, minimise, back, search) and a HUD button on screen
   often enough to be learned. A sidebar collapsed to icons shows the name on
   hover on a computer and never collapses on a phone, where nothing hovers.
5. **The icon takes the text colour of its row**, secondary when resting,
   primary or accent when selected. An icon is never the only thing that shows
   state.
6. **No brand logos.** Lucide has none, so a Discord or YouTube button uses
   `message-circle` or `link` with the name written beside it. Never write an
   id for a logo you did not upload.
7. **Nothing decorative.** An icon on every row of a settings list, each
   different and none meaningful, is noise. Put icons on tabs, on actions and
   on the first field of a search; leave plain settings rows plain.

---

## Picking for a tab list

Read the labels together first. A set of tabs is one decision:

| Tabs | Icons |
|---|---|
| Main, Player, Combat, Visuals, Misc, Settings | `home`, `user`, `swords`, `eye`, `package`, `settings` |
| Farm, Teleports, Pets, Shop, Settings | `sprout`, `map-pin`, `paw-print`, `shopping-cart`, `settings` |
| Shop, Inventory, Quests, Rewards | `shopping-cart`, `backpack`, `scroll-text`, `gift` |

If two tabs want the same icon, the labels overlap. **Settings** and
**Options** both want `settings`; that is one tab under two names, and the
fix is to rename one (`ui-copy.md`), not to find a second gear.

---

## The table

The first icon is the default. "Also fits" are real alternatives for when the
default is already taken. Copy content ids from here or from `icon-ids.txt`.

### Hub tabs

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Main, Home, General | main page, start, overview | `home` | `rbxassetid://109841253338329` | `layout-dashboard` |
| Player, Local player, Character | me, my character, movement settings | `user` | `rbxassetid://114567720540659` | `user-round` |
| Combat, Fighting, PvP | fight, attack, kill aura | `swords` | `rbxassetid://99199363807265` | `sword`, `crosshair` |
| Visuals, ESP, Render | see players, highlights, wallhack | `eye` | `rbxassetid://127234874352422` | `scan` |
| Farming, Auto farm | grind, collect, auto | `sprout` | `rbxassetid://100976494216154` | `tractor`, `coins` |
| Teleports, Locations, Waypoints | go to, places, map | `map-pin` | `rbxassetid://137091405832737` | `navigation`, `map` |
| Movement | speed, fly, jump | `footprints` | `rbxassetid://80792036653047` | `move`, `wind` |
| World, Server, Environment | lighting, time, map settings | `globe` | `rbxassetid://125685532120024` | `server` |
| Misc, Other, Extra | everything else | `package` | `rbxassetid://106101842173393` | `ellipsis`, `boxes` |
| Settings, Options, Config | change the hub itself | `settings` | `rbxassetid://106205298246017` | `sliders`, `settings-2` |
| Keybinds, Controls | keys, hotkeys | `keyboard` | `rbxassetid://121978468376124` | `mouse` |
| Theme, Appearance | colours, look | `palette` | `rbxassetid://127369887384101` | `paintbrush` |
| Credits, About, Info | who made it, version | `info` | `rbxassetid://120620848266512` | `heart` |
| Updates, Changelog, News | what's new | `megaphone` | `rbxassetid://139746713205639` | `newspaper` |
| Logs, Console, History | output, messages | `scroll-text` | `rbxassetid://93551675076113` | `file-text` |
| Scripts, Games list, Hub games | supported games | `gamepad-2` | `rbxassetid://99293705721130` | `joystick` |
| Webhook, Discord alerts | send to a server, notify | `webhook` | `rbxassetid://110638252405523` | `bell-ring` |

### Game screens

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Shop, Store | buy things | `shopping-cart` | `rbxassetid://79435149356304` | `store` |
| Inventory, Backpack, Items | my stuff | `backpack` | `rbxassetid://76143965140765` | `package` |
| Pets | companions, eggs | `paw-print` | `rbxassetid://97578437331341` | `egg` |
| Eggs, Hatching, Crates | open, roll, gacha | `egg` | `rbxassetid://103880404435578` | `gift` |
| Quests, Missions, Tasks | objectives, to-do | `scroll-text` | `rbxassetid://93551675076113` | `list-checks` |
| Daily reward, Login bonus | claim, streak | `calendar-check` | `rbxassetid://116665691227418` | `gift` |
| Rewards, Gifts, Free items | claim, bonus | `gift` | `rbxassetid://87706885156127` | `party-popper` |
| Codes, Redeem | promo code | `ticket` | `rbxassetid://126875062984266` | `key` |
| Leaderboard, Rankings | top players | `trophy` | `rbxassetid://113055182645565` | `medal` |
| Stats, Profile numbers | levels, progress | `bar-chart-3` | `rbxassetid://130626786024244` | `activity` |
| Trading | swap with players | `arrow-left-right` | `rbxassetid://112517617090898` | `repeat` |
| Friends, Party, Team | invite, group | `users` | `rbxassetid://85332511060401` | `user-plus` |
| Chat, Messages | talk | `message-circle` | `rbxassetid://74163263000218` | — |
| Rebirth, Prestige | reset for bonus | `refresh-cw` | `rbxassetid://106497040962250` | `repeat` |
| Upgrades, Boosts | improve, level up | `arrow-up-to-line` | `rbxassetid://135365442561417` | `zap` |
| Gamepasses, VIP, Premium | paid perks | `crown` | `rbxassetid://92253403464658` | `gem` |
| Currency: coins, cash | money | `coins` | `rbxassetid://117341212186115` | `wallet` |
| Currency: gems, diamonds | premium currency | `gem` | `rbxassetid://125353572203968` | — |
| Emotes, Dances | animations | `smile` | `rbxassetid://129431925610335` | `party-popper` |
| Music, Radio | songs, sound | `music` | `rbxassetid://132132095360900` | `radio` |
| Map, Areas, Worlds | zones, islands | `map` | `rbxassetid://131325044235094` | `compass` |
| Achievements, Badges | milestones | `medal` | `rbxassetid://97534791863003` | `trophy` |
| Help, Tutorial, How to play | guide | `help-circle` | `rbxassetid://71693802872044` | `book-open` |

### Features and toggles

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Aimbot, Aim assist, Lock on | aim, target | `crosshair` | `rbxassetid://83752373575368` | `target`, `locate-fixed` |
| Walk speed, Speed | run faster | `gauge` | `rbxassetid://128279962545721` | `zap` |
| Fly | flight | `plane` | `rbxassetid://123931033451986` | `feather` |
| Noclip, Walk through walls | ghost mode | `ghost` | `rbxassetid://132705178126217` | — |
| Infinite jump, Jump power | jump higher | `arrow-up-to-line` | `rbxassetid://135365442561417` | — |
| God mode, No damage | invincible | `shield` | `rbxassetid://106509993556171` | `shield-check` |
| Anti-AFK, Stay online | keep active | `timer` | `rbxassetid://120164083411828` | `clock` |
| Auto clicker, Auto click | click for me | `mouse-pointer-click` | `rbxassetid://81854854241463` | — |
| Kill aura, Auto attack | hit everything near | `swords` | `rbxassetid://99199363807265` | `skull` |
| Auto collect, Magnet | grab drops | `coins` | `rbxassetid://117341212186115` | `hand-coins` |
| Auto fish | fishing | `fish` | `rbxassetid://114555142566431` | — |
| Auto mine | mining, ore | `pickaxe` | `rbxassetid://111300940329486` | — |
| Auto chop, Wood | trees | `axe` | `rbxassetid://84931585672806` | `tree-pine` |
| Fullbright, No fog | see in the dark | `sun` | `rbxassetid://139232691165198` | `lightbulb` |
| Player ESP, Names, Tracers | see players | `eye` | `rbxassetid://127234874352422` | `scan` |
| Item or chest ESP | see items | `box` | `rbxassetid://117371753006597` | `package` |
| Server hop, Rejoin | new server | `server` | `rbxassetid://105706502741449` | `refresh-cw` |
| Unload, Destroy script | turn it all off | `power` | `rbxassetid://89331085993646` | `log-out` |

### Window and field controls

| Tab or feature | People also say | Icon | Content id | Also fits |
|---|---|---|---|---|
| Close | the X | `x` | `rbxassetid://116396312853810` | — |
| Minimise, Hide | the dash | `minus` | `rbxassetid://95070996149109` | — |
| Back | previous page | `chevron-left` | `rbxassetid://102314312897830` | — |
| Dropdown arrow | open the list | `chevron-down` | `rbxassetid://71457658246709` | — |
| Search | find | `search` | `rbxassetid://72296609649861` | — |
| Refresh, Reload | update the list | `refresh-cw` | `rbxassetid://106497040962250` | `rotate-cw` |
| Locked | not yet available | `lock` | `rbxassetid://119765975153029` | — |
| Unlocked | available | `lock-open` | `rbxassetid://71186154315213` | `unlock` |
| Copy | copy text | `copy` | `rbxassetid://116378866141355` | — |
| Delete | remove | `trash-2` | `rbxassetid://126010725826757` | — |
| Save | keep settings | `save` | `rbxassetid://122894934359450` | — |
| Success notification | done | `check-circle` | `rbxassetid://105979545056636` | — |
| Warning notification | careful | `alert-triangle` | `rbxassetid://112102474509324` | — |
| Error notification | failed | `x-circle` | `rbxassetid://111132030834422` | — |
| Info notification | note | `info` | `rbxassetid://120620848266512` | — |
---

## When the user names an icon

"Use a sword for combat": check the name exists
(`grep -P "^sword\t" icon-ids.txt`) and use its id. If the word is not a Lucide
name ("a diamond"), search the tags column and offer the closest match by name:
`gem` for diamond, `crown` for VIP. If nothing matches, say so and use the
nearest row above; never invent an id.
