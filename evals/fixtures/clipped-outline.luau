local THEME = {
	base = Color3.fromRGB(19, 21, 26),
	raised = Color3.fromRGB(31, 34, 41),
	border = Color3.fromRGB(44, 48, 57),
}

local screen = Instance.new("ScreenGui")
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(520, 420)
panel.BackgroundColor3 = THEME.base
panel.Parent = screen

local bounds = Instance.new("UISizeConstraint")
bounds.MinSize = Vector2.new(360, 320)
bounds.MaxSize = Vector2.new(640, 480)
bounds.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.fromScale(1, 1)
list.BackgroundTransparency = 1
list.Parent = panel

local rows = Instance.new("UIListLayout")
rows.SortOrder = Enum.SortOrder.LayoutOrder
rows.Padding = UDim.new(0, 8)
rows.Parent = list

local row = Instance.new("Frame")
row.LayoutOrder = 1
row.Size = UDim2.new(1, 0, 0, 44)
row.BackgroundColor3 = THEME.raised
row.Parent = list

local outline = Instance.new("UIStroke")
outline.Color = THEME.border
outline.Thickness = 2
outline.Parent = row
