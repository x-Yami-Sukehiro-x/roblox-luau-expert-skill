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

-- Geometry the engine would compute: vectors that subtract, a 1280x720 screen.
local vmeta = {}
vmeta.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y }, vmeta) end
vmeta.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y }, vmeta) end
Vector2.new = function(x, y) return setmetatable({ X = x, Y = y }, vmeta) end
Vector2.zero = Vector2.new(0, 0)
local rawNew = Instance.new
Instance.new = function(className)
	local inst = rawNew(className)
	inst.AbsolutePosition = Vector2.new(0, 0)
	inst.AbsoluteSize = if className == "ScreenGui" then Vector2.new(1280, 720) else Vector2.new(320, 44)
	if className == "ScreenGui" then inst.DisplayOrder = 0 end
	return inst
end

local function signal() return rawNew("Folder").Activated end
local Players = game:GetService("Players")
local others = {}
Players.LocalPlayer = { Name = "Me", DisplayName = "Me", UserId = 1 }
Players.GetPlayers = function()
	local list = { Players.LocalPlayer }
	for _, player in others do table.insert(list, player) end
	return list
end
Players.PlayerAdded = signal()
Players.PlayerRemoving = signal()

local createDropdown = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local function scene()
	local playerGui = Instance.new("Folder")
	local screen = Instance.new("ScreenGui")
	screen.Parent = playerGui
	local page = Instance.new("Frame")
	page.Parent = screen
	return playerGui, page
end

local function count(folder, name)
	local total = 0
	for _, child in folder:GetChildren() do
		if child.Name == name or (name == nil and child.ClassName == "TextButton") then total += 1 end
	end
	return total
end

local TARGETS = { "Nearest", "Lowest HP", "Random" }

do
	local playerGui, page = scene()
	local log = {}
	local dropdown = createDropdown(page, "D1", { label = "Target", options = TARGETS, onChanged = function(list) table.insert(log, list) end })
	local field = dropdown.root.Field
	check("D1 empty field shows its label", field.Value.Text == "Target")
	field.AbsolutePosition = Vector2.new(100, 600)
	field.Activated:Fire()
	local layer = playerGui.DropdownLayer
	local list = layer.Catcher.List
	check("D1 opens on its own layer above the host", layer.Enabled == true and layer.DisplayOrder == 1 and list.Visible)
	check("D1 lists every option", count(list.Rows) == 3 and field.Chevron.Rotation == 180)
	check("D1 flips above the field when there is no room below", list.Position.Y.Offset == 600 - 140 - 4)
	list.Rows.Random.Activated:Fire()
	check("D1 choosing reports and fills the field", log[1][1] == "Random" and field.Value.Text == "Random")
	HARNESS.drain()
	check("D1 closes after a choice", list.Visible == false and layer.Enabled == false)
	field.Activated:Fire()
	check("D1 marks the chosen row", list.Rows.Random.Tick ~= nil)
	layer.Catcher.Activated:Fire()
	HARNESS.drain()
	check("D1 a tap outside closes without choosing", list.Visible == false and #log == 1)
	field.Activated:Fire()
	HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape })
	HARNESS.drain()
	check("D1 Escape closes", list.Visible == false)
	dropdown.destroy()
	check("D1 destroy removes the layer", playerGui.DropdownLayer == nil and dropdown.root.Parent == nil)
end

do
	local playerGui, page = scene()
	local picked
	local dropdown = createDropdown(page, "D2", { label = "Search targets", options = TARGETS, onChanged = function(list) picked = list[1] end })
	local box = dropdown.root.Field.Search
	box.Text = "lo"
	local rows = playerGui.DropdownLayer.Catcher.List.Rows
	check("D2 typing opens and filters", count(rows) == 1 and rows["Lowest HP"] ~= nil)
	box.FocusLost:Fire(true)
	check("D2 Enter picks the first match", picked == "Lowest HP")
	box.Text = "zzz"
	check("D2 no match says so", rows.Empty ~= nil and rows.Empty.Text == "No matches")
	dropdown.destroy()
end

