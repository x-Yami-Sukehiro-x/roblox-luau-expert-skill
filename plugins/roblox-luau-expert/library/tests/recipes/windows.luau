local vmeta = {}
vmeta.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y }, vmeta) end
vmeta.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y }, vmeta) end
vmeta.__div = function(a, n) return setmetatable({ X = a.X / n, Y = a.Y / n }, vmeta) end
vmeta.__mul = function(a, b) return setmetatable({ X = a.X * b.X, Y = a.Y * b.Y }, vmeta) end
Vector2.new = function(x, y) return setmetatable({ X = x, Y = y }, vmeta) end
local umeta = {}
umeta.__add = function(a, b) return setmetatable({ X = { Scale = a.X.Scale + b.X.Scale, Offset = a.X.Offset + b.X.Offset }, Y = { Scale = a.Y.Scale + b.Y.Scale, Offset = a.Y.Offset + b.Y.Offset } }, umeta) end
umeta.__sub = function(a, b) return setmetatable({ X = { Scale = a.X.Scale - b.X.Scale, Offset = a.X.Offset - b.X.Offset }, Y = { Scale = a.Y.Scale - b.Y.Scale, Offset = a.Y.Offset - b.Y.Offset } }, umeta) end
local rawUDim2 = UDim2.new
UDim2.new = function(...) return setmetatable(rawUDim2(...), umeta) end
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end
UDim2.fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end
Enum.HorizontalAlignment = Enum.HorizontalAlignment or { Center = "HorizontalAlignment.Center" }

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
	function tween:Cancel()
		if tween.cancelled then return end
		tween.cancelled = true
		task.defer(function() for _, fn in tween.handlers do fn(Enum.PlaybackState.Cancelled) end end)
	end
	return tween
end

local windows = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local function scene()
	local screen = Instance.new("ScreenGui")
	local panel = Instance.new("CanvasGroup")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(0, 360, 0, 420)
	panel.AbsolutePosition = Vector2.new(400, 200)
	panel.AbsoluteSize = Vector2.new(360, 420)
	panel.Visible = true
	panel.GroupTransparency = 0
	panel.Parent = screen
	local launcher = Instance.new("TextButton")
	launcher.Name = "Launcher"
	launcher.AbsolutePosition = Vector2.new(16, 600)
	launcher.AbsoluteSize = Vector2.new(72, 44)
	launcher.Parent = screen
	return screen, panel, launcher
end

do
	local _, panel, launcher = scene()
	local window = windows.createWindow({ panel = panel, launcher = launcher }, "O1")
	check("O1 launcher hidden while open", launcher.Visible == false)
	window.hide()
	check("O1 close hides panel and shows launcher", panel.Visible == false and launcher.Visible == true)
	launcher.Activated:Fire()
	check("O1 launcher reopens", panel.Visible == true and launcher.Visible == false and window.isShown())
	window.destroy()
end

do
	local _, panel, launcher = scene()
	local calls = {}
	local opener = { open = function() table.insert(calls, "open") end, close = function() table.insert(calls, "close") end }
	local window = windows.createWindow({ panel = panel, launcher = launcher, opener = opener }, "O1")
	window.toggle()
	window.toggle()
	check("O1 hands movement to the chosen presenter", calls[1] == "close" and calls[2] == "open")
	window.destroy()
end

do
	local _, panel, launcher = scene()
	local window = windows.createWindow({ panel = panel, launcher = launcher }, "O2")
	window.hide()
	check("O2 shrinks toward the launcher", panel.WindowScale.Scale == 0.2 and panel.Position.X.Offset == 52 - 580)
	HARNESS.drain()
	check("O2 hidden with launcher shown, position restored", panel.Visible == false and launcher.Visible == true and panel.Position.X.Offset == 0)
	window.show()
	HARNESS.drain()
	check("O2 grows back to its place", panel.Visible == true and panel.WindowScale.Scale == 1 and panel.Position.X.Offset == 0 and launcher.Visible == false)
	window.hide()
	window.show()
	HARNESS.drain()
	check("O2 reopen during minimise stays open", panel.Visible == true and window.isShown())
	window.destroy()
end

