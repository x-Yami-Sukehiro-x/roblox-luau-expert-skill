--!strict
--[[
	Modal — a blocking confirm dialog with three ways out.

	Explained in: roblox-ui/references/blueprints.md (B5)

	Deliberate choices:
	  - Three dismissal routes: the cancel button, the scrim, and Escape. A
	    modal with one route is the most common trap in Roblox UI - a player
	    who does not want either answer has no way out.
	  - The SAFE action takes focus, never the destructive one. A gamepad player
	    who presses A on arrival should not have deleted their save.
	  - The scrim is a TextButton, not a Frame. A Frame does not absorb input,
	    so the menu underneath stays clickable through the "blocking" overlay.
	  - Escape unbinds itself on close, including when the modal is destroyed
	    by something else. A leaked ContextActionService binding swallows Escape
	    for the rest of the session.
--]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local Motion = require(script.Parent.Parent.Motion)
local Tokens = require(script.Parent.Parent.Tokens)

local Button = require(script.Parent.Button)

local Modal = {}

export type Options = {
	title: string,
	message: string,
	confirmText: string?,
	cancelText: string?,
	destructive: boolean?,
}

export type Handle = {
	instance: Frame,
	close: (self: Handle) -> (),
	destroy: (self: Handle) -> (),
}

local DIALOG_WIDTH = 360
local DIALOG_MIN_HEIGHT = 180
local ACTION_HEIGHT = 44
local ESCAPE_ACTION = "ModalDismiss"

--[[
	    Modal.confirm(screenGui, {
	        title = "Sell Crate",
	        message = "This gives you 250 Gems. The crate is gone.",
	        confirmText = "Sell for 250 Gems",
	    }, function(confirmed) ... end)
--]]
function Modal.confirm(
	parent: Instance,
	options: Options,
	onResult: (confirmed: boolean) -> ()
): Handle
	local root = Instance.new("Frame")
	root.Name = "Modal"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 50
	root.Parent = parent

	-- TextButton, so it absorbs the clicks a Frame would let through.
	local scrim = Instance.new("TextButton")
	scrim.Name = "Scrim"
	scrim.AutoButtonColor = false
	scrim.BackgroundColor3 = Tokens.surface.page
	scrim.BackgroundTransparency = 1
	scrim.BorderSizePixel = 0
	scrim.Text = ""
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.ZIndex = root.ZIndex
	scrim.Modal = true
	scrim.Parent = root

	local dialog = Instance.new("Frame")
	dialog.Name = "Dialog"
	dialog.BackgroundColor3 = Tokens.surface.overlay
	dialog.BorderSizePixel = 0
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.Size = UDim2.fromOffset(DIALOG_WIDTH, DIALOG_MIN_HEIGHT)
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.ZIndex = root.ZIndex + 1
	dialog.Parent = root

	-- Never wider than the screen minus a margin, which is the phone case.
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(260, DIALOG_MIN_HEIGHT)
	bounds.MaxSize = Vector2.new(DIALOG_WIDTH, 560)
	bounds.Parent = dialog

	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = Tokens.radius.panel
	corner.TopRightRadius = Tokens.radius.panel
	corner.BottomLeftRadius = Tokens.radius.panel
	corner.BottomRightRadius = Tokens.radius.panel
	corner.Parent = dialog

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	edge.Thickness = 1
	edge.Color = Tokens.stroke.strong
	edge.Parent = dialog

	local shadow = Instance.new("UIShadow")
	shadow.Color = Tokens.stroke.shadow
	shadow.BlurRadius = UDim.new(0, Tokens.elevation.overlay.blur)
	shadow.Offset = UDim2.fromOffset(0, Tokens.elevation.overlay.offset)
	shadow.Transparency = Tokens.elevation.overlay.transparency
	shadow.Parent = dialog

	local scale = Instance.new("UIScale")
	scale.Scale = 0.96
	scale.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Tokens.space.loose)
	padding.PaddingBottom = UDim.new(0, Tokens.space.loose)
	padding.PaddingLeft = UDim.new(0, Tokens.space.loose)
	padding.PaddingRight = UDim.new(0, Tokens.space.loose)
	padding.Parent = dialog

	local stack = Instance.new("UIListLayout")
	stack.FillDirection = Enum.FillDirection.Vertical
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Padding = UDim.new(0, Tokens.space.base)
	stack.Parent = dialog

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.fromScale(1, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextWrapped = true
	title.FontFace = Tokens.font.emphasis
	title.TextSize = Tokens.text_size.title
	title.TextColor3 = Tokens.text.primary
	title.Text = options.title
	title.LayoutOrder = 1
	title.ZIndex = dialog.ZIndex
	title.Parent = dialog

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.BackgroundTransparency = 1
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.Size = UDim2.fromScale(1, 0)
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextWrapped = true
	message.FontFace = Tokens.font.body
	message.TextSize = Tokens.text_size.body
	message.TextColor3 = Tokens.text.secondary
	message.Text = options.message
	message.LayoutOrder = 2
	message.ZIndex = dialog.ZIndex
	message.Parent = dialog

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.BackgroundTransparency = 1
	actions.Size = UDim2.new(1, 0, 0, ACTION_HEIGHT)
	actions.LayoutOrder = 3
	actions.ZIndex = dialog.ZIndex
	actions.Parent = dialog

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actionLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
	actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actionLayout.Padding = UDim.new(0, Tokens.space.base)
	actionLayout.Parent = actions

	local finished = false
	local previousSelection = GuiService.SelectedObject
	local cancel: Button.Handle? = nil
	local confirm: Button.Handle? = nil
	local connections: { RBXScriptConnection } = {}

	local function teardown(confirmed: boolean)
		if finished then
			return
		end
		finished = true

		ContextActionService:UnbindAction(ESCAPE_ACTION)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)

		-- Hand focus back, or a gamepad player is left with nothing selected.
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(root) then
			GuiService.SelectedObject = previousSelection
		end

		Motion.play(dialog, "exit", { BackgroundTransparency = 1 })
		Motion.play(scrim, "exit", { BackgroundTransparency = 1 }, function()
			root:Destroy()
		end)

		onResult(confirmed)
	end

	cancel = Button.secondary(options.cancelText or "Cancel", function()
		teardown(false)
	end)
	local cancelHandle = cancel :: Button.Handle
	cancelHandle.instance.LayoutOrder = 1
	cancelHandle.instance.ZIndex = actions.ZIndex
	cancelHandle.instance.Parent = actions

	confirm = Button.new(
		options.confirmText or "Confirm",
		if options.destructive then "danger" else "primary",
		function()
			teardown(true)
		end
	)
	local confirmHandle = confirm :: Button.Handle
	confirmHandle.instance.LayoutOrder = 2
	confirmHandle.instance.ZIndex = actions.ZIndex
	confirmHandle.instance.Parent = actions

	table.insert(
		connections,
		scrim.Activated:Connect(function()
			teardown(false)
		end)
	)

	ContextActionService:BindAction(ESCAPE_ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			teardown(false)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)

	-- The safe action takes focus. Arriving on a gamepad and pressing A must
	-- never be the destructive answer.
	GuiService.SelectedObject = cancelHandle.instance

	Motion.play(scrim, "enter", { BackgroundTransparency = 0.5 })
	Motion.play(dialog, "enter", { BackgroundTransparency = 0 })
	Motion.play(scale, "enter", { Scale = 1 })

	local handle = {}
	handle.instance = root

	function handle:close()
		teardown(false)
	end

	function handle:destroy()
		ContextActionService:UnbindAction(ESCAPE_ACTION)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		if cancel then
			(cancel :: Button.Handle):destroy()
		end
		if confirm then
			(confirm :: Button.Handle):destroy()
		end
		root:Destroy()
	end

	return (handle :: any) :: Handle
end

return Modal
