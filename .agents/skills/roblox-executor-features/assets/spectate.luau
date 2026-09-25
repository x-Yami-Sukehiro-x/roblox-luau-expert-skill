local TOGGLE_KEY = Enum.KeyCode.P
local NEXT_KEY = Enum.KeyCode.RightBracket
local PREVIOUS_KEY = Enum.KeyCode.LeftBracket

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Spectate then
	features.Spectate.unload()
end

local player = Players.LocalPlayer
local spectate = { on = false, alive = true, target = nil :: Player? }
local connections: { RBXScriptConnection } = {}
local watchers: { RBXScriptConnection } = {}

local function others(leaving: Player?): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other ~= leaving then
			table.insert(list, other)
		end
	end
	return list
end

local function ownHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function unwatch()
	for _, watcher in watchers do
		watcher:Disconnect()
	end
	table.clear(watchers)
end

-- The camera script points the camera back at our own body whenever we
-- respawn, and the target's respawn makes a new Humanoid; both are re-aimed.
local function aim()
	unwatch()
	local target = spectate.target
	if target == nil then
		return
	end
	table.insert(
		watchers,
		target.CharacterAdded:Connect(function(body)
			body:WaitForChild("Humanoid")
			if spectate.alive and spectate.target == target then
				aim()
			end
		end)
	)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local camera = Workspace.CurrentCamera
	camera.CameraSubject = humanoid
	table.insert(
		watchers,
		camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
			if camera.CameraSubject ~= humanoid then
				camera.CameraSubject = humanoid
			end
		end)
	)
end

-- Back to our current body, not the one captured at the start: that one may
-- have died since.
local function release()
	unwatch()
	local humanoid = ownHumanoid()
	if humanoid then
		Workspace.CurrentCamera.CameraSubject = humanoid
	end
end

function spectate.follow(target: Player?)
	spectate.target = target
	spectate.on = target ~= nil
	if target then
		aim()
	else
		release()
	end
end

function spectate.step(offset: number, leaving: Player?)
	local list = others(leaving)
	if #list == 0 then
		spectate.follow(nil)
		return
	end
	local index = table.find(list, spectate.target) or (if offset > 0 then 0 else 1)
	spectate.follow(list[(index - 1 + offset) % #list + 1])
end

function spectate.set(on: boolean)
	if on then
		spectate.step(1)
	else
		spectate.follow(nil)
	end
end

function spectate.unload()
	spectate.alive = false
	spectate.follow(nil)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.Spectate == spectate then
		features.Spectate = nil
	end
end

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == TOGGLE_KEY then
			spectate.set(not spectate.on)
		elseif spectate.on and input.KeyCode == NEXT_KEY then
			spectate.step(1)
		elseif spectate.on and input.KeyCode == PREVIOUS_KEY then
			spectate.step(-1)
		end
	end)
)

table.insert(
	connections,
	Players.PlayerRemoving:Connect(function(leaving)
		if leaving == spectate.target then
			spectate.step(1, leaving)
		end
	end)
)

features.Spectate = spectate
spectate.set(true)
