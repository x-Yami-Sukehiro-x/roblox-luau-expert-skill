-- UDim2 arithmetic and tween control for the presenter tests.
local udimMeta = {}
udimMeta.__add = function(a, b) return setmetatable({ X = { Scale = a.X.Scale + b.X.Scale, Offset = a.X.Offset + b.X.Offset }, Y = { Scale = a.Y.Scale + b.Y.Scale, Offset = a.Y.Offset + b.Y.Offset } }, udimMeta) end
udimMeta.__sub = function(a, b) return setmetatable({ X = { Scale = a.X.Scale - b.X.Scale, Offset = a.X.Offset - b.X.Offset }, Y = { Scale = a.Y.Scale - b.Y.Scale, Offset = a.Y.Offset - b.Y.Offset } }, udimMeta) end
local rawNew = UDim2.new
UDim2.new = function(...) return setmetatable(rawNew(...), udimMeta) end
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end
UDim2.fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end
Enum.EasingStyle.Back = "EasingStyle.Back"

-- Manual tweens: Play records, finish() applies goals and fires Completed.
local pending = {}
local Tweens = game:GetService("TweenService")
Tweens.Create = function(_, inst, _, goals)
	local tween = { Completed = { handlers = {} }, cancelled = false }
	function tween.Completed:Once(fn) table.insert(self.handlers, fn) end
	function tween.Completed:Connect(fn) table.insert(self.handlers, fn) end
	function tween:Play() table.insert(pending, { tween = tween, inst = inst, goals = goals }) end
	function tween:Cancel()
		if tween.cancelled then return end
		tween.cancelled = true
		for _, h in tween.Completed.handlers do h(Enum.PlaybackState.Cancelled) end
	end
	return tween
end
local function finishAll()
	local batch = pending
	pending = {}
	for _, job in batch do
		if not job.tween.cancelled then
			for k, v in job.goals do job.inst[k] = v end
			for _, h in job.tween.Completed.handlers do h(Enum.PlaybackState.Completed) end
		end
	end
end

local createPresenter = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
local function newPanel()
	local panel = Instance.new("CanvasGroup")
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Size = UDim2.new(0, 320, 0, 44)
	return panel
end

