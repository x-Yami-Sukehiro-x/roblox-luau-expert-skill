# Signals in the source

What to look for in a client dump beyond the inventory's five sections, and
what each shape suggests. A signal is a reason to read the surrounding code,
not a feature. Every suggestion still needs the evidence, authority and
check rows from the skill.

## Shapes and what they suggest

| Shape in the source | Suggests | Read next |
|---|---|---|
| `if os.clock() - lastUse < COOLDOWN then return end` before a `FireServer` | The client paces the action; the server may or may not | Whether the server handler exists in the dump (it usually does not): the rate is the server's unknown, the local wait is not |
| A module table of numbers: `SprintSpeed`, `Range`, `Duration` | A client rule the player's own client applies | Which reader copies it at startup (archetype 3 in `roblox-decompiled-features`) |
| `FireServer(target, hitPosition)` from a client hit check | The client reports hits; the server decides damage | The client's range and angle check: it shows what the server might accept |
| `:GetAttribute("Rarity")`, `:GetAttribute("Value")` on world objects | Information the client already has | ESP or a filter by that attribute (archetype 5) |
| `CollectionService:GetTagged("Chest")` | A set of targets the client can enumerate | Collect, highlight or route between them |
| A `ProximityPrompt.Triggered` or `ClickDetector` in the world with a matching remote | An interaction the executor can trigger | `HoldDuration` and distance, then archetype 2 |
| A button `Activated` handler that builds a payload | A request the game already knows how to send | Calling the handler (archetype 7) rather than rebuilding it |
| `if not player:GetAttribute("VIP") then button.Visible = false end` | A client-side gate on UI | Whether the server re-checks; usually it does |
| `RunService.Heartbeat` writing `WalkSpeed` or `CameraMaxZoomDistance` | A game loop that will fight any change | The writer to hold against (`roblox-executor-reliability`) |
| `workspace.Zones`, `SpawnPoints`, `Waypoints` folders | Positions the client knows | Teleport or route aids (archetype 6) |
| `RemoteFunction:InvokeServer("GetStats")` | Data the server will tell the client | A tracker or overlay from the answer |
| A decompile error in the region that sends a request | A gap | A probe, never a guessed payload |

## Genre words are search terms, not suggestions

A genre tells you which words to search the dump for. What comes back is
evidence; what does not is not a feature.

| Genre | Search the dump for |
|---|---|
| Simulator | `Collect`, `Sell`, `Rebirth`, `Hatch`, `Egg`, `Upgrade`, `Multiplier`, `Zone` |
| Tycoon | `Dropper`, `Collector`, `Purchase`, `Button`, `Cash`, `Claim` |
| Obby and tower | `Checkpoint`, `Stage`, `KillPart`, `Kill`, `Spawn` |
| Fighting and PvP | `Hit`, `Damage`, `Combo`, `Block`, `Parry`, `Cooldown`, `Range` |
| RPG and adventure | `Quest`, `Mob`, `Loot`, `Drop`, `Level`, `Skill`, `Inventory` |
| Horror and survival | `Monster`, `Chase`, `Hide`, `Key`, `Door`, `Generator` |
| Racing and vehicles | `Vehicle`, `Seat`, `Throttle`, `Boost`, `Nitro`, `Checkpoint` |

```bash
python tools/py/dump_index.py <dump> --feature "collect sell rebirth"
```

Report what the words found with `script:line`, and say plainly which genre
staples the dump does not show.

## Combinations that make a feature strong

The strongest recommendations often join two proven facts rather than
stretch one:

- **Targets plus an interaction**: tagged chests plus `fireproximityprompt`
  is auto-open; add movement within range and it is a route.
- **An action plus its result event**: repeat only when the previous result
  arrived, so nothing is sent twice and the count is real.
- **Information plus a filter**: every spawn, filtered by the rarity
  attribute the client already reads.
- **A rule plus its reader**: the sprint table field and the controller that
  reads it every frame, so the change is visible.

Say which facts each combination depends on; if one is unproven, the whole
combination waits for it.
