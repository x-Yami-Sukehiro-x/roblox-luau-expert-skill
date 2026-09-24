--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local THEME = {
	row = Color3.fromRGB(31, 34, 41),
	rowHover = Color3.fromRGB(44, 48, 57),
	track = Color3.fromRGB(63, 68, 79),
	knob = Color3.fromRGB(243, 245, 248),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(118, 125, 139),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
}

local ICON = {
	check = "rbxassetid://86817768619372",
	cross = "rbxassetid://116396312853810",
	eye = "rbxassetid://127234874352422",
	eyeOff = "rbxassetid://85207295981701",
}

local STATE_MOTION = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NO_MOTION = TweenInfo.new(0)

export type ToggleStyle = "T1" | "T2" | "T3" | "T4" | "T5" | "T6" | "T7" | "T8" | "T9" | "T10"

export type Toggle = {
	row: TextButton,
	set: (value: boolean) -> (),
	get: () -> boolean,
	setEnabled: (enabled: boolean) -> (),
	destroy: () -> (),
}

-- Before the row is parented there is nothing on screen to animate, so the
-- first paint assigns directly instead of sliding in from the default values.
local function animate(instance: Instance, goals: { [string]: any })
	if not instance:IsDescendantOf(game) then
		for property, goal in goals do
			(instance :: any)[property] = goal
		end
		return
	end
	local timing = if GuiService.ReducedMotionEnabled then NO_MOTION else STATE_MOTION
	TweenService:Create(instance, timing, goals):Play()
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

-- T1 and T2 differ only in corner radius; the knob position carries the state,
-- so the track colour is never the only signal.
local function switchSkin(row: TextButton, radius: UDim, knobRadius: UDim): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, radius)
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, knobRadius)
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

local function tickSkin(row: TextButton): (boolean) -> ()
	local box = newFrame("Box", UDim2.fromOffset(22, 22), THEME.row)
	box.LayoutOrder = 0
	round(box, UDim.new(0, 6))
	box.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = box

	local tick = Instance.new("ImageLabel")
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(16, 16)
	tick.BackgroundTransparency = 1
	tick.Image = ICON.check
	tick.ImageColor3 = THEME.knob
	tick.Parent = box

	local grow = Instance.new("UIScale")
	grow.Parent = tick

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
		animate(grow, { Scale = if on then 1 else 0.8 })
	end
end

