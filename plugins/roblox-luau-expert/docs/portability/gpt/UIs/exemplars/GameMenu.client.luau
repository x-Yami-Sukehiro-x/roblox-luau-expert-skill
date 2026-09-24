--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TOKENS = table.freeze({
	page = Color3.fromRGB(9, 10, 13),
	base = Color3.fromRGB(31, 34, 41),
	raised = Color3.fromRGB(44, 48, 57),
	overlay = Color3.fromRGB(63, 68, 79),
	border = Color3.fromRGB(63, 68, 79),
	textPrimary = Color3.fromRGB(243, 245, 248),
	textSecondary = Color3.fromRGB(150, 157, 170),
	textMuted = Color3.fromRGB(96, 103, 117),
	accent = Color3.fromRGB(46, 160, 127),
	accentBright = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
})

local ICONS = table.freeze({
	close = "rbxassetid://116396312853810",
	loading = "rbxassetid://71250150569964",
	alert = "rbxassetid://91165848022002",
})

local TOUCH_TARGET = 44
local ICON_INK = 16
local PANEL_RADIUS = UDim.new(0, 10)
local CONTROL_RADIUS = UDim.new(0, 6)
local ENTER_SECONDS = 0.2
local EXIT_SECONDS = 0.15

local PRESS_INPUTS = table.freeze({
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
})

local TABS = table.freeze({ "Controls", "Audio", "Graphics" })

local connections: { RBXScriptConnection } = {}

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
screen.Name = "SettingsMenu"
screen.ResetOnSpawn = false
screen.Enabled = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local scrim = Instance.new("TextButton")
scrim.Name = "Scrim"
scrim.Size = UDim2.fromScale(1, 1)
scrim.BackgroundColor3 = TOKENS.page
scrim.BackgroundTransparency = 1
scrim.BorderSizePixel = 0
scrim.AutoButtonColor = false
scrim.Text = ""
scrim.Parent = screen

local panel = Instance.new("CanvasGroup")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.42, 0.58)
panel.BackgroundColor3 = TOKENS.base
panel.BorderSizePixel = 0
panel.GroupTransparency = 1
panel.Parent = screen

local panelBounds = Instance.new("UISizeConstraint")
panelBounds.MinSize = Vector2.new(320, 300)
panelBounds.MaxSize = Vector2.new(560, 620)
panelBounds.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = PANEL_RADIUS
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = TOKENS.border
panelStroke.Thickness = 1
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 16)
panelPadding.PaddingBottom = UDim.new(0, 16)
panelPadding.PaddingLeft = UDim.new(0, 16)
panelPadding.PaddingRight = UDim.new(0, 16)
panelPadding.Parent = panel

local panelColumn = Instance.new("UIListLayout")
panelColumn.FillDirection = Enum.FillDirection.Vertical
panelColumn.SortOrder = Enum.SortOrder.LayoutOrder
panelColumn.Padding = UDim.new(0, 16)
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

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 1
title.AutomaticSize = Enum.AutomaticSize.X
title.Size = UDim2.fromScale(0, 1)
title.BackgroundTransparency = 1
title.Text = "Settings"
title.TextColor3 = TOKENS.textPrimary
title.TextSize = 20
title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
title.TextYAlignment = Enum.TextYAlignment.Center
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local slack = Instance.new("Frame")
slack.Name = "Slack"
slack.LayoutOrder = 2
slack.BackgroundTransparency = 1
slack.Parent = header

local slackFill = Instance.new("UIFlexItem")
slackFill.FlexMode = Enum.UIFlexMode.Fill
slackFill.Parent = slack

local close = Instance.new("ImageButton")
close.Name = "Close"
close.LayoutOrder = 3
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

local closeInk = Instance.new("ImageLabel")
closeInk.Name = "Ink"
closeInk.AnchorPoint = Vector2.new(0.5, 0.5)
closeInk.Position = UDim2.fromScale(0.5, 0.5)
closeInk.Size = UDim2.fromOffset(ICON_INK, ICON_INK)
closeInk.BackgroundTransparency = 1
closeInk.Image = ICONS.close
closeInk.ImageColor3 = TOKENS.textSecondary
closeInk.Parent = close

