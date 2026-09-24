local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local hidden = Instance.new("Folder")
gethui = function() return hidden end
local red = { Name = "Red" }
local blue = { Name = "Blue" }
world.player.Team = red
local ally = world.join("Ally")
ally.Team = red
ally.Character.HumanoidRootPart.Position = Vector3.new(0, 0, 10)
local rival = world.join("Rival")
rival.Team = blue
rival.Character.HumanoidRootPart.Position = Vector3.new(0, 0, 40)

local function markersOf(className)
	local list = {}
	for _, child in hidden:GetChildren() do
		if child.ClassName == className then table.insert(list, child) end
	end
	return list
end
local function highlightOn(character)
	for _, highlight in markersOf("Highlight") do
		if highlight.Adornee == character and highlight.Enabled then return highlight end
	end
	return nil
end
local function tagOf(root)
	for _, tag in markersOf("BillboardGui") do
		if tag.Adornee == root then return tag end
	end
	return nil
end

__recipe()
local esp = world.genv.Features.Esp
check("one highlight and one tag per other player, none for me", #markersOf("Highlight") == 2 and #markersOf("BillboardGui") == 2)
local enemy = highlightOn(rival.Character)
local friend = highlightOn(ally.Character)
check("enemies are filled, teammates outlined only", enemy ~= nil and enemy.FillTransparency == 0.6 and friend ~= nil and friend.FillTransparency == 1)
check("friend and enemy colours differ", enemy.FillColor ~= friend.FillColor)
local tag = tagOf(rival.Character.HumanoidRootPart)
check("the tag names the player and the distance", tag ~= nil and tag.Enabled and tag.TextLabel.Text == "Rival  40 studs")

rival.Character.HumanoidRootPart.Position = Vector3.new(0, 0, 25)
HARNESS.heartbeat:Fire(0.1)
check("labels do not update every frame", tag.TextLabel.Text == "Rival  40 studs")
HARNESS.heartbeat:Fire(0.2)
check("they update four times a second", tag.TextLabel.Text == "Rival  25 studs")

local newcomer = world.join("Newcomer")
HARNESS.heartbeat:Fire(0.3)
check("a player who joins is marked", highlightOn(newcomer.Character) ~= nil)
world.leave(newcomer)
check("a player who leaves is cleaned up", #markersOf("Highlight") == 2)

local body = world.respawn(rival)
HARNESS.heartbeat:Fire(0.3)
check("a respawned player is marked on the new body", highlightOn(body) ~= nil and tagOf(body.HumanoidRootPart) ~= nil)

world.key(Enum.KeyCode.H)
check("H hides every marker", highlightOn(body) == nil and tagOf(body.HumanoidRootPart).Enabled == false)
world.key(Enum.KeyCode.H)

for index = 1, 33 do
	local crowd = world.join("Crowd" .. index)
	crowd.Character.HumanoidRootPart.Position = Vector3.new(0, 0, 100 + index)
end
HARNESS.heartbeat:Fire(0.3)
local lit = 0
for _, highlight in markersOf("Highlight") do
	if highlight.Enabled then lit += 1 end
end
check("never more than 31 highlights, nearest first", lit == 31 and highlightOn(ally.Character) ~= nil and highlightOn(body) ~= nil)

__recipe()
local again = world.genv.Features.Esp
check("running it again replaces the old markers", again ~= esp and esp.alive == false and #markersOf("Highlight") == 35)
again.unload()
again.unload()
check("unload removes every marker and connection", #hidden:GetChildren() == 0 and #HARNESS.heartbeat.handlers == 0)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
