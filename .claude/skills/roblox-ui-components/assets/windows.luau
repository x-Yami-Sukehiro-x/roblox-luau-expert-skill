--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

type FirstStyles = "O1" | "O2" | "O3" | "O4"
type LaterStyles = "O6" | "O7" | "O8" | "O9" | "O10" | "O11"
export type WindowStyle = FirstStyles | LaterStyles

export type Opener = {
	open: () -> (),
	close: () -> (),
}

-- `launcher` is the on-screen button that brings the window back (O1, O2, O11).
-- O3 keeps `header` on screen and folds `body` away. `opener` is a presenter
-- from menus.luau; without one, O1 shows and hides instantly. O6 shows
-- `bubbleIcon`, O9 shows `title`, O10 names `keyName`, and O11 calls `onUnload`
-- when the player chooses to unload rather than hide.
export type WindowParts = {
	panel: CanvasGroup,
	launcher: GuiButton?,
	header: GuiObject?,
	body: CanvasGroup?,
	opener: Opener?,
	bubbleIcon: string?,
	title: string?,
	keyName: string?,
	onUnload: (() -> ())?,
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
	control = Color3.fromRGB(63, 68, 79),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	onAccent = Color3.fromRGB(9, 10, 13),
	danger = Color3.fromRGB(208, 88, 82),
	focus = Color3.fromRGB(72, 201, 162),
}