do
	local _, panel = scene()
	local header = Instance.new("Frame")
	header.AbsoluteSize = Vector2.new(360, 44)
	local body = Instance.new("CanvasGroup")
	body.Visible = true
	local window = windows.createWindow({ panel = panel, header = header, body = body }, "O3")
	window.hide()
	HARNESS.drain()
	check("O3 folds to the title bar", panel.Size.Y.Offset == 68 and body.Visible == false and panel.Visible == true)
	window.show()
	HARNESS.drain()
	check("O3 unfolds to full height", panel.Size.Y.Offset == 420 and body.Visible == true and body.GroupTransparency == 0)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O4")
	local tab = screen.EdgeTab
	check("O4 creates a hidden pull tab", tab ~= nil and tab.Visible == false and tab.Size.X.Offset == 44)
	window.hide()
	HARNESS.drain()
	check("O4 slides away and shows the tab", panel.Visible == false and tab.Visible == true)
	tab.Activated:Fire()
	HARNESS.drain()
	check("O4 tab brings it back", panel.Visible == true and tab.Visible == false and panel.Position.X.Offset == 0)
	window.destroy()
	check("O4 destroy removes the tab", screen.EdgeTab == nil)
end

do
	local screen = Instance.new("ScreenGui")
	local done = 0
	windows.playIntro(screen, "Blox Hub", function() done += 1 end)
	check("O5 intro card shows the title", screen.Intro ~= nil and screen.Intro.Title.Text == "Blox Hub")
	HARNESS.drain()
	check("O5 intro ends once and cleans up", done == 1 and screen.Intro == nil)
	local skipped = 0
	local skip = windows.playIntro(screen, "Blox Hub", function() skipped += 1 end)
	skip()
	HARNESS.drain()
	check("O5 skip ends at once, only once", skipped == 1)
end

local v3meta = {}
v3meta.__sub = function(a, b)
	local x, y = a.X - b.X, a.Y - b.Y
	return { X = x, Y = y, Z = 0, Magnitude = math.sqrt(x * x + y * y) }
end
local function point(x, y) return setmetatable({ X = x, Y = y, Z = 0 }, v3meta) end
local mouse = Enum.UserInputType.MouseButton1

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O6")
	local bubble = screen.Bubble
	check("O6 bubble waits hidden at the window's corner", bubble.Visible == false and bubble.Position.X.Offset == 426 and bubble.Position.Y.Offset == 226)
	bubble.AbsolutePosition = Vector2.new(400, 200)
	bubble.AbsoluteSize = Vector2.new(52, 52)
	window.hide()
	check("O6 window shrinks into the bubble", panel.WindowScale.Scale == 0.2)
	HARNESS.drain()
	check("O6 bubble shown once the window is gone", panel.Visible == false and bubble.Visible == true)
	bubble.InputBegan:Fire({ UserInputType = mouse, Position = point(0, 0) })
	HARNESS.input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = point(30, 4) })
	check("O6 dragging moves the bubble", bubble.Position.X.Offset == 456 and bubble.Position.Y.Offset == 230)
	bubble.Activated:Fire()
	HARNESS.input.InputEnded:Fire({ UserInputType = mouse })
	check("O6 releasing a drag does not reopen", window.isShown() == false)
	bubble.InputBegan:Fire({ UserInputType = mouse, Position = point(10, 10) })
	HARNESS.input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = point(12, 11) })
	bubble.Activated:Fire()
	HARNESS.drain()
	check("O6 a tap brings the window back", window.isShown() and panel.Visible == true and bubble.Visible == false)
	window.destroy()
	check("O6 destroy removes the bubble", screen.Bubble == nil)
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O7")
	local tab = screen.EdgeTab
	check("O7 tab sits on the right edge", tab.AnchorPoint.X == 1 and tab.Position.X.Scale == 1)
	window.hide()
	check("O7 window slides off to the right", panel.Position.X.Offset == 384)
	HARNESS.drain()
	check("O7 tab shown", tab.Visible == true and panel.Visible == false)
	tab.Activated:Fire()
	HARNESS.drain()
	check("O7 tab brings it back", panel.Visible == true and panel.Position.X.Offset == 0)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O8")
	local tab = screen.PullTab
	check("O8 pull tab at the top centre", tab.AnchorPoint.Y == 0 and tab.Position.X.Scale == 0.5 and tab.Size.Y.Offset == 44)
	window.hide()
	check("O8 window slides up and away", panel.Position.Y.Offset == -444)
	HARNESS.drain()
	tab.Activated:Fire()
	HARNESS.drain()
	check("O8 pull tab brings it down", panel.Visible == true and panel.Position.Y.Offset == 0 and tab.Visible == false)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel, title = "Blox Hub" }, "O9")
	window.hide()
	HARNESS.drain()
	local pill = screen.TitlePill
	check("O9 pill carries the title where the window was", pill.Visible and pill.Caption.Text == "Blox Hub" and pill.Position.X.Offset == 400 and pill.Position.Y.Offset == 200)
	pill.Activated:Fire()
	check("O9 pill reopens", window.isShown() and panel.Visible == true and pill.Visible == false)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel, keyName = "K" }, "O10")
	window.hide()
	HARNESS.drain()
	local chip = screen.KeyChip
	check("O10 chip names the key", chip.Visible and chip.Caption.Text == "Show menu · K")
	check("O10 chip folds to its icon after a while", chip.Caption.Visible == false and chip.Visible == true)
	chip.Activated:Fire()
	check("O10 chip reopens", window.isShown() and chip.Visible == false)
	window.destroy()
