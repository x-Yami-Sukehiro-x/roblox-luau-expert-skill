--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local gethui = gethui or get_hidden_gui
assert(gethui and getgenv, "needs gethui and getgenv")

local TOKENS = table.freeze({
	page = Color3.fromRGB(9, 10, 13),
	base = Color3.fromRGB(31, 34, 41),
	raised = Color3.fromRGB(44, 48, 57),
	overlay = Color3.fromRGB(63, 68, 79),
	border = Color3.fromRGB(63, 68, 79),
	textPrimary = Color3.fromRGB(243, 245, 248),
	textSecondary = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentBright = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	danger = Color3.fromRGB(208, 88, 82),
})

local ICONS = table.freeze({
	close = "rbxassetid://116396312853810",
	check = "rbxassetid://86817768619372",
	info = "rbxassetid://120620848266512",
	warning = "rbxassetid://91165848022002",
	danger = "rbxassetid://106305483906363",
	drag = "rbxassetid://136050395759142",
})

local TOUCH_TARGET = 44
local ICON_INK = 16
local PANEL_RADIUS = UDim.new(0, 10)
local CONTROL_RADIUS = UDim.new(0, 6)

local ENTER_SECONDS = 0.2
local EXIT_SECONDS = 0.15
local PRESS_SECONDS = 0.08
local TOAST_HOLD_SECONDS = 4

-- Severity changes the icon and the edge, never the fill: a toast tinted
-- end-to-end competes with the panel beside it and the game behind it.
local SEVERITY = table.freeze({
	info = { tint = TOKENS.info, icon = ICONS.info },
	success = { tint = TOKENS.success, icon = ICONS.check },
	warning = { tint = TOKENS.warning, icon = ICONS.warning },
	danger = { tint = TOKENS.danger, icon = ICONS.danger },
})

local PRESS_INPUTS = table.freeze({
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
})

local connections: { RBXScriptConnection } = {}
local threads: { thread } = {}

local function track(connection: RBXScriptConnection): RBXScriptConnection
	table.insert(connections, connection)
	return connection
end

local function ease(instance: Instance, seconds: number, goals: { [string]: any }): Tween
	local direction = if seconds == ENTER_SECONDS
		then Enum.EasingDirection.Out
		else Enum.EasingDirection.In
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, Enum.EasingStyle.Cubic, direction),
		goals
	)
	tween:Play()
	return tween
end

local screen = Instance.new("ScreenGui")
screen.Name = "Hub"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = gethui()

-- CanvasGroup, not Frame: the rounded corner clips the composited layer, so an
-- opaque child reaching the edge cannot draw a square corner over it.
local panel = Instance.new("CanvasGroup")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.34, 0.52)
panel.BackgroundColor3 = TOKENS.base
panel.BorderSizePixel = 0
panel.GroupTransparency = 1
panel.Parent = screen

local panelBounds = Instance.new("UISizeConstraint")
panelBounds.MinSize = Vector2.new(300, 260)
panelBounds.MaxSize = Vector2.new(460, 560)
panelBounds.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = PANEL_RADIUS
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = TOKENS.border
panelStroke.Thickness = 1
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 12)
panelPadding.PaddingBottom = UDim.new(0, 12)
panelPadding.PaddingLeft = UDim.new(0, 12)
panelPadding.PaddingRight = UDim.new(0, 12)
panelPadding.Parent = panel

local panelColumn = Instance.new("UIListLayout")
panelColumn.FillDirection = Enum.FillDirection.Vertical
panelColumn.SortOrder = Enum.SortOrder.LayoutOrder
panelColumn.Padding = UDim.new(0, 12)
panelColumn.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.LayoutOrder = 1
header.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
header.BackgroundTransparency = 1
header.Parent = panel

local headerRow = Instance.new("UIListLayout")
headerRow.FillDirection = Enum.FillDirection.Horizontal
headerRow.VerticalAlignment = Enum.VerticalAlignment.Center
headerRow.SortOrder = Enum.SortOrder.LayoutOrder
headerRow.Padding = UDim.new(0, 8)
headerRow.Parent = header

local grip = Instance.new("ImageLabel")
grip.Name = "Grip"
grip.LayoutOrder = 1
grip.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
grip.BackgroundTransparency = 1
grip.Image = ICONS.drag
grip.ImageColor3 = TOKENS.textSecondary
grip.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 2
title.AutomaticSize = Enum.AutomaticSize.X
title.Size = UDim2.fromScale(0, 1)
title.BackgroundTransparency = 1
title.Text = "Field Kit"
title.TextColor3 = TOKENS.textPrimary
title.TextSize = 16
title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
-- Center, not the Top a TextLabel defaults to in a fixed-height row. This one
-- property is the whole "the title sits slightly high" complaint.
title.TextYAlignment = Enum.TextYAlignment.Center
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- The gap is an element the layout can size, not a Position offset that stops
-- being right the moment the panel is a different width.
local slack = Instance.new("Frame")
slack.Name = "Slack"
slack.LayoutOrder = 3
slack.BackgroundTransparency = 1
slack.Parent = header

