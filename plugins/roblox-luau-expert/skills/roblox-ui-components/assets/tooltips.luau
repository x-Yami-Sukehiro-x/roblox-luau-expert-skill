--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- H1 to H10 without H3 to H6 attach to a control; H3 to H5 show a slider's
-- value; H6 is its own button, H11 sits under a field and H12 points once.
export type TooltipStyle = "H1" | "H2" | "H7" | "H8" | "H9" | "H10"
export type SliderStyle = "H3" | "H4" | "H5"

-- `title` and `keyHint` are shown by H7. `host` is the ScreenGui the bubble
-- floats above; by default the target's own.
export type TooltipSpec = {
	text: string,
	title: string?,
	keyHint: string?,
	host: ScreenGui?,
}

export type Tooltip = {
	setText: (text: string) -> (),
	setDisabled: (disabled: boolean) -> (),
	show: () -> (),
	hide: () -> (),
	destroy: () -> (),
}

-- `format` turns the value into words, such as `"{value} studs"`.
export type SliderParts = {
	track: GuiObject,
	thumb: GuiObject,
	min: number,
	max: number,
	format: ((value: number) -> string)?,
}

export type SliderValue = {
	update: (value: number) -> (),
	setDragging: (dragging: boolean) -> (),
	destroy: () -> (),
}

local THEME = {
	bubble = Color3.fromRGB(9, 10, 13),
	edge = Color3.fromRGB(63, 68, 79),
	chip = Color3.fromRGB(31, 34, 41),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	focus = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	lock = "rbxassetid://119765975153029",
}

local FADE_IN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

-- A pointer resting this long means a question; passing over means nothing.
local HOVER_DELAY = 0.4
-- A finger has no hover, so a hold of this long asks instead.
local TOUCH_HOLD = 0.5
-- After a finger lifts, the answer stays long enough to read.
local TOUCH_LINGER = 1.5
local GAP = 8
local EDGE = 8
local MAX_WIDTH = 240
local CURSOR_OFFSET = 16
local ARROW = 10

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function pad(target: GuiObject, vertical: number, horizontal: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, vertical)
	padding.PaddingBottom = UDim.new(0, vertical)
	padding.PaddingLeft = UDim.new(0, horizontal)
	padding.PaddingRight = UDim.new(0, horizontal)
	padding.Parent = target
end

