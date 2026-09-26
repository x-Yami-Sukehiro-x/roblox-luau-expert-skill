# Ranking features from evidence

The following source inventory is fictional and intentionally incomplete:

| Location | Observed behavior |
|---|---|
| `QuestTracker:24` | The current objective has a `ResourceKind` field |
| `ResourceMap:38` | The map shows positions for replicated resource objects |
| `ResourceMap:61` | A removal event deletes the marker for a disappeared object |
| `InventoryView:17` | Items have a displayed type, quantity and favorite state |
| `SellButton:45` | A request passes the selected item IDs, with favorite items excluded |
| `SellButton:67` | A result event matches the request ID and refreshes the display |
| `Wallet:12` | A replicated number is formatted into a currency label |
| `Sprint:31` | The client predicts energy consumption; server behavior is absent |

## Useful recommendations

| Feature | Benefit and mechanism | Boundary and next check |
|---|---|---|
| Objective resource map | Filter existing resource markers by the current objective; the tracker and map supply both sides of the relation | Local display of replicated resources; verify exact type matching and objective changes, keep missing streamed content unknown |
| Sell selection preview | Show which non-favorite items the existing action would sell and let the player review the list | Local selection is supported; preserve favorites and do not invent a price calculation the source does not show |
| Stop-after-result sale queue | Reuse the established request path, wait for its matched result, then continue only while enabled | Conditional on complete call contract, guards and cancellation; server acceptance is observed per request, not guaranteed from the client |

The map is a strong first choice when the user wants immediate utility: both
data sources and marker removal behavior are present, with no server action or
new payload to infer. The queue is not automatically the strongest idea merely
because it sounds more powerful; it has more state and result handling to prove.

## Ideas that need evidence

"Show estimated sale value" needs a price source. An item quantity and a sell
button do not establish its value. Ask for the price reader or a narrow
observation that locates it; do not invent a formula based on rarity colors.

"Keep sprint enabled indefinitely" depends on which code owns meaningful energy
and movement. The client prediction supports an energy display or warning, but
it does not establish that changing the local number prevents server exhaustion.
The next fact is the authority/reset path, not an arbitrary higher number.

## Ideas the inventory does not support

"Infinite currency" has no granting mechanism in the supplied source. Changing
the wallet label is a different outcome. "Sell every item instantly" ignores
the documented favorites filter, request matching and unknown server pacing.
"Reveal every resource across the map" exceeds a list of objects currently
replicated to the client. Name these boundaries once; do not pad the answer with
a long list of impossible ideas.

## Better labels follow a real decision

| Vague label | Useful label when that is the actual behavior |
|---|---|
| Smart Auto Farm | Follow current objective |
| Advanced Selling | Sell selected items |
| Premium ESP | Show objective resources |
| Powerful Config System | Remember map filters |

A precise label is not a substitute for evidence. "Sell selected items" still
requires a real action contract, and "remember map filters" still requires a
user preference worth persisting. Do not suggest a config or notification panel
to make a small feature seem more substantial.
