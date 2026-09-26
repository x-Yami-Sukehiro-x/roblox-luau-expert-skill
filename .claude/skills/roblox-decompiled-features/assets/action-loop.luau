--!strict
-- Repeats one game action over its current targets. The interval is the game's own
-- cooldown from the source: going faster only buys requests the server refuses.
export type Options = {
	interval: number,
	targets: () -> { Instance },
	act: (target: Instance) -> (),
	ready: (() -> boolean)?,
}

export type Loop = {
	start: () -> (),
	stop: () -> (),
	running: () -> boolean,
	actions: () -> number,
}

return function(options: Options): Loop
	local generation = 0
	local worker: thread? = nil
	local actions = 0

	-- Each pass re-reads the targets, because the game adds and removes them, and
	-- re-checks the generation after every yield so a stopped loop acts no more.
	local function run(own: number)
		while generation == own do
			local acted = false
			if options.ready == nil or options.ready() then
				for _, target in options.targets() do
					if generation ~= own then
						return
					end
					if target.Parent ~= nil then
						options.act(target)
						actions += 1
						acted = true
						task.wait(options.interval)
					end
				end
			end
			if not acted and generation == own then
				task.wait(options.interval)
			end
		end
	end

	local function stop()
		generation += 1
		local current = worker
		worker = nil
		if current ~= nil and current ~= coroutine.running() then
			task.cancel(current)
		end
	end

	local function start()
		if worker ~= nil then
			return
		end
		generation += 1
		worker = task.spawn(run, generation)
	end

	return {
		start = start,
		stop = stop,
		running = function()
			return worker ~= nil
		end,
		actions = function()
			return actions
		end,
	}
end
