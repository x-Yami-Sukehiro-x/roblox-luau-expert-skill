--!strict
--[[
	Slider — a value between two bounds, draggable by mouse, touch and keyboard.

	Explained in: roblox-ui-components/references/catalog.md
	              roblox-ui/references/blueprints.md (B2)

	Deliberate choices:
	  - Dragging is tracked on UserInputService, not on the knob. A knob-only
	    InputChanged connection loses the drag the moment the pointer leaves the
	    knob, which is immediately, which is why so many Roblox sliders feel
	    broken.
	  - The fill follows the pointer directly during a drag and springs only
	    when set from code. Springing a dragged control adds lag to the one
	    interaction that must feel direct.
	  - Arrow keys step by `step` and gamepad D-pad does the same, so the
	    control is reachable without a pointer at all.
	  - The value is quantised to `step` before the callback, so a caller never
	    receives 0.30000000000000004.
--]]

local UserInputService = game:GetService("UserInputService")

local Motion = require(script.Parent.Parent.Motion)
local Tokens = require(script.Parent.Parent.Tokens)

local Slider = {}

export type Options = {
	min: number,
	max: number,
	step: number?,
	initial: number?,
	width: number?,
}

export type Handle = {
	instance: Frame,
	get: (self: Handle) -> number,
	set: (self: Handle, value: number, silent: boolean?) -> (),
	setEnabled: (self: Handle, enabled: boolean) -> (),
	destroy: (self: Handle) -> (),
}

local HIT_HEIGHT = 44
local TRACK_HEIGHT = 6
local KNOB = 18
local DEFAULT_WIDTH = 160

local function quantise(value: number, step: number, minimum: number): number
	if step <= 0 then
		return value
	end
	return minimum + math.round((value - minimum) / step) * step
end

--[[
	    local volume = Slider.new({ min = 0, max = 1, step = 0.05, initial = 0.8 },
	        function(value) group.Volume = value end)
--]]
function Slider.new(options: Options, onChange: (value: number) -> ()): Handle
	if options.max <= options.min then
		error(`Slider.new: max ({options.max}) must be greater than min ({options.min})`, 2)
	end

	local minimum = options.min
	local maximum = options.max
	local step = options.step or 0
	local width = options.width or DEFAULT_WIDTH

	local value = math.clamp(options.initial or minimum, minimum, maximum)

	local frame = Instance.new("Frame")
	frame.Name = "Slider"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(width, HIT_HEIGHT)

	-- The whole row is the hit area. A 6px track is not a touch target.
	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Size = UDim2.fromScale(1, 1)
	hit.Selectable = true
	hit.Parent = frame

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.Size = UDim2.new(1, -KNOB, 0, TRACK_HEIGHT)
	track.BackgroundColor3 = Tokens.surface.sunken
	track.BorderSizePixel = 0
	track.Parent = hit

	local trackCorner = Instance.new("UICorner")
	trackCorner.TopLeftRadius = Tokens.radius.pill
	trackCorner.TopRightRadius = Tokens.radius.pill
	trackCorner.BottomLeftRadius = Tokens.radius.pill
	trackCorner.BottomRightRadius = Tokens.radius.pill
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Tokens.accent.base
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.TopLeftRadius = Tokens.radius.pill
	fillCorner.TopRightRadius = Tokens.radius.pill
	fillCorner.BottomLeftRadius = Tokens.radius.pill
	fillCorner.BottomRightRadius = Tokens.radius.pill
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(KNOB, KNOB)
	knob.Position = UDim2.fromScale(0, 0.5)
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
	focusRing.Parent = knob

	local emptySelection = Instance.new("Frame")
	emptySelection.BackgroundTransparency = 1
	emptySelection.Size = UDim2.fromScale(1, 1)
	emptySelection.Parent = hit
	hit.SelectionImageObject = emptySelection

	local connections: { RBXScriptConnection } = {}
	local dragging = false

	local function alpha(): number
		return (value - minimum) / (maximum - minimum)
	end

	local function paint(fraction: number)
		fill.Size = UDim2.fromScale(fraction, 1)
		knob.Position = UDim2.fromScale(fraction, 0.5)
	end

	-- Springs only when set from code. During a drag the knob follows the
	-- pointer with no smoothing, because lag under the finger reads as broken.
	local follow = Motion.springValue(alpha(), 0.08, paint)

	local function apply(next: number, silent: boolean?, immediate: boolean?)
		local clamped = math.clamp(next, minimum, maximum)
		if step > 0 then
			clamped = math.clamp(quantise(clamped, step, minimum), minimum, maximum)
		end
		if clamped == value then
			return
		end
		value = clamped

		if immediate then
			follow:snap(alpha())
		else
			follow:setTarget(alpha())
		end

		if not silent then
			onChange(value)
		end
	end

	local function valueAtX(x: number): number
		local span = track.AbsoluteSize.X
		if span <= 0 then
			return value -- AbsoluteSize is zero on the first frame
		end
		local fraction = math.clamp((x - track.AbsolutePosition.X) / span, 0, 1)
		return minimum + fraction * (maximum - minimum)
	end

	table.insert(
		connections,
		hit.InputBegan:Connect(function(input: InputObject)
			if not hit.Interactable then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				apply(valueAtX(input.Position.X), false, true)
			end
		end)
	)

	-- Tracked globally: the pointer leaves the knob on the first pixel of drag.
	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if not dragging then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				apply(valueAtX(input.Position.X), false, true)
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
			end
		end)
	)

	table.insert(
		connections,
		hit.SelectionGained:Connect(function()
			focusRing.Enabled = true
		end)
	)

	table.insert(
		connections,
		hit.SelectionLost:Connect(function()
			focusRing.Enabled = false
		end)
	)

	-- Keyboard and D-pad. A slider that needs a pointer is unusable on console.
	local nudge = if step > 0 then step else (maximum - minimum) / 20

	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed or not focusRing.Enabled or not hit.Interactable then
				return
			end
			if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then
				apply(value - nudge)
			elseif input.KeyCode == Enum.KeyCode.Right
				or input.KeyCode == Enum.KeyCode.DPadRight
			then
				apply(value + nudge)
			end
		end)
	)

	table.insert(
		connections,
		hit:GetPropertyChangedSignal("Interactable"):Connect(function()
			local enabled = hit.Interactable
			fill.BackgroundColor3 = if enabled then Tokens.accent.base else Tokens.control.disabled
			knob.BackgroundColor3 = if enabled then Tokens.text.primary else Tokens.text.muted
			if not enabled then
				focusRing.Enabled = false
			end
		end)
	)

	paint(alpha())

	local handle = {}
	handle.instance = frame

	function handle:get(): number
		return value
	end

	function handle:set(next: number, silent: boolean?)
		apply(next, silent)
	end

	function handle:setEnabled(enabled: boolean)
		hit.Interactable = enabled
	end

	function handle:destroy()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		follow:destroy()
		frame:Destroy()
	end

	return (handle :: any) :: Handle
end

return Slider
