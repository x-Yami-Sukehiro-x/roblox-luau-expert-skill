local TOGGLE_KEY = Enum.KeyCode.Z
local MAX_ZOOM = 1000
local MIN_ZOOM = 0.5
local FIELD_OF_VIEW = 80

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.CameraUnlock then
	features.CameraUnlock.unload()
end

type Hold = {
	target: Instance,
	property: string,
	original: any,
	watcher: RBXScriptConnection,
}

local player = Players.LocalPlayer
local unlock = { on = false, alive = true, zoom = MAX_ZOOM, fov = FIELD_OF_VIEW }
local connections: { RBXScriptConnection } = {}
local holds: { Hold } = {}

local function release()
	for index = #holds, 1, -1 do
		local held = holds[index]
		held.watcher:Disconnect()
		held.target[held.property] = held.original
	end
	table.clear(holds)
end

-- Games that lock first person, cap the zoom or zoom the FOV for sprinting
-- write these back; each watcher restores the unlocked value.
local function hold()
	release()
	local camera = Workspace.CurrentCamera
	local unlocked = {
		{ player, "CameraMaxZoomDistance", unlock.zoom },
		{ player, "CameraMinZoomDistance", MIN_ZOOM },
		{ player, "CameraMode", Enum.CameraMode.Classic },
		{ camera, "FieldOfView", unlock.fov },
	}
	for _, entry in unlocked do
		local target, property, value = entry[1], entry[2], entry[3]
		local original = target[property]
		target[property] = value
		table.insert(holds, {
			target = target,
			property = property,
			original = original,
			watcher = target:GetPropertyChangedSignal(property):Connect(function()
				if target[property] ~= value then
					target[property] = value
				end
			end),
		})
	end
end

function unlock.set(on: boolean)
	unlock.on = on
	if on then
		hold()
	else
		release()
	end
end

function unlock.unload()
	unlock.alive = false
	unlock.set(false)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.CameraUnlock == unlock then
		features.CameraUnlock = nil
	end
end

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == TOGGLE_KEY then
			unlock.set(not unlock.on)
		end
	end)
)

table.insert(
	connections,
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if unlock.alive and unlock.on then
			hold()
		end
	end)
)

features.CameraUnlock = unlock
unlock.set(true)