local function stackIn(target: GuiObject, direction: Enum.FillDirection, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = target
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
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	return label
end

local function glyph(name: string, image: string, size: number, colour: Color3): ImageLabel
	local picture = Instance.new("ImageLabel")
	picture.Name = name
	picture.Size = UDim2.fromOffset(size, size)
	picture.BackgroundTransparency = 1
	picture.Image = image
	picture.ImageColor3 = colour
	return picture
end

-- Bubbles float in a ScreenGui of their own above the host, so no list or
-- clipping frame cuts them off. The layer copies the host's insets, so
-- positions measured against it land where the target is drawn.
local function newLayer(target: GuiObject, host: ScreenGui?): ScreenGui
	local owner = host or target:FindFirstAncestorWhichIsA("ScreenGui")
	assert(owner, "a tooltip's target must be inside a ScreenGui")
	local layer = Instance.new("ScreenGui")
	layer.Name = "TooltipLayer"
	layer.ResetOnSpawn = false
	layer.DisplayOrder = owner.DisplayOrder + 2
	layer.ScreenInsets = owner.ScreenInsets
	layer.Parent = owner.Parent
	return layer
end

-- The bubble: a title (H7), the words, and a key hint chip (H7), or a lock
-- before the words for H9's reason.
local function newBubble(spec: TooltipSpec, locked: boolean): (CanvasGroup, TextLabel)
	local bubble = Instance.new("CanvasGroup")
	bubble.Name = "Bubble"
	bubble.AutomaticSize = Enum.AutomaticSize.XY
	bubble.BackgroundColor3 = THEME.bubble
	bubble.GroupTransparency = 1
	bubble.Visible = false
	bubble.ZIndex = 2
	round(bubble, UDim.new(0, 6))
	pad(bubble, 8, 12)
	stackIn(bubble, Enum.FillDirection.Vertical, 4)

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = if locked then THEME.danger else THEME.edge
	edge.Parent = bubble

	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	bounds.Parent = bubble

	local title = spec.title
	if title then
		local heading = words("Title", title, 14, true)
		heading.LayoutOrder = 1
		heading.Parent = bubble
	end

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.LayoutOrder = 2
	line.AutomaticSize = Enum.AutomaticSize.XY
	line.BackgroundTransparency = 1
	line.Parent = bubble
	stackIn(line, Enum.FillDirection.Horizontal, 8)

	if locked then
		local lock = glyph("Lock", ICON.lock, 16, THEME.danger)
		lock.LayoutOrder = 1
		lock.Parent = line
	end

	local body = words("Text", spec.text, if title then 12 else 14, false)
	body.LayoutOrder = 2
	body.TextColor3 = if title then THEME.textMuted else THEME.text
	body.Parent = line

	local keyHint = spec.keyHint
	if keyHint then
		local chip = words("Key", keyHint, 12, true)
		chip.LayoutOrder = 3
		chip.BackgroundColor3 = THEME.chip
		chip.BackgroundTransparency = 0
		round(chip, UDim.new(0, 4))
		pad(chip, 2, 6)
		chip.Parent = bubble
	end
	return bubble, body
end

-- Where a bubble of this size goes beside a rectangle: below it, or above
-- when the layer has no room below, and never past either side edge.
local function beside(
	layer: ScreenGui,
	bubble: GuiObject,
	left: number,
	top: number,
	width: number,
	height: number,
	above: boolean
): (number, number, boolean)
	local size = bubble.AbsoluteSize
	local room = layer.AbsoluteSize
	local rightmost = math.max(EDGE, room.X - size.X - EDGE)
	local x = math.clamp(left + width / 2 - size.X / 2, EDGE, rightmost)
	local below = top + height + GAP
	local over = top - size.Y - GAP
	local useAbove = if above then over >= 0 else below + size.Y > room.Y and over >= 0
	return x, if useAbove then over else below, useAbove
end

local function fade(bubble: CanvasGroup, visible: boolean)
	if visible then
		bubble.Visible = true
		TweenService:Create(bubble, motion(FADE_IN), { GroupTransparency = 0 }):Play()
		return
	end
	local out = TweenService:Create(bubble, motion(FADE_OUT), { GroupTransparency = 1 })
	out.Completed:Once(function()
		if bubble.GroupTransparency == 1 then
			bubble.Visible = false
		end
	end)
	out:Play()
end

-- H1 below the control, H2 above it with an arrow, H7 with a title and key,
-- H8 at the pointer, H9 only while disabled, H10 only while pressed. Every
-- style also answers a long press on a phone and keyboard or gamepad focus.
local function createTooltip(target: GuiObject, style: TooltipStyle, spec: TooltipSpec): Tooltip
	local connections: { RBXScriptConnection } = {}
	local layer = newLayer(target, spec.host)
	local bubble, body = newBubble(spec, style == "H9")
	bubble.Parent = layer
	local ticket = 0
	local shown = false
	local disabled = false
	local pointer: { x: number, y: number }? = nil

	local arrow: Frame? = nil
	if style == "H2" then
		local point = Instance.new("Frame")
		point.Name = "Arrow"
		point.Size = UDim2.fromOffset(ARROW, ARROW)
		point.AnchorPoint = Vector2.new(0.5, 0.5)
		point.Rotation = 45
		point.BackgroundColor3 = THEME.bubble
		point.BorderSizePixel = 0
		point.Visible = false
		point.ZIndex = 1
		point.Parent = layer
		arrow = point
	end

	-- H9 reads hovers through a transparent cover over the control, because a
	-- disabled control gets no input of its own.
	local cover: TextButton? = nil

	local function place()
		local origin = layer.AbsolutePosition
		local at = pointer
		if style == "H8" and at then
			local x = at.x - origin.X + CURSOR_OFFSET
			bubble.Position = UDim2.fromOffset(x, at.y - origin.Y + CURSOR_OFFSET)
			return
		end
		local left = target.AbsolutePosition.X - origin.X
		local top = target.AbsolutePosition.Y - origin.Y
		local size = target.AbsoluteSize
		local x, y, above = beside(layer, bubble, left, top, size.X, size.Y, style == "H2")
		bubble.Position = UDim2.fromOffset(x, y)
		local point = arrow
		if point then
			local tip = if above then y + bubble.AbsoluteSize.Y else y
			point.Position = UDim2.fromOffset(left + size.X / 2, tip)
		end
	end

	local function show()
		if disabled ~= (style == "H9") then
			return
		end
		ticket += 1
		shown = true
		place()
		fade(bubble, true)
		if arrow then
			arrow.Visible = true
		end
	end

	local function hide()
		ticket += 1
		if not shown then
			return
		end
		shown = false
		fade(bubble, false)
		if arrow then
			arrow.Visible = false
		end
	end

	local function later(seconds: number, run: () -> ())
		ticket += 1
		local mine = ticket
		task.delay(seconds, function()
			if mine == ticket then
				run()
			end
		end)
	end

	-- One set of handlers for the control, or for H9's cover in its place.
	local function listen(source: GuiObject)
		table.insert(connections, source.MouseEnter:Connect(function(x: number, y: number)
			pointer = { x = x, y = y }
			local touch = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
			if style ~= "H10" and not touch then
				later(HOVER_DELAY, show)
			end
		end))
		table.insert(connections, source.MouseMoved:Connect(function(x: number, y: number)
			pointer = { x = x, y = y }
			if shown and style == "H8" then
				place()
			end
		end))
		table.insert(connections, source.MouseLeave:Connect(hide))
		table.insert(connections, source.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			local click = style == "H10" and kind == Enum.UserInputType.MouseButton1
			if kind == Enum.UserInputType.Touch or click then
				later(TOUCH_HOLD, show)
			end
		end))
		table.insert(connections, source.InputEnded:Connect(function(input: InputObject)
			if style == "H10" or input.UserInputType ~= Enum.UserInputType.Touch then
				hide()
			else
				later(TOUCH_LINGER, hide)
			end
		end))
		table.insert(connections, source.SelectionGained:Connect(show))
		table.insert(connections, source.SelectionLost:Connect(hide))
	end

	if style == "H9" then
		local catcher = Instance.new("TextButton")
		catcher.Name = "ReasonCatcher"
		catcher.AutoButtonColor = false
		catcher.BackgroundTransparency = 1
		catcher.Text = ""
		catcher.Visible = false
		catcher.Parent = layer
		cover = catcher
		listen(catcher)
		table.insert(connections, catcher.Activated:Connect(show))
	else
		listen(target)
	end

	local function setDisabled(next: boolean)
		disabled = next
		local catcher = cover
		if catcher then
			local origin = layer.AbsolutePosition
			catcher.Position = UDim2.fromOffset(
				target.AbsolutePosition.X - origin.X,
				target.AbsolutePosition.Y - origin.Y
			)
			catcher.Size = UDim2.fromOffset(target.AbsoluteSize.X, target.AbsoluteSize.Y)
			catcher.Visible = next
		end
		if not next then
			hide()
		end
	end

	return {
		setText = function(text: string)
			body.Text = text
			if shown then
				place()
			end
		end,
		setDisabled = setDisabled,
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			layer:Destroy()
		end,
	}
