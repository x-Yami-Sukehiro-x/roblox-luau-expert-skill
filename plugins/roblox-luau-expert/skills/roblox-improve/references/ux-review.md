# UX review: what the linter cannot count

`lint-roblox-ui.mjs` counts text sizes, radii, spacing, targets and
handlers. These are the checks it cannot make, in the order a player meets
them. Each failure goes into the review with where it is and what the
player experiences.

## The first thirty seconds

- Is there one obvious thing to do? One element has the largest type, the
  accent and the most space.
- Can a player who never read a tooltip do it? Labels name the action
  ("Buy for 250 Gems"), not the category ("Confirm").
- Does anything block play before the player has played? Menus, codes and
  settings come after the first reward, not before.

## Feedback for every action

Every press answers within a frame: a press state, then the result. If the
result takes longer than about 0.3 s (a purchase, a teleport), show that it
is working. Silent success reads as failure; a toast for every trivial
action reads as noise.

## The six states

Rest, hover, press, focus, disabled, selected, on every control. Disabled
controls say why ("Reach level 5"), not only grey out.

## Words

Read every label aloud in order. Three tabs named Settings, Options and
Configuration are one word three times. Errors say what happened and what to
do, in the player's words: "Not enough Coins (need 40 more)", not
"Transaction failed".

## Phone pass

At 390 x 844 portrait and 640 x 360 landscape: nothing cut off, targets 44 px
after scaling, primary actions in the lower half where thumbs rest, nothing
destructive under a resting thumb, nothing only on hover.

## How an action feels

For anything the player does repeatedly (hitting, collecting, buying), feel
comes from several small responses at once, scaled to how much the moment
matters. Three tiers keep it proportional:

| Tier | Example | Feedback |
|---|---|---|
| Small | coin pickup, hover | a tick sound, a small pop (scale 1.1 back to 1 over 0.15 s) |
| Medium | a hit, a purchase | sound, a flash, a short camera nudge, a number that rises and fades |
| Large | a boss hit, a level up | all of the above, stronger, plus a brief hold before the result |

Feedback moves the visual, never the simulation: shake the camera, not the
character. Everything returns to rest; a shake that never decays is the new
normal. Offer "reduce screen shake" and "reduce flashing" in settings, and
honour `GuiService.ReducedMotionEnabled`. The tier model is adapted from the
`game-feel` skill in `gamedev-skills/awesome-gamedev-agent-skills`
(Apache-2.0).
