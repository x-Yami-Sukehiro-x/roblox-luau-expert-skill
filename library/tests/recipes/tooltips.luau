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

-- Geometry the engine would compute on a 1280x720 screen.
local rawNew = Instance.new
Instance.new = function(className)
	local inst = rawNew(className)
	inst.AbsolutePosition = Vector2.new(0, 0)
	inst.AbsoluteSize = if className == "ScreenGui" then Vector2.new(1280, 720) else Vector2.new(120, 32)
	if className == "ScreenGui" then inst.DisplayOrder = 0 end
	return inst
end

local UserInputService = game:GetService("UserInputService")
local lastInput = Enum.UserInputType.MouseMovement
UserInputService.GetLastInputType = function() return lastInput end

local tips = __recipe()
local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local function scene()
	local playerGui = Instance.new("Folder")
	local screen = Instance.new("ScreenGui")
	screen.Parent = playerGui
	local button = Instance.new("TextButton")
	button.AbsolutePosition = Vector2.new(400, 300)
	button.AbsoluteSize = Vector2.new(160, 44)
	button.Parent = screen
	return playerGui, button
end

do
	local playerGui, button = scene()
	local tip = tips.createTooltip(button, "H1", { text = "Collects drops within 30 studs" })
	local layer = playerGui.TooltipLayer
	local bubble = layer.Bubble
	check("H1 lives on its own layer above the host", layer.DisplayOrder == 2 and bubble.Visible == false)
	button.MouseEnter:Fire(450, 310)
	check("H1 waits before showing", bubble.Visible == false)
	HARNESS.drain()
	check("H1 shows below the control after the delay", bubble.Visible == true and bubble.Position.Y.Offset == 300 + 44 + 8)
	button.MouseLeave:Fire()
	HARNESS.drain()
	check("H1 leaving hides it", bubble.Visible == false)
	button.MouseEnter:Fire(450, 310)
	button.MouseLeave:Fire()
	HARNESS.drain()
	check("H1 passing over never shows it", bubble.Visible == false)
	button.SelectionGained:Fire()
	check("H1 keyboard focus shows it at once", bubble.Visible == true)
	button.SelectionLost:Fire()
	HARNESS.drain()
	tip.setText("Now 40 studs")
	check("H1 text can change", bubble.Line.Text.Text == "Now 40 studs")
	tip.destroy()
	check("H1 destroy removes the layer", playerGui:FindFirstChild("TooltipLayer") == nil)
end

do
	local playerGui, button = scene()
	tips.createTooltip(button, "H1", { text = "Auto farm" })
	lastInput = Enum.UserInputType.Touch
	button.MouseEnter:Fire(450, 310)
	HARNESS.drain()
	local bubble = playerGui.TooltipLayer.Bubble
	check("H1 a tap's fake hover does not open it", bubble.Visible == false)
	button.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch })
	HARNESS.drain()
	check("H1 a long press opens it on a phone", bubble.Visible == true)
	lastInput = Enum.UserInputType.MouseMovement
end

do
	local playerGui, button = scene()
	local tip = tips.createTooltip(button, "H2", { text = "Teleports you to spawn" })
	tip.show()
	local layer = playerGui.TooltipLayer
	check("H2 sits above the control with an arrow", layer.Bubble.Position.Y.Offset == 300 - 32 - 8 and layer.Arrow.Visible == true)
	tip.hide()
	HARNESS.drain()
	check("H2 the arrow leaves with it", layer.Arrow.Visible == false)
end

do
	local playerGui, button = scene()
	button.AbsolutePosition = Vector2.new(400, 690)
	local tip = tips.createTooltip(button, "H1", { text = "Near the bottom" })
	tip.show()
	check("H1 flips above when there is no room below", playerGui.TooltipLayer.Bubble.Position.Y.Offset == 690 - 32 - 8)
end

do
	local playerGui, button = scene()
	button.AbsolutePosition = Vector2.new(1250, 300)
	local tip = tips.createTooltip(button, "H1", { text = "At the right edge" })
	tip.show()
	check("H1 never crosses the side edge", playerGui.TooltipLayer.Bubble.Position.X.Offset == 1280 - 120 - 8)
end

do
	local playerGui, button = scene()
	local tip = tips.createTooltip(button, "H7", { text = "Flies where the camera looks", title = "Fly", keyHint = "F" })
	tip.show()
	local bubble = playerGui.TooltipLayer.Bubble
	check("H7 title, words and key", bubble.Title.Text == "Fly" and bubble.Line.Text.Text == "Flies where the camera looks" and bubble.Key.Text == "F")
	check("H7 words under a title are smaller", bubble.Line.Text.TextSize == 12)
end

do
	local playerGui, button = scene()
	tips.createTooltip(button, "H8", { text = "Follows me" })
	button.MouseEnter:Fire(430, 310)
	HARNESS.drain()
	local bubble = playerGui.TooltipLayer.Bubble
	check("H8 appears beside the pointer", bubble.Position.X.Offset == 446 and bubble.Position.Y.Offset == 326)
	button.MouseMoved:Fire(500, 320)
	check("H8 follows the pointer", bubble.Position.X.Offset == 516)
end

