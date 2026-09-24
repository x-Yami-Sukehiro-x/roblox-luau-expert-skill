--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

export type WindowStyle = "O1" | "O2" | "O3" | "O4"

export type Opener = {
	open: () -> (),
	close: () -> (),
}

-- `launcher` is the on-screen button that brings the window back (O1, O2).
-- O3 keeps `header` on screen and folds `body` away. `opener` is a presenter
-- from menus.luau; without one, O1 shows and hides instantly.
export type WindowParts = {
	panel: CanvasGroup,
	launcher: GuiButton?,
	header: GuiObject?,
	body: CanvasGroup?,
	opener: Opener?,
}

export type Window = {
	show: () -> (),
	hide: () -> (),
	toggle: () -> (),
	isShown: () -> boolean,
	destroy: () -> (),
}

local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	focus = Color3.fromRGB(72, 201, 162),
}

local ICON = {
	pullOut = "rbxassetid://101007429951147",
}

local MOTION = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	grow = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	shrink = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	line = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	instant = TweenInfo.new(0),
}

local MINIMISED_SCALE = 0.2
local INTRO_HOLD = 0.6

local function timing(chosen: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then MOTION.instant else chosen
end

local function createWindow(parts: WindowParts, style: WindowStyle): Window
	local panel = parts.panel
	local connections: { RBXScriptConnection } = {}
	local shown = panel.Visible
	local ticket = 0
	local running: { Tween } = {}

	local scale = Instance.new("UIScale")
	scale.Name = "WindowScale"
	scale.Scale = 1
	scale.Parent = panel

	local home = panel.Position
	local fullSize = panel.Size

	local function stop()
		for _, tween in running do
			tween:Cancel()
		end
		table.clear(running)
	end

	local function play(target: Instance, info: TweenInfo, goals: { [string]: any }): Tween
		local tween = TweenService:Create(target, timing(info), goals)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function afterTween(tween: Tween, finish: () -> ())
		local mine = ticket
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				finish()
			end
		end)
	end

	-- The offset that puts the panel's anchor on the launcher's centre, so the
	-- window visibly shrinks into the button that will bring it back.
	local function towardLauncher(launcher: GuiButton): UDim2
		local target = launcher.AbsolutePosition + launcher.AbsoluteSize / 2
		local anchor = panel.AbsolutePosition + panel.AbsoluteSize * panel.AnchorPoint
		local delta = target - anchor
		return home + UDim2.fromOffset(delta.X, delta.Y)
	end

	local edgeTab: ImageButton? = nil
	if style == "O4" then
		local tab = Instance.new("ImageButton")
		tab.Name = "EdgeTab"
		tab.AnchorPoint = Vector2.new(0, 0.5)
		tab.Position = UDim2.new(0, 0, 0.5, 0)
		tab.Size = UDim2.fromOffset(44, 64)
		tab.AutoButtonColor = false
		tab.BackgroundColor3 = THEME.surface
		tab.Image = ""
		tab.Visible = not shown
		tab.Parent = panel.Parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = tab

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.edge
		ring.Parent = tab

		local mark = Instance.new("ImageLabel")
		mark.Name = "Mark"
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.fromScale(0.5, 0.5)
		mark.Size = UDim2.fromOffset(16, 16)
		mark.BackgroundTransparency = 1
		mark.Image = ICON.pullOut
		mark.ImageColor3 = THEME.textMuted
		mark.Parent = tab

		table.insert(connections, tab.MouseEnter:Connect(function()
			mark.ImageColor3 = THEME.text
		end))
		table.insert(connections, tab.MouseLeave:Connect(function()
			mark.ImageColor3 = THEME.textMuted
		end))
		table.insert(connections, tab.SelectionGained:Connect(function()
			ring.Color = THEME.focus
		end))
		table.insert(connections, tab.SelectionLost:Connect(function()
			ring.Color = THEME.edge
		end))
		edgeTab = tab
	end

	local function setReturnControl(visible: boolean)
		if parts.launcher then
			parts.launcher.Visible = visible
		end
		if edgeTab then
			edgeTab.Visible = visible
		end
	end

	local function hide()
		if not shown then
			return
		end
		shown = false
		ticket += 1
		stop()

		if style == "O3" then
			local header, body = parts.header, parts.body
			assert(header and body, "O3 needs header and body")
			fullSize = panel.Size
			local collapsed = header.AbsoluteSize.Y + 24
			play(body, MOTION.exit, { GroupTransparency = 1 })
			local fold = play(panel, MOTION.shrink, {
				Size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, collapsed),
			})
			afterTween(fold, function()
				body.Visible = false
			end)
			return
		end

		if style == "O2" then
			local launcher = parts.launcher
			assert(launcher, "O2 needs a launcher")
			home = panel.Position
			play(scale, MOTION.shrink, { Scale = MINIMISED_SCALE })
			play(panel, MOTION.shrink, { GroupTransparency = 1 })
			local travel = play(panel, MOTION.shrink, { Position = towardLauncher(launcher) })
			afterTween(travel, function()
				panel.Visible = false
				panel.Position, scale.Scale = home, 1
				setReturnControl(true)
			end)
			return
		end

		if style == "O4" then
			home = panel.Position
			local offscreen = home - UDim2.fromOffset(panel.AbsoluteSize.X + 24, 0)
			local slide = play(panel, MOTION.shrink, { Position = offscreen })
			afterTween(slide, function()
				panel.Visible = false
				panel.Position = home
				setReturnControl(true)
			end)
			return
		end

		setReturnControl(true)
		if parts.opener then
			parts.opener.close()
		else
			panel.Visible = false
		end
	end

	local function show()
		if shown then
			return
		end
		shown = true
		ticket += 1
		stop()

		if style == "O3" then
			local body = parts.body
			assert(body, "O3 needs a body")
			body.Visible = true
			play(panel, MOTION.grow, { Size = fullSize })
			play(body, MOTION.enter, { GroupTransparency = 0 })
			return
		end

		setReturnControl(false)
		if style == "O2" then
			local launcher = parts.launcher
			assert(launcher, "O2 needs a launcher")
			panel.Position = towardLauncher(launcher)
			scale.Scale = MINIMISED_SCALE
			panel.GroupTransparency = 1
			panel.Visible = true
			play(scale, MOTION.grow, { Scale = 1 })
			play(panel, MOTION.grow, { Position = home, GroupTransparency = 0 })
			return
		end

		if style == "O4" then
			panel.Position = home - UDim2.fromOffset(panel.AbsoluteSize.X + 24, 0)
			panel.GroupTransparency = 0
			panel.Visible = true
			play(panel, MOTION.grow, { Position = home })
			return
		end

		if parts.opener then
			parts.opener.open()
		else
			panel.Visible = true
			panel.GroupTransparency = 0
		end
	end

	local function toggle()
		if shown then
			hide()
		else
			show()
		end
	end

	if parts.launcher then
		table.insert(connections, parts.launcher.Activated:Connect(show))
	end
	if edgeTab then
		table.insert(connections, edgeTab.Activated:Connect(show))
	end
	setReturnControl(not shown)

	return {
		show = show,
		hide = hide,
		toggle = toggle,
		isShown = function()
			return shown
		end,
		destroy = function()
			ticket += 1
			stop()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			scale:Destroy()
			if edgeTab then
				edgeTab:Destroy()
			end
		end,
	}
