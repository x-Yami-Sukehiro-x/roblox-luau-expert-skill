--!strict
--[[
	Dropdown — a closed control that opens a list, single or multi select.

	Explained in: roblox-ui-components/references/catalog.md
	              roblox-ui/references/blueprints.md (B2)

	Deliberate choices:
	  - The menu is parented to the ScreenGui, not to the control. A menu
	    parented to its trigger is clipped by the first ancestor with
	    ClipsDescendants, which in a scrolling settings list is always.
	  - It positions itself ABOVE the trigger when there is not room below.
	    Opening off the bottom of a phone screen is the standard failure.
	  - A full-screen invisible button behind the menu closes it. Without one,
	    the only way to dismiss is to pick something.
	  - Selected rows carry a check glyph as well as the accent, because colour
	    alone is not a signal everyone receives.
--]]

local Motion = require(script.Parent.Parent.Motion)
local Tokens = require(script.Parent.Parent.Tokens)

local Dropdown = {}

export type Options = {
	items: { string },
	selected: string?,
	multi: boolean?,
	width: number?,
	placeholder: string?,
}

export type Handle = {
	instance: TextButton,
	get: (self: Handle) -> { string },
	set: (self: Handle, values: { string }, silent: boolean?) -> (),
	setItems: (self: Handle, items: { string }) -> (),
	close: (self: Handle) -> (),
	destroy: (self: Handle) -> (),
}

local ROW_HEIGHT = 44
local CONTROL_HEIGHT = 36
local DEFAULT_WIDTH = 140
local MAX_MENU_HEIGHT = 220

local function contains(list: { string }, value: string): boolean
	for _, entry in list do
		if entry == value then
			return true
		end
	end
	return false
end

local function findScreenGui(instance: Instance): ScreenGui?
	local current: Instance? = instance
	while current do
		if current:IsA("ScreenGui") then
			return current
		end
		current = current.Parent
	end
	return nil
end

