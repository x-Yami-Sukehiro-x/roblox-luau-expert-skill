local createToggle = __recipe()
local parent = Instance.new("Frame")
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
for _, style in { "T1", "T2", "T3", "T5", "T6", "T7", "T8", "T9", "T10" } do
	local log = {}
	local toggle = createToggle(parent, "Auto farm " .. style, style, false, function(v) table.insert(log, v) end)
	check(style .. " starts off", toggle.get() == false)
	toggle.row.Activated:Fire()
	check(style .. " activation turns on", toggle.get() == true and log[1] == true)
	toggle.row.Activated:Fire()
	check(style .. " second activation turns off", toggle.get() == false and log[2] == false)
	toggle.row.SelectionGained:Fire()
	check(style .. " focus ring on selection", toggle.row.FocusRing.Enabled == true)
	toggle.row.MouseLeave:Fire()
	check(style .. " hover loss keeps focus", toggle.row.FocusRing.Enabled == true)
	toggle.setEnabled(false)
	toggle.row.Activated:Fire()
	check(style .. " disabled ignores activation", toggle.get() == false and #log == 2)
	toggle.destroy()
	check(style .. " destroy detaches", toggle.row.Parent == nil)
end
do
	local log = {}
	local toggle = createToggle(parent, "Damage numbers", "T4", true, function(v) table.insert(log, v) end)
	local group = toggle.row.Segments
	group.On.Activated:Fire()
	check("T4 choosing current half is a no-op", toggle.get() == true and #log == 0)
	group.Off.Activated:Fire()
	check("T4 choosing Off turns off", toggle.get() == false and log[1] == false)
	check("T4 indicator moved to Off", group.Indicator.Position.X.Scale == 0)
	group.On.Activated:Fire()
	check("T4 indicator moved to On", group.Indicator.Position.X.Scale == 0.5 and toggle.get() == true)
	check("T4 row not selectable", toggle.row.Selectable == false)
end
do
	local toggle = createToggle(parent, "Show ESP", "T6", false, function() end)
	check("T6 off shows eye-off icon", toggle.row.Badge.ImageLabel.Image == "rbxassetid://85207295981701")
	toggle.row.Activated:Fire()
	check("T6 on shows eye icon", toggle.row.Badge.ImageLabel.Image == "rbxassetid://127234874352422")
end
do
	local toggle = createToggle(parent, "Glow", "T5", false, function() end)
	check("T5 off says OFF", toggle.row.Status.Text == "OFF")
	toggle.row.Activated:Fire()
	check("T5 on says ON", toggle.row.Status.Text == "ON")
end
do
	local toggle = createToggle(parent, "Kill aura", "T7", false, function() end)
	local knob = toggle.row.Track.Knob
	check("T7 off shows a cross in the knob", knob.Mark.Image == "rbxassetid://116396312853810")
	toggle.row.Activated:Fire()
	check("T7 on shows a tick and moves the knob", knob.Mark.Image == "rbxassetid://86817768619372" and knob.Position.X.Offset == 23)
end
do
	local toggle = createToggle(parent, "Fly", "T8", false, function() end)
	local track = toggle.row.Track
	check("T8 off says OFF on the right", track.Word.Text == "OFF" and track.Word.Position.X.Offset == 24)
	toggle.row.Activated:Fire()
	check("T8 on says ON on the left, knob right", track.Word.Text == "ON" and track.Word.Position.X.Offset == 4 and track.Knob.Position.X.Offset == 35)
end
do
	local toggle = createToggle(parent, "Aimbot", "T9", false, function() end)
	check("T9 off says OFF", toggle.row.Status.Text == "OFF")
	toggle.row.Activated:Fire()
	check("T9 on says ON", toggle.row.Status.Text == "ON")
end
do
	local toggle = createToggle(parent, "Hitboxes", "T10", false, function() end)
	check("T10 tick hidden when off", toggle.row.Ring.Tick.ImageTransparency == 1)
	toggle.row.Activated:Fire()
	check("T10 tick shown when on", toggle.row.Ring.Tick.ImageTransparency == 0)
end
local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