for _, style in { "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10", "M11", "M12", "M13", "M14", "M15", "M16", "M17", "M18", "M20", "M21", "M22", "M23", "M24" } do
	local panel = newPanel()
	local presenter = createPresenter(panel, style)
	check(style .. " starts hidden", panel.Visible == false and presenter.isOpen() == false)
	presenter.open()
	check(style .. " visible while opening", panel.Visible == true and presenter.isOpen())
	finishAll()
	check(style .. " opens to rest pose", panel.GroupTransparency == 0 and panel.Position.Y.Offset == 0 and panel.Position.X.Offset == 0 and panel.OpenScale.Scale == 1)
	presenter.close()
	finishAll()
	check(style .. " closes hidden and resets", panel.Visible == false and panel.Position.Y.Offset == 0 and panel.OpenScale.Scale == 1)
	-- close interrupted by reopen: stale completion must not hide the panel
	presenter.open(); finishAll()
	presenter.close()
	presenter.open()
	finishAll()
	check(style .. " reopen during close stays visible", panel.Visible == true and presenter.isOpen())
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M0")
	presenter.open()
	check("M0 opens instantly", panel.Visible == true and panel.GroupTransparency == 0 and #pending == 0)
	presenter.close()
	check("M0 closes instantly", panel.Visible == false)
end
do
	game:GetService("GuiService").ReducedMotionEnabled = true
	local panel = newPanel()
	local presenter = createPresenter(panel, "M4")
	presenter.open()
	check("reduced motion: no travel on open", panel.Position.X.Offset == 0)
	finishAll()
	check("reduced motion still opens", panel.GroupTransparency == 0 and panel.Visible)
	game:GetService("GuiService").ReducedMotionEnabled = false
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M2")
	presenter.open(); finishAll()
	panel.Position = UDim2.new(0.5, 40, 0.5, 30) -- dragged while open
	presenter.close(); finishAll()
	presenter.open(); finishAll()
	check("M2 keeps dragged position as new home", panel.Position.X.Offset == 40 and panel.Position.Y.Offset == 30)
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M7")
	presenter.open()
	check("M7 starts off the right edge", panel.Position.X.Offset == 320 + 24)
	finishAll()
	presenter.close()
	check("M7 leaves to the right", pending[#pending].goals.Position ~= nil and pending[#pending].goals.Position.X.Offset == 344)
	finishAll()
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M8")
	presenter.open()
	check("M8 rises from below its own height", panel.Position.Y.Offset == 44 + 24)
	finishAll()
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M3", { closeStyle = "M4" })
	presenter.open()
	check("mixed: opens with M3 scale", panel.OpenScale.Scale == 0.96)
	finishAll()
	presenter.close()
	local slide = pending[#pending]
	check("mixed: closes with M4 slide", slide.goals.Position ~= nil and slide.goals.Position.X.Offset == -344)
	finishAll()
	check("mixed: hidden after close", panel.Visible == false)
	presenter.destroy()
end
do
	local panel = newPanel()
	local rows = {}
	for index = 1, 4 do
		local row = Instance.new("CanvasGroup")
		row.Name = "Row" .. index
		row.Parent = panel
		rows[index] = row
	end
	local presenter = createPresenter(panel, "M12", { rows = rows })
	presenter.open()
	check("M12 hides rows before the cascade", rows[4].GroupTransparency == 1)
	HARNESS.drain()
	finishAll()
	check("M12 cascade reveals every row", rows[1].GroupTransparency == 0 and rows[4].GroupTransparency == 0)
	presenter.close()
	presenter.open()
	HARNESS.drain()
	finishAll()
	check("M12 reopen reveals rows again", rows[2].GroupTransparency == 0)
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M13")
	presenter.open()
	check("M13 starts 24 px to the left", panel.Position.X.Offset == -24)
	finishAll()
	presenter.close()
	check("M13 leaves 12 px to the left", pending[#pending].goals.Position.X.Offset == -12)
	finishAll()
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M16")
	presenter.open()
	check("M16 starts tilted", panel.Rotation == -4)
	finishAll()
	check("M16 settles upright", panel.Rotation == 0)
	presenter.close()
	finishAll()
	check("M16 resets rotation when hidden", panel.Rotation == 0 and panel.Visible == false)
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M17")
	presenter.open()
	check("M17 starts rolled up with its top edge in place", panel.Size.Y.Offset == 0 and panel.Position.Y.Offset == -22)
	finishAll()
	check("M17 unrolls to full height", panel.Size.Y.Offset == 44 and panel.Position.Y.Offset == 0)
	presenter.close()
	finishAll()
	check("M17 hidden with its size restored", panel.Visible == false and panel.Size.Y.Offset == 44)
	presenter.destroy()
end
do
	local panel = newPanel()
	panel.AnchorPoint = Vector2.new(0, 0.5)
	local presenter = createPresenter(panel, "M18")
	presenter.open()
	check("M18 starts as a line at the centre", panel.Size.X.Offset == 0 and panel.Position.X.Offset == 160)
	finishAll()
	check("M18 stretches to full width", panel.Size.X.Offset == 320 and panel.Position.X.Offset == 0)
	presenter.destroy()
end
do
	local panel = newPanel()
	local ok = pcall(createPresenter, panel, "M19")
	check("M19 without a scrim is refused", not ok)
	local scrim = Instance.new("Frame")
	local presenter = createPresenter(newPanel(), "M19", { scrim = scrim })
	check("M19 scrim starts hidden", scrim.Visible == false and scrim.BackgroundTransparency == 1)
	presenter.open()
	finishAll()
	check("M19 dims the game while open", scrim.Visible == true and scrim.BackgroundTransparency == 0.5)
	presenter.close()
	finishAll()
	check("M19 clears the dim when closed", scrim.Visible == false and scrim.BackgroundTransparency == 1)
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M21")
	presenter.open()
	check("M21 drops from 40 px above", panel.Position.Y.Offset == -40)
	finishAll()
	presenter.destroy()
end
do
	local panel = newPanel()
	local presenter = createPresenter(panel, "M22")
	presenter.open()
	check("M22 pops from 80 %", panel.OpenScale.Scale == 0.8)
	finishAll()
	check("M22 rests at full size", panel.OpenScale.Scale == 1)
	presenter.destroy()
end
local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
