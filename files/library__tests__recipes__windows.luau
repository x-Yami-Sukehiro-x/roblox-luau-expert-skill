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

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
