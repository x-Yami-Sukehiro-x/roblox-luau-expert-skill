# Many NPCs at low cost

The usual reason a server slows down as a round goes on is NPCs: each one
with its own loop, its own path every frame, and no cap.

## One scheduler

One `Heartbeat` connection thinks for every NPC, with a time budget per
frame, and each NPC thinks at most every 0.1 to 0.2 seconds:

```lua
local RunService = game:GetService("RunService")

local THINK_EVERY = 0.15
local BUDGET_SECONDS = 0.002

local npcs = {}
local cursor = 1

local scheduler = RunService.Heartbeat:Connect(function()
	local started = os.clock()
	local now = started
	for _ = 1, #npcs do
		if cursor > #npcs then
			cursor = 1
		end
		local npc = npcs[cursor]
		cursor += 1
		if now - npc.lastThink >= THINK_EVERY then
			npc.lastThink = now
			npc:think()
		end
		if os.clock() - started > BUDGET_SECONDS then
			break
		end
	end
end)
```

Removing an NPC is `table.remove` from `npcs` when it dies or despawns; the
cursor wraps on the next frame.

## Numbers that hold up

| Knob | Starting value | Why |
|---|---|---|
| Think rate | 5 to 10 per second | Players do not notice reactions under 100 ms apart |
| Path recompute | on target moved 5+ studs, at most every 0.5 s | A path per frame per NPC is the classic stall |
| Perception radius query | once per think | Not per frame |
| Live NPC cap | a fixed number the spawner refuses past | A queue that grows forever is a slow crash |
| Far NPCs | park beyond the nearest player's view distance | Nobody sees them walk |

## Movement for crowds

Humanoids are the most expensive way to move many things. For decorative
crowds or simple enemies, an anchored model moved on the server in bulk with
`WorldRoot:BulkMoveTo` (or, for smoothness, the server sends positions and
clients tween the visuals) costs far less. Keep Humanoids for NPCs that need
Humanoid behaviour: climbing, falling, animations driven by the Animator.

## Measure

Tag the think with `debug.profilebegin("NPC think")` and
`debug.profileend()`, then read the server's MicroProfiler at the largest
NPC count the game allows. `roblox-performance` has the method.
