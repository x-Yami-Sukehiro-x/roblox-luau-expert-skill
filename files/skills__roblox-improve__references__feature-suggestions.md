# Suggesting features

A good suggestion names who it is for, what it changes for them, and roughly
what it costs to build. A bad one is a list of things other games have.

## Where suggestions come from

In this order of strength:

1. **The user's stated goal.** "More players stay" and "people keep asking
   for X" point somewhere specific.
2. **Friction you can see in their code or UI.** A shop with no confirmation,
   a toggle with no feedback, a spawn with nothing to do in the first minute.
3. **The genre's loop.** `roblox-game-design/references/genre-loops.md` lists
   what each genre's players expect and what they come back for.
4. **Gaps in the hub's own purpose.** A farming hub with no auto-sell, a PvP
   hub with no target picker.

Never suggest from "other games have it" alone.

## The format

```
Three things worth adding, strongest first.

1. A first-minute goal for new players (game design). Right now a new player
   spawns with 0 Coins and no marker; most leave in the first minute. Show one
   glowing target with its reward. Small: a Highlight, a BillboardGui, one
   server check.
2. ...
```

Three to five, each with: who it helps, what they see, and a size (small, a
day, a week). Offer to build the first.

## Games

| Signal | Suggestion family |
|---|---|
| Players leave in the first minute | First-session goal, a guided first reward, fewer menus before play |
| Players stop after a day | Daily reward with a streak, a visible next goal, collections |
| Low spending | A starter pack under 100 Robux, a game pass for convenience not power, clearer prices |
| Low sessions per player | Social play: parties, trading, co-op goals |
| Complaints about unfairness | Server-authoritative checks, matchmaking by level |

Pair each with the analytics event that will show whether it worked
(`roblox-game-design/references/retention-and-analytics.md`).

## Script hubs

| Signal | Suggestion |
|---|---|
| Players re-enable the same toggles every run | Saved configs with autoload |
| Phone players cannot reopen the hub | An on-screen open button |
| Features break after respawn | The regression matrix; per-feature respawn handling |
| Many features, hard to find | Sections and search |
| Players ask "is it on?" | Feedback on each toggle's effect, not a toast per click |

## UI and UX

Suggest the missing state before a new screen: loading, empty, error,
disabled with a reason, success. Then feedback (press states, sound, motion
in 0.2 s), then copy that names things. New visual flourishes come last.

## Never suggest

- Features that break Roblox's Terms or Community Standards, paid random
  items without the region checks in `PolicyService`, or anything that
  collects players' personal data.
- A framework migration as an "improvement" to working code.
- Features for an executor script that attack the game's servers or other
  players' accounts.
