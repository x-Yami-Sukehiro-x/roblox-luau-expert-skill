--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

type FirstSix = "D1" | "D2" | "D3" | "D4" | "D5" | "D6"
type SecondSix = "D7" | "D8" | "D9" | "D10" | "D11" | "D12"
type LaterStyles = "D13" | "D14" | "D15" | "D16" | "D17" | "D18" | "D19" | "D20" | "D21" | "D22"
export type DropdownStyle = FirstSix | SecondSix | LaterStyles

-- `text` is the value handed to onChanged; `display` is what the row shows
-- when it should differ (D10 shows a display name for a unique username).
-- D8 reads `group`, D9 and D18 `icon`, D12 `colour`, D13 `detail` and D21
-- `children`; D10 fills `image` itself.
export type Choice = {
	text: string,
	display: string?,
	detail: string?,
	icon: string?,
	image: string?,
	group: string?,
	colour: Color3?,
	children: { string | Choice }?,
}

-- `label` names what the field is for and is its placeholder. `host` is the
-- ScreenGui the list opens above; by default the field's own ScreenGui. D19
-- calls `onRun` with the chosen value; D22 calls `onCreate` with a new one.
export type DropdownSpec = {
	label: string,
	options: { string | Choice },
	chosen: { string }?,
	onChanged: (chosen: { string }) -> (),
	onRun: ((chosen: string) -> ())?,
	onCreate: ((text: string) -> ())?,
	host: ScreenGui?,
}

export type Dropdown = {
	root: Frame,
	get: () -> { string },
	set: (chosen: { string }) -> (),
	setOptions: (options: { string | Choice }) -> (),
	open: () -> (),
	close: () -> (),
	destroy: () -> (),
}

local THEME = {
	field = Color3.fromRGB(31, 34, 41),
	fieldHover = Color3.fromRGB(44, 48, 57),
	surface = Color3.fromRGB(44, 48, 57),
	rowHover = Color3.fromRGB(63, 68, 79),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	scrim = Color3.fromRGB(0, 0, 0),
}

local ICON = {
	chevronDown = "rbxassetid://71457658246709",
	chevronLeft = "rbxassetid://102314312897830",
	chevronRight = "rbxassetid://101007429951147",
	check = "rbxassetid://86817768619372",
	search = "rbxassetid://72296609649861",
	plus = "rbxassetid://101123124881873",
}

local ROW = 44
local TWO_LINE_ROW = 56
local GRID_CELL = 72
local GRID_COLUMNS = 3
local RECENT_LIMIT = 3
local SCRIM_TRANSPARENCY = 0.5
local VISIBLE_ROWS = 5
local LIST_GAP = 4
local SUGGESTIONS = 6
local PALETTE_WIDTH = 480
local OPEN = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SHUT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

-- The styles that let the player pick several at once.
local MULTI = { D3 = true, D4 = true, D20 = true }

-- The styles whose field is a text box the player types into.
local TYPED = { D2 = true, D5 = true, D17 = true, D22 = true }

