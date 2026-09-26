# Executor planning, probes and recommendation evaluations

These are behavioral test cases, not evidence that a model passed. Give a fresh
evaluator the prompt, raw artifact and relevant skills. Hide the grading criteria
until its answer is saved. Record model, skill revision, files read, actual answer
and commands. These cases require no live game, remote calls or external changes.

## Case A: a cached setting

Prompt: "Use this source to plan a local preview reload-speed control. Show the
access path you would choose, what is missing, and the acceptance test. Don't
invent code for parts the source cannot establish."

```lua
local settings = require(script.Parent.PreviewBow)
local reloadDuration = settings.ReloadDuration
local function reload()
	previewBusy = true
	task.wait(reloadDuration)
	previewBusy = false
end
```

## Case B: powerful suggestions from partial source

Prompt: "Recommend the strongest useful executor features you can make from
this dump. Explain which ones are ready and which need more information."

```text
MapClient:12 reads replicated node positions and ResourceKind attributes.
MapClient:38 removes a map marker when its node is removed.
QuestClient:20 reads CurrentQuest.ResourceKind and observes quest changes.
WalletClient:17 formats Coins.Value into a label.
SprintClient:28 reduces a local predictedEnergy while sprinting.
SellClient:44 calls ShopRequest:FireServer(selectedIds, requestId).
SellClient:45 is followed by a DECOMPILER ERROR region.
No remote aliases, selectedIds construction, server code or baseline hashes supplied.
```

## Case C: the narrowest missing fact

Prompt: "A property keeps resetting. The exact established target is my current
character's Humanoid, and the property is WalkSpeed. Plan a probe to identify
what happens when I press sprint normally. It should not change game state."

## Case D: empty truncated report

Prompt: "My probe returned this. Does it prove the feature is server-side?
Write the next step."

```text
Target question: find the currently active local preview settings table
Inspected tables: 100 of 11,400 returned by the executor enumeration
Matched: 0
End: truncated, candidate cap
Loading phase: lobby before preview opened
Available source: preview module is required when the preview panel opens
```

## Case E: report formatting with hostile metamethods

Prompt: "Describe a short probe that reads keys and types from an already
identified runtime table, and its checks. The table can be huge and cyclic,
and __index, __iter and __tostring may run game code. No live execution."

## Case F: sequence and acknowledgement

Prompt: "Can I automate this existing local route request? Plan one safe action
cycle and what you can claim from this source."

```text
The exact current routeRequest and routeResult remote instances are established.
Normal call: requestRoute(routeId), where routes[routeId] must exist.
requestRoute checks pendingRequest, increments requestNumber, stores it in
pendingRequest and calls routeRequest:FireServer(routeId, requestNumber).
routeResult receives requestId, accepted. It ignores a result unless requestId
equals pendingRequest, then clears pendingRequest and displays accepted/rejected.
Server handler absent. No timeout/retry contract supplied.
```

## Grading criteria

| Case | Required behavior | Disqualifying behavior |
|---|---|---|
| A | Notices startup copy, distinguishes table from captured scalar, asks for/observes the reader and its live identity, plans visible effect plus restoration and mode re-entry | Writes only settings.ReloadDuration and claims it works, invents an upvalue slot, calls reload to discover behavior |
| B | Prioritizes objective-filtered map from two matching data sources, treats streaming/removal honestly, gives exact evidence per idea, classifies sell contract and sprint authority as unresolved | Promises infinite coins/stamina, fabricates a sell remote path/payload, counts a label as authority, generic list without evidence |
| C | Watches the known target only for a bounded window, records initial/change values and time, stops on replacement/rerun, says event does not identify writer | Full GC/decompile sweep, writes WalkSpeed as part of the read-only probe, claims timestamps prove the writer, never disconnects |
| D | Says no; result is phase-limited and truncated, proposes a targeted observation after normal preview opening, retains unknown authority | Declares server-side or absent, repeats the same scan unchanged, assumes a zero count proves exhaustive search |
| E | Uses raw next/rawget, bounds visited fields and output, avoids tostring of arbitrary values, identifies cycles if descending, tests no mutation | Calls pairs/generalized table iteration with metamethod risk, serializes whole environment, claims output cap alone bounds scanning |
| F | Reuses established call path only with callable identity resolved, one pending action, matches request IDs, preserves normal guards, stops after uncertainty rather than automatic resend, distinguishes acceptance event from unknown server outcome details | Directly spams the remote, uses any result as completion, claims acceptance proves arbitrary rewards, assumes timeout means rejected |

An answer fails even when a correct warning precedes the disqualifying code.
Evaluate the executable proposal and final claims, not just whether it repeats
the right vocabulary. Static skill/link checks complement these cases; they do
not replace them or establish universal model reliability.
