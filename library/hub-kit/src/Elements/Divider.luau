--[[
	Divider - a 1 px rule between groups of rows that do not need a Section.

	It takes the stroke colour, one step above the rows around it, so it
	separates without competing with the rows' own edges.
--]]

local New = require(script.Parent.Parent.Core.New)

local Divider = {}

function Divider.new(container: any)
	local trove = container.trove:extend()
	local line = New("Frame", {
		Name = "Divider",
		LayoutOrder = container:nextOrder(),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "stroke" },
	}, container.frame)
	trove:add(line)

	return {
		Frame = line,
		trove = trove,
		Destroy = function()
			trove:clean()
		end,
	}
end

return Divider
