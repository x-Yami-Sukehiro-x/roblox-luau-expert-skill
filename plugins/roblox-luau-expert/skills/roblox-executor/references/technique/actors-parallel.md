# Actors & Parallel Luau (executor)

Roblox `Actor` instances host **separate Luau VMs**. Code inside an Actor has its own globals, its own registry, and its own garbage-collected set. Anti-cheat authors use this deliberately: a check placed inside an Actor is invisible to hooks installed in the main client VM, and your `getgenv()` is invisible to it.

If a game's anti-cheat "cannot be found" by `getgc` / `filtergc` / `getconnections` from the main VM, an Actor is the first place to look.

---

## API

*Verified on Potassium. Names vary between executors and several builds implement none of these — feature-detect every one.*

```lua
getactors(): {Actor}
```
All Actors that currently exist in the game.

```lua
getactorthreads(): {thread}
```
All threads belonging to Actors.

```lua
run_on_actor(actor: Actor, source: string, ...: any)
```
Runs a script **inside** that Actor's VM. Note the second parameter is a **source string, not a closure** — you cannot pass a function across the VM boundary.

```lua
run_on_thread(thread: thread, source: string, ...: any)
```
Runs source on a specific thread. Actor threads only.

```lua
is_parallel(): boolean
```
Whether the calling thread is running on an Actor.

```lua
create_comm_channel(): (number, BindableEvent)
get_comm_channel(id: number): BindableEvent
```
Creates / retrieves a communication channel. `create_comm_channel` returns the channel's numeric id **and** the `BindableEvent` itself.

---

## Why the comm channel is mandatory

Each VM has an independent global environment. This does **not** work:

```lua
-- main VM
getgenv().results = {}
run_on_actor(actor, [[ getgenv().results[#getgenv().results+1] = "hi" ]])
-- main VM's getgenv().results is still empty — different VM, different table
```

Values must be marshalled through a `BindableEvent`, which the engine bridges across VMs. Only replicable Luau values survive the crossing — strings, numbers, booleans, tables of those, and Instances. Functions and threads do not.

### Handshake pattern

```lua
if typeof(getactors) ~= "function" or typeof(run_on_actor) ~= "function" then
    return warn("Actor injection unsupported on this executor")
end

local id, channel = create_comm_channel()

channel.Event:Connect(function(tag, payload)
    print("[actor]", tag, payload)
end)

-- The id is interpolated into the source string; the Actor re-acquires the
-- same BindableEvent by id on its own side.
local source = ([[
    local channel = get_comm_channel(%d)

    -- runs inside the Actor's VM: its own getgenv, its own gc set
    for _, script in getrunningscripts() do
        channel:Fire("script", script:GetFullName())
    end
]]):format(id)

for _, actor in getactors() do
    pcall(run_on_actor, actor, source)
end
```

Points that trip people up:

- **The id must be baked into the source string.** Upvalues do not cross; string interpolation is the transport.
- **`pcall` every `run_on_actor` call.** Actors get destroyed mid-iteration and a dead Actor throws.
- The Actor's code sees **that VM's** `getrunningscripts`, `getgc`, `getconnections`. That is the entire point — from the main VM those return a different set.
- Errors inside the Actor do not surface in the main VM's output. Wrap the injected body in its own `pcall` and `Fire` the error back over the channel, or you will debug blind.

---

## Finding anti-cheat that lives in an Actor

```lua
-- 1. Are there Actors at all?
for i, actor in getactors() do
    print(i, actor:GetFullName())
end

-- 2. What is running inside them? (from the main VM, partial view)
for _, s in getscripts() do
    local a = s:FindFirstAncestorOfClass("Actor")
    if a then print("under actor:", s:GetFullName()) end
end

-- 3. Full view — enumerate from inside
local id, channel = create_comm_channel()
channel.Event:Connect(print)

local probe = ([[
    local ch = get_comm_channel(%d)
    local ok, err = pcall(function()
        for _, s in getrunningscripts() do ch:Fire("running", s:GetFullName()) end
        for _, m in getloadedmodules() do ch:Fire("module", m:GetFullName()) end
    end)
    if not ok then ch:Fire("error", tostring(err)) end
]]):format(id)

for _, actor in getactors() do pcall(run_on_actor, actor, probe) end
```

Once located, the same tools apply **inside** the Actor as outside: `hookmetamethod`, `getconnections` + `:Disable()`, `filtergc`, `debug.setupvalue`. They just have to be installed from code running in that VM.

---

## Limits

- **Actor code is still client-side.** Parallel execution grants no server authority whatsoever. Everything in `client-feasibility.md` still applies unchanged.
- Not every executor implements these. `getactors` without `run_on_actor` gives you detection but no injection — you can tell the user an Actor-isolated AC exists and that their executor cannot reach it.
- Parallel Luau restricts what may run in parallel contexts. Writes to the DataModel from a parallel phase are rejected by the engine; `task.synchronize()` where supported, or do the write from the main VM via the channel.
- Injecting into every Actor indiscriminately is loud. Enumerate, identify the one that matters, inject there.

---

## Feature detection template

```lua
local ActorSupport = {
    enumerate = typeof(getactors) == "function",
    inject    = typeof(run_on_actor) == "function",
    channel   = typeof(create_comm_channel) == "function",
    threads   = typeof(getactorthreads) == "function",
}

if not ActorSupport.enumerate then
    -- cannot even see Actors; say so rather than guessing
elseif not (ActorSupport.inject and ActorSupport.channel) then
    -- can detect an Actor-isolated AC, cannot reach into it
end
```

Report honestly which of the three tiers the user's executor supports rather than writing code that silently does nothing.