local ICON = {
	pullRight = "rbxassetid://101007429951147",
	pullLeft = "rbxassetid://102314312897830",
	pullDown = "rbxassetid://71457658246709",
	menu = "rbxassetid://83047518441184",
	keyboard = "rbxassetid://121978468376124",
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
local OUTRO_HOLD = 0.8
local CHIP_COLLAPSE = 5
-- A press that travels further than this is a drag, not a tap.
local DRAG_SLOP = 6

local function timing(chosen: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then MOTION.instant else chosen
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function glyph(parent: GuiObject, image: string, order: number): ImageLabel
	local mark = Instance.new("ImageLabel")
	mark.Name = "Mark"
	mark.LayoutOrder = order
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromOffset(16, 16)
	mark.BackgroundTransparency = 1
	mark.Image = image
	mark.ImageColor3 = THEME.textMuted
	mark.Parent = parent
	return mark
end

-- Every return control shares one look: a raised surface, a 1 px edge that
-- becomes the focus colour under keyboard or gamepad, and a mark that brightens
-- on hover. The control starts hidden; the window shows it when it hides.
local function returnControl(
	name: string,
	size: UDim2,
	anchor: Vector2,
	position: UDim2,
	image: string,
	radius: UDim,
	connections: { RBXScriptConnection }
): (TextButton, ImageLabel)
	local control = Instance.new("TextButton")
	control.Name = name
	control.AnchorPoint = anchor
	control.Position = position
	control.Size = size
	control.AutoButtonColor = false
	control.BackgroundColor3 = THEME.surface
	control.Text = ""
	control.Visible = false
	round(control, radius)

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.edge
	ring.Parent = control

	local mark = glyph(control, image, 1)
	table.insert(connections, control.MouseEnter:Connect(function()
		mark.ImageColor3 = THEME.text
	end))
	table.insert(connections, control.MouseLeave:Connect(function()
		mark.ImageColor3 = THEME.textMuted
	end))
	table.insert(connections, control.SelectionGained:Connect(function()
		ring.Color = THEME.focus
	end))
	table.insert(connections, control.SelectionLost:Connect(function()
		ring.Color = THEME.edge
	end))
	return control, mark
end

local function row(parent: GuiObject, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

local function caption(parent: GuiObject, text: string, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Caption"
	label.LayoutOrder = order
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextSize = 14
	label.TextColor3 = THEME.text
	label.Text = text
	label.Parent = parent
	return label
end

-- O6: the window is gone and a round bubble floats where it was. The bubble
-- can be dragged anywhere; a tap without a drag brings the window back.
local function makeBubble(
	parts: WindowParts,
	connections: { RBXScriptConnection },
	onTap: () -> ()
): TextButton
	local topLeft = parts.panel.AbsolutePosition
	local bubble = returnControl(
		"Bubble",
		UDim2.fromOffset(52, 52),
		Vector2.new(0.5, 0.5),
		UDim2.fromOffset(topLeft.X + 26, topLeft.Y + 26),
		parts.bubbleIcon or ICON.menu,
		UDim.new(0.5, 0),
		connections
	)

	local pressedAt: Vector3? = nil
	local origin = bubble.Position
	local dragged = false
	table.insert(connections, bubble.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressedAt, origin, dragged = input.Position, bubble.Position, false
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		local kind = input.UserInputType
		local moving = kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch
		if not pressedAt or not moving then
			return
		end
		local travel = input.Position - pressedAt
		dragged = dragged or travel.Magnitude > DRAG_SLOP
		if dragged then
			bubble.Position = origin + UDim2.fromOffset(travel.X, travel.Y)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function()
		pressedAt = nil
	end))
	table.insert(connections, bubble.Activated:Connect(function()
		if not dragged then
			onTap()
		end
	end))
	return bubble
end

-- O10: a chip that names the key which brings the window back, and folds down
-- to its icon after a few seconds so it stops competing with the game.
local function makeKeyChip(
	parts: WindowParts,
	connections: { RBXScriptConnection }
): (TextButton, TextLabel)
	local chip, mark = returnControl(
		"KeyChip",
		UDim2.fromOffset(44, 44),
		Vector2.new(1, 1),
		UDim2.new(1, -16, 1, -16),
		ICON.keyboard,
		UDim.new(0, 10),
		connections
	)
	chip.AutomaticSize = Enum.AutomaticSize.X
	mark.AnchorPoint = Vector2.zero

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = chip
	row(chip, 8)

	local hint = caption(chip, `Show menu · {parts.keyName or "RightShift"}`, 2)
	hint.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	return chip, hint
end

-- O9: the window collapses to a pill carrying its title, in the same corner.
local function makePill(
	parts: WindowParts,
	panel: CanvasGroup,
	connections: { RBXScriptConnection }
): TextButton
	local pill, mark = returnControl(
		"TitlePill",
		UDim2.fromOffset(0, 44),
		Vector2.zero,
		UDim2.fromOffset(panel.AbsolutePosition.X, panel.AbsolutePosition.Y),
		ICON.pullDown,
		UDim.new(0.5, 0),
		connections
	)
	pill.AutomaticSize = Enum.AutomaticSize.X
	mark.AnchorPoint = Vector2.zero

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = pill
	row(pill, 8)
	caption(pill, parts.title or "Menu", 0)
	return pill
end

-- O11: a small card over the window asking whether to hide it or unload the
-- script. Returns the function that opens it.
local function makeAsk(
	panel: CanvasGroup,
	connections: { RBXScriptConnection },
	onHide: () -> (),
	onUnload: () -> ()
): (CanvasGroup, () -> ())
	local card = Instance.new("CanvasGroup")
	card.Name = "Ask"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundColor3 = THEME.surface
	card.GroupTransparency = 1
	card.Visible = false
	card.ZIndex = 10
	round(card, UDim.new(0, 10))

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = card

	local column = Instance.new("UIListLayout")
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = card

	local question = Instance.new("TextLabel")
	question.Name = "Question"
	question.LayoutOrder = 1
	question.AutomaticSize = Enum.AutomaticSize.XY
	question.BackgroundTransparency = 1
	question.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	question.TextSize = 14
	question.TextColor3 = THEME.text
	question.Text = "Hide the menu? It keeps running."
	question.Parent = card

	local choices = Instance.new("Frame")
	choices.Name = "Choices"
	choices.LayoutOrder = 2
	choices.AutomaticSize = Enum.AutomaticSize.X
	choices.Size = UDim2.fromOffset(0, 44)
	choices.BackgroundTransparency = 1
	choices.Parent = card
	row(choices, 8)

	local function close()
		local fade = TweenService:Create(card, timing(MOTION.exit), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and card.GroupTransparency == 1 then
				card.Visible = false
			end
		end)
		fade:Play()
	end

	for index, choice in { "Cancel", "Hide", "Unload script" } do
		local button = Instance.new("TextButton")
		button.Name = choice
		button.LayoutOrder = index
		button.AutoButtonColor = false
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, 44)
		button.BackgroundColor3 = if choice == "Unload script" then THEME.danger else THEME.control
		button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		button.TextSize = 14
		button.TextColor3 = if choice == "Unload script" then THEME.onAccent else THEME.text
		button.Text = choice
		button.Parent = choices
		round(button, UDim.new(0, 6))

		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, 16)
		inset.PaddingRight = UDim.new(0, 16)
		inset.Parent = button

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.focus
		ring.Thickness = 2
		ring.Enabled = false
		ring.Parent = button

		table.insert(connections, button.SelectionGained:Connect(function()
			ring.Enabled = true
		end))
		table.insert(connections, button.SelectionLost:Connect(function()
			ring.Enabled = false
		end))
		table.insert(connections, button.Activated:Connect(function()
			close()
			if choice == "Hide" then
				onHide()
			elseif choice == "Unload script" then
				onUnload()
			end
		end))
	end

	return card,
		function()
			local centre = panel.AbsolutePosition + panel.AbsoluteSize / 2
			card.Position = UDim2.fromOffset(centre.X, centre.Y)
			card.Visible = true
			TweenService:Create(card, timing(MOTION.enter), { GroupTransparency = 0 }):Play()
		end
end

-- O4, O7 and O8: a tab on the edge the window left by.
local function makeTab(style: WindowStyle, connections: { RBXScriptConnection }): TextButton
	if style == "O8" then
		return (
			returnControl(
				"PullTab",
				UDim2.fromOffset(64, 44),
				Vector2.new(0.5, 0),
				UDim2.fromScale(0.5, 0),
				ICON.pullDown,
				UDim.new(0, 10),
				connections
			)
		)
	end
	local side = if style == "O7" then 1 else 0
	return (
		returnControl(
			"EdgeTab",
			UDim2.fromOffset(44, 64),
			Vector2.new(side, 0.5),
			UDim2.fromScale(side, 0.5),
			if style == "O7" then ICON.pullLeft else ICON.pullRight,
			UDim.new(0, 10),
			connections
		)
	)
end

local function createWindow(parts: WindowParts, style: WindowStyle): Window
	local panel = parts.panel
	local connections: { RBXScriptConnection } = {}
	local shown = panel.Visible
	local ticket = 0
	local running: { Tween } = {}
	local made: { Instance } = {}

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

	-- The offset that puts the panel's anchor on a control's centre, so the
	-- window visibly shrinks into the thing that will bring it back.
	local function toward(control: GuiObject): UDim2
		local target = control.AbsolutePosition + control.AbsoluteSize / 2
		local anchor = panel.AbsolutePosition + panel.AbsoluteSize * panel.AnchorPoint
		local delta = target - anchor
		return home + UDim2.fromOffset(delta.X, delta.Y)
	end

	local show: () -> ()
	local conceal: () -> ()
	local returner: GuiButton? = nil
	local chipHint: TextLabel? = nil
	local openAsk: (() -> ())? = nil

	-- O2 shrinks into the launcher and O6 into the bubble; nothing else shrinks.
	local function shrinkInto(): GuiObject?
		return if style == "O2" then parts.launcher elseif style == "O6" then returner else nil
	end

	-- Where each edge style parks the window while it is away.
	local function offscreen(): UDim2
		local size = panel.AbsoluteSize
		if style == "O7" then
			return home + UDim2.fromOffset(size.X + 24, 0)
		elseif style == "O8" then
			return home - UDim2.fromOffset(0, size.Y + 24)
		end
		return home - UDim2.fromOffset(size.X + 24, 0)
	end

	if style == "O4" or style == "O7" or style == "O8" then
		returner = makeTab(style, connections)
	elseif style == "O6" then
		returner = makeBubble(parts, connections, function()
			show()
		end)
	elseif style == "O9" then
		returner = makePill(parts, panel, connections)
	elseif style == "O10" then
		local chip, hint = makeKeyChip(parts, connections)
		returner, chipHint = chip, hint
	elseif style == "O11" then
		local onUnload = parts.onUnload
		assert(onUnload, "O11 needs parts.onUnload")
		local card, open = makeAsk(panel, connections, function()
			conceal()
		end, onUnload)
		card.Parent = panel.Parent
		table.insert(made, card)
		openAsk = open
	end

	if returner then
		returner.Parent = panel.Parent
		table.insert(made, returner)
		if style ~= "O6" then
			table.insert(connections, returner.Activated:Connect(function()
				show()
			end))
		end
	end

	local function setReturnControl(visible: boolean)
		if parts.launcher then
			parts.launcher.Visible = visible
		end
		if returner then
			returner.Visible = visible
		end
		if chipHint then
			chipHint.Visible = true
		end
	end

	local function revealReturn()
		setReturnControl(true)
		local hint = chipHint
		if hint then
			local mine = ticket
			task.delay(CHIP_COLLAPSE, function()
				if mine == ticket then
					hint.Visible = false
				end
			end)
		end
	end

	function conceal()
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

		local into = shrinkInto()
		if into then
			home = panel.Position
			play(scale, MOTION.shrink, { Scale = MINIMISED_SCALE })
			play(panel, MOTION.shrink, { GroupTransparency = 1 })
			local travel = play(panel, MOTION.shrink, { Position = toward(into) })
			afterTween(travel, function()
				panel.Visible = false
				panel.Position, scale.Scale = home, 1
				revealReturn()
			end)
			return
		end

		if style == "O4" or style == "O7" or style == "O8" then
			home = panel.Position
			local slide = play(panel, MOTION.shrink, { Position = offscreen() })
			afterTween(slide, function()
				panel.Visible = false
				panel.Position = home
				revealReturn()
			end)
			return
		end

		if style == "O9" or style == "O10" then
			if style == "O9" and returner then
				local topLeft = panel.AbsolutePosition
				returner.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
			end
			play(scale, MOTION.exit, { Scale = 0.95 })
			local fade = play(panel, MOTION.exit, { GroupTransparency = 1 })
			afterTween(fade, function()
				panel.Visible = false
				scale.Scale = 1
				revealReturn()
			end)
			return
		end

		revealReturn()
		if parts.opener then
			parts.opener.close()
		else
			panel.Visible = false
		end
	end

	function show()
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

		local from = shrinkInto()
		setReturnControl(false)
		if from then
			panel.Position = toward(from)
			scale.Scale = MINIMISED_SCALE
			panel.GroupTransparency = 1
			panel.Visible = true
			play(scale, MOTION.grow, { Scale = 1 })
			play(panel, MOTION.grow, { Position = home, GroupTransparency = 0 })
			return
		end

		if style == "O4" or style == "O7" or style == "O8" then
			panel.Position = offscreen()
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
			scale.Scale = 1
		end
	end

	-- The close button's path: O11 asks first.
	local function hide()
		local ask = openAsk
		if shown and ask then
			ask()
			return
		end
		conceal()
	end

	-- The keybind's path: it never stops to ask, even for O11.
	local function toggle()
		if shown then
			conceal()
		else
			show()
		end
	end

	if parts.launcher then
		table.insert(connections, parts.launcher.Activated:Connect(show))
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
			for _, instance in made do
				instance:Destroy()
			end
		end,
	}
