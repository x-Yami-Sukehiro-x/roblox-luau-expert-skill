---
name: roblox-runtime-probes
description: Probe scripts for what the dump lacks - a tested remote spy and table finder, bounded, changing nothing. Use when a remote or value is unknown.
---

# Ask the runtime one answerable question

Use when source is missing, stale or ambiguous, or when a feature's observed
behavior contradicts its implementation. Do not send a probe for a known engine
feature whose tested asset already fits. A probe returns evidence for a specific
decision; it is not a partially working feature or a remote fuzzer.

## Choose the missing fact first

Write one sentence: **"This report must tell us whether ___, so we can ___."**
Use the supplied source and prior report to choose a target and observation.
Do not scan the entire client again when a script, table or property is already
known. Read [probe-recipes.md](references/probe-recipes.md) for narrow observation
patterns and a report format.

| Missing fact | Smallest useful observation |
|---|---|
| Is the known Instance present in this phase? | Exact path/class at one recorded phase, plus the searched parent if absent |
| Which candidate belongs to the active reader? | Source-backed discriminators and reference relationships for all candidates |
| Which value changes during a normal action? | Whitelisted before/after snapshots tied to that one action |
| Does something reset a known property? | Initial value and timestamped changes for a short window |
| Is a known call contract incomplete? | Missing caller source first; narrowly scoped observation of a normal call if needed |
| No mechanism or location is known | One capped discovery pass using the feature's words, followed by narrower work |

## A probe has a resource contract

Choose explicit bounds appropriate to the question. Defaults for a small
observation are one run, ten seconds, fifty records, 24 fields per table, strings
clipped to 160 characters and 32 KiB of report text. Adjust only for a stated
need. A snapshot generally needs no ten-second wait.

Bound work as well as output: processed candidates, traversal depth, fields
visited, samples and elapsed time. Hitting a cap must produce **truncated**, the
cap hit and counts; zero recorded matches after truncation does not prove absence.
Do not use `GetDescendants()` over the whole game and call a short output limit
a bounded scan. A native `getgc`, `filtergc` or `decompile` call cannot be
interrupted by a Lua deadline checked only after it returns; report that limit
and avoid an unnecessary full enumeration. Never claim a hard runtime guarantee.

## Observe without changing the feature

- No `FireServer`, `InvokeServer`, signal firing, teleport, property writes to
  game objects, `setupvalue`, `setconstant`, connection disabling, or trial calls
  of discovered functions in an observational probe.
- Do not `require` unknown modules or execute uploaded source to inspect it.
  That runs code and may mutate state. Reading an existing return table is different.
- Read table keys with `next` and fields with `rawget`. Bound traversal and track
  visited tables when recursion is necessary. Do not invoke arbitrary `__iter`,
  `__index` or `__tostring`; summarize unfamiliar values by type.
- Use only fields needed for the question. Do not dump chat, credentials,
  unrelated player data or whole environments. Keep the report local; no upload,
  HTTP request or clipboard change unless specifically requested.
- Feature-detect the selected executor capabilities once. A missing capability
  is a reported limitation, not permission to switch to a different value layer.
- A hook changes a call chain, even if it forwards calls. Treat call observation
  as instrumentation: use it only when needed, identify the exact target, preserve
  receiver/arguments/nil slots/returns, and establish cleanup without removing
  somebody else's hook. Prefer a normal event connection or snapshot when sufficient.

Every temporary connection and task belongs to one named probe session. A second
run stops the old session. Normal completion, timeout, error and manual stop all
release resources; check session validity after every yield. An instrumented
pass-through hook that remains installed must be disclosed as remaining installed.

## Coarse discovery is a separate mode

`../roblox-executor/assets/runtime-probe.luau` is the existing broad discovery
asset. It enumerates client objects and GC values and can decompile matching
scripts. Its output caps do not bound native enumeration cost, and its report
can include unrelated state. Do not describe it as a narrow or fully time-bounded
probe. Prefer a tailored probe from this skill. Use the broad asset only when
coarse discovery is actually needed, make its scope explicit, and avoid optional
decompilation or unrelated state collection when the question does not need it.

## Tested probes

Start from one of these before writing a probe from scratch. Each is covered
by a behaviour test in `library/tests/recipes/`, and each changes one config
line at the top.

| Question | Probe | Config |
|---|---|---|
| What does the game send when I do this? Which remote, method and argument shapes? | [assets/remote-spy.luau](assets/remote-spy.luau): logs the game's own `FireServer` and `InvokeServer` calls for 20 s, 50 records, arguments described by type | `ONLY_NAME` to watch one remote |
| Is this config table unique, and what does it hold now? | [assets/table-finder.luau](assets/table-finder.luau): every table holding all of `KEYS`, with values, field count, frozen and metatable; says when there is not exactly one | `KEYS` from the source |
| Where is anything about this feature? | `../roblox-executor/assets/runtime-probe.luau`: the broad discovery pass | `KEYWORDS` |
| Why does a universal feature (speed, fly, camera) stop working? | `../roblox-executor-features/assets/feature-doctor.luau` | none |

The remote spy is instrumentation, not a snapshot: it installs one
`__namecall` hook that forwards every call unchanged, and it stays installed
as a pass-through after its window, which the reply must say. A rerun reuses
the installed hook instead of stacking a second. It never sends, changes or
blocks a call. The table finder only reads, with `rawget` and `next`, so a
game table's metamethods never run.

## Read the result before writing the fix

Deliver the whole probe with one action to perform, the expected report location
or Output text, what the limits mean, and how to stop it. Local file output is
optional; a short console report avoids requiring filesystem capabilities.

On return, compare the observation against the original question. Distinguish
**observed**, **not observed within these bounds**, **unavailable**, **ambiguous**
and **truncated**. A remote name is not its payload, and a changing slot is not
necessarily the writer. Choose the next step from the result; do not mutate
candidates during the same discovery run. Record the new fact in the attempt
ledger so the next chat does not restart the same search.

## Works with

- `roblox-decompiled-features`: the exact missing source or runtime identity fact.
- `roblox-executor-planning`: which decision a probe must resolve.
- `roblox-executor`: verified capabilities and hook lifetime mechanics.
- `roblox-debugging`: one hypothesis and one discriminating observation.
- `roblox-attempt-memory`: recording the observation and avoiding repeated scans.
- `roblox-code-craft`: bounded diagnostics without generic dumps or noisy comments.
- `roblox-executor-quality`: resolving targets at start, so an update breaks loudly and a probe finds what moved.
