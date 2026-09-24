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

local notices = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

do
	local screen = Instance.new("ScreenGui")
	local dismiss = notices.showAchievement(screen, "First win", "Win one round")
	local card = screen.Achievement
	check("N15 card arrives under the top edge", card.GroupTransparency == 0 and card.Position.Y.Offset == 16)
	check("N15 title, detail and default trophy", card.Content.Words.Title.Text == "First win" and card.Content.Words.Detail.Text == "Win one round" and card.Content.Tile.Glyph.Image == "rbxassetid://113055182645565")
	check("N15 light sweeps across once", card.Shine.Position.X.Scale == 1 and card.Shine.Visible == true)
	dismiss()
	check("N15 dismiss fades it", card.GroupTransparency == 1)
	HARNESS.drain()
	check("N15 card removed after fading", card.Parent == nil)
	dismiss()
	check("N15 dismiss twice is harmless", true)
end
do
	local screen = Instance.new("ScreenGui")
	local custom = "rbxassetid://97534791863003"
	notices.showAchievement(screen, "Collector", "Own 10 pets", custom)
	check("N15 custom icon", screen.Achievement.Content.Tile.Glyph.Image == custom)
	HARNESS.drain()
end
do
	game:GetService("GuiService").ReducedMotionEnabled = true
	local screen = Instance.new("ScreenGui")
	notices.showAchievement(screen, "Quiet", "No travel")
	check("N15 reduced motion: no sweep", screen.Achievement.Shine.Visible == false)
	HARNESS.drain()
	game:GetService("GuiService").ReducedMotionEnabled = false
end
do
	local screen = Instance.new("ScreenGui")
	local announcer = notices.createAnnouncer(screen)
	announcer.show("Round starting")
	local words = screen.Announcement
	check("N16 words appear in the middle", words.Visible and words.TextTransparency == 0 and words.Text == "Round starting")
	check("N16 words carry a dark edge", words.UIStroke.Transparency == 0 and words.TextSize == 28)
	announcer.show("Round 2")
	check("N16 a new line replaces the old", words.Text == "Round 2")
	HARNESS.drain()
	check("N16 fades out after its hold", words.TextTransparency == 1 and words.Visible == false)
	announcer.destroy()
end
do
	local screen = Instance.new("ScreenGui")
	local snackbar = notices.createSnackbar(screen)
	local undone = 0
	snackbar.show("Removed 3 waypoints", "Undo", function() undone += 1 end)
	local bar = screen.Snackbar
	check("N18 bar shows with its action", bar.Visible and bar.GroupTransparency == 0 and bar.Action.Visible and bar.Action.Text == "Undo")
	bar.Action.Activated:Fire()
	check("N18 action runs once and hides", undone == 1 and bar.GroupTransparency == 1)
	bar.Action.Activated:Fire()
	check("N18 a second press does nothing", undone == 1)
	snackbar.show("Settings saved")
	check("N18 no action, no button", bar.Action.Visible == false and bar.Message.Text == "Settings saved")
	HARNESS.drain()
	check("N18 hides after its hold", bar.Visible == false)
	snackbar.destroy()
end
do
	local lines = {}
	local rawNew = Instance.new
	Instance.new = function(className)
		local inst = rawNew(className)
		if className == "CanvasGroup" then table.insert(lines, inst) end
		return inst
	end
	local screen = rawNew("ScreenGui")
	local feed = notices.createFeed(screen)
	for index = 1, 7 do feed.push("Player" .. index .. " joined", "info") end
	Instance.new = rawNew
	check("N20 seven lines built", #lines == 7)
	check("N20 the oldest leaves when a seventh arrives", lines[1].GroupTransparency == 1 and lines[7].GroupTransparency == 0)
	check("N20 newest sits last", lines[7].LayoutOrder > lines[6].LayoutOrder)
	HARNESS.drain()
	check("N20 every line fades after its hold", lines[7].Parent == nil and lines[2].Parent == nil)
	feed.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local island = notices.createIsland(screen)
	island.show("Auto farm on", "Collecting within 30 studs")
	local pill = screen.Island
	check("N23 shows only the short line at first", pill.Content.Short.Text == "Auto farm on" and pill.Content.Detail.Visible == false)
	pill.Hit.MouseEnter:Fire()
	check("N23 hovering opens the detail", pill.Content.Detail.Visible == true)
	pill.Hit.MouseLeave:Fire()
	check("N23 leaving closes it", pill.Content.Detail.Visible == false)
	pill.Hit.Activated:Fire()
	check("N23 a tap opens it on a phone", pill.Content.Detail.Visible == true)
	island.destroy()
end
do
	local screen = Instance.new("ScreenGui")
	local button = Instance.new("TextButton")
	button.Parent = screen
	button.AbsolutePosition = { X = 100, Y = 200 }
	button.AbsoluteSize = { X = 80, Y = 44 }
	screen.AbsolutePosition = { X = 0, Y = 0 }
	notices.floatText(button, "+250", "rbxassetid://117341212186115")
	local reward = screen.Reward
	check("N25 rises from above the anchor", reward.Position.X.Offset == 140 and reward.Position.Y.Offset == 160)
	check("N25 fades while it rises", reward.Amount.TextTransparency == 1 and reward.Icon ~= nil)
	HARNESS.drain()
	check("N25 cleans itself up", reward.Parent == nil)
end
do
	local screen = Instance.new("ScreenGui")
	local objectives = notices.createObjectives(screen)
	objectives.complete("Collect 10 eggs")
	local card = screen.Objective
	check("N26 slides in at the right edge", card.Visible == true and card.Position.X.Offset == -16 and card.GroupTransparency == 0)
	check("N26 says what was done", card.Words.Step.Text == "Collect 10 eggs" and card.Tick ~= nil)
	objectives.destroy()
end
do
	local screen = Instance.new("ScreenGui")
	local inbox = notices.createInbox(screen)
	check("N27 no badge while empty", screen.Inbox.Badge.Visible == false)
	inbox.push("Bob sent a trade")
	inbox.push("Daily reward ready")
	check("N27 badge counts unread", screen.Inbox.Badge.Visible == true and screen.Inbox.Badge.Text == "2" and inbox.unread() == 2)
	screen.Inbox.Activated:Fire()
	check("N27 opening lists newest first and marks read", screen.Messages.Visible == true and screen.Messages.Message1.Text == "Daily reward ready" and inbox.unread() == 0)
	screen.Inbox.Activated:Fire()
	check("N27 the bell closes the list again", screen.Messages.Visible == false)
	inbox.destroy()
end
do
	local screen = Instance.new("ScreenGui")
	local captions = notices.createCaptions(screen)
	captions.say("The gate opens at dawn.", "Guard")
	local strip = screen.Caption
	check("N29 speaker first, then the line", strip.Speaker.Text == "Guard" and strip.Line.Text == "The gate opens at dawn." and strip.Visible == true)
	captions.say("Hurry.")
	check("N29 no speaker hides the name", strip.Speaker.Visible == false)
	captions.destroy()
end
do
	local screen = Instance.new("ScreenGui")
	notices.flashEdges(screen)
	local flash = screen.EdgeFlash
	check("N30 all four edges light", flash.Top ~= nil and flash.Bottom ~= nil and flash.Left ~= nil and flash.Right ~= nil and flash.Top.BackgroundTransparency < 1)
	HARNESS.drain()
	HARNESS.drain()
	check("N30 fades and removes itself", flash.Parent == nil)
end
local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
