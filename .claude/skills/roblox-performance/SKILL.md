---
name: roblox-performance
description: Roblox performance and memory - MicroProfiler, ScriptProfiler, leaks, per-frame cost, instance churn, streaming, parallel Luau, native code. Use for lag, stutter, low FPS or climbing memory.
---

# Performance and memory

Measure, then fix the largest thing, then measure again. Roblox performance
intuition is wrong often enough that optimising without a profile mostly moves
code around.

## Load a reference when

| Need | File |
|---|---|
| Actors, `SharedTable`, the serial boundary, worker pools | `references/parallel-luau.md` |

---

## Measure first

**MicroProfiler** — `Ctrl+F6` in Studio, or `Ctrl+Shift+F6` for the dump view.
Shows where frame time goes, by labelled scope. Instrument your own code so it
shows up:

```lua
debug.profilebegin("CombatTick")
updateCombat(dt)
debug.profileend()
```

The calls cost almost nothing when the profiler is closed, so leaving them in
shipped code is normal and useful. They must be balanced on the same thread.

**ScriptProfiler** — attributes CPU time to individual Luau functions, which the
MicroProfiler does not. Open it from Studio; on a live server, start it from the
developer console.

> **`ScriptProfilerService` is not callable from your game.** Every member —
> `ServerStart`, `ServerRequestData`, `ClientStart`, `ClientRequestData`,
> `ClientStop`, `DeserializeJSON` — is `{Plugin}` in the dump. A Script or
> LocalScript calling one errors. The service exists for Studio tooling; the
> profiler UI is your access path.

**Stats service** — cheap runtime numbers, good for a dev HUD or telemetry:

<!-- lint: fragment -->
```lua
local Stats = game:GetService("Stats")
Stats.FrameTime, Stats.HeartbeatTime, Stats.PhysicsStepTime
Stats.InstanceCount, Stats.MovingPrimitivesCount, Stats.ContactsCount
Stats.DataSendKbps, Stats.DataReceiveKbps
Stats.PhysicsSendKbps, Stats.PhysicsReceiveKbps
Stats:GetTotalMemoryUsageMb()
```

`MovingPrimitivesCount` is the physics number that matters — unanchored parts
being simulated. If it is in the thousands, physics is your bottleneck and no
amount of Luau optimisation will help.

**Memory** — Studio's *Developer Console → Memory* tab breaks usage down by
category. `debug.setmemorycategory("Combat")` tags a thread's allocations so
they appear under your own label instead of "Script".

---

## Memory leaks

The dominant Roblox leak is **undisconnected connections**, and it is not close.

**Why it is so common.** A connection holds your closure; the closure holds
everything it captured. Connections die automatically when *the instance owning
the signal* is destroyed — and `Player` objects are **not** destroyed when a
player leaves. Neither is a character model unless you destroy it. So every
`player.CharacterAdded:Connect` you never disconnect is permanent, and it
retains whatever that closure touched.

**Detection.**

```lua
task.spawn(function()
    while task.wait(30) do
        print(("mem %.1f MB, instances %d"):format(
            collectgarbage("count") / 1024, Stats.InstanceCount))
    end
end)
```

A leak climbs monotonically with no plateau across rounds. A healthy server
sawtooths.

Then narrow it: the Memory tab's per-category breakdown, and *LuauHeap*
snapshots in the Developer Console, which show what is retaining what.

**The other four leak shapes:**

1. **Instance-keyed tables never cleared** — `scores[player]` with no
   `PlayerRemoving` removal. Clear it, or use `__mode = "k"`.
2. **`:Destroy()` without dropping your reference** — the instance is dead but
   your table pins it.
3. **Threads that never end** — a `while true` loop over a destroyed object.
   Track them in a Trove.
4. **Growing caches with no eviction** — a memoisation table keyed by something
   unbounded.

The structural fix for all of them is the same: **one Trove or Janitor per
lifetime**, destroyed at a known point. See `roblox-architecture`.

---

## Per-frame cost

The rule: **allocate nothing in a per-frame loop that could be hoisted.**

```lua
-- WRONG: two allocations per frame per part
RunService.PostSimulation:Connect(function(dt)
    for _, part in workspace.Projectiles:GetChildren() do     -- new table each frame
        part.CFrame = part.CFrame * CFrame.new(0, 0, -dt * 50)
    end
end)

-- RIGHT: maintain the list, allocate once
local projectiles: { BasePart } = {}
workspace.Projectiles.ChildAdded:Connect(function(c) table.insert(projectiles, c :: BasePart) end)
workspace.Projectiles.ChildRemoved:Connect(function(c)
    local i = table.find(projectiles, c)
    if i then table.remove(projectiles, i) end
end)

RunService.PostSimulation:Connect(function(dt)
    local step = CFrame.new(0, 0, -dt * 50)
    for _, part in projectiles do
        part.CFrame = part.CFrame * step
    end
end)
```

Specific offenders: `GetChildren()` / `GetDescendants()`, table literals, string
concatenation, `RaycastParams.new()`, and `Instance.new` for effects that should
come from a pool.

**Not everything needs 60 Hz.** `RunService:BindToSimulation(fn, Enum.StepFrequency.Hz10)`
runs a callback at a fixed lower rate — cleaner and cheaper than an accumulator
for AI ticks, regeneration and proximity checks.

