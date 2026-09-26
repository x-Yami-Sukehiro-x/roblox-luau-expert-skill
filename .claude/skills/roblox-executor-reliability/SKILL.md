---
name: roblox-executor-reliability
description: Making an executor feature hold - who rewrites it, respawn, rerun, unload, combined features. Use for doesn't work, stops after respawn.
---

# Executor features that work

A feature works when the player presses the key in **their** game and the
effect appears, stays, survives a death and a rerun, stops cleanly, and
nothing that worked before breaks. Most failures are not in the feature's
main line. They are in what the game does around it.

Scope and ban risk are stated once in `roblox-executor`: private and
educational use, on accounts you control.

## Before writing a line

1. **Name the effect in the player's terms.** "Fly" means: moves in the
   camera's direction, holds height with no input, works on the phone
   thumbstick, lands on the key. Write the acceptance list first; it becomes
   the test.
2. **Who owns the value?** The client owns its character's physics, its
   camera, its lighting and its view of others: generic assets work
   (`../roblox-executor-features/SKILL.md`). A game value (a cooldown, a stat,
   a gun's fire rate) lives in the game's own code: find it in the dump first
   (`../roblox-executor/references/technique/feature-search.md`). A server
   value (currency, damage, inventory) cannot be written from the client;
   say so and look for the request the game already sends.
3. **Which layer, one API.** The table in
   `../roblox-executor/references/technique/source-to-api.md`. No fallback
   chain across layers.
4. **Who else writes it?** List every writer before choosing how to hold the
   value: the game's scripts, the Humanoid's own state machine, respawn, the
   camera scripts, the player's other features. `references/failure-modes.md`
   lists the usual ones per property.
5. **Check the ledger.** `node tools/bin/attempt-ledger.mjs plan "<approach>"`
   refuses an approach that already failed in this project or in the stack's
   known failures (`../roblox-attempt-memory/SKILL.md`).

## Holding a value against the game

| The game writes it | Hold it with |
|---|---|
| once, at spawn | apply on `CharacterAdded`, after `WaitForChild` |
| now and then (sprint, stun, round start) | `GetPropertyChangedSignal`, writing back only when different |
| every physics step (the Humanoid resetting `CanCollide`) | `RunService.PreSimulation`, before the step |
| every frame from its own loop | `getconnections` on the loop's signal and `Disable`, when the dump shows the loop |
| from the server (replicated property) | nothing on the client holds it; the next replication wins |

Writing every frame "just in case" costs a write per frame forever and still
loses between the game's write and yours (K9 in the known failures).

## Build from the closest tested asset

Paste the closest asset and change what differs; keep its skeleton: one
`getgenv().Features` namespace, unload the previous session before reading
any original, every connection stored, respawn re-applied after the wait with
the session and character re-checked, `processed` respected, a `set(on)` for
hub buttons, and an idempotent `unload` that restores only what it changed.
`../roblox-executor-features/references/feature-quality.md` is that skeleton
as a checklist.

## The regression matrix

Every feature passes every row that applies, in the mocks where they can
model it and in the game where they cannot. `references/regression-matrix.md`
has the test code for each row.

| Row | Pass means |
|---|---|
| runs | the effect appears on the first run |
| toggle twice | off restores the game's value; on again works |
| game writes | the game's write is answered (or honestly not, and said) |
| respawn on, respawn off | on stays on for the new body; off stays off |
| rerun | one session, one set of connections, originals not overwritten |
| unload twice | everything restored, namespace cleared, no error |
| chat typing | the key typed in chat does nothing |
| phone | reachable without a keyboard: thumbstick, tap, or a hub button |
| other features on | no feature undoes another (`references/composition.md`) |
| seat, death, streaming | behaves as stated: refuses, waits, or says what it cannot see |

A feature change re-runs the whole matrix, not only the new row: that is
what "no regressions" means in practice.

## When the user says it does not work

Do not re-send the code differently. Follow `references/diagnosis.md`:
confirm it ran, then send `../roblox-executor-features/assets/feature-doctor.luau`.
It reports the executor, every loaded feature and its state, conflicting
pairs, a seated or anchored body, and which properties something rewrote in
five seconds. That output names the layer to change. Record the failed
attempt in the ledger before the next one.

## Reply

Paste the final script whole. Say what the server can see and correct, which
rows of the matrix ran in the mocks, and which only the player can check in
game. Run `node tools/bin/check-file.mjs <file>` and report it.

| Need | File |
|---|---|
| why features break, by symptom, with the fix | `references/failure-modes.md` |
| the matrix rows as test code | `references/regression-matrix.md` |
| several features at once: who owns which property | `references/composition.md` |
| "it doesn't work": the order of questions and the doctor | `references/diagnosis.md` |
| the tested assets and their quality bar | `../roblox-executor-features/SKILL.md` |
| finding a game-specific value in a dump | `../roblox-executor/references/technique/feature-search.md` |

## Works with

- `roblox-executor-features`: the closest tested asset to start from.
- `roblox-executor`: the layer-to-call map for game-owned values.
- `roblox-attempt-memory`: each failed attempt recorded before the next.
- `roblox-debugging`: the error catalogue and one-probe-per-hypothesis method.
- `roblox-executor-scripting`: evidence and layer choice before a feature is built.
