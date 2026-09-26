# The premium bar, check by check

Each check says what passes, how to see it, and the draft that usually fails
it. Run them on the delivered file, not on the idea of it. Where a check needs
an executor or a device that was not available, say it was not run.

## 1. Capabilities named before anything changes

**Passes:** the executor functions the script calls are bound in one `local`
line and checked by one `assert` whose message lists them, before the first
instance is created or value is written.
**See it:** remove one of them from the environment (the Luau mocks can) and
run; the error names it and the game is untouched.
**Usually fails as:** seven `if typeof(x) ~= "function"` blocks spread
through the file, or a fallback that silently does nothing.

## 2. A rerun unloads the previous session

**Passes:** the session lives under one `getgenv()` key; the script unloads
whatever is there before reading any original value.
**See it:** run twice. One window, one set of connections, and the second
run's captured "original" is the game's value, not the first run's.
**Usually fails as:** two windows, doubled keybinds, and a speed that
"restores" to the patched value.

## 3. Controls show the truth

**Passes:** a toggle reads on only while its feature runs. A start that fails
turns the toggle off and shows the reason beside it.
**See it:** rename the target in a test world; the toggle reads
`Stopped: Remotes.Collect is missing`.
**Usually fails as:** the toggle flips on, the feature errors in the console,
and the player sees a lit switch that does nothing.

## 4. One owner per property

**Passes:** each feature declares the properties it writes; a second writer
is refused when it registers (`assets/feature-registry.luau`).
**See it:** add "Sprint" and "Walk speed" both owning `Humanoid.WalkSpeed`;
the second `add` errors naming both.
**Usually fails as:** two sliders that each "restore" the other's value.

## 5. Off costs nothing

**Passes:** with every feature off, the script holds only the window and its
input connections. Features create their connections in `start` and drop
them in `stop`.
**See it:** count stored connections with a feature on and off; the difference
is everything the feature made, and off returns to the baseline.
**Usually fails as:** `while task.wait() do if enabled then ... end end`,
running forever for a feature nobody turned on.

## 6. Holds in the game

**Passes:** the matrix in `roblox-executor-reliability`: toggle twice, game
writes, respawn on and off, rerun, unload twice, chat typing, phone, other
features on.
**Usually fails as:** works until the first death.

## 7. Unload leaves the game as found

**Passes:** every captured value restored, every instance destroyed, hooks
restored, threads cancelled, the window gone, the `getgenv()` key cleared only
if it still points at this session. A second unload does nothing.
**See it:** unload twice and compare the properties the script touched.
**Usually fails as:** restoring `WalkSpeed = 16` rather than the value read,
or leaving a `Highlight` parented under the character.

## 8. Settings are kept

**Passes:** a rerun restores the player's choices; where the executor has
file functions, so does a new session. Missing file functions leave settings
session-only and the window says so once.
**See it:** change a slider, rerun, compare.
**Usually fails as:** a config system that saves on every slider tick, or
restores a toggle's look without starting its feature.

## 9. Notifications earn their interruption

**Passes:** a notice appears for results the player cannot see where they
acted: a failure, a background job finishing, the game changing something
the script depends on. Never for a toggle that already shows its state.
Rules: `roblox-script-feedback`.
**Usually fails as:** "Fly enabled!" toasts stacked over the game.

## 10. Fits and responds everywhere

**Passes:** the window fits a 640 x 360 phone, every control is 44 px after
scaling, touch has a way to reopen a hidden window, a gamepad can select
every control. HubKit does all of this; a hand-built window follows the UI
bundle.
**See it:** `python tools/py/viewport_fit.py <file>` and the input matrix.

## 11. Words name effects

**Passes:** `Walk speed`, `Collect coins within 50 studs`, `Stopped:
Remotes.Collect is missing`. No `Ultimate`, `OP`, `Godmode` for a speed
change, no emoji labels, no descriptions that repeat the title.
Rules: `roblox-copy-craft`.

## 12. Measured

**Passes:** `node tools/bin/check-file.mjs <file>` passes on the delivered
file, the main chunk is under 160 registers, and the reply quotes the output.
**Usually fails as:** "tested and working" with nothing run.
