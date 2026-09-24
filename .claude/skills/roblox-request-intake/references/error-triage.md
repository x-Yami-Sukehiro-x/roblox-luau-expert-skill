# Error triage

The user pastes red text. Match it, name the cause, give the fix. No preamble,
no request for more information unless the table genuinely cannot narrow it.

---

## The big five

These five account for most of what beginners paste.

### `attempt to index nil with 'X'`

Something that was expected to exist did not. The name in quotes is the thing
being reached *for*; the nil is whatever came before it.

| Shape | Cause | Fix |
|---|---|---|
| `... with 'Humanoid'` | Character not loaded yet, or already dead | `player.CharacterAdded:Wait()`, then `WaitForChild("Humanoid")` |
| `... with 'Character'` | Script ran before the player spawned | Same — wait for the character |
| `... with 'LocalPlayer'` | A `Script` is reading a client-only value | It must be a `LocalScript` |
| `... with 'Parent'` | The instance was destroyed | Re-check after every yield |
| `... with 'Value'` | `FindFirstChild` returned nothing | Check the exact name and its capitalisation |
| `... with 'PlayerGui'` | Reached too early | `player:WaitForChild("PlayerGui")` |

The general fix is one of three: wait for it, check for it, or it is on the
other side of the client/server boundary. Full treatment in `roblox-engine-api`
reference `nil-safety.md`.

### `Infinite yield possible on 'X:WaitForChild("Y")'`

A warning, not an error — the script is stuck at that line forever. The thing
named never appeared.

Causes, in order of likelihood: the name is spelled or capitalised differently;
it is in a different parent than expected; it exists only on the server so the
client will never see it; it is created later by code that has not run yet.

Fix: correct the name, or give `WaitForChild` a timeout and handle the nil:

```lua
local remote = ReplicatedStorage:WaitForChild("RequestPurchase", 10)
if not remote then
    warn("RequestPurchase never replicated - is it in ReplicatedStorage on the server?")
    return
end
```

### `attempt to call a nil value`

A function name is wrong, or the module returned something without it. Check the
spelling first. If the call is `a.b()` where it should be `a:b()`, that is the
other frequent cause — the colon passes the object as the first argument and the
dot does not.

### `attempt to perform arithmetic (add) on nil`

A number was expected and something empty arrived. Nearly always a table lookup
that missed, or a remote argument the client never sent. The fix is a default
plus a guard:

```lua
local amount = tonumber(rawAmount)
if not amount then
    return -- the client sent something that is not a number
end
```

On a remote handler this is not just a crash fix, it is the exploit fix. See
`roblox-game-security`.

### `X is not a valid member of Y`

The instance exists, the child does not. Distinct from the nil error: this one
means the parent was found. Check the Explorer for the exact name, including
capitalisation and trailing spaces.

---

## Data and networking

| Error text | Cause | Fix |
|---|---|---|
| `Unable to cast value to Object` | Passing a value where an instance is expected | Check the argument order |
| `Argument 1 missing or nil` | Calling a method with a dot instead of a colon | `object:Method()` |
| `Cannot store Instance in DataStore` | Trying to save a live instance | Save plain data — numbers, strings, tables of those |
| `Cannot store Dictionary in DataStore` with mixed keys | A table with both numeric and string keys, or non-string keys | Use one shape: an array, or a dictionary with string keys |
| `104: Cannot store Dictionary` | Same cause, the error surfaces as a code | Same fix |
| `DataStore request was added to queue` | Exceeding the request budget | Batch writes, back off, see `roblox-data-persistence` |
| `Http requests are not enabled` | `HttpService` is off for the place | Game Settings then Security then Allow HTTP Requests |
| `RemoteEvent ... exhausted` | Too many calls too fast | Rate-limit on the client, validate on the server |
| `Maximum event re-entrancy depth exceeded` | A handler fires the event it is handling | Add a guard flag, or restructure |

---

## UI

| Symptom | Cause | Fix |
|---|---|---|
| Nothing appears at all | `ScreenGui` not in `PlayerGui`, or `Enabled = false` | Check the parent; check `Enabled` |
| Appears then vanishes on respawn | `ResetOnSpawn` is true | Set `ResetOnSpawn = false` |
| Appears behind other UI | Sibling order or `DisplayOrder` | Set `ScreenGui.DisplayOrder`; keep `ZIndexBehavior = Sibling` |
| Sizes are all zero on the first frame | `AbsoluteSize` is not populated yet | Read it after `task.defer`, or on the next render step |
| Works on PC, unusable on phone | Offset-only sizing | Scale for layout, offset for detail. `roblox-ui`, tell R3 |
| Buttons do nothing on mobile | `MouseButton1Click` is mouse-only | Use `Activated` |
| Text overflows its box | Fixed `TextSize` with no constraint | `UITextSizeConstraint`, or `AutomaticSize` |
| Hidden under the topbar | Inset not accounted for | `ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` |

---

## Luau compiler limits

These are compile-time, so the script does not run at all.

| Error text | Cause | Fix |
|---|---|---|
| `Too many local variables` | Over 200 locals in one function scope | Group into tables, or split the function |
| `Too many upvalues` | Over 255 captured from an enclosing scope | Same |
| `Too many registers` | One expression too complex | Break it into steps with intermediate locals |

Full detail: `roblox-luau-language` reference `compiler-limits.md`. Large
executor hub scripts hit these routinely.

---

## "It still doesn't work" — the protocol

This follow-up means the previous fix addressed a different layer than the bug.
Do not re-send the same code with cosmetic changes.

1. **Establish what changed.** Same error, different error, or no error? A
   different error is progress and should be said out loud.
2. **Confirm it is running at all.** `print("running")` at the top of the file.
   If that does not appear, the problem is placement or script type, not logic —
   and no amount of fixing the logic will help.
3. **Confirm which side it runs on.** `print(game:GetService("RunService"):IsServer())`.
   Half of all "still broken" reports are a `Script` and `LocalScript` mix-up.
4. **Confirm the data exists at that moment.** Print the value just before the
   line that fails, not at the top of the script.
5. **Only then** change the logic.

Ask for exactly one thing at a time, and name where to find it:

> Add `print("running")` as the very first line, press Play, and tell me whether
> "running" shows up in the **Output** window. That splits this in half — either
> the script is not starting, or it is starting and failing later.

Never ask for four things at once. Someone stuck will answer none of them.

---

## When there is no error at all

Silence is a category, not an absence. The script runs and nothing happens.

| Likely cause | Check |
|---|---|
| The script is not running | `print` on line 1 |
| Wrong script type for what it does | `RunService:IsServer()` |
| The event never fires | `print` inside the handler |
| A `pcall` swallowed the failure | `local ok, err = pcall(...)` and print `err` |
| An early `return` guard is hit | `print` before each `return` |
| The connection was made after the event already fired | Connect before triggering, not after |
| The instance is invisible, not absent | Check `Visible`, `Transparency`, `Enabled`, size and position |

An unchecked `pcall` is the single most common cause of a silent failure, and
`local _, x = pcall(...)` is how it gets written. Named in the delivery checklist
for that reason.
