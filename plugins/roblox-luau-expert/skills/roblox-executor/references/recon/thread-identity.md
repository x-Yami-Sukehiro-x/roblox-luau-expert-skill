# Thread identity and capabilities

Supersedes the "identity 0-8, higher is more privileged" model still repeated in
older documentation, including `../api/legacy-syn.md`. That model is wrong in two
ways: identities are **named**, not a privilege ladder, and access is decided by
**capabilities** rather than by the identity number alone.

Primary source: [`Pseudoreality/Roblox-Identities`](https://github.com/Pseudoreality/Roblox-Identities).

---

## The model

Every Luau thread carries an **identity**. Each identity is granted a set of
**capabilities**. An API is reachable if the calling thread's identity holds the
capability that API requires.

This is why `Workspace.AuthorityMode` is readable from an executor but not from
a `LocalScript`: the property requires the `RobloxScript` capability, a
`LocalScript` runs at `GameScript` which does not hold it, and an executor can
run at an identity that does.

### Identities

| Identity | What runs at it |
|---|---|
| `LocalGui` | client-side GUI contexts |
| `GameScript` | **an ordinary `Script` / `LocalScript`** |
| `ElevatedGameScript` | trusted core scripts |
| `CommandBar` | the Studio command bar |
| `StudioPlugin` | plugins |
| `ElevatedStudioPlugin` | elevated plugins |
| `COM` | component-object interop |
| `WebService` | web-service contexts |
| `Replicator` | network replication |
| `Assistant` | the Studio AI assistant |
| `OpenCloudSession` | Open Cloud API sessions |
| `TestingGameScript` | test contexts |
| `UndoStack` | undo/redo operations |

### Capabilities

`Plugin`, `LocalUser`, `WritePlayer`, `RobloxScript`, `RobloxEngine`,
`NotAccessible`, `RemoteCommand`, `InternalTest`, `PluginOrOpenCloud`,
`Assistant`.

Selected rows from the capability matrix, chosen because they explain the cases
that actually come up:

| Capability | LocalGui | GameScript | ElevatedGameScript | CommandBar | StudioPlugin | ElevatedStudioPlugin | COM | WebService | Replicator |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `Plugin` | yes | **no** | yes | yes | yes | yes | yes | yes | no |
| `LocalUser` | yes | **no** | yes | yes | no | yes | yes | yes | no |
| `RobloxScript` | no | **no** | yes | no | no | yes | yes | yes | yes |
| `RobloxEngine` | no | no | no | no | no | no | yes | yes | no |
| `WritePlayer` | no | no | no | no | no | no | yes | yes | yes |
| `NotAccessible` | no | no | no | no | no | no | yes | yes | no |

Two things fall out of this table immediately:

- **`GameScript` — what your game code runs at — holds almost nothing.** That is
  the point.
- **The ordering is not a ladder.** `CommandBar` has `Plugin` and `LocalUser`
  but not `RobloxScript`. `ElevatedGameScript` has `RobloxScript` but not
  `Plugin`... and so on. "Set it higher" is not a coherent instruction.

---

## Reading and setting it

```lua
local identity = getthreadidentity()      -- also aliased getidentity / get_thread_identity
setthreadidentity(n)
```

**Do not hardcode the number.** The numeric values are build- and
executor-dependent, and the old published tables predate several of the
identities above. Read the current value, change it, and change it back:

```lua
local function withIdentity<T>(target: number, fn: () -> T): T
    if typeof(getthreadidentity) ~= "function" or typeof(setthreadidentity) ~= "function" then
        return fn()
    end
    local previous = getthreadidentity()
    setthreadidentity(target)
    local ok, result = pcall(fn)
    setthreadidentity(previous)
    if not ok then error(result, 2) end
    return result
end
```

**Restore the previous identity.** Leaving a thread elevated is both a
correctness problem (game code you call behaves differently) and a detection
signal — a `GameScript`-context callback that reports an unexpected identity is
trivially checkable.

Some builds need a `task.wait()` after the change for it to take full effect.
Feature-detect rather than assuming.

---

## Where identity actually matters

**Reading gated properties.** `{RobloxScript}`-tagged members need an identity
holding `RobloxScript`. The generated table
`roblox-luau-expert/references/verified/security-tagged-apis.md` lists every
one, split by whether the gate applies to reads, writes, or both.

**`[NotScriptable]` is a different thing.** Those members are not
security-gated — they are simply not exposed to Luau. Identity does not help;
`gethiddenproperty` or `setscriptable` does. `Workspace.SignalBehavior`,
`NextGenerationReplication` and `UseFixedSimulation` are all in this category,
whereas `AuthorityMode` is genuinely security-gated. Do not treat the two the
same.

**Calling into game code.** If you elevate, call a game function, and that
function checks the identity, you have handed it a signal. Restore first.

**Instance creation and service access.** Some services refuse to resolve at
`GameScript`.

---

## Detection surface

Identity manipulation is observable.

- A script can read its own identity and compare it against what it should be.
- A hooked function called from an unexpected identity is a strong signal.
- `setscriptable` makes a normally-hidden property readable, and a game can test
  whether a property is unexpectedly accessible. `gethiddenproperty` does not
  have this problem and is the better choice where both are available.

Prefer the lowest identity that does the job, hold it for the shortest window,
and restore it. See `detection-surface.md`.

---

## Practical guidance

1. Feature-detect `getthreadidentity` / `setthreadidentity` before using either.
2. Never hardcode a numeric identity — read, modify, restore.
3. Elevate for the smallest possible scope.
4. Check the required **capability** for the API you want, not the identity
   number. `verify-api.mjs <Name>` prints the gate and its direction.
5. If a call fails at `GameScript`, the question is which capability it needs,
   not "what number is higher".
