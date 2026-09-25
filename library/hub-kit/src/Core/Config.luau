--[[
	Config - named saves of every flagged element, as JSON files under
	HubKit/<folder>/ in the executor's workspace folder.

	File access is an executor feature, so it is detected once. Without it
	`save`, `load` and `delete` return false and a sentence the hub can show
	the player; they never pretend to succeed.

	Values pass through each element's own `Encode` and `Decode`, so a
	Color3 is saved as a hex string and a KeyCode by name, and an old config
	that names a flag the hub no longer has is skipped rather than an error.
--]]

local HttpService = game:GetService("HttpService")

local writefile, readfile, isfile = writefile, readfile, isfile
local isfolder, makefolder, listfiles, delfile = isfolder, makefolder, listfiles, delfile
local HAS_FILES = typeof(writefile) == "function"
	and typeof(readfile) == "function"
	and typeof(isfile) == "function"
	and typeof(isfolder) == "function"
	and typeof(makefolder) == "function"
	and typeof(listfiles) == "function"
	and typeof(delfile) == "function"

local NO_FILES = "Saving needs an executor with file access (writefile)"
local ROOT = "HubKit"
local AUTOLOAD = "autoload.txt"

local Config = {}
Config.__index = Config
Config.available = HAS_FILES

local function validName(name: string): boolean
	return type(name) == "string"
		and #name > 0
		and #name <= 32
		and string.find(name, "^[%w _%-]+$") ~= nil
end

function Config.new(folder: string)
	assert(validName(folder), "config folder must be letters, digits, space, - or _")
	return setmetatable({ folder = `{ROOT}/{folder}`, flags = {} }, Config)
end

function Config:register(flag: string, element: any)
	if self.flags[flag] then
		error(`flag {flag} is already registered`, 3)
	end
	self.flags[flag] = element
end

function Config:unregister(flag: string)
	self.flags[flag] = nil
end

function Config:snapshot(): { [string]: any }
	local values = {}
	for flag, element in self.flags do
		local value = element:Get()
		values[flag] = if element.Encode then element.Encode(value) else value
	end
	return values
end

function Config:apply(values: { [string]: any }): number
	local applied = 0
	for flag, raw in values do
		local element = self.flags[flag]
		if element then
			element:Set(if element.Decode then element.Decode(raw) else raw)
			applied += 1
		end
	end
	return applied
end

function Config:ensureFolder()
	if not isfolder(ROOT) then
		makefolder(ROOT)
	end
	if not isfolder(self.folder) then
		makefolder(self.folder)
	end
end

function Config:path(name: string): string
	return `{self.folder}/{name}.json`
end

function Config:save(name: string): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	if not validName(name) then
		return false, "Config names use letters, digits, spaces, - and _"
	end
	self:ensureFolder()
	writefile(self:path(name), HttpService:JSONEncode(self:snapshot()))
	return true, `Saved {name}`
end

function Config:load(name: string): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	local path = self:path(name)
	if not validName(name) or not isfile(path) then
		return false, `No saved config named {name}`
	end
	local ok, values = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	if not ok or type(values) ~= "table" then
		return false, `{name} is not a readable config file`
	end
	return true, `Loaded {name} ({self:apply(values)} settings)`
end

function Config:delete(name: string): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	local path = self:path(name)
	if not validName(name) or not isfile(path) then
		return false, `No saved config named {name}`
	end
	delfile(path)
	return true, `Deleted {name}`
end

function Config:list(): { string }
	if not HAS_FILES or not isfolder(self.folder) then
		return {}
	end
	local names = {}
	for _, path in listfiles(self.folder) do
		-- Executors disagree on the separator listfiles returns.
		local name = string.match(path, "([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

function Config:setAutoload(name: string?): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	self:ensureFolder()
	writefile(`{self.folder}/{AUTOLOAD}`, name or "")
	return true, if name then `{name} loads on start` else "Nothing loads on start"
end

function Config:autoload(): (boolean, string)
	local path = `{self.folder}/{AUTOLOAD}`
	if not HAS_FILES or not isfile(path) then
		return false, "No autoload config"
	end
	local name = readfile(path)
	if name == "" then
		return false, "No autoload config"
	end
	return self:load(name)
end

return Config
