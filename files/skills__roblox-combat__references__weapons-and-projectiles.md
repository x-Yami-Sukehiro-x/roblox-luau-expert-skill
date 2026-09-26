# Weapons and projectiles

## Cooldowns and combat state

Keep per-player combat state on the server in one table, keyed by the
character for things that end with a life (stuns, buffs, a channelled
ability) and by the player for things that survive death (cooldowns
between lives, if the design wants that):

```lua
local combatState: { [Model]: { stunnedUntil: number, blocking: boolean } } = {}
```

Clear character-keyed state on `CharacterRemoving` or `Humanoid.Died`, or a
buff outlives its body. Buffer at most one queued input per player: a queue
deeper than one becomes a macro that fires faster than a human can.

## Projectiles

A slow projectile (an arrow, a fireball) is simulated on the server in one
loop for all of them. Each step casts a ray over the distance travelled, so
a fast projectile cannot pass through a thin wall between frames.

```lua
local RunService = game:GetService("RunService")

local GRAVITY = Vector3.new(0, -workspace.Gravity * 0.2, 0)
local LIFETIME = 4

local live = {}
local stepParams = RaycastParams.new()
stepParams.FilterType = Enum.RaycastFilterType.Exclude

local stepper = RunService.Heartbeat:Connect(function(deltaTime)
	local now = os.clock()
	for index = #live, 1, -1 do
		local shot = live[index]
		local travel = shot.velocity * deltaTime
		stepParams.FilterDescendantsInstances = { shot.owner }
		local hit = workspace:Raycast(shot.position, travel, stepParams)
		if hit or now - shot.fired > LIFETIME then
			table.remove(live, index)
			if hit then
				shot.onHit(hit)
			end
		else
			shot.position += travel
			shot.velocity += GRAVITY * deltaTime
		end
	end
end)
```

The server holds positions only; no part moves on the server. Clients get
one message per shot (origin, velocity, id) and animate their own copy.

## Pooling

Instances created and destroyed per shot are the second cost. Keep a pool
of visual parts on each client; take one, reset every property the last use
changed (transparency, colour, size), use it, return it. A pooled part that
comes back still invisible from its last use is the classic pooling bug.

## Which remote

| Message | Remote |
|---|---|
| "I fired", "I swung" | RemoteEvent (reliable: the server must hear it) |
| Damage results, deaths | RemoteEvent |
| Tracers, sparks, shell casings | UnreliableRemoteEvent: a lost one costs nothing |
