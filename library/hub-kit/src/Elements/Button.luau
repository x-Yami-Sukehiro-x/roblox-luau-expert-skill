--[[
	Button - a whole row that runs its Callback once per press.

	    Tab:Button({ Title = "Rejoin server", Description = "Same place, new server", Callback = rejoin })

	The chevron marks the row as something to press, since the row itself looks
	like every other row until the pointer or selection reaches it.
--]]

local Icons = require(script.Parent.Parent.Core.Icons)
local New = require(script.Parent.Parent.Core.New)
local Row = require(script.Parent.Row)

local Button = {}

function Button.new(container: any, options: { [string]: any })
	assert(type(options.Callback) == "function", "Button needs a Callback function")
	local row = Row.button(container, options)

	New("ImageLabel", {
		Name = "Chevron",
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve(options.Icon or "chevron-right"),
		Theme = { ImageColor3 = "textMuted" },
	}, row.slot)

	row.trove:connect(row.frame.Activated, function()
		options.Callback()
	end)

	function row:Press()
		options.Callback()
	end

	return row
end

return Button
