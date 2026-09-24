# RakNet / Packet Manipulation (Executor)

**Highest-risk surface in this skill.** RakNet is the UDP protocol Roblox uses for all replication. Malformed packets cause instant disconnects; sustained manipulation of replication is the most actively patched and most reliably banned exploit class on the platform.

Not part of sUNC. Availability varies sharply by executor. Feature-detect everything.

| Executor family | Surface |
|---|---|
| Velocity | Full: send + receive hooks, block/unblock, byte-patch rules, `desync`, stats |
| Volt, madium | Send hooks, `send`, `SetData`, `Block` |
| Potassium | Public docs list **no** raknet library |
| Celery (legacy) | `rnet.*` — different names entirely, see bottom |

```lua
local hasRaknet   = typeof(raknet) == "table" and typeof(raknet.add_send_hook) == "function"
local hasReceive  = hasRaknet and typeof(raknet.add_receive_hook) == "function"
local hasRules    = hasRaknet and typeof(raknet.set) == "function"
```

Read `replication-exploitation.md` first. Packet work without knowing what replicates and at what rate is guesswork.

---

## API (Velocity-class, most complete)

### Hooks

```lua
raknet.add_send_hook(callback: (packet: RakNetPacket) -> ())
raknet.remove_send_hook(callback: (packet: RakNetPacket) -> ())
raknet.add_receive_hook(callback: (packet: RakNetPacket) -> ())
raknet.remove_receive_hook()
```

Send hooks **stack** — every registered callback fires, in registration order, before the packet leaves. Receive hooks occupy a **single slot** on Velocity: registering a second one replaces the first, and `remove_receive_hook` takes no argument.

### Sending

<!-- lint: fragment -->
```lua
raknet.send(
    data: buffer | string | {number},
    priority: number?,
    reliability: number?,
    ordering_channel: number?
)
```

Injects a packet as though the client sent it. Priority/reliability values are executor-defined enums; `0` is the usual safe default when testing. Packets originated by `raknet.send` still pass through send hooks and can be modified with `:SetData` or dropped with `:Block`.

### Blocking by ID

```lua
raknet.block(packetId: number, enabled: boolean?): boolean
raknet.unblock(packetId: number)
```

Standing block rule for an entire packet ID — cheaper and more consistent than checking the ID inside a hook on every packet.

### Desync

```lua
raknet.desync(enabled: boolean): boolean
```

Suppresses outgoing physics-replication packets. See the dedicated section below before using it.

### Byte-patch rules

```lua
raknet.set(packetId: number, value: number, start: number?, stop: number?)
raknet.toggle(packetId: number, enabled: boolean)
raknet.remove(packetId: number)
```

Persistent rules that overwrite a byte range in every packet matching `packetId`. `toggle` enables/disables an existing rule without deleting it; `remove` deletes it.

### State

```lua
raknet.hooked(): boolean
raknet.stats(): table
raknet.clear()
```

`stats` returns counters and current rules. `clear` resets all rules and counters — the correct teardown call.

---

## RakNetPacket object

| Member | Type | Notes |
|---|---|---|
| `.Direction` | string | Inbound / outbound |
| `.PacketId` | number | Packet opcode. Legacy builds expose `.id` |
| `.ItemId` | number | Sub-item identifier |
| `.Priority` | number | Send priority |
| `.Reliability` | number | Reliability mode |
| `.OrderingChannel` | number | Ordering channel |
| `.Size` | number | Payload size in bytes |
| `.CapturedSize` | number | Bytes actually captured |
| `.Truncated` | boolean | Whether capture was cut short |
| `.Sequence` | number | Sequence number |
| `.Timestamp` | number | Capture timestamp |
| `.Data` | string | Raw payload |
| `.AsString` | string | Payload as string |
| `.AsBuffer` | buffer | Payload as buffer |
| `.AsArray` | {number} | Payload as byte array |
| `.Modified` | boolean | Whether a hook changed it |
| `.Blocked` | boolean | Whether it is currently dropped |
| `:SetData(data)` | — | Replace payload (buffer / string / {number}) |
| `:Block()` | — | Drop the packet. **Outgoing only** |

`CapturedSize` and `Truncated` matter: on a large packet you may be inspecting a prefix. Check `Truncated` before concluding a byte pattern is absent.

---

## Packet IDs (verified against roblox-dissector)

### Top-level

