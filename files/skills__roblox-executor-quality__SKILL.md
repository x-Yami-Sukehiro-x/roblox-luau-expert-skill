---
name: roblox-executor-quality
description: Premium executor scripts - the paid-hub bar, honest feature status, zero idle cost, surviving updates. Use for make it premium, polish it.
---

# The premium bar for executor scripts

A free paste and a paid hub often call the same functions. The difference is
everything around the calls: the script tells the truth about what is on,
costs nothing while a feature is off, leaves the game as it found it, keeps
the player's settings, and breaks loudly rather than silently when the game
updates. None of that is decoration, and all of it can be checked.

`roblox-executor-scripting` is the order an expert works in and
`roblox-executor-features` holds the tested features. This skill is what the
finished script must meet before it is called good.

## The bar

Twelve checks, each pass or fail, each with a way to see it. The full
wording and how to verify each is in [premium-bar.md](references/premium-bar.md).

| # | Check | Seen by |
|---|---|---|
| 1 | Missing executor functions are named in one line before anything changes | Run it without one of them |
| 2 | A rerun unloads the previous session first | Run twice; one window, one set of connections |
| 3 | Every control shows the feature's real state, and a failed start says why | Break a target; the toggle reads failed with the reason |
| 4 | Features that write the same property are refused at registration | Register two owners of `WalkSpeed` |
| 5 | A feature that is off costs nothing: no loop, no per-frame work | Count connections with it on, then off |
| 6 | Each feature holds against the game's writers and respawn | The regression matrix in `roblox-executor-reliability` |
| 7 | Unload restores captured values and removes every instance, hook and thread | Unload twice; the game looks as it did |
| 8 | Settings survive a rerun, and a session where the executor can save files | Change, rerun, compare |
| 9 | Notifications only where the result is not visible or arrives later | `roblox-script-feedback` |
| 10 | Controls fit and respond on a 640 x 360 phone and with a gamepad | The UI bundle; HubKit does this already |
| 11 | Labels name effects in the game's words, no hype | `roblox-copy-craft` |
| 12 | `check-file` passes on the delivered file, and registers are under 160 | Quote its output |

A script that fails one is not premium yet, whatever it looks like. Report
the checks that ran and the ones that could not (no executor, no device).

## Honest status: the feature registry

Checks 3 to 5 and 7 share one structure: a registry that knows every feature,
what it owns and whether it is on. The tested one is
[assets/feature-registry.luau](assets/feature-registry.luau):

```lua
-- lint: fragment
local toggles = {}
local registry = createRegistry(function(name, status, reason)
	if status == "failed" then
		toggles[name]:Set(false)
		toggles[name]:SetDescription(`Stopped: {reason}`)
	end
end)

registry.add("Walk speed", {
	owns = { "Humanoid.WalkSpeed" },
	start = speed.start,
	stop = speed.stop,
})

toggles["Walk speed"] = movement:Toggle({
	Title = "Walk speed",
	Flag = "WalkSpeed",
	Callback = function(on: boolean)
		registry.set("Walk speed", on)
	end,
})
session:own(registry.unload)
```

`createRegistry` is the asset's returned function; `movement` is a HubKit
section and `session` the hub loader's. HubKit's `Set` runs the callback, so
the failed toggle calls `registry.set(name, false)`, which returns at once
because the feature is not on.

- `add` refuses a second owner of one property, so two features cannot fight
  over `WalkSpeed` in the player's game.
- `set` starts a feature once; a start that errors, because an update moved
  what it reads, is reported as `failed` with the error, its partial work is
  stopped, and every other feature keeps running.
- `unload` stops running features newest first.

The callback is where the UI and notifications learn the truth. A toggle
drawn from `registry.status` cannot show on while the feature is dead.

## Surviving a game update

Updates are the most common reason a working script stops. The goal is not
to survive every update, which nothing can, but to fail loudly and in the
right place. [surviving-updates.md](references/surviving-updates.md) covers:

- resolving every game target once at start, by name, class, constant or
  table keys taken from the source, and asserting there is exactly one;
- carrying the reason into the feature's status ("Remotes.Collect is
  missing"), so the player reports something useful;
- when the script hash recorded with the dump no longer matches, marking the
  features built from that script as unverified rather than trusting them.

## Idle cost

A feature that is off has no connections, no threads and no instances. The
shape that guarantees it: `start` creates every connection and stores it,
`stop` disconnects all of them. A `while true do` loop that checks
`if enabled then` every frame costs the player frames for a feature they
turned off. Per-frame work belongs only to per-frame effects (fly steering,
freecam); everything else is event-driven. `roblox-performance` has the
measurement.

## The finish

- **Defaults that work.** The script is useful the moment it runs: sensible
  slider values, the safe features off, the window open.
- **One keybind to hide the window**, shown in the window itself, and a way
  back on touch (HubKit's open button).
- **Status where the player looks**: the control itself, not a console print.
- **Nothing narrated.** No welcome toast, no success prints, no credits
  banner over the game.
- **Whole-file delivery** with what the script assumes and what it could not
  check (`roblox-reply-craft`).

## Works with

- `roblox-executor-scripting`: the build order before this bar applies.
- `roblox-executor-features`: tested features to register.
- `roblox-executor-reliability`: the regression matrix behind check 6.
- `roblox-hub-library`: HubKit windows, status and configs for checks 8 to 10.
- `roblox-script-feedback`: which events earn a notification.
- `roblox-register-budget`: the script's shape, under 160 registers.
- `roblox-copy-craft`: labels, descriptions and notices without hype.
- `roblox-ai-mistakes`: the defects a first draft usually has.
