local HOLD_KEY = Enum.KeyCode.LeftControl
local REACH = 1000
-- The root part sits about this far above the floor, so the body lands standing.
local LIFT = Vector3.new(0, 3, 0)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.ClickTeleport then
	features.ClickTeleport.unload()
end

local player = Players.LocalPlayer
local teleport = {
	on = true,
	alive = true,
	-- A phone has no key to hold, so a plain tap on the world teleports there.
	touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
}
local connections: { RBXScriptConnection } = {}

local function teleportTo(x: number, y: number)
	local character = player.Character
	if not teleport.on or character == nil then
		return
	end
	local ray = Workspace.CurrentCamera:ViewportPointToRay(x, y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * REACH, params)
	if hit == nil then
		return
	end
	local facing = Vector3.yAxis:Cross(character:GetPivot().RightVector)
	character:PivotTo(CFrame.lookAlong(hit.Position + LIFT, facing))
end

function teleport.set(on: boolean)
	teleport.on = on
end

function teleport.unload()
	teleport.alive = false
	teleport.on = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.ClickTeleport == teleport then
		features.ClickTeleport = nil
	end
end

-- GetMouseLocation counts the top bar, which is the space ViewportPointToRay reads.
table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		local click = input.UserInputType == Enum.UserInputType.MouseButton1
		if click and not processed and UserInputService:IsKeyDown(HOLD_KEY) then
			local mouse = UserInputService:GetMouseLocation()
			teleportTo(mouse.X, mouse.Y)
		end
	end)
)

table.insert(
	connections,
	UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
		if teleport.touch and not processedByUI then
			teleportTo(position.X, position.Y)
		end
	end)
)

features.ClickTeleport = teleport
