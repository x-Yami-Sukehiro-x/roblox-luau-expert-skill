---
name: roblox-game-design
description: Roblox games that keep players - genre loops, first session, progression and economy math, retention. Use for make me a game, balancing.
---

# Game design for Roblox

Code that works is half of a game. The other half is why a player does the
next thing: what they get in the first minute, what they aim for in the first
hour, and why they come back tomorrow. This skill gives those decisions
defaults, so "make me a game" produces a loop that holds, not a baseplate with
a shop.

## Three time scales

Design the loop at all three before writing systems.

| Scale | Question | A working answer looks like |
|---|---|---|
| a minute | what does the player do, and what do they get for it? | click, collect, deliver; a number goes up with a sound |
| an hour | what are they working towards? | the next area, a rebirth, a rare pet, a rank |
| a week | why come back tomorrow? | a streak, a timed event, friends, a collection one short of complete |

A game with only the first is a toy; one with only the third is a chore.
Genre defaults for all three: `references/genre-loops.md`.

## The first session

Most players decide within their first session whether to return, so build it
first and measure it.

1. A reward in the first minute, before any menu or tutorial wall.
2. One goal on screen at a time, in the game's words ("Reach the Lava Zone").
3. The core action taught by doing it once, not by reading.
4. The first purchase prompt only after the player has played enough to
   want what it sells.
5. Each step logged with `AnalyticsService:LogOnboardingFunnelStepEvent`, so
   the drop-off point is a number, not a guess
   (`references/retention-and-analytics.md`).

## Economy

Every currency needs **sources** (how it is earned) and **sinks** (what uses
it up). A source without a sink inflates until prices mean nothing; a sink
without a matching source becomes a wall where players quit. Cost curves,
reward pacing and a worked example: `references/economy-math.md`.

- The server owns every balance and every price (`../roblox-game-security/SKILL.md`).
- Balances are saved with `UpdateAsync` and a schema version
  (`../roblox-data-persistence/SKILL.md`).
- Log each source and sink with `AnalyticsService:LogEconomyEvent`, so the
  dashboard shows where currency comes from and where it goes.

## Monetisation that fits the loop

Sell time, convenience and expression, not the win: boosts, extra slots,
cosmetics, a second pet equipped. A pass that decides who wins a fair fight
makes free players leave, and they are most of the server. Mechanics,
receipts and region rules: `../roblox-monetization/SKILL.md`.

## Deciding for a vague request

"Make me a game" gets one question, the genre, then this skill's defaults for
that genre, built as one complete loop end to end: spawn, the core action,
one progression step, one reward, data saved, one UI screen from
`../roblox-ui/references/screen-archetypes.md`. State the loop in three lines
in the reply so the user can change it before more is built.

| Need | File |
|---|---|
| loops, progression and what breaks, per genre | `references/genre-loops.md` |
| sources and sinks, cost curves, reward pacing | `references/economy-math.md` |
| first session, daily rewards, quests, events, analytics calls | `references/retention-and-analytics.md` |

## Works with

- `roblox-monetization`: what is sold and how purchases are granted.
- `roblox-data-persistence`: every balance, streak and unlock is saved.
- `roblox-ui`: screen archetypes for shop, daily reward, quests and HUD.
- `roblox-game-security`: the server owns currency, prices and rewards.
- `roblox-npc-ai`: enemies and waves the design calls for.
- `roblox-combat`: fights that are fair and feel good.
- `roblox-improve`: grounded feature suggestions for an existing game.
