local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local body = world.player.Character
local input = HARNESS.input
local function click() input.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, false) end

__recipe()
local teleport = world.genv.Features.ClickTeleport
world.workspace.hit = Vector3.new(50, 0, 20)

click()
check("a plain click does nothing", body.pivot == nil)

input.down = Enum.KeyCode.LeftControl
click()
local target = body.pivot
check("Ctrl+click moves the body to the clicked ground, standing", target ~= nil and target.Position == Vector3.new(50, 3, 20))
check("the body keeps facing the same way", target.LookVector.Z == -1)

body.pivot = nil
input.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, true)
check("a click on a button is left to the button", body.pivot == nil)

world.workspace.hit = nil
click()
check("clicking the sky goes nowhere", body.pivot == nil)

world.workspace.hit = Vector3.new(5, 0, 5)
input.TouchTapInWorld:Fire(Vector2.new(100, 100), false)
check("with a keyboard, taps do not teleport", body.pivot == nil)
teleport.touch = true
input.TouchTapInWorld:Fire(Vector2.new(100, 100), true)
check("a tap on a button is left to the button", body.pivot == nil)
input.TouchTapInWorld:Fire(Vector2.new(100, 100), false)
check("on a phone a tap on the world teleports", body.pivot ~= nil and body.pivot.Position == Vector3.new(5, 3, 5))

__recipe()
local again = world.genv.Features.ClickTeleport
check("running it again replaces the old session", again ~= teleport and teleport.alive == false and #input.InputBegan.handlers == 1)
again.unload()
again.unload()
check("unload twice leaves nothing", #input.InputBegan.handlers == 0 and #input.TouchTapInWorld.handlers == 0 and world.genv.Features.ClickTeleport == nil)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
