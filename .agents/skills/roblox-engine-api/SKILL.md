---
name: roblox-engine-api
description: Roblox engine APIs and their lifecycles — Instance creation, parenting and destruction, FindFirstChild vs WaitForChild, attributes and CollectionService tags, the RunService frame pipeline, raycasting and spatial queries, physics constraints and movers, CFrame math, Humanoid and character lifecycle, animation, TweenService, sound, camera, StreamingEnabled, TextChatService, and input handling. Use for "attempt to index nil", raycast questions, character spawning, tweens, camera control, or any question about how a specific Roblox service behaves.
---

# Roblox engine APIs

Every entry here is verified against the vendored dump. When you need a
signature you do not have, run `node tools/bin/verify-api.mjs <Name>` rather than
recalling it.

| Topic | File |
|---|---|
| `attempt to index nil`, `WaitForChild` hangs | `references/nil-safety.md` |
| raycast, shapecast, spatial queries, CFrame | `references/spatial-and-cframe.md` |
| character spawn, Humanoid, animation, movers | `references/character-and-physics.md` |

---

## Instance lifecycle

```lua
local part = Instance.new("Part")
part.Size = Vector3.new(4, 1, 8)
part.Anchored = true
part.Parent = workspace          -- parent LAST
```

**Parent last.** Setting `Parent` makes the instance live: it starts
replicating, physics starts simulating it, and `ChildAdded` handlers fire.
Setting every other property first means one replication event instead of six,
and no observer ever sees a half-configured object.

`Instance.new("Part", workspace)` — the two-argument form — does the opposite
and is slower. Do not use it.

### Destruction

```lua
part:Destroy()
myTable[key] = nil     -- your reference, your job
```

`Destroy` sets `Parent = nil`, locks the instance so it cannot be re-parented,
disconnects the instance's own signal connections, and destroys descendants. It
does **not** clear references you hold. An instance in your table is an instance
that cannot be collected — see `roblox-luau-expert/references/common-mistakes.md`
entry 11.

`part.Parent = nil` is not `Destroy`. It removes the instance from the tree but
leaves it fully alive, still connected, still resurrectable. Occasionally what
you want (object pooling); usually a leak.

### Finding things

| Call | Returns | Use when |
|---|---|---|
| `FindFirstChild(name, recursive?)` | `Instance?` | it may not be there |
| `FindFirstChildOfClass(class)` | typed `?` | you want a Humanoid, any name |
| `FindFirstChildWhichIsA(class, recursive?)` | typed `?` | subclasses count |
| `FindFirstAncestorOfClass(class)` | typed `?` | walking up from a part |
| `WaitForChild(name, timeout?)` | `Instance` | it arrives eventually |
| `GetChildren()` | `{ Instance }` | **allocates every call** |
| `GetDescendants()` | `{ Instance }` | allocates, and can be very large |

**`WaitForChild` always takes a timeout in code you hand over.** Without one it
yields forever on a typo — a silent failure with nothing to grep for. Roblox
prints "Infinite yield possible" after 5 s, but that is a line in a noisy output
window, not an error.

```lua
local humanoid = character:WaitForChild("Humanoid", 10)
if not humanoid then
    warn("[combat] Humanoid never appeared on " .. character:GetFullName())
    return
end
```

**`GetChildren()` in a per-frame loop is an allocation per frame.** Cache it and
maintain the cache with `ChildAdded`/`ChildRemoved`, or use tags.

---

## Attributes and tags — the modern way to annotate instances

**Attributes** replicate, survive `Clone`, show in Studio, and fire a change
signal. They replaced child `Value` objects for almost every use.

```lua
part:SetAttribute("Damage", 25)
local damage = part:GetAttribute("Damage")     -- typed `any` — narrow it
if typeof(damage) ~= "number" then return end

part:GetAttributeChangedSignal("Damage"):Connect(function() ... end)
for name, value in part:GetAttributes() do end
```

Attributes accept a fixed set of types (numbers, strings, booleans, `Vector3`,
`CFrame`, `Color3`, `UDim`/`UDim2`, `BrickColor`, `NumberRange`, `Rect`, `font`,
and a few more). **They cannot hold an Instance reference or a table.** Names
cannot start with `RBX`.

**`CollectionService` tags** are for set membership, and give you reactivity for
free:

