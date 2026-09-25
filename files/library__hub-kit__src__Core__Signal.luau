--[[
	Signal - the Changed event on every element handle.

	Each listener runs in its own thread, so a hub callback that errors prints
	its own traceback and the listeners after it still run.
--]]

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Connected: boolean,
	Disconnect: (Connection) -> (),
}

function Signal.new()
	return setmetatable({ listeners = {} }, Signal)
end

function Signal:Connect(listener: (...any) -> ()): Connection
	local listeners = self.listeners
	table.insert(listeners, listener)

	local connection = { Connected = true }
	function connection.Disconnect()
		if not connection.Connected then
			return
		end
		connection.Connected = false
		local index = table.find(listeners, listener)
		if index then
			table.remove(listeners, index)
		end
	end
	return connection
end

function Signal:Fire(...: any)
	for _, listener in table.clone(self.listeners) do
		task.spawn(listener, ...)
	end
end

function Signal:Destroy()
	table.clear(self.listeners)
end

return Signal
