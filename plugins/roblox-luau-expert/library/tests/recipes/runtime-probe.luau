local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local function node(className, name, parentPath, children)
	local self = { ClassName = className, Name = name, children = children or {} }
	self.path = parentPath .. "." .. name
	function self:GetFullName() return self.path end
	function self:GetChildren() return self.children end
	function self:IsA(class) return self.ClassName == class or (class == "ValueBase" and className:match("Value$") ~= nil) end
	function self:GetDescendants()
		local all = {}
		local function walk(item)
			for _, child in item.children do
				table.insert(all, child)
				walk(child)
			end
		end
		walk(self)
		return all
	end
	function self:GetAttributes() return self.attributes or {} end
	function self:FindFirstChild(childName) for _, child in self.children do if child.Name == childName then return child end end return nil end
	function self:FindFirstChildOfClass(class) for _, child in self.children do if child.ClassName == class then return child end end return nil end
	return self
end

local flyScript = node("LocalScript", "FlyController", "ReplicatedFirst")
local remotes = node("Folder", "Remotes", "ReplicatedStorage", {
	node("RemoteEvent", "ToggleFlight", "ReplicatedStorage.Remotes"),
	node("RemoteEvent", "Network", "ReplicatedStorage.Remotes"),
})
local services = {
	ReplicatedStorage = node("ReplicatedStorage", "ReplicatedStorage", "game", { remotes }),
	ReplicatedFirst = node("ReplicatedFirst", "ReplicatedFirst", "game", { flyScript }),
	Workspace = node("Workspace", "Workspace", "game"),
	StarterPlayer = node("StarterPlayer", "StarterPlayer", "game"),
	StarterGui = node("StarterGui", "StarterGui", "game"),
	Lighting = node("Lighting", "Lighting", "game"),
}
local humanoid = node("Humanoid", "Humanoid", "Workspace.Player")
humanoid.WalkSpeed, humanoid.JumpPower, humanoid.Health, humanoid.MaxHealth = 16, 50, 100, 100
local character = node("Model", "Player", "Workspace", { humanoid })
local player = node("Player", "Player", "Players", { node("Folder", "leaderstats", "Players.Player", { node("IntValue", "Coins", "Players.Player.leaderstats") }) })
player.children[1].children[1].Value = 250
player.attributes = { FlightUnlocked = true }
player.Character = character
services.Players = { LocalPlayer = player }
game = { PlaceId = 4242, GetService = function(_, name) return services[name] end }

local function flyHandler() end
local function unrelated() end
local constantsOf = {
	[flyHandler] = { "FlySpeed", "BodyGyro", 80, 0.5 },
	[unrelated] = { "Coins", 1 },
}
getgc = function(includeTables)
	local list = { flyHandler, unrelated, print }
	if includeTables then
		table.insert(list, { FlySpeed = 80, NoclipEnabled = false, Other = 1 })
		table.insert(list, setmetatable({ Name = "x" }, { __index = function() error("probe ran game code") end }))
	end
	return list
end
debug = {
	getinfo = function(fn)
		if fn == print then return { what = "C" } end
		return { what = "Lua", short_src = "ReplicatedFirst.FlyController", currentline = 12, name = fn == flyHandler and "startFlight" or "", numparams = 1, nups = 2 }
	end,
	getconstants = function(fn) return constantsOf[fn] or {} end,
}
local written = {}
writefile = function(path, contents) written[path] = contents end
decompile = function(script) return "-- source of " .. script.Name end
getscripthash = function() return "abc123" end

__recipe()

local report = written["feature-probe.txt"]
check("probe writes its report", report ~= nil)
report = report or ""
check("lists every remote and stars the match", report:find("%* RemoteEvent  ReplicatedStorage.Remotes.ToggleFlight") ~= nil and report:find("  RemoteEvent  ReplicatedStorage.Remotes.Network", 1, true) ~= nil)
check("finds the matching script with its hash", report:find("ReplicatedFirst.FlyController  abc123", 1, true) ~= nil)
check("finds the closure by its constants", report:find("startFlight", 1, true) ~= nil and report:find("strings: FlySpeed", 1, true) ~= nil and report:find("numbers: 80, 0.5", 1, true) ~= nil)
check("skips functions without a matching constant", select(2, report:gsub("params 1", "")) == 1)
check("finds tables by key without running metamethods", report:find("FlySpeed = 80", 1, true) ~= nil)
check("reports player state", report:find("attribute FlightUnlocked = true", 1, true) ~= nil and report:find("leaderstat Coins = 250", 1, true) ~= nil and report:find("WalkSpeed 16", 1, true) ~= nil and report:find("MaxHealth 100", 1, true) ~= nil)
check("includes decompiled source of matching scripts", report:find("-- source of FlyController", 1, true) ~= nil)

written = {}
decompile = nil
getscripthash = nil
__recipe()
report = written["feature-probe.txt"] or ""
check("names a missing decompile instead of skipping silently", report:find("decompile unavailable", 1, true) ~= nil)
check("names a missing script hash", report:find("hash unavailable", 1, true) ~= nil)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
