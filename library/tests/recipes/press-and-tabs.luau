-- Real tweens finish after Play returns; completion is deferred to the drain.
game:GetService("TweenService").Create = function(_, inst, _, goals)
	local tween = { cancelled = false, handlers = {} }
	tween.Completed = { Once = function(_, fn) table.insert(tween.handlers, fn) end, Connect = function(_, fn) table.insert(tween.handlers, fn) end }
	function tween:Play()
		for key, value in goals do inst[key] = value end
		task.defer(function()
			if not tween.cancelled then
				for _, fn in tween.handlers do fn(Enum.PlaybackState.Completed) end
			end
		end)
	end
	function tween:Cancel() tween.cancelled = true end
	return tween
end

local feel = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
local press = { UserInputType = Enum.UserInputType.MouseButton1 }

for style, expected in { P1 = 1, P2 = 0.97, P3 = 0.98 } do
	local button = Instance.new("TextButton")
	local detach = feel.attachPress(button, style)
	button.MouseEnter:Fire()
	check(style .. " hover scale", button.PressScale.Scale == (style == "P3" and 1.02 or 1))
	button.InputBegan:Fire(press)
	check(style .. " press scale", button.PressScale.Scale == expected)
	button.InputEnded:Fire(press)
	check(style .. " release returns to hover", button.PressScale.Scale == (style == "P3" and 1.02 or 1))
	button.MouseLeave:Fire()
	check(style .. " rest", button.PressScale.Scale == 1)
	if style == "P3" then
		button.MouseEnter:Fire()
		check("P3 lift edge on hover", button.LiftEdge.Transparency == 0)
		button.MouseLeave:Fire()
	end
	detach()
	check(style .. " detach cleans up", button.PressScale == nil)
end