end

-- H3 floats the value over the thumb while it is dragged; H4 keeps it over
-- the thumb; H5 writes the ends under the track and the value after it.
local function createSliderValue(parts: SliderParts, style: SliderStyle): SliderValue
	local format = parts.format or function(value: number): string
		return tostring(math.floor(value + 0.5))
	end
	local made: { Instance } = {}
	local dragging = false
	local current = parts.min

	local bubble: CanvasGroup? = nil
	local bubbleText: TextLabel? = nil
	local layer: ScreenGui? = nil
	if style == "H3" then
		local floating = newLayer(parts.thumb)
		table.insert(made, floating)
		local card, text = newBubble({ text = format(current) }, false)
		card.AnchorPoint = Vector2.new(0.5, 1)
		card.Parent = floating
		layer, bubble, bubbleText = floating, card, text
	end

	local tag: TextLabel? = nil
	if style == "H4" then
		local label = words("ValueTag", format(current), 12, true)
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 0, -GAP)
		label.BackgroundColor3 = THEME.bubble
		label.BackgroundTransparency = 0
		round(label, UDim.new(0, 4))
		pad(label, 2, 6)
		label.Parent = parts.thumb
		table.insert(made, label)
		tag = label
	end

	local readout: TextLabel? = nil
	if style == "H5" then
		-- The two ends of the range, under the matching end of the track.
		local function markEnd(name: string, value: number, side: number)
			local mark = words(name, format(value), 12, false)
			mark.AnchorPoint = Vector2.new(side, 0)
			mark.Position = UDim2.new(side, 0, 1, 4)
			mark.TextColor3 = THEME.textMuted
			mark.Parent = parts.track
			table.insert(made, mark)
		end
		markEnd("Min", parts.min, 0)
		markEnd("Max", parts.max, 1)
		local label = words("Value", format(current), 14, true)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.new(1, 12, 0.5, 0)
		label.Parent = parts.track
		table.insert(made, label)
		readout = label
	end

	local function place()
		local card, floating = bubble, layer
		if not card or not floating then
			return
		end
		local origin = floating.AbsolutePosition
		local thumb = parts.thumb
		local x = thumb.AbsolutePosition.X - origin.X + thumb.AbsoluteSize.X / 2
		local y = thumb.AbsolutePosition.Y - origin.Y - GAP
		card.Position = UDim2.fromOffset(x, y)
	end

	local function update(value: number)
		current = math.clamp(value, parts.min, parts.max)
		local text = format(current)
		if bubbleText then
			bubbleText.Text = text
		end
		if tag then
			tag.Text = text
		end
		if readout then
			readout.Text = text
		end
		if dragging then
			place()
		end
	end

	return {
		update = update,
		setDragging = function(next: boolean)
			dragging = next
			local card = bubble
			if card then
				if next then
					place()
				end
				fade(card, next)
			end
		end,
		destroy = function()
			for _, instance in made do
				instance:Destroy()
			end
		end,
	}
