-- ====== HubKit behaviour ======
-- Runs after stubs.luau, stubs-extra.luau and `local function loadKit()`,
-- which wraps dist/HubKit.luau, so the file under test is the bundle an
-- executor runs. Each loadKit() is a fresh copy with fresh module state.

local pass, fail = 0, 0
local function check(label, ok, detail)
	if ok then
		pass += 1
	else
		fail += 1
		print(string.format("FAIL  %s   %s", label, detail or ""))
	end
end

local input = HARNESS.input
local function key(code, processed)
	input.InputBegan:Fire({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }, processed == true)
	input.InputEnded:Fire({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }, processed == true)
end
local function handlers(signal)
	return #signal.handlers
end
local function find(root, name)
	for _, child in root:GetDescendants() do
		if child.Name == name then
			return child
		end
	end
	return nil
end

-- A fake executor workspace folder.
local disk = {}
local function withFiles()
	writefile = function(path, text)
		disk[path] = text
	end
	readfile = function(path)
		return assert(disk[path], "harness: no file " .. path)
	end
	isfile = function(path)
		return disk[path] ~= nil
	end
	isfolder = function(path)
		return disk[path .. "/"] ~= nil
	end
	makefolder = function(path)
		disk[path .. "/"] = ""
	end
	delfile = function(path)
		disk[path] = nil
	end
	listfiles = function(folder)
		local list = {}
		for path in disk do
			if string.sub(path, 1, #folder + 1) == folder .. "/" and string.sub(path, -1) ~= "/" then
				table.insert(list, (string.gsub(path, "/", "\\")))
			end
		end
		return list
	end
end

local baseline = {
	began = handlers(input.InputBegan),
	changed = handlers(input.InputChanged),
	ended = handlers(input.InputEnded),
}

print("1. without file access: config saving reports itself off")
do
	local HubKit = loadKit()
	check("version string", type(HubKit.Version) == "string")
	check("CanSaveConfigs false without writefile", HubKit.CanSaveConfigs == false)
	local window = HubKit:CreateWindow({ Title = "Test Hub" })
	local ok, message = window.config:save("farming")
	check("save refuses", ok == false and string.find(message, "writefile", 1, true) ~= nil, message)
	local settings = window:SettingsTab()
	check("settings says saving is off", find(settings.frame, "Saving is off") ~= nil)
	check("window parented to PlayerGui without gethui", window.gui.Parent ~= nil and window.gui.Parent.ClassName == "PlayerGui")
	HubKit:Unload()
end

withFiles()
local hidden = Instance.new("Folder")
gethui = function()
	return hidden
end

print("2. window, tabs and elements")
local HubKit = loadKit()
check("CanSaveConfigs true with file access", HubKit.CanSaveConfigs == true)
local window = HubKit:CreateWindow({ Title = "Test Hub", Subtitle = "v1", Icon = "sparkles", Folder = "TestHub" })
check("window parented to gethui()", window.gui.Parent.ClassName == "Folder")
check("root sinks input", window.root.Active == true)
check("errors on a missing title", not pcall(function()
	HubKit:CreateWindow({})
end))

local main = window:Tab({ Title = "Main", Icon = "home" })
local other = window:Tab({ Title = "Other" })
check("first tab selected", window.selected == main and main.frame.Visible == true and other.frame.Visible == false)
other.button.Activated:Fire()
check("tab switch shows the page", other.frame.Visible == true and main.frame.Visible == false)
main:Select()

local log = {}
local fly = main:Toggle({ Title = "Fly", Description = "Hold space to rise", Flag = "Fly", Callback = function(on)
	table.insert(log, { "fly", on })
end })
check("toggle starts off", fly:Get() == false)
fly.Frame.Activated:Fire()
check("activation turns on and calls back", fly:Get() == true and log[#log][2] == true)
check("knob moved right", fly.Frame.Line.Slot.Track.Knob.Position.X.Offset > 10)
fly:Set(true)
check("Set with the same value still calls back", #log == 2)
check("flag registered", window.Flags.Fly == fly)

local defaultOn = {}
main:Toggle({ Title = "Anti AFK", Default = true, Callback = function(on)
	table.insert(defaultOn, on)
end })
check("Default = true defers its callback", #defaultOn == 0)
HARNESS.drain()
check("Default = true calls back once", #defaultOn == 1 and defaultOn[1] == true)

local speeds = {}
local speed = main:Slider({
	Title = "Walk speed",
	Min = 16,
	Max = 100,
	Default = 16,
	Step = 0.5,
	Suffix = "studs/s",
	Flag = "Speed",
	Callback = function(value)
		table.insert(speeds, value)
	end,
})
speed:Set(37.3)
check("slider snaps to step", speed:Get() == 37.5, tostring(speed:Get()))
speed:Set(500)
check("slider clamps to Max", speed:Get() == 100)
local box = speed.Frame.Line.Slot.Value
check("value box shows value and suffix", box.Text == "100.0 studs/s", box.Text)
box.Text = "20"
box.FocusLost:Fire(true)
check("typed value applies", speed:Get() == 20)
box.Text = "fast"
box.FocusLost:Fire(true)
check("non-number typed is rejected", speed:Get() == 20 and box.Text == "20.0 studs/s", box.Text)
local track = speed.Frame.Below.Track
track.SelectionGained:Fire()
local nudge
for name, binding in HARNESS.bound do
	if string.find(name, "HubKitSlider", 1, true) then
		nudge = binding
	end
end
check("selection binds arrow keys at high priority", nudge ~= nil and nudge.priority == 3000)
if nudge then
	local result = nudge.callback("x", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.DPadRight })
	check("D-pad right steps up and sinks", speed:Get() == 20.5 and result == Enum.ContextActionResult.Sink)
end
track.SelectionLost:Fire()
check("selection lost unbinds", (function()
	for name in HARNESS.bound do
		if string.find(name, "HubKitSlider", 1, true) then
			return false
		end
	end
	return true
end)())
local bar = track.Bar
bar.AbsolutePosition = { X = 100, Y = 0 }
bar.AbsoluteSize = { X = 200, Y = 6 }
track.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(200, 0, 0) })
check("press on the track jumps to that point", speed:Get() == 58, tostring(speed:Get()))
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(300, 0, 0) })
check("drag follows the mouse off the track", speed:Get() == 100)
input.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(100, 0, 0) })
check("release ends the drag", speed:Get() == 100)