end

local function titleCard(screen: ScreenGui, name: string, title: string): (CanvasGroup, Frame)
	local card = Instance.new("CanvasGroup")
	card.Name = name
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

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.LayoutOrder = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextSize = 28
	label.TextColor3 = THEME.text
	label.Text = title
	label.Parent = card

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.LayoutOrder = 2
	line.Size = UDim2.fromOffset(0, 2)
	line.BackgroundColor3 = THEME.accent
	line.BorderSizePixel = 0
	line.Parent = card
	return card, line
end

-- O5 and O12: a title card that plays once, then gets out of the way. Both
-- return `skip`, which ends the card at once and runs `onDone` exactly once.
local function playCard(
	screen: ScreenGui,
	name: string,
	title: string,
	hold: number,
	onDone: () -> ()
): () -> ()
	local finished = false
	local card, line = titleCard(screen, name, title)

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
	task.delay(hold, function()
		if finished then
			return
		end
		local fade = TweenService:Create(card, timing(MOTION.exit), { GroupTransparency = 1 })
		fade.Completed:Once(finish)
		fade:Play()
	end)
	return finish
end

-- O5: before the window's first opening.
local function playIntro(screen: ScreenGui, title: string, onDone: () -> ()): () -> ()
	return playCard(screen, "Intro", title, INTRO_HOLD, onDone)
end

-- O12: after the script unloads, so the player sees that it is gone on purpose.
local function playOutro(screen: ScreenGui, title: string, onDone: () -> ()): () -> ()
	return playCard(screen, "Outro", title, OUTRO_HOLD, onDone)
end

return {
	createWindow = createWindow,
	playIntro = playIntro,
	playOutro = playOutro,
}
