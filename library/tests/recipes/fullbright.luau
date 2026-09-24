local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local lighting = world.lighting
local night = lighting.Ambient
__recipe()
local fullbright = world.genv.Features.Fullbright

check("running it lights the place", lighting.ClockTime == 14 and lighting.GlobalShadows == false and lighting.FogEnd == 100000 and lighting.Ambient ~= night)
lighting.ClockTime = 22
check("a day and night script cannot bring the dark back", lighting.ClockTime == 14)

world.key(Enum.KeyCode.B)
check("B restores the game's own lighting", lighting.ClockTime == 20 and lighting.Brightness == 1 and lighting.Ambient == night and lighting.GlobalShadows == true)
lighting.ClockTime = 22
check("while off the game's cycle runs", lighting.ClockTime == 22)

world.key(Enum.KeyCode.B)
fullbright.set(true)
fullbright.set(false)
check("turning it on twice still restores the real original", lighting.ClockTime == 22)

fullbright.set(true)
__recipe()
local again = world.genv.Features.Fullbright
check("running it again replaces the old session", again ~= fullbright and fullbright.alive == false and lighting.ClockTime == 14)
again.unload()
again.unload()
check("unload restores the lighting and leaves nothing", lighting.ClockTime == 22 and world.genv.Features.Fullbright == nil and #HARNESS.input.InputBegan.handlers == 0)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
