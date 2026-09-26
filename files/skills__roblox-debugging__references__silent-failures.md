# When nothing happens and nothing errors

Walk this in order and stop at the first "no". Each step is one probe.

## 1. Does the script run?

Put `print("<script name> running on", if game:GetService("RunService"):IsServer() then "server" else "client")`
on line 1. No output means it never ran:

| Script | Runs in | Never runs in |
|---|---|---|
| Script, `RunContext` Legacy (the default) | `ServerScriptService`, `Workspace` | `ReplicatedStorage`, `StarterPlayerScripts` |
| LocalScript | `StarterPlayerScripts`, `StarterCharacterScripts`, `StarterGui`, the character, a tool the player holds | `Workspace` (outside the character), `ServerScriptService`, `ReplicatedStorage` |
| ModuleScript | only when something requires it | anywhere, on its own |

Also check `Enabled` on the script. A Script whose `RunContext` is Server
or Client ignores the container rules above and runs in more places,
including `ReplicatedStorage`, so read that property before concluding it
cannot run.

## 2. Is it on the right side?

A server script changing one player's GUI changes the copy the server made,
not what the player sees. A LocalScript changing a part changes it only for
that player. `roblox-networking/references/replication-model.md` is the
table.

## 3. Does the thing exist yet?

The character loads after the player joins; with StreamingEnabled, distant
parts are not on the client at all. Print the instance at the moment of use.
Wait for the event that creates it (`CharacterAdded`, `ChildAdded`) rather
than a fixed delay.

## 4. Did respawn undo it?

Changes to a character die with it. So do connections held on its parts.
Re-apply on `CharacterAdded`. A ScreenGui with `ResetOnSpawn = true` (the
default) is rebuilt on every death, and its old connections point at the
destroyed copy.

## 5. Does something rewrite it?

Print the value one frame later (`task.wait()` then print). If it is back,
something writes it: the game's scripts, the Humanoid (WalkSpeed, JumpPower,
CanCollide on limbs), animations (Motor6D transforms), the camera scripts.
`GetPropertyChangedSignal` with a `debug.traceback()` print shows who.

## 6. UI: does the input reach it?

In order: the connection exists (not lost to a clone or respawn); the object
is a button (`Activated` on a Frame never fires); nothing covers it (an
`Active` frame, a higher `ZIndex` or `DisplayOrder`); `Interactable` is on;
it is inside a clipping parent's visible area; a scroll gesture did not take
the touch; the game's input bindings did not sink it. Printing
`PlayerGui:GetGuiObjectsAtPosition(x, y)` at the press point lists what is
on top. `roblox-ui-interaction` has the fixes.

## 7. Executor: did a missing function turn into nothing?

A fallback like `if hookfunction then ... end` skips the feature silently on
an executor without it. Replace it with one bind and one assert so the
missing function is an error the player can report.