do
	local playerGui, button = scene()
	local tip = tips.createTooltip(button, "H9", { text = "Unlocks at level 10" })
	local layer = playerGui.TooltipLayer
	tip.show()
	check("H9 says nothing while the control works", layer.Bubble.Visible == false and layer.ReasonCatcher.Visible == false)
	tip.setDisabled(true)
	check("H9 covers the disabled control", layer.ReasonCatcher.Visible == true and layer.ReasonCatcher.Position.X.Offset == 400)
	layer.ReasonCatcher.Activated:Fire()
	check("H9 a tap explains why, with a lock", layer.Bubble.Visible == true and layer.Bubble.Line.Lock ~= nil)
	tip.setDisabled(false)
	HARNESS.drain()
	check("H9 enabling removes the reason", layer.Bubble.Visible == false and layer.ReasonCatcher.Visible == false)
end

do
	local playerGui, button = scene()
	tips.createTooltip(button, "H10", { text = "Held" })
	local bubble = playerGui.TooltipLayer.Bubble
	button.MouseEnter:Fire(430, 310)
	HARNESS.drain()
	check("H10 hover alone shows nothing", bubble.Visible == false)
	button.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	HARNESS.drain()
	check("H10 holding shows it", bubble.Visible == true)
	button.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	HARNESS.drain()
	check("H10 letting go hides it", bubble.Visible == false)
end

do
	local playerGui, button = scene()
	local track = Instance.new("Frame")
	track.Parent = button
	local thumb = Instance.new("Frame")
	thumb.AbsolutePosition = Vector2.new(500, 300)
	thumb.AbsoluteSize = Vector2.new(16, 16)
	thumb.Parent = track
	local slider = tips.createSliderValue({ track = track, thumb = thumb, min = 16, max = 100, format = function(v) return `{math.floor(v)} speed` end }, "H3")
	local bubble = playerGui.TooltipLayer.Bubble
	slider.update(40)
	check("H3 hidden until dragged", bubble.Visible == false)
	slider.setDragging(true)
	check("H3 shows the value over the thumb while dragging", bubble.Visible == true and bubble.Line.Text.Text == "40 speed" and bubble.Position.X.Offset == 508 and bubble.Position.Y.Offset == 292)
	slider.update(500)
	check("H3 clamps to the range", bubble.Line.Text.Text == "100 speed")
	slider.setDragging(false)
	HARNESS.drain()
	check("H3 hides when the drag ends", bubble.Visible == false)
end

do
	local _, button = scene()
	local track = Instance.new("Frame")
	track.Parent = button
	local thumb = Instance.new("Frame")
	thumb.Parent = track
	local slider = tips.createSliderValue({ track = track, thumb = thumb, min = 0, max = 10 }, "H4")
	slider.update(7)
	check("H4 the value rides on the thumb", thumb.ValueTag.Text == "7")
	local ends = tips.createSliderValue({ track = track, thumb = thumb, min = 0, max = 100 }, "H5")
	ends.update(42)
	check("H5 the ends under the track and the value after it", track.Min.Text == "0" and track.Max.Text == "100" and track.Value.Text == "42")
	ends.destroy()
	check("H5 destroy removes its labels", track:FindFirstChild("Min") == nil)
end

do
	local playerGui, button = scene()
	local row = Instance.new("Frame")
	row.Parent = button.Parent
	local info = tips.createInfoButton(row, "Chance to hatch a shiny pet", 3)
	local layer = playerGui.TooltipLayer
	check("H6 a 44 px target", info.button.Size.X.Offset == 44 and info.button.LayoutOrder == 3)
	info.button.Activated:Fire()
	check("H6 a tap opens the words", layer.Bubble.Visible == true and layer.Catcher.Visible == true)
	layer.Catcher.Activated:Fire()
	HARNESS.drain()
	check("H6 a tap anywhere else closes them", layer.Bubble.Visible == false and layer.Catcher.Visible == false)
	info.button.Activated:Fire()
	HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape })
	HARNESS.drain()
	check("H6 Escape closes them", layer.Bubble.Visible == false)
	info.destroy()
end

do
	local form = Instance.new("Frame")
	local help = tips.createHelperText(form, "3 to 20 letters", 2)
	check("H11 helper line under the field", form.Help.LayoutOrder == 2 and form.Help.Text.Text == "3 to 20 letters" and form.Help.Alert.Visible == false)
	help.setError("That name is taken")
	check("H11 turns into the error with an icon", form.Help.Text.Text == "That name is taken" and form.Help.Alert.Visible == true)
	help.setError(nil)
	check("H11 back to the hint", form.Help.Text.Text == "3 to 20 letters" and form.Help.Alert.Visible == false)
end

do
	local playerGui, button = scene()
	local done = 0
	local dismiss = tips.showCoachMark(button, "New: auto sell is here", function() done += 1 end)
	local layer = playerGui.TooltipLayer
	check("H12 rings the new thing and explains it", layer.Ring.Position.X.Offset == 396 and layer.Bubble.Visible == true and layer.Bubble.GotIt.Text == "Got it")
	layer.Bubble.GotIt.Activated:Fire()
	check("H12 Got it closes it once", done == 1 and playerGui:FindFirstChild("TooltipLayer") == nil)
	dismiss()
	check("H12 dismiss twice is harmless", done == 1)
end

local failed = 0
for _, line in results do print(line) if line:sub(1,4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
