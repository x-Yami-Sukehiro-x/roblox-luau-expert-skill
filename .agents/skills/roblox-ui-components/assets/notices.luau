--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

export type Severity = "info" | "success" | "warning" | "error"

local THEME = {
	scrim = Color3.fromRGB(9, 10, 13),
	surface = Color3.fromRGB(44, 48, 57),
	control = Color3.fromRGB(63, 68, 79),
	controlHover = Color3.fromRGB(78, 84, 97),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentHover = Color3.fromRGB(72, 201, 162),
	onAccent = Color3.fromRGB(9, 10, 13),
	focus = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	success = "rbxassetid://88244323237265",
	warning = "rbxassetid://91165848022002",
	error = "rbxassetid://106305483906363",
	close = "rbxassetid://116396312853810",
}

local ENTER = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function holdFor(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.clamp(2 + words * 0.3, 3, 8)
end

local function iconLabel(parent: GuiObject, severity: Severity, order: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.LayoutOrder = order
	icon.Size = UDim2.fromOffset(16, 16)
	icon.BackgroundTransparency = 1
	icon.Image = ICON[severity]
	icon.ImageColor3 = THEME[severity]
	icon.Parent = parent
	return icon
end

local function rowLayout(parent: GuiObject, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

-- N3: the row is always present at its full height, so showing a message never
-- pushes the controls below it down.
local function createInlineMessage(parent: GuiObject, order: number)
	local ticket = 0

	local slot = Instance.new("CanvasGroup")
	slot.Name = "InlineMessage"
	slot.LayoutOrder = order
	slot.Size = UDim2.new(1, 0, 0, 20)
	slot.BackgroundTransparency = 1
	slot.GroupTransparency = 1
	slot.Parent = parent
	rowLayout(slot, 8)

	local icon = iconLabel(slot, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 12
	text.TextColor3 = THEME.textMuted
	text.Text = ""
	text.Parent = slot

	local function clear()
		ticket += 1
		TweenService:Create(slot, motion(EXIT), { GroupTransparency = 1 }):Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		local mine = ticket
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		TweenService:Create(slot, motion(ENTER), { GroupTransparency = 0 }):Play()
		if severity ~= "error" then
			task.delay(holdFor(message), function()
				if mine == ticket then
					clear()
				end
			end)
		end
	end

	return {
		show = show,
		clear = clear,
		destroy = function()
			ticket += 1
			slot:Destroy()
		end,
	}
end

-- Hover, press and focus for the dialog buttons; the focus ring is separate
-- from the fill so a pointer leaving never hides keyboard or gamepad focus.
local function actionButton(parent: GuiObject, text: string, primary: boolean, order: number)
	local rest = if primary then THEME.accent else THEME.control
	local hover = if primary then THEME.accentHover else THEME.controlHover
	local connections: { RBXScriptConnection } = {}

	local button = Instance.new("TextButton")
	button.Name = text
	button.LayoutOrder = order
	button.AutoButtonColor = false
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 44)
	button.BackgroundColor3 = rest
	button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	button.TextSize = 14
	button.TextColor3 = if primary then THEME.onAccent else THEME.text
	button.Text = text
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = button

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	local press = Instance.new("UIScale")
	press.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hover
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		button.BackgroundColor3 = rest
		press.Scale = 1
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			press.Scale = 0.97
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		press.Scale = 1
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
	return button, connections
end

-- N5: a strip for a condition that lasts, such as "Reconnecting". It stays until
-- the condition ends or the player dismisses it.
local function createBanner(screen: ScreenGui)
	local connections: { RBXScriptConnection } = {}

	local strip = Instance.new("CanvasGroup")
	strip.Name = "Banner"
	strip.AutomaticSize = Enum.AutomaticSize.Y
	strip.Size = UDim2.fromScale(1, 0)
	strip.BackgroundColor3 = THEME.surface
	strip.GroupTransparency = 1
	strip.Visible = false
	strip.Parent = screen

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = strip

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = strip
	rowLayout(strip, 12)

	local icon = iconLabel(strip, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.Size = UDim2.new(0, 0, 0, 44)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 14
	text.TextColor3 = THEME.text
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.Text = ""
	text.Parent = strip

	local fill = Instance.new("UIFlexItem")
	fill.FlexMode = Enum.UIFlexMode.Fill
	fill.Parent = text

	local dismiss = Instance.new("ImageButton")
	dismiss.Name = "Dismiss"
	dismiss.LayoutOrder = 3
	dismiss.Size = UDim2.fromOffset(44, 44)
	dismiss.AutoButtonColor = false
	dismiss.BackgroundTransparency = 1
	dismiss.Image = ""
	dismiss.Parent = strip

	local ink = Instance.new("ImageLabel")
	ink.AnchorPoint = Vector2.new(0.5, 0.5)
	ink.Position = UDim2.fromScale(0.5, 0.5)
	ink.Size = UDim2.fromOffset(16, 16)
	ink.BackgroundTransparency = 1
	ink.Image = ICON.close
	ink.ImageColor3 = THEME.textMuted
	ink.Parent = dismiss

	local ticket = 0
	local function hide()
		ticket += 1
		local mine = ticket
		local fade = TweenService:Create(strip, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				strip.Visible = false
			end
		end)
		fade:Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		strip.Visible = true
		TweenService:Create(strip, motion(ENTER), { GroupTransparency = 0 }):Play()
	end

	table.insert(connections, dismiss.Activated:Connect(hide))
	return {
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			strip:Destroy()
		end,
	}
end

-- N8: one short status line in a compact bar under the top bar. A new message
-- replaces the old one instead of stacking; anything the player must act on
-- belongs in N4 or N6, not here.
local function createCapsule(screen: ScreenGui)
	local ticket = 0

	local capsule = Instance.new("CanvasGroup")
	capsule.Name = "Capsule"
	capsule.AnchorPoint = Vector2.new(0.5, 0)
	capsule.Position = UDim2.new(0.5, 0, 0, 12)
	capsule.AutomaticSize = Enum.AutomaticSize.X
	capsule.Size = UDim2.fromOffset(0, 36)
	capsule.BackgroundColor3 = THEME.surface
	capsule.GroupTransparency = 1
	capsule.Visible = false
	capsule.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = capsule

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = capsule

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = capsule
	rowLayout(capsule, 8)

	local icon = iconLabel(capsule, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 14
	text.TextColor3 = THEME.text
	text.Text = ""
	text.Parent = capsule

	local grow = Instance.new("UIScale")
	grow.Scale = 1
	grow.Parent = capsule

	local function hide(mine: number)
		local fade = TweenService:Create(capsule, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				capsule.Visible = false
			end
		end)
		fade:Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		local mine = ticket
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		if not capsule.Visible then
			capsule.Visible = true
			grow.Scale = 0.9
		end
		TweenService:Create(capsule, motion(ENTER), { GroupTransparency = 0 }):Play()
		TweenService:Create(grow, motion(ENTER), { Scale = 1 }):Play()
		task.delay(holdFor(message), function()
			if mine == ticket then
				hide(mine)
			end
		end)
	end

	return {
		show = show,
		destroy = function()
			ticket += 1
			capsule:Destroy()
		end,
	}
end

export type AlertSpec = {
	title: string,
	body: string,
	confirmText: string,
	cancelText: string,
}

-- N6: only for something the player must answer. The dim layer is a button so
-- a tap outside the dialog counts as Cancel instead of reaching the game; the
-- dialog is its sibling and Active, so a tap inside it never reaches the dim.
local function confirmAlert(
	screen: ScreenGui,
	spec: AlertSpec,
	onChoice: (confirmed: boolean) -> ()
)
	local connections: { RBXScriptConnection } = {}
	local answered = false

	local scrim = Instance.new("TextButton")
	scrim.Name = "AlertScrim"
	scrim.AutoButtonColor = false
	scrim.Text = ""
	scrim.Selectable = false
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = THEME.scrim
	scrim.BackgroundTransparency = 1
	scrim.ZIndex = 10
	scrim.Parent = screen

	local dialog = Instance.new("CanvasGroup")
	dialog.Name = "Alert"
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.Size = UDim2.fromScale(0.9, 0)
	dialog.BackgroundColor3 = THEME.surface
	dialog.GroupTransparency = 1
	dialog.Active = true
	dialog.ZIndex = 11
	dialog.Parent = screen

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(400, math.huge)
	bounds.Parent = dialog

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = dialog

	local pop = Instance.new("UIScale")
	pop.Scale = 0.96
	pop.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 24)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = dialog

	local column = Instance.new("UIListLayout")
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = dialog

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.fromScale(1, 0)
	title.BackgroundTransparency = 1
	title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	title.TextSize = 20
	title.TextColor3 = THEME.text
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = spec.title
	title.Parent = dialog

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.LayoutOrder = 2
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.fromScale(1, 0)
	body.BackgroundTransparency = 1
	body.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	body.TextSize = 14
	body.TextColor3 = THEME.textMuted
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.Text = spec.body
	body.Parent = dialog

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.LayoutOrder = 3
	actions.Size = UDim2.new(1, 0, 0, 44)
	actions.BackgroundTransparency = 1
	actions.Parent = dialog
	rowLayout(actions, 8).HorizontalAlignment = Enum.HorizontalAlignment.Right

	local cancel, cancelConnections = actionButton(actions, spec.cancelText, false, 1)
	local confirm, confirmConnections = actionButton(actions, spec.confirmText, true, 2)
	table.move(cancelConnections, 1, #cancelConnections, #connections + 1, connections)
	table.move(confirmConnections, 1, #confirmConnections, #connections + 1, connections)

	local function answer(confirmed: boolean)
		if answered then
			return
		end
		answered = true
		for _, connection in connections do
			connection:Disconnect()
		end
		if GuiService.SelectedObject == confirm or GuiService.SelectedObject == cancel then
			GuiService.SelectedObject = nil
		end
		TweenService:Create(scrim, motion(EXIT), { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(dialog, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function()
			dialog:Destroy()
			scrim:Destroy()
		end)
		fade:Play()
		onChoice(confirmed)
	end

	table.insert(connections, confirm.Activated:Connect(function()
		answer(true)
	end))
	table.insert(connections, cancel.Activated:Connect(function()
		answer(false)
	end))
	table.insert(connections, scrim.Activated:Connect(function()
		answer(false)
	end))

	TweenService:Create(scrim, motion(ENTER), { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(dialog, motion(ENTER), { GroupTransparency = 0 }):Play()
	TweenService:Create(pop, motion(ENTER), { Scale = 1 }):Play()
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = cancel
	end
end

return {
	createInlineMessage = createInlineMessage,
	createBanner = createBanner,
	createCapsule = createCapsule,
	confirmAlert = confirmAlert,
}
