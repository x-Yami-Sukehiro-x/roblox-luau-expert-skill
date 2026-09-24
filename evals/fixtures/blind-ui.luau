local CLASSES = { "Frame", "TextLabel", "TextButton", "ScreenGui", "UICorner", "UIPadding" }

local function describe(names)
	local lines = {}
	for _, name in names do
		table.insert(lines, name)
	end
	return table.concat(lines, ", ")
end

return describe(CLASSES)
