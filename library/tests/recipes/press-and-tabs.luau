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

for _, style in { "S1", "S2", "S3" } do
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

local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