end

-- H6: an info mark with a 44 px target; a tap opens its words and a tap
-- anywhere else, or Escape, closes them. Nothing depends on hover.
local function createInfoButton(parent: GuiObject, text: string, order: number?)
	local connections: { RBXScriptConnection } = {}
	local button = Instance.new("ImageButton")
	button.Name = "Info"
	button.LayoutOrder = order or 0
	button.Size = UDim2.fromOffset(44, 44)
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Image = ""
	button.Parent = parent

	local mark = glyph("Mark", ICON.info, 16, THEME.textMuted)
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Parent = button

	local layer = newLayer(button)
	local catcher = Instance.new("TextButton")
	catcher.Name = "Catcher"
	catcher.AutoButtonColor = false
	catcher.BackgroundTransparency = 1
	catcher.Text = ""
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.Visible = false
	catcher.Parent = layer

	local bubble = newBubble({ text = text }, false)
	bubble.Parent = layer

	local function setOpen(open: boolean)
		catcher.Visible = open
		mark.ImageColor3 = if open then THEME.focus else THEME.textMuted
		if open then
			local origin = layer.AbsolutePosition
			local left = button.AbsolutePosition.X - origin.X
			local top = button.AbsolutePosition.Y - origin.Y
			local size = button.AbsoluteSize
			local x, y = beside(layer, bubble, left, top, size.X, size.Y, false)
			bubble.Position = UDim2.fromOffset(x, y)
		end
		fade(bubble, open)
	end

	table.insert(connections, button.Activated:Connect(function()
		setOpen(not catcher.Visible)
	end))
	table.insert(connections, catcher.Activated:Connect(function()
		setOpen(false)
	end))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject)
		if catcher.Visible and input.KeyCode == Enum.KeyCode.Escape then
			setOpen(false)
		end
	end))

	return {
		button = button,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			layer:Destroy()
			button:Destroy()
		end,
	}
