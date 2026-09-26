-- ====== example/Example.luau against the bundle ======
-- Runs after stubs.luau, stubs-extra.luau, `local function loadKit()` and
-- `local function runExample()`. The example is the file users paste first,
-- so it gets its own run: build, respawn, rerun, unload.

local pass, fail = 0, 0
local function check(label, ok, detail)
	if ok then
		pass += 1
	else
		fail += 1
		print(string.format("FAIL  %s   %s", label, detail or ""))
	end
end

local world = HARNESS.world()
local input = HARNESS.services.UserInputService
input.KeyboardEnabled = true
input.GetLastInputType = function()
	return Enum.UserInputType.MouseButton1
end

local storage = Instance.new("Folder")
local module = Instance.new("ModuleScript")
module.Name = "HubKit"
module.Parent = storage
HARNESS.services.ReplicatedStorage = storage
function require(target)
	assert(target == module, "the example should require ReplicatedStorage.HubKit")
	return loadKit()
end

runExample()
local first = world.genv.HubKitDemo
check("the example registers its window for reruns", first ~= nil)
local titles = {}
for _, tab in first.tabs do
	table.insert(titles, tab.title)
end
check("four tabs, settings last", table.concat(titles, ",") == "Player,Visuals,Elements,Settings", table.concat(titles, ","))

first.Flags.WalkSpeed:Set(40)
check("walk speed reaches the humanoid", world.player.Character.Humanoid.WalkSpeed == 40)
local body = world.respawn(world.player)
check("walk speed is applied again after respawn", body.Humanoid.WalkSpeed == 40)
first.Flags.FieldOfView:Set(90)
check("field of view reaches the camera", world.camera.FieldOfView == 90)
first.Flags.Highlight:Set(true)
local glow = world.workspace:FindFirstChildOfClass("Highlight")
check("highlight outlines the current body", glow ~= nil and glow.Adornee == body and glow.Enabled == true)
first.Flags.OutlineDepth:Set("Only when visible")
check("depth choice maps to Occluded", glow ~= nil and glow.DepthMode == Enum.HighlightDepthMode.Occluded)

runExample()
local second = world.genv.HubKitDemo
check("a rerun unloads the first window", first.gui.Parent == nil and second ~= first)
check("the first unload restored walk speed", body.Humanoid.WalkSpeed == 16)
check("the first unload restored the field of view", world.camera.FieldOfView == 70)
check("the first unload removed its highlight", glow.Parent == nil)

second:Unload()
check("unload clears the rerun handle", world.genv.HubKitDemo == nil)

print(string.format("%d passed, %d failed", pass, fail))
if fail > 0 then
	error(string.format("%d assertion(s) failed", fail))
end
