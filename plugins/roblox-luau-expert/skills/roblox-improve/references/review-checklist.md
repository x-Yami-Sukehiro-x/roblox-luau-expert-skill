# Review checklist

Read in this order. Earlier categories hurt players more when they fail, so
a review that runs out of time has covered the ones that matter.

## 1. Correctness

- Nil after a yield: the player left, the character respawned, the instance
  was destroyed between the check and the use.
- `WaitForChild` on a name that does not exist, or on something the server
  never replicates (`ServerStorage`, `ServerScriptService`).
- A value read once at start-up that the game changes later.
- Numbers from outside the file: NaN fails every comparison, so a `>` check
  lets it through. Test `value == value` (false only for NaN) and a range
  that excludes infinity before using the number.
- `if value then` on a count, balance or string where 0 or "" is a real case.
- Tables sent through remotes: mixed keys, nil holes, metatables and
  functions do not survive the trip.
- Deprecated APIs in the code being changed (`wait`, `spawn`, `BodyVelocity`).

## 2. Security and trust (game code)

- Every `OnServerEvent` and `OnServerInvoke`: type, range, ownership and rate
  checked before anything happens.
- Prices, damage, cooldowns, positions and rewards computed on the server,
  never taken from the client.
- `ProximityPrompt` and `ClickDetector` grants re-checked on the server:
  distance, state, cooldown.
- Attributes on a player carry only what every client may see.
- Admin commands check the caller's identity on the server, not a client flag.

## 3. Data

- `UpdateAsync` for anything derived from the old value; session locking or
  ProfileStore; `BindToClose` saves; schema versioned.
- A failed load never falls through to defaults on a path that saves.
- Receipts idempotent through a `PurchaseId` ledger.

## 4. Lifetime and leaks

- Every `Connect` has an owner that disconnects it, or it lives on an
  instance that is destroyed with it.
- Per-player tables cleared on `PlayerRemoving`; per-life state cleared on
  `CharacterRemoving`.
- Threads from `task.delay` and `task.spawn` cancelled on teardown.
- Executor scripts: rerun replaces the old session; unload restores what
  was changed and removes hooks and Drawings.

## 5. Performance

Only on a hot path: `Heartbeat`, `RenderStepped`, `PreSimulation` bodies,
tight loops. Allocation, `FindFirstChild` chains and `GetDescendants` there
are findings; the same in `PlayerAdded` or a purchase handler are not.
Per-frame work that could be an event is a finding anywhere. Claim a speed-up
only with a before and after measurement.

## 6. Input and fit (anything that draws)

- `Activated` rather than `MouseButton1Click`; 44 px targets; nothing
  hover-only; gamepad selection reaches every control.
- Fits 640 x 360 without clipping; bounded on ultrawide.
- Loading, empty and error states exist.

## 7. Code craft

The ceremony budget, names from the game's vocabulary, comments that carry
facts, one `pcall` per boundary. Mostly Advisory unless it hides a bug (a
`pcall` swallowing the error that explains the report).

## Executor scripts, additionally

- Every executor function feature-detected in one bind with one assert.
- One value layer per job; no fallback chain across globals, upvalues and
  properties.
- Search by value or constant, never by index; restore the captured value,
  not a retyped literal.
- The regression matrix from `roblox-executor-reliability`: toggle twice,
  respawn, rerun, unload twice, chat typing, phone.
