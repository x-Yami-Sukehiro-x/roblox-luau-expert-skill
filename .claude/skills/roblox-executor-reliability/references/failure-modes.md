# Failure modes

Why executor features break, grouped by what the player reports. Each row is
the usual cause and the fix the tested assets use. The doctor
(`../../roblox-executor-features/assets/feature-doctor.luau`) confirms most of
them in one run.

## "It does nothing"

| Cause | How to tell | Fix |
|---|---|---|
| the script errored before the feature started | the console (F9) shows a red line from the script | read the line; a missing executor function is the assert's message |
| an old copy is still running, or this copy never ran | the doctor lists the feature as off, or not at all | rerun; every asset unloads its previous session first |
| the key was typed into chat or a TextBox | works when the chat box is closed | none needed: `processed` is respected on purpose |
| the character was not there when it ran | the doctor: "no character" | apply on `CharacterAdded`, after `WaitForChild` |
| the body is seated | the doctor: "seated" | jump out of the seat first; a `SeatWeld` holds the root to the seat |
| the root is anchored by the game | the doctor: "the root is anchored" | nothing moves an anchored part; wait for the game to release it |
| the game resets the value at once | the doctor counts writes on that property | hold it (the table in `../SKILL.md`) |
| the value lives on the server | it changes on your screen and nothing else happens, or it returns on the next update; currency, damage and inventory always live there | client writes do not replicate; find the request the game sends |
| a phone has no key for it | works on PC only | the phone path: thumbstick, `TouchTapInWorld`, or a hub button calling `set` |

## "It works, then stops"

| Cause | How to tell | Fix |
|---|---|---|
| respawn made a new character | stops after the first death | rebind on `CharacterAdded`; never keep the old body in a file-scope local (K4) |
| a game script rewrote the value | stops after a few seconds, or at a round start | `GetPropertyChangedSignal` write-back |
| the camera scripts took the camera back | camera features stop after respawn | watch `CameraType` or `CameraSubject` and re-apply |
| `CurrentCamera` was replaced | FOV or camera features stop after a cutscene | reconnect on `Workspace`'s `CurrentCamera` change (camera-unlock does) |
| the game's anti-cheat corrected it | position snaps back, or a kick | the server checks movement; nothing client-side hides it |
| streaming unloaded the target | ESP labels or teleport targets vanish at distance | work with what is streamed in; say so |

## "It broke something else"

| Cause | How to tell | Fix |
|---|---|---|
| unload restored a retyped value | the game's own value is wrong after unload | restore the captured value (K7) |
| unload restored every part, not only the changed ones | accessories collide after noclip turns off | record what was switched and restore only that |
| two features write the same property | one undoes the other | one owner per property (`composition.md`) |
| a rerun captured the patched value as "original" | unload leaves the feature's value in place | unload the old session before reading originals |
| a hook catches the script's own calls | its own remote calls are rewritten | `checkcaller()` first (K11) |
| a keybind shadows the game's | the game's action on that key stops | pick a key the game does not use; keep it in a constant at the top |

## "It lags"

| Cause | Fix |
|---|---|
| work every frame that could be event-driven | property-changed signals, `CharacterAdded`, `PlayerAdded` |
| instances created every frame | create once, toggle `Enabled` or `Visible` |
| ESP labels rebuilt each frame | refresh a few times a second; 31 highlights at most |
| a `while true do task.wait() end` loop per feature | one connection, disconnected by unload (K5) |

## What the server can see

Position, velocity and physics state of a client-owned character replicate:
fly, noclip, speed and teleports are visible to the server and to other
players, and a server that checks movement corrects them. Camera, lighting,
ESP, spectate and freecam are local and change nothing anyone else sees.
Freecam anchors the local body; other players see it standing still.
