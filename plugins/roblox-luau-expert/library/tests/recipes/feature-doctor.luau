local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local printed = {}
local report = print
print = function(text) table.insert(printed, text) end
local copied = nil
identifyexecutor = function() return "TestExecutor", "2.1" end
setclipboard = function(text) copied = text end

local world = HARNESS.world()
local humanoid = world.player.Character.Humanoid
local root = world.player.Character.HumanoidRootPart
world.genv.Features = {
	Fly = { on = true, alive = true },
	Freecam = { on = true, alive = true },
	Speed = { on = false, alive = false },
}
root.Anchored = true
humanoid.SeatPart = Instance.new("Seat")
world.workspace.StreamingEnabled = true
__recipe()

humanoid.WalkSpeed = 8
humanoid.WalkSpeed = 16
humanoid.WalkSpeed = 8
world.lighting.ClockTime = 12
check("nothing is printed until the watch ends", #printed == 0)
HARNESS.drain()
local text = printed[1] or ""

check("the report names the executor", text:find("executor TestExecutor 2.1", 1, true) ~= nil)
check("each loaded feature and its state is listed", text:find("Fly: on", 1, true) ~= nil and text:find("Freecam: on", 1, true) ~= nil)
check("a session unloaded but still registered is called out", text:find("Speed: unloaded but still registered", 1, true) ~= nil)
check("two features that fight are named with the reason", text:find("Fly and Freecam are both on: freecam anchors the body;", 1, true) ~= nil)
check("a seated character is explained", text:find("seated: fly, noclip and teleports", 1, true) ~= nil)
check("an anchored root is explained", text:find("the root is anchored", 1, true) ~= nil)
check("streaming is mentioned when it is on", text:find("StreamingEnabled:", 1, true) ~= nil)
check("a property the game keeps writing is counted", text:find("Humanoid.WalkSpeed: 3", 1, true) ~= nil)
check("a day cycle writing the clock is counted", text:find("Lighting.ClockTime: 1", 1, true) ~= nil)
check("properties nobody touched are left out", text:find("FieldOfView", 1, true) == nil)
check("the same text goes to the clipboard", copied ~= nil and copied == text)
check("it changes nothing it reads", humanoid.WalkSpeed == 8 and root.Anchored == true and world.genv.Features.Fly.on == true)

humanoid.WalkSpeed = 30
check("the watchers stop after the report", #humanoid:GetPropertyChangedSignal("WalkSpeed").handlers == 0)

printed = {}
identifyexecutor, setclipboard = nil, nil
world = HARNESS.world()
world.player.Character = nil
__recipe()
HARNESS.drain()
text = printed[1] or ""
check("without identifyexecutor the executor is unknown", text:find("executor unknown", 1, true) ~= nil)
check("no features loaded says what to run first", text:find("none loaded: run the feature script first", 1, true) ~= nil)
check("no character says when features apply", text:find("no character with a Humanoid", 1, true) ~= nil)
check("a quiet five seconds says so", text:find("nothing changed", 1, true) ~= nil)
check("without setclipboard nothing claims a copy", text:find("clipboard", 1, true) == nil)

print = report
local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
