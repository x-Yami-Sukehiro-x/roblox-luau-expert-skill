--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

export type Severity = "info" | "success" | "warning" | "error"

local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	tile = Color3.fromRGB(28, 88, 74),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	action = Color3.fromRGB(72, 201, 162),
	outline = Color3.fromRGB(9, 10, 13),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	trophy = "rbxassetid://113055182645565",
}

local ENTER = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local ARRIVE = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SWEEP = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local INSTANT = TweenInfo.new(0)

local ACHIEVEMENT_HOLD = 4
local SNACK_HOLD = 4
local SNACK_ACTION_HOLD = 6
local FEED_HOLD = 4
local FEED_LINES = 6
local FEED_DIM = 0.2

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function readingTime(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.clamp(2 + words * 0.3, 3, 8)
end

local function tween(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
	local playing = TweenService:Create(target, motion(timing), goals)
	playing:Play()
	return playing
end

local function round(target: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
end

local function outline(target: GuiObject)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = target
end

local function pad(target: GuiObject, vertical: number, horizontal: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, vertical)
	padding.PaddingBottom = UDim.new(0, vertical)
	padding.PaddingLeft = UDim.new(0, horizontal)
	padding.PaddingRight = UDim.new(0, horizontal)
	padding.Parent = target
end

local function line(parent: GuiObject, gap: number, direction: Enum.FillDirection): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

local function words(name: string, text: string, size: number, bold: boolean): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	return label
end

-- N15: a card that drops in at the top centre, a light passes across it once,
-- and it leaves after four seconds. Returns a dismiss that is safe to repeat.
local function showAchievement(
	screen: ScreenGui,
	title: string,
	detail: string,
	icon: string?
): () -> ()
	local gone = false

	local card = Instance.new("CanvasGroup")
	card.Name = "Achievement"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundColor3 = THEME.surface
	card.GroupTransparency = 1
	card.Parent = screen
	round(card, 10)
	outline(card)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(400, math.huge)
	bounds.Parent = card

	-- The layout lives one level down so the sweeping light is free to move.
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AutomaticSize = Enum.AutomaticSize.XY
	content.BackgroundTransparency = 1
	content.Parent = card
	pad(content, 12, 12)
	line(content, 12, Enum.FillDirection.Horizontal)

	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.LayoutOrder = 1
	tile.Size = UDim2.fromOffset(48, 48)
	tile.BackgroundColor3 = THEME.tile
	tile.BorderSizePixel = 0
	tile.Parent = content
	round(tile, 6)

	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Glyph"
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromOffset(24, 24)
	glyph.BackgroundTransparency = 1
	glyph.Image = icon or ICON.trophy
	glyph.ImageColor3 = THEME.action
	glyph.Parent = tile

	local column = Instance.new("Frame")
	column.Name = "Words"
	column.LayoutOrder = 2
	column.AutomaticSize = Enum.AutomaticSize.XY
	column.BackgroundTransparency = 1
	column.Parent = content
	line(column, 4, Enum.FillDirection.Vertical)

	local heading = words("Title", title, 16, true)
	heading.LayoutOrder = 1
	heading.Parent = column

	local note = words("Detail", detail, 12, false)
	note.LayoutOrder = 2
	note.TextColor3 = THEME.textMuted
	note.Parent = column

	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Position = UDim2.fromScale(-0.5, 0)
	shine.Size = UDim2.fromScale(0.5, 1)
	shine.BackgroundColor3 = THEME.text
	shine.BorderSizePixel = 0
	shine.Parent = card

	local band = Instance.new("UIGradient")
	band.Rotation = 20
	band.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	band.Parent = shine

	local function dismiss()
		if gone then
			return
		end
		gone = true
		tween(card, EXIT, { Position = UDim2.new(0.5, 0, 0, 8) })
		tween(card, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
			card:Destroy()
		end)
	end

	local reduced = GuiService.ReducedMotionEnabled
	card.Position = UDim2.new(0.5, 0, 0, if reduced then 16 else 0)
	tween(card, ARRIVE, { Position = UDim2.new(0.5, 0, 0, 16), GroupTransparency = 0 })
	shine.Visible = not reduced
	tween(shine, SWEEP, { Position = UDim2.fromScale(1, 0) })
	task.delay(ACHIEVEMENT_HOLD, dismiss)
	return dismiss
end

-- N16: large words in the middle of the screen for a moment that matters to
-- everyone, such as a round starting. A new line replaces the one showing.
local function createAnnouncer(screen: ScreenGui)
	local ticket = 0

	local banner = words("Announcement", "", 28, true)
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.35)
	banner.TextXAlignment = Enum.TextXAlignment.Center
	banner.TextTransparency = 1
	banner.Visible = false
	banner.Parent = screen

	-- The world behind is any colour, so the words carry their own dark edge.
	local rim = Instance.new("UIStroke")
	rim.Color = THEME.outline
	rim.Thickness = 2
	rim.Transparency = 1
	rim.Parent = banner

	local grow = Instance.new("UIScale")
	grow.Parent = banner

	local function show(message: string)
		ticket += 1
		local mine = ticket
		banner.Text = message
		banner.Visible = true
		grow.Scale = if GuiService.ReducedMotionEnabled then 1 else 0.9
		tween(grow, ENTER, { Scale = 1 })
		tween(banner, ENTER, { TextTransparency = 0 })
		tween(rim, ENTER, { Transparency = 0 })
		task.delay(readingTime(message), function()
			if mine ~= ticket then
				return
			end
			tween(rim, EXIT, { Transparency = 1 })
			tween(banner, EXIT, { TextTransparency = 1 }).Completed:Once(function()
				if mine == ticket then
					banner.Visible = false
				end
			end)
		end)
	end

	return {
		show = show,
		destroy = function()
			ticket += 1
			banner:Destroy()
		end,
	}
end

-- N18: one bar at the bottom with an optional action on its right. A new
-- message replaces the old one; the action runs once and closes the bar.
local function createSnackbar(screen: ScreenGui)
	local ticket = 0
	local onAction: (() -> ())? = nil
	local connections: { RBXScriptConnection } = {}

	local bar = Instance.new("CanvasGroup")
	bar.Name = "Snackbar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.AutomaticSize = Enum.AutomaticSize.Y
	bar.Size = UDim2.new(1, -32, 0, 0)
	bar.BackgroundColor3 = THEME.surface
	bar.GroupTransparency = 1
	bar.Visible = false
	bar.Parent = screen
	round(bar, 10)
	outline(bar)
	pad(bar, 4, 16)
	line(bar, 12, Enum.FillDirection.Horizontal)

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(560, math.huge)
	bounds.Parent = bar

	local message = words("Message", "", 14, false)
	message.LayoutOrder = 1
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.Size = UDim2.fromScale(0, 0)
	message.TextWrapped = true
	message.Parent = bar

	local grow = Instance.new("UIFlexItem")
	grow.FlexMode = Enum.UIFlexMode.Fill
	grow.Parent = message

	local action = Instance.new("TextButton")
	action.Name = "Action"
	action.LayoutOrder = 2
	action.AutoButtonColor = false
	action.AutomaticSize = Enum.AutomaticSize.X
	action.Size = UDim2.fromOffset(0, 44)
	action.BackgroundTransparency = 1
	action.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	action.TextSize = 14
	action.TextColor3 = THEME.action
	action.Text = ""
	action.Visible = false
	action.Parent = bar

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.action
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = action

	local function hide()
		ticket += 1
		local mine = ticket
		onAction = nil
		tween(bar, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
			if mine == ticket then
				bar.Visible = false
			end
		end)
	end

	local function show(text: string, actionLabel: string?, run: (() -> ())?)
		ticket += 1
		local mine = ticket
		message.Text = text
		onAction = run
		action.Text = actionLabel or ""
		action.Visible = actionLabel ~= nil and run ~= nil
		if not bar.Visible then
			bar.Visible = true
			bar.Position = UDim2.new(0.5, 0, 1, if GuiService.ReducedMotionEnabled then -16 else 0)
		end
		tween(bar, ENTER, { Position = UDim2.new(0.5, 0, 1, -16), GroupTransparency = 0 })
		task.delay(if action.Visible then SNACK_ACTION_HOLD else SNACK_HOLD, function()
			if mine == ticket then
				hide()
			end
		end)
	end

	table.insert(connections, action.Activated:Connect(function()
		local run = onAction
		hide()
		if run then
			run()
		end
	end))
	table.insert(connections, action.MouseEnter:Connect(function()
		action.TextColor3 = THEME.text
	end))
	table.insert(connections, action.MouseLeave:Connect(function()
		action.TextColor3 = THEME.action
	end))
	table.insert(connections, action.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, action.SelectionLost:Connect(function()
		ring.Enabled = false
	end))

	return {
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			bar:Destroy()
		end,
	}
end

-- N20: short lines stacking in the top-right corner, newest at the bottom, each
-- fading after four seconds. Six at most; a seventh pushes the oldest out.
local function createFeed(screen: ScreenGui)
	local count = 0
	local lines: { CanvasGroup } = {}

	local feed = Instance.new("Frame")
	feed.Name = "Feed"
	feed.AnchorPoint = Vector2.new(1, 0)
	feed.Position = UDim2.new(1, -16, 0, 16)
	feed.AutomaticSize = Enum.AutomaticSize.Y
	feed.Size = UDim2.fromOffset(280, 0)
	feed.BackgroundTransparency = 1
	feed.Parent = screen
	line(feed, 4, Enum.FillDirection.Vertical).HorizontalAlignment = Enum.HorizontalAlignment.Right

	local function remove(entry: CanvasGroup)
		local index = table.find(lines, entry)
		if not index then
			return
		end
		table.remove(lines, index)
		tween(entry, EXIT, { GroupTransparency = 1 }).Completed:Once(function()
			entry:Destroy()
		end)
	end

	local function push(text: string, severity: Severity?)
		count += 1
		if #lines >= FEED_LINES then
			remove(lines[1])
		end

		local entry = Instance.new("CanvasGroup")
		entry.Name = "Line"
		entry.LayoutOrder = count
		entry.AutomaticSize = Enum.AutomaticSize.XY
		entry.BackgroundColor3 = THEME.surface
		entry.BackgroundTransparency = FEED_DIM
		entry.GroupTransparency = 1
		round(entry, 6)
		pad(entry, 4, 8)
		line(entry, 8, Enum.FillDirection.Horizontal)

		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.LayoutOrder = 1
		dot.Size = UDim2.fromOffset(8, 8)
		dot.BackgroundColor3 = THEME[severity or "info"]
		dot.BorderSizePixel = 0
		dot.Parent = entry
		round(dot, 4)

		local label = words("Text", text, 14, false)
		label.LayoutOrder = 2
		label.Parent = entry

		entry.Parent = feed
		table.insert(lines, entry)
		tween(entry, ENTER, { GroupTransparency = 0 })
		task.delay(FEED_HOLD, remove, entry)
	end

	return {
		push = push,
		destroy = function()
			table.clear(lines)
			feed:Destroy()
		end,
	}
end

return {
	showAchievement = showAchievement,
	createAnnouncer = createAnnouncer,
	createSnackbar = createSnackbar,
	createFeed = createFeed,
}
