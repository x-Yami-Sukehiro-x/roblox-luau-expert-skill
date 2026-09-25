--[[
	Keybind - a key the player chooses, and a Callback when it is pressed.

	    Tab:Keybind({
	        Title = "Fly key",
	        Default = Enum.KeyCode.F,
	        Flag = "FlyKey",
	        Callback = function() fly:Set(not fly:Get()) end,
	    })

	Press the row, then any key or gamepad button: Escape cancels and Backspace
	clears the bind. While it listens, `kit.capturing` stands every window's
	menu key down, so choosing RightShift does not also hide the window.

	Presses the game already consumed (typing in chat, a focused TextBox) never
	fire the Callback. With `Mode = "Hold"` the Callback receives true on press
	and false on release; the default "Press" mode calls it once per press.
--]]

local UserInputService = game:GetService("UserInputService")

local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)
local Row = require(script.Parent.Row)

local Keybind = {}

local function keyFromName(name: string?): Enum.KeyCode?
	if name == nil or name == "" then
		return nil
	end
	for _, item in Enum.KeyCode:GetEnumItems() do
		if item.Name == name then
			return item
		end
	end
	return nil
end

function Keybind.new(container: any, options: { [string]: any })
	local kit = container.kit
	local hold = options.Mode == "Hold"
	local callback = options.Callback
	local row = Row.button(container, options)
	local trove = row.trove
	local key: Enum.KeyCode? = options.Default
	local listening = false

	local chip = New("TextLabel", {
		Name = "Key",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = "",
		Theme = { BackgroundColor3 = "background" },
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, chip)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, chip)

	local function render()
		chip.Text = if listening then "Press a key" elseif key then key.Name else "None"
		chip.TextColor3 = Theme.get(if listening then "accent" else "text")
	end

	function row:Get(): Enum.KeyCode?
		return key
	end

	function row:Set(newKey: Enum.KeyCode?)
		key = newKey
		render()
		self.Changed:Fire(key)
	end

	row.Encode = function(value: Enum.KeyCode?): string
		return if value then value.Name else ""
	end
	row.Decode = keyFromName

	local function stopListening()
		listening = false
		kit.capturing = false
		render()
	end

	trove:connect(row.frame.Activated, function()
		if listening then
			return
		end
		listening = true
		kit.capturing = true
		render()
	end)

	trove:connect(UserInputService.InputBegan, function(input: InputObject, processed: boolean)
		if listening then
			local pressed = input.KeyCode
			if pressed == Enum.KeyCode.Unknown then
				return
			end
			-- Deferred so the release of the chosen key, and this same press
			-- reaching a window's menu-key check, both see capturing still on.
			task.defer(stopListening)
			if pressed == Enum.KeyCode.Escape then
				return
			end
			row:Set(if pressed == Enum.KeyCode.Backspace then nil else pressed)
			return
		end
		if processed or kit.capturing or key == nil or input.KeyCode ~= key then
			return
		end
		if callback then
			callback(if hold then true else nil)
		end
	end)

	if hold then
		trove:connect(UserInputService.InputEnded, function(input: InputObject, processed: boolean)
			if not processed and key ~= nil and input.KeyCode == key and callback then
				callback(false)
			end
		end)
	end

	trove:add(function()
		if listening then
			kit.capturing = false
		end
	end)
	trove:connect(Theme.changed, render)
	render()
	return row
end

return Keybind
