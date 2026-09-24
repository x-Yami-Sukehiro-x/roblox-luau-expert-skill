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
	keyBase = Color3.fromRGB(19, 21, 26),
}

local ICON = {
	check = "rbxassetid://86817768619372",
	cross = "rbxassetid://116396312853810",
	eye = "rbxassetid://127234874352422",
	eyeOff = "rbxassetid://85207295981701",
	power = "rbxassetid://89331085993646",
	feature = "rbxassetid://109718589733073",
}

local STATE_MOTION = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NO_MOTION = TweenInfo.new(0)
-- Plays forward then back, so the knob is wide only mid-travel.
local STRETCH = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

type FirstTen = "T1" | "T2" | "T3" | "T4" | "T5" | "T6" | "T7" | "T8" | "T9" | "T10"
type SecondTen = "T11" | "T12" | "T13" | "T14" | "T15" | "T16" | "T17" | "T18" | "T19" | "T20"
type ThirdTen = "T21" | "T22" | "T23" | "T24" | "T25" | "T26" | "T27" | "T28" | "T29" | "T30"
export type ToggleStyle = FirstTen | SecondTen | ThirdTen

-- T19 reads `description`, T20 reads `icon`, T29 reads `key`; the other styles
-- ignore all three.
export type ToggleDetails = {
	description: string?,
	icon: string?,
	key: string?,
}

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

local function round(target: GuiObject, radius: UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
	return corner
end

local function newIcon(name: string, size: number, image: string): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(size, size)
	icon.BackgroundTransparency = 1
	icon.Image = image
	return icon
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
local function switchSkin(
	row: TextButton,
	radius: UDim,
	knobRadius: UDim,
	order: number?
): ((boolean) -> (), Frame)
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = order or 2
	round(track, radius)
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, knobRadius)
	knob.Parent = track

	local function paint(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
	return paint, track
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

-- T11: a thin rail with a knob that overhangs it, as on Android.
local function railSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(36, 14), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(20, 20), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, {
			Position = UDim2.new(0, if on then 19 else -3, 0.5, 0),
			BackgroundColor3 = if on then THEME.accent else THEME.knob,
		})
		animate(track, { BackgroundColor3 = if on then THEME.accentDim else THEME.track })
	end
end

-- T12: a hollow track; the outline and the knob take the accent together.
local function outlineSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.row)
	track.LayoutOrder = 2
	track.BackgroundTransparency = 1
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(14, 14), THEME.textMuted)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, {
			Position = UDim2.new(0, if on then 25 else 5, 0.5, 0),
			BackgroundColor3 = if on then THEME.accent else THEME.textMuted,
		})
		animate(outline, { Color = if on then THEME.accent else THEME.track })
	end
end

-- T13: T1 at thumb size for touch-first screens.
local function bigSwitchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 32), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(26, 26), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 27 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T14: the whole row is a pill chip; a tick appears before the label when on.
local function chipSkin(row: TextButton, rowCorner: UICorner): (boolean) -> ()
	rowCorner.CornerRadius = UDim.new(0.5, 0)
	local tick = newIcon("Tick", 16, ICON.check)
	tick.LayoutOrder = 0
	tick.ImageColor3 = THEME.focus
	tick.Parent = row

	return function(on: boolean)
		tick.Visible = on
	end
end

