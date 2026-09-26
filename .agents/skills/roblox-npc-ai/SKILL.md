---
name: roblox-npc-ai
description: NPCs and enemy AI - pathfinding, MoveTo timeouts, state machines, sight checks, many NPCs cheaply. Use for mobs, chase, patrol.
---

# NPCs and enemy AI

An NPC is three separate jobs, and most broken NPCs mix them:

- **Decide** what to do: patrol, chase, attack, return. A state machine.
- **Path**: how to get there around walls. `PathfindingService`.
- **Move**: walk the path. `Humanoid:MoveTo`, or movers for non-humanoids.

Keep them apart. The state machine picks a target, the pathfinder turns it
into waypoints, the mover walks them. Then each can be fixed alone.

## The server owns NPCs

AI decisions, health and damage run on the server. So does movement, with
one step people miss: an unanchored NPC near a player can have its physics
handed to that player's client, which then decides where it is. Call
`rootPart:SetNetworkOwner(nil)` once the NPC is parented under Workspace and
unanchored (the call errors on an anchored part or one outside Workspace),
so the server keeps it. Clients only draw.

## Paths

```lua
local PathfindingService = game:GetService("PathfindingService")

local path = PathfindingService:CreatePath({
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	Costs = { Water = 20, DangerZone = math.huge },
})

local ok = pcall(path.ComputeAsync, path, rootPart.Position, goal)
if ok and path.Status == Enum.PathStatus.Success then
	local waypoints = path:GetWaypoints()
end
```

What the engine does not do for you, each covered in
[pathfinding.md](references/pathfinding.md) with a complete follower:

- **`ComputeAsync` yields and can fail.** It is a boundary: `pcall`, check
  `Status`, and have a plan for no path (wait, pick another target).
- **`MoveTo` gives up after 8 seconds** if the goal is not reached, firing
  `MoveToFinished(false)`. Walk one waypoint at a time and handle `false`.
- **Paths get blocked.** Listen to `Path.Blocked` and recompute only when the
  blocked waypoint is ahead of the NPC.
- **Jump waypoints** have `Action` `Jump`; the follower makes the Humanoid
  jump there with `ChangeState(Enum.HumanoidStateType.Jumping)`.
- **Limits**: 3,000 studs straight-line distance, about 20,000 search nodes.
  Long trips are split into legs.

Studio's **Visualization Options** show the navigation mesh, modifiers and
links; turn them on before tuning `AgentRadius`.

## Deciding

A state machine with a handful of states (Idle, Patrol, Chase, Attack,
Return) covers most NPCs. Each state decides its own exit; nothing checks
`state == "Chase"` from outside. Perception is cheap first, precise second:
`WorldRoot:GetPartBoundsInRadius` for who is near, then a `Raycast` for line
of sight to the few that are.
[behaviour.md](references/behaviour.md) has the state machine and the
perception code.

## Many NPCs

One scheduler for all NPCs, not a loop per NPC; thinking at 5 to 10 times a
second, spread across frames; paths computed on a change, not per frame;
NPCs far from every player slowed or parked; a hard cap on live NPCs.
[scale.md](references/scale.md) has the scheduler and the numbers.

## Common mistakes

- Computing a path every frame, or every NPC every frame.
- `MoveTo` straight at a far target with no pathfinding: it walks into walls.
- Leaving network ownership automatic, so the NPC stutters as it changes
  hands and an exploiter can move it.
- Keeping behaviour running after death; stop everything on `Died` and
  destroy the behaviour with the model.
- Trusting a client that says "I hit the NPC": damage is decided on the
  server (`roblox-combat`).

## Works with

- `roblox-engine-api`: Humanoid states, movers, spatial queries and raycasts.
- `roblox-combat`: server-side hit validation and damage for NPC attacks.
- `roblox-networking`: network ownership and what replicates to clients.
- `roblox-performance`: profiling AI cost with the MicroProfiler.
- `roblox-vfx-animation`: animation tracks for walking and attacking.
- `roblox-game-design`: wave pacing, difficulty and rewards.
