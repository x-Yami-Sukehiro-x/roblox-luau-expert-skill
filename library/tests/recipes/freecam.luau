local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
local function near(a, b) return math.abs(a - b) < 0.01 end

local world = HARNESS.world()
local input = HARNESS.input
local step = HARNESS.services.RunService.PreRender
local camera = world.camera
local humanoid = world.player.Character.Humanoid
local root = world.player.Character.HumanoidRootPart
local UNKNOWN = Enum.KeyCode.Unknown
local function mouse(kind, down)
	local signal = if down then input.InputBegan else input.InputEnded
	signal:Fire({ KeyCode = UNKNOWN, UserInputType = kind }, false)
end
local function drag(kind, x, y, processed)
	input.InputChanged:Fire({ KeyCode = UNKNOWN, UserInputType = kind, Delta = Vector3.new(x, y, 0) }, processed == true)
end

__recipe()
local freecam = world.genv.Features.Freecam

check("running it detaches the camera", camera.CameraType == Enum.CameraType.Scriptable)
check("the body is held where it stood", root.Anchored == true)

humanoid.MoveDirection = Vector3.new(0, 0, -1)
step:Fire(1)
check("forward moves the camera where it looks", near(camera.CFrame.Position.Z, -40) and near(camera.CFrame.Position.Y, 0))
humanoid.MoveDirection = Vector3.zero
world.key(Enum.KeyCode.E)
step:Fire(1)
check("E climbs", near(camera.CFrame.Position.Y, 40))
world.key(Enum.KeyCode.E, false)

drag(Enum.UserInputType.MouseMovement, 360, 0)
step:Fire(0)
check("the mouse alone does not turn the view", near(camera.CFrame.LookVector.Z, -1))
mouse(Enum.UserInputType.MouseButton2, true)
check("holding the right button locks the cursor in place", input.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition)
drag(Enum.UserInputType.MouseMovement, 360, 0)
step:Fire(0)
check("dragging with the right button turns the view", near(camera.CFrame.LookVector.X, 1))
mouse(Enum.UserInputType.MouseButton2, false)
check("releasing it frees the cursor", input.MouseBehavior == Enum.MouseBehavior.Default)

drag(Enum.UserInputType.Touch, -360, 0, true)
step:Fire(0)
check("a finger on the thumbstick does not turn the view", near(camera.CFrame.LookVector.X, 1))
drag(Enum.UserInputType.Touch, -360, 0)
step:Fire(0)
check("a finger dragged across the screen turns it back", near(camera.CFrame.LookVector.Z, -1))

input.InputChanged:Fire({ KeyCode = Enum.KeyCode.Thumbstick2, UserInputType = Enum.UserInputType.Gamepad1, Position = Vector3.new(0, 1, 0) }, false)
step:Fire(1 / 9)
check("the right stick tilts the view up", camera.CFrame.LookVector.Y > 0.3)
input.InputChanged:Fire({ KeyCode = Enum.KeyCode.Thumbstick2, UserInputType = Enum.UserInputType.Gamepad1, Position = Vector3.new(0, 1, 0) }, false)
step:Fire(5)
check("looking up stops short of straight up", camera.CFrame.LookVector.Y < 0.99)
input.InputChanged:Fire({ KeyCode = Enum.KeyCode.Thumbstick2, UserInputType = Enum.UserInputType.Gamepad1, Position = Vector3.zero }, false)

camera.CameraType = Enum.CameraType.Custom
check("the camera scripts taking the camera back is undone", camera.CameraType == Enum.CameraType.Scriptable)

freecam.speed = 80
humanoid.MoveDirection = Vector3.zero
world.key(Enum.KeyCode.Q)
local before = camera.CFrame.Position.Y
step:Fire(1)
check("a hub slider changes the speed live", near(before - camera.CFrame.Position.Y, 80))
world.key(Enum.KeyCode.Q, false)

local body = world.respawn(world.player)
check("a new body after respawn is held too", body.HumanoidRootPart.Anchored == true)

world.key(Enum.KeyCode.X)
check("X gives the camera back to the game", camera.CameraType == Enum.CameraType.Custom and body.HumanoidRootPart.Anchored == false)
local resting = camera.CFrame.Position
world.key(Enum.KeyCode.E)
step:Fire(1)
check("while off the keys and the step leave the camera alone", camera.CFrame.Position == resting)
world.key(Enum.KeyCode.E, false)
input.InputBegan:Fire({ KeyCode = Enum.KeyCode.X }, true)
check("X typed into chat does not toggle", freecam.on == false)

body.HumanoidRootPart.Anchored = true
freecam.set(true)
freecam.set(false)
check("a root the game had anchored stays anchored", body.HumanoidRootPart.Anchored == true)
body.HumanoidRootPart.Anchored = false

freecam.set(true)
__recipe()
local again = world.genv.Features.Freecam
check("running it again replaces the old session", again ~= freecam and freecam.alive == false and #step.handlers == 1)
check("a rerun saves the game's camera type, not Scriptable", again.on and body.HumanoidRootPart.Anchored == true)

again.unload()
again.unload()
check("unload twice is harmless and restores the camera", world.genv.Features.Freecam == nil and camera.CameraType == Enum.CameraType.Custom and #step.handlers == 0)
check("unload frees the body", body.HumanoidRootPart.Anchored == false)
world.key(Enum.KeyCode.X)
check("after unload the key does nothing", camera.CameraType == Enum.CameraType.Custom)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
