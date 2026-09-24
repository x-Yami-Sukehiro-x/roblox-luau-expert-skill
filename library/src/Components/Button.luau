--!strict
--[[
	Button — three weights, all six states, gamepad-reachable.

	Explained in: roblox-ui-components/references/component-states.md
	               roblox-ui-components/references/catalog.md

	Deliberate choices:
	  - Activated, not MouseButton1Click. Activated fires for mouse, touch AND
	    gamepad; MouseButton1Click is mouse-only, which is why so many Roblox
	    menus cannot be used on console.
	  - One render() reads every flag. Handlers only SET flags. Independent
	    handlers fight: hover-out during a press leaves the button stuck.
	  - Interactable = false for disabled, checked first in render().
--]]

local TweenService = game:GetService("TweenService")

local Motion = require(script.Parent.Parent.Motion)
local Tokens = require(script.Parent.Parent.Tokens)

local Button = {}

export type Weight = "primary" | "secondary" | "ghost" | "danger"

export type Handle = {
	instance: TextButton,
	setEnabled: (self: Handle, enabled: boolean) -> (),
	setBusy: (self: Handle, busy: boolean) -> (),
	setText: (self: Handle, text: string) -> (),
	destroy: (self: Handle) -> (),
}

local MIN_TOUCH_TARGET = 44

type Palette = { fill: Color3, hover: Color3, pressed: Color3, text: Color3, stroke: Color3? }

local function paletteFor(weight: Weight): Palette
	if weight == "primary" then
		return {
			fill = Tokens.accent.base,
			hover = Tokens.accent.bright,
			pressed = Tokens.accent.dim,
			text = Tokens.text.onAccent,
		}
	elseif weight == "secondary" then
		return {
			fill = Tokens.control.base,
			hover = Tokens.control.hover,
			pressed = Tokens.control.pressed,
			text = Tokens.text.primary,
			stroke = Tokens.stroke.base,
		}
	elseif weight == "danger" then
		return {
			fill = Tokens.danger.base,
			hover = Tokens.danger.hover,
			pressed = Tokens.danger.pressed,
			text = Tokens.text.primary,
		}
	end

	return {
		fill = Tokens.surface.base,
		hover = Tokens.control.hover,
		pressed = Tokens.control.pressed,
		text = Tokens.text.secondary,
	}
end

--[[
	    local ok = Button.new("Confirm", "primary", function() ... end)
	    ok.instance.Parent = panel
--]]
function Button.new(text: string, weight: Weight, onClick: () -> ()): Handle
	if typeof(text) ~= "string" then
		error(`Button.new expects a string label, got {typeof(text)}`, 2)
	end

	local palette = paletteFor(weight)

	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.AutoButtonColor = false -- we own every state
	button.BackgroundColor3 = palette.fill
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, MIN_TOUCH_TARGET)
	button.Selectable = true -- gamepad reachable

	local minimum = Instance.new("UISizeConstraint")
	minimum.MinSize = Vector2.new(MIN_TOUCH_TARGET * 2, MIN_TOUCH_TARGET)
	minimum.Parent = button

	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = Tokens.radius.control
	corner.TopRightRadius = Tokens.radius.control
	corner.BottomLeftRadius = Tokens.radius.control
	corner.BottomRightRadius = Tokens.radius.control
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Tokens.space.loose)
	padding.PaddingRight = UDim.new(0, Tokens.space.loose)
	padding.Parent = button

	-- Press scales DOWN — reads as the control moving away under the finger.
	local scale = Instance.new("UIScale")
	scale.Parent = button

	if palette.stroke then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
		stroke.Thickness = 1
		stroke.Color = palette.stroke
		stroke.Parent = button
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.FontFace = Tokens.font.emphasis
	label.TextSize = Tokens.text_size.body
	label.TextColor3 = palette.text
	label.Text = text
	label.Parent = button

	-- Focus ring: Outer, so it sits outside the bounds without disturbing layout.
	local focusRing = Instance.new("UIStroke")
	focusRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	focusRing.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	focusRing.Thickness = 2
	focusRing.Color = Tokens.stroke.focus
	focusRing.Enabled = false
	focusRing.Parent = button

	-- Suppress the default blue selection box; the ring above replaces it.
	local emptySelection = Instance.new("Frame")
	emptySelection.BackgroundTransparency = 1
	emptySelection.Size = UDim2.fromScale(1, 1)
	emptySelection.Parent = button
	button.SelectionImageObject = emptySelection

	local connections: { RBXScriptConnection } = {}
	local hovered, pressed, focused, busy = false, false, false, false

	local function render()
		-- Disabled short-circuits, so a dead control cannot show hover.
		if not button.Interactable then
			button.BackgroundColor3 = Tokens.control.disabled
			button.BackgroundTransparency = 0.35
			label.TextColor3 = Tokens.text.muted
			focusRing.Enabled = false
			scale.Scale = 1
			return
		end

		button.BackgroundTransparency = 0
		label.TextColor3 = palette.text

		local target = palette.fill
		if pressed then
			target = palette.pressed
		elseif hovered then
			target = palette.hover
		end

		local tweenInfo = Motion.presets.instant
		TweenService:Create(button, tweenInfo, { BackgroundColor3 = target }):Play()
		TweenService:Create(scale, tweenInfo, { Scale = if pressed then 0.97 else 1 }):Play()

		focusRing.Enabled = focused
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
			-- Leaving cancels the press, or a drag-off leaves it stuck.
			hovered, pressed = false, false
			render()
		end)
	)

	local function isPressInput(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	table.insert(
		connections,
		button.InputBegan:Connect(function(input: InputObject)
			if isPressInput(input) then
				pressed = true
				render()
			end
		end)
	)

	table.insert(
		connections,
		button.InputEnded:Connect(function(input: InputObject)
			if isPressInput(input) then
				pressed = false
				render()
			end
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
			if busy then
				return -- closes the race between the click and the property write
			end
			onClick()
		end)
	)

	render()

	local handle = {}
	handle.instance = button

	function handle:setEnabled(enabled: boolean)
		button.Interactable = enabled
	end

	function handle:setBusy(value: boolean)
		busy = value
		button.Interactable = not value
		label.Text = if value then "..." else text
	end

	function handle:setText(value: string)
		text = value
		if not busy then
			label.Text = value
		end
	end

	function handle:destroy()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		button:Destroy()
	end

	return (handle :: any) :: Handle
end

function Button.primary(text: string, onClick: () -> ()): Handle
	return Button.new(text, "primary", onClick)
end

function Button.secondary(text: string, onClick: () -> ()): Handle
	return Button.new(text, "secondary", onClick)
end

function Button.ghost(text: string, onClick: () -> ()): Handle
	return Button.new(text, "ghost", onClick)
end

function Button.danger(text: string, onClick: () -> ()): Handle
	return Button.new(text, "danger", onClick)
end

return Button