end

-- O5: a title card before the window's first opening. It never delays a
-- player who asked for less motion by more than the hold, and `skip` ends it
-- at once for a rerun or an impatient tap.
local function playIntro(screen: ScreenGui, title: string, onDone: () -> ()): () -> ()
	local finished = false

	local card = Instance.new("CanvasGroup")
	card.Name = "Intro"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundTransparency = 1
	card.GroupTransparency = 1
	card.Parent = screen

	local column = Instance.new("UIListLayout")
	column.HorizontalAlignment = Enum.HorizontalAlignment.Center
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = card

	local name = Instance.new("TextLabel")
	name.Name = "Title"
	name.LayoutOrder = 1
	name.AutomaticSize = Enum.AutomaticSize.XY
	name.BackgroundTransparency = 1
	name.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	name.TextSize = 28
	name.TextColor3 = THEME.text
	name.Text = title
	name.Parent = card

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.LayoutOrder = 2
	line.Size = UDim2.fromOffset(0, 2)
	line.BackgroundColor3 = THEME.accent
	line.BorderSizePixel = 0
	line.Parent = card

	local function finish()
		if finished then
			return
		end
		finished = true
		card:Destroy()
		onDone()
	end

	TweenService:Create(card, timing(MOTION.enter), { GroupTransparency = 0 }):Play()
	TweenService:Create(line, timing(MOTION.line), { Size = UDim2.fromOffset(120, 2) }):Play()
	task.delay(INTRO_HOLD, function()
		if finished then
			return
		end
		local fade = TweenService:Create(card, timing(MOTION.exit), { GroupTransparency = 1 })
		fade.Completed:Once(finish)
		fade:Play()
	end)
	return finish
end

return {
	createWindow = createWindow,
	playIntro = playIntro,
}