do
	local playerGui, page = scene()
	local last
	local dropdown = createDropdown(page, "D3", { label = "Rarities", options = { "Common", "Rare", "Epic" }, onChanged = function(list) last = list end })
	dropdown.root.Field.Activated:Fire()
	local list = playerGui.DropdownLayer.Catcher.List
	list.Rows.Rare.Activated:Fire()
	list.Rows.Epic.Activated:Fire()
	check("D3 several can be chosen", #last == 2 and dropdown.root.Field.Value.Text == "2 selected")
	check("D3 stays open while choosing", list.Visible == true and list.Rows.Epic.Box.Tick.ImageTransparency == 0)
	list.Rows.Rare.Activated:Fire()
	check("D3 choosing again removes it", #last == 1 and dropdown.root.Field.Value.Text == "Epic")
end

do
	local playerGui, page = scene()
	local dropdown = createDropdown(page, "D4", { label = "Auto sell", options = { "Wood", "Stone", "Gold" }, onChanged = function() end })
	local chips = dropdown.root.Field.Chips
	check("D4 shows its label while empty", chips.Placeholder ~= nil)
	dropdown.root.Field.Activated:Fire()
	local rows = playerGui.DropdownLayer.Catcher.List.Rows
	rows.Wood.Activated:Fire()
	rows.Gold.Activated:Fire()
	check("D4 one chip per choice", chips.Wood ~= nil and chips.Gold ~= nil and chips.Stone == nil and chips.Placeholder == nil)
end

do
	local playerGui, page = scene()
	local picked
	local dropdown = createDropdown(page, "D5", { label = "Search features", options = { "Teleport", "Fly", "Walk speed", "Trade" }, onChanged = function(list) picked = list[1] end })
	local box = dropdown.root.Field.Search
	check("D5 closed until something is typed", playerGui:FindFirstChild("DropdownLayer") == nil or playerGui.DropdownLayer.Enabled == false)
	box.Text = "t"
	local rows = playerGui.DropdownLayer.Catcher.List.Rows
	check("D5 suggestions appear while typing", count(rows) == 2 and rows.Teleport ~= nil and rows.Trade ~= nil)
	rows.Trade.Activated:Fire()
	check("D5 a suggestion fills the box and reports", picked == "Trade" and box.Text == "Trade")
	box.Text = ""
	HARNESS.drain()
	check("D5 clearing the box hides suggestions", playerGui.DropdownLayer.Catcher.List.Visible == false)
end

do
	local _, page = scene()
	local dropdown = createDropdown(page, "D6", { label = "Quality", options = { "Low", "High" }, onChanged = function() end })
	dropdown.root.Field.Activated:Fire()
	check("D6 opens in place, pushing what is below", dropdown.root.List.Visible == true and dropdown.root.List.LayoutOrder == 2)
	dropdown.root.List.Rows.High.Activated:Fire()
	HARNESS.drain()
	check("D6 closes after a choice", dropdown.root.List.Visible == false and dropdown.get()[1] == "High")
end

do
	local _, page = scene()
	local dropdown = createDropdown(page, "D7", { label = "Target", options = TARGETS, chosen = { "Nearest" }, onChanged = function() end })
	local field = dropdown.root.Field
	field.Next.Activated:Fire()
	check("D7 next steps forward", dropdown.get()[1] == "Lowest HP" and field.Value.Text == "Lowest HP")
	field.Previous.Activated:Fire()
	field.Previous.Activated:Fire()
	check("D7 previous wraps to the end", dropdown.get()[1] == "Random")
	check("D7 arrows are touch sized", field.Next.Size.X.Offset == 44)
end

do
	local playerGui, page = scene()
	local options = {
		{ text = "Spawn", group = "Places" },
		{ text = "Shop", group = "Places" },
		{ text = "Nearest player", group = "Players" },
	}
	local dropdown = createDropdown(page, "D8", { label = "Teleport to", options = options, onChanged = function() end })
	dropdown.root.Field.Activated:Fire()
	local rows = playerGui.DropdownLayer.Catcher.List.Rows
	check("D8 sections have headings", rows.PLACES ~= nil and rows.PLAYERS ~= nil and count(rows) == 3)
end

do
	local _, page = scene()
	local sword = "rbxassetid://121406454377051"
	local dropdown = createDropdown(page, "D9", { label = "Weapon", options = { { text = "Sword", icon = sword }, { text = "Bow" } }, onChanged = function() end })
	check("D9 no icon until something is chosen", dropdown.root.Field.Lead.Visible == false)
	dropdown.set({ "Sword" })
	check("D9 the field shows the chosen icon", dropdown.root.Field.Lead.Visible == true and dropdown.root.Field.Lead.Image == sword)
end

do
	others = { { Name = "Bob", DisplayName = "Bobby", UserId = 2 }, { Name = "alice", DisplayName = "Ali", UserId = 3 } }
	local playerGui, page = scene()
	local last = {}
	local dropdown = createDropdown(page, "D10", { label = "Player", options = {}, onChanged = function(list) last = list end })
	dropdown.root.Field.Activated:Fire()
	local rows = playerGui.DropdownLayer.Catcher.List.Rows
	check("D10 lists other players, not you", count(rows) == 2 and rows.Me == nil)
	check("D10 rows show display name, username and headshot", rows.Bob.Label.Text == "Bobby" and rows.Bob.Detail.Text == "@Bob" and rows.Bob.Icon.Image == "rbxthumb://type=AvatarHeadShot&id=2&w=48&h=48")
	rows.Bob.Activated:Fire()
	check("D10 choosing reports the unique username", last[1] == "Bob" and dropdown.root.Field.Value.Text == "Bobby")
	local bob = others[1]
	table.remove(others, 1)
	Players.PlayerRemoving:Fire(bob)
	HARNESS.drain()
	check("D10 a chosen player who leaves is cleared", #last == 0 and #dropdown.get() == 0)
	table.insert(others, { Name = "Cara", DisplayName = "Cara", UserId = 4 })
	Players.PlayerAdded:Fire(others[2])
	dropdown.open()
	check("D10 a player who joins appears", playerGui.DropdownLayer.Catcher.List.Rows.Cara ~= nil)
	dropdown.destroy()
	others = {}
end

do
	local playerGui, page = scene()
	local ran
	local actions = { "Teleport to spawn", "Toggle fly", "Rejoin server" }
	local dropdown = createDropdown(page, "D11", { label = "Search features", options = actions, onChanged = function(list) ran = list[1] end })
	dropdown.root.Field.Activated:Fire()
	local list = playerGui.DropdownLayer.Catcher.List
	local box = list.SearchRow.Search
	check("D11 palette opens with the cursor in its search box", list.Visible and box.focused == true and list.AnchorPoint.X == 0.5)
	box.Text = "fly"
	check("D11 typing narrows the actions", count(list.Rows) == 1)
	box.FocusLost:Fire(true)
	HARNESS.drain()
	check("D11 Enter runs the first action and closes", ran == "Toggle fly" and list.Visible == false and box.Text == "")
end

do
	local _, page = scene()
	local purple = Color3.fromRGB(140, 90, 220)
	local dropdown = createDropdown(page, "D12", { label = "Theme", options = { { text = "Purple", colour = purple }, { text = "Green" } }, chosen = { "Purple" }, onChanged = function() end })
	check("D12 the field shows the chosen colour", dropdown.root.Field.Swatch.BackgroundColor3 == purple)
end

local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
