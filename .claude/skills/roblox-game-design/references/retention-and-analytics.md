# Retention and analytics

The systems that bring players back, and the `AnalyticsService` calls that
show whether they work. All the calls below run on the server and take the
`Player`; signatures from the API dump
(`node tools/bin/verify-api.mjs AnalyticsService --members`).

## Systems, from cheapest to build

| System | Brings players back because | Build notes |
|---|---|---|
| daily reward with a streak | missing a day costs the streak | server clock, saved last-claim time, a grace window; UI from the daily reward archetype |
| short quests | a goal they can finish this session | three at a time, refreshed on a timer, rewards in the main currency |
| collections | one missing piece | a visible index with the gaps shown |
| timed events | it ends | a start and end time from the server, content that returns in a later event |
| friends | people | invite rewards, co-op bonuses, visible friends in the server |
| updates | something new | a steady cadence players can see coming |

Streak and cooldown times come from the server (`os.time()` on the server and
saved), never from the client's clock.

## Logging the first session

```lua
-- lint: fragment
local AnalyticsService = game:GetService("AnalyticsService")

AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Joined")
AnalyticsService:LogOnboardingFunnelStepEvent(player, 2, "First coin")
AnalyticsService:LogOnboardingFunnelStepEvent(player, 3, "First upgrade")
AnalyticsService:LogOnboardingFunnelStepEvent(player, 4, "Reached zone 2")
```

Steps are numbered in order and logged once per player. The drop between two
steps is the part of the first session to fix.

## Logging the economy

```lua
-- lint: fragment
AnalyticsService:LogEconomyEvent(
	player,
	Enum.AnalyticsEconomyFlowType.Source,
	"Coins",
	amount,
	balanceAfter,
	Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
	"SellOre"
)
```

`transactionType` is a string; the `Enum.AnalyticsEconomyTransactionType`
names (`IAP`, `Shop`, `Gameplay`, `ContextualPurchase`, `TimedReward`,
`Onboarding`) keep reports grouped the way Roblox's dashboards expect. Log
every source and every sink, with the balance after the change.

## Other events

| Call | Use |
|---|---|
| `LogProgressionStartEvent`, `LogProgressionCompleteEvent`, `LogProgressionFailEvent` | levels, stages, zones: where players stop |
| `LogFunnelStepEvent` | any other ordered flow, such as a shop purchase |
| `LogCustomEvent` | a single number worth charting, such as eggs hatched |

The older `Fire...` methods on `AnalyticsService` are deprecated; do not use
them.

## Live ops cadence

A predictable rhythm beats occasional large drops: a small update or event on
a regular schedule, announced in the game before it lands, with each event
tied to one of the systems above. Content that returns (a seasonal egg, a
recurring boss) costs less to make than content made once.
