local TOAST_DURATION = 0.4

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addFlexFill(parent)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = parent
end

local screen = Instance.new("ScreenGui")
screen.Name = "Menu"
screen.Parent = game.Players.LocalPlayer.PlayerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(300, 136)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.ClipsDescendants = true
panel.Parent = screen
addCorner(panel, 10)

local stripe = Instance.new("Frame")
stripe.Size = UDim2.new(1, 0, 0, 3)
stripe.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
stripe.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.6, 1)
title.TextSize = 15
title.TextScaled = true
title.TextYAlignment = Enum.TextYAlignment.Top
title.Parent = panel
addFlexFill(title)

local row = Instance.new("UIListLayout")
row.FillDirection = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding = UDim.new(0, 7)
row.Parent = panel

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 0)
pad.PaddingLeft = UDim.new(0, 0)
pad.Parent = title

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 24)
close.Text = "\u{00D7}"
close.Parent = panel
addCorner(close, 4)

close.MouseButton1Click:Connect(function()
	screen.Enabled = false
end)

local badge = Instance.new("ImageLabel")
badge.Image = "rbxassetid://1234567890"
badge.Parent = panel

wait(TOAST_DURATION)
