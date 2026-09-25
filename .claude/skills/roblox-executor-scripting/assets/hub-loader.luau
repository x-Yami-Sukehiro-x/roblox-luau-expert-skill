--!strict
-- Routes a multi-game hub by game.GameId, which every place of one experience shares,
-- and makes a rerun unload the previous session before the new one starts.
local getgenv = getgenv
assert(typeof(getgenv) == "function", "hub-loader needs getgenv")

export type Session = {
	name: string,
	gameName: string,
	unloaded: boolean,
	own: (self: Session, cleanup: () -> ()) -> (),
	unload: (self: Session) -> (),
}

export type GameEntry = {
	name: string,
	start: (session: Session) -> (),
}

return function(hubName: string, games: { [number]: GameEntry }, universal: GameEntry): Session
	local env = getgenv()
	local previous = env[hubName]
	if previous then
		previous:unload()
	end

	local entry = games[game.GameId] or universal
	local cleanups: { () -> () } = {}
	local session = { name = hubName, gameName = entry.name, unloaded = false }

	function session:own(cleanup: () -> ())
		table.insert(cleanups, cleanup)
	end

	-- Newest first: a feature started later may depend on one started earlier.
	function session:unload()
		if self.unloaded then
			return
		end
		self.unloaded = true
		for index = #cleanups, 1, -1 do
			cleanups[index]()
		end
		table.clear(cleanups)
		if env[hubName] == self then
			env[hubName] = nil
		end
	end

	-- Registered before start runs, so a start that errors halfway is still
	-- unloaded by the next run instead of leaving its first features behind.
	env[hubName] = session
	entry.start(session :: any)
	return session :: any
end
