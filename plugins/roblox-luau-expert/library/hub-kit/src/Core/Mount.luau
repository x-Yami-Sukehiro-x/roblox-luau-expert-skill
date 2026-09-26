--[[
	Mount - the container every kit ScreenGui is parented to.

	An executor's gethui() returns a container the game's scripts cannot walk.
	Studio has no such function, so the kit falls back to PlayerGui there,
	which is also what makes the example testable without an executor.
--]]

local Players = game:GetService("Players")

local function mount(): Instance
	if typeof(gethui) == "function" then
		return gethui()
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

return mount