-- T15: a round power button, with the state spelled out beside it.
local function powerSkin(row: TextButton): (boolean) -> ()
	local word = Instance.new("TextLabel")
	word.Name = "Status"
	word.LayoutOrder = 2
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.Text = "OFF"
	word.Parent = row

	local button = newFrame("Power", UDim2.fromOffset(32, 32), THEME.track)
	button.LayoutOrder = 3
	round(button, UDim.new(0.5, 0))
	button.Parent = row

	local glyph = newIcon("Glyph", 16, ICON.power)
	glyph.Parent = button

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		animate(word, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		animate(button, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		animate(glyph, { ImageColor3 = if on then THEME.knob else THEME.textMuted })
	end
end

-- T16: T1 whose knob stretches while it travels and is round again on arrival.
local function stretchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		if knob:IsDescendantOf(game) and not GuiService.ReducedMotionEnabled then
			TweenService:Create(knob, STRETCH, { Size = UDim2.fromOffset(26, 18) }):Play()
		end
	end
end

-- T17: a tick and a cross live in the track; the knob covers the one not chosen.
local function trackIconSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 28), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local yes = newIcon("Yes", 14, ICON.check)
	yes.Position = UDim2.new(0, 14, 0.5, 0)
	yes.Parent = track

	local no = newIcon("No", 14, ICON.cross)
	no.Position = UDim2.new(1, -14, 0.5, 0)
	no.ImageColor3 = THEME.textMuted
	no.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(22, 22), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.ZIndex = 2
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 31 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		yes.ImageColor3 = if on then THEME.knob else THEME.textMuted
	end
end

-- T18: a key that sinks onto its base and stays down while on.
local function keySkin(row: TextButton): (boolean) -> ()
	local key = newFrame("Key", UDim2.fromOffset(52, 36), THEME.row)
	key.LayoutOrder = 2
	key.BackgroundTransparency = 1
	key.Parent = row

	local base = newFrame("Base", UDim2.new(1, 0, 0, 32), THEME.keyBase)
	base.Position = UDim2.fromOffset(0, 4)
	base.ZIndex = 1
	round(base, UDim.new(0, 6))
	base.Parent = key

	local cap = Instance.new("TextLabel")
	cap.Name = "Cap"
	cap.Size = UDim2.new(1, 0, 0, 32)
	cap.BackgroundColor3 = THEME.rowHover
	cap.BorderSizePixel = 0
	cap.ZIndex = 2
	cap.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	cap.TextSize = 12
	cap.Text = "OFF"
	round(cap, UDim.new(0, 6))
	cap.Parent = key

	return function(on: boolean)
		cap.Text = if on then "ON" else "OFF"
		animate(cap, {
			Position = UDim2.fromOffset(0, if on then 3 else 0),
			BackgroundColor3 = if on then THEME.accent else THEME.rowHover,
			TextColor3 = if on then THEME.knob else THEME.textMuted,
		})
	end
end

-- T19: the label gains one short line underneath; the row grows to fit it.
local function describedSkin(
	row: TextButton,
	label: TextLabel,
	description: string
): (boolean) -> ()
	row.Size = UDim2.new(1, 0, 0, 56)

	local column = newFrame("Labels", UDim2.fromScale(0, 1), THEME.row)
	column.LayoutOrder = 1
	column.BackgroundTransparency = 1
	column.Parent = row

	local grow = Instance.new("UIFlexItem")
	grow.FlexMode = Enum.UIFlexMode.Fill
	grow.Parent = column

	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.Padding = UDim.new(0, 4)
	stack.Parent = column

	label.Size = UDim2.new(1, 0, 0, 16)
	label.Parent = column

	local detail = Instance.new("TextLabel")
	detail.Name = "Description"
	detail.LayoutOrder = 2
	detail.Size = UDim2.new(1, 0, 0, 16)
	detail.BackgroundTransparency = 1
	detail.FontFace = Font.fromEnum(Enum.Font.Gotham)
	detail.TextSize = 12
	detail.TextColor3 = THEME.textMuted
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextTruncate = Enum.TextTruncate.AtEnd
	detail.Text = description
	detail.Parent = column

	return (switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0)))
end

-- T20: a feature icon leads the row and takes the accent while the switch is on.
local function iconRowSkin(row: TextButton, image: string): (boolean) -> ()
	local lead = newIcon("Lead", 20, image)
	lead.AnchorPoint = Vector2.zero
	lead.Position = UDim2.fromScale(0, 0)
	lead.LayoutOrder = 0
	lead.Parent = row

	local paintSwitch = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	return function(on: boolean)
		animate(lead, { ImageColor3 = if on then THEME.accent else THEME.textMuted })
		paintSwitch(on)
	end
end

local function newWord(name: string, order: number, text: string): TextLabel
	local word = Instance.new("TextLabel")
	word.Name = name
	word.LayoutOrder = order
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.TextColor3 = THEME.textMuted
	word.Text = text
	return word
end

