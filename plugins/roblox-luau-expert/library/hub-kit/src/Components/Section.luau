--[[
	Section - a titled group of rows inside a tab, collapsible from its header.

	    local movement = Tab:Section({ Title = "Movement" })
	    movement:Toggle({ Title = "Fly", Flag = "Fly", Callback = setFly })

	A section has the same element methods as a tab. While the window search
	has text, a collapsed section still shows its matching rows: a search
	that hides its own results behind a fold looks like a search that failed.
--]]

local Elements = require(script.Parent.Parent.Elements)
local Icons = require(script.Parent.Parent.Core.Icons)
local Motion = require(script.Parent.Parent.Core.Motion)
local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)

local Section = {}

function Section.new(tab: any, options: { [string]: any })
	assert(type(options.Title) == "string", "a Section needs a Title string")
	local trove = tab.trove:extend()

	local holder = New("Frame", {
		Name = options.Title,
		LayoutOrder = tab:nextOrder(),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, tab.frame)
	trove:add(holder)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, holder)

	local header = New("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, holder)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, header)
	local chevron = New("ImageLabel", {
		Name = "Chevron",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve("chevron-down"),
		Theme = { ImageColor3 = "textMuted" },
	}, header)
	local label = New("TextLabel", {
		Name = "Title",
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 14,
		Text = options.Title,
		Theme = { TextColor3 = "textMuted" },
	}, header)

	local body = New("Frame", {
		Name = "Body",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, holder)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, body)

	local section = {
		kit = tab.kit,
		window = tab.window,
		tab = tab,
		frame = body,
		holder = holder,
		trove = trove,
		entries = tab.entries,
		collapsed = false,
		order = 0,
	}
	section.section = section

	function section:nextOrder(): number
		self.order += 1
		return self.order
	end

	function section:SetCollapsed(collapsed: boolean)
		self.collapsed = collapsed
		Motion.play(chevron, Motion.state, { Rotation = if collapsed then -90 else 0 })
		self.window:applySearch()
	end

	function section:Destroy()
		local index = table.find(tab.sections, section)
		if index then
			table.remove(tab.sections, index)
		end
		trove:clean()
	end

	local hovered = false
	local function paint()
		label.TextColor3 = Theme.get(if hovered then "text" else "textMuted")
	end
	trove:connect(header.MouseEnter, function()
		hovered = true
		paint()
	end)
	trove:connect(header.MouseLeave, function()
		hovered = false
		paint()
	end)
	trove:connect(header.SelectionGained, function()
		hovered = true
		paint()
	end)
	trove:connect(header.SelectionLost, function()
		hovered = false
		paint()
	end)
	trove:connect(Theme.changed, paint)
	trove:connect(header.Activated, function()
		section:SetCollapsed(not section.collapsed)
	end)

	Elements.install(section)
	table.insert(tab.sections, section)
	if options.Collapsed then
		section:SetCollapsed(true)
	end
	return section
end

return Section
