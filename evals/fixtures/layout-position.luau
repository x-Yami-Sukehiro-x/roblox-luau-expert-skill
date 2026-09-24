local TweenService = game:GetService("TweenService")

local THEME = {
	raised = Color3.fromRGB(44, 48, 57),
}

local screen = Instance.new("ScreenGui")
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

local stack = Instance.new("Frame")
stack.Name = "Notifications"
stack.Size = UDim2.fromOffset(300, 240)
stack.BackgroundTransparency = 1
stack.Parent = screen

local bounds = Instance.new("UISizeConstraint")
bounds.MinSize = Vector2.new(240, 0)
bounds.MaxSize = Vector2.new(360, 480)
bounds.Parent = stack

local column = Instance.new("UIListLayout")
column.SortOrder = Enum.SortOrder.LayoutOrder
column.Padding = UDim.new(0, 8)
column.Parent = stack

local card = Instance.new("CanvasGroup")
card.LayoutOrder = 1
card.Size = UDim2.new(1, 0, 0, 60)
card.BackgroundColor3 = THEME.raised
card.Parent = stack
card.Position = UDim2.fromOffset(24, 0)
TweenService:Create(card, TweenInfo.new(0.2), { Position = UDim2.fromOffset(0, 0) }):Play()
