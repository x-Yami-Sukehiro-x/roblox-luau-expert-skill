# False positives: what not to flag

A review loses the user's trust fastest by reporting something that is not
wrong. These shapes look like defects and usually are not. Adapted from the
severity taxonomy and guardrails in `andrian-syh/roblox-best-practices-skill`
(MIT), rewritten for this stack.

## Near-miss pairs

Severity follows the context, not the pattern.

| Shape | Not a finding when | A finding when |
|---|---|---|
| Attribute holding player state | Public display state (a nameplate, a round timer) | Private state an exploiter can use (balance, cooldowns, a damage multiplier): Blocker |
| `SetAsync` | One code path writes a per-player key | Several servers write the same key: Blocker |
| Connection made per spawn | Cleared in `CharacterRemoving` or on an instance destroyed with the character | The owner outlives the object and nothing disconnects it: Blocker if unbounded |
| Deprecated API | Untouched code far from the change: mention at most | On the path this change modifies: Correctness, with the replacement |
| No validation | A server-side BindableEvent or module call | A RemoteEvent, RemoteFunction or teleport data: Blocker |
| `while task.wait(n)` | A scheduled cadence (autosave, AI ticks) | Polling a condition a signal already reports: Correctness |
| `pcall` around a call | A boundary: DataStore, HTTP, `require`, another script's code | Deterministic code, or a result never checked: Advisory |
| A remote handler that returns silently on bad input | Always fine; silence is often deliberate | Never a finding on its own |

## Things that are not leaks

- Connections on an instance that is later destroyed: `Destroy` disconnects
  them.
- `Once` listeners, which disconnect after firing.
- Connections on the character's own parts: they die with the character.
- Anything in a Trove, Janitor or Maid with a teardown path.

## Things that are not slow

A `GetChildren` scan, a table built, or a deep lookup in `PlayerAdded`, a
purchase handler, round setup or module load. They run once per event.
"Hot" means per frame or per tight-loop iteration, and the allocation can
actually be hoisted.

## Things that are not wrong

- An API newer than your memory. Check the dump before calling it invented.
- A project's own structure (Rojo, Knit, a custom framework) that differs
  from this stack's defaults.
- Tutorial-shaped code that works and that the user did not ask to change.
- Missing type annotations in a project that does not use `--!strict`.

## The four-step gate

Every finding passes all four or is not reported:

1. Both sides of paired logic traced (a writer and its reader, a check and
   its use), and they disagree.
2. The shape is not intentional: call sites and comments checked.
3. A concrete failure: these inputs, this state, this wrong result.
4. The API verified against the dump or the live docs.
