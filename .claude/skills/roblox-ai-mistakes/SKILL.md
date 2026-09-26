---
name: roblox-ai-mistakes
description: Mistakes AI makes in Roblox and executor code - invented APIs, wrong side, register overflow, dead toggles - each with its check. Use before delivery.
---

# The mistakes AI makes, and the check for each

Models make the same Roblox mistakes in the same places. A draft that reads
well can still call a member that does not exist, write a value the server
never sees, and overflow the local limit on its last line. Reading the whole
draft again rarely finds these; checking the known places does.

## Where the mistakes come from

| Cause | What it produces | The counter |
|---|---|---|
| **Recall instead of lookup** | Invented members, executor functions under the wrong name, deprecated APIs from old tutorials | Look it up: `verify-api.mjs`, `verify-executor-api.mjs`. Exit 1 means it does not exist |
| **Patterns from elsewhere** | `wait()`, `BodyVelocity`, `_G.Enabled` loops, `MouseButton1Click`, web-Lua habits | The linters and `known-failures.md` know these by shape |
| **Local reasoning, global effect** | Each line is fine; the file is not: 201 locals, two features owning `WalkSpeed`, a local that fell out of scope in a refactor | Whole-file tools: `check-registers`, the feature registry, `check-file` |
| **Claiming instead of checking** | "Tested and working", "fixed", "undetected" with nothing run | Run the check, quote the output, name what was not run |

## The ten that cost the most

| # | Mistake | How it shows | Caught by |
|---|---|---|---|
| 1 | An API that does not exist, or not at this security level | `X is not a valid member of Y`, or silence | `node tools/bin/verify-api.mjs <Name>` |
| 2 | A client write expected to reach the server or other players | "It resets", "others can't see it" | Ask which side owns the value, before code |
| 3 | 200 locals in the main chunk | `Out of local registers`; in an executor, `attempt to call a nil value` | `check-registers` (`E-COMPILE`, `I-LOCALS`) |
| 4 | A local moved into a block by that fix, used outside it | Nil at runtime, no error until that line runs | `check-registers` `W-SCOPE` |
| 5 | A connection with no teardown | Doubled effects after respawn or rerun | `lint-roblox-ui` `E-LEAK`; one session table |
| 6 | A rerun that stacks on the previous session | Two windows, a speed that "restores" to the patched value | Unload whatever is under the `getgenv()` key first |
| 7 | A found constant restored by retyping it | Right until the game changes the number | Capture the value read; restore the variable |
| 8 | A fallback chain across value layers | Works in one game, silently edits the wrong thing in the next | `lint-luau-slop` `E-LAYERCHAIN` |
| 9 | A toggle that lights up when its feature failed | The player sees on, nothing happens | The feature registry's status (`roblox-executor-quality`) |
| 10 | A claim with no check behind it | The user finds the failure | Quote `check-file`; say what was not run |

The full catalogue, by area, with the linter code or test for each, is
[mistake-catalogue.md](references/mistake-catalogue.md).

## Before writing

1. **Answer the question asked.** "Make my fly work on mobile" is not a
   request for a new fly. Re-read the request after the plan
   (`roblox-executor-planning`).
2. **Read the ledger** (`roblox-attempt-memory`): the approach that failed
   last time is in it, and `attempt-ledger plan` compares yours against it.
3. **Look up every name you are not certain of**, before it is written.
   A name you had to guess is a name you look up.
4. **Decide the shape of a long script** before its first line: families in
   tables, a builder per tab (`roblox-register-budget`).

## Before delivering

Run the whole-file check and read every finding, not the verdict:

```bash
node tools/bin/check-file.mjs <file.luau>     # slop, format, UI, API, compile, registers, fit, ledger
python tools/py/check_file.py <file.luau>     # the same without Node
```

Then the five questions no tool asks:

- Does it do what was asked, in the user's game, from their source?
- Which side owns every value it changes, and did I say so?
- What happens on respawn, rerun and unload?
- What did I assume that the source did not show? Is it in the reply?
- Which checks ran, which did not, and does the reply say both?

## When a new mistake is found

A mistake found once should be caught automatically after that:

1. Record it in the project ledger with what was tried, what was seen and
   what works instead (`roblox-attempt-memory`).
2. If it will recur across projects, add it to
   `roblox-attempt-memory/references/known-failures.md` with an `Avoid`
   pattern when a regular expression can find it without flagging correct
   code; `check-file` then reads it for every file.
3. If it is a shape a linter can count, it becomes a rule and a test; if it
   is behaviour, a recipe test in `library/tests/recipes/`.

## Works with

- `roblox-attempt-memory`: the ledger and known failures behind every check here.
- `roblox-executor-planning`: the plan that prevents answering the wrong question.
- `roblox-register-budget`: mistakes 3 and 4.
- `roblox-code-craft`: the ceremony and naming mistakes.
- `roblox-debugging`: when the mistake is already a bug in the user's hands.
- `roblox-executor-quality`: mistake 9 and the premium bar.
- `roblox-reply-craft`: claims, receipts and what the reply says was not run.
