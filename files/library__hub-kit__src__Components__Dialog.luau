--[[
	Dialog - a question the player must answer before going on.

	    Window:Dialog({
	        Title = "Delete farming?",
	        Content = "The saved file is removed.",
	        Buttons = {
	            { Title = "Delete", Variant = "danger", Callback = remove },
	            { Title = "Keep", Cancel = true },
	        },
	    })

	Buttons are labelled with what they do ("Delete", "Keep"), never "OK". The
	one marked Cancel is the safe action: it answers Escape, B and a press on
	the dimmed scrim, and it takes gamepad selection when the dialog opens, so
	a player mashing A does not delete anything.

	The scrim is Modal, which frees the mouse in first-person games where the
	camera would otherwise hold it in the centre of the screen.
--]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Motion = require(script.Parent.Parent.Core.Motion)
local Mount = require(script.Parent.Parent.Core.Mount)
local New = require(script.Parent.Parent.Core.New)
local Trove = require(script.Parent.Parent.Core.Trove)

local ACTION = "HubKitDialogCancel"

-- Fill and text for each variant, as theme roles. Hover lightens the fill by
-- transparency, which works for every variant and every palette.
local VARIANTS = {
	primary = { "accent", "onAccent" },
	danger = { "danger", "onAccent" },
	secondary = { "raised", "text" },
}

local Dialog = {}

function Dialog.open(kit: any, options: { [string]: any })
	assert(type(options.Title) == "string", "a Dialog needs a Title string")
	local trove = Trove.new()

	local gui = New("ScreenGui", {
		Name = "HubKitDialog",
		DisplayOrder = 120,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, Mount())
	trove:add(gui)

	local scrim = New("TextButton", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.35,
		AutoButtonColor = false,
		Modal = true,
		Selectable = false,
		Text = "",
		Theme = { BackgroundColor3 = "background" },
	}, gui)

	local panel = New("Frame", {
		Name = "Panel",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Theme = { BackgroundColor3 = "surface" },
	}, gui)
	New("UISizeConstraint", {
		MinSize = Vector2.new(260, 0),
		MaxSize = Vector2.new(420, 400),
	}, panel)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, panel)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}, panel)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
	}, panel)
	local scale = New("UIScale", { Scale = 0.96 }, panel)

	New("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Title,
		Theme = { TextColor3 = "text" },
	}, panel)
	New("TextLabel", {
		Name = "Content",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = options.Content ~= nil,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Content or "",
		Theme = { TextColor3 = "textMuted" },
	}, panel)

	local actions = New("Frame", {
		Name = "Actions",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, panel)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, actions)

	local handle = { gui = gui }
	local closed = false
	function handle.close()
		if closed then
			return
		end
		closed = true
		trove:clean()
	end

	local safe, safeCallback
	for order, choice in options.Buttons or { { Title = "Close", Cancel = true } } do
		local roles = VARIANTS[choice.Variant or "secondary"]
		assert(roles, `no Dialog button variant named {choice.Variant}`)
		local button = New("TextButton", {
			Name = choice.Title,
			LayoutOrder = order,
			Size = UDim2.fromOffset(0, 44),
			AutomaticSize = Enum.AutomaticSize.X,
			AutoButtonColor = false,
			FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
			TextSize = 14,
			Text = choice.Title,
			Theme = { BackgroundColor3 = roles[1], TextColor3 = roles[2] },
		}, actions)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
		New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, button)
		local ring = New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Thickness = 2,
			Enabled = false,
			Theme = { Color = "focus" },
		}, button)

		local function choose()
			handle.close()
			if choice.Callback then
				choice.Callback()
			end
		end
		local function lit(on: boolean)
			button.BackgroundTransparency = if on then 0.15 else 0
		end
		trove:connect(button.MouseEnter, function()
			lit(true)
		end)
		trove:connect(button.MouseLeave, function()
			lit(false)
		end)
		trove:connect(button.SelectionGained, function()
			ring.Enabled = true
		end)
		trove:connect(button.SelectionLost, function()
			ring.Enabled = false
		end)
		trove:connect(button.Activated, choose)
		if choice.Cancel or safe == nil then
			safe, safeCallback = button, choose
		end
	end

	trove:connect(scrim.Activated, safeCallback)
	ContextActionService:BindActionAtPriority(ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			safeCallback()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
	trove:add(function()
		ContextActionService:UnbindAction(ACTION)
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
	end)

	if string.find(tostring(UserInputService:GetLastInputType()), "Gamepad", 1, true) then
		GuiService.SelectedObject = safe
	end
	Motion.play(scale, Motion.enter, { Scale = 1 })
	return handle
end

return Dialog
