local notices = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

do
	local form = Instance.new("Frame")
	local inline = notices.createInlineMessage(form, 3)
	local slot = form.InlineMessage
	check("N3 slot reserved before any message", slot.Size.Y.Offset == 20 and slot.GroupTransparency == 1)
	inline.show("Name is taken", "error")
	check("N3 shows message with icon", slot.GroupTransparency == 0 and slot.Text.Text == "Name is taken" and slot.Icon.Image == "rbxassetid://106305483906363")
	inline.show("Saved", "success")
	check("N3 replaces message", slot.Text.Text == "Saved")
	inline.clear()
	check("N3 clears", slot.GroupTransparency == 1)
	inline.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local banner = notices.createBanner(screen)
	local strip = screen.Banner
	check("N5 hidden until shown", strip.Visible == false)
	banner.show("Reconnecting to the server", "warning")
	check("N5 shows", strip.Visible == true and strip.GroupTransparency == 0 and strip.Text.Text == "Reconnecting to the server")
	strip.Dismiss.Activated:Fire()
	check("N5 dismiss hides", strip.Visible == false)
	banner.show("Reconnecting to the server", "warning")
	banner.hide()
	banner.show("Back online", "success")
	check("N5 show after hide stays visible", strip.Visible == true)
	banner.destroy()
end

do
	local screen = Instance.new("ScreenGui")
	local choice = nil
	notices.confirmAlert(screen, { title = "Reset your progress?", body = "Your coins and pets go back to zero.", confirmText = "Reset progress", cancelText = "Keep progress" }, function(confirmed) choice = confirmed end)
	local dialog, scrim = screen.Alert, screen.AlertScrim
	check("N6 dialog is a sibling of the dim layer", dialog.Parent == screen and scrim.Parent == screen and dialog.Active == true)
	check("N6 buttons named for their action", dialog.Actions["Reset progress"] ~= nil and dialog.Actions["Keep progress"] ~= nil)
	dialog.Actions["Reset progress"].Activated:Fire()
	check("N6 confirm reports true", choice == true)
	scrim.Activated:Fire()
	check("N6 answers once", choice == true)
end

do
	local screen = Instance.new("ScreenGui")
	local choice = nil
	notices.confirmAlert(screen, { title = "Leave the match?", body = "You lose this round.", confirmText = "Leave match", cancelText = "Stay" }, function(confirmed) choice = confirmed end)
	screen.AlertScrim.Activated:Fire()
	check("N6 tap outside cancels", choice == false)
end

do
	local screen = Instance.new("ScreenGui")
	local capsule = notices.createCapsule(screen)
	local pill = screen.Capsule
	check("N8 hidden until shown", pill.Visible == false)
	capsule.show("Config saved", "success")
	check("N8 shows one line with its icon", pill.Visible == true and pill.GroupTransparency == 0 and pill.Text.Text == "Config saved" and pill.Icon.Image == "rbxassetid://88244323237265")
	capsule.show("Rejoining server", "info")
	check("N8 replaces rather than stacks", pill.Text.Text == "Rejoining server")
	HARNESS.drain()
	check("N8 leaves after reading time, only for the latest message", pill.Visible == false)
	capsule.destroy()
end

local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
