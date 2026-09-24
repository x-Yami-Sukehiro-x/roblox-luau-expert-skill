--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local THEME = {
	row = Color3.fromRGB(31, 34, 41),
	rowHover = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	mark = Color3.fromRGB(243, 245, 248),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(118, 125, 139),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
	danger = Color3.fromRGB(208, 88, 82),
	swatchRed = Color3.fromRGB(208, 88, 82),
	swatchGold = Color3.fromRGB(214, 158, 62),
	swatchGreen = Color3.fromRGB(72, 178, 112),
	swatchBlue = Color3.fromRGB(88, 141, 214),
	swatchPurple = Color3.fromRGB(150, 110, 214),
}

local ICON = {
	check = "rbxassetid://86817768619372",
	dash = "rbxassetid://95070996149109",
	tile = "rbxassetid://106101842173393",
	cross = "rbxassetid://116396312853810",
	star = "rbxassetid://72669221096319",
}

-- C18's colours when the caller names none.
local DEFAULT_SWATCHES = {
	Red = THEME.swatchRed,
	Gold = THEME.swatchGold,
	Green = THEME.swatchGreen,
	Blue = THEME.swatchBlue,
	Purple = THEME.swatchPurple,
}

local STATE_MOTION = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DRAW_MOTION = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_MOTION = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local NO_MOTION = TweenInfo.new(0)

export type BoxStyle = "C1" | "C2" | "C3" | "C5" | "C6" | "C7" | "C11" | "C12" | "C13" | "C14"
type FirstGroups = "C4" | "C8" | "C9" | "C10"
export type GroupStyle = FirstGroups | "C15" | "C16" | "C17" | "C18" | "C19" | "C20"

-- C7 reads `description`, C12 `count`; C10 reads `icons`, C18 `colours` and C20
-- `descriptions`, each keyed by item name.
export type CheckDetails = {
	description: string?,
	count: number?,
	icons: { [string]: string }?,
	colours: { [string]: Color3 }?,
	descriptions: { [string]: string }?,
}

export type Checkbox = {
	row: TextButton,
	set: (value: boolean) -> (),
	get: () -> boolean,
	setEnabled: (enabled: boolean) -> (),
	destroy: () -> (),
}

export type CheckGroup = {
	frame: Frame,
	set: (name: string, on: boolean) -> (),
	selected: () -> { string },
	destroy: () -> (),
}

