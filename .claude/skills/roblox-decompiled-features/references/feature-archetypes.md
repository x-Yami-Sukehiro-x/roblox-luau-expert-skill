# Feature archetypes: from a source line to a working feature

Nearly every game-specific feature built from a dump is one of seven shapes.
Each shape names the evidence it needs, the one call that reaches the value,
what paces it, what stops it, and what the server still decides. Identify the
shape first; a feature that fits none of them needs a plan
(`roblox-executor-planning`) before code.

"OP" means the strongest version of one of these that the server accepts:
the full rate the game allows, every target in reach, no idle time. It never
means a value the client does not own.

## 1. Repeat an action the game already sends

Auto farm, auto collect, auto sell, auto hatch, auto rebirth.

| Needs | A call site: remote path, `FireServer` or `InvokeServer`, the arguments as the game builds them, and the guards before the call |
|---|---|
| Reaches it | Prefer the game's own function that sends it (its closure via `filtergc` by constant, or the button handler via `getconnections`); else the remote with the call site's exact arguments |
| Paced by | The cooldown the source uses before the call, or the result event the game waits for. Not faster |
| Stops on | The toggle, death, leaving the zone the guard checks, the target leaving |
| Server decides | Whether each request counts. A changed counter on screen is not proof |

The tested loop is [assets/action-loop.luau](../assets/action-loop.luau):
targets re-read each pass, the game's precondition checked before each
action, the interval from the source, a stop that takes effect after the
current action. Register its `start` and `stop` with the feature registry.

A game that waits for a result (`routeResult.OnClientEvent` in the worked
traces) needs `act` to wait for the matching result, not a fixed interval.

## 2. Interact with what the world offers

Auto open chests, auto press prompts, auto click, auto touch pads.

| Needs | The prompt, detector or part in the client's world, found by the tag, name or folder the source uses |
|---|---|
| Reaches it | `fireproximityprompt(prompt)`, `fireclickdetector(detector)`, `firetouchinterest(part, root, 0)` then `1` |
| Paced by | The prompt's `HoldDuration`, the game's debounce in the handler |
| Stops on | The toggle; the prompt's `Enabled` going false |
| Server decides | Whether the trigger counts. Move within the prompt's `MaxActivationDistance` first; an out-of-range trigger is the first thing a game refuses |

Streaming: a prompt in an unstreamed region does not exist on the client.
Collect targets from what is present and listen for `DescendantAdded`.

## 3. Change a rule the client applies to itself

Faster sprint, shorter local cooldown, wider local reach check, longer
ability duration on your own character.

| Needs | The value and where it lives: a module table field, an upvalue, a constant, a property |
|---|---|
| Reaches it | One API for that layer (`roblox-executor/references/technique/function-selection.md`) |
| Paced by | Nothing; it is a value |
| Stops on | Unload restores the captured original |
| Server decides | Whether it re-checks. A client cooldown the server also enforces changes the button, not the rate |

Find the **reader**: a value copied into a local at startup is not changed by
editing the table afterwards (worked traces, "a setting with two readers").

## 4. Remove a client-side gate

A button disabled until a level, a zone check before an action, a local
"can use" function.

| Needs | The gate function or condition in the source, and what calls it |
|---|---|
| Reaches it | `hookfunction` on the gate, returning what the pass case returns, with `restorefunction` on unload; or the value the condition reads (archetype 3) |
| Server decides | Almost always re-checks. Say so; the gate often exists because the server will refuse |

Build this only when the source shows the server does not own the result (a
cosmetic, a local mode) or the user accepts that the server may refuse.

## 5. Show what the client already knows

ESP for chests, rare spawns, other players' tools, a boss timer; trackers and
route aids.

| Needs | Where the data is: a tag, an attribute, a folder, a replicated value the source reads |
|---|---|
| Reaches it | Ordinary DataModel reads: `CollectionService:GetTagged`, `:GetAttribute`, `.Value`. No executor API |
| Paced by | Events (`GetInstanceAddedSignal`, `AttributeChanged`), labels refreshed a few times a second |
| Server decides | Nothing; it is display. It is also the safest strong feature there is |

Often the most useful "OP" feature: knowing where every rare spawn is beats a
risky speed change. `esp.luau` in `roblox-executor-features` is the base.

## 6. Move to the targets

Teleport to a chest, walk a route between spawns, follow the objective.

| Needs | Target positions from instances the client has, found as in 5 |
|---|---|
| Reaches it | `character:PivotTo(cframe)` for a jump; `Humanoid:MoveTo` for walking; the tested `click-teleport.luau` |
| Paced by | The server's movement check. Many games reject large jumps; walking or short hops holds |
| Server decides | Position validity. Test one hop before chaining a route |

Combine with 1 or 2: move within range, then act.

## 7. Call the game's own handler

"Buy the best upgrade", "equip the best pet", "claim every reward".

| Needs | The UI button or function the game calls for that action, and its arguments from the source |
|---|---|
| Reaches it | `getconnections(button.Activated)` and the connection's `Function`, called with the arguments the game passes; or the module function by constant |
| Paced by | Whatever the handler already does (it usually includes the game's checks and cooldown) |
| Server decides | As for 1, but the payload is right by construction |

This is the most reliable way to send a complex request: the handler builds
every field, including the ones the dump made hard to read. Guard on
`connection.LuaConnection`; C connections have no `Function`.

## Choosing between two that fit

- Prefer the game's own function (7) over rebuilding its payload (1).
- Prefer showing (5) over changing (3) when either serves the player's goal.
- Prefer a rule the client owns (3) over a gate the server re-checks (4).
- Prefer walking (6, `MoveTo`) over teleporting when the game checks movement.

## Checks per archetype

| Archetype | The check that proves it, beyond "no error" |
|---|---|
| 1, 2, 7 | The game's own result appears: leaderstat delta, inventory change, the result event with this request's id |
| 3 | The reader uses the new value: the sprint is faster, measured |
| 4 | The gated action runs, and the server's answer is reported |
| 5 | Markers appear for targets added after start, and vanish with them |
| 6 | Position after the move, one second later: not snapped back |
