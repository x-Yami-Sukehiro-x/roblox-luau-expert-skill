--[[
	Trove - owns what a window, element or popup creates, so one `clean` call
	removes all of it: connections, instances, threads, Signals, nested troves
	and plain cleanup functions.

	Items are released newest first. A later item usually depends on an earlier
	one (a connection on a frame the trove also destroys), and releasing in
	reverse never touches something already gone.
--]]

local Trove = {}
Trove.__index = Trove

local function release(item: any)
	local kind = typeof(item)
	if kind == "function" then
		item()
	elseif kind == "thread" then
		task.cancel(item)
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif item.Disconnect then
		item:Disconnect()
	else
		item:Destroy()
	end
end

function Trove.new()
	return setmetatable({ items = {} }, Trove)
end

function Trove:add<T>(item: T): T
	table.insert(self.items, item)
	return item
end

function Trove:connect(signal: any, listener: (...any) -> ()): any
	return self:add(signal:Connect(listener))
end

-- A child trove is cleaned with its parent, or on its own when the thing it
-- owns (one element, one popup) goes away first.
function Trove:extend()
	local child = Trove.new()
	self:add(child)
	return child
end

function Trove:clean()
	local items = self.items
	self.items = {}
	for index = #items, 1, -1 do
		release(items[index])
	end
end

Trove.Destroy = Trove.clean

return Trove
