local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local part = Instance.new("Part")
part.GravityScale = 2
Players.LocalPlayer.Character:SetSuperJump(10)
local info = TweenInfo.new(0.2, Enum.EasingStyle.Smooth)
TweenService:CreateTweenNow(part, info, {})
