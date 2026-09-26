--!strict
-- Two features writing the same property undo each other, so each declares what it
-- owns and a second owner is refused when it registers, not found later in a game.
export type Status = "off" | "on" | "failed"

export type FeatureSpec = {
	owns: { string },
	start: () -> (),
	stop: () -> (),
}

export type Registry = {
	add: (name: string, feature: FeatureSpec) -> (),
	set: (name: string, on: boolean) -> (),
	status: (name: string) -> (Status, string?),
	unload: () -> (),
}

return function(onChange: ((name: string, status: Status, reason: string?) -> ())?): Registry
	local features: { [string]: FeatureSpec } = {}
	local order: { string } = {}
	local owners: { [string]: string } = {}
	local statuses: { [string]: Status } = {}
	local reasons: { [string]: string } = {}

	local function report(name: string, status: Status, reason: string?)
		statuses[name] = status
		reasons[name] = reason
		if onChange then
			onChange(name, status, reason)
		end
	end

	local function add(name: string, feature: FeatureSpec)
		assert(features[name] == nil, `feature {name} is already registered`)
		for _, property in feature.owns do
			local owner = owners[property]
			assert(owner == nil, `{name} and {owner} both own {property}`)
		end
		for _, property in feature.owns do
			owners[property] = name
		end
		features[name] = feature
		table.insert(order, name)
		statuses[name] = "off"
	end

	-- A start reads the game's current structure, which an update can move. The
	-- broken feature reports why and stops what it began; the others keep working.
	local function set(name: string, on: boolean)
		local feature = features[name]
		assert(feature, `unknown feature {name}`)
		if on == (statuses[name] == "on") then
			return
		end
		if not on then
			feature.stop()
			report(name, "off")
			return
		end
		local started, problem = pcall(feature.start)
		if started then
			report(name, "on")
		else
			feature.stop()
			report(name, "failed", tostring(problem))
		end
	end

	local function status(name: string): (Status, string?)
		return statuses[name], reasons[name]
	end

	-- Newest first: a feature added later may lean on one added earlier.
	local function unload()
		for index = #order, 1, -1 do
			local name = order[index]
			if statuses[name] == "on" then
				features[name].stop()
				report(name, "off")
			end
		end
	end

	return {
		add = add,
		set = set,
		status = status,
		unload = unload,
	}
end