-- Before the row is parented there is nothing on screen to animate, so the
-- first paint assigns directly instead of easing in from the defaults.
local function animate(instance: Instance, goals: { [string]: any }, timing: TweenInfo?)
	if not instance:IsDescendantOf(game) then
		for property, goal in goals do
			(instance :: any)[property] = goal
		end
		return
	end
	local chosen = if GuiService.ReducedMotionEnabled then NO_MOTION else timing or STATE_MOTION
	TweenService:Create(instance, chosen, goals):Play()
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function newFrame(name: string, size: UDim2, colour: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	return frame
end

local function newIcon(name: string, size: number, image: string): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.Image = image
	icon.ImageColor3 = THEME.mark
	return icon
end

local function newLabel(name: string, text: string, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = size
	label.TextColor3 = THEME.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	return label
end

-- Returns the modifiers too, so a style can reshape the row without searching it.
local function row(name: string, height: number): (TextButton, UICorner, UIListLayout, UIPadding)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = false
	button.Text = ""
	button.Size = UDim2.new(1, 0, 0, height)
	button.BackgroundColor3 = THEME.row
	button.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = button

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = button
	return button, corner, layout, padding
end

local function fill(target: GuiObject)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = target
end

-- Hover, press and focus are separate flags, so losing hover never clears
-- focus and a repaint keeps both.
local function watchStates(
	button: GuiButton,
	connections: { RBXScriptConnection },
	paint: (hovered: boolean, pressed: boolean) -> ()
)
	local hovered, pressed = false, false
	local ring = Instance.new("UIStroke")
	ring.Name = "FocusRing"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		hovered = true
		paint(hovered, pressed)
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint(hovered, pressed)
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressed = true
			paint(hovered, pressed)
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		pressed = false
		paint(hovered, pressed)
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
end

local function surface(hovered: boolean, pressed: boolean): Color3
	return if pressed then THEME.row elseif hovered then THEME.rowHover else THEME.row
end

-- The 22 px box every square style shares; the styles differ in how the tick
-- arrives, whether the box fills, and which side of the label it sits on.
local function newBox(order: number, radius: UDim): (Frame, UIStroke)
	local box = newFrame("Box", UDim2.fromOffset(22, 22), THEME.row)
	box.LayoutOrder = order
	round(box, radius)

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.edge
	outline.Thickness = 2
	outline.Parent = box
	return box, outline
end

-- C1: the tick is uncovered left to right by a clipping strip, like a pen stroke.
local function drawSkin(button: TextButton): (boolean) -> ()
	local box, outline = newBox(0, UDim.new(0, 6))
	box.Parent = button

	local reveal = newFrame("Reveal", UDim2.fromOffset(0, 16), THEME.row)
	reveal.AnchorPoint = Vector2.new(0, 0.5)
	reveal.Position = UDim2.new(0, 3, 0.5, 0)
	reveal.BackgroundTransparency = 1
	reveal.ClipsDescendants = true
	reveal.Parent = box

	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.Position = UDim2.fromScale(0, 0)
	tick.Parent = reveal

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(reveal, { Size = UDim2.fromOffset(if on then 16 else 0, 16) }, DRAW_MOTION)
	end
end

-- C2: the box never fills; the outline and the tick take the accent.
local function outlineSkin(button: TextButton): (boolean) -> ()
	local box, outline = newBox(0, UDim.new(0, 6))
	box.BackgroundTransparency = 1
	box.Parent = button

	local tick = newIcon("Tick", 16, ICON.check)
	tick.ImageColor3 = THEME.focus
	tick.Parent = box

	return function(on: boolean)
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end
end

-- C3, C5 and C6 share a filled box with a fading tick; `order` puts the box
-- before (0) or after (2) the label.
local function filledSkin(button: TextButton, order: number): ((boolean) -> (), Frame, ImageLabel)
	local box, outline = newBox(order, UDim.new(0, 6))
	box.Parent = button

	local tick = newIcon("Tick", 16, ICON.check)
	tick.Parent = box

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end,
		box,
		tick
end

-- C5: a to-do line; ticking it strikes the words through and mutes them.
local function strikeSkin(button: TextButton, label: TextLabel, text: string): (boolean) -> ()
	local paintBox = filledSkin(button, 0)
	label.RichText = true
	return function(on: boolean)
		paintBox(on)
		label.Text = if on then `<s>{text}</s>` else text
		label.TextColor3 = if on then THEME.textMuted else THEME.text
	end
end

-- C6: the box pops from 85 % with one small overshoot when ticked.
local function popSkin(button: TextButton): (boolean) -> ()
	local paintBox, box = filledSkin(button, 0)
	local scale = Instance.new("UIScale")
	scale.Parent = box
	return function(on: boolean)
		paintBox(on)
		if on and box:IsDescendantOf(game) and not GuiService.ReducedMotionEnabled then
			scale.Scale = 0.85
			TweenService:Create(scale, POP_MOTION, { Scale = 1 }):Play()
		end
	end
end

-- C7: a card with a title, one short line, and a round tick badge in its corner.
local function cardSkin(button: TextButton, label: TextLabel, description: string): (boolean) -> ()
	button.Size = UDim2.new(1, 0, 0, 64)
	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = button

	local column = newFrame("Labels", UDim2.fromScale(0, 1), THEME.row)
	column.LayoutOrder = 1
	column.BackgroundTransparency = 1
	column.Parent = button
	fill(column)

	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.Padding = UDim.new(0, 4)
	stack.Parent = column

	label.Size = UDim2.new(1, 0, 0, 16)
	label.Parent = column

	local detail = newLabel("Description", description, 12)
	detail.LayoutOrder = 2
	detail.Size = UDim2.new(1, 0, 0, 16)
	detail.FontFace = Font.fromEnum(Enum.Font.Gotham)
	detail.TextColor3 = THEME.textMuted
	detail.Parent = column

	local badge = newFrame("Badge", UDim2.fromOffset(24, 24), THEME.row)
	badge.LayoutOrder = 2
	round(badge, UDim.new(0.5, 0))
	badge.Parent = button

	local ring = Instance.new("UIStroke")
	ring.Color = THEME.edge
	ring.Thickness = 2
	ring.Parent = badge

	local tick = newIcon("Tick", 14, ICON.check)
	tick.Parent = badge

	return function(on: boolean)
		animate(edge, { Color = if on then THEME.accent else THEME.edge })
		animate(badge, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(ring, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end
end

-- C11: no box at all; a tick appears at the right end of a chosen row.
local function rightTickSkin(button: TextButton, label: TextLabel): (boolean) -> ()
	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 2
	tick.ImageColor3 = THEME.focus
	tick.Parent = button

	return function(on: boolean)
		tick.ImageTransparency = if on then 0 else 1
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

-- C12: a filled box plus a count at the end of the row, such as matching items.
local function countSkin(button: TextButton, count: number): (boolean) -> ()
	local paintBox = filledSkin(button, 0)
	local badge = newLabel("Count", tostring(count), 12)
	badge.LayoutOrder = 2
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.Size = UDim2.fromScale(0, 1)
	badge.TextColor3 = THEME.textMuted
	badge.Parent = button

	return function(on: boolean)
		paintBox(on)
		badge.TextColor3 = if on then THEME.text else THEME.textMuted
	end
end

-- C13: an exclude list; the chosen box fills red with a cross, not a tick.
local function crossSkin(button: TextButton, label: TextLabel): (boolean) -> ()
	local box, outline = newBox(0, UDim.new(0, 6))
	box.Parent = button

	local cross = newIcon("Cross", 16, ICON.cross)
	cross.Parent = box

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.danger else THEME.row })
		animate(outline, { Color = if on then THEME.danger else THEME.edge })
		animate(cross, { ImageTransparency = if on then 0 else 1 })
		label.TextColor3 = if on then THEME.textMuted else THEME.text
	end
end

-- C14: a thumb-sized 32 px box for touch-first screens.
local function bigBoxSkin(button: TextButton): (boolean) -> ()
	local box = newFrame("Box", UDim2.fromOffset(32, 32), THEME.row)
	box.LayoutOrder = 0
	round(box, UDim.new(0, 6))
	box.Parent = button

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.edge
	outline.Thickness = 2
	outline.Parent = box

	local tick = newIcon("Tick", 20, ICON.check)
	tick.Parent = box

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
	end
end

local function createCheckbox(
	parent: GuiObject,
	labelText: string,
	style: BoxStyle,
	initial: boolean,
	onChanged: (boolean) -> (),
	details: CheckDetails?
): Checkbox
	local value = initial
	local enabled = true
	local connections: { RBXScriptConnection } = {}

	local button = row(labelText, 44)
	local label = newLabel("Label", labelText, 14)
	label.LayoutOrder = 1
	label.Size = UDim2.fromScale(0, 1)
	label.Parent = button
	fill(label)

	local paintValue: (boolean) -> ()
	if style == "C1" then
		paintValue = drawSkin(button)
	elseif style == "C2" then
		paintValue = outlineSkin(button)
	elseif style == "C3" then
		paintValue = filledSkin(button, 2)
	elseif style == "C5" then
		paintValue = strikeSkin(button, label, labelText)
	elseif style == "C6" then
		paintValue = popSkin(button)
	elseif style == "C7" then
		local description = if details and details.description then details.description else ""
		paintValue = cardSkin(button, label, description)
	end

	if style == "C11" then
		paintValue = rightTickSkin(button, label)
	elseif style == "C12" then
		paintValue = countSkin(button, if details and details.count then details.count else 0)
	elseif style == "C13" then
		paintValue = crossSkin(button, label)
	elseif style == "C14" then
		paintValue = bigBoxSkin(button)
	end

	local function paintRow(hovered: boolean, pressed: boolean)
		animate(button, { BackgroundColor3 = surface(hovered, pressed) })
		if style ~= "C5" and style ~= "C13" then
			label.TextColor3 = if enabled then THEME.text else THEME.textMuted
		end
	end
	watchStates(button, connections, paintRow)

	local function set(next: boolean)
		if not enabled or next == value then
			return
		end
		value = next
		paintValue(value)
		onChanged(value)
	end
	table.insert(connections, button.Activated:Connect(function()
		set(not value)
	end))

	paintRow(false, false)
	paintValue(value)
	button.Parent = parent

	return {
		row = button,
		set = set,
		get = function()
			return value
		end,
		setEnabled = function(next: boolean)
			enabled = next
			button.Active = next
			button.Interactable = next
			paintRow(false, false)
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			button:Destroy()
		end,
	}
end

type Item = {
	button: TextButton,
	paint: (on: boolean) -> (),
}

-- C8: a ring with a dot for the one chosen option.
local function radioItem(button: TextButton): (boolean) -> ()
	local socket = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	socket.LayoutOrder = 0
	round(socket, UDim.new(0.5, 0))
	socket.Parent = button

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.edge
	outline.Thickness = 2
	outline.Parent = socket

	local dot = newFrame("Dot", UDim2.fromOffset(10, 10), THEME.accent)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	round(dot, UDim.new(0.5, 0))
	dot.Parent = socket

	return function(on: boolean)
		animate(outline, { Color = if on then THEME.accent else THEME.edge })
		animate(dot, { BackgroundTransparency = if on then 0 else 1 })
	end
end

-- C9: a pill that fills and shows a tick; the label keeps its words.
local function chipItem(button: TextButton, corner: UICorner): (boolean) -> ()
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 44)
	corner.CornerRadius = UDim.new(0.5, 0)

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = button

	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 0
	tick.ImageColor3 = THEME.focus
	tick.Parent = button

	return function(on: boolean)
		tick.Visible = on
		edge.Color = if on then THEME.accent else THEME.edge
		animate(button, { BackgroundColor3 = if on then THEME.accentDim else THEME.row })
	end
end

-- C10: a square tile with an icon over its name, ticked in the corner.
local function tileItem(
	button: TextButton,
	layout: UIListLayout,
	label: TextLabel,
	image: string
): (boolean) -> ()
	button.Size = UDim2.fromOffset(88, 88)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2.new(1, 0, 0, 16)
	label.TextSize = 12

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = button

	local glyph = newIcon("Glyph", 24, image)
	glyph.AnchorPoint = Vector2.zero
	glyph.LayoutOrder = 0
	glyph.ImageColor3 = THEME.textMuted
	glyph.Parent = button

	local badge = newFrame("Badge", UDim2.fromOffset(20, 20), THEME.accent)
	badge.AnchorPoint = Vector2.new(0, 1)
	badge.Position = UDim2.new(1, -4, 0, 4)
	round(badge, UDim.new(0.5, 0))
	badge.Parent = glyph

	local tick = newIcon("Tick", 12, ICON.check)
	tick.Parent = badge

	return function(on: boolean)
		badge.Visible = on
		edge.Color = if on then THEME.accent else THEME.edge
		animate(glyph, { ImageColor3 = if on then THEME.focus else THEME.textMuted })
		animate(button, { BackgroundColor3 = if on then THEME.accentDim else THEME.row })
	end
end

-- C16 and C19 sit in one rounded track; the CanvasGroup rounds the segments,
-- because a UICorner on the track would not round its children. The segments
-- live in their own row so C19's marker can sit behind them outside the layout.
local function newTrack(frame: Frame): (CanvasGroup, Frame)
	local track = Instance.new("CanvasGroup")
	track.Name = "Track"
	track.AutomaticSize = Enum.AutomaticSize.X
	track.Size = UDim2.fromOffset(0, 36)
	track.BackgroundColor3 = THEME.edge
	track.BorderSizePixel = 0
	round(track, UDim.new(0, 6))
	track.Parent = frame

	local segments = newFrame("Segments", UDim2.fromOffset(0, 36), THEME.row)
	segments.AutomaticSize = Enum.AutomaticSize.X
	segments.BackgroundTransparency = 1
	segments.ZIndex = 2
	segments.Parent = track

	local line = Instance.new("UIListLayout")
	line.FillDirection = Enum.FillDirection.Horizontal
	line.SortOrder = Enum.SortOrder.LayoutOrder
	line.Parent = segments
	return track, segments
end

-- C16: joined buttons for picking several; each chosen one fills and ticks.
local function segmentItem(button: TextButton, corner: UICorner): (boolean) -> ()
	corner:Destroy()
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 36)
	button.BackgroundColor3 = THEME.row

	local tick = newIcon("Tick", 16, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 0
	tick.ImageColor3 = THEME.focus
	tick.Parent = button

	return function(on: boolean)
		tick.Visible = on
		animate(button, { BackgroundColor3 = if on then THEME.accentDim else THEME.row })
	end
end

-- C17: star buttons; the rating is how many are lit, set by the parent group.
local function starItem(button: TextButton, label: TextLabel, corner: UICorner): (boolean) -> ()
	corner:Destroy()
	button.Size = UDim2.fromOffset(44, 44)
	button.BackgroundTransparency = 1
	label.Visible = false

	local star = newIcon("Star", 24, ICON.star)
	star.AnchorPoint = Vector2.zero
	star.LayoutOrder = 0
	star.ImageColor3 = THEME.edge
	star.Parent = button

	return function(lit: boolean)
		animate(star, { ImageColor3 = if lit then THEME.swatchGold else THEME.edge })
	end
end

-- C18: round colour dots; the chosen dot gets a ring and a tick.
local function swatchItem(
	button: TextButton,
	label: TextLabel,
	corner: UICorner,
	colour: Color3
): (boolean) -> ()
	corner.CornerRadius = UDim.new(0.5, 0)
	button.Size = UDim2.fromOffset(44, 44)
	button.BackgroundColor3 = colour
	label.Visible = false

	local ring = Instance.new("UIStroke")
	ring.Name = "Ring"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.mark
	ring.Thickness = 3
	ring.Parent = button

	local tick = newIcon("Tick", 20, ICON.check)
	tick.AnchorPoint = Vector2.zero
	tick.LayoutOrder = 0
	tick.Parent = button

	return function(on: boolean)
		ring.Enabled = on
		tick.Visible = on
	end
end

-- C19: equal-width segments for one choice, such as S, M and L; the marker
-- behind the chosen one is placed by the parent group.
local function sizeItem(button: TextButton, label: TextLabel, corner: UICorner): (boolean) -> ()
	corner:Destroy()
	button.Size = UDim2.fromOffset(64, 36)
	button.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Center

	return function(on: boolean)
		label.TextColor3 = if on then THEME.mark else THEME.textMuted
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

-- C4, C8, C9 and C10 own several options at once. C4 adds a "Select all"
-- header whose box shows none, some (a dash) or all (a tick).
local function createCheckGroup(
	parent: GuiObject,
	names: { string },
	style: GroupStyle,
	initial: { string },
	onChanged: (selected: { string }) -> (),
	details: CheckDetails?
): CheckGroup
	local connections: { RBXScriptConnection } = {}
	local chosen: { [string]: boolean } = {}
	local items: { [string]: Item } = {}
	for _, name in initial do
		chosen[name] = true
	end

	local frame = newFrame("Choices", UDim2.fromScale(1, 0), THEME.row)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = frame
	if style == "C9" or style == "C10" or style == "C18" then
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Wraps = true
	elseif style == "C17" then
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
	end

	-- One choice at a time; the rest pick several.
	local single = style == "C8"
		or style == "C17"
		or style == "C18"
		or style == "C19"
		or style == "C20"
	local holder: GuiObject = frame
	local marker: Frame? = nil
	if style == "C16" or style == "C19" then
		local track, segments = newTrack(frame)
		holder = segments
		if style == "C19" then
			local slide = newFrame("Marker", UDim2.fromOffset(64, 36), THEME.accent)
			slide.ZIndex = 1
			slide.Parent = track
			marker = slide
		end
	end

	local function selected(): { string }
		local list = {}
		for _, name in names do
			if chosen[name] then
				table.insert(list, name)
			end
		end
		return list
	end

	local paintHeader: (() -> ())? = nil

	-- C17 lights every star up to the chosen one; C19 slides its marker there.
	local function repaint()
		local rating = 0
		for index, name in names do
			if chosen[name] then
				rating = index
			end
		end
		for index, name in names do
			local item = items[name]
			if style == "C17" then
				item.paint(index <= rating)
			else
				item.paint(chosen[name] == true)
			end
		end
		if marker then
			marker.Visible = rating > 0
			animate(marker, { Position = UDim2.fromOffset((math.max(rating, 1) - 1) * 64, 0) })
		end
		if paintHeader then
			paintHeader()
		end
	end

	local function set(name: string, on: boolean)
		if not items[name] or (chosen[name] == true) == on then
			return
		end
		if single then
			if not on then
				return
			end
			table.clear(chosen)
		end
		chosen[name] = if on then true else nil
		repaint()
		onChanged(selected())
	end

	if style == "C4" then
		local header = row("SelectAll", 44)
		header.LayoutOrder = 0
		header.Parent = frame
		local paintBox, _, mark = filledSkin(header, 0)

		local title = newLabel("Label", "Select all", 14)
		title.LayoutOrder = 1
		title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		title.Size = UDim2.fromScale(0, 1)
		title.Parent = header
		fill(title)

		paintHeader = function()
			local count = #selected()
			paintBox(count > 0)
			mark.Image = if count == #names then ICON.check else ICON.dash
		end
		watchStates(header, connections, function(hovered, pressed)
			animate(header, { BackgroundColor3 = surface(hovered, pressed) })
		end)
		table.insert(connections, header.Activated:Connect(function()
			local everything = #selected() == #names
			for _, name in names do
				chosen[name] = if everything then nil else true
			end
			repaint()
			onChanged(selected())
		end))
	end

	-- C15: a heading that counts what is done, over a bar that fills with it.
	if style == "C15" then
		local header = newFrame("Progress", UDim2.new(1, 0, 0, 32), THEME.row)
		header.LayoutOrder = 0
		header.BackgroundTransparency = 1
		header.Parent = frame

		local summary = newLabel("Summary", "", 12)
		summary.Size = UDim2.new(1, 0, 0, 16)
		summary.TextColor3 = THEME.textMuted
		summary.Parent = header

		local bar = newFrame("Bar", UDim2.new(1, 0, 0, 4), THEME.edge)
		bar.Position = UDim2.fromOffset(0, 24)
		round(bar, UDim.new(0.5, 0))
		bar.Parent = header

		local done = newFrame("Fill", UDim2.fromScale(0, 1), THEME.accent)
		round(done, UDim.new(0.5, 0))
		done.Parent = bar

		paintHeader = function()
			local count = #selected()
			summary.Text = `{count} of {#names} done`
			animate(done, { Size = UDim2.fromScale(if #names > 0 then count / #names else 0, 1) })
		end
	end

	for index, name in names do
		local button, corner, rowLayout, padding = row(name, 44)
		button.LayoutOrder = index
		local label = newLabel("Label", name, 14)
		label.LayoutOrder = 1
		label.Size = UDim2.fromScale(0, 1)
		label.Parent = button

		local paint: (boolean) -> ()
		if style == "C4" then
			padding.PaddingLeft = UDim.new(0, 32)
			fill(label)
			paint = filledSkin(button, 0)
		elseif style == "C8" then
			fill(label)
			paint = radioItem(button)
		elseif style == "C9" then
			label.AutomaticSize = Enum.AutomaticSize.X
			paint = chipItem(button, corner)
		elseif style == "C10" then
			local icons = if details and details.icons then details.icons else {}
			paint = tileItem(button, rowLayout, label, icons[name] or ICON.tile)
		elseif style == "C15" then
			fill(label)
			paint = strikeSkin(button, label, name)
		elseif style == "C16" then
			label.AutomaticSize = Enum.AutomaticSize.X
			paint = segmentItem(button, corner)
		end
		if style == "C17" then
			paint = starItem(button, label, corner)
		elseif style == "C18" then
			local colours = details and details.colours or DEFAULT_SWATCHES
			paint = swatchItem(button, label, corner, colours[name] or THEME.edge)
		elseif style == "C19" then
			fill(label)
			paint = sizeItem(button, label, corner)
		elseif style == "C20" then
			local descriptions = details and details.descriptions or {}
			paint = cardSkin(button, label, descriptions[name] or "")
		end

		items[name] = { button = button, paint = paint }
		-- Chips, tiles and segments fill when chosen, so hover must not paint over
		-- that; stars, swatches and sizes never take a row surface at all.
		local filledWhenChosen = style == "C9" or style == "C10" or style == "C16"
		local bare = style == "C17" or style == "C18" or style == "C19"
		watchStates(button, connections, function(hovered, pressed)
			if not bare and not (filledWhenChosen and chosen[name]) then
				animate(button, { BackgroundColor3 = surface(hovered, pressed) })
			end
		end)
		table.insert(connections, button.Activated:Connect(function()
			set(name, if single then true else not chosen[name])
		end))
		button.Parent = holder
	end

	repaint()
	frame.Parent = parent

	return {
		frame = frame,
		set = set,
		selected = selected,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			frame:Destroy()
		end,
	}
end

return {
	createCheckbox = createCheckbox,
	createCheckGroup = createCheckGroup,
}
