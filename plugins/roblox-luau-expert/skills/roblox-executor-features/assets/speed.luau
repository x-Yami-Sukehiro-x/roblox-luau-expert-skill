local TOGGLE_KEY = Enum.KeyCode.G
local WALK_SPEED = 40
local JUMP_HEIGHT = 16

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Speed then
	features.Speed.unload()
end

type Held = {
	humanoid: Humanoid,
	walkSpeed: number,
	jumpPower: number,
	jumpHeight: number,
	watchers: { RBXScriptConnection },
}

local player = Players.LocalPlayer
local speed = { on = false, alive = true, walk = WALK_SPEED, jump = JUMP_HEIGHT }
local connections: { RBXScriptConnection } = {}
local held: Held? = nil

-- A game that uses JumpPower ignores JumpHeight, so both are written; the power
-- is the launch speed that reaches the same height under this place's gravity.
local function write(humanoid: Humanoid)
	humanoid.WalkSpeed = speed.walk
	humanoid.JumpHeight = speed.jump
	humanoid.JumpPower = math.sqrt(2 * Workspace.Gravity * speed.jump)
end

local function release()
	if held == nil then
		return
	end
	for _, watcher in held.watchers do
		watcher:Disconnect()
	end
	local humanoid = held.humanoid
	humanoid.WalkSpeed = held.walkSpeed
	humanoid.JumpPower = held.jumpPower
	humanoid.JumpHeight = held.jumpHeight
	held = nil
end

-- Sprint, stun and round scripts rewrite WalkSpeed; the watchers write it back.
local function hold()
	release()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local watchers = {}
	held = {
		humanoid = humanoid,
		walkSpeed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		watchers = watchers,
	}
	write(humanoid)
	for _, property in { "WalkSpeed", "JumpPower", "JumpHeight" } do
		table.insert(
			watchers,
			humanoid:GetPropertyChangedSignal(property):Connect(function()
				write(humanoid)
			end)
		)
	end
end

function speed.set(on: boolean)
	speed.on = on
	if on then
		hold()
	else
		release()
	end
end

function speed.unload()
	speed.alive = false
	speed.set(false)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.Speed == speed then
		features.Speed = nil
	end
end

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == TOGGLE_KEY then
			speed.set(not speed.on)
		end
	end)
)

table.insert(
	connections,
	player.CharacterAdded:Connect(function(character)
		release()
		character:WaitForChild("Humanoid")
		if speed.alive and speed.on and player.Character == character then
			hold()
		end
	end)
)

features.Speed = speed
speed.set(true)
