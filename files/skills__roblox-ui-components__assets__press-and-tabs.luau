--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

type FirstPress = "P1" | "P2" | "P3" | "P4" | "P5" | "P6"
type LaterPress = "P7" | "P8" | "P9" | "P10" | "P11" | "P12"
export type PressStyle = FirstPress | LaterPress | "P13" | "P14" | "P15" | "P21" | "P22"
-- The styles that change what the button says or whether it can be pressed.
export type ActionStyle = "P16" | "P17" | "P18" | "P19" | "P20"

-- `run` does the button's work and calls `finish` when it is done; P17 shows
-- whether it worked. P18 waits `seconds` before the next press; P19 asks with
-- `confirmText`; P20 refuses with a shake while `allowed` returns false.
export type ActionSpec = {
	run: (finish: (ok: boolean) -> ()) -> (),
	seconds: number?,
	confirmText: string?,
	allowed: (() -> boolean)?,
}
type FirstTabs = "S1" | "S2" | "S3" | "S4" | "S5" | "S6"
export type TabStyle = FirstTabs | "S7" | "S8" | "S9" | "S10" | "S11" | "S12"

local THEME = {
	control = Color3.fromRGB(44, 48, 57),
	controlHover = Color3.fromRGB(63, 68, 79),
	controlPressed = Color3.fromRGB(31, 34, 41),
	track = Color3.fromRGB(19, 21, 26),
	edge = Color3.fromRGB(118, 125, 139),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
	-- A UIGradient multiplies the fill, so P6 paints white and lets it choose.
	white = Color3.fromRGB(255, 255, 255),
}

local ICON = {
	arrow = "rbxassetid://134908902120212",
	tab = "rbxassetid://89644754139307",
}

local QUICK = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPRING_BACK = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SWEEP = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SHINE = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local RIPPLE = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOLD = TweenInfo.new(1, Enum.EasingStyle.Linear)
local DRAIN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Plays forward then back: one quick pop that returns to rest on its own.
local POP = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local SPIN = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
-- Turns for as long as the pointer stays; cancelled when it leaves.
local SHIMMER = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
-- Three quick wiggles that end where they started.
local SHAKE = TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true)
local PAGE_OUT = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local PAGE_IN = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local INSTANT = TweenInfo.new(0)

local RIPPLE_SPREAD = 2.5
local RIPPLE_START = 0.75
local HOLD_FILL = 0.5
local NUDGE = 4
local PAGE_SHIFT = 24
local TILT = -2
local SHAKE_ANGLE = 4
local RESULT_HOLD = 1.2
local CONFIRM_WINDOW = 3
local DEFAULT_COOLDOWN = 3