```lua
local CollectionService = game:GetService("CollectionService")

CollectionService:AddTag(part, "Damaging")

for _, tagged in CollectionService:GetTagged("Damaging") do
    setup(tagged)
end
CollectionService:GetInstanceAddedSignal("Damaging"):Connect(setup)
CollectionService:GetInstanceRemovedSignal("Damaging"):Connect(teardown)
```

This is the right shape for "every part with this behaviour", and it decouples
the code from the tree layout — a builder can move things without breaking
scripts. Tags are set in Studio's Tag Editor, so designers can wire behaviour
without touching code.

---

## The frame pipeline

Verified event names and their order within a frame on the client:

| Event | Fires | Signature |
|---|---|---|
| `RunService.PreRender` | before rendering, after input | `(deltaTimeRender)` |
| `RunService.PreAnimation` | before animations evaluate | `(deltaTimeSim)` |
| `RunService.PreSimulation` | before physics steps | `(deltaTimeSim)` |
| `RunService.PostSimulation` | after physics steps | `(deltaTimeSim)` |

Three pairs are **two names for one point in the frame**, not five separate events:

| Modern name | Older name |
|---|---|
| `RunService.PreSimulation` | `RunService.Stepped` |
| `RunService.PreRender` | `RunService.RenderStepped` |
| `RunService.PostSimulation` | `RunService.Heartbeat` |

The older names still exist and are **not deprecated** — none of the three carries a
`[Deprecated]` flag in the dump. Prefer the modern names in new code, do not flag the
old ones as defects, and do not connect both halves of a pair expecting them to fire at
different moments.

`PreRender` and `RenderStepped` are **client only** — connecting them on the
server errors.

For camera work use `RunService:BindToRenderStep(name, priority, fn)` rather
than a raw `PreRender` connection: it lets you order against
`Enum.RenderPriority.Camera.Value` deterministically, and `UnbindFromRenderStep`
gives you a clean teardown by name.

```lua
RunService:BindToRenderStep("CameraFollow", Enum.RenderPriority.Camera.Value + 1, function(dt)
    ...
end)
-- later
RunService:UnbindFromRenderStep("CameraFollow")
```

### Throttled binding

`BindToSimulation(fn, frequency, priority)` and `BindToAnimation(...)` accept an
`Enum.StepFrequency` (`Hz60`, `Hz30`, `Hz15`, `Hz10`, `Hz5`, `Hz1`) and return a
connection. For logic that does not need 60 Hz — AI ticks, proximity checks,
regeneration — this is cheaper and simpler than hand-rolled accumulators.

### Client prediction

The engine exposes a prediction/rollback surface:
`RunService:SetPredictionMode(context, Enum.PredictionMode)` with `Automatic`,
`On`, `Off`; `GetPredictionStatus(context)` returning `Authoritative`,
`Predicted` or `None`; `IsResimulating()`; and the `Rollback` and `Misprediction`
events. Relevant when building responsive movement or abilities under
server-authoritative physics. Verify each signature before use — this surface is
newer than most documentation.

### Context detection

```lua
if RunService:IsServer() then end
if RunService:IsClient() then end
if RunService:IsStudio() then end
```

`IsEdit()`, `Run()`, `Pause()` and `Stop()` are **Plugin-security** and
unavailable at runtime in a published game. `IsRunMode()` is **not** — the dump
marks it `{Basic} {Safe}` with no Plugin gate, so a normal script may call it.
It reports whether the simulation is running, which is different from
`IsStudio()` (are we in Studio at all) and from `IsClient()`/`IsServer()`.

---

## TweenService

```lua
local TweenService = game:GetService("TweenService")

local info = TweenInfo.new(
    0.4,                              -- duration
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out,
    0,                                -- repeat count (-1 = forever)
    false,                            -- reverses
    0                                 -- delay
)

local tween = TweenService:Create(frame, info, { Position = UDim2.fromScale(0.5, 0.5) })
tween:Play()
tween.Completed:Wait()
```

Traps worth knowing:

- **A tween holds a reference to its target.** Cancel or let it complete before
  destroying the instance, or track it in a Trove.
- **Two tweens on the same property fight.** The second does not cancel the
  first; both keep writing. Cancel explicitly.
- **Tweening a physics part's `CFrame` fights the solver.** Anchor it, or use a
  constraint instead.
