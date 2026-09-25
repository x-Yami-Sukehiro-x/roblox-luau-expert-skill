---
name: roblox-executor-scripting
description: How an expert writes executor scripts - evidence before code, one layer per value, multi-game loaders by GameId, remotes from call sites, cross-executor checks. Use for any new executor script.
---

# Writing executor scripts like an expert

`roblox-executor` is the reference: the sUNC API, hooking, decompiled
source, which call reaches which value. `roblox-executor-features` is the
tested features. `roblox-executor-reliability` keeps a feature working.
This skill is the order an expert works in, so those three are used in the
right sequence and nothing is guessed.

## The loop

1. **Name the effect and its owner.** "Walk faster" is a Humanoid property
   the client owns; "more coins" is a server value no client script can
   change. `roblox-executor/references/technique/client-feasibility.md`
   decides which requests are possible before any code exists. Say so when
   one is not.
2. **Find the evidence.** A universal effect (fly, ESP) starts from the
   tested asset in `roblox-executor-features`. A game-specific one starts from
   the game's own code: search the dump for the feature
   (`python tools/py/dump_index.py <dump> --feature "<words>"`), and when it
   is not there, send `runtime-probe.luau` rather than guessing names.
3. **Pick one layer.** The value is a property, an upvalue, a constant, a
   module table field, or rewritten each frame by a loop. One call reaches
   each; `roblox-executor/references/technique/function-selection.md` is the
   table. No fallback chain across layers.
4. **List every writer.** The game's scripts, the Humanoid, respawn, the
   camera scripts, the player's other features. Hold the value against the
   writers that exist, with the mechanism that matches
   (`roblox-executor-reliability`).
5. **Build from the closest tested asset**, one bind and one assert for the
   executor functions it uses, a `getgenv()` session, and an unload that
   restores the captured value.
6. **Run the matrix**: runs, toggle twice, game writes, respawn on and off,
   rerun, unload twice, chat typing, phone, other features on. "It works"
   without the matrix is a guess.
7. **Record** the attempt in the ledger (`roblox-attempt-memory`) and deliver
   the whole script with what it assumes.

## Choosing the script's shape

| What the user wants | Shape |
|---|---|
| One feature | One file: session, feature, unload. The feature assets are this shape |
| Several features, one game | One file per concern is overkill; one script, one HubKit window, a section per group |
| A hub for many games | A loader that routes by `game.GameId`, a module per game, a universal fallback: [script-architecture.md](references/script-architecture.md) |
| A library other people build on | `roblox-hub-library` |

Route by **`game.GameId`**, not `game.PlaceId`: every place of one experience
(lobby, match, event place) shares the GameId, while each has its own
PlaceId. The tested loader is `assets/hub-loader.luau`.

## Remotes

Take a remote's name, method and argument shapes from a call site in the
game's code or a logged call, never from what it "probably" takes. A value
sent to a remote is a request the server may refuse; a changed client value
is not proof the server accepted anything.
[remotes-from-evidence.md](references/remotes-from-evidence.md) covers
reading call sites, what survives serialisation, and rate limits.

## Across executors

Executors differ in which functions exist, what `identifyexecutor()` returns,
and how their file functions behave. Detect each capability once, assert on
the list, report what is missing in one sentence, and never claim an
executor was tested when it was not.
[compatibility.md](references/compatibility.md) has the patterns.

## Habits that separate expert scripts

- **Capture before you change.** Read the original value, store it, restore
  that value on unload, never a retyped literal.
- **Event-driven over polling.** `GetPropertyChangedSignal`, `CharacterAdded`
  and `ChildAdded` over `while task.wait()` loops; per-frame work only for
  per-frame effects.
- **Cache what does not change.** Services, the local player, remotes found
  once. Re-find what respawn replaces (the character, the Humanoid).
- **One owner per property.** Two features writing `WalkSpeed` fight; one
  feature owns it and the others ask it.
- **Everything under one session.** Hooks, connections, Drawings, threads
  and instances registered for unload as they are made.
- **Say what the script cannot do.** A server-side value, an unreadable
  region of a dump, a function the executor lacks: one line each in the reply.

## What this skill will not help with

Attacking a game's servers or other players (crashing servers, flooding
remotes, stealing items or accounts), hiding a script from anti-cheat, and
anything that sends a player's data somewhere. Say so plainly and offer the
closest legitimate help: a client-side feature, or how the game's own
developer would stop the exploit (`roblox-game-security`).

## Works with

- `roblox-executor`: the sUNC API, decompiled source, and the layer-to-call table.
- `roblox-executor-features`: the tested feature scripts to build from.
- `roblox-executor-reliability`: writers, ownership and the regression matrix.
- `roblox-hub-library`: the hub window, elements and configs around the features.
- `roblox-debugging`: executor error messages and what each one means.
- `roblox-attempt-memory`: never repeating a failed approach on the same game.
- `roblox-networking`: what replicates, and why a client write is not a server change.
- `roblox-code-craft`: the ceremony budget that keeps a 330-line script at 59.
