# Pathfinding, in full

Facts here are from Roblox's pathfinding guide and the Humanoid reference,
and every API name is checked against the vendored dump.

## Agent parameters

| Parameter | Default | Meaning |
|---|---|---|
| `AgentRadius` | 2 | clearance from walls, in studs |
| `AgentHeight` | 5 | spaces lower than this are not walkable |
| `AgentCanJump` | true | jump waypoints allowed |
| `AgentCanClimb` | false | `TrussPart` climbing allowed; climb waypoints are labelled `Climb` |
| `WaypointSpacing` | 4 | studs between intermediate waypoints; `math.huge` for as few as possible |
| `Costs` | none | per material (`Water`) or per label; `math.huge` forbids |

Costs keys are `Enum.Material` names as strings, or the `Label` of a
`PathfindingModifier` or `PathfindingLink`. A modifier's part should be
anchored and not collide. `PassThrough = true` on a modifier makes its
volume walkable (a door NPCs open).

## Why paths fail

- The straight-line distance is over 3,000 studs.
- The search ran out of nodes (about 20,000) in a large or maze-like area.
- The parameters cannot work: the goal is only reachable by jumping and
  `AgentCanJump` is false, or `AgentHeight` is taller than every gap.
- Waypoints with a Y coordinate below -65,536 or above 65,536 are ignored.

`Path.Status` after `ComputeAsync` says which kind of failure: `Success`,
`NoPath`, or a partial result.

## A follower

A server-side follower for one Humanoid NPC. It walks waypoints one at a
time, jumps where the path says, recomputes when a waypoint ahead is
blocked, and cleans up after itself.

```lua
local PathfindingService = game:GetService("PathfindingService")

local Follower = {}
Follower.__index = Follower

function Follower.new(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	rootPart:SetNetworkOwner(nil)
	local self = setmetatable({
		humanoid = humanoid,
		rootPart = rootPart,
		path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true }),
		waypoints = {},
		index = 0,
		goal = nil :: Vector3?,
		connections = {},
	}, Follower)

	table.insert(self.connections, humanoid.MoveToFinished:Connect(function(reached)
		if reached then
			self:step()
		elseif self.goal then
			self:moveTo(self.goal)
		end
	end))
	table.insert(self.connections, self.path.Blocked:Connect(function(blockedIndex)
		if blockedIndex >= self.index and self.goal then
			self:moveTo(self.goal)
		end
	end))
	table.insert(self.connections, humanoid.Died:Connect(function()
		self:destroy()
	end))
	return self
end

function Follower:moveTo(goal: Vector3): boolean
	self.goal = goal
	local ok = pcall(self.path.ComputeAsync, self.path, self.rootPart.Position, goal)
	if not ok or self.path.Status ~= Enum.PathStatus.Success then
		self.goal = nil
		return false
	end
	self.waypoints = self.path:GetWaypoints()
	-- Waypoint 1 is where the NPC already stands.
	self.index = 1
	self:step()
	return true
end

function Follower:step()
	self.index += 1
	local waypoint = self.waypoints[self.index]
	if not waypoint then
		self.goal = nil
		return
	end
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
	self.humanoid:MoveTo(waypoint.Position)
end

function Follower:destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.goal = nil
end

return Follower
```

Three details that are easy to get wrong:

- **`MoveToFinished(false)` after 8 seconds.** Here it recomputes from where
  the NPC is. A stuck NPC then retries every 8 seconds; count the retries and
  give up (pick another target) after a few.
- **Blocked behind is not blocked.** The check `blockedIndex >= self.index`
  ignores a path blocked somewhere the NPC has already passed.
- **Moving targets.** Chasing a player means recomputing as they move, but
  not every frame: only when the target has moved several studs since the
  last path, and no more often than every half second.

## Links and special traversal

A `PathfindingLink` joins two attachments across a gap the navigation mesh
cannot cross (a boat, a ladder, a teleporter). Its waypoint carries the
link's `Label`; the follower checks the label and runs the custom movement
for it instead of `MoveTo`.

## Streaming

With StreamingEnabled, the server still has the whole world, so server-side
NPCs path normally. A client-side path can fail because the destination has
not streamed in; keep NPC pathing on the server.
