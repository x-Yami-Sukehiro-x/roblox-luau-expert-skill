local TOGGLE_KEY = Enum.KeyCode.V

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Noclip then
	features.Noclip.unload()
end

local player = Players.LocalPlayer
local noclip = { on = false, alive = true }
local connections: { RBXScriptConnection } = {}
local switched: { [BasePart]: true } = {}

-- The Humanoid turns collision back on for its body parts every step, so the
-- write repeats before each physics step instead of happening once.
local function phase()
	local character = player.Character
	if not noclip.on or character == nil then
		return
	end
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide then
			switched[part] = true
			part.CanCollide = false
		end
	end
end

local function restore()
	for part in switched do
		if part.Parent then
			part.CanCollide = true
		end
	end
	table.clear(switched)
end

function noclip.set(on: boolean)
	noclip.on = on
	if on then
		phase()
	else
		restore()
	end
end

function noclip.unload()
	noclip.alive = false
	noclip.set(false)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.Noclip == noclip then
		features.Noclip = nil
	end
end

table.insert(connections, RunService.PreSimulation:Connect(phase))

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == TOGGLE_KEY then
			noclip.set(not noclip.on)
		end
	end)
)

table.insert(
	connections,
	player.CharacterAdded:Connect(function()
		table.clear(switched)
	end)
)

features.Noclip = noclip
noclip.set(true)
