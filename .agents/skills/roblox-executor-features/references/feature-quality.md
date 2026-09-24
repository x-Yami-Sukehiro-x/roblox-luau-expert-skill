# The quality bar for a feature script

What separates a feature script that works once in one game from one that
works every time. Each line is something the tested assets do and a failing
script usually does not.

## Start-up

- **One bind, one assert.** `local getgenv, gethui = getgenv, gethui` then
  `assert(getgenv and gethui, "needs getgenv, gethui")`. No `typeof` ladders.
- **One namespace.** `getgenv().Features.<Name>` holds the session table.
  Never scatter globals such as `_G.FlyEnabled`.
- **Unload the previous session first**, before reading any original value;
  otherwise a rerun saves the patched value as the "original".
- **Start on.** Running the script is the request; the key turns it off.

## Input

- **`processed` is respected.** `InputBegan:Connect(function(input, processed)`
  and return when `processed`, so typing F in chat does not toggle fly.
- **Mobile has a path.** A key alone strands a phone player. Fly steers from
  `Humanoid.MoveDirection`, which the touch thumbstick drives; click teleport
  uses `TouchTapInWorld`; every feature exposes `set(on)` for a hub button.
- **Held keys are a set**, cleared on `InputEnded`, not a counter that drifts
  when a key-up is missed.

## Physics

- **Modern movers only.** `LinearVelocity`, `AlignOrientation`,
  `AlignPosition`. `BodyVelocity`, `BodyGyro` and `BodyPosition` are
  deprecated (`verify-api.mjs BodyVelocity`).
- **Constraints live under one Attachment** on the root, so one `Destroy`
  removes all of them.
- **Camera-relative, including pitch.** Split `MoveDirection` along the
  camera's flat forward and right, then rebuild along `LookVector`: looking
  up and pressing forward climbs.
- **Speed is capped, not summed.** Diagonal plus climb is normalised, so it is
  never faster than the set speed.
- **Steer before physics**: `RunService.PreSimulation`, not `RenderStepped`
  or a `while task.wait()` loop.

## Lifetime

- **Every connection is stored** and disconnected in `unload`.
- **Respawn is handled.** `CharacterAdded` drops references to the old body,
  waits for the new one's parts, re-checks that the session is alive and the
  character is still current after the wait, then re-applies.
- **Restore what was captured, only what was changed.** Noclip restores only
  parts it switched off, not every part to `true`. Speed restores the game's
  own values, not 16.
- **Unload is idempotent** and clears the namespace only if it still points
  at this session.

## Cost

- **Event-driven where possible.** Speed and fullbright write back on
  `GetPropertyChangedSignal`, not every frame.
- **Throttle labels.** ESP refreshes four times a second, not per frame, and
  hands its 31 highlights to the nearest players.
- **No per-frame allocation** of instances; create once, toggle `Enabled`.

## Honesty

- Report a missing executor function by the assert; never a silent no-op.
- Say in the reply what replicates and what the server can correct.
- A mocked test proves the logic, not the game. Name the runtime checks that
  were not run.
