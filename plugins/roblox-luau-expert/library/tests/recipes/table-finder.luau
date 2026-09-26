local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local realPrint = print
local lines = {}
print = function(text) table.insert(lines, tostring(text)) end

local config = { SprintSpeed = 24, WalkSpeed = 16, Stamina = 100, Name = "Sprint" }
local hostile = setmetatable({ SprintSpeed = 30, WalkSpeed = 16 }, {
	__index = function() error("probe ran game code") end,
	__iter = function() error("probe ran game code") end,
	__tostring = function() error("probe ran game code") end,
})
local frozen = table.freeze({ SprintSpeed = 24, WalkSpeed = 16 })
local matches = { config }
local seenKeys
filtergc = function(kind, options, returnOne)
	check("asks for tables holding the configured keys, all matches", kind == "table" and returnOne == false)
	seenKeys = options.Keys
	return matches
end

__recipe()
check("searches by every key", seenKeys[1] == "SprintSpeed" and seenKeys[2] == "WalkSpeed")
check("reports the count and the keys", lines[1] == "table finder: 1 table(s) hold SprintSpeed, WalkSpeed")
check("lists the searched keys first with their values", string.find(lines[3], "SprintSpeed = 24, WalkSpeed = 16", 1, true) == 6)
check("then the table's other fields", string.find(lines[3], "Stamina = 100", 1, true) ~= nil and string.find(lines[3], 'Name = "Sprint"', 1, true) ~= nil)
check("counts the fields and notes frozen and metatable", lines[2] == "  1. 4 field(s), frozen false, metatable false")
check("one match needs no advice", #lines == 3)

lines = {}
matches = { frozen, hostile }
local ran = pcall(__recipe)
check("never runs a game table's metamethods", ran)
check("says when there is not exactly one", lines[#lines] == "a feature needs exactly one; add a key only the right table has, and run again")
check("marks a frozen table", string.find(lines[2], "frozen true", 1, true) ~= nil)
check("and one with a metatable", string.find(lines[4], "metatable true", 1, true) ~= nil)

lines = {}
local big = { SprintSpeed = 1, WalkSpeed = 2 }
for index = 1, 2500 do big[index] = index end
matches = { big }
__recipe()
check("stops counting a huge table at the scan limit", string.find(lines[2], "2000+ field(s)", 1, true) ~= nil)

print = realPrint
local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
