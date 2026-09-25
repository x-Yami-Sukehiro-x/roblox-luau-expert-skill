local TOGGLE_KEY = Enum.KeyCode.X
local SPEED = 40
local LOOK_DEGREES_PER_PIXEL = 0.25
local STICK_DEGREES_PER_SECOND = 180
local STICK_DEAD_ZONE = 0.15
local MAX_PITCH = math.rad(80)
local CLIMB_KEYS = {
	[Enum.KeyCode.E] = 1,
	[Enum.KeyCode.Q] = -1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Freecam then
	features.Freecam.unload()
end

type Saved = {
	cameraType: Enum.CameraType,
	mouseBehavior: Enum.MouseBehavior,
}

local player = Players.LocalPlayer
local freecam = { on = false, alive = true, speed = SPEED }
local connections: { RBXScriptConnection } = {}
local watchers: { RBXScriptConnection } = {}
local held: { [Enum.KeyCode]: number } = {}
local saved: Saved? = nil
local frozen: { root: BasePart, anchored: boolean }? = nil
local position = Vector3.zero
local yaw, pitch = 0, 0
local dragging = false
local stick = Vector3.zero

-- The body stays where it was: anchoring the root stops it walking off while
-- the movement keys drive the camera instead.
local function freeze()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return
	end
	frozen = { root = root, anchored = root.Anchored }
	root.Anchored = true
end

local function thaw()
	if frozen == nil then
		return
	end
	frozen.root.Anchored = frozen.anchored
	frozen = nil
end

local function facing(): Vector3
	local level = math.cos(pitch)
	return Vector3.new(-math.sin(yaw) * level, math.sin(pitch), -math.cos(yaw) * level)
end

local function turn(degreesRight: number, degreesUp: number)
	yaw -= math.rad(degreesRight)
	pitch = math.clamp(pitch + math.rad(degreesUp), -MAX_PITCH, MAX_PITCH)
end

-- MoveDirection comes from the keyboard, the gamepad stick and the touch
-- thumbstick alike, relative to the camera; split along the camera it steers
-- like fly, including climbing where the camera looks.
local function glide(deltaTime: number)
	if not freecam.on then
		return
	end
	if stick.Magnitude > STICK_DEAD_ZONE then
		local degrees = STICK_DEGREES_PER_SECOND * deltaTime
		turn(stick.X * degrees, stick.Y * degrees)
	end
	local view = CFrame.lookAlong(position, facing())
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local move = if humanoid then humanoid.MoveDirection else Vector3.zero
	local ahead = Vector3.yAxis:Cross(view.RightVector)
	local climb = 0
	for _, amount in held do
		climb += amount
	end
	local forward = view.LookVector * move:Dot(ahead)
	local sideways = view.RightVector * move:Dot(view.RightVector)
	local direction = forward + sideways + Vector3.yAxis * math.clamp(climb, -1, 1)
	if direction.Magnitude > 1 then
		direction = direction.Unit
	end
	position += direction * freecam.speed * deltaTime
	Workspace.CurrentCamera.CFrame = CFrame.lookAlong(position, facing())
end

local function detach()
	local camera = Workspace.CurrentCamera
	saved = { cameraType = camera.CameraType, mouseBehavior = UserInputService.MouseBehavior }
	local look = camera.CFrame.LookVector
	position = camera.CFrame.Position
	yaw = math.atan2(-look.X, -look.Z)
	pitch = math.clamp(math.asin(math.clamp(look.Y, -1, 1)), -MAX_PITCH, MAX_PITCH)
	camera.CameraType = Enum.CameraType.Scriptable
	-- The camera scripts put the type back on respawn.
	table.insert(
		watchers,
		camera:GetPropertyChangedSignal("CameraType"):Connect(function()
			if camera.CameraType ~= Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Scriptable
			end
		end)
	)
	freeze()
end

local function attach()
	for _, watcher in watchers do
		watcher:Disconnect()
	end
	table.clear(watchers)
	table.clear(held)
	dragging = false
	stick = Vector3.zero
	thaw()
	if saved then
		Workspace.CurrentCamera.CameraType = saved.cameraType
		UserInputService.MouseBehavior = saved.mouseBehavior
		saved = nil
	end
end

function freecam.set(on: boolean)
	if on == freecam.on then
		return
	end
	freecam.on = on
	if on then
		detach()
	else
		attach()
	end
end

function freecam.unload()
	freecam.alive = false
	freecam.set(false)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.Freecam == freecam then
		features.Freecam = nil
	end
end

table.insert(connections, RunService.PreRender:Connect(glide))

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == TOGGLE_KEY then
			freecam.set(not freecam.on)
		elseif freecam.on and CLIMB_KEYS[input.KeyCode] then
			held[input.KeyCode] = CLIMB_KEYS[input.KeyCode]
		elseif freecam.on and input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end)
)

table.insert(
	connections,
	UserInputService.InputEnded:Connect(function(input)
		held[input.KeyCode] = nil
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = false
			if saved then
				UserInputService.MouseBehavior = saved.mouseBehavior
			end
		end
	end)
)

-- Right mouse drag, a finger dragged anywhere the game's buttons are not, and
-- the right stick all turn the view.
table.insert(
	connections,
	UserInputService.InputChanged:Connect(function(input, processed)
		if not freecam.on then
			return
		end
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick = input.Position
		elseif input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			turn(input.Delta.X * LOOK_DEGREES_PER_PIXEL, -input.Delta.Y * LOOK_DEGREES_PER_PIXEL)
		elseif input.UserInputType == Enum.UserInputType.Touch and not processed then
			turn(input.Delta.X * LOOK_DEGREES_PER_PIXEL, -input.Delta.Y * LOOK_DEGREES_PER_PIXEL)
		end
	end)
)

table.insert(
	connections,
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		if freecam.alive and freecam.on and player.Character == character then
			thaw()
			freeze()
		end
	end)
)

features.Freecam = freecam
freecam.set(true)
