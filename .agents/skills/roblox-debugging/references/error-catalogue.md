# Error catalogue

The message as Roblox prints it, what usually causes it, and the first thing
to check. Placeholders in angle brackets.

## Nil and missing things

| Message | Usual cause | First check |
|---|---|---|
| `attempt to index nil with '<Name>'` | The thing before the dot is nil: a character not loaded, a `FindFirstChild` that found nothing, a player who left | Print the thing before the dot; wait for `CharacterAdded` or the right event |
| `<Name> is not a valid member of <Class> "<Path>"` | The parent exists, the child does not: a typo, wrong capitalisation, not replicated yet, or server-only | Capitalisation; whether the client can see it; `WaitForChild` if it arrives later |
| `Infinite yield possible on '<Path>:WaitForChild("<Name>")'` | The name never appears: wrong name, wrong parent, or it lives somewhere the client cannot see (`ServerStorage`) | The exact path in the Explorer during play, on the same side |
| `attempt to call a nil value` | A dot where a colon belongs, a misspelled method, a function defined below its first use, or (executor) a function the executor lacks | Read the call; check spelling and `:` versus `.` |
| `attempt to call a nil value (global '<name>')` | A global that does not exist here: an executor function outside an executor, or a typo | `verify-executor-api.mjs <name>`; whether the script runs in an executor |

## Types and values

| Message | Usual cause | First check |
|---|---|---|
| `attempt to perform arithmetic (add) on nil and number` | A value not loaded yet (a DataStore field, an attribute not set) | Where the value is set, and whether it can be nil at this point |
| `attempt to compare number <= nil` | Same, in a comparison | Same |
| `Unable to assign property <Prop>. <Type> expected, got <Type>` | A wrong type: a number for a UDim2, a string for a Color3 | The constructor (`UDim2.fromOffset`, `Color3.fromRGB`) |
| `invalid argument #1 to '<function>' (number expected, got string)` | A string from a TextBox or attribute passed as a number | `tonumber` and a nil check |
| `Script timeout: exhausted allowed execution time` | A loop that never yields | Find the `while` without a `task.wait` or a yielding call |
| `stack overflow` | A function calling itself without end, often a property-changed handler that sets the property it watches | The handler: does it write what it listens to? |

## Engine limits and access

| Message | Usual cause | First check |
|---|---|---|
| `The current thread cannot access '<Member>' (lacking capability <Name>)` | A member restricted to plugins or core scripts | `verify-api.mjs <Class.Member>` shows the gate |
| `<Member> is not a valid member` on a real API | Deprecated or removed, or the wrong class | `verify-api.mjs` |
| `Out of local registers when trying to allocate <n> registers` | Over 200 locals in one function, usually one giant script | Group values into tables; split into modules (`roblox-luau-language`) |
| `Requested module experienced an error while loading` | The required module itself errored | The module's own error, printed just above |
| `DataStore request was added to queue` | Requests over the budget | Batch saves; `UpdateAsync` on a timer, not per change |
| `HTTP 429 (Too Many Requests)` | An HTTP or Open Cloud rate limit | Back off; cache |
| `Http requests are not enabled` | Game Settings, Security, Allow HTTP Requests is off | The setting, in the published place |
| `Remote event invocation queue exhausted` | A remote fired before anything connected to it, many times | Connect handlers before firing; do not fire at startup in a loop |

## Executor-specific

| Symptom | Usual cause | First check |
|---|---|---|
| An error naming a game script, after your hook ran | Your hook changed what the game's function returns or receives | Return exactly what the original returns; pass `...` through |
| `cannot hook` or a crash on `hookfunction` | Hooking a C closure the executor cannot, or re-hooking without restoring | Check `islclosure`; restore on unload before rehooking |
| A feature works, then stops after death | It changed the old character; respawn built a new one | Re-apply on `CharacterAdded` |
| A feature works, then snaps back each frame | A game loop rewrites the value | List the writers; see `roblox-executor-reliability` |
| Two copies of every action | The script ran twice without unloading the first | A `getgenv()` session that unloads the previous run |
| Changes visible only to you | Client writes do not replicate | Expected; say so. The server owns that value |
