---
name: roblox-attempt-memory
description: Never repeating a failed fix - the attempt ledger in PROJECT_CONTEXT.md with plan, check and search. Use for you didn't fix it, same problem again, any retry, a new chat on old work.
---

# Attempt memory

A model that forgets its last attempt makes it again. The user sees the same
failure twice and concludes nothing listens. This skill makes the last attempt
impossible to forget: every attempt is written down in a fixed shape, and two
commands read it back before the next one.

The ledger is the **Attempts** section of `PROJECT_CONTEXT.md` in the project
root, beside the rest of the carried context in
`../roblox-luau-expert/references/task-contract.md`. One file, so a GPT user
uploads one thing and Claude, Codex and Cursor read the same record.

```bash
node tools/bin/attempt-ledger.mjs plan "hold WalkSpeed with a Heartbeat loop"   # repeats a failed attempt?
node tools/bin/attempt-ledger.mjs check Speed.client.luau                        # a recorded mistake back in the code?
node tools/bin/attempt-ledger.mjs search walkspeed resets                         # what do we know about this symptom?
node tools/bin/attempt-ledger.mjs lint                                            # malformed or repeated entries
python tools/py/attempt_ledger.py plan "..."                                      # the same, without Node
```

`check` also reads the stack's own ledger, `references/known-failures.md`:
approaches that look right, keep being generated, and fail. `check-file.mjs`
runs it on every file.

---

## The loop, every attempt

1. **Read before acting.** Open `PROJECT_CONTEXT.md` if it exists (or ask the
   GPT user to upload it) and `search` the symptom's words. A matching
   `failed` entry is the most important fact in the conversation.
2. **Name the approach in one line, then `plan` it.** "Set WalkSpeed every
   Heartbeat" and "write WalkSpeed in a RenderStepped loop" are the same
   approach; the words differ, the tokens do not. Exit 1 means it failed
   before. Change the approach, or say exactly what is different this time
   and why that difference addresses what was seen.
3. **Build, then run `check` on the file.** A hit is a recorded mistake coming
   back, usually through a helper copied from an older draft.
4. **Record the outcome as soon as the user reports it**, in the entry format
   below. "Still broken" is a result: the previous attempt becomes `failed`
   with what the user saw, before anything else is written.
5. **Turn every fix into something that fails loudly if it comes back**: a
   test assertion, an `Avoid` pattern, or a named check. Prose alone decays;
   the next model reads past it.

## An entry

```markdown
### A4 failed: speed resets after a few seconds
- Tried: set Humanoid.WalkSpeed once when the toggle turns on
- Saw: speed returns to 16 after about 3 s, and on every respawn
- Cause: the game's sprint script writes WalkSpeed; respawn makes a new Humanoid
- Instead: write back on GetPropertyChangedSignal, rebind on CharacterAdded (assets/speed.luau)
- Avoid: `WalkSpeed\s*=\s*\d+\s*$`
- Unless: `GetPropertyChangedSignal`
- Check: library/tests/recipes/speed.luau "a game stun or sprint script is overridden"
- Date: 2026-09-25
```

| Status | Means | Required |
|---|---|---|
| `failed` | the approach did not work | Tried, Saw |
| `rejected` | it worked, and the user did not want it (a design, a behaviour) | Tried, Saw |
| `fixed` | a bug that was found and removed; it must not return | Avoid or Check |
| `works` | a confirmed approach to keep using | Tried |
| `open` | unresolved; the next attempt starts here | Saw |

`Saw` is what was observed: the user's words, an error line, a measured value.
`Cause` is written only when evidence supports it, otherwise `unknown`. A
guessed cause recorded as fact sends every later attempt down the same wrong
layer. Field meanings, pattern rules and more examples:
`references/ledger-format.md`.

---

## Same complaint twice

The second "it still does not work" means the fix addressed a different layer
than the bug. Do not re-send the same code differently. Check, in order:

1. **Is the new code the code that ran?** An old script still executing, a
   stale copy in Studio, the edit made to a different file. Ask what the
   Output or console printed on the latest run, and compare it with this
   version's behaviour.
2. **Is it the same symptom?** A different error after a fix is progress;
   record the first as `fixed` and open a new entry.
3. **Which layer did the last attempt change, and which layer owns the
   symptom?** Client versus server, the value versus the thing that resets it,
   the element versus its clipping parent, the handler versus whatever sits on
   top of the button. `../roblox-executor-reliability/SKILL.md` and
   `../roblox-ui-interaction/SKILL.md` list the layers for their areas.
4. **What evidence would tell two causes apart?** Ask for exactly that one
   thing: a print, a screenshot, the doctor's output.

## Context that crosses a conversation

Never claim to remember a conversation you cannot see. A new chat, a
compacted one, or another host starts from the record, not from memory.
`references/recovering-context.md` covers what to rebuild and where each host
keeps it: `PROJECT_CONTEXT.md` everywhere, plus Claude Code's memory for the
user's lasting preferences, and a downloadable copy from a GPT at the end of
each attempt.

## Keeping the ledger useful

- One entry per approach. `lint` reports two failed entries whose Tried lines
  describe the same thing: merge them, and treat that as a warning sign.
- Supersede, never erase: a `works` entry that later fails becomes `failed`
  with the new Saw. History is what stops the loop.
- Patterns are narrow. An `Avoid` that matches correct code trains everyone to
  ignore `check`. Add an `Unless` for the fix's signature.
- Project facts stay in the project. Do not turn one game's quirk into a
  global preference.

| Need | File |
|---|---|
| every field, status and pattern rule, with examples | `references/ledger-format.md` |
| a new chat, a compacted one, or another host picking up the work | `references/recovering-context.md` |
| the stack's own recorded failures, checked on every file | `references/known-failures.md` |

## Works with

- `roblox-studio-mcp`: a Studio playtest is evidence for the Saw line.
- `roblox-executor-reliability`: the feature doctor's output names the layer to record.
- `roblox-ui-interaction`: its ladder lists the layers a UI fix can miss.
- `roblox-code-craft`: the diff is the changelog; the ledger holds the story.
- `roblox-debugging`: the probe that turns a Saw line into a Cause.
