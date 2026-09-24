local recipe = __recipe()
local createCheckbox, createCheckGroup = recipe.createCheckbox, recipe.createCheckGroup
local parent = Instance.new("Frame")
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

for _, style in { "C1", "C2", "C3", "C5", "C6", "C7", "C11", "C12", "C13", "C14" } do
	local log = {}
	local box = createCheckbox(parent, "Damage numbers " .. style, style, false, function(v) table.insert(log, v) end)
	check(style .. " starts unticked", box.get() == false)
	box.row.Activated:Fire()
	check(style .. " activation ticks", box.get() == true and log[1] == true)
	box.row.Activated:Fire()
	check(style .. " second activation unticks", box.get() == false and log[2] == false)
	box.row.SelectionGained:Fire()
	check(style .. " focus ring on selection", box.row.FocusRing.Enabled == true)
	box.row.MouseLeave:Fire()
	check(style .. " hover loss keeps focus", box.row.FocusRing.Enabled == true)
	box.setEnabled(false)
	box.row.Activated:Fire()
	check(style .. " disabled ignores activation", box.get() == false and #log == 2)
	box.destroy()
	check(style .. " destroy detaches", box.row.Parent == nil)
end

do
	local box = createCheckbox(parent, "Draw", "C1", false, function() end)
	check("C1 tick hidden behind a closed strip", box.row.Box.Reveal.Size.X.Offset == 0)
	box.row.Activated:Fire()
	check("C1 strip opens to 16 px", box.row.Box.Reveal.Size.X.Offset == 16 and box.row.Box.Reveal.ClipsDescendants == true)
end
do
	local box = createCheckbox(parent, "Outline", "C2", false, function() end)
	check("C2 box never fills", box.row.Box.BackgroundTransparency == 1 and box.row.Box.Tick.ImageTransparency == 1)
	box.row.Activated:Fire()
	check("C2 tick appears", box.row.Box.Tick.ImageTransparency == 0)
end
do
	local box = createCheckbox(parent, "Right", "C3", false, function() end)
	check("C3 box sits after the label", box.row.Box.LayoutOrder == 2 and box.row.Label.LayoutOrder == 1)
end
do
	local box = createCheckbox(parent, "Collect eggs", "C5", false, function() end)
	check("C5 plain text before ticking", box.row.Label.Text == "Collect eggs" and box.row.Label.RichText == true)
	box.row.Activated:Fire()
	check("C5 ticking strikes the words", box.row.Label.Text == "<s>Collect eggs</s>")
	box.row.Activated:Fire()
	check("C5 unticking restores them", box.row.Label.Text == "Collect eggs")
end
do
	local box = createCheckbox(parent, "Pop", "C6", false, function() end)
	box.row.Activated:Fire()
	check("C6 box fills and rests at full size", box.row.Box.UIStroke.Color == box.row.Box.BackgroundColor3 and box.row.Box.UIScale ~= nil)
end
do
	local box = createCheckbox(parent, "Hard mode", "C7", false, function() end, { description = "Enemies hit twice as hard" })
	check("C7 card is 64 tall with a description", box.row.Size.Y.Offset == 64 and box.row.Labels.Description.Text == "Enemies hit twice as hard")
	check("C7 badge tick hidden when off", box.row.Badge.Tick.ImageTransparency == 1)
	box.row.Activated:Fire()
	check("C7 badge ticks and edge lights", box.row.Badge.Tick.ImageTransparency == 0 and box.row.Edge.Color == box.row.Badge.BackgroundColor3)
end

do
	local picked = {}
	local group = createCheckGroup(parent, { "Common", "Rare", "Epic" }, "C4", {}, function(list) picked = list end)
	local header = group.frame.SelectAll
	header.Activated:Fire()
	check("C4 select all ticks every item", #group.selected() == 3 and #picked == 3 and header.Box.Tick.Image == "rbxassetid://86817768619372")
	group.frame.Rare.Activated:Fire()
	check("C4 some ticked shows a dash", #group.selected() == 2 and header.Box.Tick.Image == "rbxassetid://95070996149109")
	header.Activated:Fire()
	check("C4 select all from some ticks all", #group.selected() == 3)
	header.Activated:Fire()
	check("C4 select all from all clears", #group.selected() == 0 and header.Box.Tick.ImageTransparency == 1)
	check("C4 items are indented under the header", group.frame.Epic.UIPadding.PaddingLeft.Offset == 32)
	group.destroy()
	check("C4 destroy", group.frame.Parent == nil)
end
do
	local calls = 0
	local group = createCheckGroup(parent, { "Nearest", "Lowest HP", "Random" }, "C8", { "Nearest" }, function() calls += 1 end)
	check("C8 starts on the initial choice", group.selected()[1] == "Nearest" and group.frame.Nearest.Ring.Dot.BackgroundTransparency == 0)
	group.frame["Lowest HP"].Activated:Fire()
	check("C8 choosing moves the dot", #group.selected() == 1 and group.selected()[1] == "Lowest HP" and group.frame.Nearest.Ring.Dot.BackgroundTransparency == 1)
	group.frame["Lowest HP"].Activated:Fire()
	check("C8 choosing the current option is a no-op", calls == 1)
	group.set("Lowest HP", false)
	check("C8 cannot clear the only choice", group.selected()[1] == "Lowest HP")
end
do
	local group = createCheckGroup(parent, { "Wood", "Stone", "Gold" }, "C9", {}, function() end)
	check("C9 chips wrap", group.frame.UIListLayout.Wraps == true)
	check("C9 chip is a pill", group.frame.Gold.UICorner.CornerRadius.Scale == 0.5 and group.frame.Gold.Tick.Visible == false)
	group.frame.Gold.Activated:Fire()
	check("C9 tapping shows the tick", group.frame.Gold.Tick.Visible == true and group.selected()[1] == "Gold")
	group.frame.Gold.Activated:Fire()
	check("C9 tapping again clears it", group.frame.Gold.Tick.Visible == false and #group.selected() == 0)
end
do
	local group = createCheckGroup(parent, { "Sword", "Bow" }, "C10", { "Bow" }, function() end, { icons = { Sword = "rbxassetid://121406454377051" } })
	check("C10 named icon used", group.frame.Sword.Glyph.Image == "rbxassetid://121406454377051")
	check("C10 default icon for the rest", group.frame.Bow.Glyph.Image == "rbxassetid://106101842173393")
	check("C10 initial tile shows its badge", group.frame.Bow.Glyph.Badge.Visible == true and group.frame.Sword.Glyph.Badge.Visible == false)
	group.frame.Sword.Activated:Fire()
	check("C10 tile toggles independently", #group.selected() == 2)
end

do
	local box = createCheckbox(parent, "Right tick", "C11", false, function() end)
	check("C11 no box, tick hidden", box.row:FindFirstChild("Box") == nil and box.row.Tick.ImageTransparency == 1)
	box.row.Activated:Fire()
	check("C11 tick shown at the right", box.row.Tick.ImageTransparency == 0 and box.row.Tick.LayoutOrder == 2)
end
do
	local box = createCheckbox(parent, "Coins", "C12", false, function() end, { count = 12 })
	check("C12 shows the count", box.row.Count.Text == "12")
end
do
	local box = createCheckbox(parent, "Ignore team", "C13", false, function() end)
	box.row.Activated:Fire()
	check("C13 shows a cross when chosen", box.row.Box.Cross.ImageTransparency == 0)
end
do
	local box = createCheckbox(parent, "Big", "C14", false, function() end)
	check("C14 box is 32 px", box.row.Box.Size.X.Offset == 32)
end
do
	local log = {}
	local group = createCheckGroup(parent, { "Collect", "Sell", "Rebirth" }, "C15", {}, function(list) log = list end)
	check("C15 counts none done", group.frame.Progress.Summary.Text == "0 of 3 done")
	group.frame.Sell.Activated:Fire()
	check("C15 counts one done and fills a third", group.frame.Progress.Summary.Text == "1 of 3 done" and math.abs(group.frame.Progress.Bar.Fill.Size.X.Scale - 1 / 3) < 0.001 and #log == 1)
end
do
	local group = createCheckGroup(parent, { "Sword", "Bow", "Staff" }, "C16", { "Bow" }, function() end)
	local segments = group.frame.Track.Segments
	check("C16 chosen segment shows a tick", segments.Bow.Tick.Visible == true and segments.Sword.Tick.Visible == false)
	segments.Sword.Activated:Fire()
	check("C16 picks several", #group.selected() == 2)
end
do
	local picked
	local group = createCheckGroup(parent, { "1", "2", "3", "4", "5" }, "C17", {}, function(list) picked = list[1] end)
	group.frame["4"].Activated:Fire()
	check("C17 rating is one value", picked == "4" and #group.selected() == 1)
	group.frame["2"].Activated:Fire()
	check("C17 lower rating replaces it", picked == "2" and group.selected()[1] == "2")
end
do
	local group = createCheckGroup(parent, { "Red", "Blue" }, "C18", { "Red" }, function() end)
	check("C18 chosen dot has a ring", group.frame.Red.Ring.Enabled == true and group.frame.Blue.Ring.Enabled == false)
	group.frame.Blue.Activated:Fire()
	check("C18 one colour at a time", group.selected()[1] == "Blue" and #group.selected() == 1)
end
do
	local group = createCheckGroup(parent, { "S", "M", "L" }, "C19", { "M" }, function() end)
	local marker = group.frame.Track.Marker
	check("C19 marker under M", marker.Position.X.Offset == 64)
	group.frame.Track.Segments.L.Activated:Fire()
	check("C19 marker moves to L", marker.Position.X.Offset == 128 and group.selected()[1] == "L")
end
do
	local group = createCheckGroup(parent, { "Free", "VIP" }, "C20", { "Free" }, function() end, { descriptions = { VIP = "Double coins" } })
	check("C20 cards show descriptions", group.frame.VIP.Labels.Description.Text == "Double coins")
	group.frame.VIP.Activated:Fire()
	check("C20 one plan at a time", group.selected()[1] == "VIP" and #group.selected() == 1)
end
local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