end

do
	local _, panel = scene()
	check("O11 needs an unload handler", not pcall(windows.createWindow, { panel = panel }, "O11"))
end

do
	local screen, panel, launcher = scene()
	local unloaded = 0
	local window = windows.createWindow({ panel = panel, launcher = launcher, onUnload = function() unloaded += 1 end }, "O11")
	local ask = screen.Ask
	window.hide()
	check("O11 closing asks first", ask.Visible == true and window.isShown() and panel.Visible == true)
	ask.Choices.Hide.Activated:Fire()
	check("O11 Hide hides and shows the launcher", window.isShown() == false and panel.Visible == false and launcher.Visible == true)
	launcher.Activated:Fire()
	window.hide()
	ask.Choices["Unload script"].Activated:Fire()
	check("O11 Unload runs the handler once", unloaded == 1)
	HARNESS.drain()
	ask.Visible = false
	window.show()
	window.toggle()
	check("O11 the keybind hides without asking", ask.Visible == false and window.isShown() == false)
	window.destroy()
	check("O11 destroy removes the question", screen.Ask == nil)
end

do
	local screen = Instance.new("ScreenGui")
	local done = 0
	windows.playOutro(screen, "Blox Hub closed", function() done += 1 end)
	check("O12 goodbye card shows", screen.Outro ~= nil and screen.Outro.Title.Text == "Blox Hub closed")
	HARNESS.drain()
	check("O12 ends once and cleans up", done == 1 and screen.Outro == nil)
end

Enum.KeyCode.FromName = Enum.KeyCode.FromName or function(_, name) return Enum.KeyCode[name] end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O13")
	local tab = screen.PullTab
	check("O13 pull tab at the bottom centre", tab.AnchorPoint.Y == 1 and tab.Position.Y.Scale == 1)
	window.hide()
	check("O13 window slides down and away", panel.Position.Y.Offset == 444)
	HARNESS.drain()
	check("O13 tab shown", tab.Visible == true and panel.Visible == false)
	tab.Activated:Fire()
	HARNESS.drain()
	check("O13 tab brings it back", panel.Visible == true and panel.Position.Y.Offset == 0)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O14")
	local icon = screen.Dock.DockIcon
	check("O14 makes a dock with this window's icon", icon ~= nil and icon.Visible == false)
	icon.AbsolutePosition = Vector2.new(600, 660)
	icon.AbsoluteSize = Vector2.new(44, 44)
	window.hide()
	check("O14 window shrinks into its dock icon", panel.WindowScale.Scale == 0.2)
	HARNESS.drain()
	check("O14 icon shown once the window is gone", panel.Visible == false and icon.Visible == true)
	icon.Activated:Fire()
	HARNESS.drain()
	check("O14 the icon brings it back", panel.Visible == true and icon.Visible == false)
	window.destroy()
	check("O14 destroy removes the dock it made", screen.Dock == nil)
end

