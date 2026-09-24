local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
local function near(a, b) return math.abs(a - b) < 0.01 end

local world = HARNESS.world()
local step = HARNESS.services.RunService.PreSimulation
__recipe()
local fly = world.genv.Features.Fly
local humanoid = world.player.Character.Humanoid
local root = world.player.Character.HumanoidRootPart
local rig = root.FlyAttachment

check("running it starts flying on the root", rig ~= nil and rig.LinearVelocity ~= nil and rig.AlignOrientation.RigidityEnabled == true)
check("the humanoid stops fighting the constraints", humanoid.PlatformStand == true)
check("velocity is world space with no force cap", rig.LinearVelocity.RelativeTo == Enum.ActuatorRelativeTo.World and rig.LinearVelocity.MaxForce == math.huge)

step:Fire(1 / 60)
check("no input holds still in the air", rig.LinearVelocity.VectorVelocity.Magnitude == 0)

world.camera.CFrame = CFrame.lookAlong(Vector3.zero, Vector3.new(0, 1, -1))
humanoid.MoveDirection = Vector3.new(0, 0, -1)
step:Fire(1 / 60)
local velocity = rig.LinearVelocity.VectorVelocity
check("forward follows the camera's pitch", near(velocity.Y, 42.43) and near(velocity.Z, -42.43))
check("the body faces where the camera looks, level", near(rig.AlignOrientation.CFrame.LookVector.Z, -1))

world.camera.CFrame = CFrame.identity
humanoid.MoveDirection = Vector3.new(1, 0, 0)
step:Fire(1 / 60)
check("the thumbstick or D strafes right", near(rig.LinearVelocity.VectorVelocity.X, 60))

humanoid.MoveDirection = Vector3.zero
world.key(Enum.KeyCode.E)
step:Fire(1 / 60)
check("E climbs", near(rig.LinearVelocity.VectorVelocity.Y, 60))
world.key(Enum.KeyCode.E, false)
world.key(Enum.KeyCode.LeftControl)
step:Fire(1 / 60)
check("LeftControl sinks", near(rig.LinearVelocity.VectorVelocity.Y, -60))
world.key(Enum.KeyCode.LeftControl, false)

humanoid.MoveDirection = Vector3.new(0, 0, -1)
world.key(Enum.KeyCode.Space)
world.key(Enum.KeyCode.E)
step:Fire(1 / 60)
check("climbing while moving is no faster than the set speed", near(rig.LinearVelocity.VectorVelocity.Magnitude, 60))
world.key(Enum.KeyCode.Space, false)
world.key(Enum.KeyCode.E, false)

fly.speed = 100
step:Fire(1 / 60)
check("a hub slider can change the speed live", near(rig.LinearVelocity.VectorVelocity.Magnitude, 100))

world.key(Enum.KeyCode.F)
check("F lands: constraints removed, humanoid back in control", root:FindFirstChild("FlyAttachment") == nil and rig.destroyed and humanoid.PlatformStand == false)
HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.F }, true)
check("F typed into chat does not toggle", root:FindFirstChild("FlyAttachment") == nil)
world.key(Enum.KeyCode.F)
check("F again takes off", root:FindFirstChild("FlyAttachment") ~= nil and humanoid.PlatformStand == true)

local body = world.respawn(world.player)
check("flying carries over a respawn", body.HumanoidRootPart:FindFirstChild("FlyAttachment") ~= nil and body.Humanoid.PlatformStand == true)
fly.set(false)
check("landing after respawn frees the new body", body.Humanoid.PlatformStand == false)
body = world.respawn(world.player)
check("respawning while landed stays landed", body.HumanoidRootPart:FindFirstChild("FlyAttachment") == nil)

fly.set(true)
local before = body.HumanoidRootPart.FlyAttachment
__recipe()
local again = world.genv.Features.Fly
check("running it again replaces the old session", again ~= fly and fly.alive == false and before.destroyed)
check("one steering loop after a rerun", #step.handlers == 1 and body.HumanoidRootPart.FlyAttachment ~= before)

again.unload()
again.unload()
check("unload twice is harmless and leaves nothing", world.genv.Features.Fly == nil and #step.handlers == 0 and body.Humanoid.PlatformStand == false)
world.key(Enum.KeyCode.F)
check("after unload the key does nothing", body.HumanoidRootPart:FindFirstChild("FlyAttachment") == nil)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
