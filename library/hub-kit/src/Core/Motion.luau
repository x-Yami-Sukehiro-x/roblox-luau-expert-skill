--[[
	Motion - three timings for the whole kit, and the reduced-motion switch.

	Entrances ease out over 0.2 s, exits ease in over 0.15 s, and state changes
	(hover, press, on and off) take 0.12 s. With the player's Reduce Motion
	setting on, every change lands in one frame instead.

	`onDone` waits for PlaybackState.Completed. A newer tween on the same
	property stops this one and still fires Completed, and acting on that
	would hide a window the player has just reopened.
--]]

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Motion = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	state = TweenInfo.new(0.12, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}

function Motion.play(
	instance: Instance,
	info: TweenInfo,
	goals: { [string]: any },
	onDone: (() -> ())?
)
	if GuiService.ReducedMotionEnabled then
		for property, value in goals do
			instance[property] = value
		end
		if onDone then
			onDone()
		end
		return
	end

	local tween = TweenService:Create(instance, info, goals)
	if onDone then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				onDone()
			end
		end)
	end
	tween:Play()
end

return Motion
