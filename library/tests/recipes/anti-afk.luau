local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local virtual = HARNESS.services.VirtualUser
local idled = world.player.Idled
__recipe()
local afk = world.genv.Features.AntiAfk

idled:Fire(120)
check("going idle sends one synthetic click", virtual.captured == true and virtual.clicks == 1)
idled:Fire(240)
check("each idle warning is answered", virtual.clicks == 2)

__recipe()
idled:Fire(360)
check("running it again does not double the clicks", virtual.clicks == 3 and afk.alive == false)
world.genv.Features.AntiAfk.unload()
world.genv.Features.AntiAfk = nil
idled:Fire(480)
check("unload stops it", virtual.clicks == 3 and #idled.handlers == 0)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
