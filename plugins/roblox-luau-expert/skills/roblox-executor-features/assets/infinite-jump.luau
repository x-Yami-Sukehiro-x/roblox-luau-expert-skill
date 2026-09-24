local TOGGLE_KEY = Enum.KeyCode.J
-- JumpRequest repeats every frame while the button is held; the gap turns a
-- held button into a steady climb instead of a launch.
local JUMP_GAP = 0.2

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.InfiniteJump then
	features.InfiniteJump.unload()
end

local player = Players.LocalPlayer
local jump = { on = true, alive = true }
local connections: { RBXScriptConnection } = {}
local lastJump = -math.huge

function jump.set(on: boolean)
	jump.on = on
end

function jump.unload()
	jump.alive = false
	jump.on = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.InfiniteJump == jump then
		features.InfiniteJump = nil
	end
end

table.insert(
	connections,
	UserInputService.JumpRequest:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local now = os.clock()
		if not jump.on or humanoid == nil or humanoid.Health <= 0 or now - lastJump < JUMP_GAP then
			return
		end
		lastJump = now
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end)
)

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == TOGGLE_KEY then
			jump.set(not jump.on)
		end
	end)
)

features.InfiniteJump = jump
