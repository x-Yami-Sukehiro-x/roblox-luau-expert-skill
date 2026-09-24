--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

export type PressStyle = "P1" | "P2" | "P3"
export type TabStyle = "S1" | "S2" | "S3"

local THEME = {
	control = Color3.fromRGB(44, 48, 57),
	controlHover = Color3.fromRGB(63, 68, 79),
	controlPressed = Color3.fromRGB(31, 34, 41),
	edge = Color3.fromRGB(118, 125, 139),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	focus = Color3.fromRGB(72, 201, 162),
}

local QUICK = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local INSTANT = TweenInfo.new(0)

local function animate(instance: Instance, timing: TweenInfo, goals: { [string]: any })
	local chosen = if GuiService.ReducedMotionEnabled then INSTANT else timing
	TweenService:Create(instance, chosen, goals):Play()
end

-- The scale a style shows for each pointer state: P1 never scales, P2 presses
-- in, P3 lifts on hover and settles on press.
local SCALE = {
	P1 = { rest = 1, hover = 1, pressed = 1 },
	P2 = { rest = 1, hover = 1, pressed = 0.97 },
	P3 = { rest = 1, hover = 1.02, pressed = 0.98 },
}

local function attachPress(button: GuiButton, style: PressStyle): () -> ()
	local connections: { RBXScriptConnection } = {}
	local hovered, pressed = false, false
	button.AutoButtonColor = false

	local size = Instance.new("UIScale")
	size.Name = "PressScale"
	size.Parent = button

	local rim = Instance.new("UIStroke")
	rim.Name = "LiftEdge"
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = THEME.edge
	rim.Transparency = 1
	rim.Parent = button

	local function paint()
		local steps = SCALE[style]
		local fill = if pressed then THEME.controlPressed
			elseif hovered then THEME.controlHover
			else THEME.control
		local scale = if pressed then steps.pressed elseif hovered then steps.hover else steps.rest
		local timing = if pressed then QUICK else RELEASE
		animate(button, timing, { BackgroundColor3 = fill })
		animate(size, timing, { Scale = scale })
		if style == "P3" then
			animate(rim, timing, { Transparency = if hovered and not pressed then 0 else 1 })
		end
	end

	table.insert(connections, button.MouseEnter:Connect(function()
		hovered = true
		paint()
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint()
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressed = true
			paint()
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		pressed = false
		paint()
	end))

	button.BackgroundColor3 = THEME.control
	size.Scale = 1
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		size:Destroy()
		rim:Destroy()
	end
end

export type Tabs = {
	select: (name: string) -> (),
	selected: () -> string,
	destroy: () -> (),
}

-- The marker is a sibling of the button row, not a child of its UIListLayout,
-- so it can slide freely; its target is read from the chosen tab's geometry.
local function createTabs(
	parent: GuiObject,
	names: { string },
	style: TabStyle,
	onSelect: (name: string) -> ()
): Tabs
	local connections: { RBXScriptConnection } = {}
	local buttons: { [string]: TextButton } = {}
	local current = names[1]
	local hovered: string? = nil

	local bar = Instance.new("Frame")
	bar.Name = "Tabs"
	bar.Size = UDim2.new(1, 0, 0, 44)
	bar.BackgroundTransparency = 1
	bar.Parent = parent

	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BorderSizePixel = 0
	marker.BackgroundColor3 = if style == "S2" then THEME.controlHover else THEME.accent
	marker.Visible = style ~= "S3"
	marker.ZIndex = 1
	marker.Parent = bar

	local markerCorner = Instance.new("UICorner")
	markerCorner.CornerRadius = UDim.new(0, if style == "S2" then 6 else 0)
	markerCorner.Parent = marker

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.fromScale(1, 1)
	row.BackgroundTransparency = 1
	row.ZIndex = 2
	row.Parent = bar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local function moveMarker(instant: boolean)
		local tab = buttons[current]
		local x = tab.AbsolutePosition.X - bar.AbsolutePosition.X
		local width = tab.AbsoluteSize.X
		local goal = if style == "S1"
			then { Position = UDim2.new(0, x, 1, -2), Size = UDim2.fromOffset(width, 2) }
			else { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0, width, 1, 0) }
		animate(marker, if instant then INSTANT else SLIDE, goal)
	end

	local function paint()
		for name, tab in buttons do
			local chosen = name == current
			tab.TextColor3 = if chosen or name == hovered then THEME.text else THEME.textMuted
			local weight = if chosen then Enum.Font.GothamBold else Enum.Font.GothamMedium
			tab.FontFace = Font.fromEnum(weight)
		end
	end

	local function select(name: string)
		if name == current or not buttons[name] then
			return
		end
		current = name
		paint()
		moveMarker(false)
		onSelect(name)
	end

	for index, name in names do
		local tab = Instance.new("TextButton")
		tab.Name = name
		tab.LayoutOrder = index
		tab.AutoButtonColor = false
		tab.Size = UDim2.fromScale(0, 1)
		tab.BackgroundTransparency = 1
		tab.TextSize = 14
		tab.Text = name
		tab.Parent = row

		local share = Instance.new("UIFlexItem")
		share.FlexMode = Enum.UIFlexMode.Fill
		share.Parent = tab

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.focus
		ring.Thickness = 2
		ring.Enabled = false
		ring.Parent = tab

		buttons[name] = tab
		table.insert(connections, tab.Activated:Connect(function()
			select(name)
		end))
		table.insert(connections, tab.MouseEnter:Connect(function()
			hovered = name
			paint()
		end))
		table.insert(connections, tab.MouseLeave:Connect(function()
			if hovered == name then
				hovered = nil
			end
			paint()
		end))
		table.insert(connections, tab.SelectionGained:Connect(function()
			ring.Enabled = true
		end))
		table.insert(connections, tab.SelectionLost:Connect(function()
			ring.Enabled = false
		end))
	end

	table.insert(connections, bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		moveMarker(true)
	end))
	paint()
	moveMarker(true)

	return {
		select = select,
		selected = function()
			return current
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			bar:Destroy()
		end,
	}
end

return {
	attachPress = attachPress,
	createTabs = createTabs,
}
