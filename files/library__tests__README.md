# Headless tests for `library/src`

`Toast.luau` owns real bookkeeping — a capped visible set, a capped queue, dedup
keys with a count badge, severity preemption, and reflow derived from index
rather than stored position. That logic is worth testing without opening Studio.

```bash
node tools/bin/run-library-tests.mjs
node tools/bin/run-library-tests.mjs --keep   # leave the generated harness on disk
```

Needs `node` and the standalone `luau` binary (`rokit add luau-lang/luau`).

## How it works

Three pieces are concatenated into one Luau file and run:

| File | Role |
|---|---|
| `stubs.luau` | Enough of the engine to run headless: `Instance`, signals, `TweenService`, `task` |
| `library/src/*.luau` | The real modules, wrapped so `require` resolves them |
| `assertions.luau` | The assertions |

The generated `toastharness.luau` is a build artifact. It is gitignored and
deleted after each run unless you pass `--keep`.

## What is asserted

12 assertions across five scenarios:

1. **Capacity and queueing** — pushes past the visible cap go to the queue.
2. **Dedup** — forty pushes on one key collapse to a single entry showing `(x40)`.
3. **Preemption** — an error evicts a low-priority toast when the set is full.
4. **Reflow** — dismissing the *middle* toast moves the one below into the gap.
5. **Teardown** — destroy leaves nothing behind.

Scenario 4 is the one that separates a real notification system from a demo, and
the reason position is derived from index instead of stored.
