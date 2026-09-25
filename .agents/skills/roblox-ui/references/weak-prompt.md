# From a weak prompt to a shippable screen

"make me a gui", "make a ui for my script", "a shop menu, make it look good".
The prompt names a thing and nothing else. The result still has to look
designed, fit every screen and work on every input. That is possible because
almost every decision has a right default; the prompt only has to supply what
the screen is for, and the user's own files usually supply the content.

## What a weak prompt still tells you

| Signal | Where it is | What it decides |
|---|---|---|
| the surface | "executor", "script", a pasted script with `getgenv` / a game's LocalScript / a plugin | hub, game screen or plugin (`responsive-and-surfaces.md`) |
| the screen | "hub", "shop", "settings", "menu" | the archetype (`screen-archetypes.md`) |
| the content | the user's script: feature names, remotes, config tables, item lists | every row, tab and label; never invent placeholder features |
| the game | the place's name or genre, if given | the direction (`design-directions.md`, "Choosing between them") |
| taste words | "clean", "modern", "sick", "like Blox Fruits" | a direction and density, translated with `../../roblox-request-intake/references/vague-to-spec.md` |
| earlier picks | `PROJECT_CONTEXT.md`, memory, the conversation | style codes and palette already chosen; never re-ask |

## Decide these, in order

1. **Archetype and hero.** The nearest archetype, and the one thing that gets
   the largest type, the accent and the most space. A hub has no hero: the
   window stays quiet.
2. **Content inventory.** List what the screen shows, from the user's files,
   in the game's words: `Fly`, `Walk speed`, `Auto farm`, not `Feature 1`,
   `Option`, `Toggle`. No file? Build the minimum the archetype needs and name
   the rows from the request.
3. **Grouping.** Two to five tabs or sections named for what the player does
   there (`Movement`, `Visuals`, `Farming`), never `Main`, `Misc`, `Settings`,
   `Other`. Under five rows, no tabs.
4. **Direction.** Slate unless the game or a taste word says otherwise;
   match an existing project over any default. One accent, used three to five
   times.
5. **Sizes.** From `../../roblox-ui-viewport/references/device-matrix.md`:
   scale size, `UISizeConstraint` with a minimum that fits 640 x 300, type
   12/14/16/20/28, spacing 4/8/12/16/24/32, radius 6 and 10.
6. **Style codes.** The user's picks, or the one grouped question with the
   picker link (`../../roblox-request-intake/references/visual-choices.md`),
   asked as the end of the turn with decisions 1 to 5 stated beside it.
   "Choose for you" means the suggestion in that question: T1, M1, N1 and O1,
   with N4 for a script hub, built from the recipes as written.
7. **States.** Empty, loading, error and disabled-with-a-reason for every
   list and action, built now, in the game's words.
8. **Input and fit.** Every control on mouse, touch and gamepad
   (`../../roblox-ui-interaction/SKILL.md`); every screen from 640 x 360 to 4K
   (`../../roblox-ui-viewport/SKILL.md`).

State the result in the reply as a short brief before or beside the code, so
the user can correct a premise with one word:

```text
Built as: script hub, Slate, 3 tabs (Movement, Visuals, Player), 11 rows from your script.
Picks: T1 toggles, M1 opening, N4 notifications (the choose-for-you suggestion).
Fits: 640x360 phone to 4K (viewport_fit.py); mouse, touch, gamepad.
```

## The ship bar

A screen ships when every line holds. Each has a check that does not need
taste.

| # | Holds | Check |
|---|---|---|
| 1 | one hero, or deliberately none | the reading test in `self-review.md` |
| 2 | every label is real content in the game's words | no `Feature`, `Option`, `Button`, `Label`, `Lorem`, `Main`, `Misc` |
| 3 | one token block; no colour literal outside it | `lint-roblox-ui.mjs` H1 |
| 4 | type, spacing and radius on the scales | `lint-roblox-ui.mjs` C1, C3, C5 |
| 5 | root bounded and fits a phone | `E-UNBOUNDED`, `E-MINFIT`; `viewport_fit.py` |
| 6 | nothing clipped or poking out | `E-STROKECLIP`, `E-CORNERBLEED` (`clipping.md`) |
| 7 | every control on every input | `E-MOUSEONLY`, `W-TOUCH`; the input matrix |
| 8 | six states on every control | `W-STATES`, `E-AUTOBUTTON`; `component-states.md` |
| 9 | empty, loading and error states exist | read every list and action |
| 10 | motion 0.20 s in, 0.15 s out, nothing idles | `../../roblox-ui-motion/SKILL.md` |
| 11 | every connection torn down | `E-LEAK`; the unload path |
| 12 | no recorded mistake is back | `attempt-ledger.mjs check` |

`node tools/bin/check-file.mjs <file>` runs rows 3 to 8, 11 and 12 at once.
Rows 1, 2, 9 and 10 are read, and the reply says they were read.

## What not to add because the prompt was vague

A weak prompt is not permission to decorate. None of these by default:
gradient headers, glow on everything, emoji as icons, a big logo, a
changelog panel, a welcome screen, fake stats, placeholder features to fill a
tab, a colour per tab. `anti-slop-catalog.md` has the full list and why each
reads as generated.