-- T21: the accent fills the track from the left as the knob travels.
local function fillSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local fill = newFrame("Fill", UDim2.fromScale(0, 1), THEME.accent)
	round(fill, UDim.new(0.5, 0))
	fill.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.ZIndex = 2
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(fill, { Size = UDim2.fromScale(if on then 1 else 0, 1) })
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
	end
end

-- T22: both words stay visible either side of the switch; the chosen one is lit.
local function labelledEndsSkin(row: TextButton): (boolean) -> ()
	local off = newWord("OffWord", 2, "Off")
	off.Parent = row
	local paintSwitch = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0), 3)
	local on = newWord("OnWord", 4, "On")
	on.Parent = row

	return function(value: boolean)
		paintSwitch(value)
		animate(off, { TextColor3 = if value then THEME.textMuted else THEME.text })
		animate(on, { TextColor3 = if value then THEME.focus else THEME.textMuted })
	end
end

-- T23: T1 whose track takes a soft accent glow while on.
local function glowSkin(row: TextButton): (boolean) -> ()
	local paintSwitch, track = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.Color = THEME.focus
	glow.Thickness = 2
	glow.Transparency = 1
	glow.Parent = track

	return function(on: boolean)
		paintSwitch(on)
		animate(glow, { Transparency = if on then 0.4 else 1 })
	end
end

-- T24: an upright lever; the knob rises for on, like a wall switch.
local function leverSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(24, 40), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0.5, 0)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0.5, 0, 0, if on then 3 else 19) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T25: an empty ring whose centre dot grows in, as a single-option radio.
local function dotRingSkin(row: TextButton): (boolean) -> ()
	local ring = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	ring.LayoutOrder = 0
	round(ring, UDim.new(0.5, 0))
	ring.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = ring

	local dot = newFrame("Dot", UDim2.fromOffset(10, 10), THEME.accent)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	round(dot, UDim.new(0.5, 0))
	dot.Parent = ring

	local grow = Instance.new("UIScale")
	grow.Parent = dot

	return function(on: boolean)
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(grow, { Scale = if on then 1 else 0 })
	end
end

-- T26: a stripe on the row's left edge lights, and the word says it.
local function stripeSkin(row: TextButton): (boolean) -> ()
	local stripe = newFrame("Stripe", UDim2.fromOffset(4, 24), THEME.track)
	stripe.LayoutOrder = 0
	round(stripe, UDim.new(0.5, 0))
	stripe.Parent = row

	local status = newWord("Status", 2, "OFF")
	status.Parent = row

	return function(on: boolean)
		status.Text = if on then "ON" else "OFF"
		animate(stripe, { BackgroundColor3 = if on then THEME.accent else THEME.track })
		animate(status, { TextColor3 = if on then THEME.focus else THEME.textMuted })
	end
end

-- T27: a rocker marked O and I; the cap sits under the side that is down.
local function rockerSkin(row: TextButton): (boolean) -> ()
	local rocker = newFrame("Rocker", UDim2.fromOffset(64, 32), THEME.keyBase)
	rocker.LayoutOrder = 2
	round(rocker, UDim.new(0, 6))
	rocker.Parent = row

	local cap = newFrame("Cap", UDim2.new(0.5, -4, 1, -8), THEME.track)
	cap.AnchorPoint = Vector2.new(0, 0.5)
	cap.ZIndex = 1
	round(cap, UDim.new(0, 4))
	cap.Parent = rocker

	local marks: { TextLabel } = {}
	for index, glyph in { "O", "I" } do
		local mark = Instance.new("TextLabel")
		mark.Name = if glyph == "O" then "Off" else "On"
		mark.Position = UDim2.fromScale((index - 1) * 0.5, 0)
		mark.Size = UDim2.fromScale(0.5, 1)
		mark.BackgroundTransparency = 1
		mark.ZIndex = 2
		mark.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		mark.TextSize = 14
		mark.Text = glyph
		mark.Parent = rocker
		marks[index] = mark
	end

	return function(on: boolean)
		animate(cap, {
			Position = UDim2.new(if on then 0.5 else 0, 4, 0.5, 0),
			BackgroundColor3 = if on then THEME.accent else THEME.track,
		})
		marks[1].TextColor3 = if on then THEME.textMuted else THEME.text
		marks[2].TextColor3 = if on then THEME.knob else THEME.textMuted
	end