end

-- H11: a line under a field that says what it wants, and turns into the
-- error, with an icon, when the entry is wrong.
local function createHelperText(parent: GuiObject, text: string, order: number)
	local row = Instance.new("Frame")
	row.Name = "Help"
	row.LayoutOrder = order
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.fromScale(1, 0)
	row.BackgroundTransparency = 1
	row.Parent = parent
	stackIn(row, Enum.FillDirection.Horizontal, 4)

	local warning = glyph("Alert", ICON.info, 16, THEME.danger)
	warning.LayoutOrder = 1
	warning.Visible = false
	warning.Parent = row

	local hint = words("Text", text, 12, false)
	hint.LayoutOrder = 2
	hint.TextColor3 = THEME.textMuted
	hint.Parent = row

	return {
		label = hint,
		setError = function(message: string?)
			warning.Visible = message ~= nil
			hint.Text = message or text
			hint.TextColor3 = if message then THEME.danger else THEME.textMuted
		end,
		destroy = function()
			row:Destroy()
		end,
	}
end

-- H12: shown once to point at something new, with a ring around it and a
-- button that says the player has seen it. `onDone` runs once; store it so
-- the mark never returns. Returns a dismiss that is safe to repeat.
local function showCoachMark(target: GuiObject, text: string, onDone: () -> ()): () -> ()
	local layer = newLayer(target)
	local finished = false
	local connections: { RBXScriptConnection } = {}

	local origin = layer.AbsolutePosition
	local left = target.AbsolutePosition.X - origin.X
	local top = target.AbsolutePosition.Y - origin.Y
	local size = target.AbsoluteSize

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Position = UDim2.fromOffset(left - 4, top - 4)
	ring.Size = UDim2.fromOffset(size.X + 8, size.Y + 8)
	ring.BackgroundTransparency = 1
	ring.Parent = layer
	round(ring, UDim.new(0, 10))

	local glow = Instance.new("UIStroke")
	glow.Color = THEME.focus
	glow.Thickness = 2
	glow.Parent = ring

	local bubble = newBubble({ text = text }, false)
	bubble.Parent = layer

	local gotIt = Instance.new("TextButton")
	gotIt.Name = "GotIt"
	gotIt.LayoutOrder = 4
	gotIt.AutoButtonColor = false
	gotIt.AutomaticSize = Enum.AutomaticSize.X
	gotIt.Size = UDim2.fromOffset(0, 44)
	gotIt.BackgroundColor3 = THEME.accent
	gotIt.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	gotIt.TextSize = 14
	gotIt.TextColor3 = THEME.text
	gotIt.Text = "Got it"
	gotIt.Parent = bubble
	round(gotIt, UDim.new(0, 6))
	pad(gotIt, 0, 16)

	local x, y = beside(layer, bubble, left, top, size.X, size.Y, false)
	bubble.Position = UDim2.fromOffset(x, y)
	fade(bubble, true)

	local function dismiss()
		if finished then
			return
		end
		finished = true
		for _, connection in connections do
			connection:Disconnect()
		end
		layer:Destroy()
		onDone()
	end
	table.insert(connections, gotIt.Activated:Connect(dismiss))
	return dismiss
end

return {
	createTooltip = createTooltip,
	createSliderValue = createSliderValue,
	createInfoButton = createInfoButton,
	createHelperText = createHelperText,
	showCoachMark = showCoachMark,
}