local tabStrip = Instance.new("Frame")
tabStrip.Name = "Tabs"
tabStrip.LayoutOrder = 2
tabStrip.Size = UDim2.new(1, 0, 0, TOUCH_TARGET)
tabStrip.BackgroundTransparency = 1
tabStrip.Parent = panel

local tabRow = Instance.new("UIListLayout")
tabRow.FillDirection = Enum.FillDirection.Horizontal
tabRow.VerticalAlignment = Enum.VerticalAlignment.Center
tabRow.SortOrder = Enum.SortOrder.LayoutOrder
tabRow.Padding = UDim.new(0, 8)
tabRow.Parent = tabStrip

local content = Instance.new("Frame")
content.Name = "Content"
content.LayoutOrder = 3
content.Size = UDim2.fromScale(1, 0)
content.BackgroundTransparency = 1
content.Parent = panel

local contentFill = Instance.new("UIFlexItem")
contentFill.FlexMode = Enum.UIFlexMode.Fill
contentFill.Parent = content

-- The three states a list can be in, all built now. Adding them after the happy
-- path ships is how a player ends up staring at an empty rectangle.
local status = Instance.new("Frame")
status.Name = "Status"
status.Size = UDim2.fromScale(1, 1)
status.BackgroundTransparency = 1
status.Parent = content

local statusColumn = Instance.new("UIListLayout")
statusColumn.FillDirection = Enum.FillDirection.Vertical
statusColumn.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusColumn.VerticalAlignment = Enum.VerticalAlignment.Center
statusColumn.SortOrder = Enum.SortOrder.LayoutOrder
statusColumn.Padding = UDim.new(0, 12)
statusColumn.Parent = status

local statusIcon = Instance.new("ImageLabel")
statusIcon.Name = "StatusIcon"
statusIcon.LayoutOrder = 1
statusIcon.Size = UDim2.fromOffset(24, 24)
statusIcon.BackgroundTransparency = 1
statusIcon.Image = ICONS.loading
statusIcon.ImageColor3 = TOKENS.textMuted
statusIcon.Parent = status

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.LayoutOrder = 2
statusText.AutomaticSize = Enum.AutomaticSize.Y
statusText.Size = UDim2.fromScale(1, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "Loading your saved settings"
statusText.TextColor3 = TOKENS.textSecondary
statusText.TextSize = 14
statusText.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
statusText.TextWrapped = true
statusText.Parent = status

local retry = Instance.new("TextButton")
retry.Name = "Retry"
retry.LayoutOrder = 3
retry.Size = UDim2.fromOffset(120, TOUCH_TARGET)
retry.BackgroundColor3 = TOKENS.accent
retry.BackgroundTransparency = 1
retry.BorderSizePixel = 0
retry.AutoButtonColor = false
retry.Visible = false
retry.Text = "Try again"
retry.TextColor3 = TOKENS.textPrimary
retry.TextSize = 14
retry.FontFace = Font.fromEnum(Enum.Font.GothamBold)
retry.Parent = status

local retryCorner = Instance.new("UICorner")
retryCorner.CornerRadius = CONTROL_RADIUS
retryCorner.Parent = retry

local function paint(button: GuiButton, transparency: number, seconds: number)
	ease(button, seconds, { BackgroundTransparency = transparency })
end

local function wireStates(button: GuiButton, restTransparency: number)
	track(button.MouseEnter:Connect(function()
		paint(button, restTransparency - 0.3, ENTER_SECONDS)
	end))
	track(button.MouseLeave:Connect(function()
		paint(button, restTransparency, EXIT_SECONDS)
	end))
	track(button.InputBegan:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, restTransparency - 0.1, EXIT_SECONDS)
		end
	end))
	track(button.InputEnded:Connect(function(input: InputObject)
		if PRESS_INPUTS[input.UserInputType] then
			paint(button, restTransparency, EXIT_SECONDS)
		end
	end))
	track(button.SelectionGained:Connect(function()
		panelStroke.Color = TOKENS.accentBright
	end))
	track(button.SelectionLost:Connect(function()
		panelStroke.Color = TOKENS.border
	end))