local slackFill = Instance.new("UIFlexItem")
slackFill.FlexMode = Enum.UIFlexMode.Fill
slackFill.Parent = slack

local close = Instance.new("ImageButton")
close.Name = "Close"
close.LayoutOrder = 4
close.Size = UDim2.fromOffset(TOUCH_TARGET, TOUCH_TARGET)
close.BackgroundColor3 = TOKENS.raised
close.BackgroundTransparency = 1
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Image = ""
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = CONTROL_RADIUS
closeCorner.Parent = close

-- 44 px of reach, 16 px of ink. Sizing the glyph as the button is the reason
-- close buttons are hard to hit on a phone.
local closeInk = Instance.new("ImageLabel")
closeInk.Name = "Ink"
closeInk.AnchorPoint = Vector2.new(0.5, 0.5)
closeInk.Position = UDim2.fromScale(0.5, 0.5)
closeInk.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
closeInk.BackgroundTransparency = 1
closeInk.Image = ICONS.close
closeInk.ImageColor3 = TOKENS.textSecondary
closeInk.Parent = close

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.LayoutOrder = 2
body.Size = UDim2.fromScale(1, 0)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 2
body.ScrollBarImageColor3 = TOKENS.overlay
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel

local bodyFill = Instance.new("UIFlexItem")
bodyFill.FlexMode = Enum.UIFlexMode.Fill
bodyFill.Parent = body

local bodyColumn = Instance.new("UIListLayout")
bodyColumn.FillDirection = Enum.FillDirection.Vertical
bodyColumn.SortOrder = Enum.SortOrder.LayoutOrder
bodyColumn.Padding = UDim.new(0, 8)
bodyColumn.Parent = body

local empty = Instance.new("TextLabel")
empty.Name = "Empty"
empty.LayoutOrder = 1
empty.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
empty.BackgroundTransparency = 1
empty.Text = "No modules loaded for this place"
empty.TextColor3 = TOKENS.textSecondary
empty.TextSize = 14
empty.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
empty.TextYAlignment = Enum.TextYAlignment.Center
empty.Parent = body

local toasts = Instance.new("Frame")
toasts.Name = "Toasts"
toasts.AnchorPoint = Vector2.new(1, 1)
toasts.Position = UDim2.new(1, -16, 1, -16)
toasts.Size = UDim2.fromScale(0.3, 0.6)
toasts.BackgroundTransparency = 1
toasts.Parent = screen

local toastBounds = Instance.new("UISizeConstraint")
toastBounds.MinSize = Vector2.new(240, 80)
toastBounds.MaxSize = Vector2.new(320, 480)
toastBounds.Parent = toasts

local toastColumn = Instance.new("UIListLayout")
toastColumn.FillDirection = Enum.FillDirection.Vertical
toastColumn.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastColumn.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastColumn.SortOrder = Enum.SortOrder.LayoutOrder
toastColumn.Padding = UDim.new(0, 8)
toastColumn.Parent = toasts

local toastOrder = 0

local function notify(severity: string, message: string)
	local level = SEVERITY[severity]
	if not level then
		error(("unknown severity %q"):format(severity), 2)
	end

	toastOrder += 1

	-- Same fill, same radius, same stroke as the panel. One token entry decides
	-- what "floating" looks like, so the two cannot drift apart on a re-theme.
	local card = Instance.new("CanvasGroup")
	card.Name = "Toast"
	card.LayoutOrder = toastOrder
	card.Size = UDim2.new(1, 0, 0, TOUCH_TARGET + 16)
	card.BackgroundColor3 = TOKENS.overlay
	card.BorderSizePixel = 0
	card.GroupTransparency = 1
	card.Parent = toasts

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = PANEL_RADIUS
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = TOKENS.border
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local edge = Instance.new("Frame")
	edge.Name = "Edge"
	edge.Size = UDim2.new(0, 2, 1, 0)
	edge.BackgroundColor3 = level.tint
	edge.BorderSizePixel = 0
	edge.Parent = card

	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 12)
	cardPadding.PaddingBottom = UDim.new(0, 12)
	cardPadding.PaddingLeft = UDim.new(0, 12)
	cardPadding.PaddingRight = UDim.new(0, 12)
	cardPadding.Parent = card

	local cardRow = Instance.new("UIListLayout")
	cardRow.FillDirection = Enum.FillDirection.Horizontal
	cardRow.VerticalAlignment = Enum.VerticalAlignment.Center
	cardRow.SortOrder = Enum.SortOrder.LayoutOrder
	cardRow.Padding = UDim.new(0, 8)
	cardRow.Parent = card

	-- The icon carries the severity as well as the hue: red and green are the
	-- same toast to a red-green colourblind reader.
	local badge = Instance.new("ImageLabel")
	badge.Name = "Badge"
	badge.LayoutOrder = 1
	badge.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
	badge.BackgroundTransparency = 1
	badge.Image = level.icon
	badge.ImageColor3 = level.tint
	badge.Parent = card

	local text = Instance.new("TextLabel")
	text.Name = "Message"
	text.LayoutOrder = 2
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.Text = message
	text.TextColor3 = TOKENS.textPrimary
	text.TextSize = 14
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Parent = card

	local textFill = Instance.new("UIFlexItem")
	textFill.FlexMode = Enum.UIFlexMode.Fill
	textFill.Parent = text

	ease(card, ENTER_SECONDS, { GroupTransparency = 0 })

	-- Timed from arrival, not from the queue: a toast that waited behind two
	-- others has still only been readable since it appeared.
	table.insert(threads, task.delay(TOAST_HOLD_SECONDS, function()
		ease(card, EXIT_SECONDS, { GroupTransparency = 1 }).Completed:Wait()
		card:Destroy()
	end))
