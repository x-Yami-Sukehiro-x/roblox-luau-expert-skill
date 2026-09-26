-- lint: complete
-- Prints every game table holding all of KEYS, with its values, so a feature writes to
-- a table only after exactly one candidate is confirmed. Reads only.
local KEYS = { "SprintSpeed", "WalkSpeed" }
local FIELD_LIMIT = 12
local SCAN_LIMIT = 2000

local filtergc = filtergc
assert(filtergc, "needs filtergc")

local function shape(value: any): string
	local kind = typeof(value)
	if kind == "number" or kind == "boolean" then
		return tostring(value)
	elseif kind == "string" then
		return string.format("%q", string.sub(value, 1, 40))
	end
	return kind
end

-- rawget and next only: a game table's __index, __iter or __tostring never runs.
local function describe(candidate: { [any]: any }): (string, string)
	local fields = {}
	for _, key in KEYS do
		table.insert(fields, `{key} = {shape(rawget(candidate, key))}`)
	end
	local total = 0
	local key, value = next(candidate)
	while key ~= nil and total < SCAN_LIMIT do
		total += 1
		local listed = typeof(key) == "string" and table.find(KEYS, key) ~= nil
		if not listed and #fields < FIELD_LIMIT then
			local label = if typeof(key) == "string" then key else typeof(key)
			table.insert(fields, `{label} = {shape(value)}`)
		end
		key, value = next(candidate, key)
	end
	local counted = if key ~= nil then `{SCAN_LIMIT}+` else tostring(total)
	local traits = `{counted} field(s), frozen {table.isfrozen(candidate)}`
	return traits .. `, metatable {getmetatable(candidate) ~= nil}`, table.concat(fields, ", ")
end

local candidates = filtergc("table", { Keys = KEYS }, false)
print(`table finder: {#candidates} table(s) hold {table.concat(KEYS, ", ")}`)
for index, candidate in candidates do
	local traits, fields = describe(candidate)
	print(`  {index}. {traits}`)
	print(`     {fields}`)
end
if #candidates ~= 1 then
	print("a feature needs exactly one; add a key only the right table has, and run again")
end
