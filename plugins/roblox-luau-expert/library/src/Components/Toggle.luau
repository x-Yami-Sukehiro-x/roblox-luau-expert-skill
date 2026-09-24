--!strict
--[[
	Toggle — a switch that reads as on or off without relying on colour.

	Explained in: roblox-ui-components/references/component-states.md
	              roblox-ui/references/blueprints.md (B2)

	Deliberate choices:
	  - The knob MOVES. A switch that only changes colour is invisible to a
	    player who cannot distinguish the two colours, and ambiguous to everyone
	    else at a glance.
	  - The track is a spring, not a tween. A toggle spammed twice with a tween
	    snaps, because restarting a tween discards velocity.
	  - 44px minimum height on the whole hit area, not on the visible track. The
	    visible switch is 44x24; the button around it is 44 tall.
	  - Interactable = false is the disabled signal, checked first in render(),
	    so a dead switch cannot show hover.
--]]

local TweenService = game:GetService("TweenService")

local Motion = require(script.Parent.Parent.Motion)
local Tokens = require(script.Parent.Parent.Tokens)

local Toggle = {}

export type Handle = {
	instance: TextButton,
	get: (self: Handle) -> boolean,
	set: (self: Handle, value: boolean, silent: boolean?) -> (),
	setEnabled: (self: Handle, enabled: boolean) -> (),
	destroy: (self: Handle) -> (),
}

local HIT_HEIGHT = 44
local TRACK_WIDTH = 44
local TRACK_HEIGHT = 24
local KNOB = 18
local KNOB_INSET = 3

--[[
	    local sound = Toggle.new(false, function(on) music.Playing = on end)
	    sound.instance.Parent = row
--]]
function Toggle.new(initial: boolean, onChange: (value: boolean) -> ()): Handle
	local state = initial == true

	local button = Instance.new("TextButton")
	button.Name = "Toggle"
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Size = UDim2.fromOffset(TRACK_WIDTH, HIT_HEIGHT)
	button.Selectable = true

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT)
	track.BackgroundColor3 = Tokens.control.base
	track.BorderSizePixel = 0
	track.Parent = button

	local trackCorner = Instance.new("UICorner")
	trackCorner.TopLeftRadius = Tokens.radius.pill
	trackCorner.TopRightRadius = Tokens.radius.pill
	trackCorner.BottomLeftRadius = Tokens.radius.pill
	trackCorner.BottomRightRadius = Tokens.radius.pill
	trackCorner.Parent = track

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	edge.Thickness = 1
	edge.Color = Tokens.stroke.base
	edge.Parent = track

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.fromOffset(KNOB, KNOB)
	knob.Position = UDim2.new(0, KNOB_INSET, 0.5, 0)
	knob.BackgroundColor3 = Tokens.text.primary
	knob.BorderSizePixel = 0
	knob.Parent = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.TopLeftRadius = Tokens.radius.pill
	knobCorner.TopRightRadius = Tokens.radius.pill
	knobCorner.BottomLeftRadius = Tokens.radius.pill
	knobCorner.BottomRightRadius = Tokens.radius.pill
	knobCorner.Parent = knob

	local focusRing = Instance.new("UIStroke")
	focusRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	focusRing.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	focusRing.Thickness = 2
	focusRing.Color = Tokens.stroke.focus
	focusRing.Enabled = false
	focusRing.Parent = track

	local emptySelection = Instance.new("Frame")
	emptySelection.BackgroundTransparency = 1
	emptySelection.Size = UDim2.fromScale(1, 1)
	emptySelection.Parent = button
	button.SelectionImageObject = emptySelection

	-- The knob position is a plain number so it can spring; UDim2 is not a
	-- SmoothDamp-supported type. See Motion.springValue.
	local offOffset = KNOB_INSET
	local onOffset = TRACK_WIDTH - KNOB - KNOB_INSET

	local slide = Motion.springValue(if state then onOffset else offOffset, 0.09, function(value)
		knob.Position = UDim2.new(0, value, 0.5, 0)
	end)

	local connections: { RBXScriptConnection } = {}
	local hovered, focused = false, false

	local function render()
		if not button.Interactable then
			track.BackgroundColor3 = Tokens.control.disabled
			track.BackgroundTransparency = 0.3
			knob.BackgroundColor3 = Tokens.text.muted
			focusRing.Enabled = false
			return
		end

		track.BackgroundTransparency = 0
		knob.BackgroundColor3 = if state then Tokens.text.onAccent else Tokens.text.primary

		local target = if state then Tokens.accent.base else Tokens.control.base
		if hovered then
			target = if state then Tokens.accent.bright else Tokens.control.hover
		end

		TweenService:Create(track, Motion.presets.instant, { BackgroundColor3 = target }):Play()
		edge.Color = if state then Tokens.accent.dim else Tokens.stroke.base
		focusRing.Enabled = focused
		slide:setTarget(if state then onOffset else offOffset)
	end

	table.insert(
		connections,
		button.MouseEnter:Connect(function()
			hovered = true
			render()
		end)
	)

	table.insert(
		connections,
		button.MouseLeave:Connect(function()
			hovered = false
			render()
		end)
	)

	table.insert(
		connections,
		button.SelectionGained:Connect(function()
			focused = true
			render()
		end)
	)

	table.insert(
		connections,
		button.SelectionLost:Connect(function()
			focused = false
			render()
		end)
	)

	table.insert(connections, button:GetPropertyChangedSignal("Interactable"):Connect(render))

	table.insert(
		connections,
		button.Activated:Connect(function()
			state = not state
			render()
			onChange(state)
		end)
	)

	render()

	local handle = {}
	handle.instance = button

	function handle:get(): boolean
		return state
	end

	--[[
		Set from code. `silent` skips the callback, which is what a settings
		screen wants when it restores saved values — otherwise restoring the
		config re-fires every handler on open.
	--]]
	function handle:set(value: boolean, silent: boolean?)
		local next = value == true
		if next == state then
			return
		end
		state = next
		render()
		if not silent then
			onChange(state)
		end
	end

	function handle:setEnabled(enabled: boolean)
		button.Interactable = enabled
	end

	function handle:destroy()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		slide:destroy()
		button:Destroy()
	end

	return (handle :: any) :: Handle
end

return Toggle
