--[[
	ColorPicker - a Color3 chosen on a saturation/value square and a hue bar,
	or typed as a hex code.

	    Tab:ColorPicker({
	        Title = "ESP colour",
	        Default = Color3.fromRGB(72, 201, 162),
	        Flag = "EspColour",
	        Callback = function(colour) ... end,
	    })

	The square is three frames and two UIGradients, no images: the hue fills
	the frame, a white-to-clear gradient runs left to right over it, and a
	clear-to-black gradient runs top to bottom over that. Nothing to upload,
	nothing to moderate, and it renders crisply at any size.

	The swatch and hex update while dragging; the Callback runs when the drag
	ends or a typed hex code is accepted, so an ESP rebuilding on every colour
	change does not rebuild sixty times a second.
--]]

local UserInputService = game:GetService("UserInputService")

local New = require(script.Parent.Parent.Core.New)
local Popup = require(script.Parent.Parent.Components.Popup)
local Row = require(script.Parent.Row)

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SQUARE = Vector2.new(208, 140)
local HUE_HEIGHT = 16
local CURSOR = 12
local PANEL_WIDTH = 224
local PANEL_HEIGHT = 16 + SQUARE.Y + 8 + HUE_HEIGHT + 8 + 32

local ColorPicker = {}

local function hueSequence(): ColorSequence
	local points = {}
	for index = 0, 6 do
		local hue = index / 6
		table.insert(points, ColorSequenceKeypoint.new(hue, Color3.fromHSV(hue % 1, 1, 1)))
	end
	return ColorSequence.new(points)
end

local function press(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

function ColorPicker.new(container: any, options: { [string]: any })
	local callback = options.Callback
	local row = Row.button(container, options)
	local colour: Color3 = options.Default or Color3.fromRGB(255, 255, 255)
	local hue, saturation, brightness = colour:ToHSV()

	local hex = New("TextLabel", {
		Name = "Hex",
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, row.slot)
	local swatch = New("Frame", {
		Name = "Swatch",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(28, 20),
		BackgroundColor3 = colour,
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, swatch)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, swatch)

	local function show()
		swatch.BackgroundColor3 = colour
		hex.Text = "#" .. string.upper(colour:ToHex())
	end

	function row:Get(): Color3
		return colour
	end

	function row:Set(value: Color3)
		colour = value
		hue, saturation, brightness = value:ToHSV()
		show()
		self.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	row.Encode = function(value: Color3): string
		return value:ToHex()
	end
	row.Decode = function(raw: string): Color3
		return Color3.fromHex(raw)
	end

	local function openPicker()
		local popup = Popup.open(container.kit, row.frame, PANEL_WIDTH, PANEL_HEIGHT)
		local trove = popup.trove
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, popup.panel)

		local square = New("Frame", {
			Name = "Square",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(SQUARE.X, SQUARE.Y),
			Active = true,
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, square)
		local whiten = New("Frame", {
			Name = "Saturation",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = WHITE,
		}, square)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, whiten)
		New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, whiten)
		local darken = New("Frame", {
			Name = "Value",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = BLACK,
		}, square)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, darken)
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, darken)
		local cursor = New("Frame", {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(CURSOR, CURSOR),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, square)
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, cursor)
		New("UIStroke", { Thickness = 2, Color = WHITE }, cursor)

		local bar = New("Frame", {
			Name = "Hue",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, HUE_HEIGHT),
			BackgroundColor3 = WHITE,
			Active = true,
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, bar)
		New("UIGradient", { Color = hueSequence() }, bar)
		local marker = New("Frame", {
			Name = "Marker",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 4, 1, 4),
			BackgroundColor3 = WHITE,
		}, bar)
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, marker)
		New("UIStroke", { Thickness = 1, Color = BLACK }, marker)

		local field = New("TextBox", {
			Name = "HexField",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 32),
			ClearTextOnFocus = false,
			FontFace = Font.fromEnum(Enum.Font.BuilderSans),
			TextSize = 14,
			Text = "",
			Theme = { BackgroundColor3 = "background", TextColor3 = "text" },
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, field)

		local function paint()
			square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			cursor.Position = UDim2.fromScale(saturation, 1 - brightness)
			marker.Position = UDim2.fromScale(hue, 0.5)
			field.Text = "#" .. string.upper(colour:ToHex())
		end

		local dragging: GuiObject? = nil
		local function track(position: Vector3)
			local target = dragging :: GuiObject
			local corner, size = target.AbsolutePosition, target.AbsoluteSize
			local across = math.clamp((position.X - corner.X) / size.X, 0, 1)
			if target == bar then
				hue = across
			else
				saturation = across
				brightness = 1 - math.clamp((position.Y - corner.Y) / size.Y, 0, 1)
			end
			colour = Color3.fromHSV(hue, saturation, brightness)
			show()
			paint()
		end

		for _, surface in { square, bar } do
			trove:connect(surface.InputBegan, function(input: InputObject)
				if press(input) then
					dragging = surface
					track(input.Position)
				end
			end)
		end
		trove:connect(UserInputService.InputChanged, function(input: InputObject)
			local moving = input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			if dragging and moving then
				track(input.Position)
			end
		end)
		trove:connect(UserInputService.InputEnded, function(input: InputObject)
			if dragging and press(input) then
				dragging = nil
				row:Set(colour)
			end
		end)
		trove:connect(field.FocusLost, function()
			local code = string.match(field.Text, "^%s*#?(%x%x%x%x%x%x)%s*$")
			if code then
				row:Set(Color3.fromHex(code))
			end
			paint()
		end)
		paint()
	end

	row.trove:connect(row.frame.Activated, openPicker)
	show()
	return row
end

return ColorPicker
