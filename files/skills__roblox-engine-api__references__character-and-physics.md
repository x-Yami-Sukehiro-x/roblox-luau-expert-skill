# Character lifecycle, Humanoid, animation, movers

The character is the most lifecycle-hostile object in Roblox. It is created
after the player joins, destroyed and recreated on every death, and may be
absent at any moment. Most character bugs are lifecycle bugs.

---

## The join / spawn sequence

<!-- lint: fragment -->
```lua
Players.PlayerAdded         -- player exists; Character is usually nil
  player.CharacterAdded     -- model exists; children still replicating
    character.Humanoid      -- may need WaitForChild
    Humanoid.Died
  player.CharacterRemoving  -- before the old model is destroyed
Players.PlayerRemoving      -- player leaving; Player object is NOT destroyed
```

The both-orders pattern is mandatory, because your script may load before or
after the event fired:

```lua
local function onCharacter(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    if not (humanoid and root) then return end
    -- safe from here
end

local function onPlayer(player: Player)
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        onCharacter(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
    onPlayer(player)
end
```

`player.CharacterAppearanceLoaded` fires later than `CharacterAdded` — use it
when you need accessories and body parts to be present.

**`Player.Character` can be nil at any time**, including mid-function after a
yield. Never cache it across a yield without re-reading.

**Player objects are not destroyed when a player leaves.** Their connections
survive, and so does everything those closures captured. This is the
single largest source of Roblox memory leaks. Disconnect on `PlayerRemoving`.

`player.Parent == nil` is the canonical "has left" test after a yield.

---

## Humanoid

<!-- lint: fragment -->
```lua
humanoid.Health, humanoid.MaxHealth
humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight
humanoid.UseJumpPower                 -- picks which of the two applies
humanoid.HipHeight, humanoid.AutoRotate
humanoid.PlatformStand                -- disables movement, keeps physics
humanoid.RigType                      -- R6 or R15

humanoid:TakeDamage(amount)           -- respects ForceField; prefer over Health -=
humanoid:MoveTo(position, part?)
humanoid:ApplyDescription(description)
humanoid:GetState() / :ChangeState(state) / :SetStateEnabled(state, enabled)
humanoid:EquipTool(tool) / :UnequipTools()

humanoid.Died
humanoid.StateChanged(old, new)
humanoid.Seated(active, seat)
humanoid.Touched(part, limb)
```

**`TakeDamage` respects `ForceField`; `Health -= n` does not.** Use
`TakeDamage` for damage, direct assignment only for healing and initialization.

**`Died` can fire more than once** in edge cases, and fires again on the next
character. Guard with a per-character flag, not a per-player one.

**`MoveTo` times out after 8 seconds** and fires `MoveToFinished(reached)` with
`reached = false`. For pathing longer than that, re-issue it, or use
`PathfindingService` and walk the waypoints.

**Setting `WalkSpeed` on the client does not replicate.** The server keeps its
own value. A client can still move fast locally because it owns its character's
physics — that is why speed changes need server validation, not client trust.
See `roblox-game-security`.

### Humanoid states

`SetStateEnabled` is how you disable behaviour cleanly:

```lua
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)   -- no jumping
humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
humanoid:ChangeState(Enum.HumanoidStateType.Physics)              -- ragdoll-ish
```

`Enum.HumanoidStateType.Physics` hands control to the solver — the basis of most
ragdoll implementations, combined with disabling the Motor6Ds and adding
`BallSocketConstraint`s.

---

## Animation

```lua
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then return end

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://1234567"

local track = animator:LoadAnimation(animation)
track.Priority = Enum.AnimationPriority.Action
track.Looped = false
track:Play(0.1)                       -- fade-in time
track:AdjustSpeed(1.5)
track:GetMarkerReachedSignal("Hit"):Connect(onHit)
track.Stopped:Wait()
track:Stop(0.2)
```

**Load through `Animator`, not `Humanoid`.** `Humanoid:LoadAnimation` is the
legacy path. `Animator` is also what works for non-Humanoid rigs
(`AnimationController`).

**Load each animation once and reuse the track.** `LoadAnimation` in a loop
leaks tracks and stutters. Cache by animation id at character setup.

