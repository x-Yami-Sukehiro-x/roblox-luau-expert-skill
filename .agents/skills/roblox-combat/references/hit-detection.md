# Hit detection on the server

Two complete server handlers: a melee swing and a hitscan shot. Both take
intent from the client and decide everything else themselves.

## Melee

The client fires `Swing` with nothing but the weapon's name. The server
knows where the character is, so it sweeps a box forward from there.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Swing = ReplicatedStorage.Remotes.Swing

local SWORD = { damage = 20, cooldown = 0.6, reach = 7, width = Vector3.new(4, 5, 1) }

local lastSwing: { [Player]: number } = {}

local sweepParams = RaycastParams.new()
sweepParams.FilterType = Enum.RaycastFilterType.Exclude

local function applyDamage(attacker: Player, humanoid: Humanoid, amount: number)
	if humanoid.Health <= 0 then
		return
	end
	humanoid:TakeDamage(amount)
	if humanoid.Health <= 0 then
		humanoid:SetAttribute("KilledBy", attacker.UserId)
	end
end

Swing.OnServerEvent:Connect(function(player: Player, weaponName: unknown)
	if weaponName ~= "Sword" then
		return
	end
	local now = os.clock()
	if now - (lastSwing[player] or 0) < SWORD.cooldown then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if not character:FindFirstChild("Sword") then
		return
	end
	lastSwing[player] = now

	sweepParams.FilterDescendantsInstances = { character }
	local start = root.CFrame
	local result = workspace:Blockcast(start, SWORD.width, start.LookVector * SWORD.reach, sweepParams)
	if not result then
		return
	end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local target = model and model:FindFirstChildOfClass("Humanoid")
	if target then
		applyDamage(player, target, SWORD.damage)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastSwing[player] = nil
end)
```

A Blockcast returns the first thing it hits, and it does not report parts
the box already overlaps where it starts, so an enemy pressed against the
attacker is missed. Start the box a stud or two behind the character, or
check point-blank range with `Workspace:GetPartBoundsInBox`. For a swing that should hit
several enemies, use `Workspace:GetPartBoundsInBox` at the swing's end
position with `OverlapParams` filtered to characters, then deduplicate by
model so one enemy with six parts is hit once.

## Hitscan

The client sends where it fired from and the direction. The server trusts
neither: the origin must be near the character, and the ray is cast by the
server.

```lua
local MAX_ORIGIN_ERROR = 6
local RANGE = 300

local function validShot(character: Model, origin: unknown, direction: unknown): boolean
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (origin - root.Position).Magnitude > MAX_ORIGIN_ERROR then
		return false
	end
	return direction.Magnitude > 0.5 and direction.Magnitude < 1.5
end
```

After `validShot`, the server casts `workspace:Raycast(origin, direction.Unit
* RANGE, params)` with the shooter excluded, and damages what it hits.
`MAX_ORIGIN_ERROR` is the latency allowance, named so it can be tuned and
found. The direction check rejects a zero vector and a scaled one that would
change the range.

## What never to accept from a client

- A damage number, a target to damage, or a hit position used for damage.
- "My cooldown is over."
- A weapon the character is not holding.
- An origin far from the character.
