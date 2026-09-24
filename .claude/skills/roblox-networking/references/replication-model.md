# Replication model — what crosses the wire

The engine's replication rules, stated precisely. This is the reference behind
every "it only works on my screen" and "why did my change get reset" answer.

The mirror-image reference written for client-side scripting is
`roblox-executor/references/technique/replication-exploitation.md` — same
mechanics, opposite goal.

---

## Client to server

| Channel | Carries |
|---|---|
| Physics for owned assemblies | CFrame + velocity, ~20 Hz, unreliable and unordered |
| Character position + Motor6D transforms | a special case of the above |
| `RemoteEvent` / `RemoteFunction` calls | whatever you send |
| `UnreliableRemoteEvent` | whatever you send, may be dropped or reordered |

**Nothing else.** No property write, no instance creation, no reparenting, no
attribute, no tag. A client can construct an elaborate world for itself and the
server will never know.

The corollary developers must internalise: **anything a client "has" that the
server did not grant does not exist.** Inventory, currency and progression read
from client state is a duplication bug waiting to be found.

## Server to client

The server replicates automatically:

- instance creation, destruction and reparenting,
- property changes,
- attribute changes,
- `CollectionService` tags.

Subject to:

- **`StreamingEnabled`** — the client may simply not have the instance yet, or
  may have had it removed.
- **Container rules** — `ServerStorage` and `ServerScriptService` never
  replicate at all.
- **`Instance.Archivable`** — affects `Clone` and saving, not replication.

---

## Physics replication characteristics

| Property | Value |
|---|---|
| Send rate | ~20 Hz |
| Reliability | unreliable, unordered |
| Receiver behaviour | interpolates toward received state |
| Loss tolerance | high — designed to drop packets |

Consequences:

- Out-of-order arrival is normal; the receiver reconciles by timestamp.
- There is no retransmit queue, so a dropped physics packet is simply gone.
- **Last write wins within a frame.** Setting a property five times in one frame
  produces one replication with the final value. A loop that thrashes a property
  costs CPU and gains nothing on the wire.

---

## Bandwidth per value

| Payload | Bytes |
|---|---|
| Empty remote call | ~9 |
| number | 9 |
| string | length + 2 |
| Vector3 | 13 |
| CFrame, axis-aligned | 14 |
| CFrame, rotated | 20 |

Tables carry their keys as strings. `{x = 1, y = 2, z = 3}` is substantially
more expensive than the `Vector3` it represents. This is the whole argument for
`buffer` payloads on high-frequency messages.

---

## Signal behaviour: deferred events

`Workspace.SignalBehavior` (`Enum.SignalBehavior`: `Default`, `Immediate`,
`Deferred`, `AncestryDeferred`) changes **when** your handlers run.

Under `Deferred`, a signal does not invoke handlers at the moment it fires.
Handlers are queued and run at the next resumption point. What this changes in
practice:

- **Handlers no longer run before the line after `:Fire()`.** Code that relied on
  a `BindableEvent` behaving like a function call breaks.
- **State can change between fire and handle.** By the time your `ChildAdded`
  handler runs, the child may already be destroyed. Re-validate at the top of
  the handler, not just at the fire site.
- **Ordering between different signals is not guaranteed** the way it was under
  `Immediate`.

If a codebase behaves differently in a new place file than an old one, this
property is a prime suspect — it defaults differently depending on when the
place was created.

`Workspace.SignalBehavior` is `[NotScriptable]`: set it in Studio's properties
pane, not from code.

---

## Streaming

`Workspace.StreamingEnabled` is `{Plugin}`-gated **for writes** — readable from
a script, settable only in Studio or a plugin. Related settings:

- `StreamingTargetRadius`, `StreamingMinRadius` — how much the client holds.
- `Enum.StreamingIntegrityMode` — `Default`, `Disabled`, `MinimumRadiusPause`,
  `PauseOutsideLoadedArea`. Controls whether the client pauses rather than
  letting a character fall through unloaded terrain.
- `Model.ModelStreamingMode` — `Default`, `Atomic`, `Persistent`,
  `PersistentPerPlayer`, `Nonatomic`. `Atomic` streams a model all-or-nothing;
  `Persistent` never streams out.

Client code under streaming must treat absence as normal:

```lua
local door = workspace:WaitForChild("Map", 20)
    and workspace.Map:FindFirstChild("Door")
if not door then
    -- not an error: it may simply not be streamed in
    return
end
```

`Player:RequestStreamAroundAsync(position, timeout?)` asks the server to stream a
region before you teleport a player into it.

---

## Instances that do not replicate normally

- Anything parented under `ServerStorage` / `ServerScriptService`.
- Anything created on the client (stays client-only, forever).
- `Camera`, `PlayerGui` contents, and most client-local UI.
- `LocalScript`s do not run on the server; `Script`s with `RunContext = Client`
  do run on the client — check `RunContext` before assuming from the class name.

---

## Debugging replication

**Is it a replication problem at all?** Print the value on both sides at the
same moment. If the server print shows the old value, nothing crossed.

**Studio's Network tab** (`View → Network`) shows per-remote traffic and rates,
and is the fastest way to find a remote being fired 200 times a second.

**Test with two clients.** Studio's `Test → Clients and Servers` with two players
catches the entire class of "works for me" bugs. A single-player playtest does
not exercise replication at all.

**Server-side `print` in a `LocalScript` never appears.** If a print is missing,
confirm which context the script is actually in — `RunService:IsServer()` at the
top settles it in one line.

---

## Design rules that follow from all of this

1. The client sends **intent**, the server sends **outcome**. Never the reverse.
2. Anything the player can gain must be granted server-side and stored
   server-side.
3. Every remote handler validates type, range, ownership and rate before acting.
4. High-frequency, drop-tolerant data goes on `UnreliableRemoteEvent`.
5. Batch before you optimise payload size; a rate reduction beats a byte
   reduction.
6. Nothing secret goes in `ReplicatedStorage`. A client can read all of it.