end

local function paint(button: ImageButton | TextButton, transparency: number, seconds: number)
	ease(button, seconds, { BackgroundTransparency = transparency })
end

local function wireStates(button: ImageButton | TextButton)
	track(button.MouseEnter:Connect(function()
		paint(button, 0, ENTER_SECONDS)
	end))
	track(button.MouseLeave:Connect(function()
		paint(button, 1, EXIT_SECONDS)
	end))
	-- InputBegan rather than MouseButton1Down, which never fires on a phone. The
	-- press state is the one a touch user sees most and the one most often
	-- wired mouse-only.
	track(button.InputBegan:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, 0.4, PRESS_SECONDS)
		end
	end))
	track(button.InputEnded:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, 0, PRESS_SECONDS)
		end
	end))
	-- SelectionGained is the gamepad and keyboard path. Without it, a focus ring
	-- never appears and the panel is unusable on a console.
	track(button.SelectionGained:Connect(function()
		panelStroke.Color = TOKENS.accentBright
	end))
	track(button.SelectionLost:Connect(function()
		panelStroke.Color = TOKENS.border
	end))
end

local function addToggle(label: string, order: number, onChanged: (boolean) -> ())
	empty.Visible = false

	local row = Instance.new("TextButton")
	row.Name = label
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
	row.BackgroundColor3 = TOKENS.raised
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.Selectable = true
	row.Parent = body

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = CONTROL_RADIUS
	rowCorner.Parent = row

	local rowPadding = Instance.new("UIPadding")
	rowPadding.PaddingLeft = UDim.new(0, 12)
	rowPadding.PaddingRight = UDim.new(0, 12)
	rowPadding.Parent = row

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = row

	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.LayoutOrder = 1
	caption.Size = UDim2.fromScale(0, 1)
	caption.BackgroundTransparency = 1
	caption.Text = label
	caption.TextColor3 = TOKENS.textPrimary
	caption.TextSize = 14
	caption.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.TextYAlignment = Enum.TextYAlignment.Center
	caption.Parent = row

	local captionFill = Instance.new("UIFlexItem")
	captionFill.FlexMode = Enum.UIFlexMode.Fill
	captionFill.Parent = caption

	local pip = Instance.new("Frame")
	pip.Name = "Pip"
	pip.LayoutOrder = 2
	pip.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
	pip.BackgroundColor3 = TOKENS.overlay
	pip.BorderSizePixel = 0
	pip.Parent = row

	local pipCorner = Instance.new("UICorner")
	pipCorner.CornerRadius = CONTROL_RADIUS
	pipCorner.Parent = pip

	local enabled = false
	wireStates(row)

	-- Activated, not MouseButton1Click: it fires for touch, gamepad and the
	-- selection system as well as a mouse.
	track(row.Activated:Connect(function()
		enabled = not enabled
		pip.BackgroundColor3 = if enabled then TOKENS.accent else TOKENS.overlay
		onChanged(enabled)
	end))
end

local function unload()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, running in threads do
		task.cancel(running)
	end
	table.clear(threads)
	screen:Destroy()
end

wireStates(close)
track(close.Activated:Connect(function()
	ease(panel, EXIT_SECONDS, { GroupTransparency = 1 }).Completed:Wait()
	unload()
end))

track(UserInputService.InputBegan:Connect(function(input: InputObject, typing: boolean)
	if typing or input.KeyCode ~= Enum.KeyCode.RightShift then
		return
	end
	panel.Visible = not panel.Visible
end))

addToggle("Highlight nearby players", 2, function(enabled)
	local level = if enabled then "success" else "info"
	notify(level, if enabled then "Highlights on" else "Highlights off")
end)

addToggle("Log remote traffic", 3, function(enabled)
	local level = if enabled then "warning" else "info"
	notify(level, if enabled then "Logging every remote" else "Logging stopped")
end)

getgenv().UnloadFieldKit = unload

ease(panel, ENTER_SECONDS, { GroupTransparency = 0 })
notify("info", ("Loaded for %s"):format(Players.LocalPlayer.Name))
