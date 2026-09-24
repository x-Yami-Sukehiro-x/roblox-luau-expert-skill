local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local step = HARNESS.services.RunService.PreSimulation
local body = world.player.Character
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.CanCollide = false
local hat = Instance.new("Accessory")
hat.Name = "Hat"
handle.Parent = hat
hat.Parent = body

__recipe()
local noclip = world.genv.Features.Noclip
check("running it turns collision off at once", body.HumanoidRootPart.CanCollide == false and body.Head.CanCollide == false)

body.HumanoidRootPart.CanCollide = true
step:Fire(1 / 60)
check("the Humanoid turning it back on is undone every step", body.HumanoidRootPart.CanCollide == false)

world.key(Enum.KeyCode.V)
check("V restores only what it switched off", body.HumanoidRootPart.CanCollide == true and body.Head.CanCollide == true and handle.CanCollide == false)
step:Fire(1 / 60)
check("while off the step leaves collision alone", body.HumanoidRootPart.CanCollide == true)
HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.V }, true)
check("V typed into chat does not toggle", noclip.on == false)

world.key(Enum.KeyCode.V)
body = world.respawn(world.player)
step:Fire(1 / 60)
check("a new body after respawn walks through walls too", body.HumanoidRootPart.CanCollide == false)

__recipe()
local again = world.genv.Features.Noclip
check("running it again replaces the old session", again ~= noclip and noclip.alive == false and #step.handlers == 1)
again.unload()
again.unload()
check("unload restores collision and leaves nothing", body.HumanoidRootPart.CanCollide == true and #step.handlers == 0 and world.genv.Features.Noclip == nil)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
