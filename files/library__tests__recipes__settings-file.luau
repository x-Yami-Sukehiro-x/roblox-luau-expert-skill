local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

-- JSON stand-in: encoding keeps a copy under a token, decoding returns it, and any
-- other text is malformed, which is all the store's logic depends on.
local encoded = {}
HARNESS.services.HttpService = {
	JSONEncode = function(_, value)
		local token = "json:" .. (#encoded + 1)
		encoded[#encoded + 1] = table.clone(value)
		return token
	end,
	JSONDecode = function(_, text)
		local index = tonumber(string.match(text, "^json:(%d+)$"))
		if index == nil then error("Can't parse JSON") end
		return table.clone(encoded[index])
	end,
}

local disk, folders, failWrites = {}, {}, false
local function withFiles()
	readfile = function(path) return disk[path] end
	writefile = function(path, text)
		if failWrites then error("disk full") end
		disk[path] = text
	end
	isfile = function(path) return disk[path] ~= nil end
	isfolder = function(path) return folders[path] == true end
	makefolder = function(path) folders[path] = true end
end

local DEFAULTS = { walkSpeed = 32, autoFarm = false, farmKey = "F" }
withFiles()
local create = __recipe()

local fresh = create("PetHub", "settings", DEFAULTS)
check("a first run starts from the defaults", fresh.values.walkSpeed == 32 and fresh.values.farmKey == "F")
check("with file access the settings are persistent", fresh.persistent == true)
fresh.values.walkSpeed = 50
check("save creates the folder and reports success", fresh.save() == true and folders.PetHub == true)
check("and writes the current values", encoded[#encoded].walkSpeed == 50)
check("defaults are copied, not shared", DEFAULTS.walkSpeed == 32)

encoded[#encoded + 1] = { walkSpeed = "fast", autoFarm = true, removedOption = 3 }
disk["PetHub/settings.json"] = "json:" .. #encoded
local loaded = create("PetHub", "settings", DEFAULTS)
check("a stored value of the right type is kept", loaded.values.autoFarm == true)
check("a stored value of the wrong type falls back to its default", loaded.values.walkSpeed == 32)
check("an option the script no longer has is ignored", loaded.values.removedOption == nil)

disk["PetHub/settings.json"] = "{ not json"
local broken = create("PetHub", "settings", DEFAULTS)
check("an unreadable file gives the defaults", broken.values.walkSpeed == 32)
check("and is kept as a copy before anything overwrites it", disk["PetHub/settings.unreadable.json"] == "{ not json")

failWrites = true
check("a failed write is reported, never claimed as saved", broken.save() == false)
failWrites = false

-- The script binds the file functions when it runs, so this case runs it again.
readfile, writefile, isfile, isfolder, makefolder = nil, nil, nil, nil, nil
local session = __recipe()("PetHub", "settings", DEFAULTS)
check("without file access the settings are session-only and say so", session.persistent == false and session.values.walkSpeed == 32)
check("and save reports that nothing was written", session.save() == false)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
