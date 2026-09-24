# Diagnostics — errors, warnings, prints, comments

Everything the code says to a human. When something breaks, these messages are the only evidence you have. A vague one costs an hour; a specific one costs a minute.

---

## Prefer returning failure over throwing

The official Roblox style guide is stricter here than most people expect:

> "When writing functions that can fail, return `success, result`, use a `Result` type, or use an async primitive that encodes failure, like `Promise`."
>
> "Do not throw errors except when validating correct usage of a function."

Two reasons given, both worth internalising:

1. **Lua can only throw strings**, which makes distinguishing one error kind from another very difficult.
2. **Exceptions are not encoded in a function's contract.** A caller reading the signature has no way to know what might be thrown.

```lua
-- Expected failure: the caller can reasonably handle it
local function fetchProfile(userId: number): (boolean, Profile | string)
    local success, result = pcall(profileStore.GetAsync, profileStore, userId)
    if not success then
        return false, ("unable to load profile for user %d: %s"):format(userId, tostring(result))
    end
    return true, result
end

-- Usage violation: the caller passed something impossible. Throw.
local function setFireRate(rate: number)
    if typeof(rate) ~= "number" or rate <= 0 then
        error(("setFireRate: expected a positive number, got %s (%s)")
            :format(tostring(rate), typeof(rate)), 2)
    end
end
```

The distinction: **a network call failing is a normal outcome; being handed a string where a number was required is a bug in the caller.** Return the first, throw the second.

`assert` is for usage validation. Wrap calls that throw in `pcall`.

---

## `error(message, level)` — the parameter that makes errors useful

The second argument decides *whose line number appears in the message*.

| Level | Position reported |
|---|---|
| `0` | No position information added at all |
| `1` (default) | Where `error` was called — i.e. inside your own function |
| `2` | **Where your function's caller is** |

This matters enormously. When a module validates its arguments and throws at level 1, the message points at your validation line — sending the reader into your module, when the mistake is in *their* code.

```lua
-- Level 1 (default): "InventoryModule:14: expected a positive number"
-- Reader opens InventoryModule line 14. Wrong place.
error("expected a positive number")

-- Level 2: "PlayerScript:88: expected a positive number"
-- Reader opens the line that actually made the mistake.
error("expected a positive number", 2)
```

**Use level 2 for every argument-validation throw in a module function.** Use level 1 when the error is genuinely inside your own logic. Use level 0 when you are composing a message that already contains its own location.

---

## Message anatomy

Structure: **what failed → which value → what to do.**

Conventions drawn from Temporal's guide (built on Uber and Go practice), plus Elm and Rust compiler design:

- **Lowercase start, no trailing period.** These get composed into larger messages; a capital mid-sentence reads wrong.
- **`"unable to X"`** over `"failed to X"`, `"can't X"`, or `"error in X"`.
- **Cite the values the caller supplied, not your internal variable names.** The reader knows what they passed in. They have never seen your locals.
- **Show expected versus received** whenever a comparison failed. This is the single highest-value addition to any message.
- **Make it greppable.** Include a distinctive, stable substring so searching the codebase for the message text lands on the raising site immediately. Interpolated values vary; the fixed prefix should not.
- **Say why, or better, how to fix it.** "unable to equip: slot 3 is occupied" beats "unable to equip".
- **One clear sentence.** Nobody reads a paragraph in a console.

```lua
-- Nothing actionable. Which argument? What was wrong with it? Where?
error("Invalid argument")

-- What failed, which value, expected vs received, and it blames the caller
error(("setFireRate: expected a positive number, got %s (%s)")
    :format(tostring(rate), typeof(rate)), 2)
```

Searching the project for `setFireRate: expected` finds the raising line instantly. Searching for `Invalid argument` finds forty.

---

## `print` / `warn` / `error`

Roblox gives you three channels, not five log levels. Map them deliberately rather than defaulting everything to `print`.

| Channel | Use for | Not for |
|---|---|---|
| `print` | Normal operation worth recording; state transitions; startup confirmation | Per-frame output; leftover debugging |
| `warn` | Recoverable problems; degraded fallback paths; deprecated usage | Things that are actually fatal |
| `error` | Contract violations; unrecoverable state | Expected failure modes — return `success, result` instead |

Rules that carry over from logging practice generally:

- **Log once, at one strategic layer.** The same failure reported at every level of the call stack is noise that buries the one line that mattered.
- **Include the identifying context in the line itself.** There is no structured-logging layer to attach fields to, so the player, place, item id, or slot has to be in the string.
- **Pick the lowest level that is accurate.** Logging routine events as `warn` trains you to ignore warnings.

