--[[
	Slider - a number between Min and Max, snapped to Step.

	    Tab:Slider({
	        Title = "Walk speed",
	        Min = 16,
	        Max = 120,
	        Default = 16,
	        Suffix = "studs/s",
	        Flag = "WalkSpeed",
	        Callback = function(speed) ... end,
	    })

	Three ways to change it, one per input: drag the track (mouse and touch),
	type into the value box (exact values on a phone, where dragging to 37 is
	fiddly), or select the track and press left and right (keyboard, gamepad).
	The arrows are bound through ContextActionService while the track is
	selected; UserInputService would see them already consumed by gamepad
	navigation, which moves the selection instead.

	The drag follows UserInputService.InputChanged, not the track's own
	events, because the pointer leaves the track on the first pixel of a fast
	drag and the track would stop hearing it.
--]]

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)
local Row = require(script.Parent.Row)

local BAR_HEIGHT = 6
local KNOB = 16

local Slider = {}

local nextAction = 0

local function decimalsOf(step: number): number
	local text = string.format("%.6f", step):gsub("0+$", "")
	local dot = string.find(text, ".", 1, true)
	return if dot then #text - dot else 0
end

function Slider.new(container: any, options: { [string]: any })
	local minimum, maximum = options.Min, options.Max
	local numeric = type(minimum) == "number" and type(maximum) == "number"
	assert(numeric, "Slider needs numeric Min and Max")
	assert(maximum > minimum, "Slider Max must be greater than Min")
	local step = options.Step or 1
	local decimals = decimalsOf(step)
	local suffix = if options.Suffix then " " .. options.Suffix else ""
	local callback = options.Callback

	local row = Row.frame(container, options, true)
	local trove = row.trove

	local function snap(raw: number): number
		local snapped = minimum + math.round((raw - minimum) / step) * step
		local clamped = math.clamp(snapped, minimum, maximum)
		return tonumber(string.format(`%.{decimals}f`, clamped)) :: number
	end

	local value = snap(options.Default or minimum)

	local box = New("TextBox", {
		Name = "Value",
		Size = UDim2.fromOffset(88, 28),
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = "",
		Theme = { BackgroundColor3 = "background", TextColor3 = "text" },
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, box)

	local hit = New("TextButton", {
		Name = "Track",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row.below)

	local bar = New("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		Theme = { BackgroundColor3 = "hover" },
	}, hit)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)

	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "accent" },
	}, bar)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)

	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(KNOB, KNOB),
		Theme = { BackgroundColor3 = "text" },
	}, hit)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, knob)
	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 2,
		Enabled = false,
		Theme = { Color = "focus" },
	}, knob)

	local function render()
		local alpha = (value - minimum) / (maximum - minimum)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		if not box:IsFocused() then
			box.Text = string.format(`%.{decimals}f`, value) .. suffix
		end
	end

	function row:Get(): number
		return value
	end

	function row:Set(raw: number)
		value = snap(raw)
		render()
		self.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	local function setFromX(x: number)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local snapped = snap(minimum + alpha * (maximum - minimum))
		if snapped ~= value then
			row:Set(snapped)
		end
	end

	local dragging: InputObject? = nil
	trove:connect(hit.InputBegan, function(input: InputObject)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		if row.frame.Interactable then
			dragging = input
			setFromX(input.Position.X)
		end
	end)
	trove:connect(UserInputService.InputChanged, function(input: InputObject)
		if not dragging then
			return
		end
		local mouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local mouseDrag = mouse and dragging.UserInputType == Enum.UserInputType.MouseButton1
		if input == dragging or mouseDrag then
			setFromX(input.Position.X)
		end
	end)
	trove:connect(UserInputService.InputEnded, function(input: InputObject)
		if dragging and (input == dragging or input.UserInputType == dragging.UserInputType) then
			dragging = nil
		end
	end)

	trove:connect(box.FocusLost, function()
		local typed = tonumber((string.gsub(box.Text, "[^%d%.%-]", "")))
		if typed and row.frame.Interactable then
			row:Set(typed)
		else
			render()
		end
	end)

	nextAction += 1
	local action = `HubKitSlider{nextAction}`
	local function nudge(_, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local key = input.KeyCode
		local down = key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft
		row:Set(value + (if down then -step else step))
		return Enum.ContextActionResult.Sink
	end
	trove:connect(hit.SelectionGained, function()
		ring.Enabled = true
		ContextActionService:BindActionAtPriority(
			action,
			nudge,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Left,
			Enum.KeyCode.Right,
			Enum.KeyCode.DPadLeft,
			Enum.KeyCode.DPadRight
		)
	end)
	trove:connect(hit.SelectionLost, function()
		ring.Enabled = false
		ContextActionService:UnbindAction(action)
	end)
	trove:add(function()
		ContextActionService:UnbindAction(action)
	end)

	row.searchText ..= suffix
	render()
	return row
end

return Slider
