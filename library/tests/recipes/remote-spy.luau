local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local realPrint = print
local lines = {}
print = function(...)
	local parts = {}
	for index = 1, select("#", ...) do parts[index] = tostring((select(index, ...))) end
	table.insert(lines, table.concat(parts, " "))
end
typeof = function(value)
	if type(value) == "table" and getmetatable(value) ~= nil and value.ClassName ~= nil then return "Instance" end
	return type(value)
end

local installs, dispatch, method, ours = 0, nil, "FireServer", false
hookmetamethod = function(_, name, hook)
	installs += 1
	check("hooks __namecall on game", name == "__namecall")
	dispatch = hook
	return function(_, ...) return "forwarded", ... end
end
getnamecallmethod = function() return method end
checkcaller = function() return ours end
newcclosure = function(fn) return fn end
local genv = {}
getgenv = function() return genv end

local function remote(className, path)
	local object = Instance.new(className)
	object.Name = string.match(path, "[^.]+$")
	object.GetFullName = function() return path end
	return object
end
local collect = remote("RemoteEvent", "ReplicatedStorage.Remotes.Collect")
local buy = remote("RemoteFunction", "ReplicatedStorage.Remotes.BuyItem")
local sword = remote("Tool", "ReplicatedStorage.Items.Sword")

local function call(target, name, ...)
	method = name
	return dispatch(target, ...)
end
local function reports()
	local count = 0
	for _, line in lines do if string.find(line, "^remote spy:") then count += 1 end end
	return count
end

__recipe()
check("installs one hook", installs == 1)

local first, second = call(collect, "FireServer", "Coin_12", 5, { Id = 1 })
check("forwards the game's call and its returns unchanged", first == "forwarded" and second == "Coin_12")
ours = true
call(collect, "FireServer", "from the executor")
ours = false
call(collect, "GetChildren")
call(buy, "InvokeServer", sword)

HARNESS.drain()
check("reports once when the window ends", reports() == 1)
check("counts only the game's remote calls", lines[1] == "remote spy: 2 call(s) in 0 s, 0 past the 50 limit")
check("lists the method, path and argument shapes", string.find(lines[2], 'FireServer  ReplicatedStorage.Remotes.Collect  ("Coin_12", 5, {Id: number})', 1, true) ~= nil)
check("describes an Instance argument by class and path", string.find(lines[3], "InvokeServer  ReplicatedStorage.Remotes.BuyItem  (Tool ReplicatedStorage.Items.Sword)", 1, true) ~= nil)

local after = #lines
local forwarded = call(collect, "FireServer", "late")
check("after the window the hook still forwards and records nothing", forwarded == "forwarded" and genv.RemoteSpy.record == nil and #lines == after)

lines = {}
__recipe()
check("a rerun reuses the installed hook", installs == 1)
for index = 1, 51 do call(collect, "FireServer", index) end
HARNESS.drain()
check("stops recording at the limit and says how many it dropped", lines[1] == "remote spy: 50 call(s) in 0 s, 1 past the 50 limit")

lines = {}
__recipe()
call(collect, "FireServer", "first window")
__recipe()
check("a rerun during a window reports that window first", reports() == 1 and string.find(lines[1], "1 call(s)", 1, true) ~= nil)
HARNESS.drain()
check("and the old window's timer does not report again", reports() == 2)

print = realPrint
local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
