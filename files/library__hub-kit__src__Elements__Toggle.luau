--[[
	Toggle - an on/off switch across the whole row.

	    local fly = Tab:Toggle({ Title = "Fly", Flag = "Fly", Callback = function(on) ... end })

	The knob moves as well as changing colour, so on and off differ for a
	player who cannot tell the two colours apart. A toggle built with
	`Default = true` runs its Callback once, deferred, because a switch drawn
	on must mean the feature is on. Other elements only show their Default.

	`Set` always runs the Callback, even with the value it already has. That
	is what makes loading a config start every saved feature, including the
	ones whose saved value matches the default.
--]]

local Motion = require(script.Parent.Parent.Core.Motion)
local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)
local Row = require(script.Parent.Row)

local TRACK_WIDTH = 40
local TRACK_HEIGHT = 24
local KNOB = 18
local INSET = 3

local Toggle = {}

function Toggle.new(container: any, options: { [string]: any })
	local callback = options.Callback
	local row = Row.button(container, options)
	local value = options.Default == true

	local track = New("Frame", {
		Name = "Track",
		Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT),
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)

	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(KNOB, KNOB),
	}, track)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, knob)

	local function render()
		local enabled = row.frame.Interactable
		local fill = if value then "accent" else "hover"
		Motion.play(track, Motion.state, {
			BackgroundColor3 = Theme.get(if enabled then fill else "stroke"),
		})
		Motion.play(knob, Motion.state, {
			Position = UDim2.new(0, if value then TRACK_WIDTH - KNOB - INSET else INSET, 0.5, 0),
			BackgroundColor3 = Theme.get(if value then "onAccent" else "textMuted"),
		})
	end

	function row:Get(): boolean
		return value
	end

	function row:Set(on: boolean)
		value = on == true
		render()
		self.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	row.trove:connect(row.frame.Activated, function()
		row:Set(not value)
	end)
	row.trove:connect(row.frame:GetPropertyChangedSignal("Interactable"), render)
	row.trove:connect(Theme.changed, render)
	render()

	if value and callback then
		task.defer(callback, true)
	end
	return row
end

return Toggle
