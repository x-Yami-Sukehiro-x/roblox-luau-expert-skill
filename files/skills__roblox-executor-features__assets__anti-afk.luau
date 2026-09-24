-- Idled fires after two minutes without input and the kick comes at twenty; a
-- synthetic right click resets that timer. VirtualUser is LocalUser security:
-- it works from an executor and errors in a game's own LocalScript.
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.AntiAfk then
	features.AntiAfk.unload()
end

local afk = { alive = true }
local idled = Players.LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.zero)
end)

function afk.unload()
	afk.alive = false
	idled:Disconnect()
	if features.AntiAfk == afk then
		features.AntiAfk = nil
	end
end

features.AntiAfk = afk