local function animate(instance: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
	local chosen = if GuiService.ReducedMotionEnabled then INSTANT else timing
	local tween = TweenService:Create(instance, chosen, goals)
	tween:Play()
	return tween
end

-- The scale a style shows for each pointer state: most never scale, P2 presses
-- in, P3 lifts on hover and settles on press, P7 squashes and springs back.
local SCALE = {
	P2 = { rest = 1, hover = 1, pressed = 0.97 },
	P3 = { rest = 1, hover = 1.02, pressed = 0.98 },
	P7 = { rest = 1, hover = 1, pressed = 0.94 },
	P21 = { rest = 1, hover = 1.06, pressed = 0.98 },
}
local FLAT = { rest = 1, hover = 1, pressed = 1 }

-- The effects that add children need a button whose own layout would not
-- grab them: a plain text button, or one whose content sits in a child frame.
local function needsBare(button: GuiButton, style: string)
	local layout = button:FindFirstChildOfClass("UIListLayout")
	assert(not layout, `{style} needs a button with no UIListLayout`)
end

-- A clipped layer that matches the button's corners, for effects that must
-- stay inside its shape; a CanvasGroup rounds what ClipsDescendants cannot.
local function layer(button: GuiButton, style: string, name: string): CanvasGroup
	needsBare(button, style)
	local group = Instance.new("CanvasGroup")
	group.Name = name
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundTransparency = 1
	group.Parent = button

	local shape = button:FindFirstChildOfClass("UICorner")
	if shape then
		shape:Clone().Parent = group
	end
	return group
end

local function newFrame(name: string, colour: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	return frame
end

-- `onHold` is P10's action: it runs when the fill completes, never on a tap.
local function attachPress(button: GuiButton, style: PressStyle, onHold: (() -> ())?): () -> ()
	local connections: { RBXScriptConnection } = {}
	local made: { Instance } = {}
	local hovered, pressed = false, false
	button.AutoButtonColor = false

	local size = Instance.new("UIScale")
	size.Name = "PressScale"
	size.Parent = button
	table.insert(made, size)

	local rim = Instance.new("UIStroke")
	rim.Name = "LiftEdge"
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = if style == "P5" or style == "P12" then THEME.accent else THEME.edge
	rim.Thickness = if style == "P5" or style == "P12" then 2 else 1
	rim.Transparency = 1
	rim.Parent = button
	table.insert(made, rim)

	local sweep: UIGradient? = nil
	if style == "P6" then
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Sweep"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.accentDim),
			ColorSequenceKeypoint.new(0.499, THEME.accentDim),
			ColorSequenceKeypoint.new(0.5, THEME.control),
			ColorSequenceKeypoint.new(1, THEME.control),
		})
		gradient.Offset = Vector2.new(-0.5, 0)
		gradient.Parent = button
		table.insert(made, gradient)
		sweep = gradient
	end

	-- P13 starts as an outline; P14 needs the icon it spins; P15 a gradient to turn.
	if style == "P13" then
		rim.Color = THEME.accent
		rim.Transparency = 0
		button.BackgroundTransparency = 1
	end
	local spinner: GuiObject? = nil
	if style == "P14" then
		local found = button:FindFirstChild("Icon")
		assert(found and found:IsA("GuiObject"), "P14 needs a child named Icon")
		spinner = found
	end
	local shimmer: UIGradient? = nil
	local turning: Tween? = nil
	if style == "P15" then
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Shimmer"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.controlHover),
			ColorSequenceKeypoint.new(0.5, THEME.accentDim),
			ColorSequenceKeypoint.new(1, THEME.controlHover),
		})
		gradient.Enabled = false
		gradient.Parent = button
		table.insert(made, gradient)
		shimmer = gradient
	end

	local underline: Frame? = nil
	local shine: Frame? = nil
	local ripples: CanvasGroup? = nil
	local fill: Frame? = nil
	local arrow: ImageLabel? = nil
	if style == "P8" then
		needsBare(button, style)
		local line = newFrame("Underline", THEME.accent)
		line.AnchorPoint = Vector2.new(0.5, 1)
		line.Position = UDim2.fromScale(0.5, 1)
		line.Size = UDim2.fromOffset(0, 2)
		line.Parent = button
		table.insert(made, line)
		underline = line
	elseif style == "P9" then
		local group = layer(button, style, "ShineLayer")
		table.insert(made, group)

		local band = newFrame("Shine", THEME.white)
		band.Position = UDim2.fromScale(-0.5, 0)
		band.Size = UDim2.fromScale(0.4, 1)
		band.Rotation = 15
		band.BackgroundTransparency = 0.85
		band.Parent = group
		shine = band
	elseif style == "P4" then
		ripples = layer(button, style, "RippleLayer")
		table.insert(made, ripples)
	elseif style == "P10" then
		assert(onHold, "P10 needs onHold")
		local group = layer(button, style, "HoldLayer")
		table.insert(made, group)

		local bar = newFrame("HoldFill", THEME.accent)
		bar.Size = UDim2.fromScale(0, 1)
		bar.BackgroundTransparency = HOLD_FILL
		bar.Parent = group
		fill = bar
	elseif style == "P11" then
		needsBare(button, style)

		local mark = Instance.new("ImageLabel")
		mark.Name = "Arrow"
		mark.AnchorPoint = Vector2.new(1, 0.5)
		mark.Position = UDim2.new(1, -12, 0.5, 0)
		mark.Size = UDim2.fromOffset(16, 16)
		mark.BackgroundTransparency = 1
		mark.Image = ICON.arrow
		mark.ImageColor3 = THEME.text
		mark.Parent = button
		table.insert(made, mark)
		arrow = mark
	end

	local function paint()
		local steps = SCALE[style] or FLAT
		local timing = if pressed then QUICK else RELEASE
		if style == "P13" then
			animate(button, timing, {
				BackgroundTransparency = if hovered or pressed then 0 else 1,
				BackgroundColor3 = if pressed then THEME.accent else THEME.accentDim,
			})
		elseif not sweep then
			local colour = if pressed then THEME.controlPressed
				elseif hovered then THEME.controlHover
				else THEME.control
			animate(button, timing, { BackgroundColor3 = colour })
		end
		local scale = if pressed then steps.pressed elseif hovered then steps.hover else steps.rest
		local springing = (style == "P7" and not pressed and size.Scale < 1)
			or (style == "P21" and hovered and not pressed)
		animate(size, if springing then SPRING_BACK else timing, { Scale = scale })
		if style == "P22" then
			animate(button, timing, { Rotation = if pressed then TILT else 0 })
		end

		if style == "P3" or style == "P5" then
			local lit = if style == "P5" then hovered or pressed else hovered and not pressed
			animate(rim, timing, { Transparency = if lit then 0 else 1 })
			rim.Color = if style == "P5" and pressed then THEME.focus
				elseif style == "P5" then THEME.accent
				else THEME.edge
		end
		if sweep then
			local filled = if hovered or pressed then 0.5 else -0.5
			animate(sweep, SWEEP, { Offset = Vector2.new(filled, 0) })
		end
		if underline then
			animate(underline, SWEEP, { Size = UDim2.new(if hovered then 1 else 0, 0, 0, 2) })
		end
		if arrow then
			local inset = if hovered then -12 + NUDGE else -12
			animate(arrow, RELEASE, { Position = UDim2.new(1, inset, 0.5, 0) })
		end
	end

	local function rippleAt(input: InputObject)
		local group = ripples
		if not group or GuiService.ReducedMotionEnabled then
			return
		end
		local spot = input.Position
		local corner = button.AbsolutePosition
		local reach = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * RIPPLE_SPREAD
		local wave = newFrame("Ripple", THEME.white)
		wave.AnchorPoint = Vector2.new(0.5, 0.5)
		wave.Position = UDim2.fromOffset(spot.X - corner.X, spot.Y - corner.Y)
		wave.Size = UDim2.fromOffset(0, 0)
		wave.BackgroundTransparency = RIPPLE_START
		wave.Parent = group

		local circle = Instance.new("UICorner")
		circle.CornerRadius = UDim.new(0.5, 0)
		circle.Parent = wave

		local spread = animate(wave, RIPPLE, {
			Size = UDim2.fromOffset(reach, reach),
			BackgroundTransparency = 1,
		})
		spread.Completed:Once(function()
			wave:Destroy()
		end)
	end

	local holding: Tween? = nil
	local function startHold()
		local bar, run = fill, onHold
		if not bar or not run then
			return
		end
		local tween = TweenService:Create(bar, HOLD, { Size = UDim2.fromScale(1, 1) })
		holding = tween
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and holding == tween then
				holding = nil
				bar.Size = UDim2.fromScale(0, 1)
				run()
			end
		end)
		tween:Play()
	end
	local function drainHold()
		local tween, bar = holding, fill
		if not tween or not bar then
			return
		end
		holding = nil
		tween:Cancel()
		animate(bar, DRAIN, { Size = UDim2.fromScale(0, 1) })
	end

	table.insert(connections, button.MouseEnter:Connect(function()
		hovered = true
		paint()
		local band = shine
		if band then
			band.Position = UDim2.fromScale(-0.5, 0)
			animate(band, SHINE, { Position = UDim2.fromScale(1.1, 0) })
		end
		local gradient = shimmer
		if gradient and not GuiService.ReducedMotionEnabled then
			gradient.Enabled = true
			gradient.Rotation = 0
			turning = TweenService:Create(gradient, SHIMMER, { Rotation = 360 })
			turning:Play()
		end
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint()
		drainHold()
		if turning then
			turning:Cancel()
			turning = nil
		end
		if shimmer then
			shimmer.Enabled = false
		end
	end))
	if spinner then
		local icon = spinner
		table.insert(connections, button.Activated:Connect(function()
			icon.Rotation = 0
			animate(icon, SPIN, { Rotation = 360 }).Completed:Once(function()
				icon.Rotation = 0
			end)
		end))
	end
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressed = true
			paint()
			rippleAt(input)
			startHold()
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		pressed = false
		paint()
		drainHold()
	end))
	if style == "P12" then
		table.insert(connections, button.Activated:Connect(function()
			rim.Transparency = 0
			animate(rim, RIPPLE, { Transparency = 1 })
			animate(size, POP, { Scale = 1.05 })
		end))
	end

	button.BackgroundColor3 = if sweep then THEME.white else THEME.control
	size.Scale = 1
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		if holding then
			holding:Cancel()
		end
		if turning then
			turning:Cancel()
		end
		for _, instance in made do
			instance:Destroy()
		end
	end