function Dropdown.new(options: Options, onChange: (values: { string }) -> ()): Handle
	local items = table.clone(options.items)
	local multi = options.multi == true
	local width = options.width or DEFAULT_WIDTH
	local placeholder = options.placeholder or "Select"

	local chosen: { string } = {}
	if options.selected and contains(items, options.selected) then
		table.insert(chosen, options.selected)
	end

	local button = Instance.new("TextButton")
	button.Name = "Dropdown"
	button.AutoButtonColor = false
	button.BackgroundColor3 = Tokens.control.base
	button.BorderSizePixel = 0
	button.Text = ""
	button.Size = UDim2.fromOffset(width, CONTROL_HEIGHT)
	button.Selectable = true
	button.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = Tokens.radius.control
	corner.TopRightRadius = Tokens.radius.control
	corner.BottomLeftRadius = Tokens.radius.control
	corner.BottomRightRadius = Tokens.radius.control
	corner.Parent = button

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	edge.Thickness = 1
	edge.Color = Tokens.stroke.base
	edge.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Tokens.space.base)
	padding.PaddingRight = UDim.new(0, Tokens.space.snug)
	padding.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -18, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.FontFace = Tokens.font.body
	label.TextSize = Tokens.text_size.body
	label.TextColor3 = Tokens.text.primary
	label.Text = placeholder
	label.Parent = button

	-- A rotating caret, not a swapped glyph: one instance, and the rotation
	-- itself is the open/closed signal.
	local caret = Instance.new("TextLabel")
	caret.Name = "Caret"
	caret.BackgroundTransparency = 1
	caret.AnchorPoint = Vector2.new(1, 0.5)
	caret.Position = UDim2.fromScale(1, 0.5)
	caret.Size = UDim2.fromOffset(16, 16)
	caret.FontFace = Tokens.font.emphasis
	caret.TextSize = Tokens.text_size.caption
	caret.TextColor3 = Tokens.text.secondary
	caret.Text = "v"
	caret.Parent = button

	local menu: Frame? = nil
	local scrim: TextButton? = nil
	local connections: { RBXScriptConnection } = {}
	local rowConnections: { RBXScriptConnection } = {}

	local function summarise(): string
		if #chosen == 0 then
			return placeholder
		elseif #chosen == 1 then
			return chosen[1]
		end
		return `{#chosen} selected`
	end

	local function closeMenu()
		for _, connection in rowConnections do
			connection:Disconnect()
		end
		table.clear(rowConnections)

		if menu then
			menu:Destroy()
			menu = nil
		end
		if scrim then
			scrim:Destroy()
			scrim = nil
		end
		caret.Rotation = 0
	end

	local function openMenu()
		local screenGui = findScreenGui(button)
		if not screenGui then
			warn("Dropdown: no ScreenGui ancestor, cannot open the menu")
			return
		end

		closeMenu()
		caret.Rotation = 180

		local blocker = Instance.new("TextButton")
		blocker.Name = "DropdownScrim"
		blocker.BackgroundTransparency = 1
		blocker.Text = ""
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.ZIndex = button.ZIndex + 10
		blocker.Parent = screenGui
		scrim = blocker

		local height = math.min(#items * ROW_HEIGHT + Tokens.space.tight * 2, MAX_MENU_HEIGHT)

		local panel = Instance.new("Frame")
		panel.Name = "DropdownMenu"
		panel.BackgroundColor3 = Tokens.surface.overlay
		panel.BorderSizePixel = 0
		panel.Size = UDim2.fromOffset(button.AbsoluteSize.X, height)
		panel.ZIndex = blocker.ZIndex + 1
		panel.Parent = screenGui

		-- Open upward when there is not room below. On a phone in a settings
		-- list, there usually is not.
		local viewport = screenGui.AbsoluteSize.Y
		local below = button.AbsolutePosition.Y + button.AbsoluteSize.Y
		local opensDown = below + height + Tokens.space.tight <= viewport
		panel.Position = UDim2.fromOffset(
			button.AbsolutePosition.X,
			if opensDown
				then below + Tokens.space.tight
				else button.AbsolutePosition.Y - height - Tokens.space.tight
		)

		local panelCorner = Instance.new("UICorner")
		panelCorner.TopLeftRadius = Tokens.radius.control
		panelCorner.TopRightRadius = Tokens.radius.control
		panelCorner.BottomLeftRadius = Tokens.radius.control
		panelCorner.BottomRightRadius = Tokens.radius.control
		panelCorner.Parent = panel

		local panelEdge = Instance.new("UIStroke")
		panelEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		panelEdge.BorderStrokePosition = Enum.BorderStrokePosition.Inner
		panelEdge.Thickness = 1
		panelEdge.Color = Tokens.stroke.strong
		panelEdge.Parent = panel

		local shadow = Instance.new("UIShadow")
		shadow.Color = Tokens.stroke.shadow
		shadow.BlurRadius = UDim.new(0, Tokens.elevation.floating.blur)
		shadow.Offset = UDim2.fromOffset(0, Tokens.elevation.floating.offset)
		shadow.Transparency = Tokens.elevation.floating.transparency
		shadow.Parent = panel

		local list = Instance.new("ScrollingFrame")
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.Size = UDim2.fromScale(1, 1)
		list.CanvasSize = UDim2.new()
		list.AutomaticCanvasSize = Enum.AutomaticSize.Y
		list.ScrollBarThickness = 3
		list.ZIndex = panel.ZIndex
		list.Parent = panel

		local listPadding = Instance.new("UIPadding")
		listPadding.PaddingTop = UDim.new(0, Tokens.space.tight)
		listPadding.PaddingBottom = UDim.new(0, Tokens.space.tight)
		listPadding.Parent = list

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list

		for index, item in items do
			local row = Instance.new("TextButton")
			row.Name = item
			row.AutoButtonColor = false
			row.BackgroundColor3 = Tokens.surface.overlay
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.Text = ""
			row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
			row.LayoutOrder = index
			row.ZIndex = list.ZIndex
			row.Parent = list

			local rowPadding = Instance.new("UIPadding")
			rowPadding.PaddingLeft = UDim.new(0, Tokens.space.base)
			rowPadding.PaddingRight = UDim.new(0, Tokens.space.snug)
			rowPadding.Parent = row

			local isSelected = contains(chosen, item)

			local rowLabel = Instance.new("TextLabel")
			rowLabel.BackgroundTransparency = 1
			rowLabel.Size = UDim2.new(1, -16, 1, 0)
			rowLabel.TextXAlignment = Enum.TextXAlignment.Left
			rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
			rowLabel.FontFace = if isSelected then Tokens.font.emphasis else Tokens.font.body
			rowLabel.TextSize = Tokens.text_size.body
			rowLabel.TextColor3 = if isSelected then Tokens.accent.bright else Tokens.text.primary
			rowLabel.Text = item
			rowLabel.ZIndex = row.ZIndex
			rowLabel.Parent = row

			-- Shape as well as colour, so selection survives colour blindness.
			local tick = Instance.new("TextLabel")
			tick.BackgroundTransparency = 1
			tick.AnchorPoint = Vector2.new(1, 0.5)
			tick.Position = UDim2.fromScale(1, 0.5)
			tick.Size = UDim2.fromOffset(14, 14)
			tick.FontFace = Tokens.font.emphasis
			tick.TextSize = Tokens.text_size.caption
			tick.TextColor3 = Tokens.accent.bright
			tick.Text = "+"
			tick.Visible = isSelected
			tick.ZIndex = row.ZIndex
			tick.Parent = row

			table.insert(
				rowConnections,
				row.MouseEnter:Connect(function()
					row.BackgroundTransparency = 0
					row.BackgroundColor3 = Tokens.control.hover
				end)
			)

			table.insert(
				rowConnections,
				row.MouseLeave:Connect(function()
					row.BackgroundTransparency = 1
				end)
			)

			table.insert(
				rowConnections,
				row.Activated:Connect(function()
					if multi then
						if contains(chosen, item) then
							local at = table.find(chosen, item)
							if at then
								table.remove(chosen, at)
							end
						else
							table.insert(chosen, item)
						end
						label.Text = summarise()
						rowLabel.TextColor3 = if contains(chosen, item)
							then Tokens.accent.bright
							else Tokens.text.primary
						rowLabel.FontFace = if contains(chosen, item)
							then Tokens.font.emphasis
							else Tokens.font.body
						tick.Visible = contains(chosen, item)
					else
						chosen = { item }
						label.Text = summarise()
						closeMenu()
					end
					onChange(table.clone(chosen))
				end)
			)
		end

		Motion.play(panel, "enter", { BackgroundTransparency = 0 })

		table.insert(rowConnections, blocker.Activated:Connect(closeMenu))
	end

	table.insert(
		connections,
		button.Activated:Connect(function()
			if menu then
				closeMenu()
			else
				openMenu()
			end
		end)
	)

	table.insert(
		connections,
		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = Tokens.control.hover
		end)
	)

	table.insert(
		connections,
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Tokens.control.base
		end)
	)

	label.Text = summarise()

	local handle = {}
	handle.instance = button

	function handle:get(): { string }
		return table.clone(chosen)
	end

	function handle:set(values: { string }, silent: boolean?)
		chosen = {}
		for _, value in values do
			if contains(items, value) then
				table.insert(chosen, value)
			end
		end
		label.Text = summarise()
		if not silent then
			onChange(table.clone(chosen))
		end
	end

	function handle:setItems(next: { string })
		items = table.clone(next)
		local kept: { string } = {}
		for _, value in chosen do
			if contains(items, value) then
				table.insert(kept, value)
			end
		end
		chosen = kept
		label.Text = summarise()
		if menu then
			closeMenu()
		end
	end

	function handle:close()
		closeMenu()
	end

	function handle:destroy()
		closeMenu()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		button:Destroy()
	end

	return (handle :: any) :: Handle
end

return Dropdown
