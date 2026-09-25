# Verifying in Studio

What to run in Studio for each kind of change, so the reply reports what was
observed rather than what should happen. Every check here needs a playtest
unless it says `Edit`.

## Any script change

1. `get_console_output` right after the edit, before playing: syntax and load
   errors show here.
2. `start_stop_play` to start; `get_console_output` again for runtime errors
   and warnings, including deprecation notices.
3. Read the state the change was meant to produce with `execute_luau` in the
   right data model (`Server` for server values, `Client` for UI and input),
   returning the value rather than printing it.
4. Stop the playtest before the next edit.

## UI: fit on every screen

- `screen_capture` of the running UI at the current window size.
- For phone and tablet sizes, call `skill` with `rbx-device-simulator-lua`
  and follow Roblox's own instructions for switching the emulated device.
  Capture again at a small landscape phone and at a tablet.
- Compare with `python tools/py/viewport_fit.py <file>`: the computed sizes
  say what should fit; the captures say what did.

## UI: every control responds

In `Client` during a playtest:

```lua
-- lint: fragment
local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
local target = playerGui.Hub.Panel.Buy
local centre = target.AbsolutePosition + target.AbsoluteSize / 2
local covering = {}
for _, hit in playerGui:GetGuiObjectsAtPosition(centre.X, centre.Y) do
	table.insert(covering, hit:GetFullName())
end
return covering
```

Anything listed besides the button and its own children sits over it
(`../../roblox-ui-interaction/references/blocked-input.md`, rung 3). Then
click it with `user_mouse_input` on the instance, and read back the state
the click should change.

## Server and client agree

Run the same read in `Server` and in `Client`. A value that differs is a
replication question (`../../roblox-networking/SKILL.md`): a client write that
never reached the server, or a server value the client has not been sent.

## Saving and loading

Only with the user's go-ahead and a test store name, never the live one.
Play, change the value, stop; play again and read it back in `Server`.
`BindToClose` runs when the playtest stops, which is the path that loses data
in production when it is wrong.

## Performance

Call `skill` with `rbx-perf-profiling` for Roblox's current MicroProfiler and
memory workflow, then compare against `../../roblox-performance/SKILL.md`.

## Reporting

Name the place, the data model and the playtest runs. Quote the console
lines that matter, attach or describe the captures, and say which checks
were not run. A Studio playtest is one machine and one player: it does not
prove behaviour with many players, on real phones, or in a published server.