local function lightSkin(row: TextButton, label: TextLabel): (boolean) -> ()
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.LayoutOrder = 2
	status.AutomaticSize = Enum.AutomaticSize.X
	status.Size = UDim2.fromScale(0, 1)
	status.BackgroundTransparency = 1
	status.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	status.TextSize = 12
	status.Text = "OFF"
	status.Parent = row

	return function(on: boolean)
		status.Text = if on then "ON" else "OFF"
		animate(status, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

local function iconSkin(row: TextButton): (boolean) -> ()
	local badge = newFrame("Badge", UDim2.fromOffset(32, 32), THEME.track)
	badge.LayoutOrder = 0
	round(badge, UDim.new(0, 6))
	badge.Parent = row

	local glyph = Instance.new("ImageLabel")
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromOffset(16, 16)
	glyph.BackgroundTransparency = 1
	glyph.Parent = badge

	return function(on: boolean)
		glyph.Image = if on then ICON.eye else ICON.eyeOff
		animate(glyph, { ImageColor3 = if on then THEME.knob else THEME.textMuted })
		animate(badge, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T7: the knob carries the answer as a tick or a cross.
local function knobIconSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	local mark = Instance.new("ImageLabel")
	mark.Name = "Mark"
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromOffset(12, 12)
	mark.BackgroundTransparency = 1
	mark.Parent = knob

	return function(on: boolean)
		mark.Image = if on then ICON.check else ICON.cross
		mark.ImageColor3 = if on then THEME.accent else THEME.textMuted
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T8: the word sits inside the track, on the side the knob has left.
local function wordSwitchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local word = Instance.new("TextLabel")
	word.Name = "Word"
	word.AnchorPoint = Vector2.new(0, 0.5)
	word.Size = UDim2.fromOffset(28, 24)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.TextColor3 = THEME.knob
	word.Text = "OFF"
	word.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		word.Position = UDim2.new(0, if on then 4 else 24, 0.5, 0)
		animate(knob, { Position = UDim2.new(0, if on then 35 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T9: a small light plus the word, so the state never rests on the colour.
local function statusDotSkin(row: TextButton): (boolean) -> ()
	local dot = newFrame("Dot", UDim2.fromOffset(8, 8), THEME.track)
	dot.LayoutOrder = 2
	round(dot, UDim.new(0.5, 0))
	dot.Parent = row

	local word = Instance.new("TextLabel")
	word.Name = "Status"
	word.LayoutOrder = 3
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.Text = "OFF"
	word.Parent = row

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		animate(word, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		animate(dot, { BackgroundColor3 = if on then THEME.focus else THEME.track })
	end
end

-- T10: T3's tick in a circle, for lists where square boxes feel heavy.
local function roundTickSkin(row: TextButton): (boolean) -> ()
	local ring = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	ring.LayoutOrder = 0
	round(ring, UDim.new(0.5, 0))
	ring.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = ring

	local tick = Instance.new("ImageLabel")
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(14, 14)
	tick.BackgroundTransparency = 1
	tick.Image = ICON.check
	tick.ImageColor3 = THEME.knob
	tick.Parent = ring

	local grow = Instance.new("UIScale")
	grow.Parent = tick

	return function(on: boolean)
		animate(ring, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
		animate(grow, { Scale = if on then 1 else 0.6 })
	end
end

-- T4 shows both words; each half is its own button so pressing the half that is
-- already selected leaves the value alone instead of flipping it.
local function segmentSkin(
	row: TextButton,
	choose: (boolean) -> (),
	watch: (GuiButton) -> (),
	connections: { RBXScriptConnection }
): (boolean) -> ()
	local group = newFrame("Segments", UDim2.fromOffset(112, 36), THEME.track)
	group.LayoutOrder = 2
	round(group, UDim.new(0, 6))
	group.Parent = row

	local indicator = newFrame("Indicator", UDim2.new(0.5, -4, 1, -8), THEME.accent)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.ZIndex = 1
	round(indicator, UDim.new(0, 4))
	indicator.Parent = group

	local halves: { TextButton } = {}
	for index, word in { "Off", "On" } do
		local half = Instance.new("TextButton")
		half.Name = word
		half.AutoButtonColor = false
		half.BackgroundTransparency = 1
		half.Position = UDim2.fromScale((index - 1) * 0.5, 0)
		half.Size = UDim2.fromScale(0.5, 1)
		half.ZIndex = 2
		half.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		half.TextSize = 14
		half.Text = word
		half.Parent = group
		watch(half)
		table.insert(connections, half.Activated:Connect(function()
			choose(word == "On")
		end))
		halves[index] = half
	end

	row.Selectable = false
	return function(on: boolean)
		animate(indicator, { Position = UDim2.new(if on then 0.5 else 0, 4, 0.5, 0) })
		halves[1].TextColor3 = if on then THEME.textMuted else THEME.text
		halves[2].TextColor3 = if on then THEME.text else THEME.textMuted
	end
end

local function createToggle(
	parent: GuiObject,
	labelText: string,
	style: ToggleStyle,
	initial: boolean,
	onChanged: (boolean) -> ()
): Toggle
	local value = initial
	local enabled = true
	local hovered, pressed, focused = false, false, false
	local connections: { RBXScriptConnection } = {}

	local row = Instance.new("TextButton")
	row.Name = labelText
	row.AutoButtonColor = false
	row.Text = ""
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = THEME.row
	row.BorderSizePixel = 0
	round(row, UDim.new(0, 6))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = row

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.LayoutOrder = 1
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = labelText
	label.Parent = row

	local fill = Instance.new("UIFlexItem")
	fill.FlexMode = Enum.UIFlexMode.Fill
	fill.Parent = label

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Enabled = style == "T5"
	edge.Parent = row

	local focusRing = Instance.new("UIStroke")
	focusRing.Name = "FocusRing"
	focusRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	focusRing.Color = THEME.focus
	focusRing.Thickness = 2
	focusRing.Enabled = false
	focusRing.Parent = row

	-- T5 is the only style whose whole row is the "on" signal, so its lit
	-- colour outranks hover; the other styles leave the row neutral.
	local function paintRow()
		label.TextColor3 = if enabled then THEME.text else THEME.textMuted
		local lit = style == "T5" and value
		local surface = if lit then THEME.accentDim
			elseif pressed then THEME.row
			elseif hovered then THEME.rowHover
			else THEME.row
		animate(row, { BackgroundColor3 = surface })
		edge.Color = if not lit then THEME.track elseif hovered then THEME.focus else THEME.accent
	end

	-- One watcher per focusable button: hover, press and focus are separate
	-- flags, so losing hover never clears focus and a refresh keeps both.
	local function watch(button: GuiButton)
		table.insert(connections, button.MouseEnter:Connect(function()
			hovered = true
			paintRow()
		end))
		table.insert(connections, button.MouseLeave:Connect(function()
			hovered, pressed = false, false
			paintRow()
		end))
		table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				pressed = true
				paintRow()
			end
		end))
		table.insert(connections, button.InputEnded:Connect(function()
			pressed = false
			paintRow()
		end))
		table.insert(connections, button.SelectionGained:Connect(function()
			focused = true
			focusRing.Enabled = focused
		end))
		table.insert(connections, button.SelectionLost:Connect(function()
			focused = false
			focusRing.Enabled = focused
		end))
	end

	local paintValue: (boolean) -> ()
	local function set(next: boolean)
		if not enabled or next == value then
			return
		end
		value = next
		paintValue(value)
		paintRow()
		onChanged(value)
	end

	if style == "T1" then
		paintValue = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	elseif style == "T2" then
		paintValue = switchSkin(row, UDim.new(0, 6), UDim.new(0, 4))
	elseif style == "T3" then
		paintValue = tickSkin(row)
	elseif style == "T4" then
		paintValue = segmentSkin(row, set, watch, connections)
	elseif style == "T5" then
		paintValue = lightSkin(row, label)
	elseif style == "T6" then
		paintValue = iconSkin(row)
	elseif style == "T7" then
		paintValue = knobIconSkin(row)
	elseif style == "T8" then
		paintValue = wordSwitchSkin(row)
	elseif style == "T9" then
		paintValue = statusDotSkin(row)
	else
		paintValue = roundTickSkin(row)
	end

	if style ~= "T4" then
		watch(row)
		table.insert(connections, row.Activated:Connect(function()
			set(not value)
		end))
	end

	paintRow()
	paintValue(value)
	row.Parent = parent

	return {
		row = row,
		set = set,
		get = function()
			return value
		end,
		setEnabled = function(next: boolean)
			enabled = next
			row.Active = next
			row.Interactable = next
			paintRow()
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			row:Destroy()
		end,
	}
end

return createToggle