end

-- P16 to P20 change what a text button says while its work happens, so the
-- player always knows whether pressing again does anything. Returns cleanup.
local function attachAction(button: TextButton, style: ActionStyle, spec: ActionSpec): () -> ()
	local connections: { RBXScriptConnection } = {}
	local label = button.Text
	local rest = button.BackgroundColor3
	local ticket = 0
	local busy = false
	local armed = false

	local function restore()
		ticket += 1
		busy, armed = false, false
		button.Text = label
		button.BackgroundColor3 = rest
		button.Interactable = true
	end

	-- P18: a bar across the button drains while the cooldown counts down.
	local drain: Frame? = nil
	if style == "P18" then
		local group = layer(button, style, "CooldownLayer")
		local bar = newFrame("Cooldown", THEME.white)
		bar.Size = UDim2.fromScale(0, 1)
		bar.BackgroundTransparency = HOLD_FILL
		bar.Parent = group
		drain = bar
	end

	local function countDown(left: number, mine: number)
		if mine ~= ticket then
			return
		end
		if left <= 0 then
			restore()
			return
		end
		button.Text = `{label} {left}s`
		task.delay(1, countDown, left - 1, mine)
	end

	local function finished(ok: boolean)
		if style == "P17" then
			ticket += 1
			local mine = ticket
			button.Text = if ok then "Done" else "Failed"
			button.BackgroundColor3 = if ok then THEME.accent else THEME.danger
			task.delay(RESULT_HOLD, function()
				if mine == ticket then
					restore()
				end
			end)
			return
		end
		if style == "P18" then
			ticket += 1
			local seconds = spec.seconds or DEFAULT_COOLDOWN
			local bar = drain
			if bar then
				bar.Size = UDim2.fromScale(1, 1)
				local timing = TweenInfo.new(seconds, Enum.EasingStyle.Linear)
				animate(bar, timing, { Size = UDim2.fromScale(0, 1) })
			end
			countDown(seconds, ticket)
			return
		end
		restore()
	end

	local function shake()
		button.Rotation = 0
		animate(button, SHAKE, { Rotation = SHAKE_ANGLE }).Completed:Once(function()
			button.Rotation = 0
		end)
	end

	table.insert(connections, button.Activated:Connect(function()
		if busy then
			return
		end
		local allowed = spec.allowed
		if style == "P20" and allowed and not allowed() then
			shake()
			return
		end
		if style == "P19" and not armed then
			ticket += 1
			local mine = ticket
			armed = true
			button.Text = spec.confirmText or "Press again to confirm"
			button.BackgroundColor3 = THEME.danger
			task.delay(CONFIRM_WINDOW, function()
				if mine == ticket then
					restore()
				end
			end)
			return
		end
		busy = true
		button.Interactable = style ~= "P16" and style ~= "P18"
		if style == "P16" then
			button.Text = "Working…"
		end
		spec.run(finished)
	end))

	return function()
		ticket += 1
		for _, connection in connections do
			connection:Disconnect()
		end
		button.Text = label
		button.BackgroundColor3 = rest
		button.Interactable = true
	end
