# Regression matrix

The rows every feature script passes, written as the tests in
`library/tests/recipes/` write them. Run a new feature through all of them in
the Luau mocks (`node tools/bin/run-recipe-tests.mjs` for the shipped assets;
the same harness for a new file), then give the player the rows only the game
can show.

## The harness

`library/tests/stubs.luau` builds a world with `HARNESS.world()`: the local
player and camera as instances whose properties can be watched, a character
with a Humanoid and root part, `getgenv()`, other players through
`world.join`, respawns through `world.respawn`, keys through `world.key`, and
`RunService.PreSimulation` and `PreRender` signals to step. The feature file
runs as `__recipe()`.

## Rows, with the assertion each makes

```lua
-- lint: fragment
local world = HARNESS.world()
__recipe()
local feature = world.genv.Features.Speed
local humanoid = world.player.Character.Humanoid

-- runs
check("running it applies the effect", humanoid.WalkSpeed == 40)

-- game writes
humanoid.WalkSpeed = 8
check("a game script's write is answered", humanoid.WalkSpeed == 40)

-- toggle twice
world.key(Enum.KeyCode.G)
check("off restores the game's own value", humanoid.WalkSpeed == 16)
world.key(Enum.KeyCode.G)
check("on again works", humanoid.WalkSpeed == 40)

-- chat typing: the second argument is `processed`
HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.G }, true)
check("the key typed in chat does nothing", feature.on == true)

-- respawn on, respawn off
local body = world.respawn(world.player)
check("on carries to the new body", body.Humanoid.WalkSpeed == 40)
feature.set(false)
body = world.respawn(world.player)
check("off stays off after respawn", body.Humanoid.WalkSpeed == 16)

-- rerun
feature.set(true)
__recipe()
local again = world.genv.Features.Speed
check("a rerun replaces the session", again ~= feature and feature.alive == false)
check("one set of connections", #HARNESS.input.InputBegan.handlers == 1)

-- unload twice
again.unload()
again.unload()
check("unload restores and clears the namespace", body.Humanoid.WalkSpeed == 16 and world.genv.Features.Speed == nil)
world.key(Enum.KeyCode.G)
check("the key does nothing after unload", body.Humanoid.WalkSpeed == 16)
```

The rerun row is the one that catches "originals" captured from the patched
value: run the feature, run it again, unload, and check the game's value
came back rather than the feature's.

## Rows only the game can show

The mocks model signals and property writes. They do not model physics,
replication, the camera scripts, or the game's own code. Give the player these
steps, short, with what they should see:

| Row | Step | Expected |
|---|---|---|
| runs in this game | run it, press nothing | the effect is on |
| the game's own resets | play a round, sprint, get stunned | the effect stays, or the reply said it would not |
| phone | play on a phone or the emulator's touch mode | reachable without a keyboard |
| seat | sit in a vehicle or seat, toggle | behaves as the reply said: refuses or waits |
| anti-cheat | use it for a minute near other players | no snap-back or kick; if there is, it is the server's check |
| other features | turn on the other features the player uses | none of them stops working |

Report which rows ran in the mocks, which the player has to run, and never
upgrade the second kind to a pass.

## Adding a row for a fixed bug

Every bug found in a feature becomes a row before it is fixed: reproduce it in
the mocks (it fails), fix it (it passes), and record the fix in the ledger with
`Check:` naming that row. The bug cannot come back without a failing test.
