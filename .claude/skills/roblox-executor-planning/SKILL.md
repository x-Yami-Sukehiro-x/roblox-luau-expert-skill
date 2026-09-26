---
name: roblox-executor-planning
description: Thinking before coding an executor feature - effect, evidence, mechanism, writers, pre-mortem, check. Use before building, not winging it.
---

# Plan the mechanism before the script

Use for a new game-specific executor feature, a hub combining several features,
or a request such as "make it OP" whose actual effect is unresolved. For a small
engine feature with an established asset, use the asset and its checks directly;
do not turn planning into a questionnaire or a second deliverable.

Read the supplied source and the project's attempt ledger first. Keep a short
decision record in the task notes: intended effect, supporting locations,
ownership, chosen access path, unresolved fact, and acceptance check. Record
decisions and evidence, not a transcript of internal deliberation.

## Define success where the user will see it

Translate adjectives into observable behavior. "Premium" might mean a toggle
that restores correctly, a useful explanation when unavailable, and settings
that survive a rerun. "OP" is a request for a strong useful effect, not evidence
that currency, damage or cooldown authority can be changed from a client.

Name which outcome is being promised:

| Outcome | What would establish it |
|---|---|
| Local display or camera change | The actual reader uses the changed local value |
| Local movement or physics change | The client controls the relevant simulation and the game permits the observed effect |
| Repeating an existing player action | Its receiver, arguments, prerequisites, pacing and completion signal are established |
| Server result such as an item grant | Relevant server code or an observed authoritative acknowledgement; a sent request is insufficient |
| Unknown | Name the missing fact; keep dependent code out of the build |

Character physics ownership can change, and server corrections can limit local
movement. A client-visible number is not automatically client-authoritative.
Missing source does not establish server ownership either.

## Choose one mechanism that reaches the reader

1. Trace the desired effect back from its reader. A settings table is useful
   only if the active reader still reads it; startup copies and cloned tables
   can make an otherwise correct edit inert.
2. Find the narrowest established control: an existing setter or command, a
   local table field, an ordinary Instance member, or a uniquely identified
   closure slot. Choose the layer the evidence shows. Do not try unrelated
   layers until something changes.
3. List the writers that can undo the effect and when they run. Record whose
   value should win on disable. A game update, respawn and another feature are
   different ownership events and may need different behavior.
4. Check coexistence before implementation. Two toggles may share one movement
   owner; a free camera and spectate cannot independently own the same camera.
   A disabled connection may also update UI or clear stale state.
5. Define the cheapest discriminating check. It must distinguish the intended
   effect from a label changing, a request being sent, or the wrong object
   being patched.

For source-to-runtime identity and callable contracts, use
`../roblox-decompiled-features/SKILL.md`. For a missing discriminating fact, use
`../roblox-runtime-probes/SKILL.md`. For comparing candidate approaches, read
[decision-examples.md](references/decision-examples.md).

## The plan, written before code

Five lines, kept in the task notes and checked against the draft before it
is delivered:

```
Effect:    Auto collect coins within 60 studs (the player's words)
Evidence:  CoinClient:41 fires Remotes.Collect(coin.Name) after a 0.5 s check
Mechanism: repeat the call site's request with action-loop, interval 0.5
Writers:   none for this value; respawn stops the loop until CharacterAdded
Check:     Coins leaderstat rises by the coin's value per collect; unload stops it
```

A line that cannot be filled is the next thing to find, not a guess to make:
an empty Evidence line is a probe (`roblox-runtime-probes`), an empty Check
line means nobody will know whether it works.

## Pre-mortem: how this fails

Before writing, list how the chosen mechanism fails in the player's game,
then make sure the plan answers each. The ones that recur:

| It fails because | The plan answers with |
|---|---|
| The server refuses it (rate, distance, state) | Pacing from the source; moving in range first; the game's preconditions |
| Something writes the value back | The writers list, and the mechanism that holds against them |
| Respawn replaces what it holds | Re-resolve on `CharacterAdded` |
| A rerun stacks a second copy | Unload the previous session first |
| The game updates | Targets resolved at start, reported by name when missing |
| Two features own one property | The feature registry refuses the second |
| The executor lacks a function | Named in one line before anything changes |
| The main chunk passes 200 locals | The register-safe shape from the start |

If an answer is "it probably won't", the risk goes in the reply as an
assumption the user can reject.

## Build, investigate or explain the boundary

- **Build** the parts whose prerequisites are established. Do not block an
  independent camera feature because a requested inventory feature needs evidence.
- **Investigate** a specific unknown with a bounded observation. State what each
  possible result would change. A probe with no decision attached is busywork.
- **Explain the boundary** when evidence establishes that the required effect is
  outside client authority. Offer an achievable effect only when it serves the
  same user goal; do not relabel a visual counter as real currency.

Skip optional complexity that does not improve the requested effect. A
notification, persistent config, global hook, polling loop or abstraction each
needs an actual consumer or failure condition. `roblox-script-feedback` owns
notifications and config decisions; `roblox-code-craft` owns names and comments.

## Keep the plan true during implementation

Check compile and register pressure as sections grow, before adding the full UI
(`roblox-register-budget`). Avoid turning every setting, control and callback
into a live top-level local. Capture originals before mutation and give the
session one teardown path. Use `roblox-executor-reliability` for the runtime matrix.

When a check fails, update the decision record and ledger from the observed
result. Change the approach only when new evidence changes the mechanism; do
not wrap the same guess in extra guards. At delivery, separate static checks,
mocked behavior and actual executor testing. No claim that "any executor" or
"every AI" is now guaranteed correct follows from one successful test.

## Works with

- `roblox-executor-scripting`: build and delivery order after a mechanism is chosen.
- `roblox-decompiled-features`: source evidence and runtime target identity.
- `roblox-runtime-probes`: the smallest observation that resolves an unknown.
- `roblox-executor-reliability`: writers, cleanup and feature coexistence.
- `roblox-register-budget`: compiler limits while the implementation grows.
- `roblox-script-feedback`: when feedback and persistent config earn their place.
- `roblox-attempt-memory`: prior failures and the check each fix must retain.
- `roblox-code-craft`: direct names, short errors and comments with useful facts.
- `roblox-ai-mistakes`: the defects a plan exists to prevent, each with its check.
- `roblox-executor-quality`: the bar the finished script is measured against.