| ID | Name | Direction |
|---|---|---|
| `0x00` | ID_CONNECTED_PING | BIDI |
| `0x01` | ID_CONNECTED_PONG | BIDI |
| `0x05` | ID_OPEN_CONNECTION_REQUEST_1 | C→S |
| `0x06` | ID_OPEN_CONNECTION_REPLY_1 | S→C |
| `0x07` | ID_OPEN_CONNECTION_REQUEST_2 | C→S |
| `0x08` | ID_OPEN_CONNECTION_REPLY_2 | S→C |
| `0x09` | ID_CONNECTION_REQUEST | C→S |
| `0x10` | ID_CONNECTION_ACCEPTED | S→C |
| `0x13` | ID_NEW_INCOMING_CONNECTION | C→S |
| `0x15` | ID_DISCONNECTION_NOTIFICATION | BIDI |
| `0x81` | ID_SET_GLOBALS | S→C |
| **`0x83`** | **ID_DATA** (replication container) | BIDI |
| **`0x85`** | **ID_PHYSICS** | BIDI |
| `0x86` | ID_TOUCH | BIDI |
| `0x87` | ID_CHAT_ALL | S→C |
| `0x8A` | ID_SUBMIT_TICKET | C→S |
| `0x8D` | ID_CLUSTER | S→C |
| `0x8F` | ID_PLACEID_VERIFICATION / ID_PREFERRED_SPAWN_NAME | C→S |
| `0x90` | ID_PROTOCOL_SYNC | C→S |
| `0x93` | ID_DICTIONARY_FORMAT | S→C |
| `0x96` | ID_REQUEST_STATS | C→S |
| `0x97` | ID_NEW_SCHEMA | S→C |
| `0x98` | ID_KICK_MESSAGE | S→C |
| **`0x9B`** | **ID_LUAU_CHALLENGE** | BIDI |

### 0x83 (ID_DATA) subpackets — where replication actually lives

| ID | Name | Direction |
|---|---|---|
| `0x01` | ID_REPLIC_DELETE_INSTANCE | BIDI |
| `0x02` | ID_REPLIC_NEW_INSTANCE | BIDI |
| **`0x03`** | **ID_REPLIC_PROP** (property updates) | BIDI |
| `0x05` | ID_REPLIC_PING | BIDI |
| `0x06` | ID_REPLIC_PONG | BIDI |
| **`0x07`** | **ID_REPLIC_EVENT** (remote calls) | BIDI |
| `0x09` | ID_REPLIC_ROCKY | BIDI |
| `0x0A` | ID_REPLIC_CFRAME_ACK | C→S |
| `0x0B` | ID_REPLIC_JOIN_DATA (initial snapshot) | BIDI |
| `0x0C` | ID_REPLIC_UPDATE_CLIENT_QUOTA | C→S |
| `0x0D` | ID_REPLIC_STREAM_DATA | S→C |
| `0x0E` | ID_REPLIC_REGION_REMOVAL | S→C |
| `0x0F` | ID_REPLIC_INSTANCE_REMOVAL | S→C |
| `0x10` | ID_REPLIC_TAG | S→C |
| `0x11` | ID_REPLIC_STATS | S→C |
| `0x12` | ID_REPLIC_HASH | C→S |
| `0x13` | ID_REPLIC_ATOMIC | S→C |
| `0x14` | ID_REPLIC_STREAM_DATA_INFO | S→C |

Sub-packet payload formats inside `0x83` are complex, schema-driven (`ID_NEW_SCHEMA`, `ID_DICTIONARY_FORMAT`), and change with Roblox updates. **Treat any hard-coded byte offset as fragile** — verify it every client version.

---

## Two hard rules

**1. Never block or modify `0x9B` (ID_LUAU_CHALLENGE).**
That is the anti-cheat challenge/response channel. Failing to answer it is not a subtle heuristic — it is an unambiguous, immediate detection. Exclude it explicitly in every hook, including catch-all loggers.

**2. `0x85` (ID_PHYSICS) is 20 Hz, unreliable and unordered.**
Dropping individual physics packets looks exactly like ordinary network loss, because the protocol expects loss. *Sustained total suppression* does not look like loss and is what desync detection watches for.

---

## Examples

### Log outgoing packets

```lua
local function logger(packet)
    local id = packet.PacketId or packet.id
    if id == 0x9B then return end          -- never touch the challenge channel
    print(string.format("0x%02X", id), packet.Size, packet.Priority)
end

raknet.add_send_hook(logger)
-- teardown: raknet.remove_send_hook(logger)
```

### Block a packet ID

```lua
-- Standing rule (preferred — no per-packet Luau cost)
raknet.block(0x86, true)     -- ID_TOUCH
-- raknet.unblock(0x86)

-- Or inside a hook, when the decision depends on payload
raknet.add_send_hook(function(packet)
    if packet.Size > 512 then packet:Block() end
end)
```