**Signals beat polling.** A `.Changed` connection costs nothing when nothing
changes; a per-frame comparison costs every frame forever.

---

## Instance and part cost

- **Part count is a render and physics cost.** Union and mesh where practical;
  `MeshPart` with a low-detail `CollisionFidelity` is cheaper than a
  many-part assembly.
- **`CollisionFidelity`** — `Box` < `Hull` < `Default` < `PreciseConvexDecomposition`
  in cost. Most decorative meshes want `Box`, or `CanCollide = false` and no
  collision geometry at all.
- **Anchor everything that does not move.** An unanchored part is simulated
  forever, even at rest. `MovingPrimitivesCount` is the number to watch.
- **`CanTouch = false` and `CanQuery = false`** on decorative parts removes them
  from touch dispatch and spatial queries.
- **Instance count itself matters.** Tens of thousands of instances costs memory
  and replication regardless of what they do.

---

## StreamingEnabled

For any large world, this is the highest-leverage single setting: the client
holds only nearby content, cutting client memory and join time substantially.

The cost is that client code must handle absence as normal — see
`roblox-engine-api`. Set `ModelStreamingMode = Persistent` on anything a client
script must always be able to find, and use `StreamingIntegrityMode` to control
whether the client pauses rather than dropping a character through unloaded
ground.

`Player:RequestStreamAroundAsync(position)` before teleporting a player avoids
landing them in the void.

---

## Parallel Luau

Real multi-core execution, with real restrictions.

```lua
-- inside an Actor
local actor = script:GetActor()

actor:BindToMessageParallel("ComputePaths", function(request)
    -- parallel: read the DataModel, compute freely
    local results = expensiveSolve(request)

    task.synchronize()
    -- serial again: safe to write
    applyResults(results)
end)
```

The API surface:

```lua
Actor:BindToMessage(topic, fn)          -- runs serially
Actor:BindToMessageParallel(topic, fn)  -- runs in parallel
Actor:SendMessage(topic, ...)
task.desynchronize()                     -- leave serial execution
task.synchronize()                        -- return to it
SharedTableRegistry:GetSharedTable(name) -- cross-Actor shared state
SharedTableRegistry:SetSharedTable(name, st)
```

Rules:

- **Read in parallel, write in serial.** The engine explicitly marks some members
  `Safe` and some `Unsafe` — the generated table
  `roblox-luau-expert/references/verified/parallel-safety.md` lists both.
  Anything unmarked is not a promise either way; if a write is involved,
  synchronize.
- **A script only runs in parallel if it is a descendant of an `Actor`.**
  Wrapping code in `task.desynchronize` outside an Actor does nothing.
- **Actors do not share Luau state.** Communication is `SendMessage` (copied) or
  `SharedTable` (genuinely shared, and safe for concurrent access).
- **`SharedTable` holds only primitives**, nested SharedTables, and a limited set
  of datatypes. No Instances, no functions.

**Worth it for:** pathfinding over many agents, procedural generation, voxel or
terrain work, large per-frame raycast batches, physics-adjacent maths.

**Not worth it for:** anything dominated by DataModel writes, anything already
under a millisecond, or ordinary gameplay logic. The synchronisation overhead is
real and the debugging cost is high.

---

## Native code generation

```lua
--!native
```

at the top of a script, or `@native` on a single function, compiles to machine
code instead of bytecode.

It pays off in **numeric hot loops with type annotations** — the compiler
specialises on the types you declare. It costs memory, increases load time, and
silently falls back to the interpreter for constructs it cannot compile, so a
script marked `--!native` is not guaranteed to be native.

Measure before and after. Applying it project-wide is a common mistake that
increases memory for no measurable gain.

---

## Asset loading

```lua
local ContentProvider = game:GetService("ContentProvider")

ContentProvider:PreloadAsync({ soundInstance, imageLabel, meshPart })
```

Preload before a moment that must not stutter — round start, a cutscene, a menu
open. Preloading *everything* at join makes the loading screen long instead;
preload what the next thirty seconds needs.

`PreloadAsync` yields and can error on a bad asset id — wrap it, and never let
one broken decal block the loading screen forever.

---

## Optimisation order

Do these in order. Skipping ahead wastes effort.

1. **Profile.** Find the actual cost. It is frequently not where you assumed.
2. **Do less work.** Fewer parts, fewer instances, lower tick rate, smaller
   radius, earlier exit. This is where the large wins are.
3. **Do it less often.** Batch, cache, throttle, event-drive instead of polling.
4. **Do it more cheaply.** Hoist allocations, avoid `GetChildren` in loops,
   compare squared magnitudes, reuse `RaycastParams`.
5. **Do it in parallel.** Actors, once (2) through (4) are exhausted.
6. **Do it natively.** `--!native` on the remaining measured hot loop.

Micro-optimising Luau before reducing part count and instance count is the most
common wasted effort in Roblox performance work.

## Works with

- `roblox-engine-api`: the frame pipeline the costs sit in.
- `roblox-ui-components`: virtualised lists instead of thousands of rows.
- `roblox-studio-mcp`: Roblox's profiling skill during a playtest.