print("3. dropdowns and popups")
local picks = {}
local target = main:Dropdown({
	Title = "Target",
	Values = { "Nearest", "Lowest health", "Random" },
	Default = "Nearest",
	Flag = "Target",
	Callback = function(value)
		table.insert(picks, value)
	end,
})
local summary = target.Frame.Line.Slot.Summary
check("summary shows the default", summary.Text == "Nearest")
target.Frame.Activated:Fire()
local popup = window.kit.popup
check("row opens a popup", popup ~= nil and popup.gui.DisplayOrder == 110)
local optionButton = find(popup.panel, "Random")
optionButton.Activated:Fire()
check("picking closes the popup and calls back", window.kit.popup == nil and picks[#picks] == "Random")
check("summary follows the pick", summary.Text == "Random")
target:Refresh({ "Nearest", "Lowest health" })
check("Refresh drops a value that left", target:Get() == nil and summary.Text == "None")

local multi = main:Dropdown({ Title = "Features", Values = { "A", "B", "C", "D" }, Multi = true, Flag = "Features" })
multi.Frame.Activated:Fire()
find(window.kit.popup.panel, "C").Activated:Fire()
find(window.kit.popup.panel, "A").Activated:Fire()
check("multi keeps the popup open", window.kit.popup ~= nil)
check("multi value follows list order", table.concat(multi:Get(), ",") == "A,C")
local scrim = find(window.kit.popup.gui, "Scrim")
scrim.Activated:Fire()
check("scrim closes the popup", window.kit.popup == nil)
multi.Frame.Activated:Fire()
HARNESS.bound.HubKitPopupClose.callback("x", Enum.UserInputState.Begin)
check("Escape closes the popup", window.kit.popup == nil)

local many = {}
for index = 1, 12 do
	table.insert(many, "Player" .. index)
end
local players = main:Dropdown({ Title = "Player", Values = many })
players.Frame.Activated:Fire()
local search = find(window.kit.popup.panel, "Search")
check("long lists get a search box", search.Visible == true)
search.Text = "player1"
local shown = 0
for _, option in find(window.kit.popup.panel, "Options"):GetChildren() do
	if option:IsA("GuiButton") and option.Visible then
		shown += 1
	end
end
check("search filters the options", shown == 4, tostring(shown))
window.kit.popup.close()

print("4. keybinds, inputs and colours")
local presses = 0
local flyKey = main:Keybind({ Title = "Fly key", Default = Enum.KeyCode.F, Flag = "FlyKey", Callback = function()
	presses += 1
end })
key(Enum.KeyCode.F)
check("bound key fires the callback", presses == 1)
key(Enum.KeyCode.F, true)
check("a key the game consumed does not", presses == 1)
flyKey.Frame.Activated:Fire()
check("listening stands window keys down", window.kit.capturing == true)
key(Enum.KeyCode.RightShift)
check("RightShift was captured, window stayed open", flyKey:Get() == Enum.KeyCode.RightShift and window.visible == true)
HARNESS.drain()
check("capturing ends after the press", window.kit.capturing == false)
flyKey.Frame.Activated:Fire()
key(Enum.KeyCode.Escape)
HARNESS.drain()
check("Escape cancels without clearing", flyKey:Get() == Enum.KeyCode.RightShift)
flyKey.Frame.Activated:Fire()
key(Enum.KeyCode.Backspace)
HARNESS.drain()
check("Backspace clears the bind", flyKey:Get() == nil)
flyKey:Set(Enum.KeyCode.G)

local typed = {}
local name = main:Input({ Title = "Teleport to", Placeholder = "Player name", Flag = "Name", Callback = function(text)
	table.insert(typed, text)
end })
local nameBox = name.Frame.Line.Slot.Box
nameBox.Text = "builderman"
nameBox.FocusLost:Fire(true)
check("input calls back when typing ends", typed[#typed] == "builderman")
local amount = main:Input({ Title = "Amount", Numeric = true })
amount.Frame.Line.Slot.Box.Text = "12abc"
amount.Frame.Line.Slot.Box.FocusLost:Fire(true)
check("numeric input rejects text", amount:Get() == nil and amount.Frame.Line.Slot.Box.Text == "")
amount:Set(42)
check("numeric input returns a number", amount:Get() == 42)

local colour = main:ColorPicker({ Title = "ESP colour", Default = Color3.fromRGB(255, 0, 0), Flag = "Colour" })
check("hex label shows the colour", colour.Frame.Line.Slot.Hex.Text == "#FF0000")
check("colour encodes as hex", colour.Encode(colour:Get()) == "FF0000")
colour.Frame.Activated:Fire()
local field = find(window.kit.popup.panel, "HexField")
field.Text = "#00ff80"
field.FocusLost:Fire(true)
check("typed hex applies", colour:Get() == Color3.fromRGB(0, 255, 128))
field.Text = "not a colour"
field.FocusLost:Fire(true)
check("bad hex is ignored", colour:Get() == Color3.fromRGB(0, 255, 128))
window.kit.popup.close()

print("5. search")
local section = main:Section({ Title = "Visuals" })
section:Toggle({ Title = "ESP", Description = "Outlines players" })
section:Button({ Title = "Clear highlights", Callback = function() end })
local searchBox = find(window.root, "Search")
searchBox.Text = "outlines"
check("search keeps the matching row", find(section.frame, "ESP").Visible == true)
check("search hides the rest", fly.Frame.Visible == false and find(section.frame, "Clear highlights").Visible == false)
searchBox.Text = "zzz"
check("empty state appears", main.empty.Visible == true and string.find(main.empty.Text, "zzz", 1, true) ~= nil)
check("a section with no matches hides", section.holder.Visible == false)
searchBox.Text = ""
check("clearing search restores rows", fly.Frame.Visible == true and main.empty.Visible == false)
section:SetCollapsed(true)
check("collapse hides the body", section.frame.Visible == false)
searchBox.Text = "esp"
check("search opens a collapsed section's matches", section.frame.Visible == true)
searchBox.Text = ""

print("6. configs")
local ok, message = window.config:save("farming")
check("save succeeds", ok, message)
check("file written under HubKit/TestHub", disk["HubKit/TestHub/farming.json"] ~= nil)
fly:Set(false)
speed:Set(16)
flyKey:Set(nil)
colour:Set(Color3.fromRGB(1, 2, 3))
local before = #log
ok, message = window.config:load("farming")
check("load succeeds", ok, message)
check("load restores values", fly:Get() == true and speed:Get() == 100 and flyKey:Get() == Enum.KeyCode.G)
check("load restores a colour from hex", colour:Get() == Color3.fromRGB(0, 255, 128))
check("load runs callbacks", #log > before)
check("list finds the save through backslashes", table.concat(window.config:list(), ",") == "farming")
disk["HubKit/TestHub/broken.json"] = "{not json"
ok = window.config:load("broken")
check("unreadable file is reported, not thrown", ok == false)
check("bad names are refused", window.config:save("../escape") == false)
check("setAutoload and autoload", window.config:setAutoload("farming") and window:LoadAutoload() == true)
check("delete removes the file", window.config:delete("farming") and disk["HubKit/TestHub/farming.json"] == nil)
check("duplicate flags are an error", not pcall(function()
	main:Toggle({ Title = "Fly again", Flag = "Fly" })
end))

print("7. themes")
local rootColour = window.root.BackgroundColor3
HubKit:SetTheme("Daylight")
check("theme switch recolours bound instances", window.root.BackgroundColor3 ~= rootColour)
check("unknown theme is an error", not pcall(function()
	HubKit:SetTheme("Nope")
end))
check("a theme missing a role is refused", not pcall(function()
	HubKit:AddTheme({ name = "Half", text = Color3.new(1, 1, 1) })
end))
HubKit:SetTheme("Midnight")
check("unknown icon is an error", not pcall(function()
	window:Tab({ Title = "Bad", Icon = "not-an-icon" })
end))

print("8. notifications")
HARNESS.drain()
table.clear(HARNESS.delays)
for index = 1, 6 do
	HubKit:Notify({ Title = "Notice " .. index, Content = "Body", Kind = "success", Duration = 0.2 })
end
-- The stubs index children by Name, so four frames named Toast read as one;
-- the kit's own list is the count.
local visible = #window.kit.toasts.visible
check("four toasts show at once", visible == 4, tostring(visible))
check("toasts live in the bottom-right stack", window.kit.toasts.stack.AnchorPoint.X == 1)
check("the rest wait", #window.kit.toasts.queue == 2)
check("hold is at least 1.5 s", HARNESS.delays[1] == 1.5, tostring(HARNESS.delays[1]))
HARNESS.drain()
check("queue drains as toasts leave", #window.kit.toasts.queue == 0)
check("unknown Kind falls back to info", pcall(function()
	HubKit:Notify({ Content = "x", Kind = "weird" })
end))

print("9. hiding, dragging and unload")
key(Enum.KeyCode.RightShift)
check("menu key hides the window", window.visible == false and window.root.Visible == false)
local chip = window.gui.Open
check("the open chip appears", chip.Visible == true)
chip.Activated:Fire()
check("the chip reopens the window", window.visible == true and window.root.Visible == true and chip.Visible == false)
key(Enum.KeyCode.RightShift, true)
check("a consumed menu key is ignored", window.visible == true)

window.gui.AbsoluteSize = { X = 800, Y = 600 }
window.root.AbsoluteSize = { X = 400, Y = 300 }
window.root.AbsolutePosition = { X = 200, Y = 150 }
window.root.Position = UDim2.new(0.5, 0, 0.5, 0)
local topbar = window.root.Topbar
topbar.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(300, 160, 0) })
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(900, 900, 0) })
input.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
check("drag is clamped to the screen", window.root.Position.X.Offset == 200 and window.root.Position.Y.Offset == 150,
	`{window.root.Position.X.Offset},{window.root.Position.Y.Offset}`)

window.root.AbsoluteSize = { X = 400, Y = 300 }
check("narrow window turns compact", window.compact == true and main.label.Visible == false)
window.root.AbsoluteSize = { X = 700, Y = 400 }
check("wide window shows labels", window.compact == false and main.label.Visible == true)

local unloaded = false
window.OnUnload:Connect(function()
	unloaded = true
end)
window.root.Topbar.Close.Activated:Fire()
local dialogGui
for _, child in window.gui.Parent:GetChildren() do
	if child.Name == "HubKitDialog" then
		dialogGui = child
	end
end
check("close asks first", dialogGui ~= nil and unloaded == false)
if dialogGui then
	find(dialogGui, "Keep open").Activated:Fire()
	check("Keep open leaves the window", unloaded == false and window.gui.Parent ~= nil)
end
window:ConfirmUnload()
for _, child in window.gui.Parent:GetChildren() do
	if child.Name == "HubKitDialog" then
		find(child, "Unload").Activated:Fire()
	end
end
check("Unload fires OnUnload", unloaded == true)
check("Unload removes the gui", window.gui.Parent == nil)
HubKit:Unload()
check("every input connection released", handlers(input.InputBegan) == baseline.began
	and handlers(input.InputChanged) == baseline.changed
	and handlers(input.InputEnded) == baseline.ended,
	`{handlers(input.InputBegan)}/{baseline.began} {handlers(input.InputChanged)}/{baseline.changed} {handlers(input.InputEnded)}/{baseline.ended}`)

print(string.format("%d passed, %d failed", pass, fail))
if fail > 0 then
	error(string.format("%d assertion(s) failed", fail))
end