### Modify a payload

```lua
raknet.add_send_hook(function(packet)
    if (packet.PacketId or packet.id) == 0x83 then
        -- only edit bytes whose meaning you have confirmed by observation
        packet:SetData(packet.AsString .. "\x00")
    end
end)
```

### Byte-patch rule

```lua
-- Overwrite bytes [start, stop] of every 0x83 packet with `value`
raknet.set(0x83, 0x00, 4, 8)
raknet.toggle(0x83, false)   -- suspend without deleting
raknet.remove(0x83)          -- delete
```

### Capture and replay

```lua
local saved
raknet.add_send_hook(function(packet)
    if (packet.PacketId or packet.id) == 0x83 and not saved then
        saved = {
            data        = packet.AsBuffer or packet.AsArray,
            priority    = packet.Priority,
            reliability = packet.Reliability,
            channel     = packet.OrderingChannel,
        }
    end
end)

-- later
if saved then
    raknet.send(saved.data, saved.priority, saved.reliability, saved.channel)
end
```

Replay is only meaningful for packets whose contents are not sequence- or timestamp-bound. `ID_REPLIC_EVENT` replays often fail because the schema carries per-call state.

---

## Desync

Breaking outbound character replication so other clients stop receiving your position while you keep receiving theirs.

### Route A — FastFlag

The `NextGenReplicator*` family (e.g. `NextGenReplicatorEnabledWrite4`), part of Roblox's NextGen / Aurora replicator — the same system behind client prediction, rollback netcode, and the Server Authority beta. Setting these client-side breaks character replication to other clients.

```lua
setfflag("SomeNextGenReplicatorFlag", "True")
```

`setfflag(name: string, value: string)` (*Synapse-lineage; executor-dependent*) **must run before Roblox loads** — auto-execute plus auto-launch. Flags set after the client is up have no effect. The equivalent outside an executor is a `ClientAppSettings.json` under a `ClientSettings` folder; Roblox now ignores flags not on its allowlist.

Flag names change between client versions. Anything hardcoded here will rot.

### Route B — packet suppression

```lua
if typeof(raknet.desync) == "function" then
    raknet.desync(true)
    -- raknet.desync(false) to restore
end
```

Or suppress outgoing physics manually (`0x85` and the physics path inside `0x83`). The dedicated `desync` call is preferable — it knows which packets the current client version actually uses.

### What desync does and does not do

**Does:** other players see a character frozen at its last replicated position. They lose their visual read on you.

**Does not:** make you invincible. You remain in sync **with the server** — the server holds your true position, so server-side hit detection still lands on you normally. Players shooting at where the server thinks you are will hit you; they just have no visual indicator of where that is.

State this limit whenever desync comes up. Users routinely expect godmode and get confused when they still take damage.

### Risk

The most-reported exploit class on the DevForum engine-bugs board, with multiple active threads and ongoing patching. Highest patch-and-ban risk of anything documented in this skill. Private servers and alts only.

---

## Legacy Celery `rnet` API

Older executors exposed a different, higher-level surface. Not standardised; prefer `raknet.*` where available.

<!-- lint: fragment -->
```lua
rnet.sendphysics(value: CFrame)   -- ask the server to place your character at `value`
rnet.startcapture()               -- show outgoing packets in the debug console
rnet.stopcapture()
rnet.setfilter(t: table)          -- block packets whose first bytes match; {} clears
rnet.sendraw(value: string | {number})  -- hex string or byte table
```

`rnet.Capture` is a signal; connect to it for custom packet logging. Handlers receive a packet object with `id` and `data` fields.

> `sendphysics` is documented as **position only** — rotation compression was never finished. Passing a rotated CFrame does not rotate the character.

Other names seen in community wrappers (`fireevent`, `fireremote`, `getevents`, `setparent`, `setproperty`, `touch`, `destroy`) were experimental, are not standardised, and should not be presented as available.

---

## Safety checklist

1. Feature-detect before every call; report honestly when the executor lacks the function.
2. Exclude `0x9B` in every hook.
3. Observe before modifying — log a session, learn which IDs the game uses and at what rate.
4. Never send a packet whose format you have not read. Wrong opcodes or lengths disconnect instantly.
5. Prefer blocking or light modification over synthesising new packets.
6. Store hook references; call `remove_send_hook` / `remove_receive_hook` / `clear` on unload.
7. Match natural rates. Anomalous cadence is caught by heuristics no matter how well-formed the packet is.
8. Private servers and alt accounts.
