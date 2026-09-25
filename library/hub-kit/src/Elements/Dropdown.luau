--[[
	Dropdown - one value, or several with Multi = true, from a list of strings.

	    Tab:Dropdown({
	        Title = "Target",
	        Values = { "Nearest", "Lowest health" },
	        Default = "Nearest",
	        Flag = "Target",
	        Callback = function(choice) ... end,
	    })

	The whole row opens the list; the current choice is shown in the slot, so
	the row reads as a sentence ("Target  Nearest") without opening anything.
	Past eight values the list gets a search box, because scrolling forty
	player names on a phone is how the wrong one gets picked.

	Values are what the Callback receives: a string or nil, or for Multi an
	array in the order of `Values`, never in the order the player clicked.
	`Refresh` drops any selection the new list no longer contains, so a
	player who left the server cannot stay selected.
--]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Icons = require(script.Parent.Parent.Core.Icons)
local Motion = require(script.Parent.Parent.Core.Motion)
local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)
local Popup = require(script.Parent.Parent.Components.Popup)
local Row = require(script.Parent.Row)

local OPTION_HEIGHT = 44
local SEARCH_FROM = 9
local LIST_WIDTH = 240
local MAX_HEIGHT = 300

local Dropdown = {}

local function lastInputIsGamepad(): boolean
	return string.find(tostring(UserInputService:GetLastInputType()), "Gamepad", 1, true) ~= nil
end

function Dropdown.new(container: any, options: { [string]: any })
	local multi = options.Multi == true
	local callback = options.Callback
	local values: { string } = table.clone(options.Values or {})
	local row = Row.button(container, options)
	local trove = row.trove

	local chosen: { [string]: boolean } = {}
	if multi then
		for _, name in options.Default or {} do
			chosen[name] = true
		end
	elseif options.Default ~= nil then
		chosen[options.Default] = true
	end

	local summary = New("TextLabel", {
		Name = "Summary",
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, row.slot)
	New("UISizeConstraint", { MaxSize = Vector2.new(160, 20) }, summary)
	New("ImageLabel", {
		Name = "Chevron",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve("chevron-down"),
		Theme = { ImageColor3 = "textMuted" },
	}, row.slot)

	local function current(): any
		if not multi then
			for _, name in values do
				if chosen[name] then
					return name
				end
			end
			return nil
		end
		local list = {}
		for _, name in values do
			if chosen[name] then
				table.insert(list, name)
			end
		end
		return list
	end

	local function render()
		local value = current()
		if not multi then
			summary.Text = value or "None"
		elseif #value == 0 then
			summary.Text = "None"
		elseif #value <= 2 then
			summary.Text = table.concat(value, ", ")
		else
			summary.Text = `{#value} selected`
		end
	end

	local function commit()
		render()
		local value = current()
		row.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	function row:Get(): any
		return current()
	end

	function row:Set(value: any)
		table.clear(chosen)
		if multi then
			for _, name in value or {} do
				chosen[name] = true
			end
		elseif value ~= nil then
			chosen[value] = true
		end
		commit()
	end

	function row:Refresh(list: { string })
		values = table.clone(list)
		local kept = {}
		for _, name in values do
			kept[name] = chosen[name]
		end
		chosen = kept
		commit()
	end

	local function openList()
		local searchable = #values >= SEARCH_FROM
		local listHeight = math.min(#values * (OPTION_HEIGHT + 4), MAX_HEIGHT)
		local height = listHeight + 16 + (if searchable then OPTION_HEIGHT + 8 else 0)
		local popup = Popup.open(container.kit, row.frame, LIST_WIDTH, height)

		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, popup.panel)
		local search = New("TextBox", {
			Name = "Search",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
			Visible = searchable,
			ClearTextOnFocus = false,
			FontFace = Font.fromEnum(Enum.Font.BuilderSans),
			TextSize = 14,
			PlaceholderText = "Search",
			Text = "",
			Theme = {
				BackgroundColor3 = "background",
				TextColor3 = "text",
				PlaceholderColor3 = "textMuted",
			},
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, search)

		local list = New("ScrollingFrame", {
			Name = "Options",
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Theme = { ScrollBarImageColor3 = "stroke" },
		}, popup.panel)
		New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, list)
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, list)

		local buttons = {}
		for order, name in values do
			local option = New("TextButton", {
				Name = name,
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
				AutoButtonColor = false,
				FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = name,
				Theme = { TextColor3 = "text" },
			}, list)
			New("UICorner", { CornerRadius = UDim.new(0, 6) }, option)
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, option)
			local check = New("ImageLabel", {
				Name = "Check",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				Image = Icons.resolve("check"),
				Theme = { ImageColor3 = "accent" },
			}, option)

			local hovered = false

			local function paint()
				check.Visible = chosen[name] == true
				local role = "surface"
				if chosen[name] then
					role = "raised"
				elseif hovered then
					role = "hover"
				end
				Motion.play(option, Motion.state, { BackgroundColor3 = Theme.get(role) })
			end

			popup.trove:connect(option.MouseEnter, function()
				hovered = true
				paint()
			end)
			popup.trove:connect(option.MouseLeave, function()
				hovered = false
				paint()
			end)
			popup.trove:connect(option.SelectionGained, function()
				hovered = true
				paint()
			end)
			popup.trove:connect(option.SelectionLost, function()
				hovered = false
				paint()
			end)

			popup.trove:connect(option.Activated, function()
				if multi then
					chosen[name] = not chosen[name] or nil
				elseif chosen[name] and options.AllowNone then
					chosen[name] = nil
				else
					table.clear(chosen)
					chosen[name] = true
				end
				commit()
				if multi then
					for _, repaint in buttons do
						repaint()
					end
				else
					popup.close()
				end
			end)
			paint()
			buttons[name] = paint
		end

		popup.trove:connect(search:GetPropertyChangedSignal("Text"), function()
			local query = string.lower(search.Text)
			for _, option in list:GetChildren() do
				if option:IsA("GuiButton") then
					local found = string.find(string.lower(option.Name), query, 1, true)
					option.Visible = query == "" or found ~= nil
				end
			end
		end)

		if lastInputIsGamepad() then
			GuiService.SelectedObject = list:FindFirstChildWhichIsA("GuiButton")
		end
	end

	trove:connect(row.frame.Activated, openList)
	row.searchText ..= " " .. table.concat(values, " ")
	render()
	return row
end

return Dropdown