### Prefix for greppability

A short stable tag per subsystem makes output filterable and searchable:

```lua
warn(("[Inventory] slot %d already occupied by %s; skipping equip")
    :format(slotIndex, occupant.Name))
```

Pick one tag per subsystem and keep it stable across the project. Then `[Inventory]` filters the console and greps the source.

---

## `pcall` discipline

`pcall` is for calls whose failure you cannot prevent. It is not a way to make errors go away.

**Use it for** genuinely unpredictable calls: `DataStoreService`, `MarketplaceService`, `HttpService`, `MessagingService` — anything crossing the network.

**Do not wrap everything.** Blanket `pcall` makes debugging a nightmare and hides the errors you most need to see. If a call cannot realistically fail, calling it inside `pcall` only removes your stack trace.

**Always check the success value.** This is the one that bites:

```lua
-- Silent failure. If GetAsync throws, profile is the error string and
-- nothing says so. The bug surfaces somewhere unrelated, later.
local _, profile = pcall(store.GetAsync, store, key)

-- The failure is visible and handled
local success, profile = pcall(store.GetAsync, store, key)
if not success then
    warn(("[Profiles] unable to load %s: %s"):format(key, tostring(profile)))
    return nil
end
```

A `pcall` whose first return is discarded is a blindfold. It is also one of the most-cited markers of machine-written code — catch-all handling that catches everything and does nothing.

**`xpcall` + `debug.traceback`** gives a full stack for diagnosis. It also exposes your code structure in the message, so keep it to development rather than shipping it.

---

## Words that make a string read as machine-written

Error messages, log lines, and comments are prose, and the same vocabulary tells apply. Adapted from the `avoid-ai-writing` pattern set, scoped to short technical strings.

**Replace on sight:**

| Instead of | Write |
|---|---|
| leverage | use |
| utilize | use |
| robust | reliable |
| seamless | smooth |
| comprehensive | complete |
| delve into | examine |
| in order to | to |
| facilitate | help, let |
| ensure that | make sure |

**Cut hollow intensifiers** — `actually`, `truly`, `genuinely` — when they only add emphasis. "this actually works" says nothing "this works" doesn't.

**Prefer `is` and `has`** over `serves as`, `features`, `provides`. Copula avoidance reads as padding.

**Skip template constructions** — "whether you're X or Y", "a [adjective] step towards [noun]". They manufacture breadth that isn't there.

Rules that **do not** apply to technical strings, so don't over-correct: hedging (`may`, `could` are correct in specs), bullet lists of noun phrases (standard in parameter docs), and terse repetition (repeating the correct term beats cycling synonyms).

---

## Comments — why, not what

Ousterhout's correction is the anchor: "good code is self-documenting" is only partly true, because an interface carries details the code cannot express. Comments are not banned. Their job is narrow.

**Comment the why.** Non-obvious decisions, constraints, workarounds, the reason a magic value is that value.

```lua
-- Roblox clamps WalkSpeed changes made in the same frame as a respawn,
-- so this is deferred by one heartbeat rather than set directly.
task.defer(applyMovementProfile, character)
```

**Never restate the line below.** `-- increment the counter` above `counter += 1` is the single most-cited signal of generated code, and it adds nothing for a reader who can already read Luau.

**Uniformity is a bigger giveaway than density.** Identically-formatted comments above every function across every file, with grammar and capitalisation held perfectly consistent, is a pattern no human sustains. A comment where the reasoning is non-obvious and none where it isn't reads as human because it *is* how humans work.

**Roblox specifics:**
- A short block comment above a public function's contract earns its place, especially for anything crossing the client/server boundary.
- In-body narration does not.
- Document what an argument means when the type doesn't say it — `slotIndex: number` is clear; `mode: number` needs a comment or an enum.

**Kill `TODO` before delivery**, or turn it into a tracked item. `-- TODO: add real validation here` sitting in shipped code is both a tell and a genuine hazard.

---

## Quick checks

Before handing over code:

- Every `pcall` first return is checked.
- Every argument-validation `error` uses level `2`.
- Every message names the failing value and shows expected vs received where relevant.
- Every message has a stable, greppable prefix.
- No comment restates the line under it.
- No `TODO`s.

---

## Related references
- `naming.md` — identifiers, including names used inside messages
- `code-signature.md` — matching an existing file's error and log conventions
- `roblox-architecture/SKILL.md` — re-validation after yields, remote validation
- `roblox-executor/references/api/misc.md` — `rconsole*` output functions in executor contexts
