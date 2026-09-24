--!strict
--[[
	Divider — a hairline, not a border.

	Explained in: roblox-ui-components/references/outlines-and-dividers.md

	Deliberate choices:
	  - 1px in OFFSET. A divider in scale becomes 3px on a large monitor and
	    invisible on a phone.
	  - Low contrast. A divider competing with body text is too strong.
	  - BorderSizePixel = 0, or you get a border on your border.
	  - Inset by default so it aligns with content rather than the container edge.

	Before using one, try spacing. A list with a line between every row reads as
	a table; group with space and use one divider between GROUPS.
--]]

local Tokens = require(script.Parent.Parent.Tokens)

local Divider = {}

export type Orientation = "horizontal" | "vertical"

--[[
	    local rule = Divider.new("horizontal", { inset = 16, layoutOrder = 3 })
	    rule.Parent = panel
--]]
function Divider.new(
	orientation: Orientation?,
	options: { inset: number?, layoutOrder: number?, transparency: number? }?
): Frame
	local axis: Orientation = orientation or "horizontal"
	local settings = options or {}
	local inset = settings.inset or 0

	local line = Instance.new("Frame")
	line.Name = "Divider"
	line.BackgroundColor3 = Tokens.stroke.subtle
	line.BackgroundTransparency = settings.transparency or 0.45
	line.BorderSizePixel = 0
	line.LayoutOrder = settings.layoutOrder or 0

	if axis == "horizontal" then
		line.Size = UDim2.new(1, -inset * 2, 0, 1)
		line.AnchorPoint = Vector2.new(0.5, 0)
		line.Position = UDim2.fromScale(0.5, 0)
	else
		line.Size = UDim2.new(0, 1, 1, -inset * 2)
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.Position = UDim2.fromScale(0, 0.5)
	end

	return line
end

--[[
	A labelled section break — a rule with a heading sitting in it.

	Usually better than a bare divider: a heading with weight does more grouping
	work than any line.
--]]
function Divider.labelled(text: string, layoutOrder: number?): Frame
	local holder = Instance.new("Frame")
	holder.Name = "SectionBreak"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 20)
	holder.LayoutOrder = layoutOrder or 0

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Tokens.space.snug)
	layout.Parent = holder

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.LayoutOrder = 0
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 20)
	label.FontFace = Tokens.font.emphasis
	label.TextSize = Tokens.text_size.caption
	label.TextColor3 = Tokens.text.muted
	label.Text = text
	label.Parent = holder

	local rule = Divider.new("horizontal")
	rule.LayoutOrder = 1
	rule.Size = UDim2.new(1, -(label.AbsoluteSize.X + Tokens.space.snug), 0, 1)
	rule.Parent = holder

	-- The label's width is not known until layout resolves; let flex own the
	-- remaining space instead of computing it.
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = rule

	return holder
end

return Divider
