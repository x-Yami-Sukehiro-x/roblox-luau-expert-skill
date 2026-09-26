--[[
	Input - free text or a number typed by the player.

	    Tab:Input({
	        Title = "Teleport to",
	        Placeholder = "Player name",
	        Flag = "TeleportTarget",
	        Callback = function(name) ... end,
	    })

	The Callback runs when typing finishes (focus lost), not on every
	keystroke, unless `Live = true`. With `Numeric = true` anything that is
	not a number is rejected and the box returns to the last good value,
	so the Callback never receives text it cannot use.

	Pressing the row focuses the box: the box is small, the row is the target.
--]]

local New = require(script.Parent.Parent.Core.New)
local Row = require(script.Parent.Row)

local Input = {}

function Input.new(container: any, options: { [string]: any })
	local numeric = options.Numeric == true
	local callback = options.Callback
	local row = Row.button(container, options)
	local value = if options.Default ~= nil then tostring(options.Default) else ""

	local box = New("TextBox", {
		Name = "Box",
		Size = UDim2.fromOffset(160, 32),
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		PlaceholderText = options.Placeholder or "",
		Text = value,
		Theme = {
			BackgroundColor3 = "background",
			TextColor3 = "text",
			PlaceholderColor3 = "textMuted",
		},
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

	local function accept(text: string): boolean
		return not numeric or text == "" or tonumber(text) ~= nil
	end

	function row:Get(): any
		return if numeric then tonumber(value) else value
	end

	function row:Set(text: any)
		local typed = if text == nil then "" else tostring(text)
		if not accept(typed) then
			box.Text = value
			return
		end
		value = typed
		box.Text = typed
		local result = self:Get()
		self.Changed:Fire(result)
		if callback then
			callback(result)
		end
	end

	row.trove:connect(row.frame.Activated, function()
		box:CaptureFocus()
	end)
	row.trove:connect(box.FocusLost, function()
		if box.Text ~= value then
			row:Set(box.Text)
		end
	end)
	if options.Live then
		row.trove:connect(box:GetPropertyChangedSignal("Text"), function()
			if box:IsFocused() and accept(box.Text) and box.Text ~= value then
				row:Set(box.Text)
			end
		end)
	end

	row.searchText ..= " " .. (options.Placeholder or "")
	return row
end

return Input
