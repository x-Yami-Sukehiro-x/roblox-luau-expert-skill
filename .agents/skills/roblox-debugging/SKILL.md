---
name: roblox-debugging
description: Finding the real cause of a Roblox or executor bug - exact error, reproduce, which side runs it, one probe per hypothesis, error catalogue. Use for errors, it does nothing, works in Studio only.
---

# Debugging Roblox and executor code

A bug report is "it doesn't work". A fix needs one sentence: *this line
does this, when it should do that, because of this*. Everything below gets
from the first to the second without guessing, and without sending the same
code again in a different shape.

## The loop

1. **Get the exact text.** The whole error line from the Output window (or
   the Developer Console, F9, in a live game), with the script path and line
   number. "It errors" is not a message. If there is no error, that is a
   finding too: go to step 3.
2. **Reproduce it.** The shortest sequence of actions that shows it every
   time. A bug that only happens "sometimes" has a condition not found yet:
   respawn, a second player, a slow load, a phone.
3. **Find where the code runs.** Is the script running at all (a `print` on
   line 1)? Which side (`RunService:IsServer()`)? Is it in a container that
   runs its class (a LocalScript in `Workspace` never runs; a Script in
   `ReplicatedStorage` never runs)? Most "does nothing" reports end here.
4. **Look the error up** in [error-catalogue.md](references/error-catalogue.md).
   Each entry gives the usual cause and the first thing to check.
5. **Rank hypotheses, test one at a time.** Write down two or three
   explanations, most likely first, then a probe that tells them apart: a
   `print` with the values that matter, an `assert` at the point the
   assumption is made, a breakpoint. One probe, one answer.
   [probes.md](references/probes.md) has the shapes.
6. **Fix the cause, not the symptom.** A `WaitForChild` that hangs is not
   fixed by a timeout that hides it; it is fixed by the right name, the
   right side, or waiting for the right event.
7. **Leave a check behind** and record the attempt (`roblox-attempt-memory`):
   what was tried, what was seen, what caused it. The next person with the
   same symptom starts from the answer.

## When there is no error

"It does nothing" has a short list of causes, in order of frequency. The
full tree is in [silent-failures.md](references/silent-failures.md):

1. The script never runs (wrong container, disabled, wrong script class).
2. It runs on the other side (a server script changing a player's GUI, a
   client script changing what others should see).
3. It runs before the thing exists (character not loaded, streamed out).
4. It ran once, and respawn replaced what it changed.
5. Something rewrites the value after it (the game's own scripts, the
   Humanoid, another feature).
6. For UI: something covers the button, or it is a mouse-only event.
7. For executor scripts: a missing function turned into a silent no-op.

## "Works in Studio, not in the game"

Studio's Play solo runs server and client in one process, so timing and
replication hide. Test with **Start** (a local server and players) in the
Test tab, and check in order: server versus client ownership, StreamingEnabled
(the part is not there yet on the client), load order (the game loads
slower), and API access that differs outside Studio (HTTP requests, DataStores
need the published place's settings).

## Executor scripts

Executor errors look like ordinary Luau errors with different causes:
`attempt to call a nil value` on a global usually means the executor lacks
that function; an error inside a hook shows up in the game's script, not
yours. Before anything else, run the feature doctor
(`roblox-executor-features/assets/feature-doctor.luau`) for a feature that
does nothing, and read its counts. The catalogue has the executor section.

## Tools, by question

| Question | Tool |
|---|---|
| What was the error, where? | Output window; Developer Console (F9) in a live game, server and client tabs |
| What is this value right now? | Breakpoint and Watch in Studio's script debugger |
| Is it slow, and where? | MicroProfiler (Ctrl+F6), Script Profiler |
| Is memory climbing? | Developer Console, Memory tab, by tag |
| Did the remote fire, with what? | A logged `OnServerEvent`, or a remote logger for executor work |
| In a real playtest, driven by the AI | `roblox-studio-mcp`: read the console, capture the screen |

Logs can be read by code too: `LogService.MessageOut` and
`ScriptContext.Error` see every message and error, which is how an in-game
debug panel or an automated test collects them.

## Works with

- `roblox-attempt-memory`: the ledger that stops a failed fix being tried twice.
- `roblox-engine-api`: instance lifecycles behind most nil errors.
- `roblox-networking`: replication and ownership behind "others can't see it".
- `roblox-ui-interaction`: why a button does nothing.
- `roblox-executor-reliability`: the feature doctor and what rewrites a value.
- `roblox-studio-mcp`: reproducing in a real playtest and reading the console.
- `roblox-performance`: when the bug is lag or memory.
- `roblox-reply-craft`: asking the user for exactly one thing at a time.
