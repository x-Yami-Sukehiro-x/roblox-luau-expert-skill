--[[
	Row - the one layout every element shares: title and description on the
	left, the element's control in `slot` on the right, and for stacked
	elements (Slider) a full-width `below` line under both.

	A button row is the element's hit area, 44 px tall at minimum, so a phone
	player taps the whole row rather than a 16 px icon. It draws five of the
	six states itself: rest, hover, press, keyboard or gamepad focus, and
	disabled. Selected belongs to the element (a toggle's knob, a dropdown's
	value), so the row leaves it alone.

	The description is always visible under the title. Nothing an element
	needs to say is hidden behind a hover that a touch screen never sends.
--]]

local UserInputService = game:GetService("UserInputService")

local Motion = require(script.Parent.Parent.Core.Motion)
local New = require(script.Parent.Parent.Core.New)
local Signal = require(script.Parent.Parent.Core.Signal)
local Theme = require(script.Parent.Parent.Core.Theme)

local ROW_SIZE = UDim2.new(1, 0, 0, 44)

-- The engine's selection outline would draw a second ring over the row's own.
local noSelection = Instance.new("Frame")
noSelection.BackgroundTransparency = 1

local Row = {}

local function isPress(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

local function build(row: any, options: { [string]: any }, stacked: boolean)
	local frame = row.frame
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, frame)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, frame)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, frame)

	local line = New("Frame", {
		Name = "Line",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, frame)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
	}, line)

	local words = New("Frame", {
		Name = "Words",
		LayoutOrder = 1,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, line)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, words)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, words)

	row.title = New("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Title,
		Theme = { TextColor3 = "text" },
	}, words)

	row.description = New("TextLabel", {
		Name = "Description",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Description or "",
		Visible = options.Description ~= nil,
		Theme = { TextColor3 = "textMuted" },
	}, words)

	row.slot = New("Frame", {
		Name = "Slot",
		LayoutOrder = 2,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, line)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, row.slot)

	if stacked then
		row.below = New("Frame", {
			Name = "Below",
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, frame)
	end
end

local function finish(row: any, options: { [string]: any })
	row.searchText = `{options.Title} {options.Description or ""}`
	row.Changed = Signal.new()
	row.trove:add(row.Changed)

	function row:SetTitle(text: string)
		self.title.Text = text
		self.frame.Name = text
	end

	function row:SetDescription(text: string?)
		self.description.Text = text or ""
		self.description.Visible = text ~= nil
	end

	-- The title binding restores "text" on a theme switch; this runs after it.
	local function shade()
		row.title.TextColor3 = Theme.get(if row.frame.Interactable then "text" else "textMuted")
	end
	row.trove:connect(Theme.changed, shade)

	function row:SetDisabled(disabled: boolean)
		self.frame.Interactable = not disabled
		shade()
	end

	function row:Destroy()
		self.trove:clean()
	end

	row.Frame = row.frame
	return row
end

function Row.frame(container: any, options: { [string]: any }, stacked: boolean?): any
	assert(type(options.Title) == "string", "every element needs a Title string")
	local row = { trove = container.trove:extend() }
	row.frame = New("Frame", {
		Name = options.Title,
		LayoutOrder = container:nextOrder(),
		Size = ROW_SIZE,
		AutomaticSize = Enum.AutomaticSize.Y,
		Theme = { BackgroundColor3 = "raised" },
	}, container.frame)
	row.trove:add(row.frame)
	build(row, options, stacked == true)
	return finish(row, options)
end

function Row.button(container: any, options: { [string]: any }): any
	assert(type(options.Title) == "string", "every element needs a Title string")
	local row = { trove = container.trove:extend() }
	local frame = New("TextButton", {
		Name = options.Title,
		LayoutOrder = container:nextOrder(),
		Size = ROW_SIZE,
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoButtonColor = false,
		Text = "",
		SelectionImageObject = noSelection,
		BackgroundColor3 = Theme.get("raised"),
	}, container.frame)
	row.frame = frame
	row.trove:add(frame)
	build(row, options, false)

	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 2,
		Enabled = false,
		Theme = { Color = "focus" },
	}, frame)

	local hovered, pressed, focused = false, false, false
	local function render()
		local enabled = frame.Interactable
		local role = "raised"
		if enabled and pressed then
			role = "stroke"
		elseif enabled and hovered then
			role = "hover"
		end
		Motion.play(frame, Motion.state, { BackgroundColor3 = Theme.get(role) })
		frame.BackgroundTransparency = if enabled then 0 else 0.4
		ring.Enabled = focused and enabled
	end

	local trove = row.trove
	trove:connect(frame.MouseEnter, function()
		hovered = true
		render()
	end)
	trove:connect(frame.MouseLeave, function()
		hovered, pressed = false, false
		render()
	end)
	trove:connect(frame.InputBegan, function(input: InputObject)
		if isPress(input) then
			pressed = true
			render()
		end
	end)
	trove:connect(UserInputService.InputEnded, function(input: InputObject)
		if pressed and isPress(input) then
			pressed = false
			render()
		end
	end)
	trove:connect(frame.SelectionGained, function()
		focused = true
		render()
	end)
	trove:connect(frame.SelectionLost, function()
		focused = false
		render()
	end)
	trove:connect(frame:GetPropertyChangedSignal("Interactable"), render)
	trove:connect(Theme.changed, render)
	return finish(row, options)
end

return Row
