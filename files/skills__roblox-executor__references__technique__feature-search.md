# Finding a feature in a dump, and what to do when it is not there

The user names a feature — "auto farm", "infinite stamina", "sell everything" —
and hands over decompiled source. Before a line of the script is written, the
dump is searched for the code that feature runs through, and the search ends in
one of three verdicts. Only one of them builds.

Related: `decompiled-source.md` for reading what the search finds,
`source-to-api.md` for choosing the call once the value layer is known.

---

## 1. Restate the feature as a mechanism

Translate the user's words into what the game must do for the feature to exist:

| They ask for | The game must have |
|---|---|
| auto farm, auto collect | a pickup: `Touched`, `ProximityPrompt.Triggered`, `ClickDetector`, or a remote that claims a drop |
| auto sell, auto buy | a remote or `InvokeServer` with an item or amount argument |
| infinite stamina, no cooldown | a number that is decremented or compared, and whoever resets it |
| auto hatch, auto roll | a remote with an egg or crate identifier |
| auto quest | a remote that claims or advances an objective |
| kill aura, auto hit | a damage remote and its argument shape |

Features built on the player's own character or camera — fly, noclip, speed,
jump, ESP, teleport, aim — need no game code. For those, the dump is read for
the code that **resets or detects** the change (a `Heartbeat` loop writing
`WalkSpeed`, a position-delta check), not for an implementation.

## 2. Index the dump

```powershell
python tools/py/dump_index.py <dump file or folder> --summary
```

It reads `.lua`, `.luau`, `.txt` and the script sources inside a saveinstance
`.rbxlx` / `.rbxmx`, and lists every remote call with its argument count at the
call site, every `OnClientEvent`, attribute, tag, `require` and failed-decompile
marker. Read the remote list in full: games often name remotes for the system
(`Network`, `Event`, `Remote`) rather than the feature, so the feature's words
alone would miss them.

No Python (a chat model without a code tool): do the same passes by reading.
Search every file, not the first one that looks right.

## 3. Search, in four passes

```powershell
python tools/py/dump_index.py <dump> --feature "auto farm"
python tools/py/dump_index.py <dump> --feature "stamina" --terms sprint,energy
```

1. **Names.** The feature's words and their synonyms (`farm` also searches
   `collect`, `coin`, `orb`, `drop`, `claim`...) against identifiers, strings,
   instance names, attribute keys and tags. Short words match whole tokens only,
   so `tp` does not match `HttpService`.
2. **Game vocabulary.** Add the words the summary showed this game uses —
   `--terms` — because the game calls its coins `Gems` or its farm `Harvest`.
3. **Trace.** For each hit, read the whole enclosing function and its callers.
   Follow aliases: `u3:FireServer(...)` means nothing until `local u3 =
   ...WaitForChild("CollectCoin")` is found — the tool prints that alias.
   Record the remote, call form, argument count and each argument's origin.
4. **Absence.** Count failed-decompile regions, `require`s of modules missing
   from the dump, and scripts that were never dumped. Absence in any of those is
   unknown, not proof that the logic is server-side.

The tool ranks hits by what they are: a remote call site (6) outranks an
instance name (5), a function, attribute or tag (4), a UI label (3), a string
(2), a bare identifier (1).

## 4. Record the evidence

One row per fact the script needs, each with `file:line` and one of
**observed**, **inferred**, **unknown**:

| Fact | Evidence | Status |
|---|---|---|
| remote path | `CoinCollector:5  WaitForChild("Remotes"):WaitForChild("CollectCoin")` | observed |
| call form | `CoinCollector:11  u3:FireServer(...)` | observed |
| arguments | `(p6.Name, p6.Position)` — coin's name, then its position | observed |
| where coins live | `CoinCollector:13  workspace.Coins.ChildAdded` | observed |
| server checks distance | not in the dump | unknown |

## 5. The verdict decides the reply

| Verdict | Means | Reply |
|---|---|---|
| **FOUND** | a remote call site, function, attribute, tag or instance name carries the feature, and every row the script needs is observed | build against exactly those rows |
| **PARTIAL** | only strings, labels or identifiers mention it; the mechanism is not shown | build nothing that depends on a missing row; send the runtime probe |
| **NOT FOUND** | nothing mentions it | send the runtime probe |
| **engine route** | fly, noclip, speed, jump, ESP, teleport, aim | build on the engine members the tool names; probe only if play shows a reset or kick |

FOUND with an unknown row is PARTIAL for the part that depends on it: the
indexer finding the remote does not tell you the third argument.

## 6. When the dump does not have it: send the runtime probe

**Never search by guessed names.** Each of these looks like work and is a guess
that mutates or fires something nobody identified:

```lua
-- all three are wrong without evidence
ReplicatedStorage.Remotes:FindFirstChild("AutoFarm"):FireServer()
for _, remote in ReplicatedStorage:GetDescendants() do
	if remote.Name:lower():find("sell") then remote:FireServer() end
end
for _, fn in getgc() do
	if table.find(debug.getconstants(fn), "Stamina") then debug.setconstant(fn, 1, math.huge) end
end
```

Instead, send `../../assets/runtime-probe.luau` unchanged except its `KEYWORDS`
line, which `dump_index.py` prints for a PARTIAL or NOT FOUND verdict. The
probe only reads. It writes `feature-probe.txt` to the executor's workspace
folder with:

- every remote under `ReplicatedStorage`, `ReplicatedFirst`, `Workspace`,
  `StarterPlayer`, `StarterGui`, `Lighting` and the player, keyword matches starred;
- client scripts whose path matches, with `getscripthash` when available;
- `getgc` closures whose string constants match, with source, line, parameter
  and upvalue counts, and their number constants;
- `getgc(true)` tables with a matching key, read with `next` so no metamethod runs;
- the player's attributes, `leaderstats`, `Humanoid` speeds and health;
- `decompile` output of the matching scripts, or a line saying it is unavailable.

The reply that sends it says, in the user's words: run it once in the game,
open the executor's `workspace` folder, and paste or attach `feature-probe.txt`.
Nothing else is built for that feature in the same reply. When the report comes
back, save it next to the dump and run the search again: it is a `.txt`, and
its decompiled sources are searched like any other script.

## 7. After the probe

- A starred remote with no call site is still unknown in its argument shape.
  Ask for the decompile of the script that fires it (the report names matching
  scripts) rather than guessing arguments.
- A closure match gives a lead, not identity. Two closures with the same
  constant are ambiguous until a second source fact separates them —
  `decompiled-source.md`, "Ambiguity is a stop condition".
- A value in `leaderstats` or a server-owned attribute changed on the client
  does not change the server's copy — `client-feasibility.md`.
- The report showed nothing: say so. The feature may be server-side, in an
  unloaded module or another VM; the dump and probe together do not locate it.
