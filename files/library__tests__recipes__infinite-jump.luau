local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local clock = 100
os = setmetatable({ clock = function() return clock end }, { __index = os })

local world = HARNESS.world()
local humanoid = world.player.Character.Humanoid
local request = HARNESS.input.JumpRequest
__recipe()
local jump = world.genv.Features.InfiniteJump

request:Fire()
check("a jump request in mid-air jumps again", humanoid.lastState == Enum.HumanoidStateType.Jumping)

humanoid.lastState = nil
clock += 0.05
request:Fire()
check("a held button does not jump every frame", humanoid.lastState == nil)
clock += 0.2
request:Fire()
check("after the gap it jumps again", humanoid.lastState == Enum.HumanoidStateType.Jumping)

humanoid.lastState = nil
humanoid.Health = 0
clock += 1
request:Fire()
check("a dead body is left alone", humanoid.lastState == nil)

local body = world.respawn(world.player)
clock += 1
request:Fire()
check("the new body after respawn jumps", body.Humanoid.lastState == Enum.HumanoidStateType.Jumping)

body.Humanoid.lastState = nil
world.key(Enum.KeyCode.J)
clock += 1
request:Fire()
check("J turns it off", body.Humanoid.lastState == nil and jump.on == false)

__recipe()
local again = world.genv.Features.InfiniteJump
check("running it again replaces the old session", again ~= jump and jump.alive == false and #request.handlers == 1)
again.unload()
again.unload()
check("unload twice leaves nothing", #request.handlers == 0 and world.genv.Features.InfiniteJump == nil)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
