-- lint: complete
-- Fill KEYWORDS from dump_index.py's NOT FOUND line, run once in the game, and
-- send back the file it writes. It reads only; nothing in the game is changed.
local KEYWORDS = { "fly", "flight", "noclip" }
local REPORT_FILE = "feature-probe.txt"
local SECTION_LIMIT = 40
local DECOMPILE_LIMIT = 5
local SOURCE_CHARACTERS = 20000
local SEARCHED_SERVICES = {
	"ReplicatedStorage",
	"ReplicatedFirst",
	"Workspace",
	"StarterPlayer",
	"StarterGui",
	"Lighting",
}
local REMOTE_CLASSES = {
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
	BindableEvent = true,
	BindableFunction = true,
}

local Players = game:GetService("Players")

local getgc, getconstants, getinfo, writefile = getgc, debug.getconstants, debug.getinfo, writefile
assert(
	getgc and getconstants and getinfo and writefile,
	"needs getgc, debug.getconstants, debug.getinfo, writefile"
)

-- Optional sections: a missing one is written into the report as missing.
local decompile, getscripthash = decompile, getscripthash

local report: { string } = {}
local function add(line: string)
	table.insert(report, line)
end

local function keywordIn(text: string): string?
	local lower = string.lower(text)
	for _, keyword in KEYWORDS do
		if string.find(lower, keyword, 1, true) then
			return keyword
		end
	end
	return nil
end

local player = Players.LocalPlayer
local roots: { Instance } = { player }
for _, name in SEARCHED_SERVICES do
	table.insert(roots, game:GetService(name))
end

local instances: { Instance } = {}
for _, root in roots do
	for _, descendant in root:GetDescendants() do
		table.insert(instances, descendant)
	end
end

add(`feature probe  PlaceId {game.PlaceId}  keywords: {table.concat(KEYWORDS, ", ")}`)
add(`searched {#instances} instances under {table.concat(SEARCHED_SERVICES, ", ")} and the player`)

-- Every remote is listed, because game remotes are often named for the system
-- ("Network", "Event") rather than the feature; matches are starred.
add("")
add("== remotes (* = name or path matches a keyword)")
local remoteCount = 0
for _, instance in instances do
	if REMOTE_CLASSES[instance.ClassName] then
		remoteCount += 1
		if remoteCount <= SECTION_LIMIT * 3 then
			local star = if keywordIn(instance:GetFullName()) then "*" else " "
			add(`{star} {instance.ClassName}  {instance:GetFullName()}`)
		end
	end
end
add(`{remoteCount} remote(s)`)

add("")
add("== scripts whose name or path matches")
local matchedScripts: { LuaSourceContainer } = {}
for _, instance in instances do
	if instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
		if keywordIn(instance:GetFullName()) and #matchedScripts < SECTION_LIMIT then
			table.insert(matchedScripts, instance :: LuaSourceContainer)
			local hash = if getscripthash then getscripthash(instance) else "hash unavailable"
			add(`  {instance.ClassName}  {instance:GetFullName()}  {hash}`)
		end
	end
end

-- Constants survive decompilation failures and renamed locals, so a closure
-- whose constants mention the feature is the strongest lead a probe can give.
add("")
add("== functions whose constants mention a keyword")
local closureCount = 0
for _, value in getgc() do
	if closureCount >= SECTION_LIMIT or type(value) ~= "function" then
		continue
	end
	local origin = getinfo(value)
	if origin.what ~= "Lua" then
		continue
	end
	local ok, constants = pcall(getconstants, value)
	if not ok then
		continue
	end

	local named: { string } = {}
	local numbers: { string } = {}
	for _, constant in constants do
		if type(constant) == "string" and keywordIn(constant) then
			table.insert(named, constant)
		elseif type(constant) == "number" and #numbers < 8 then
			table.insert(numbers, tostring(constant))
		end
	end

	if #named > 0 then
		closureCount += 1
		local name = if origin.name and origin.name ~= "" then origin.name else "(anonymous)"
		add(`  {origin.short_src}:{origin.currentline}  {name}`)
		add(`    params {origin.numparams}  upvalues {origin.nups}`)
		add(`    strings: {table.concat(named, ", ")}`)
		add(`    numbers: {table.concat(numbers, ", ")}`)
	end
end
add(`{closureCount} matching function(s)`)

-- `next` reads raw keys, so a table's __iter or __index cannot run game code.
add("")
add("== tables with a matching key")
local tableCount = 0
for _, value in getgc(true) do
	if tableCount >= SECTION_LIMIT or type(value) ~= "table" then
		continue
	end
	local fields: { string } = {}
	for key, field in next, value do
		if type(key) == "string" and keywordIn(key) and #fields < 12 then
			local shown = if type(field) == "table" then "{...}" else tostring(field)
			table.insert(fields, `{key} = {shown}`)
		end
	end
	if #fields > 0 then
		tableCount += 1
		add(`  {table.concat(fields, "; ")}`)
	end
end
add(`{tableCount} matching table(s)`)

add("")
add("== player state")
for key, value in player:GetAttributes() do
	add(`  attribute {key} = {tostring(value)}`)
end
local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
	for _, stat in leaderstats:GetChildren() do
		if stat:IsA("ValueBase") then
			add(`  leaderstat {stat.Name} = {tostring((stat :: any).Value)}`)
		end
	end
end
local character = player.Character
local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
if character and humanoid then
	add(`  WalkSpeed {humanoid.WalkSpeed}  JumpPower {humanoid.JumpPower}`)
	add(`  Health {humanoid.Health}  MaxHealth {humanoid.MaxHealth}`)
	for key, value in character:GetAttributes() do
		add(`  character attribute {key} = {tostring(value)}`)
	end
end

add("")
if decompile then
	add("== decompiled sources of matching scripts")
	for index, script in matchedScripts do
		if index > DECOMPILE_LIMIT then
			break
		end
		local ok, source = pcall(decompile, script)
		add(`-- {script:GetFullName()}`)
		add(if ok then string.sub(source, 1, SOURCE_CHARACTERS) else `decompile failed: {source}`)
	end
else
	add("== decompile unavailable in this executor; send the lists above")
end

writefile(REPORT_FILE, table.concat(report, "\n"))
print(`feature probe: {#report} lines written to {REPORT_FILE} in the executor workspace`)
