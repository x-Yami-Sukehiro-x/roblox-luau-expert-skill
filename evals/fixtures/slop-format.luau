local TweenService =
	game:GetService(
		"TweenService"
	)
local Players = game:GetService("Players")


local function buildPanel(parent: Instance)

	local frame = Instance.new(
		"Frame"
	)
	frame.Size = UDim2.fromOffset(
		320,
		180
	)
	frame.BackgroundColor3 = Color3.fromRGB(31,34,41)
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0)
	label.Text = "Ready"
	label.TextSize = 14
	label.BackgroundTransparency = 1
	label.Parent = frame
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(44, 44)
	button.Text = "Go"
	button.AutoButtonColor = false
	button.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	local tween = TweenService:Create(
		frame,
		TweenInfo.new(0.2),
		{ BackgroundTransparency = 0 }
	)
	tween:Play()

	return frame

end

return buildPanel