- `TweenInfo` is immutable — build a new one to change anything.
- Tweens do not replicate. A server tween on an unanchored part replicates via
  physics; a server tween on a GUI does nothing for clients.

---

## Sound

```lua
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://1234567"
sound.RollOffMaxDistance = 100
sound.Parent = part          -- parented to a BasePart = positional 3D audio
sound:Play()
sound.Ended:Once(function() sound:Destroy() end)
```

Parent decides behaviour: under a `BasePart` or `Attachment` it is 3D
positional; under `SoundService` or a GUI it is 2D. `PlayOnRemove` fires a sound
when the instance is destroyed, which is the classic way to play a one-shot
without leaking the instance.

Preload with `ContentProvider:PreloadAsync` before a moment that must not
stutter — see `roblox-performance`.

---

## Camera

```lua
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable    -- required before manual control
camera.CFrame = CFrame.lookAt(position, target)
```

`CurrentCamera` is client-only and can be replaced on respawn — re-read it
rather than caching across a character reset. Manual camera work belongs in
`BindToRenderStep` at `Enum.RenderPriority.Camera.Value`, not in `Heartbeat`,
or the camera lags the render by a frame.

---

## StreamingEnabled

With `Workspace.StreamingEnabled` on, the client receives only nearby parts.
Consequences that break naive code:

- `workspace.Map.Door` may be nil on the client even though it exists on the
  server. Use `WaitForChild` with a timeout, and handle the nil case as normal
  operation rather than an error.
- Instances can be **removed** from the client and re-added later. A cached
  reference goes stale; `instance.Parent == nil` does not mean destroyed.
- `Player:RequestStreamAroundAsync(position)` asks for a region before a
  teleport so the player does not land in the void.
- Model `ModelStreamingMode` (`Atomic`, `Persistent`, `PersistentPerPlayer`)
  controls what is exempt. Anything a client script must always see should be
  `Persistent`.

Server code is unaffected — the server always has the full DataModel.

---

## TextChatService

Legacy chat is gone; `TextChatService` is the only chat system.

```lua
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
    local overrides = Instance.new("TextChatMessageProperties")
    if message.TextSource then
        local player = Players:GetPlayerByUserId(message.TextSource.UserId)
        if player and player:GetAttribute("Vip") then
            overrides.PrefixText = "<font color='#ffd700'>[VIP]</font> " .. message.PrefixText
        end
    end
    return overrides
end
```

Send from a client with `TextChannel:SendAsync(text)`. Custom commands are
`TextChatCommand` instances. Server-side display messages go through
`TextChannel:DisplaySystemMessage(text)`.

Anything a player typed must go through `TextService:FilterStringAsync` before
being shown to anyone else — this is a platform requirement, not a suggestion.

---

## Input

```lua
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- Simple, global
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end          -- typing in a TextBox
    if input.KeyCode == Enum.KeyCode.E then interact() end
end)

-- Contextual, cross-device, unbindable
ContextActionService:BindAction("Interact", handler, true, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("Interact", "Use")
-- later
ContextActionService:UnbindAction("Interact")
```

`ContextActionService` is the better default for gameplay actions: one binding
covers keyboard, gamepad and a touch button (`createTouchButton = true`), and
unbinding is a named operation rather than tracking connections.

**Always check `gameProcessed`** in `UserInputService` handlers or your hotkeys
fire while the player types in chat.

Device detection: `UserInputService.TouchEnabled`,
`.KeyboardEnabled`, `.GamepadEnabled`, and `.LastInputType` /
`.LastInputTypeChanged` for adapting UI live. Do not assume touch means phone —
many desktops report `TouchEnabled`.

---

## Services you should reach for by name

```lua
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerStorage      = game:GetService("ServerStorage")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local CollectionService  = game:GetService("CollectionService")
local UserInputService   = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TextChatService    = game:GetService("TextChatService")
local HttpService        = game:GetService("HttpService")
local DataStoreService   = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService    = game:GetService("TeleportService")
local PhysicsService     = game:GetService("PhysicsService")
local ContentProvider    = game:GetService("ContentProvider")
```

Always `game:GetService("X")`, never `game.X`. The service may not exist yet at
script start, and `GetService` creates it; dot access errors.

`workspace` is the one exception — it is a global and always present.
