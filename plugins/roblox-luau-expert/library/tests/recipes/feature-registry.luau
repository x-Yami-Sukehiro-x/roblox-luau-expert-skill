local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local changes = {}
local registry = __recipe()(function(name, status, reason)
	table.insert(changes, { name = name, status = status, reason = reason })
end)
local log = {}

local function feature(name, owns, options)
	options = options or {}
	return {
		owns = owns,
		start = function()
			table.insert(log, "start " .. name)
			if options.broken then error("Remotes.Collect is missing") end
		end,
		stop = function() table.insert(log, "stop " .. name) end,
	}
end

registry.add("Speed", feature("Speed", { "Humanoid.WalkSpeed" }))
registry.add("Fullbright", feature("Fullbright", { "Lighting.Ambient" }))
registry.add("AutoCollect", feature("AutoCollect", {}, { broken = true }))

local refused, message = pcall(registry.add, "Sprint", feature("Sprint", { "Humanoid.WalkSpeed" }))
check("a second owner of one property is refused and both are named", not refused and string.find(message, "Sprint and Speed both own Humanoid.WalkSpeed", 1, true) ~= nil)
check("the refused feature is not registered", select(1, pcall(registry.set, "Sprint", true)) == false)

registry.set("Speed", true)
registry.set("Speed", true)
check("turning a feature on twice starts it once", #log == 1 and log[1] == "start Speed")
check("status reports on and the change is announced", registry.status("Speed") == "on" and changes[1].status == "on")

registry.set("AutoCollect", true)
local status, reason = registry.status("AutoCollect")
check("a start that errors is reported as failed with the reason", status == "failed" and string.find(reason, "Remotes.Collect is missing", 1, true) ~= nil)
check("and what it began is stopped", log[#log] == "stop AutoCollect")
check("other features keep running", registry.status("Speed") == "on")

local before = #log
registry.set("AutoCollect", false)
check("turning a failed feature off does not stop it twice", #log == before and registry.status("AutoCollect") == "failed")

registry.set("Fullbright", true)
before = #log
registry.unload()
check("unload stops running features newest first", log[before + 1] == "stop Fullbright" and log[before + 2] == "stop Speed" and #log == before + 2)
check("every status is off or failed after unload", registry.status("Speed") == "off" and registry.status("Fullbright") == "off")

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
