--[[
	Tab - one sidebar button and the scrolling page it shows.

	    local player = Window:Tab({ Title = "Player", Icon = "user" })
	    player:Slider({ Title = "Walk speed", Min = 16, Max = 120, Default = 16 })

	Every page is built once and shown or hidden, never rebuilt on switch, so
	a half-typed Input or an open section survives a trip to another tab.
	In a compact window the label hides and the icon carries the tab alone,
	which is why a tab without an Icon still gets one.
--]]

local Elements = require(script.Parent.Parent.Elements)
local Icons = require(script.Parent.Parent.Core.Icons)
local Motion = require(script.Parent.Parent.Core.Motion)
local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)
local Section = require(script.Parent.Section)

-- Rows are appended with increasing LayoutOrder; the empty-search line
-- sorts after all of them.
local LAST = 1e6

local Tab = {}

function Tab.new(window: any, options: { [string]: any })
	assert(type(options.Title) == "string", "a Tab needs a Title string")
	local image = Icons.resolve(options.Icon or "layout-list")
	local trove = window.trove:extend()

	local button = New("TextButton", {
		Name = options.Title,
		LayoutOrder = #window.tabs + 1,
		Size = UDim2.new(1, 0, 0, 44),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		Theme = { BackgroundColor3 = "raised" },
	}, window.sidebar)
	trove:add(button)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, button)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, button)
	local icon = New("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = image,
	}, button)
	local label = New("TextLabel", {
		Name = "Label",
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = options.Title,
	}, button)
	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 2,
		Enabled = false,
		Theme = { Color = "focus" },
	}, button)

	local page = New("ScrollingFrame", {
		Name = options.Title,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Theme = { ScrollBarImageColor3 = "stroke" },
	}, window.pages)
	trove:add(page)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, page)
	New("UIPadding", { PaddingRight = UDim.new(0, 8) }, page)
	local empty = New("TextLabel", {
		Name = "NoMatches",
		LayoutOrder = LAST,
		Size = UDim2.new(1, 0, 0, 44),
		Visible = false,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextWrapped = true,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, page)

	local tab = {
		kit = window.kit,
		window = window,
		title = options.Title,
		button = button,
		label = label,
		frame = page,
		empty = empty,
		trove = trove,
		entries = {},
		sections = {},
		order = 0,
	}

	function tab:nextOrder(): number
		self.order += 1
		return self.order
	end

	function tab:Section(sectionOptions: { [string]: any })
		return Section.new(self, sectionOptions)
	end

	function tab:Select()
		window:SelectTab(self)
	end

	local hovered, focused = false, false
	function tab:render()
		local selected = window.selected == self
		local fill = if selected then 0 elseif hovered then 0.5 else 1
		Motion.play(button, Motion.state, { BackgroundTransparency = fill })
		label.TextColor3 = Theme.get(if selected or hovered then "text" else "textMuted")
		icon.ImageColor3 = Theme.get(if selected then "accent" else "textMuted")
		local weight = if selected then Enum.Font.BuilderSansBold else Enum.Font.BuilderSansMedium
		label.FontFace = Font.fromEnum(weight)
		ring.Enabled = focused
	end

	trove:connect(button.MouseEnter, function()
		hovered = true
		tab:render()
	end)
	trove:connect(button.MouseLeave, function()
		hovered = false
		tab:render()
	end)
	trove:connect(button.SelectionGained, function()
		focused = true
		tab:render()
	end)
	trove:connect(button.SelectionLost, function()
		focused = false
		tab:render()
	end)
	trove:connect(Theme.changed, function()
		tab:render()
	end)
	trove:connect(button.Activated, function()
		window:SelectTab(tab)
	end)

	Elements.install(tab)
	return tab
end

return Tab
