--!strict
-- Settings for a script without a hub library: one JSON file in the executor's
-- workspace folder. Each stored value must match its default's type, so a stale or
-- hand-edited file falls back per field instead of breaking the script.
local HttpService = game:GetService("HttpService")

-- Optional: without file access the settings last for this session, and
-- `persistent` says so, so the window can tell the player once.
local readfile, writefile, isfile = readfile, writefile, isfile
local isfolder, makefolder = isfolder, makefolder

export type Settings = {
	values: { [string]: any },
	persistent: boolean,
	save: () -> boolean,
}

return function(folder: string, name: string, defaults: { [string]: any }): Settings
	local persistent = readfile ~= nil
		and writefile ~= nil
		and isfile ~= nil
		and isfolder ~= nil
		and makefolder ~= nil
	local path = `{folder}/{name}.json`
	local values = table.clone(defaults)

	if persistent and isfile(path) then
		local text = readfile(path)
		local decoded, stored = pcall(HttpService.JSONDecode, HttpService, text)
		if decoded and type(stored) == "table" then
			for key, default in defaults do
				if typeof(stored[key]) == typeof(default) then
					values[key] = stored[key]
				end
			end
		else
			-- The next save replaces the file; this copy is the player's way back.
			writefile(`{folder}/{name}.unreadable.json`, text)
		end
	end

	-- A write is a filesystem boundary; "saved" is reported only when it succeeded.
	local function save(): boolean
		if not persistent then
			return false
		end
		local written = pcall(function()
			if not isfolder(folder) then
				makefolder(folder)
			end
			writefile(path, HttpService:JSONEncode(values))
		end)
		return written
	end

	return {
		values = values,
		persistent = persistent,
		save = save,
	}
end