**Animations must be owned by the game or the uploader** or they will not play
in a live server. This is the usual cause of "works in Studio, silent in game".

**Priority decides what wins.** `Core` < `Idle` < `Movement` < `Action` <
`Action2..4`. An attack animation at `Movement` priority will be stomped by
walking.

**Animation markers** (`GetMarkerReachedSignal`) are how you sync a hitbox to a
swing without a hardcoded `task.wait`. Set them in the animation editor.

Tracks are per-Animator. On respawn the old tracks die with the character —
re-load against the new Animator.

---

## Movers: constraints, not BodyMovers

Every `Body*` object is deprecated. The replacements are constraints, which need
an `Attachment`:

| Deprecated | Replacement | Does |
|---|---|---|
| `BodyVelocity` | `LinearVelocity` | drive to a target velocity |
| `BodyAngularVelocity` | `AngularVelocity` | drive to a target spin |
| `BodyPosition` | `AlignPosition` | move toward a position |
| `BodyGyro` | `AlignOrientation` | rotate toward an orientation |
| `BodyForce` | `VectorForce` | constant force |
| `BodyThrust` | `VectorForce` | force at an offset |
| `RocketPropulsion` | `LinearVelocity` + `AlignOrientation` | |

```lua
local attachment = Instance.new("Attachment")
attachment.Parent = part

local push = Instance.new("LinearVelocity")
push.Attachment0 = attachment
push.RelativeTo = Enum.ActuatorRelativeTo.World
push.VectorVelocity = Vector3.new(0, 50, 0)
push.MaxForce = math.huge
push.Parent = part

task.delay(0.5, function()
    push:Destroy()
    attachment:Destroy()
end)
```

**Destroy movers when done.** A forgotten `LinearVelocity` keeps applying force
forever, and is a classic "why is this part slowly drifting" bug.

`AlignPosition` and `AlignOrientation` both have a `Mode` (`OneAttachment` /
`TwoAttachment`) and `RigidityEnabled`. Rigid mode snaps instantly and ignores
`MaxForce`/`Responsiveness`; non-rigid springs toward the goal.

---

## Network ownership

The client that owns an assembly simulates it and replicates the result upward.
This is why a client can move its own character faster than the server told it
to, and why an unowned part cannot be pushed from the client.

```lua
part:SetNetworkOwner(player)     -- give simulation to that client
part:SetNetworkOwner(nil)        -- server simulates it
part:GetNetworkOwner()           -- may error on anchored parts
part:GetNetworkOwnershipAuto()
part:SetNetworkOwnershipAuto()
```

Rules that matter:

- **Anchored parts have no network owner.** Calling `SetNetworkOwner` on one
  errors. Guard with `part:IsGrounded()` or a `pcall`.
- **A character is owned by its player** by default. That ownership is why
  client-side movement feels responsive and why movement cheats are possible.
- **Give ownership deliberately for responsiveness** — a projectile the shooter
  owns feels instant to them. Take it back (`nil`) for anything that must be
  authoritative.
- Ownership changes automatically based on proximity unless you pin it.

Full replication behaviour: `roblox-networking/references/replication-model.md`.

---

## Collision groups

```lua
local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:RegisterCollisionGroup("Debris")
PhysicsService:CollisionGroupSetCollidable("Players", "Debris", false)

part.CollisionGroup = "Debris"
```

Groups are registered at runtime but are usually better configured in Studio's
Collision Groups editor so they persist in the place file. Setting
`CollisionGroup` on a part whose group was never registered errors.

For "players pass through each other", set the character's parts to a group that
does not collide with itself — apply it on `CharacterAdded` to every
`BasePart` descendant, and again on `DescendantAdded` for accessories that
arrive late.

---

## Tools

```lua
tool.Equipped:Connect(function(mouse) end)     -- mouse is nil on the server
tool.Unequipped:Connect(function() end)
tool.Activated:Connect(function() end)         -- fires on both sides
tool.RequiresHandle = false                    -- for tools with no Handle part
```

`Activated` fires on the server too, which makes it a legitimate authority point
— but the *client* decides when to activate, so rate-limit and validate exactly
as you would a remote.

A tool moved to `Backpack` is unequipped; moved to the character it is equipped.
`Tool.Parent` is the state.
