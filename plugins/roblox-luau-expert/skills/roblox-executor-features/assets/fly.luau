local TOGGLE_KEY = Enum.KeyCode.F
local SPEED = 60
local CLIMB_KEYS = {
	[Enum.KeyCode.E] = 1,
	[Enum.KeyCode.Space] = 1,
	[Enum.KeyCode.Q] = -1,
	[Enum.KeyCode.LeftControl] = -1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Fly then
	features.Fly.unload()
end

type Rig = {
	humanoid: Humanoid,
	attachment: Attachment,
	velocity: LinearVelocity,
	align: AlignOrientation,
}

local player = Players.LocalPlayer
local fly = { on = false, alive = true, speed = SPEED }
local held: { [Enum.KeyCode]: number } = {}
local connections: { RBXScriptConnection } = {}
local rig: Rig? = nil

local function land()
	if rig == nil then
		return
	end
	rig.humanoid.PlatformStand = false
	rig.attachment:Destroy()
	rig = nil
end

local function takeOff()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if humanoid == nil or root == nil then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlyAttachment"
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = attachment
	-- Rigid alignment ignores torque limits, so the body never tips while flying.
	local align = Instance.new("AlignOrientation")
	align.Attachment0 = attachment
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.RigidityEnabled = true
	align.Parent = attachment
	attachment.Parent = root
	humanoid.PlatformStand = true
	rig = { humanoid = humanoid, attachment = attachment, velocity = velocity, align = align }
end

-- MoveDirection is already camera-yaw relative on keyboard, gamepad and the
-- touch thumbstick, so splitting it along the camera gives pitch for free.
local function steer()
	if rig == nil then
		return
	end
	local view = Workspace.CurrentCamera.CFrame
	local ahead = Vector3.yAxis:Cross(view.RightVector)
	local move = rig.humanoid.MoveDirection
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
	rig.velocity.VectorVelocity = direction * fly.speed
	rig.align.CFrame = CFrame.lookAlong(Vector3.zero, ahead)
end

function fly.set(on: boolean)
	fly.on = on
	if not on then
		land()
	elseif rig == nil then
		takeOff()
	end
end

function fly.unload()
	fly.alive = false
	fly.on = false
	land()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if features.Fly == fly then
		features.Fly = nil
	end
end

table.insert(connections, RunService.PreSimulation:Connect(steer))

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == TOGGLE_KEY then
			fly.set(not fly.on)
		elseif CLIMB_KEYS[input.KeyCode] then
			held[input.KeyCode] = CLIMB_KEYS[input.KeyCode]
		end
	end)
)

table.insert(
	connections,
	UserInputService.InputEnded:Connect(function(input)
		held[input.KeyCode] = nil
	end)
)

table.insert(
	connections,
	player.CharacterAdded:Connect(function(character)
		rig = nil
		character:WaitForChild("Humanoid")
		character:WaitForChild("HumanoidRootPart")
		if fly.alive and fly.on and player.Character == character then
			takeOff()
		end
	end)
)

features.Fly = fly
fly.set(true)
