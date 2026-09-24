local createToggle = __recipe()
local parent = Instance.new("Frame")
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
for _, style in { "T1", "T2", "T3", "T5", "T6", "T7", "T8", "T9", "T10", "T11", "T12", "T13", "T14", "T15", "T16", "T17", "T18", "T19", "T20" } do
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
do
	local toggle = createToggle(parent, "Rail", "T11", false, function() end)
	local knob = toggle.row.Track.Knob
	check("T11 knob overhangs the rail when off", knob.Position.X.Offset == -3)
	toggle.row.Activated:Fire()
	check("T11 knob travels to the far end", knob.Position.X.Offset == 19)
end
do
	local toggle = createToggle(parent, "Outline", "T12", false, function() end)
	local track = toggle.row.Track
	check("T12 track is hollow", track.BackgroundTransparency == 1)
	toggle.row.Activated:Fire()
	check("T12 knob moves and outline lights", track.Knob.Position.X.Offset == 25 and track.UIStroke.Color == track.Knob.BackgroundColor3)
end
do
	local toggle = createToggle(parent, "Big", "T13", false, function() end)
	check("T13 track is thumb sized", toggle.row.Track.Size.X.Offset == 56 and toggle.row.Track.Size.Y.Offset == 32)
	toggle.row.Activated:Fire()
	check("T13 knob reaches 27", toggle.row.Track.Knob.Position.X.Offset == 27)
end
do
	local toggle = createToggle(parent, "Chip", "T14", false, function() end)
	check("T14 row is a pill", toggle.row.UICorner.CornerRadius.Scale == 0.5)
	check("T14 tick hidden when off", toggle.row.Tick.Visible == false)
	toggle.row.Activated:Fire()
	check("T14 tick shown and edge lit when on", toggle.row.Tick.Visible == true and toggle.row.Edge.Enabled == true)
end
do
	local toggle = createToggle(parent, "Power", "T15", false, function() end)
	check("T15 off says OFF beside the button", toggle.row.Status.Text == "OFF" and toggle.row.Power.Glyph.Image == "rbxassetid://89331085993646")
	toggle.row.Activated:Fire()
	check("T15 on says ON", toggle.row.Status.Text == "ON")
end
do
	local toggle = createToggle(parent, "Stretch", "T16", false, function() end)
	toggle.row.Activated:Fire()
	local knob = toggle.row.Track.Knob
	check("T16 knob arrives round at 23", knob.Position.X.Offset == 23 and knob.Size.X.Offset == 18)
end
do
	local toggle = createToggle(parent, "Icons", "T17", false, function() end)
	local track = toggle.row.Track
	check("T17 both marks live in the track", track.Yes.Image == "rbxassetid://86817768619372" and track.No.Image == "rbxassetid://116396312853810")
	toggle.row.Activated:Fire()
	check("T17 knob covers the cross when on", track.Knob.Position.X.Offset == 31)
end
do
	local toggle = createToggle(parent, "Key", "T18", false, function() end)
	local cap = toggle.row.Key.Cap
	check("T18 key up and OFF", cap.Text == "OFF" and cap.Position.Y.Offset == 0)
	toggle.row.Activated:Fire()
	check("T18 key sinks and says ON", cap.Text == "ON" and cap.Position.Y.Offset == 3)
end
do
	local toggle = createToggle(parent, "Auto farm", "T19", false, function() end, { description = "Collects drops near you" })
	check("T19 row grows to 56", toggle.row.Size.Y.Offset == 56)
	check("T19 label and description stack", toggle.row.Labels.Label.Text == "Auto farm" and toggle.row.Labels.Description.Text == "Collects drops near you")
	toggle.row.Activated:Fire()
	check("T19 switch still works", toggle.get() == true and toggle.row.Track.Knob.Position.X.Offset == 23)
end
do
	local toggle = createToggle(parent, "Speed", "T20", false, function() end)
	check("T20 default lead icon", toggle.row.Lead.Image == "rbxassetid://109718589733073")
	local custom = createToggle(parent, "Fly", "T20", false, function() end, { icon = "rbxassetid://103991922506350" })
	check("T20 custom lead icon", custom.row.Lead.Image == "rbxassetid://103991922506350")
	custom.row.Activated:Fire()
	check("T20 switch moves", custom.row.Track.Knob.Position.X.Offset == 23)
end
local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
