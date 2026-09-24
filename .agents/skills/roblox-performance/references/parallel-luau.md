# Parallel Luau: Actors, SharedTable and the serial boundary

Parallel Luau is not "threads". It is a set of isolated Luau VMs that may run
simultaneously, with a hard rule about when any of them is allowed to touch the
DataModel.

Reach for it when profiling shows a **CPU-bound** workload — pathfinding for
many agents, chunk generation, per-entity simulation. It does nothing for a
workload that is waiting on the network or a DataStore, and it makes simple code
considerably harder to read. Measure first.

---

## The model

- An **`Actor`** is an `Instance` (a `Model` subclass). Scripts **parented under
  an `Actor`** get their own Luau VM.
- Actors **share no Luau state**. No upvalues, no globals, no module instances.
  A `ModuleScript` required from two Actors is loaded twice, independently.
- Code runs **serial** by default. `task.desynchronize()` moves the current
  thread into parallel; `task.synchronize()` moves it back.
- **In parallel you may read the DataModel but not write it.** Writes must
  happen serially.

Only the last two are enforced by the engine. The first two are what actually
shape the design, and are why "just wrap it in an Actor" does not work on
existing code.

---

## A worked Actor

The structure matters as much as the code — a script only runs in its own VM if
it is a descendant of an `Actor`.

```
ServerScriptService
└── Workers                (Folder)
    ├── Actor              (Actor)
    │   └── Worker         (Script, RunContext = Server)
    ├── Actor              (Actor)
    │   └── Worker         (Script)
    └── ...
```

```lua
--!strict
-- Worker: one copy of this runs inside each Actor, in its own VM.
local actor = script:GetActor()
assert(actor, "Worker must be parented under an Actor")

local function solve(request)
    -- Pure computation. No DataModel writes, no yielding.
    local total = 0
    for _, value in request.values do
        total += value * value
    end
    return total
end

-- BindToMessageParallel runs the handler in parallel automatically.
actor:BindToMessageParallel("Solve", function(request)
    local answer = solve(request)

    -- Writing back to the DataModel requires the serial phase.
    task.synchronize()
    request.target.Value = answer
end)
```

Dispatch from the serial side:

```lua
local workers = {}
for _, actor in workerFolder:GetChildren() do
    if actor:IsA("Actor") then
        table.insert(workers, actor)
    end
end

local next = 1
local function dispatch(request)
    workers[next]:SendMessage("Solve", request)
    next = next % #workers + 1          -- round-robin
end
```

| Member | Runs the handler | Note |
|---|---|---|
| `Actor:BindToMessage(topic, fn)` | Serially | Safe to write the DataModel |
| `Actor:BindToMessageParallel(topic, fn)` | In parallel | `task.synchronize()` before any write |
| `Actor:SendMessage(topic, ...)` | — | Fire-and-forget. No return value |
| `Instance:GetActor()` | — | The owning `Actor`, or `nil` if not under one |

**`SendMessage` has no return value.** There is no request/response. The worker
writes its result somewhere the caller can see it — a `SharedTable`, a value
object, an attribute set after `task.synchronize()`.

**Pick a worker count.** One `Actor` per work item is worse than none: each
carries VM setup cost. A small pool sized to the core count, fed round-robin, is
the shape that pays.

---

## `SharedTable`

`SharedTable` is the only structure that can be read and written from more than
one VM. It is a **datatype**, not a class, so it is absent from the API dump
entirely — `node tools/bin/verify-api.mjs SharedTable` resolves it from the
vendored datatype reference instead.

```lua
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local state = SharedTable.new({ processed = 0 })
SharedTableRegistry:SetSharedTable("WorkerState", state)

-- In any Actor's VM:
local state = SharedTableRegistry:GetSharedTable("WorkerState")
```

| Member | Purpose |
|---|---|
| `SharedTable.new(t?)` | Construct, optionally from a plain table |
| `SharedTable.increment(st, key, delta)` | **Atomic** read-modify-write on a number |
| `SharedTable.update(st, key, fn)` | **Atomic** read-modify-write with a function |
| `SharedTable.clone(st, deep?)` | Copy |
| `SharedTable.cloneAndFreeze(st, deep?)` | Frozen copy; writes to it error |
| `SharedTable.isFrozen(st)` | |
| `SharedTable.size(st)` | |
| `SharedTable.clear(st)` | |