for _, style in { "S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10", "S11", "S12" } do
	local parent = Instance.new("Frame")
	local picked = {}
	local tabs = feel.createTabs(parent, { "Combat", "Movement", "Visuals" }, style, function(name) table.insert(picked, name) end)
	local bar = parent.Tabs
	check(style .. " first tab selected", tabs.selected() == "Combat" and #picked == 0)
	bar.Row.Movement.Activated:Fire()
	check(style .. " activation selects", tabs.selected() == "Movement" and picked[1] == "Movement")
	bar.Row.Movement.Activated:Fire()
	check(style .. " reselecting is a no-op", #picked == 1)
	bar.Row.Visuals.SelectionGained:Fire()
	check(style .. " focus does not change selection", tabs.selected() == "Movement")
	check(style .. " marker visibility", bar.Marker.Visible == (style ~= "S3"))
	tabs.destroy()
	check(style .. " destroy", parent.Tabs == nil)
end

local function roundedButton()
	local button = Instance.new("TextButton")
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end
local pressAt = { UserInputType = Enum.UserInputType.MouseButton1, Position = { X = 10, Y = 10 } }

do
	local button = roundedButton()
	local detach = feel.attachPress(button, "P4")
	check("P4 ripple layer keeps the button corners", button.RippleLayer.UICorner.CornerRadius.Offset == 6)
	button.InputBegan:Fire(pressAt)
	local ripple = button.RippleLayer.Ripple
	check("P4 ripple spreads from the press", ripple ~= nil and ripple.Position.X.Offset == 10 and ripple.Size.X.Offset == 800)
	HARNESS.drain()
	check("P4 ripple removed once faded", button.RippleLayer.Ripple == nil)
	detach()
	check("P4 detach removes the layer", button.RippleLayer == nil)
end
do
	local button = Instance.new("TextButton")
	local detach = feel.attachPress(button, "P5")
	button.MouseEnter:Fire()
	local glowColour = button.LiftEdge.Color
	check("P5 edge lights on hover", button.LiftEdge.Transparency == 0 and button.LiftEdge.Thickness == 2)
	button.InputBegan:Fire(pressAt)
	check("P5 edge changes colour while pressed", button.LiftEdge.Color ~= glowColour)
	button.MouseLeave:Fire()
	check("P5 edge fades when the pointer leaves", button.LiftEdge.Transparency == 1)
	detach()
end
do
	local button = Instance.new("TextButton")
	feel.attachPress(button, "P6")
	check("P6 starts unfilled", button.Sweep.Offset.X == -0.5)
	button.MouseEnter:Fire()
	check("P6 hover sweeps the fill across", button.Sweep.Offset.X == 0.5)
	button.MouseLeave:Fire()
	check("P6 leaving sweeps it back", button.Sweep.Offset.X == -0.5)
end
do
	local button = Instance.new("TextButton")
	feel.attachPress(button, "P7")
	button.InputBegan:Fire(pressAt)
	check("P7 squashes while held", button.PressScale.Scale == 0.94)
	button.InputEnded:Fire(pressAt)
	check("P7 springs back on release", button.PressScale.Scale == 1)
end
do
	local button = Instance.new("TextButton")
	feel.attachPress(button, "P8")
	check("P8 underline starts empty", button.Underline.Size.X.Scale == 0)
	button.MouseEnter:Fire()
	check("P8 underline grows on hover", button.Underline.Size.X.Scale == 1)
end
do
	local button = roundedButton()
	feel.attachPress(button, "P9")
	button.MouseEnter:Fire()
	check("P9 shine crosses on hover", button.ShineLayer.Shine.Position.X.Scale == 1.1)
end
do
	local held = 0
	local button = roundedButton()
	feel.attachPress(button, "P10", function() held += 1 end)
	button.InputBegan:Fire(pressAt)
	check("P10 fill grows while held", button.HoldLayer.HoldFill.Size.X.Scale == 1)
	button.InputEnded:Fire(pressAt)
	HARNESS.drain()
	check("P10 early release drains and does not fire", held == 0 and button.HoldLayer.HoldFill.Size.X.Scale == 0)
	button.InputBegan:Fire(pressAt)
	HARNESS.drain()
	check("P10 a full hold fires once", held == 1 and button.HoldLayer.HoldFill.Size.X.Scale == 0)
	check("P10 without onHold is refused", not pcall(feel.attachPress, Instance.new("TextButton"), "P10"))
end
do
	local button = Instance.new("TextButton")
	feel.attachPress(button, "P11")
	button.MouseEnter:Fire()
	check("P11 arrow nudges right on hover", button.Arrow.Position.X.Offset == -8)
	button.MouseLeave:Fire()
	check("P11 arrow returns", button.Arrow.Position.X.Offset == -12)
	local laidOut = Instance.new("TextButton")
	Instance.new("UIListLayout").Parent = laidOut
	check("P11 refuses a button with its own layout", not pcall(feel.attachPress, laidOut, "P11"))
end
do
	local button = Instance.new("TextButton")
	feel.attachPress(button, "P12")
	button.Activated:Fire()
	check("P12 pops when clicked", button.PressScale.Scale == 1.05 and button.LiftEdge.Transparency == 1)
end

do
	local parent = Instance.new("Frame")
	feel.createTabs(parent, { "Combat", "Movement" }, "S4", function() end)
	local row = parent.Tabs.Row
	check("S4 stacks tabs down the side", row.UIListLayout.FillDirection == Enum.FillDirection.Vertical and row.Combat.Size.Y.Offset == 44)
	check("S4 marker is a side bar", parent.Tabs.Marker.Size.X.Offset == 3)
end
do
	local parent = Instance.new("Frame")
	feel.createTabs(parent, { "Combat", "Movement" }, "S6", function() end, { icons = { Combat = "rbxassetid://99199363807265" } })
	local tab = parent.Tabs.Row.Combat
	check("S6 icon above a small label", tab.Text == "" and tab.Glyph.Image == "rbxassetid://99199363807265" and tab.Label.Text == "Combat" and tab.Label.TextSize == 12)
	check("S6 default icon when none given", parent.Tabs.Row.Movement.Glyph.Image == "rbxassetid://89644754139307")
end
do
	local parent = Instance.new("Frame")
	feel.createTabs(parent, { "Combat", "Movement" }, "S7", function() end)
	local tab = parent.Tabs.Row.Combat
	check("S7 icon-only 44 px tabs", tab.Size.X.Offset == 44 and tab.Label == nil and tab.Glyph ~= nil)
end
do
	local parent = Instance.new("Frame")
	feel.createTabs(parent, { "Combat", "Movement" }, "S8", function() end)
	check("S8 tabs sit in a sunken track", parent.Tabs.BackgroundTransparency == 0 and parent.Tabs.Row.UIPadding.PaddingTop.Offset == 4)
end
for _, style in { "S9", "S10" } do
	local parent = Instance.new("Frame")
	local combat, movement = Instance.new("CanvasGroup"), Instance.new("CanvasGroup")
	feel.createTabs(parent, { "Combat", "Movement" }, style, function() end, { pages = { Combat = combat, Movement = movement } })
	check(style .. " only the first page shows", combat.Visible == true and movement.Visible == false)
	parent.Tabs.Row.Movement.Activated:Fire()
	local shift = if style == "S9" then -24 else 0
	check(style .. " old page leaves", combat.GroupTransparency == 1 and combat.Position.X.Offset == shift)
	check(style .. " new page arrives", movement.Visible == true and movement.GroupTransparency == 0 and movement.Position.X.Offset == 0)
	HARNESS.drain()
	check(style .. " old page hidden after leaving", combat.Visible == false)
end
do
	local parent = Instance.new("Frame")
	feel.createTabs(parent, { "Combat", "Movement" }, "S11", function() end)
	check("S11 marker is a 6 px dot", parent.Tabs.Marker.Size.X.Offset == 6 and parent.Tabs.Marker.UICorner.CornerRadius.Scale == 0.5)
end
do
	local parent = Instance.new("Frame")
	local tabs = feel.createTabs(parent, { "Main", "Player", "Visuals", "Misc" }, "S12", function() end)
	check("S12 tabs scroll sideways", parent.Tabs.ClassName == "ScrollingFrame" and parent.Tabs.Row.Main.AutomaticSize == Enum.AutomaticSize.X)
	tabs.select("Misc")
	check("S12 choosing a tab scrolls toward it", parent.Tabs.CanvasPosition ~= nil and tabs.selected() == "Misc")
end

local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
