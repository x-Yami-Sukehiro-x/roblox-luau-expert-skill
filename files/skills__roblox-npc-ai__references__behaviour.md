# Behaviour: states and perception

## A state machine

Each state is a table of three functions. The machine calls `think` on the
current state; a state that wants to change returns the next state's name.
Transitions live inside the states, so there is never a pile of flags
checked from outside.

```lua
local Players = game:GetService("Players")

local SIGHT = 60
local ATTACK_RANGE = 6

local function nearestTarget(npc: any): Model?
	local nearest, shortest = nil, SIGHT
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - npc.rootPart.Position).Magnitude
			if distance < shortest and npc:canSee(root) then
				nearest, shortest = character, distance
			end
		end
	end
	return nearest
end

local States = {}

States.Patrol = {
	enter = function(npc)
		npc.follower:moveTo(npc:nextPatrolPoint())
	end,
	think = function(npc)
		local target = nearestTarget(npc)
		if target then
			npc.target = target
			return "Chase"
		end
		if not npc.follower.goal then
			npc.follower:moveTo(npc:nextPatrolPoint())
		end
		return nil
	end,
	exit = function() end,
}

States.Chase = {
	enter = function() end,
	think = function(npc)
		local root = npc.target and npc.target:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - npc.rootPart.Position).Magnitude > SIGHT * 1.5 then
			npc.target = nil
			return "Patrol"
		end
		if (root.Position - npc.rootPart.Position).Magnitude <= ATTACK_RANGE then
			return "Attack"
		end
		npc:chase(root.Position)
		return nil
	end,
	exit = function() end,
}
```

The machine itself is a few lines: on `think`, if the state returns a name,
call the old state's `exit`, set the new state, call its `enter`.

Chase leaves at 1.5 times the sight range, not at the sight range: a target
standing at the edge would otherwise flip the NPC between Chase and Patrol
every tick.

## Perception, cheap first

1. **Who is near**: one `WorldRoot:GetPartBoundsInRadius` per NPC per think,
   with `OverlapParams` filtered to player characters, instead of a distance
   check against every player every frame.
2. **Who is visible**: a `Workspace:Raycast` from the NPC's head to each
   nearby target, excluding the NPC's own model. Only for the few that are
   near.

```lua
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude

local function canSee(npcModel: Model, from: Vector3, target: BasePart): boolean
	sightParams.FilterDescendantsInstances = { npcModel, target.Parent :: Instance }
	return workspace:Raycast(from, target.Position - from, sightParams) == nil
end
```

Nothing between the two means visible, which is why the target's own model
is excluded as well.

## Behaviour trees

For bosses with many prioritised moves, a behaviour tree (selectors and
sequences returning success, failure or running) scales better than a big
state machine. Keep leaves that take time (walking, an attack animation)
returning *running* until done, or the tree restarts them every tick. For
most enemies a state machine is enough.

## Groups

NPCs chasing one target share its position, take formation offsets so they
do not stack on one point, and recompute on staggered ticks so eight paths
are not computed in the same frame.
