local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local load = __recipe()
local log = {}

local games = {
	[111] = { name = "Obby", start = function(session)
		table.insert(log, "obby")
		session:own(function() table.insert(log, "stop obby A") end)
		session:own(function() table.insert(log, "stop obby B") end)
	end },
}
local universal = { name = "Universal", start = function(session)
	table.insert(log, "universal")
	session:own(function() table.insert(log, "stop universal") end)
end }

game.GameId = 111
local first = load("TestHub", games, universal)
check("routes by GameId", first.gameName == "Obby" and log[1] == "obby")
check("registers the session in getgenv", world.genv.TestHub == first)

game.GameId = 999
local second = load("TestHub", games, universal)
check("a rerun unloads the previous session first, newest cleanup first", log[2] == "stop obby B" and log[3] == "stop obby A" and log[4] == "universal")
check("an unknown game gets the universal entry", second.gameName == "Universal" and first.unloaded == true)

second:unload()
second:unload()
check("unload runs each cleanup once and clears the handle", #log == 5 and world.genv.TestHub == nil)

local broken = { name = "Broken", start = function(session)
	session:own(function() table.insert(log, "stop broken") end)
	error("feature failed to start")
end }
local ok = pcall(load, "TestHub", {}, broken)
check("a start that errors is reported", ok == false)
check("and stays registered for the next run", world.genv.TestHub ~= nil)
load("TestHub", {}, universal)
check("so the next run cleans up its half-started features", log[6] == "stop broken")

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
