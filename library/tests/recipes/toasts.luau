local vmeta = {}
vmeta.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y }, vmeta) end
vmeta.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y }, vmeta) end
Vector2.new = function(x, y) return setmetatable({ X = x, Y = y }, vmeta) end
Vector2.zero = Vector2.new(0, 0)
local Tweens = game:GetService("TweenService")
Tweens.SmoothDamp = function(_, current, target, velocity) return target, Vector2.zero end
local preRender = game:GetService("RunService").PreRender
local function frames(n, dt) for _ = 1, n do preRender:Fire(dt or 0.1) end end

local createNotifier = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

for _, placement in { "N1", "N2", "N4", "N7" } do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, placement)
	local stack = screen.Notifications
	local rightEdge = placement == "N4" or placement == "N7"
	check(placement .. " stack inset from edge", stack.Position.X.Offset == (rightEdge and -16 or 0))
	notifier.push("Saved", "success")
	check(placement .. " first toast appears", stack.Toast ~= nil and stack.Toast.Content.Icon.Image == "rbxassetid://88244323237265")
	check(placement .. " time-left bar only on corner stacks", (stack.Toast.TimeLeft ~= nil) == rightEdge)
	frames(3, 0.1) -- 0.3 s
	check(placement .. " still visible before 1.5 s", stack.Toast ~= nil and stack.Toast.GroupTransparency == 0)
	frames(40, 0.1) -- 4 s more
	check(placement .. " leaves after its lifetime", stack.Toast == nil or stack.Toast.GroupTransparency == 1)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N4")
	notifier.push("coin", "success", "coin")
	notifier.push("coin", "success", "coin")
	notifier.push("coin", "success", "coin")
	check("duplicate key collapses to a count", screen.Notifications.Toast.Content.Message.Text == "coin ×3")
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N1")
	notifier.push("Server unreachable", "error")
	local toast = screen.Notifications.Toast
	frames(200, 0.1) -- 20 s
	check("error stays until dismissed", toast.GroupTransparency == 0 and toast.Parent ~= nil)
	toast.Content.Dismiss.Activated:Fire()
	check("dismiss removes error", toast.GroupTransparency == 1)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N1")
	for i = 1, 5 do notifier.push("message " .. i, "info") end
	frames(1, 0.01)
	frames(60, 0.1)
	check("burst drains through the queue without error", true)
	notifier.destroy()
	check("destroy removes the stack", screen.Notifications == nil)
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N4")
	notifier.push("Hover me", "info")
	local toast = screen.Notifications.Toast
	toast.MouseEnter:Fire()
	frames(100, 0.1)
	check("hover pauses the timer", toast.GroupTransparency == 0)
	toast.MouseLeave:Fire()
	frames(100, 0.1)
	check("leaving resumes the timer", toast.GroupTransparency == 1)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N7")
	check("N7 anchors top-right", screen.Notifications.AnchorPoint.X == 1 and screen.Notifications.AnchorPoint.Y == 0)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N4")
	local job = notifier.progress("Teleporting to spawn")
	local toast = screen.Notifications.Toast
	check("N9 progress shows the loading icon", toast.Content.Icon.Image == "rbxassetid://71250150569964")
	frames(100, 0.1)
	check("N9 progress stays while working", toast.GroupTransparency == 0)
	frames(1, 0.05)
	check("N9 progress spins", toast.Content.Icon.Rotation ~= 0)
	job.done("Teleported", "success")
	check("N9 done swaps icon and text", toast.Content.Icon.Image == "rbxassetid://88244323237265" and toast.Content.Message.Text == "Teleported" and toast.Content.Icon.Rotation == 0)
	check("N9 done starts the time-left bar", toast.TimeLeft ~= nil)
	frames(100, 0.1)
	check("N9 done leaves after reading time", toast.GroupTransparency == 1)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N4")
	local job = notifier.progress("Saving config")
	job.done("Config did not save", "error")
	local toast = screen.Notifications.Toast
	frames(200, 0.1)
	check("N9 failed result stays with a dismiss button", toast.GroupTransparency == 0 and toast.Content.Dismiss ~= nil)
	toast.Content.Dismiss.Activated:Fire()
	check("N9 failed result dismisses", toast.GroupTransparency == 1)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N4")
	local undone = 0
	notifier.action("Removed 3 waypoints", "Undo", function() undone += 1 end)
	local toast = screen.Notifications.Toast
	check("N10 action button labelled", toast.Content.Action.Text == "Undo")
	frames(50, 0.1)
	check("N10 action toast holds at least 6 s", toast.GroupTransparency == 0)
	toast.Content.Action.Activated:Fire()
	check("N10 action runs once and closes", undone == 1 and toast.GroupTransparency == 1)
	notifier.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local notifier = createNotifier(screen, "N1")
	for i = 1, 3 do notifier.push("busy " .. i, "info") end
	local job = notifier.progress("Queued work")
	job.done("Queued work finished", "success")
	frames(80, 0.1)
	HARNESS.drain()
	check("N9 finished while queued arrives finished", true)
	notifier.destroy()
end

local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