end

export type TabOptions = {
	icons: { [string]: string }?,
	pages: { [string]: CanvasGroup }?,
}

export type Tabs = {
	select: (name: string) -> (),
	selected: () -> string,
	destroy: () -> (),
}

type Marker = "line" | "pill" | "side" | "dot" | "none"

-- What marks the chosen tab in each style.
local MARKER: { [TabStyle]: Marker } = {
	S1 = "line",
	S2 = "pill",
	S3 = "none",
	S4 = "side",
	S5 = "pill",
	S6 = "line",
	S7 = "pill",
	S8 = "pill",
	S9 = "line",
	S10 = "line",
	S11 = "dot",
	S12 = "pill",
}

-- S9 and S10 move the pages too: S9 slides them toward the side the new tab is
-- on, S10 fades the old page out before the new one fades in.
local function turnPage(style: TabStyle, from: CanvasGroup?, to: CanvasGroup?, forward: boolean)
	local shift = if style ~= "S9" then 0 elseif forward then PAGE_SHIFT else -PAGE_SHIFT
	if from then
		local out = animate(from, PAGE_OUT, {
			GroupTransparency = 1,
			Position = UDim2.fromOffset(-shift, 0),
		})
		out.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and from.GroupTransparency == 1 then
				from.Visible = false
			end
		end)
	end
	if to then
		to.Visible = true
		to.GroupTransparency = 1
		to.Position = UDim2.fromOffset(shift, 0)
		animate(to, PAGE_IN, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
	end
end

local function label(parent: GuiObject, text: string, size: number, order: number): TextLabel
	local words = Instance.new("TextLabel")
	words.Name = "Label"
	words.LayoutOrder = order
	words.Size = UDim2.new(1, 0, 0, 16)
	words.BackgroundTransparency = 1
	words.TextSize = size
	words.Text = text
	words.Parent = parent
	return words
end

-- The marker is a sibling of the tab row, not a child of its UIListLayout, so
-- it can slide freely; its target is read from the chosen tab's geometry.
-- S4, S5 and S7 stack their tabs down the side instead of across.
local function createTabs(
	parent: GuiObject,
	names: { string },
	style: TabStyle,
	onSelect: (name: string) -> (),
	options: TabOptions?
): Tabs
	local connections: { RBXScriptConnection } = {}
	local buttons: { [string]: TextButton } = {}
	local words: { [string]: TextLabel } = {}
	local glyphs: { [string]: ImageLabel } = {}
	local current = names[1]
	local hovered: string? = nil
	local icons = if options and options.icons then options.icons else {}
	local pages = if options and options.pages then options.pages else {}
	local vertical = style == "S4" or style == "S5" or style == "S7"
	local marker = MARKER[style]
	local scrolls = style == "S12"

	local bar: Frame | ScrollingFrame
	if scrolls then
		local scroller = Instance.new("ScrollingFrame")
		scroller.ScrollingDirection = Enum.ScrollingDirection.X
		scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
		scroller.CanvasSize = UDim2.fromScale(0, 1)
		scroller.CanvasPosition = Vector2.zero
		scroller.ScrollBarThickness = 0
		scroller.BorderSizePixel = 0
		bar = scroller
	else
		bar = Instance.new("Frame")
	end
	bar.Name = "Tabs"
	bar.Size = if vertical
		then UDim2.fromScale(1, 1)
		else UDim2.new(1, 0, 0, if style == "S6" then 56 else 44)
	bar.BackgroundColor3 = THEME.track
	bar.BackgroundTransparency = if style == "S8" then 0 else 1
	bar.Parent = parent

	if style == "S8" then
		local sunk = Instance.new("UICorner")
		sunk.CornerRadius = UDim.new(0, 6)
		sunk.Parent = bar
	end

	local mark = newFrame("Marker", if marker == "pill" then THEME.controlHover else THEME.accent)
	mark.Visible = marker ~= "none"
	mark.ZIndex = 1
	mark.Parent = bar

	local markCorner = Instance.new("UICorner")
	markCorner.CornerRadius = if marker == "dot" then UDim.new(0.5, 0)
		elseif marker == "pill" then UDim.new(0, 6)
		else UDim.new(0, 0)
	markCorner.Parent = mark

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = if scrolls then UDim2.fromScale(0, 1) else UDim2.fromScale(1, 1)
	row.AutomaticSize = if scrolls then Enum.AutomaticSize.X else Enum.AutomaticSize.None
	row.BackgroundTransparency = 1
	row.ZIndex = 2
	row.Parent = bar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection[if vertical then "Vertical" else "Horizontal"]
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, if vertical then 4 else 0)
	layout.Parent = row

	if style == "S8" then
		local inset = Instance.new("UIPadding")
		inset.PaddingTop = UDim.new(0, 4)
		inset.PaddingBottom = UDim.new(0, 4)
		inset.PaddingLeft = UDim.new(0, 4)
		inset.PaddingRight = UDim.new(0, 4)
		inset.Parent = row
	end

	local function moveMarker(instant: boolean)
		local tab = buttons[current]
		local origin = bar.AbsolutePosition
		local canvas = if scrolls then (bar :: ScrollingFrame).CanvasPosition else Vector2.zero
		local x = tab.AbsolutePosition.X - origin.X + canvas.X
		local y = tab.AbsolutePosition.Y - origin.Y + canvas.Y
		local width, height = tab.AbsoluteSize.X, tab.AbsoluteSize.Y
		local position, size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
		if marker == "line" then
			position, size = UDim2.fromOffset(x, y + height - 2), UDim2.fromOffset(width, 2)
		elseif marker == "side" then
			size = UDim2.fromOffset(3, height)
		elseif marker == "dot" then
			position = UDim2.fromOffset(x + width / 2 - 3, y + height - 8)
			size = UDim2.fromOffset(6, 6)
		end
		animate(mark, if instant then INSTANT else SLIDE, { Position = position, Size = size })
	end

	local function paint()
		for name, tab in buttons do
			local chosen = name == current
			local colour = if chosen or name == hovered then THEME.text else THEME.textMuted
			local weight = if chosen then Enum.Font.GothamBold else Enum.Font.GothamMedium
			tab.TextColor3 = colour
			tab.FontFace = Font.fromEnum(weight)
			local caption = words[name]
			if caption then
				caption.TextColor3 = colour
				caption.FontFace = Font.fromEnum(weight)
			end
			local glyph = glyphs[name]
			if glyph then
				glyph.ImageColor3 = if chosen then THEME.focus else colour
			end
		end
	end

	local function select(name: string)
		if name == current or not buttons[name] then
			return
		end
		local before = table.find(names, current) or 0
		local after = table.find(names, name) or 0
		turnPage(style, pages[current], pages[name], after > before)
		current = name
		paint()
		moveMarker(false)
		if scrolls then
			local scroller = bar :: ScrollingFrame
			local tab = buttons[name]
			local canvas = scroller.CanvasPosition.X
			local left = tab.AbsolutePosition.X - scroller.AbsolutePosition.X + canvas
			local visible = scroller.AbsoluteSize.X
			local target = math.clamp(left - (visible - tab.AbsoluteSize.X) / 2, 0, math.huge)
			animate(scroller, SLIDE, { CanvasPosition = Vector2.new(target, 0) })
		end
		onSelect(name)
	end

	for index, name in names do
		local tab = Instance.new("TextButton")
		tab.Name = name
		tab.LayoutOrder = index
		tab.AutoButtonColor = false
		tab.BackgroundTransparency = 1
		tab.TextSize = 14
		tab.Text = name
		tab.Parent = row

		if vertical then
			tab.Size = UDim2.new(1, 0, 0, 44)
			tab.TextXAlignment = Enum.TextXAlignment.Left
			local inset = Instance.new("UIPadding")
			inset.PaddingLeft = UDim.new(0, 16)
			inset.Parent = tab
		elseif scrolls then
			tab.AutomaticSize = Enum.AutomaticSize.X
			tab.Size = UDim2.fromScale(0, 1)
			local inset = Instance.new("UIPadding")
			inset.PaddingLeft = UDim.new(0, 16)
			inset.PaddingRight = UDim.new(0, 16)
			inset.Parent = tab
		else
			tab.Size = UDim2.fromScale(0, 1)
			local share = Instance.new("UIFlexItem")
			share.FlexMode = Enum.UIFlexMode.Fill
			share.Parent = tab
		end

		-- S6 stacks an icon over a small label; S7 shows the icon alone.
		if style == "S6" or style == "S7" then
			tab.Text = ""
			local glyph = Instance.new("ImageLabel")
			glyph.Name = "Glyph"
			glyph.LayoutOrder = 1
			glyph.Size = UDim2.fromOffset(20, 20)
			glyph.BackgroundTransparency = 1
			glyph.Image = icons[name] or ICON.tab
			glyph.Parent = tab
			glyphs[name] = glyph

			local stack = Instance.new("UIListLayout")
			stack.SortOrder = Enum.SortOrder.LayoutOrder
			stack.HorizontalAlignment = Enum.HorizontalAlignment.Center
			stack.VerticalAlignment = Enum.VerticalAlignment.Center
			stack.Padding = UDim.new(0, 4)
			stack.Parent = tab
			if style == "S7" then
				tab.Size = UDim2.fromOffset(44, 44)
			else
				words[name] = label(tab, name, 12, 2)
			end
		end

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

	for name, page in pages do
		page.Visible = name == current
		page.GroupTransparency = if name == current then 0 else 1
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
	attachAction = attachAction,
	createTabs = createTabs,
}
