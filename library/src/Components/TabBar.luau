--!strict
--[[
	TabBar — tabs over a page container, with a sliding indicator.

	Explained in: roblox-ui/references/blueprints.md (B6)

	Deliberate choices:
	  - Pages are built once and toggled with Visible. Rebuilding on every
	    switch is an allocation spike per switch and throws away scroll
	    position, which players notice immediately and cannot articulate.
	  - The indicator is one instance that MOVES, not one per tab that toggles.
	    Moving it is what makes the switch read as a single object changing
	    place rather than two things blinking.
	  - Selected tabs change weight as well as colour. Colour alone is not a
	    signal every player receives.
	  - Above five tabs this shape is wrong; the constructor says so rather
	    than rendering something unusable.
--]]

local Motion = require(script.Parent.Parent.Motion)
local Tokens = require(script.Parent.Parent.Tokens)

local TabBar = {}

export type Handle = {
	instance: Frame,
	pages: Frame,
	select: (self: Handle, name: string) -> (),
	current: (self: Handle) -> string,
	page: (self: Handle, name: string) -> Frame?,
	destroy: (self: Handle) -> (),
}

local BAR_HEIGHT = 44
local TAB_MIN_WIDTH = 88
local INDICATOR_HEIGHT = 2
local COMFORTABLE_TAB_LIMIT = 5

--[[
	    local tabs = TabBar.new(container, { "Combat", "Visuals", "Settings" })
	    someControl.Parent = tabs:page("Combat")
--]]
function TabBar.new(parent: Instance, names: { string }, onSwitch: ((name: string) -> ())?): Handle
	if #names == 0 then
		error("TabBar.new needs at least one tab name", 2)
	end
	if #names > COMFORTABLE_TAB_LIMIT then
		warn(
			`TabBar: {#names} tabs will not fit on a phone. Group them, or use a sidebar - `
				.. `see roblox-ui/references/blueprints.md (B6).`
		)
	end

	local container = Instance.new("Frame")
	container.Name = "Tabs"
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(1, 1)
	container.Parent = parent

	local containerStack = Instance.new("UIListLayout")
	containerStack.FillDirection = Enum.FillDirection.Vertical
	containerStack.SortOrder = Enum.SortOrder.LayoutOrder
	containerStack.Padding = UDim.new(0, Tokens.space.base)
	containerStack.Parent = container

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundTransparency = 1
	bar.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
	bar.LayoutOrder = 1
	bar.Parent = container

	-- The tabs get their own row so the indicator can stay outside the layout:
	-- a UIListLayout places every sibling it manages and ignores its Position.
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = bar

	local barLayout = Instance.new("UIListLayout")
	barLayout.FillDirection = Enum.FillDirection.Horizontal
	barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	barLayout.SortOrder = Enum.SortOrder.LayoutOrder
	barLayout.Padding = UDim.new(0, Tokens.space.tight)
	-- Wraps is what stops a five-tab row overflowing a 360px phone.
	barLayout.Wraps = true
	barLayout.Parent = row

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.Size = UDim2.fromScale(1, 0)
	pages.LayoutOrder = 2
	pages.Parent = container

	local pagesFlex = Instance.new("UIFlexItem")
	pagesFlex.FlexMode = Enum.UIFlexMode.Fill
	pagesFlex.Parent = pages

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.AnchorPoint = Vector2.new(0, 1)
	indicator.BackgroundColor3 = Tokens.accent.base
	indicator.BorderSizePixel = 0
	indicator.Size = UDim2.fromOffset(TAB_MIN_WIDTH, INDICATOR_HEIGHT)
	indicator.Position = UDim2.new(0, 0, 1, 0)
	indicator.ZIndex = 2
	indicator.Parent = bar

	local buttons: { [string]: TextButton } = {}
	local labels: { [string]: TextLabel } = {}
	local pageFrames: { [string]: Frame } = {}
	local connections: { RBXScriptConnection } = {}
	local selected = names[1]

	-- Springs an X offset rather than a Position: UDim2 is not a
	-- SmoothDamp-supported type, so the number is sprung and composed here.
	local slide = Motion.springValue(0, 0.10, function(value)
		indicator.Position = UDim2.new(0, value, 1, 0)
	end)

	local function paint()
		for name, label in labels do
			local isCurrent = name == selected
			label.TextColor3 = if isCurrent then Tokens.accent.bright else Tokens.text.secondary
			label.FontFace = if isCurrent then Tokens.font.emphasis else Tokens.font.body
		end
		for name, frame in pageFrames do
			frame.Visible = name == selected
		end

		local button = buttons[selected]
		if button then
			indicator.Size = UDim2.fromOffset(button.AbsoluteSize.X, INDICATOR_HEIGHT)
			slide:setTarget(button.AbsolutePosition.X - bar.AbsolutePosition.X)
		end
	end

	for index, name in names do
		local button = Instance.new("TextButton")
		button.Name = name
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1
		button.Text = ""
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, BAR_HEIGHT)
		button.LayoutOrder = index
		button.Selectable = true
		button.Parent = row

		local minimum = Instance.new("UISizeConstraint")
		minimum.MinSize = Vector2.new(TAB_MIN_WIDTH, BAR_HEIGHT)
		minimum.Parent = button

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, Tokens.space.base)
		padding.PaddingRight = UDim.new(0, Tokens.space.base)
		padding.Parent = button

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.FontFace = Tokens.font.body
		label.TextSize = Tokens.text_size.body
		label.TextColor3 = Tokens.text.secondary
		label.Text = name
		label.Parent = button

		local page = Instance.new("Frame")
		page.Name = name
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.Visible = false
		page.Parent = pages

		buttons[name] = button
		labels[name] = label
		pageFrames[name] = page

		table.insert(
			connections,
			button.Activated:Connect(function()
				if selected == name then
					return
				end
				selected = name
				paint()
				if onSwitch then
					onSwitch(name)
				end
			end)
		)

		table.insert(
			connections,
			button.MouseEnter:Connect(function()
				if selected ~= name then
					label.TextColor3 = Tokens.text.primary
				end
			end)
		)

		table.insert(
			connections,
			button.MouseLeave:Connect(function()
				if selected ~= name then
					label.TextColor3 = Tokens.text.secondary
				end
			end)
		)
	end

	-- AbsoluteSize is zero on the frame an instance is created, so the first
	-- paint is deferred and the indicator is snapped rather than sprung to it.
	task.defer(function()
		if not container.Parent then
			return
		end
		local first = buttons[selected]
		if first then
			slide:snap(first.AbsolutePosition.X - bar.AbsolutePosition.X)
		end
		paint()
	end)

	table.insert(connections, bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(paint))

	local handle = {}
	handle.instance = container
	handle.pages = pages

	function handle:select(name: string)
		if not pageFrames[name] then
			error(`TabBar: no tab named "{name}"`, 2)
		end
		if selected == name then
			return
		end
		selected = name
		paint()
		if onSwitch then
			onSwitch(name)
		end
	end

	function handle:current(): string
		return selected
	end

	function handle:page(name: string): Frame?
		return pageFrames[name]
	end

	function handle:destroy()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		slide:destroy()
		container:Destroy()
	end

	return (handle :: any) :: Handle
end

return TabBar
