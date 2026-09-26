# Rewrites, surface by surface

Each row is a string a model produced and the string that replaced it. The
rewrite is never a synonym swap; it says something more specific.

## Hub rows

| Generated | Written | What changed |
|---|---|---|
| **Ultimate Auto Farm** · "Seamlessly farm coins with our powerful automation!" | **Auto farm** · "Coins within 60 studs, every 0.5 s" | The description gives the two limits a player needs |
| **Enable Speed Hack** | **Walk speed** · slider 16 to 100 | The switch already says enable; the range is the information |
| **OP Kill Aura 🔥** | **Attack nearest** · "Mobs only, within your sword's reach" | No hype, no emoji; the scope is stated |
| **Infinite Money** | (removed) | The server owns money; a label promising it is a lie |
| **Misc** tab holding fly, noclip and teleports | **Movement** tab | A tab name says what is in it |
| **Anti AFK (Bypass)** | **Stay in server** · "Stops the 20-minute idle kick" | The effect, and the fact that makes it useful |

## Notices

| Generated | Written |
|---|---|
| Successfully enabled Fly! ✅ | (none: the toggle shows it) |
| Script loaded successfully! Enjoy! | (none) |
| Error! Something went wrong. Please try again. | Auto farm stopped: Remotes.Collect is missing |
| Settings saved successfully! | Settings saved (only when the write returned success) |
| Warning: your executor may not support this feature. | Needs fireproximityprompt, which this executor lacks |

## Errors in code

| Generated | Written |
|---|---|
| `error("An unexpected error occurred while trying to find the remote. Please make sure the game has loaded!")` | `error("Remotes.Collect is missing")` |
| `assert(humanoid, "Failed to get humanoid; character may not exist yet")` | Wait for `CharacterAdded`; no message is needed where the engine's own error names the missing child |
| `warn("[MyHub] [Error] Failed!")` | ``warn(`{HUB} {feature} stopped: {reason}`)`` with `HUB` declared once |

## Names

| Generated | Written | Why |
|---|---|---|
| `local data = remote:InvokeServer()` | `local inventory = remote:InvokeServer()` | Says what came back |
| `local temp = humanoid.WalkSpeed` | `local originalWalkSpeed = humanoid.WalkSpeed` | Says why it was kept |
| `local function handleIt()` | `local function collectNearestCoin()` | A verb phrase for what it does |
| `local plr, btn, pos` | `local player, buyButton, spawnPosition` | Spelled out |
| `local v14 = u3.Cooldown` (kept from a dump) | `local sprintCooldown = sprintConfig.Cooldown`, once the source proves it | A decompiler label is not a name |

## Comments

| Generated | Written |
|---|---|
| `-- This function handles the speed feature by setting the walk speed` | (deleted: the function name says it) |
| `-- Based on the decompiled SprintController script provided by the user` | (deleted: provenance goes in the reply) |
| `-- Fixed: now uses task.wait instead of wait` | (deleted: the diff is the changelog) |
| `-- Loop through all the coins` above `for _, coin in coins do` | (deleted) |
| (nothing) above `task.wait(0.5)` | `-- The server drops collects closer together than CollectCooldown (0.5 s in CoinClient).` |

## Commit messages

| Generated | Written |
|---|---|
| `Update files` | `Pace the auto farm at the game's 0.5 s collect cooldown` |
| `feat: enhance script with various improvements` | `Report a feature that fails to start instead of leaving its toggle on` |
| `Refactor code for better readability and maintainability` | `Move hub toggles into builders; main chunk 206 -> 16 registers` |
| `Fixed bug` | `Stop fly from restoring the patched speed after a rerun` |

## Replies

| Generated | Written |
|---|---|
| "Great question! Here's a comprehensive, robust solution that seamlessly handles all edge cases:" | (start with the one-line summary, then the code) |
| "I've thoroughly tested this and it works perfectly." | "check-file: 6 passed. Not run: a real executor." |
| "Let me know if you need anything else! 😊" | (nothing) |