end

local selected = TABS[1]
local tabButtons: { [string]: TextButton } = {}

local function repaintTabs()
	for name, tabButton in tabButtons do
		local active = name == selected
		tabButton.BackgroundTransparency = if active then 0 else 1
		tabButton.TextColor3 = if active then TOKENS.textPrimary else TOKENS.textSecondary
	end
end

for order, name in TABS do
	local tab = Instance.new("TextButton")
	tab.Name = name
	tab.LayoutOrder = order
	tab.Size = UDim2.new(0, 0, 0, TOUCH_TARGET)
	tab.AutomaticSize = Enum.AutomaticSize.X
	tab.BackgroundColor3 = TOKENS.raised
	tab.BackgroundTransparency = 1
	tab.BorderSizePixel = 0
	tab.AutoButtonColor = false
	tab.Text = name
	tab.TextColor3 = TOKENS.textSecondary
	tab.TextSize = 14
	tab.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	tab.Parent = tabStrip

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = CONTROL_RADIUS
	tabCorner.Parent = tab

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 16)
	tabPadding.PaddingRight = UDim.new(0, 16)
	tabPadding.Parent = tab

	tabButtons[name] = tab
	wireStates(tab, 1)

	track(tab.Activated:Connect(function()
		selected = name
		repaintTabs()
	end))
end

repaintTabs()

local function showStatus(icon: string, message: string, canRetry: boolean)
	statusIcon.Image = icon
	statusIcon.ImageColor3 = if canRetry then TOKENS.danger else TOKENS.textMuted
	statusText.Text = message
	retry.Visible = canRetry
end

local function loadSettings()
	showStatus(ICONS.loading, "Loading your saved settings", false)

	local remote = ReplicatedStorage:FindFirstChild("GetSettings")
	if not remote or not remote:IsA("RemoteFunction") then
		showStatus(ICONS.alert, "Settings are unavailable right now", true)
		return
	end

	local ok, result = pcall(function()
		return (remote :: RemoteFunction):InvokeServer()
	end)
	if not ok then
		warn(("[settings] load failed: %s"):format(tostring(result)))
		showStatus(ICONS.alert, "Settings are unavailable right now", true)
		return
	end
	if typeof(result) ~= "table" or next(result) == nil then
		showStatus(ICONS.alert, "No settings saved for this account yet", false)
		return
	end
	status.Visible = false
end

local function setOpen(open: boolean)
	if open then
		screen.Enabled = true
		ease(scrim, ENTER_SECONDS, { BackgroundTransparency = 0.4 })
		ease(panel, ENTER_SECONDS, { GroupTransparency = 0 })
		loadSettings()
		return
	end
	ease(scrim, EXIT_SECONDS, { BackgroundTransparency = 1 })
	ease(panel, EXIT_SECONDS, { GroupTransparency = 1 }).Completed:Wait()
	screen.Enabled = false
end

wireStates(close, 1)
wireStates(scrim, 1)
wireStates(retry, 1)

track(close.Activated:Connect(function()
	setOpen(false)
end))
track(scrim.Activated:Connect(function()
	setOpen(false)
end))
track(retry.Activated:Connect(loadSettings))

track(UserInputService.InputBegan:Connect(function(input: InputObject, typing: boolean)
	if typing then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and screen.Enabled then
		setOpen(false)
	elseif input.KeyCode == Enum.KeyCode.P then
		setOpen(not screen.Enabled)
	end
end))

track(Players.LocalPlayer.AncestryChanged:Connect(function()
	if Players.LocalPlayer.Parent ~= nil then
		return
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end))