### The rule that prevents data races

Individual reads and writes are atomic. **A read followed by a write is not.**

```lua
-- WRONG - two Actors can both read 5 and both write 6. One increment is lost.
state.processed = state.processed + 1

-- RIGHT - one atomic operation
SharedTable.increment(state, "processed", 1)

-- RIGHT - for anything that is not a plain number
SharedTable.update(state, "best", function(current)
    if current == nil or candidate.score > current.score then
        return candidate
    end
    return current
end)
```

`increment` and `update` exist precisely because the naive form is broken, and
they are the whole reason to prefer `SharedTable` over passing data through
messages. Code that reads a field, computes, and assigns back is a race that
appears only under load — the worst kind to debug.

`update`'s callback may run **more than once** under contention, exactly like a
DataStore `UpdateAsync` transform. Keep it pure.

### What it can hold

Booleans, numbers, vectors, strings, other `SharedTable`s, and serialisable
datatypes. **No `Instance`s, no functions, no threads, no metatables.**
Nesting `SharedTable`s is how you build a structure; a plain Luau table assigned
into a `SharedTable` is converted, not referenced.

`cloneAndFreeze` gives you a read-only snapshot several Actors can read without
any coordination at all, which is often the better answer than a mutable shared
structure.

---

## The serial boundary in practice

```lua
-- parallel phase: read freely, compute
local origin = part.Position          -- reading the DataModel is fine
local result = expensive(origin)

task.synchronize()                     -- <- everything after this is serial
part.CFrame = CFrame.new(result)       -- writing requires it
```

`task.synchronize()` **yields** until the engine reaches a serial phase. That
means:

- Anything you captured before it must be re-validated after — the part may have
  been destroyed while you waited.
- Calling it in a tight loop destroys the benefit. Do all the parallel work,
  synchronize once, write everything.

**Not every read is safe in parallel, either.** The dump marks a small set of
members explicitly `Unsafe`, and several of them are exactly what UI or layout
code reaches for:

- `GuiBase2d.AbsolutePosition`, `.AbsoluteSize`, `.AbsoluteRotation`
- `ScrollingFrame.AbsoluteCanvasSize`, `.AbsoluteWindowSize`
- `UIGridLayout.AbsoluteCellCount`, `.AbsoluteCellSize`
- `UIGridStyleLayout.AbsoluteContentSize`

The full generated lists are in
`roblox-luau-expert/references/verified/parallel-safety.md`. **Anything not
listed there is unmarked, which is not a promise of safety** — treat unmarked
DataModel writes as serial-only regardless.

---

## Deciding whether it is worth it

Parallel Luau costs: a rigid folder structure, no shared upvalues, message
plumbing instead of function calls, and a class of bug that only appears under
load. Take that trade when the profile says the work is CPU-bound and
parallelisable, and not before.

Cheaper things to try first:

1. **Do less work.** Spatial partitioning beats parallelising a brute-force loop.
2. **Spread it across frames.** `RunService:BindToSimulation` with
   `Enum.StepFrequency.Hz10` turns a per-frame cost into a tenth of one, with no
   Actors involved.
3. **Cache.** Recomputing something that did not change is the most common
   "needs parallelism" that does not.

Then measure with the MicroProfiler and `Stats` — `SceneDrawcallCount` and
`SceneTriangleCount` for render cost, `MovingPrimitivesCount` and
`ContactsCount` for physics. If the bottleneck is any of those, Actors will not
help: none of that work is Luau.

---

## Checklist

- [ ] Profiled first, and the bottleneck is Luau CPU.
- [ ] Scripts are descendants of an `Actor`; `script:GetActor()` is asserted.
- [ ] A bounded worker pool, not one Actor per work item.
- [ ] No expectation of a return value from `SendMessage`.
- [ ] `task.synchronize()` once before writes, not per write.
- [ ] References re-validated after `task.synchronize()`.
- [ ] Shared counters use `SharedTable.increment` / `.update`, never read-then-write.
- [ ] `SharedTable` holds no Instances, functions or metatables.
- [ ] Reads checked against `verified/parallel-safety.md` for `Unsafe` members.
