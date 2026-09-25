# Economy math

Numbers a first version can start from, and the checks that tell you when
they are wrong. Every figure here is a starting point to test, not a law.

## Map the flows first

Write the table before the code.

| Currency | Sources | Sinks | Multipliers | Gates |
|---|---|---|---|---|
| Coins | selling, quests, daily reward | upgrades, eggs, zone doors | pets, boosts, rebirth | zone price, level |
| Gems (premium) | purchases, rare drops, streaks | boosts, exclusive eggs | none | none |

A source with no sink, or a sink with no source that matches its size, is
the first thing to fix.

## Cost curves

Upgrade prices usually grow geometrically: each level costs `growth` times
the last. Earnings usually grow more slowly, which is what makes each level
take a little longer than the one before.

```lua
local function upgradeCost(level: number, base: number, growth: number): number
	return math.floor(base * growth ^ (level - 1))
end

-- base 10, growth 1.15: level 1 costs 10, level 10 costs 35, level 30 costs 575
print(upgradeCost(1, 10, 1.15), upgradeCost(10, 10, 1.15), upgradeCost(30, 10, 1.15))
```

| Growth per level | Feel |
|---|---|
| 1.07 to 1.12 | gentle; long upgrade tracks with many levels |
| 1.15 to 1.25 | the usual simulator range |
| 1.3 and up | steep; a few levels per tier, then a gate or rebirth |

## Time to the next goal

The number that matters is **how long the next purchase takes at the
current earning rate**. Compute it for the first ten goals:

- first goals within a minute or two;
- a steady climb through the first session;
- a gate (new zone, rebirth) where the time jumps, with something new behind
  it that justifies the wait.

A goal that takes much longer than the one before it with nothing new behind
it is the wall where players quit.

## Rebirth and prestige

Rebirth resets progress for a permanent multiplier. Price it where the
climb has become slow, and give a multiplier large enough that the second run
reaches the old wall noticeably faster, or nobody presses it twice.

## Checking the live economy

Log every source and sink with `AnalyticsService:LogEconomyEvent`
(`retention-and-analytics.md`). Then watch:

- **average ending balance rising week on week** with nothing new to buy:
  inflation, so add sinks;
- **most players stuck at one balance**: a wall;
- **one source far above the others**: an exploit or a farming route.