-- Rich text treats these as markup; a typed "<" must show as itself.
local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function animate(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
	local chosen = if GuiService.ReducedMotionEnabled then INSTANT else timing
	local tween = TweenService:Create(target, chosen, goals)
	tween:Play()
	return tween
end

local function round(target: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
end

local function outline(target: GuiObject): UIStroke
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = target
	return edge
end

local function pad(target: GuiObject, vertical: number, horizontal: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, vertical)
	padding.PaddingBottom = UDim.new(0, vertical)
	padding.PaddingLeft = UDim.new(0, horizontal)
	padding.PaddingRight = UDim.new(0, horizontal)
	padding.Parent = target
end

local function lineUp(target: GuiObject, direction: Enum.FillDirection, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = target
	return layout
end

local function fill(target: GuiObject)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = target
end

local function newText(name: string, text: string, size: number, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	return label
end

local function newIcon(name: string, image: string, size: number, order: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.LayoutOrder = order
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.Image = image
	icon.ImageColor3 = THEME.textMuted
	return icon
end

local function toChoice(option: string | Choice): Choice
	return if type(option) == "string" then { text = option } else option
end

-- Case-insensitive, and plain: a player typing "[" must not break the search.
local function matches(choice: Choice, query: string): boolean
	if query == "" then
		return true
	end
	local haystack = string.lower(`{choice.display or choice.text} {choice.detail or ""}`)
	return haystack:find(query:lower(), 1, true) ~= nil
end

local function playerChoices(): { Choice }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player ~= Players.LocalPlayer then
			table.insert(list, {
				text = player.Name,
				display = player.DisplayName,
				detail = `@{player.Name}`,
				image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=48&h=48`,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.text:lower() < b.text:lower()
	end)
	return list
end

-- One interactive row or field: hover, press and focus each change something
-- the player can see, and focus survives the pointer leaving.
local function watch(
	button: GuiButton,
	connections: { RBXScriptConnection },
	rest: () -> Color3
)
	local ring = Instance.new("UIStroke")
	ring.Name = "FocusRing"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		button.BackgroundColor3 = THEME.rowHover
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		button.BackgroundColor3 = rest()
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			button.BackgroundColor3 = THEME.field
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		button.BackgroundColor3 = rest()
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
end

local function newBox(name: string, placeholder: string, order: number): TextBox
	local box = Instance.new("TextBox")
	box.Name = name
	box.LayoutOrder = order
	box.Size = UDim2.fromScale(0, 1)
	box.BackgroundTransparency = 1
	box.ClearTextOnFocus = false
	box.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	box.TextSize = 14
	box.TextColor3 = THEME.text
	box.PlaceholderColor3 = THEME.textMuted
	box.PlaceholderText = placeholder
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Text = ""
	fill(box)
	return box
end

local function createDropdown(parent: GuiObject, style: DropdownStyle, spec: DropdownSpec): Dropdown
	local connections: { RBXScriptConnection } = {}
	local rowConnections: { RBXScriptConnection } = {}
	local choices: { Choice } = {}
	local chosen: { string } = table.clone(spec.chosen or {})
	local query = ""
	local isOpen = false
	local ticket = 0
	local multi = MULTI[style] == true

	local root = Instance.new("Frame")
	root.Name = spec.label
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.fromScale(1, 0)
	root.BackgroundTransparency = 1
	lineUp(root, Enum.FillDirection.Vertical, LIST_GAP)

	local function isChosen(text: string): boolean
		return table.find(chosen, text) ~= nil
	end

	local function choiceFor(text: string, within: { string | Choice }?): Choice?
		for _, option in within or choices do
			local choice = toChoice(option)
			if choice.text == text then
				return choice
			end
			local nested = if choice.children then choiceFor(text, choice.children) else nil
			if nested then
				return nested
			end
		end
		return nil
	end

	-- D14 remembers the last few picks; D20 holds picks until Apply; D21 keeps
	-- the path of open sub-menus.
	local recent: { string } = {}
	local pending: { string }? = nil
	local trail: { Choice } = {}

	-- The field. Most styles are one button; the typed styles hold a TextBox,
	-- D7 holds two arrows, and D4 grows to fit its chips.
	local field: GuiObject
	local fieldButton: TextButton? = nil
	local box: TextBox? = nil
	local value: TextLabel? = nil
	local lead: ImageLabel? = nil
	local swatch: Frame? = nil
	local chips: Frame? = nil
	local chevron: ImageLabel? = nil

	local ghost: TextLabel? = nil
	if TYPED[style] then
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, ROW)
		field = frame
		if style == "D5" then
			local glass = newIcon("Search", ICON.search, 16, 0)
			glass.Parent = frame
		end
		local entry = newBox("Search", spec.label, 1)
		entry.Parent = frame
		box = entry

		-- D17 shows the rest of the first match behind the typing, in grey.
		if style == "D17" then
			local hint = newText("Ghost", "", 14, 0)
			hint.Size = UDim2.fromScale(1, 1)
			hint.RichText = true
			hint.TextColor3 = THEME.textMuted
			hint.Parent = entry
			ghost = hint
		end
	elseif style == "D7" or style == "D19" then
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, ROW)
		field = frame
	else
		local button = Instance.new("TextButton")
		button.AutoButtonColor = false
		button.Text = ""
		button.Size = UDim2.new(1, 0, 0, ROW)
		field = button
		fieldButton = button
		if style == "D4" then
			button.AutomaticSize = Enum.AutomaticSize.Y
		end
	end
	field.Name = "Field"
	field.LayoutOrder = 1
	field.BackgroundColor3 = THEME.field
	field.Parent = root
	round(field, 6)
	outline(field)
	pad(field, if style == "D4" then 4 else 0, if style == "D7" or style == "D19" then 0 else 12)
	lineUp(field, Enum.FillDirection.Horizontal, 8)

	if style == "D9" or style == "D10" or style == "D11" then
		local image = if style == "D11" then ICON.search else ""
		local icon = newIcon("Lead", image, if style == "D10" then 24 else 16, 0)
		icon.Parent = field
		lead = icon
	elseif style == "D12" then
		local chip = Instance.new("Frame")
		chip.Name = "Swatch"
		chip.LayoutOrder = 0
		chip.Size = UDim2.fromOffset(20, 20)
		chip.BorderSizePixel = 0
		chip.Parent = field
		round(chip, 6)
		swatch = chip
	end

	if style == "D4" then
		local holder = Instance.new("Frame")
		holder.Name = "Chips"
		holder.LayoutOrder = 1
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.Size = UDim2.fromScale(0, 0)
		holder.BackgroundTransparency = 1
		holder.Parent = field
		fill(holder)
		lineUp(holder, Enum.FillDirection.Horizontal, 4).Wraps = true
		chips = holder
	elseif not box then
		local label = newText("Value", spec.label, 14, 1)
		if style == "D7" then
			label.TextXAlignment = Enum.TextXAlignment.Center
		end
		label.Parent = field
		fill(label)
		value = label
	end

	if style ~= "D5" and style ~= "D7" and style ~= "D11" then
		local mark = newIcon("Chevron", ICON.chevronDown, 16, 2)
		mark.Parent = field
		chevron = mark
	end

	-- D19: the value is a button that runs it; only the arrow opens the list.
	local runButton: TextButton? = nil
	local moreButton: TextButton? = nil
	if style == "D19" then
		local run = Instance.new("TextButton")
		run.Name = "Run"
		run.LayoutOrder = 1
		run.AutoButtonColor = false
		run.Text = ""
		run.Size = UDim2.fromScale(0, 1)
		run.BackgroundColor3 = THEME.field
		run.Parent = field
		round(run, 6)
		pad(run, 0, 12)
		lineUp(run, Enum.FillDirection.Horizontal, 8)
		fill(run)
		if value then
			value.Parent = run
		end
		runButton = run

		local more = Instance.new("TextButton")
		more.Name = "More"
		more.LayoutOrder = 2
		more.AutoButtonColor = false
		more.Text = ""
		more.Size = UDim2.fromOffset(ROW, ROW)
		more.BackgroundColor3 = THEME.field
		more.Parent = field
		round(more, 6)
		local centre = lineUp(more, Enum.FillDirection.Horizontal, 0)
		centre.HorizontalAlignment = Enum.HorizontalAlignment.Center
		if chevron then
			chevron.Parent = more
		end
		moreButton = more
	end

	-- The list: under the field for D6; for the rest, a layer of its own above
	-- the host ScreenGui, so no ScrollingFrame clips it and no ZIndex fight
	-- hides it. The list sits inside a full-screen catcher: a tap outside the
	-- list lands on the catcher and closes it, and the list is Active, so a
	-- tap on it never reaches the catcher.
	local list = Instance.new("CanvasGroup")
	list.Name = "List"
	list.BackgroundColor3 = THEME.surface
	list.GroupTransparency = 1
	list.Visible = false
	round(list, 10)
	outline(list)
	pad(list, LIST_GAP, LIST_GAP)
	lineUp(list, Enum.FillDirection.Vertical, LIST_GAP)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(160, 0)
	bounds.MaxSize = Vector2.new(PALETTE_WIDTH, 320)
	bounds.Parent = list

	local layer: ScreenGui? = nil
	local catcher: TextButton? = nil
	local paletteBox: TextBox? = nil
	if style == "D6" then
		list.LayoutOrder = 2
		list.AutomaticSize = Enum.AutomaticSize.Y
		list.Size = UDim2.fromScale(1, 0)
	else
		local overlay = Instance.new("ScreenGui")
		overlay.Name = "DropdownLayer"
		overlay.ResetOnSpawn = false
		overlay.Enabled = false
		layer = overlay

		local shield = Instance.new("TextButton")
		shield.Name = "Catcher"
		shield.AutoButtonColor = false
		shield.Text = ""
		shield.Selectable = false
		shield.BackgroundTransparency = 1
		shield.Size = UDim2.fromScale(1, 1)
		shield.Parent = overlay
		catcher = shield

		list.Active = true
		if style == "D11" then
			list.AnchorPoint = Vector2.new(0.5, 0)
			list.Position = UDim2.new(0.5, 0, 0.2, 0)
			list.AutomaticSize = Enum.AutomaticSize.Y
			list.Size = UDim2.fromOffset(PALETTE_WIDTH, 0)
			local strip = Instance.new("Frame")
			strip.Name = "SearchRow"
			strip.LayoutOrder = 0
			strip.Size = UDim2.new(1, 0, 0, ROW)
			strip.BackgroundTransparency = 1
			strip.Parent = list
			pad(strip, 0, 8)
			lineUp(strip, Enum.FillDirection.Horizontal, 8)
			newIcon("Search", ICON.search, 16, 0).Parent = strip
			local entry = newBox("Search", `{spec.label}…`, 1)
			entry.Parent = strip
			paletteBox = entry
		end
	end

	list.Parent = if catcher then catcher else root

	-- D20 commits nothing until this is pressed.
	local applyButton: TextButton? = nil
	if style == "D20" then
		local apply = Instance.new("TextButton")
		apply.Name = "Apply"
		apply.LayoutOrder = 2
		apply.AutoButtonColor = false
		apply.Size = UDim2.new(1, 0, 0, ROW)
		apply.BackgroundColor3 = THEME.accent
		apply.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		apply.TextSize = 14
		apply.TextColor3 = THEME.text
		apply.Text = "Apply"
		apply.Parent = list
		round(apply, 6)
		applyButton = apply
	end

	local rows = Instance.new("ScrollingFrame")
	rows.Name = "Rows"
	rows.LayoutOrder = 1
	rows.Size = UDim2.fromScale(1, 0)
	rows.BackgroundTransparency = 1
	rows.BorderSizePixel = 0
	rows.ScrollBarThickness = 4
	rows.ScrollBarImageColor3 = THEME.edge
	rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rows.CanvasSize = UDim2.new()
	rows.Parent = list
	if style == "D18" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(1 / GRID_COLUMNS, -LIST_GAP, 0, GRID_CELL)
		grid.CellPadding = UDim2.fromOffset(LIST_GAP, LIST_GAP)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = rows
	else
		lineUp(rows, Enum.FillDirection.Vertical, 0)
	end

	local refreshField: () -> ()
	local rebuild: () -> ()
	local close: () -> ()

	local function report()
		spec.onChanged(table.clone(chosen))
	end

	local function remember(text: string)
		local at = table.find(recent, text)
		if at then
			table.remove(recent, at)
		end
		table.insert(recent, 1, text)
		if #recent > RECENT_LIMIT then
			table.remove(recent)
		end
	end

	local function choose(text: string)
		local level = if #trail > 0 then trail[#trail].children else nil
		local picked = choiceFor(text, level)
		if style == "D21" and picked and picked.children then
			table.insert(trail, picked)
			rebuild()
			return
		end

		if style == "D20" and pending then
			local at = table.find(pending, text)
			if at then
				table.remove(pending, at)
			else
				table.insert(pending, text)
			end
			rebuild()
			return
		end
		if style == "D14" then
			remember(text)
		end

		if multi then
			local at = table.find(chosen, text)
			if at then
				table.remove(chosen, at)
			else
				table.insert(chosen, text)
			end
			refreshField()
			rebuild()
			report()
			return
		end
		chosen = { text }
		if style == "D5" and box then
			box.Text = text
		end
		refreshField()
		close()
		report()
	end

	local function visibleChoices(): { Choice }
		local shown = {}
		local level: { string | Choice } = choices
		if #trail > 0 then
			level = trail[#trail].children or {}
		end
		for _, option in level do
			local choice = toChoice(option)
			if matches(choice, query) then
				table.insert(shown, choice)
			end
		end
		if style == "D5" and #shown > SUGGESTIONS then
			return { table.unpack(shown, 1, SUGGESTIONS) }
		end
		return shown
	end

	-- `name` and `onPick` let D14, D21 and D22 add rows that are not options:
	-- a repeat of a recent pick, a way back, a way to create one.
	local function addRow(
		choice: Choice,
		order: number,
		name: string?,
		onPick: (() -> ())?
	): TextButton
		local row = Instance.new("TextButton")
		row.Name = name or choice.text
		row.LayoutOrder = order
		row.AutoButtonColor = false
		row.Text = ""
		row.Size = UDim2.new(1, 0, 0, if style == "D13" then TWO_LINE_ROW else ROW)
		row.BackgroundColor3 = THEME.surface
		row.BackgroundTransparency = 0
		row.Parent = rows
		round(row, 6)
		pad(row, 0, if style == "D18" then 4 else 12)
		local rowLayout = lineUp(
			row,
			if style == "D18" then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
			if style == "D18" then 4 else 12
		)
		if style == "D18" then
			rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		end

		local picked = isChosen(choice.text)
		if pending then
			picked = table.find(pending, choice.text) ~= nil
		end
		if multi then
			local tickBox = Instance.new("Frame")
			tickBox.Name = "Box"
			tickBox.LayoutOrder = 0
			tickBox.Size = UDim2.fromOffset(20, 20)
			tickBox.BackgroundColor3 = if picked then THEME.accent else THEME.field
			tickBox.BorderSizePixel = 0
			tickBox.Parent = row
			round(tickBox, 6)
			local tick = newIcon("Tick", ICON.check, 16, 0)
			tick.ImageColor3 = THEME.text
			tick.ImageTransparency = if picked then 0 else 1
			tick.Parent = tickBox
		elseif choice.colour then
			local chip = Instance.new("Frame")
			chip.Name = "Swatch"
			chip.LayoutOrder = 0
			chip.Size = UDim2.fromOffset(20, 20)
			chip.BackgroundColor3 = choice.colour
			chip.BorderSizePixel = 0
			chip.Parent = row
			round(chip, 6)
		elseif choice.icon or choice.image then
			local size = if choice.image or style == "D18" then 24 else 16
			newIcon("Icon", choice.image or choice.icon or "", size, 0).Parent = row
		end

		local words = newText("Label", choice.display or choice.text, 14, 1)
		words.Parent = row
		if style == "D18" then
			words.TextSize = 12
			words.TextXAlignment = Enum.TextXAlignment.Center
			words.Size = UDim2.new(1, 0, 0, 16)
		elseif style == "D13" then
			-- Two lines: the label over its detail, both left aligned.
			local column = Instance.new("Frame")
			column.Name = "Lines"
			column.LayoutOrder = 1
			column.Size = UDim2.fromScale(0, 1)
			column.BackgroundTransparency = 1
			column.Parent = row
			fill(column)
			lineUp(column, Enum.FillDirection.Vertical, 4)

			words.Size = UDim2.new(1, 0, 0, 16)
			words.Parent = column
			local under = newText("Detail", choice.detail or "", 12, 2)
			under.Size = UDim2.new(1, 0, 0, 16)
			under.TextColor3 = THEME.textMuted
			under.Parent = column
		else
			fill(words)
		end
		if choice.children then
			newIcon("Deeper", ICON.chevronRight, 16, 3).Parent = row
		end

		if choice.detail and style ~= "D13" and style ~= "D18" then
			local extra = newText("Detail", choice.detail, 12, 2)
			extra.AutomaticSize = Enum.AutomaticSize.X
			extra.TextColor3 = THEME.textMuted
			extra.Parent = row
		end
		if picked and not multi then
			local tick = newIcon("Tick", ICON.check, 16, 3)
			tick.ImageColor3 = THEME.focus
			tick.Parent = row
		end

		watch(row, rowConnections, function()
			return THEME.surface
		end)
		table.insert(rowConnections, row.Activated:Connect(function()
			if onPick then
				onPick()
			else
				choose(choice.text)
			end
		end))
		return row
	end

	local function addNote(name: string, text: string, order: number)
		local note = newText(name, text, 12, order)
		note.Size = UDim2.new(1, 0, 0, if name == "Empty" then ROW else 24)
		note.TextColor3 = THEME.textMuted
		note.Parent = rows
		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, 12)
		inset.Parent = note
	end

	function rebuild()
		for _, connection in rowConnections do
			connection:Disconnect()
		end
		table.clear(rowConnections)
		for _, child in rows:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local shown = visibleChoices()
		local order, group = 0, nil
		if style == "D14" and query == "" and #recent > 0 then
			order += 1
			addNote("RECENT", "RECENT", order)
			for _, text in recent do
				local choice = choiceFor(text)
				if choice then
					order += 1
					addRow(choice, order, `Recent {text}`)
				end
			end
			order += 1
			addNote("ALL", "ALL", order)
		end

		if #trail > 0 then
			order += 1
			local above = trail[#trail]
			local back = { text = "Back", display = `Back to {above.display or above.text}` }
			addRow(back, order, "Back", function()
				table.remove(trail)
				rebuild()
			end)
		end
		for _, choice in shown do
			if style == "D8" and choice.group and choice.group ~= group then
				group = choice.group
				order += 1
				local heading = (choice.group :: string):upper()
				addNote(heading, heading, order)
			end
			order += 1
			addRow(choice, order)
		end

		-- D22: nothing matches exactly, so offer to add what was typed.
		local exact = choiceFor(query) ~= nil
		if style == "D22" and query ~= "" and not exact then
			order += 1
			local typed = query
			local offer = { text = typed, display = `Add "{typed}"`, icon = ICON.plus }
			addRow(offer, order, "Create", function()
				table.insert(choices, { text = typed })
				if spec.onCreate then
					spec.onCreate(typed)
				end
				choose(typed)
			end)
		elseif #shown == 0 then
			addNote("Empty", if #choices == 0 then "Nothing to choose yet" else "No matches", 1)
		end

		if style == "D18" then
			local lines = math.clamp(math.ceil(order / GRID_COLUMNS), 1, 3)
			rows.Size = UDim2.new(1, 0, 0, lines * (GRID_CELL + LIST_GAP))
		else
			local height = if style == "D13" then TWO_LINE_ROW else ROW
			rows.Size = UDim2.new(1, 0, 0, math.clamp(order, 1, VISIBLE_ROWS) * height)
		end
	end

	-- D4: one chip per chosen value, or the label while nothing is chosen.
	local function drawChips(holder: Frame)
		for _, child in holder:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for index, text in chosen do
			local chip = newText(text, text, 12, index)
			chip.AutomaticSize = Enum.AutomaticSize.X
			chip.Size = UDim2.fromOffset(0, 32)
			chip.BackgroundTransparency = 0
			chip.BackgroundColor3 = THEME.accentDim
			chip.Parent = holder
			round(chip, 6)
			pad(chip, 0, 8)
		end
		if #chosen == 0 then
			local hint = newText("Placeholder", spec.label, 14, 0)
			hint.AutomaticSize = Enum.AutomaticSize.X
			hint.Size = UDim2.fromOffset(0, 32)
			hint.TextColor3 = THEME.textMuted
			hint.Parent = holder
		end
	end

	function refreshField()
		local first = choiceFor(chosen[1] or "")
		if value then
			local text = if #chosen == 0 then spec.label
				elseif multi and #chosen > 1 then `{#chosen} selected`
				elseif first then first.display or first.text
				else chosen[1]
			value.Text = text
			value.TextColor3 = if #chosen == 0 then THEME.textMuted else THEME.text
		end
		if lead and style ~= "D11" then
			lead.Image = if first then first.image or first.icon or "" else ""
			lead.Visible = first ~= nil
		end
		if swatch then
			swatch.BackgroundColor3 = if first and first.colour then first.colour else THEME.field
		end
		if chips then
			drawChips(chips)
		end
	end

	-- Places the floating list under the field, or above it when the screen
	-- has no room below. The layer copies the host's inset settings, so a
	-- position measured against the layer lands where the field is.
	local function place(overlay: ScreenGui)
		if style == "D11" then
			return
		end
		local extra = if applyButton then ROW + LIST_GAP else 0
		local height = rows.Size.Y.Offset + LIST_GAP * 2 + extra
		-- D16 is a sheet along the bottom edge instead of a list at the field.
		if style == "D16" then
			list.AnchorPoint = Vector2.new(0.5, 1)
			list.Size = UDim2.fromOffset(math.min(overlay.AbsoluteSize.X, PALETTE_WIDTH), height)
			list.Position = UDim2.new(0.5, 0, 1, 0)
			return
		end
		local top = field.AbsolutePosition - overlay.AbsolutePosition
		local below = top.Y + field.AbsoluteSize.Y + LIST_GAP
		local above = top.Y - height - LIST_GAP
		local fits = below + height <= overlay.AbsoluteSize.Y
		-- D15 opens upward whenever there is room, for fields near the bottom.
		local y = if style == "D15" and above >= 0 then above elseif fits then below else above
		list.Size = UDim2.fromOffset(field.AbsoluteSize.X, height)
		list.Position = UDim2.fromOffset(top.X, y)
	end

	local function open()
		if isOpen or style == "D7" then
			return
		end
		isOpen = true
		ticket += 1
		if style == "D20" then
			pending = table.clone(chosen)
		end
		rebuild()

		local overlay = layer
		if overlay then
			local host = spec.host or field:FindFirstAncestorWhichIsA("ScreenGui")
			assert(host, "the dropdown must be inside a ScreenGui before it opens")
			overlay.DisplayOrder = host.DisplayOrder + 1
			overlay.ScreenInsets = host.ScreenInsets
			overlay.Parent = host.Parent
			overlay.Enabled = true
			place(overlay)
		end
		list.Visible = true
		animate(list, OPEN, { GroupTransparency = 0 })

		if style == "D16" and catcher then
			catcher.BackgroundColor3 = THEME.scrim
			animate(catcher, OPEN, { BackgroundTransparency = SCRIM_TRANSPARENCY })
			list.Position = UDim2.new(0.5, 0, 1, list.Size.Y.Offset)
			animate(list, OPEN, { Position = UDim2.new(0.5, 0, 1, 0) })
		end
		if chevron then
			animate(chevron, OPEN, { Rotation = 180 })
		end
		if paletteBox then
			paletteBox:CaptureFocus()
		end
		if UserInputService.GamepadEnabled then
			GuiService.SelectedObject = rows:FindFirstChildWhichIsA("GuiButton")
		end
	end

	function close()
		if not isOpen then
			return
		end
		isOpen = false
		ticket += 1
		local mine = ticket
		local overlay = layer
		if chevron then
			animate(chevron, SHUT, { Rotation = 0 })
		end
		pending = nil
		table.clear(trail)
		if style == "D16" and catcher then
			animate(catcher, SHUT, { BackgroundTransparency = 1 })
			animate(list, SHUT, { Position = UDim2.new(0.5, 0, 1, list.Size.Y.Offset) })
		end
		animate(list, SHUT, { GroupTransparency = 1 }).Completed:Once(function()
			if mine == ticket then
				list.Visible = false
				if overlay then
					overlay.Enabled = false
				end
			end
		end)
		if paletteBox then
			paletteBox.Text = ""
		end
	end

	local function toggle()
		if isOpen then
			close()
		else
			open()
		end
	end

	local function setOptions(options: { string | Choice })
		table.clear(choices)
		for _, option in options do
			table.insert(choices, toChoice(option))
		end
		if isOpen then
			rebuild()
		end
		refreshField()
	end

	-- D7: arrows step through the options and wrap at either end.
	local function step(by: number)
		if #choices == 0 then
			return
		end
		local at = 1
		for index, choice in choices do
			if choice.text == chosen[1] then
				at = index
			end
		end
		local nextIndex = (at - 1 + by) % #choices + 1
		chosen = { choices[nextIndex].text }
		refreshField()
		report()
	end

	if style == "D7" then
		for index, direction in { -1, 1 } do
			local arrow = Instance.new("ImageButton")
			arrow.Name = if direction < 0 then "Previous" else "Next"
			arrow.LayoutOrder = if index == 1 then 0 else 2
			arrow.Size = UDim2.fromOffset(ROW, ROW)
			arrow.AutoButtonColor = false
			arrow.BackgroundColor3 = THEME.field
			arrow.Image = ""
			arrow.Parent = field
			round(arrow, 6)

			local image = if direction < 0 then ICON.chevronLeft else ICON.chevronRight
			newIcon("Mark", image, 16, 0).Parent = arrow
			local centre = lineUp(arrow, Enum.FillDirection.Horizontal, 0)
			centre.HorizontalAlignment = Enum.HorizontalAlignment.Center
			watch(arrow, connections, function()
				return THEME.field
			end)
			table.insert(connections, arrow.Activated:Connect(function()
				step(direction)
			end))
		end
	end

	if fieldButton then
		watch(fieldButton, connections, function()
			return THEME.field
		end)
		table.insert(connections, fieldButton.Activated:Connect(toggle))
	end
	if runButton and moreButton then
		for _, button in { runButton, moreButton } do
			watch(button, connections, function()
				return THEME.field
			end)
		end
		table.insert(connections, moreButton.Activated:Connect(toggle))
		table.insert(connections, runButton.Activated:Connect(function()
			if spec.onRun and chosen[1] then
				spec.onRun(chosen[1])
			end
		end))
	end
	if applyButton then
		table.insert(connections, applyButton.Activated:Connect(function()
			if pending then
				chosen = table.clone(pending)
			end
			refreshField()
			close()
			report()
		end))
	end
	if catcher then
		table.insert(connections, catcher.Activated:Connect(close))
	end

	-- Typing filters; Enter picks the first match, as a search box would.
	local typing = box or paletteBox
	if typing then
		local entry = typing
		-- D17: the grey rest of the first option that starts with the typing.
		local function suggest()
			local hint = ghost
			if not hint then
				return
			end
			local lowered = query:lower()
			for _, choice in visibleChoices() do
				local word = choice.display or choice.text
				if query ~= "" and word:lower():sub(1, #query) == lowered then
					local rest = escape(word:sub(#query + 1))
					hint.Text = `<font transparency="1">{escape(query)}</font>{rest}`
					return
				end
			end
			hint.Text = ""
		end

		table.insert(connections, entry:GetPropertyChangedSignal("Text"):Connect(function()
			query = entry.Text
			suggest()
			if style == "D5" and query == "" then
				close()
				return
			end
			if isOpen then
				rebuild()
				if layer then
					place(layer)
				end
			elseif entry.Text ~= "" and style ~= "D11" then
				open()
			end
		end))
		table.insert(connections, entry.FocusLost:Connect(function(enterPressed: boolean)
			if not enterPressed then
				return
			end
			local first = visibleChoices()[1]
			if first then
				choose(first.text)
			end
		end))
		if style == "D2" or style == "D17" or style == "D22" then
			table.insert(connections, entry.Focused:Connect(open))
		end
	end

	table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject)
		if isOpen and input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
		-- D17: Tab accepts the grey completion.
		local entry = box
		if style == "D17" and entry and input.KeyCode == Enum.KeyCode.Tab and entry:IsFocused() then
			local first = visibleChoices()[1]
			if first then
				entry.Text = first.display or first.text
			end
		end
	end))

	if style == "D10" then
		table.insert(connections, Players.PlayerAdded:Connect(function()
			setOptions(playerChoices())
		end))
		-- A chosen player who leaves is no longer a valid target.
		table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
			task.defer(function()
				setOptions(playerChoices())
				if isChosen(player.Name) then
					table.remove(chosen, table.find(chosen, player.Name) :: number)
					refreshField()
					report()
				end
			end)
		end))
		setOptions(playerChoices())
	else
		setOptions(spec.options)
	end
	root.Parent = parent

	return {
		root = root,
		get = function()
			return table.clone(chosen)
		end,
		set = function(next: { string })
			chosen = table.clone(next)
			refreshField()
			if isOpen then
				rebuild()
			end
		end,
		setOptions = setOptions,
		open = open,
		close = close,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			for _, connection in rowConnections do
				connection:Disconnect()
			end
			list:Destroy()
			if layer then
				layer:Destroy()
			end
			root:Destroy()
		end,
	}
end

return createDropdown