end

-- T28: a compact pill that reads ON or OFF, for dense feature lists.
local function pillSkin(row: TextButton): (boolean) -> ()
	local pill = Instance.new("TextLabel")
	pill.Name = "Pill"
	pill.LayoutOrder = 2
	pill.Size = UDim2.fromOffset(52, 24)
	pill.BackgroundColor3 = THEME.track
	pill.BorderSizePixel = 0
	pill.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	pill.TextSize = 12
	pill.Text = "OFF"
	round(pill, UDim.new(0.5, 0))
	pill.Parent = row

	return function(on: boolean)
		pill.Text = if on then "ON" else "OFF"
		animate(pill, {
			BackgroundColor3 = if on then THEME.accent else THEME.track,
			TextColor3 = if on then THEME.knob else THEME.textMuted,
		})
	end
end

-- T29: T1 with the feature's hotkey shown in a chip before the switch.
local function keyChipSkin(row: TextButton, keyName: string): (boolean) -> ()
	local chip = newWord("Key", 2, keyName)
	chip.BackgroundColor3 = THEME.keyBase
	chip.BackgroundTransparency = 0
	chip.Size = UDim2.fromOffset(0, 24)
	round(chip, UDim.new(0, 4))
	chip.Parent = row

	local inset = Instance.new("UIPadding")
	inset.PaddingLeft = UDim.new(0, 8)
	inset.PaddingRight = UDim.new(0, 8)
	inset.Parent = chip

	return (switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0), 3))
end

-- T30: a small switch for long, dense lists; the row stays 44 tall to tap.
local function miniSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(32, 18), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(14, 14), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 16 else 2, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
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
	onChanged: (boolean) -> (),
	details: ToggleDetails?
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
	local rowCorner = round(row, UDim.new(0, 6))

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
	edge.Enabled = style == "T5" or style == "T14"
	edge.Parent = row

	local focusRing = Instance.new("UIStroke")
	focusRing.Name = "FocusRing"
	focusRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	focusRing.Color = THEME.focus
	focusRing.Thickness = 2
	focusRing.Enabled = false
	focusRing.Parent = row

	-- T5 and T14 light the whole row as the "on" signal, so their lit colour
	-- outranks hover; the other styles leave the row neutral.
	local function paintRow()
		label.TextColor3 = if enabled then THEME.text else THEME.textMuted
		local lit = (style == "T5" or style == "T14") and value
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
	elseif style == "T10" then
		paintValue = roundTickSkin(row)
	end

	if style == "T11" then
		paintValue = railSkin(row)
	elseif style == "T12" then
		paintValue = outlineSkin(row)
	elseif style == "T13" then
		paintValue = bigSwitchSkin(row)
	elseif style == "T14" then
		paintValue = chipSkin(row, rowCorner)
	elseif style == "T15" then
		paintValue = powerSkin(row)
	elseif style == "T16" then
		paintValue = stretchSkin(row)
	elseif style == "T17" then
		paintValue = trackIconSkin(row)
	elseif style == "T18" then
		paintValue = keySkin(row)
	elseif style == "T19" then
		local description = if details and details.description then details.description else ""
		paintValue = describedSkin(row, label, description)
	elseif style == "T20" then
		local image = if details and details.icon then details.icon else ICON.feature
		paintValue = iconRowSkin(row, image)
	end

	if style == "T21" then
		paintValue = fillSkin(row)
	elseif style == "T22" then
		paintValue = labelledEndsSkin(row)
	elseif style == "T23" then
		paintValue = glowSkin(row)
	elseif style == "T24" then
		paintValue = leverSkin(row)
	elseif style == "T25" then
		paintValue = dotRingSkin(row)
	elseif style == "T26" then
		paintValue = stripeSkin(row)
	elseif style == "T27" then
		paintValue = rockerSkin(row)
	elseif style == "T28" then
		paintValue = pillSkin(row)
	elseif style == "T29" then
		paintValue = keyChipSkin(row, if details and details.key then details.key else "F")
	elseif style == "T30" then
		paintValue = miniSkin(row)
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