do
	local screen, panel = scene()
	local shared = Instance.new("Frame")
	shared.Name = "SharedDock"
	shared.Parent = screen
	local window = windows.createWindow({ panel = panel, dock = shared }, "O14")
	check("O14 uses the dock it is given", shared.DockIcon ~= nil and screen:FindFirstChild("Dock") == nil)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O15")
	window.hide()
	check("O15 window stays but goes faint and ignores clicks", panel.Visible == true and panel.GroupTransparency == 0.8 and panel.Interactable == false)
	check("O15 a button to make it solid appears at its corner", screen.Solid.Visible == true and screen.Solid.Position.X.Offset == 400)
	screen.Solid.Activated:Fire()
	check("O15 solid again", panel.GroupTransparency == 0 and panel.Interactable == true and screen.Solid.Visible == false)
	window.destroy()
end

do
	local screen, panel = scene()
	local rail = Instance.new("Frame")
	rail.AbsoluteSize = Vector2.new(140, 420)
	local body = Instance.new("CanvasGroup")
	body.Visible = true
	local window = windows.createWindow({ panel = panel, rail = rail, body = body }, "O16")
	window.hide()
	HARNESS.drain()
	check("O16 folds to the tab rail", panel.Size.X.Offset == 140 and body.Visible == false and panel.Visible == true)
	check("O16 an expand button sits beside the rail", screen.Expand.Visible == true and screen.Expand.Position.X.Offset == 548)
	screen.Expand.Activated:Fire()
	HARNESS.drain()
	check("O16 expands to full width", panel.Size.X.Offset == 360 and body.Visible == true and screen.Expand.Visible == false)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O17")
	window.hide()
	check("O17 hidden until held", panel.Visible == false and screen.Peek.Visible == true)
	HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.LeftAlt, UserInputType = Enum.UserInputType.Keyboard })
	check("O17 holding the key shows it", panel.Visible == true)
	HARNESS.input.InputEnded:Fire({ KeyCode = Enum.KeyCode.LeftAlt, UserInputType = Enum.UserInputType.Keyboard })
	check("O17 letting go hides it", panel.Visible == false)
	screen.Peek.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch })
	check("O17 holding the button shows it on a phone", panel.Visible == true)
	screen.Peek.InputEnded:Fire({ UserInputType = Enum.UserInputType.Touch })
	check("O17 releasing the button hides it", panel.Visible == false)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O18")
	local corner = screen.Corner
	check("O18 round button waits in the corner", corner.AnchorPoint.X == 1 and corner.AnchorPoint.Y == 1 and corner.Visible == false)
	corner.AbsolutePosition = Vector2.new(1200, 640)
	corner.AbsoluteSize = Vector2.new(56, 56)
	window.hide()
	check("O18 window shrinks into the corner button", panel.WindowScale.Scale == 0.2)
	HARNESS.drain()
	corner.Activated:Fire()
	HARNESS.drain()
	check("O18 the button grows it back", panel.Visible == true and corner.Visible == false)
	window.destroy()
end

do
	local screen, panel = scene()
	local header = Instance.new("Frame")
	header.Parent = panel
	local window = windows.createWindow({ panel = panel, header = header }, "O19")
	header.InputBegan:Fire({ UserInputType = mouse, Position = point(100, 0) })
	HARNESS.input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = point(160, 0) })
	check("O19 the window follows the drag", panel.Position.X.Offset == 60)
	HARNESS.input.InputEnded:Fire({ UserInputType = mouse, Position = point(160, 0) })
	check("O19 a short drag springs back", panel.Position.X.Offset == 0 and window.isShown())
	header.InputBegan:Fire({ UserInputType = mouse, Position = point(100, 0) })
	HARNESS.input.InputEnded:Fire({ UserInputType = mouse, Position = point(260, 0) })
	HARNESS.drain()
	check("O19 a long swipe right hides it to the right", panel.Visible == false and screen.EdgeTab.Visible == true and screen.EdgeTab.AnchorPoint.X == 1)
	screen.EdgeTab.Activated:Fire()
	HARNESS.drain()
	check("O19 the tab brings it back", panel.Visible == true and panel.Position.X.Offset == 0)
	window.destroy()
end

do
	local screen, panel = scene()
	local window = windows.createWindow({ panel = panel }, "O20")
	window.hide()
	HARNESS.drain()
	check("O20 fades away when idle", panel.Visible == false)
	HARNESS.input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = point(1, 1) })
	check("O20 any input brings it back", panel.Visible == true and window.isShown())
	window.destroy()
end

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
