local TweenService = game:GetService("TweenService")

local function openPanel(panel)
    -- LT2 rebuilds the dragger between drags, so the panel must reparent first.
    -- Create the tween info for the panel.
    -- Then play the tween on the panel.
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    local tween = TweenService:Create(panel, tweenInfo, { GroupTransparency = 0 })
    tween:Play()
end

return openPanel
