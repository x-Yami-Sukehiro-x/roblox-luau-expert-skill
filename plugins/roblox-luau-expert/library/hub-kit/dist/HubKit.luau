-- HubKit 1.0.0: library/hub-kit/src bundled into one file by tools/bin/build-hub-kit.mjs.
-- Generated; edit the sources and rebuild rather than editing this file.
local modules = {}
local loaded = {}
local loading = {}

local function requireModule(id)
	local cached = loaded[id]
	if cached == nil then
		assert(not loading[id], `require cycle through {id}`)
		loading[id] = true
		cached = modules[id]()
		loaded[id] = cached
	end
	return cached
end

modules["Components/Dialog"] = function()
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

local Motion = requireModule("Core/Motion")
local Mount = requireModule("Core/Mount")
local New = requireModule("Core/New")
local Trove = requireModule("Core/Trove")

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
end

modules["Components/Notifications"] = function()
--[[
	Notifications - toasts stacked in the bottom-right corner.

	    HubKit:Notify({
		Title = "Config",
		Content = "Saved farming",
		Kind = "success",
		Duration = 4,
	})

	Four show at once; the rest wait in order and appear as earlier ones
	leave, so a burst of twenty is readable instead of a wall. A toast stays
	for at least 1.5 s whatever Duration says, the time it takes to read one
	at a glance.

	Kind picks an icon as well as a colour (info, success, warning, error), so
	the meaning survives for a player who cannot tell the colours apart. The
	stack is a UIListLayout, so a toast that leaves from the middle closes
	its gap without any position bookkeeping.
--]]

local Icons = requireModule("Core/Icons")
local Motion = requireModule("Core/Motion")
local Mount = requireModule("Core/Mount")
local New = requireModule("Core/New")
local Trove = requireModule("Core/Trove")

local MAX_VISIBLE = 4
local MIN_HOLD = 1.5
local DEFAULT_HOLD = 4

local KINDS = {
	info = { icon = "info", role = "info" },
	success = { icon = "circle-check", role = "success" },
	warning = { icon = "triangle-alert", role = "warning" },
	error = { icon = "octagon-alert", role = "danger" },
}

local Notifications = {}

local function ensure(kit: any)
	if kit.toasts then
		return kit.toasts
	end
	local trove = Trove.new()
	local gui = New("ScreenGui", {
		Name = "HubKitNotifications",
		DisplayOrder = 130,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, Mount())
	trove:add(gui)
	local stack = New("Frame", {
		Name = "Stack",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0.32, 0, 1, -32),
		BackgroundTransparency = 1,
	}, gui)
	New("UISizeConstraint", {
		MinSize = Vector2.new(260, 0),
		MaxSize = Vector2.new(360, 2000),
	}, stack)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
	}, stack)
	kit.toasts = { trove = trove, stack = stack, visible = {}, queue = {}, order = 0 }
	return kit.toasts
end

local show

local function dismiss(state: any, toast: any)
	if toast.gone then
		return
	end
	toast.gone = true
	-- The timer may be the thread running this; cancelling that one errors.
	if toast.timer and toast.timer ~= coroutine.running() then
		task.cancel(toast.timer)
	end
	local index = table.find(state.visible, toast)
	if index then
		table.remove(state.visible, index)
	end
	Motion.play(toast.scale, Motion.exit, { Scale = 0.9 }, function()
		toast.trove:clean()
	end)
	local waiting = table.remove(state.queue, 1)
	if waiting then
		show(state, waiting)
	end
end

function show(state: any, toast: any)
	local notice = toast.notice
	local kind = KINDS[notice.Kind or "info"] or KINDS.info
	local trove = state.trove:extend()
	toast.trove = trove
	state.order += 1

	local frame = New("Frame", {
		Name = "Toast",
		LayoutOrder = state.order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Theme = { BackgroundColor3 = "surface" },
	}, state.stack)
	trove:add(frame)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, frame)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}, frame)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
	}, frame)
	toast.scale = New("UIScale", { Scale = 0.9 }, frame)

	New("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Image = Icons.resolve(kind.icon),
		Theme = { ImageColor3 = kind.role },
	}, frame)
	local words = New("Frame", {
		Name = "Words",
		LayoutOrder = 2,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, frame)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, words)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, words)
	New("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = notice.Title ~= nil,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = notice.Title or "",
		Theme = { TextColor3 = "text" },
	}, words)
	New("TextLabel", {
		Name = "Content",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = notice.Content ~= nil,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = notice.Content or "",
		Theme = { TextColor3 = "textMuted" },
	}, words)
	local close = New("TextButton", {
		Name = "Dismiss",
		LayoutOrder = 3,
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, frame)
	local mark = New("ImageLabel", {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve("x"),
		Theme = { ImageColor3 = "textMuted" },
	}, close)
	trove:connect(close.MouseEnter, function()
		mark.ImageTransparency = 0
	end)
	trove:connect(close.MouseLeave, function()
		mark.ImageTransparency = 0.3
	end)
	trove:connect(close.Activated, function()
		dismiss(state, toast)
	end)
	mark.ImageTransparency = 0.3

	table.insert(state.visible, toast)
	Motion.play(toast.scale, Motion.enter, { Scale = 1 })
	local hold = math.max(notice.Duration or DEFAULT_HOLD, MIN_HOLD)
	toast.timer = task.delay(hold, dismiss, state, toast)
end

function Notifications.push(kit: any, notice: { [string]: any })
	assert(notice.Title or notice.Content, "a notification needs a Title or Content")
	local state = ensure(kit)
	local toast = { notice = notice, gone = false }
	if #state.visible < MAX_VISIBLE then
		show(state, toast)
	else
		table.insert(state.queue, toast)
	end
	return {
		Dismiss = function()
			if toast.trove then
				dismiss(state, toast)
			else
				local index = table.find(state.queue, toast)
				if index then
					table.remove(state.queue, index)
				end
			end
		end,
	}
end

function Notifications.clear(kit: any)
	local state = kit.toasts
	if not state then
		return
	end
	kit.toasts = nil
	for _, toast in state.visible do
		toast.gone = true
		if toast.timer then
			task.cancel(toast.timer)
		end
	end
	state.trove:clean()
end

return Notifications
end

modules["Components/OpenButton"] = function()
--[[
	OpenButton - the chip that brings a hidden window back.

	A phone has no menu key, so a hidden window with no on-screen way back is
	a hub the player can only reopen by re-executing. The chip sits at the top
	centre, below the Roblox topbar, and can be dragged anywhere; a tap that
	did not move reopens the window. On a keyboard device it also names the
	menu key, so the chip teaches the shortcut instead of replacing it.
--]]

local UserInputService = game:GetService("UserInputService")

local Drag = requireModule("Core/Drag")
local Icons = requireModule("Core/Icons")
local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")

local OpenButton = {}

function OpenButton.new(window: any, options: { [string]: any })
	local trove = window.trove

	local chip = New("TextButton", {
		Name = "Open",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		AutoButtonColor = false,
		Visible = false,
		Text = "",
		Theme = { BackgroundColor3 = "surface" },
	}, window.gui)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, chip)
	New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, chip)
	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, chip)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, chip)
	New("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve(options.Icon or "layout-list"),
		Theme = { ImageColor3 = "accent" },
	}, chip)
	New("TextLabel", {
		Name = "Label",
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = `Open {options.Title}`,
		Theme = { TextColor3 = "text" },
	}, chip)
	local hint = New("TextLabel", {
		Name = "Key",
		LayoutOrder = 3,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 12,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, chip)

	local dragger = Drag.attach(trove, chip, chip)
	local function lit(on: boolean)
		ring.Color = Theme.get(if on then "focus" else "stroke")
	end
	trove:connect(chip.MouseEnter, function()
		lit(true)
	end)
	trove:connect(chip.MouseLeave, function()
		lit(false)
	end)
	trove:connect(chip.SelectionGained, function()
		lit(true)
	end)
	trove:connect(chip.SelectionLost, function()
		lit(false)
	end)
	trove:connect(chip.Activated, function()
		if not dragger.wasDragged() then
			window:SetVisible(true)
		end
	end)

	local function setHint(key: Enum.KeyCode?)
		hint.Text = if key then key.Name else ""
		hint.Visible = key ~= nil and UserInputService.KeyboardEnabled
	end
	setHint(window.toggleKey)

	return {
		show = function()
			chip.Visible = true
		end,
		hide = function()
			chip.Visible = false
		end,
		setHint = setHint,
	}
end

return OpenButton
end

modules["Components/Popup"] = function()
--[[
	Popup - the floating panel a Dropdown or ColorPicker opens beside its row.

	It lives in its own ScreenGui above the window rather than inside the tab's
	ScrollingFrame, which would clip it at the page edge. Only one is open at a
	time; opening a second closes the first.

	Placement: right-aligned with the row, below it, flipped above when the
	screen has no room underneath, then clamped 8 px inside every edge. Sizes
	are given, not measured, because AbsoluteSize of automatic content is not
	known until the next layout pass and the panel would jump once it was.

	Three ways out, one per input: the scrim (a press anywhere else), Escape
	(keyboard) and B (gamepad). The keys are bound through ContextActionService
	so the game does not also act on them.
--]]

local ContextActionService = game:GetService("ContextActionService")

local Mount = requireModule("Core/Mount")
local New = requireModule("Core/New")
local Trove = requireModule("Core/Trove")

local EDGE = 8
local GAP = 4
local ACTION = "HubKitPopupClose"

local Popup = {}

function Popup.open(
	kit: any,
	anchor: GuiObject,
	width: number,
	height: number,
	onClose: (() -> ())?
)
	if kit.popup then
		kit.popup.close()
	end

	local trove = Trove.new()
	local gui = New("ScreenGui", {
		Name = "HubKitPopup",
		DisplayOrder = 110,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, Mount())
	trove:add(gui)

	local scrim = New("TextButton", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Selectable = false,
		Text = "",
	}, gui)

	-- Active: a click on empty panel space must not fall through to the scrim.
	local panel = New("Frame", {
		Name = "Panel",
		Active = true,
		Size = UDim2.fromOffset(width, height),
		Theme = { BackgroundColor3 = "surface" },
	}, gui)
	New("UISizeConstraint", { MaxSize = Vector2.new(width, height) }, panel)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, panel)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, panel)

	local base, screen = gui.AbsolutePosition, gui.AbsoluteSize
	local corner, size = anchor.AbsolutePosition, anchor.AbsoluteSize
	local left = corner.X + size.X - width - base.X
	local top = corner.Y + size.Y + GAP - base.Y
	if top + height > screen.Y - EDGE then
		top = corner.Y - GAP - height - base.Y
	end
	left = math.clamp(left, EDGE, math.max(screen.X - width - EDGE, EDGE))
	top = math.clamp(top, EDGE, math.max(screen.Y - height - EDGE, EDGE))
	panel.Position = UDim2.fromOffset(left, top)

	local handle = { panel = panel, trove = trove, gui = gui }
	function handle.close()
		if kit.popup ~= handle then
			return
		end
		kit.popup = nil
		trove:clean()
		if onClose then
			onClose()
		end
	end

	trove:connect(scrim.Activated, handle.close)
	ContextActionService:BindActionAtPriority(ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			handle.close()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
	trove:add(function()
		ContextActionService:UnbindAction(ACTION)
	end)

	kit.popup = handle
	return handle
end

return Popup
end

modules["Components/Section"] = function()
--[[
	Section - a titled group of rows inside a tab, collapsible from its header.

	    local movement = Tab:Section({ Title = "Movement" })
	    movement:Toggle({ Title = "Fly", Flag = "Fly", Callback = setFly })

	A section has the same element methods as a tab. While the window search
	has text, a collapsed section still shows its matching rows: a search
	that hides its own results behind a fold looks like a search that failed.
--]]

local Elements = requireModule("Elements")
local Icons = requireModule("Core/Icons")
local Motion = requireModule("Core/Motion")
local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")

local Section = {}

function Section.new(tab: any, options: { [string]: any })
	assert(type(options.Title) == "string", "a Section needs a Title string")
	local trove = tab.trove:extend()

	local holder = New("Frame", {
		Name = options.Title,
		LayoutOrder = tab:nextOrder(),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, tab.frame)
	trove:add(holder)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, holder)

	local header = New("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, holder)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, header)
	local chevron = New("ImageLabel", {
		Name = "Chevron",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve("chevron-down"),
		Theme = { ImageColor3 = "textMuted" },
	}, header)
	local label = New("TextLabel", {
		Name = "Title",
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 14,
		Text = options.Title,
		Theme = { TextColor3 = "textMuted" },
	}, header)

	local body = New("Frame", {
		Name = "Body",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, holder)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, body)

	local section = {
		kit = tab.kit,
		window = tab.window,
		tab = tab,
		frame = body,
		holder = holder,
		trove = trove,
		entries = tab.entries,
		collapsed = false,
		order = 0,
	}
	section.section = section

	function section:nextOrder(): number
		self.order += 1
		return self.order
	end

	function section:SetCollapsed(collapsed: boolean)
		self.collapsed = collapsed
		Motion.play(chevron, Motion.state, { Rotation = if collapsed then -90 else 0 })
		self.window:applySearch()
	end

	function section:Destroy()
		local index = table.find(tab.sections, section)
		if index then
			table.remove(tab.sections, index)
		end
		trove:clean()
	end

	local hovered = false
	local function paint()
		label.TextColor3 = Theme.get(if hovered then "text" else "textMuted")
	end
	trove:connect(header.MouseEnter, function()
		hovered = true
		paint()
	end)
	trove:connect(header.MouseLeave, function()
		hovered = false
		paint()
	end)
	trove:connect(header.SelectionGained, function()
		hovered = true
		paint()
	end)
	trove:connect(header.SelectionLost, function()
		hovered = false
		paint()
	end)
	trove:connect(Theme.changed, paint)
	trove:connect(header.Activated, function()
		section:SetCollapsed(not section.collapsed)
	end)

	Elements.install(section)
	table.insert(tab.sections, section)
	if options.Collapsed then
		section:SetCollapsed(true)
	end
	return section
end

return Section
end

modules["Components/SettingsTab"] = function()
--[[
	SettingsTab - the tab every hub needs and nobody wants to write: theme,
	menu key, saved configs and unload.

	    Window:SettingsTab()

	The theme and menu key carry the flags "HubKit.Theme" and "HubKit.MenuKey",
	so a saved config restores the look and the key along with the features.
	Without executor file access the Configs section says so in one line
	instead of offering buttons that cannot work.
--]]

local Config = requireModule("Core/Config")
local Theme = requireModule("Core/Theme")

local SettingsTab = {}

function SettingsTab.build(window: any, options: { [string]: any })
	local tab = window:Tab({ Title = options.Title or "Settings", Icon = "settings" })

	local look = tab:Section({ Title = "Appearance" })
	look:Dropdown({
		Title = "Theme",
		Values = Theme.list(),
		Default = Theme.current(),
		Flag = "HubKit.Theme",
		Callback = function(name: string?)
			if name then
				Theme.set(name)
			end
		end,
	})

	local controls = tab:Section({ Title = "Controls" })
	local menuKey = controls:Keybind({
		Title = "Menu key",
		Description = "Shows and hides this window",
		Default = window.toggleKey,
		Flag = "HubKit.MenuKey",
	})
	menuKey.trove:add(menuKey.Changed:Connect(function(key: Enum.KeyCode?)
		window:SetToggleKey(key)
	end))

	local saves = tab:Section({ Title = "Configs" })
	if not Config.available then
		saves:Paragraph({
			Title = "Saving is off",
			Content = "This executor has no file access, so settings last until you leave.",
		})
	else
		local function report(ok: boolean, message: string)
			window:Notify({
				Title = "Configs",
				Content = message,
				Kind = if ok then "success" else "error",
			})
		end

		local name = saves:Input({ Title = "Config name", Placeholder = "farming" })
		local saved = saves:Dropdown({
			Title = "Saved configs",
			Values = window.config:list(),
			AllowNone = true,
		})
		local function refresh()
			saved:Refresh(window.config:list())
		end

		saves:Button({
			Title = "Save",
			Description = "Saves every setting under the name above",
			Icon = "save",
			Callback = function()
				report(window.config:save(name:Get()))
				refresh()
			end,
		})
		saves:Button({
			Title = "Load",
			Description = "Loads the config picked above",
			Icon = "folder",
			Callback = function()
				local pick = saved:Get()
				if pick then
					report(window.config:load(pick))
				else
					report(false, "Pick a saved config first")
				end
			end,
		})
		saves:Button({
			Title = "Load on start",
			Description = "The picked config loads each time the hub starts",
			Icon = "star",
			Callback = function()
				report(window.config:setAutoload(saved:Get()))
			end,
		})
		saves:Button({
			Title = "Delete",
			Description = "Removes the picked config file",
			Icon = "trash-2",
			Callback = function()
				local pick = saved:Get()
				if not pick then
					report(false, "Pick a saved config first")
					return
				end
				window:Dialog({
					Title = `Delete {pick}?`,
					Content = "The file is removed from your executor's workspace folder.",
					Buttons = {
						{
							Title = "Delete",
							Variant = "danger",
							Callback = function()
								report(window.config:delete(pick))
								refresh()
							end,
						},
						{ Title = "Keep", Cancel = true },
					},
				})
			end,
		})
	end

	local session = tab:Section({ Title = "Session" })
	session:Button({
		Title = "Unload",
		Description = "Closes the hub and disconnects everything it started",
		Icon = "log-out",
		Callback = function()
			window:ConfirmUnload()
		end,
	})
	return tab
end

return SettingsTab
end

modules["Components/Tab"] = function()
--[[
	Tab - one sidebar button and the scrolling page it shows.

	    local player = Window:Tab({ Title = "Player", Icon = "user" })
	    player:Slider({ Title = "Walk speed", Min = 16, Max = 120, Default = 16 })

	Every page is built once and shown or hidden, never rebuilt on switch, so
	a half-typed Input or an open section survives a trip to another tab.
	In a compact window the label hides and the icon carries the tab alone,
	which is why a tab without an Icon still gets one.
--]]

local Elements = requireModule("Elements")
local Icons = requireModule("Core/Icons")
local Motion = requireModule("Core/Motion")
local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")
local Section = requireModule("Components/Section")

-- Rows are appended with increasing LayoutOrder; the empty-search line
-- sorts after all of them.
local LAST = 1e6

local Tab = {}

function Tab.new(window: any, options: { [string]: any })
	assert(type(options.Title) == "string", "a Tab needs a Title string")
	local image = Icons.resolve(options.Icon or "layout-list")
	local trove = window.trove:extend()

	local button = New("TextButton", {
		Name = options.Title,
		LayoutOrder = #window.tabs + 1,
		Size = UDim2.new(1, 0, 0, 44),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		Theme = { BackgroundColor3 = "raised" },
	}, window.sidebar)
	trove:add(button)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, button)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, button)
	local icon = New("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = image,
	}, button)
	local label = New("TextLabel", {
		Name = "Label",
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = options.Title,
	}, button)
	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 2,
		Enabled = false,
		Theme = { Color = "focus" },
	}, button)

	local page = New("ScrollingFrame", {
		Name = options.Title,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Theme = { ScrollBarImageColor3 = "stroke" },
	}, window.pages)
	trove:add(page)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, page)
	New("UIPadding", { PaddingRight = UDim.new(0, 8) }, page)
	local empty = New("TextLabel", {
		Name = "NoMatches",
		LayoutOrder = LAST,
		Size = UDim2.new(1, 0, 0, 44),
		Visible = false,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextWrapped = true,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, page)

	local tab = {
		kit = window.kit,
		window = window,
		title = options.Title,
		button = button,
		label = label,
		frame = page,
		empty = empty,
		trove = trove,
		entries = {},
		sections = {},
		order = 0,
	}

	function tab:nextOrder(): number
		self.order += 1
		return self.order
	end

	function tab:Section(sectionOptions: { [string]: any })
		return Section.new(self, sectionOptions)
	end

	function tab:Select()
		window:SelectTab(self)
	end

	local hovered, focused = false, false
	function tab:render()
		local selected = window.selected == self
		local fill = if selected then 0 elseif hovered then 0.5 else 1
		Motion.play(button, Motion.state, { BackgroundTransparency = fill })
		label.TextColor3 = Theme.get(if selected or hovered then "text" else "textMuted")
		icon.ImageColor3 = Theme.get(if selected then "accent" else "textMuted")
		local weight = if selected then Enum.Font.BuilderSansBold else Enum.Font.BuilderSansMedium
		label.FontFace = Font.fromEnum(weight)
		ring.Enabled = focused
	end

	trove:connect(button.MouseEnter, function()
		hovered = true
		tab:render()
	end)
	trove:connect(button.MouseLeave, function()
		hovered = false
		tab:render()
	end)
	trove:connect(button.SelectionGained, function()
		focused = true
		tab:render()
	end)
	trove:connect(button.SelectionLost, function()
		focused = false
		tab:render()
	end)
	trove:connect(Theme.changed, function()
		tab:render()
	end)
	trove:connect(button.Activated, function()
		window:SelectTab(tab)
	end)

	Elements.install(tab)
	return tab
end

return Tab
end

modules["Components/Window"] = function()
--[[
	Window - the hub: a draggable panel with a tab sidebar, a search box and
	one scrolling page per tab.

	Sized by scale and held between 300 x 240 and 760 x 540, so it fits a
	640 x 360 phone under the topbar and does not stretch across an
	ultrawide monitor. Below 520 px wide it turns compact: the sidebar shrinks
	to icons and the subtitle hides, instead of the page being squeezed.

	The root frame is Active so a click on the window never reaches the game
	world behind it; with a click-teleport feature on, a press on the hub
	would otherwise teleport the player.

	Hiding (the minimize button or the menu key) leaves a draggable Open chip
	on screen, because a phone has no RightShift. Closing asks first, then
	unloads: every connection, instance and popup the window made is released
	through one trove, and OnUnload fires first so the hub can switch its own
	features off.
--]]

local UserInputService = game:GetService("UserInputService")

local Config = requireModule("Core/Config")
local Drag = requireModule("Core/Drag")
local Icons = requireModule("Core/Icons")
local Motion = requireModule("Core/Motion")
local Mount = requireModule("Core/Mount")
local New = requireModule("Core/New")
local Signal = requireModule("Core/Signal")
local Theme = requireModule("Core/Theme")
local Trove = requireModule("Core/Trove")
local Dialog = requireModule("Components/Dialog")
local OpenButton = requireModule("Components/OpenButton")
local SettingsTab = requireModule("Components/SettingsTab")
local Tab = requireModule("Components/Tab")

local COMPACT_BELOW = 520
local SIDEBAR_WIDE = 160
local SIDEBAR_COMPACT = 52
local HIDDEN_SCALE = 0.96

local Window = {}

local function folderFrom(title: string): string
	local cleaned = string.sub(string.gsub(title, "[^%w _%-]", ""), 1, 32)
	return if cleaned == "" then "Hub" else cleaned
end

local function topbarButton(
	trove: any,
	parent: Instance,
	image: string,
	order: number,
	name: string
): TextButton
	local button = New("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Theme = { BackgroundColor3 = "raised" },
	}, parent)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	local mark = New("ImageLabel", {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve(image),
		Theme = { ImageColor3 = "textMuted" },
	}, button)
	local function lit(on: boolean)
		button.BackgroundTransparency = if on then 0 else 1
		mark.ImageColor3 = Theme.get(if on then "text" else "textMuted")
	end
	trove:connect(button.MouseEnter, function()
		lit(true)
	end)
	trove:connect(button.MouseLeave, function()
		lit(false)
	end)
	trove:connect(button.SelectionGained, function()
		lit(true)
	end)
	trove:connect(button.SelectionLost, function()
		lit(false)
	end)
	return button
end

function Window.new(kit: any, options: { [string]: any })
	assert(type(options.Title) == "string", "CreateWindow needs a Title string")
	local trove = Trove.new()

	local gui = New("ScreenGui", {
		Name = "HubKit",
		DisplayOrder = 100,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, Mount())
	trove:add(gui)

	local root = New("Frame", {
		Name = "Window",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = options.Size or UDim2.fromScale(0.62, 0.72),
		Theme = { BackgroundColor3 = "surface" },
	}, gui)
	New("UISizeConstraint", {
		MinSize = Vector2.new(300, 240),
		MaxSize = Vector2.new(760, 540),
	}, root)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, root)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, root)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, root)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, root)
	local pop = New("UIScale", { Scale = 1 }, root)

	local topbar = New("Frame", {
		Name = "Topbar",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, root)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, topbar)
	New("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(20, 20),
		Visible = options.Icon ~= nil,
		BackgroundTransparency = 1,
		Image = if options.Icon then Icons.resolve(options.Icon) else "",
		Theme = { ImageColor3 = "accent" },
	}, topbar)
	local titles = New("Frame", {
		Name = "Titles",
		LayoutOrder = 2,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, topbar)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, titles)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, titles)
	New("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = options.Title,
		Theme = { TextColor3 = "text" },
	}, titles)
	local subtitle = New("TextLabel", {
		Name = "Subtitle",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = options.Subtitle ~= nil,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = options.Subtitle or "",
		Theme = { TextColor3 = "textMuted" },
	}, titles)
	local minimize = topbarButton(trove, topbar, "minus", 3, "Minimize")
	local close = topbarButton(trove, topbar, "x", 4, "Close")

	local body = New("Frame", {
		Name = "Body",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
	}, root)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, body)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, body)

	local sidebar = New("ScrollingFrame", {
		Name = "Sidebar",
		LayoutOrder = 1,
		Size = UDim2.new(0, SIDEBAR_WIDE, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, body)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, sidebar)

	local content = New("Frame", {
		Name = "Content",
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "background" },
	}, body)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, content)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, content)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	}, content)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, content)

	local header = New("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
	}, content)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, header)
	local pageTitle = New("TextLabel", {
		Name = "PageTitle",
		LayoutOrder = 1,
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Theme = { TextColor3 = "text" },
	}, header)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, pageTitle)
	local search = New("TextBox", {
		Name = "Search",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(160, 36),
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		PlaceholderText = "Search this tab",
		Text = "",
		Theme = {
			BackgroundColor3 = "surface",
			TextColor3 = "text",
			PlaceholderColor3 = "textMuted",
		},
	}, header)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, search)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, search)

	local pages = New("Frame", {
		Name = "Pages",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
	}, content)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, pages)

	local window = {
		kit = kit,
		trove = trove,
		gui = gui,
		root = root,
		sidebar = sidebar,
		pages = pages,
		tabs = {},
		selected = nil,
		query = "",
		visible = true,
		toggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
		config = Config.new(options.Folder or folderFrom(options.Title)),
		Flags = {},
		OnUnload = Signal.new(),
		Gui = gui,
	}
	trove:add(window.OnUnload)
	local opener = OpenButton.new(window, options)

	function window:Tab(tabOptions: { [string]: any })
		local tab = Tab.new(self, tabOptions)
		table.insert(self.tabs, tab)
		tab.label.Visible = not self.compact
		if self.selected == nil then
			self:SelectTab(tab)
		else
			tab:render()
		end
		return tab
	end

	function window:SettingsTab(tabOptions: { [string]: any }?)
		return SettingsTab.build(self, tabOptions or {})
	end

	function window:SelectTab(tab: any)
		self.selected = tab
		for _, other in self.tabs do
			other.frame.Visible = other == tab
			other:render()
		end
		pageTitle.Text = tab.title
		self:applySearch()
	end

	function window:applySearch()
		local tab = self.selected
		if not tab then
			return
		end
		local query = self.query
		local shown, sectionsShown = 0, {}
		for _, entry in tab.entries do
			local match = query == "" or string.find(entry.text, query, 1, true) ~= nil
			entry.frame.Visible = match
			if match then
				shown += 1
				if entry.section then
					sectionsShown[entry.section] = true
				end
			end
		end
		for _, section in tab.sections do
			section.holder.Visible = query == "" or sectionsShown[section] == true
			section.frame.Visible = query ~= "" or not section.collapsed
		end
		tab.empty.Visible = query ~= "" and shown == 0
		tab.empty.Text = `Nothing on {tab.title} matches "{search.Text}"`
	end

	function window:SetVisible(visible: boolean)
		if visible == self.visible then
			return
		end
		self.visible = visible
		if visible then
			opener.hide()
			root.Visible = true
			pop.Scale = HIDDEN_SCALE
			Motion.play(pop, Motion.enter, { Scale = 1 })
			return
		end
		if kit.popup then
			kit.popup.close()
		end
		opener.show()
		Motion.play(pop, Motion.exit, { Scale = HIDDEN_SCALE }, function()
			root.Visible = self.visible
		end)
	end

	function window:Toggle()
		self:SetVisible(not self.visible)
	end

	function window:SetToggleKey(key: Enum.KeyCode?)
		self.toggleKey = key
		opener.setHint(key)
	end

	function window:Notify(notice: { [string]: any })
		return kit.notify(notice)
	end

	function window:Dialog(dialogOptions: { [string]: any })
		return Dialog.open(kit, dialogOptions)
	end

	function window:LoadAutoload(): (boolean, string)
		local ok, message = self.config:autoload()
		if ok then
			self:Notify({ Title = "Config", Content = message, Kind = "success" })
		end
		return ok, message
	end

	function window:Unload()
		if self.unloaded then
			return
		end
		self.unloaded = true
		if kit.popup then
			kit.popup.close()
		end
		self.OnUnload:Fire()
		local index = table.find(kit.windows, self)
		if index then
			table.remove(kit.windows, index)
		end
		trove:clean()
	end

	local function arrange()
		local compact = root.AbsoluteSize.X < COMPACT_BELOW
		window.compact = compact
		sidebar.Size = UDim2.new(0, if compact then SIDEBAR_COMPACT else SIDEBAR_WIDE, 1, 0)
		search.Size = UDim2.fromOffset(if compact then 112 else 160, 36)
		subtitle.Visible = options.Subtitle ~= nil and not compact
		for _, tab in window.tabs do
			tab.label.Visible = not compact
		end
	end

	Drag.attach(trove, topbar, root)
	trove:connect(root:GetPropertyChangedSignal("AbsoluteSize"), arrange)
	trove:connect(search:GetPropertyChangedSignal("Text"), function()
		window.query = string.lower(search.Text)
		window:applySearch()
	end)
	trove:connect(minimize.Activated, function()
		window:SetVisible(false)
	end)
	local function unload()
		window:Unload()
	end
	function window:ConfirmUnload()
		return self:Dialog({
			Title = `Unload {options.Title}?`,
			Content = "The window closes and everything it connected is disconnected.",
			Buttons = {
				{ Title = "Unload", Variant = "danger", Callback = unload },
				{ Title = "Keep open", Cancel = true },
			},
		})
	end
	trove:connect(close.Activated, function()
		window:ConfirmUnload()
	end)
	trove:connect(UserInputService.InputBegan, function(input: InputObject, processed: boolean)
		if not processed and not kit.capturing and input.KeyCode == window.toggleKey then
			window:Toggle()
		end
	end)

	arrange()
	return window
end

return Window
end

modules["Core/Config"] = function()
--[[
	Config - named saves of every flagged element, as JSON files under
	HubKit/<folder>/ in the executor's workspace folder.

	File access is an executor feature, so it is detected once. Without it
	`save`, `load` and `delete` return false and a sentence the hub can show
	the player; they never pretend to succeed.

	Values pass through each element's own `Encode` and `Decode`, so a
	Color3 is saved as a hex string and a KeyCode by name, and an old config
	that names a flag the hub no longer has is skipped rather than an error.
--]]

local HttpService = game:GetService("HttpService")

local writefile, readfile, isfile = writefile, readfile, isfile
local isfolder, makefolder, listfiles, delfile = isfolder, makefolder, listfiles, delfile
local HAS_FILES = typeof(writefile) == "function"
	and typeof(readfile) == "function"
	and typeof(isfile) == "function"
	and typeof(isfolder) == "function"
	and typeof(makefolder) == "function"
	and typeof(listfiles) == "function"
	and typeof(delfile) == "function"

local NO_FILES = "Saving needs an executor with file access (writefile)"
local ROOT = "HubKit"
local AUTOLOAD = "autoload.txt"

local Config = {}
Config.__index = Config
Config.available = HAS_FILES

local function validName(name: string): boolean
	return type(name) == "string"
		and #name > 0
		and #name <= 32
		and string.find(name, "^[%w _%-]+$") ~= nil
end

function Config.new(folder: string)
	assert(validName(folder), "config folder must be letters, digits, space, - or _")
	return setmetatable({ folder = `{ROOT}/{folder}`, flags = {} }, Config)
end

function Config:register(flag: string, element: any)
	if self.flags[flag] then
		error(`flag {flag} is already registered`, 3)
	end
	self.flags[flag] = element
end

function Config:unregister(flag: string)
	self.flags[flag] = nil
end

function Config:snapshot(): { [string]: any }
	local values = {}
	for flag, element in self.flags do
		local value = element:Get()
		values[flag] = if element.Encode then element.Encode(value) else value
	end
	return values
end

function Config:apply(values: { [string]: any }): number
	local applied = 0
	for flag, raw in values do
		local element = self.flags[flag]
		if element then
			element:Set(if element.Decode then element.Decode(raw) else raw)
			applied += 1
		end
	end
	return applied
end

function Config:ensureFolder()
	if not isfolder(ROOT) then
		makefolder(ROOT)
	end
	if not isfolder(self.folder) then
		makefolder(self.folder)
	end
end

function Config:path(name: string): string
	return `{self.folder}/{name}.json`
end

function Config:save(name: string): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	if not validName(name) then
		return false, "Config names use letters, digits, spaces, - and _"
	end
	self:ensureFolder()
	writefile(self:path(name), HttpService:JSONEncode(self:snapshot()))
	return true, `Saved {name}`
end

function Config:load(name: string): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	local path = self:path(name)
	if not validName(name) or not isfile(path) then
		return false, `No saved config named {name}`
	end
	local ok, values = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	if not ok or type(values) ~= "table" then
		return false, `{name} is not a readable config file`
	end
	return true, `Loaded {name} ({self:apply(values)} settings)`
end

function Config:delete(name: string): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	local path = self:path(name)
	if not validName(name) or not isfile(path) then
		return false, `No saved config named {name}`
	end
	delfile(path)
	return true, `Deleted {name}`
end

function Config:list(): { string }
	if not HAS_FILES or not isfolder(self.folder) then
		return {}
	end
	local names = {}
	for _, path in listfiles(self.folder) do
		-- Executors disagree on the separator listfiles returns.
		local name = string.match(path, "([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

function Config:setAutoload(name: string?): (boolean, string)
	if not HAS_FILES then
		return false, NO_FILES
	end
	self:ensureFolder()
	writefile(`{self.folder}/{AUTOLOAD}`, name or "")
	return true, if name then `{name} loads on start` else "Nothing loads on start"
end

function Config:autoload(): (boolean, string)
	local path = `{self.folder}/{AUTOLOAD}`
	if not HAS_FILES or not isfile(path) then
		return false, "No autoload config"
	end
	local name = readfile(path)
	if name == "" then
		return false, "No autoload config"
	end
	return self:load(name)
end

return Config
end

modules["Core/Drag"] = function()
--[[
	Drag - moves a GuiObject by a handle with mouse or touch, and keeps the
	whole object on screen.

	The new position is clamped from where the drag began, arithmetically,
	rather than from AbsolutePosition after each move: the engine recomputes
	that on the next layout pass, so reading it mid-drag lags a frame behind
	and lets a fast flick throw the window off screen.

	`wasDragged` tells a tap from a drag on the same button. Activated fires
	for both, so a draggable button checks it before acting.
--]]

local UserInputService = game:GetService("UserInputService")

-- A press that travels further than this is a drag, not a tap.
local SLOP = 6

local Drag = {}

local function isPress(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

function Drag.attach(trove: any, handle: GuiObject, target: GuiObject)
	local active: InputObject? = nil
	local origin, startPosition, startCorner
	local moved = false

	trove:connect(handle.InputBegan, function(input: InputObject)
		if active or not isPress(input) then
			return
		end
		active = input
		origin = input.Position
		startPosition = target.Position
		startCorner = target.AbsolutePosition
		moved = false
	end)

	trove:connect(UserInputService.InputChanged, function(input: InputObject)
		if not active then
			return
		end
		local mouseFollow = input.UserInputType == Enum.UserInputType.MouseMovement
			and active.UserInputType == Enum.UserInputType.MouseButton1
		if input ~= active and not mouseFollow then
			return
		end

		local delta = input.Position - origin
		if not moved and delta.Magnitude < SLOP then
			return
		end
		moved = true

		-- Bounds come from the ScreenGui itself, so the clamp holds whichever
		-- origin its ScreenInsets give AbsolutePosition.
		local layer = target:FindFirstAncestorWhichIsA("LayerCollector")
		local corner, screen, size = layer.AbsolutePosition, layer.AbsoluteSize, target.AbsoluteSize
		local roomX = math.max(screen.X - size.X, 0)
		local roomY = math.max(screen.Y - size.Y, 0)
		local left = math.clamp(startCorner.X + delta.X, corner.X, corner.X + roomX)
		local top = math.clamp(startCorner.Y + delta.Y, corner.Y, corner.Y + roomY)
		target.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + left - startCorner.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + top - startCorner.Y
		)
	end)

	trove:connect(UserInputService.InputEnded, function(input: InputObject)
		if active and (input == active or input.UserInputType == active.UserInputType) then
			active = nil
		end
	end)

	return {
		wasDragged = function(): boolean
			return moved
		end,
	}
end

return Drag
end

modules["Core/Icons"] = function()
--[[
	Icons - Lucide icons already uploaded to Roblox, by name.

	Every id here is copied from roblox-ui-components/references/icon-ids.txt,
	where each was confirmed as a real image, and verify-asset-ids.mjs checks
	them again in CI. A name that is not in the table is an error, never a
	blank ImageLabel. A full "rbxassetid://" string passes through, for icons
	a hub uploads itself.
--]]

local IDS = {
	["check"] = "rbxassetid://86817768619372",
	["chevron-down"] = "rbxassetid://71457658246709",
	["chevron-right"] = "rbxassetid://101007429951147",
	["circle-check"] = "rbxassetid://88244323237265",
	["eye"] = "rbxassetid://127234874352422",
	["folder"] = "rbxassetid://77937190465422",
	["home"] = "rbxassetid://109841253338329",
	["info"] = "rbxassetid://120620848266512",
	["keyboard"] = "rbxassetid://121978468376124",
	["layout-list"] = "rbxassetid://72384664085473",
	["log-out"] = "rbxassetid://140299936053191",
	["minus"] = "rbxassetid://95070996149109",
	["mouse-pointer-click"] = "rbxassetid://81854854241463",
	["octagon-alert"] = "rbxassetid://101226496664732",
	["palette"] = "rbxassetid://127369887384101",
	["pipette"] = "rbxassetid://104047428948587",
	["refresh-cw"] = "rbxassetid://106497040962250",
	["save"] = "rbxassetid://122894934359450",
	["search"] = "rbxassetid://72296609649861",
	["settings"] = "rbxassetid://106205298246017",
	["sliders-horizontal"] = "rbxassetid://125396339381135",
	["sparkles"] = "rbxassetid://105634041692696",
	["star"] = "rbxassetid://72669221096319",
	["swords"] = "rbxassetid://99199363807265",
	["trash-2"] = "rbxassetid://126010725826757",
	["triangle-alert"] = "rbxassetid://91165848022002",
	["user"] = "rbxassetid://114567720540659",
	["x"] = "rbxassetid://116396312853810",
	["zap"] = "rbxassetid://109718589733073",
}

local Icons = {}

function Icons.resolve(name: string): string
	if string.sub(name, 1, 13) == "rbxassetid://" then
		return name
	end
	local id = IDS[name]
	if not id then
		error(`no icon named {name}`, 2)
	end
	return id
end

function Icons.names(): { string }
	local list = {}
	for name in IDS do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

return Icons
end

modules["Core/Motion"] = function()
--[[
	Motion - three timings for the whole kit, and the reduced-motion switch.

	Entrances ease out over 0.2 s, exits ease in over 0.15 s, and state changes
	(hover, press, on and off) take 0.12 s. With the player's Reduce Motion
	setting on, every change lands in one frame instead.

	`onDone` waits for PlaybackState.Completed. A newer tween on the same
	property stops this one and still fires Completed, and acting on that
	would hide a window the player has just reopened.
--]]

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Motion = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	state = TweenInfo.new(0.12, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}

function Motion.play(
	instance: Instance,
	info: TweenInfo,
	goals: { [string]: any },
	onDone: (() -> ())?
)
	if GuiService.ReducedMotionEnabled then
		for property, value in goals do
			instance[property] = value
		end
		if onDone then
			onDone()
		end
		return
	end

	local tween = TweenService:Create(instance, info, goals)
	if onDone then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				onDone()
			end
		end)
	end
	tween:Play()
end

return Motion
end

modules["Core/Mount"] = function()
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
end

modules["Core/New"] = function()
--[[
	New(className, properties, parent) - one statement per instance.

	`Theme = { BackgroundColor3 = "surface" }` binds a property to a palette
	role instead of setting a colour, so a theme switch reaches it. Parent is
	assigned after every other property: an instance never appears on screen
	half-built, and nothing fires Changed for a value it is about to replace.
--]]

local Theme = requireModule("Core/Theme")

local function New(className: string, properties: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for property, value in properties do
		if property == "Theme" then
			for themed, role in value do
				Theme.bind(instance, themed, role)
			end
		else
			instance[property] = value
		end
	end
	instance.Parent = parent
	return instance
end

return New
end

modules["Core/Signal"] = function()
--[[
	Signal - the Changed event on every element handle.

	Each listener runs in its own thread, so a hub callback that errors prints
	its own traceback and the listeners after it still run.
--]]

local Signal = {}
Signal.__index = Signal

type Connection = {
	Connected: boolean,
	Disconnect: (Connection) -> (),
}

function Signal.new()
	return setmetatable({ listeners = {} }, Signal)
end

function Signal:Connect(listener: (...any) -> ()): Connection
	local listeners = self.listeners
	table.insert(listeners, listener)

	local connection = { Connected = true }
	function connection.Disconnect()
		if not connection.Connected then
			return
		end
		connection.Connected = false
		local index = table.find(listeners, listener)
		if index then
			table.remove(listeners, index)
		end
	end
	return connection
end

function Signal:Fire(...: any)
	for _, listener in table.clone(self.listeners) do
		task.spawn(listener, ...)
	end
end

function Signal:Destroy()
	table.clear(self.listeners)
end

return Signal
end

modules["Core/Theme"] = function()
--[[
	Theme - one palette at a time, addressed by role.

	Static colours are bound with `bind`, which remembers the instance and the
	role, so `set` recolours everything already on screen. Colours that depend
	on state (hover, on, disabled) are read with `get` inside a render function
	that also listens to `changed`, so a theme switch never strands a hovered
	row in the old palette.

	Every palette must define every role in ROLES. A missing one is an error at
	registration rather than a nil colour discovered on some later hover.
--]]

local Signal = requireModule("Core/Signal")

local ROLES = {
	"background",
	"surface",
	"raised",
	"hover",
	"stroke",
	"text",
	"textMuted",
	"accent",
	"accentHover",
	"onAccent",
	"focus",
	"success",
	"warning",
	"danger",
	"info",
}

local Theme = {}
Theme.ROLES = ROLES
Theme.changed = Signal.new()

local palettes = {}
local names = {}
local current

-- Strong keys released on Destroying. A weak-keyed table of Instances loses
-- entries whenever Luau collects the reference while the instance is alive.
local bindings = {}

function Theme.register(palette: { [string]: any })
	local name = palette.name
	assert(type(name) == "string", "a theme needs a name")
	for _, role in ROLES do
		if palette[role] == nil then
			error(`theme {name} has no {role} colour`, 2)
		end
	end
	if not palettes[name] then
		table.insert(names, name)
	end
	palettes[name] = palette
	current = current or palette
end

function Theme.set(name: string)
	local palette = palettes[name]
	if not palette then
		error(`no theme named {name}`, 2)
	end
	current = palette
	for instance, roles in bindings do
		for property, role in roles do
			instance[property] = palette[role]
		end
	end
	Theme.changed:Fire(name)
end

function Theme.get(role: string): Color3
	local colour = current[role]
	if colour == nil then
		error(`unknown theme role {role}`, 2)
	end
	return colour
end

function Theme.bind(instance: Instance, property: string, role: string)
	local roles = bindings[instance]
	if not roles then
		roles = {}
		bindings[instance] = roles
		instance.Destroying:Once(function()
			bindings[instance] = nil
		end)
	end
	roles[property] = role
	instance[property] = Theme.get(role)
end

function Theme.current(): string
	return current.name
end

function Theme.list(): { string }
	return table.clone(names)
end

return Theme
end

modules["Core/Trove"] = function()
--[[
	Trove - owns what a window, element or popup creates, so one `clean` call
	removes all of it: connections, instances, threads, Signals, nested troves
	and plain cleanup functions.

	Items are released newest first. A later item usually depends on an earlier
	one (a connection on a frame the trove also destroys), and releasing in
	reverse never touches something already gone.
--]]

local Trove = {}
Trove.__index = Trove

local function release(item: any)
	local kind = typeof(item)
	if kind == "function" then
		item()
	elseif kind == "thread" then
		task.cancel(item)
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif item.Disconnect then
		item:Disconnect()
	else
		item:Destroy()
	end
end

function Trove.new()
	return setmetatable({ items = {} }, Trove)
end

function Trove:add<T>(item: T): T
	table.insert(self.items, item)
	return item
end

function Trove:connect(signal: any, listener: (...any) -> ()): any
	return self:add(signal:Connect(listener))
end

-- A child trove is cleaned with its parent, or on its own when the thing it
-- owns (one element, one popup) goes away first.
function Trove:extend()
	local child = Trove.new()
	self:add(child)
	return child
end

function Trove:clean()
	local items = self.items
	self.items = {}
	for index = #items, 1, -1 do
		release(items[index])
	end
end

Trove.Destroy = Trove.clean

return Trove
end

modules["Elements/Button"] = function()
--[[
	Button - a whole row that runs its Callback once per press.

	    Tab:Button({
	        Title = "Rejoin server",
	        Description = "Same place, new server",
	        Callback = rejoin,
	    })

	The chevron marks the row as something to press, since the row itself looks
	like every other row until the pointer or selection reaches it.
--]]

local Icons = requireModule("Core/Icons")
local New = requireModule("Core/New")
local Row = requireModule("Elements/Row")

local Button = {}

function Button.new(container: any, options: { [string]: any })
	assert(type(options.Callback) == "function", "Button needs a Callback function")
	local row = Row.button(container, options)

	New("ImageLabel", {
		Name = "Chevron",
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve(options.Icon or "chevron-right"),
		Theme = { ImageColor3 = "textMuted" },
	}, row.slot)

	row.trove:connect(row.frame.Activated, function()
		options.Callback()
	end)

	function row:Press()
		options.Callback()
	end

	return row
end

return Button
end

modules["Elements/ColorPicker"] = function()
--[[
	ColorPicker - a Color3 chosen on a saturation/value square and a hue bar,
	or typed as a hex code.

	    Tab:ColorPicker({
	        Title = "ESP colour",
	        Default = Color3.fromRGB(72, 201, 162),
	        Flag = "EspColour",
	        Callback = function(colour) ... end,
	    })

	The square is three frames and two UIGradients, no images: the hue fills
	the frame, a white-to-clear gradient runs left to right over it, and a
	clear-to-black gradient runs top to bottom over that. Nothing to upload,
	nothing to moderate, and it renders crisply at any size.

	The swatch and hex update while dragging; the Callback runs when the drag
	ends or a typed hex code is accepted, so an ESP rebuilding on every colour
	change does not rebuild sixty times a second.
--]]

local UserInputService = game:GetService("UserInputService")

local New = requireModule("Core/New")
local Popup = requireModule("Components/Popup")
local Row = requireModule("Elements/Row")

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SQUARE = Vector2.new(208, 140)
local HUE_HEIGHT = 16
local CURSOR = 12
local PANEL_WIDTH = 224
local PANEL_HEIGHT = 16 + SQUARE.Y + 8 + HUE_HEIGHT + 8 + 32

local ColorPicker = {}

local function hueSequence(): ColorSequence
	local points = {}
	for index = 0, 6 do
		local hue = index / 6
		table.insert(points, ColorSequenceKeypoint.new(hue, Color3.fromHSV(hue % 1, 1, 1)))
	end
	return ColorSequence.new(points)
end

local function press(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

function ColorPicker.new(container: any, options: { [string]: any })
	local callback = options.Callback
	local row = Row.button(container, options)
	local colour: Color3 = options.Default or Color3.fromRGB(255, 255, 255)
	local hue, saturation, brightness = colour:ToHSV()

	local hex = New("TextLabel", {
		Name = "Hex",
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, row.slot)
	local swatch = New("Frame", {
		Name = "Swatch",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(28, 20),
		BackgroundColor3 = colour,
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, swatch)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, swatch)

	local function show()
		swatch.BackgroundColor3 = colour
		hex.Text = "#" .. string.upper(colour:ToHex())
	end

	function row:Get(): Color3
		return colour
	end

	function row:Set(value: Color3)
		colour = value
		hue, saturation, brightness = value:ToHSV()
		show()
		self.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	row.Encode = function(value: Color3): string
		return value:ToHex()
	end
	row.Decode = function(raw: string): Color3
		return Color3.fromHex(raw)
	end

	local function openPicker()
		local popup = Popup.open(container.kit, row.frame, PANEL_WIDTH, PANEL_HEIGHT)
		local trove = popup.trove
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, popup.panel)

		local square = New("Frame", {
			Name = "Square",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(SQUARE.X, SQUARE.Y),
			Active = true,
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, square)
		local whiten = New("Frame", {
			Name = "Saturation",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = WHITE,
		}, square)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, whiten)
		New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, whiten)
		local darken = New("Frame", {
			Name = "Value",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = BLACK,
		}, square)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, darken)
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, darken)
		local cursor = New("Frame", {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(CURSOR, CURSOR),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, square)
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, cursor)
		New("UIStroke", { Thickness = 2, Color = WHITE }, cursor)

		local bar = New("Frame", {
			Name = "Hue",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, HUE_HEIGHT),
			BackgroundColor3 = WHITE,
			Active = true,
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, bar)
		New("UIGradient", { Color = hueSequence() }, bar)
		local marker = New("Frame", {
			Name = "Marker",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 4, 1, 4),
			BackgroundColor3 = WHITE,
		}, bar)
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, marker)
		New("UIStroke", { Thickness = 1, Color = BLACK }, marker)

		local field = New("TextBox", {
			Name = "HexField",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 32),
			ClearTextOnFocus = false,
			FontFace = Font.fromEnum(Enum.Font.BuilderSans),
			TextSize = 14,
			Text = "",
			Theme = { BackgroundColor3 = "background", TextColor3 = "text" },
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, field)

		local function paint()
			square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			cursor.Position = UDim2.fromScale(saturation, 1 - brightness)
			marker.Position = UDim2.fromScale(hue, 0.5)
			field.Text = "#" .. string.upper(colour:ToHex())
		end

		local dragging: GuiObject? = nil
		local function track(position: Vector3)
			local target = dragging :: GuiObject
			local corner, size = target.AbsolutePosition, target.AbsoluteSize
			local across = math.clamp((position.X - corner.X) / size.X, 0, 1)
			if target == bar then
				hue = across
			else
				saturation = across
				brightness = 1 - math.clamp((position.Y - corner.Y) / size.Y, 0, 1)
			end
			colour = Color3.fromHSV(hue, saturation, brightness)
			show()
			paint()
		end

		for _, surface in { square, bar } do
			trove:connect(surface.InputBegan, function(input: InputObject)
				if press(input) then
					dragging = surface
					track(input.Position)
				end
			end)
		end
		trove:connect(UserInputService.InputChanged, function(input: InputObject)
			local moving = input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			if dragging and moving then
				track(input.Position)
			end
		end)
		trove:connect(UserInputService.InputEnded, function(input: InputObject)
			if dragging and press(input) then
				dragging = nil
				row:Set(colour)
			end
		end)
		trove:connect(field.FocusLost, function()
			local code = string.match(field.Text, "^%s*#?(%x%x%x%x%x%x)%s*$")
			if code then
				row:Set(Color3.fromHex(code))
			end
			paint()
		end)
		paint()
	end

	row.trove:connect(row.frame.Activated, openPicker)
	show()
	return row
end

return ColorPicker
end

modules["Elements/Divider"] = function()
--[[
	Divider - a 1 px rule between groups of rows that do not need a Section.

	It takes the stroke colour, one step above the rows around it, so it
	separates without competing with the rows' own edges.
--]]

local New = requireModule("Core/New")

local Divider = {}

function Divider.new(container: any)
	local trove = container.trove:extend()
	local line = New("Frame", {
		Name = "Divider",
		LayoutOrder = container:nextOrder(),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		Theme = { BackgroundColor3 = "stroke" },
	}, container.frame)
	trove:add(line)

	return {
		Frame = line,
		trove = trove,
		Destroy = function()
			trove:clean()
		end,
	}
end

return Divider
end

modules["Elements/Dropdown"] = function()
--[[
	Dropdown - one value, or several with Multi = true, from a list of strings.

	    Tab:Dropdown({
	        Title = "Target",
	        Values = { "Nearest", "Lowest health" },
	        Default = "Nearest",
	        Flag = "Target",
	        Callback = function(choice) ... end,
	    })

	The whole row opens the list; the current choice is shown in the slot, so
	the row reads as a sentence ("Target  Nearest") without opening anything.
	Past eight values the list gets a search box, because scrolling forty
	player names on a phone is how the wrong one gets picked.

	Values are what the Callback receives: a string or nil, or for Multi an
	array in the order of `Values`, never in the order the player clicked.
	`Refresh` drops any selection the new list no longer contains, so a
	player who left the server cannot stay selected.
--]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Icons = requireModule("Core/Icons")
local Motion = requireModule("Core/Motion")
local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")
local Popup = requireModule("Components/Popup")
local Row = requireModule("Elements/Row")

local OPTION_HEIGHT = 44
local SEARCH_FROM = 9
local LIST_WIDTH = 240
local MAX_HEIGHT = 300

local Dropdown = {}

local function lastInputIsGamepad(): boolean
	return string.find(tostring(UserInputService:GetLastInputType()), "Gamepad", 1, true) ~= nil
end

function Dropdown.new(container: any, options: { [string]: any })
	local multi = options.Multi == true
	local callback = options.Callback
	local values: { string } = table.clone(options.Values or {})
	local row = Row.button(container, options)
	local trove = row.trove

	local chosen: { [string]: boolean } = {}
	if multi then
		for _, name in options.Default or {} do
			chosen[name] = true
		end
	elseif options.Default ~= nil then
		chosen[options.Default] = true
	end

	local summary = New("TextLabel", {
		Name = "Summary",
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Theme = { TextColor3 = "textMuted" },
	}, row.slot)
	New("UISizeConstraint", { MaxSize = Vector2.new(160, 20) }, summary)
	New("ImageLabel", {
		Name = "Chevron",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve("chevron-down"),
		Theme = { ImageColor3 = "textMuted" },
	}, row.slot)

	local function current(): any
		if not multi then
			for _, name in values do
				if chosen[name] then
					return name
				end
			end
			return nil
		end
		local list = {}
		for _, name in values do
			if chosen[name] then
				table.insert(list, name)
			end
		end
		return list
	end

	local function render()
		local value = current()
		if not multi then
			summary.Text = value or "None"
		elseif #value == 0 then
			summary.Text = "None"
		elseif #value <= 2 then
			summary.Text = table.concat(value, ", ")
		else
			summary.Text = `{#value} selected`
		end
	end

	local function commit()
		render()
		local value = current()
		row.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	function row:Get(): any
		return current()
	end

	function row:Set(value: any)
		table.clear(chosen)
		if multi then
			for _, name in value or {} do
				chosen[name] = true
			end
		elseif value ~= nil then
			chosen[value] = true
		end
		commit()
	end

	function row:Refresh(list: { string })
		values = table.clone(list)
		local kept = {}
		for _, name in values do
			kept[name] = chosen[name]
		end
		chosen = kept
		commit()
	end

	local function openList()
		local searchable = #values >= SEARCH_FROM
		local listHeight = math.min(#values * (OPTION_HEIGHT + 4), MAX_HEIGHT)
		local height = listHeight + 16 + (if searchable then OPTION_HEIGHT + 8 else 0)
		local popup = Popup.open(container.kit, row.frame, LIST_WIDTH, height)

		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, popup.panel)
		local search = New("TextBox", {
			Name = "Search",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
			Visible = searchable,
			ClearTextOnFocus = false,
			FontFace = Font.fromEnum(Enum.Font.BuilderSans),
			TextSize = 14,
			PlaceholderText = "Search",
			Text = "",
			Theme = {
				BackgroundColor3 = "background",
				TextColor3 = "text",
				PlaceholderColor3 = "textMuted",
			},
		}, popup.panel)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, search)

		local list = New("ScrollingFrame", {
			Name = "Options",
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Theme = { ScrollBarImageColor3 = "stroke" },
		}, popup.panel)
		New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, list)
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, list)

		local buttons = {}
		for order, name in values do
			local option = New("TextButton", {
				Name = name,
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
				AutoButtonColor = false,
				FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = name,
				Theme = { TextColor3 = "text" },
			}, list)
			New("UICorner", { CornerRadius = UDim.new(0, 6) }, option)
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, option)
			local check = New("ImageLabel", {
				Name = "Check",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				Image = Icons.resolve("check"),
				Theme = { ImageColor3 = "accent" },
			}, option)

			local hovered = false

			local function paint()
				check.Visible = chosen[name] == true
				local role = "surface"
				if chosen[name] then
					role = "raised"
				elseif hovered then
					role = "hover"
				end
				Motion.play(option, Motion.state, { BackgroundColor3 = Theme.get(role) })
			end

			popup.trove:connect(option.MouseEnter, function()
				hovered = true
				paint()
			end)
			popup.trove:connect(option.MouseLeave, function()
				hovered = false
				paint()
			end)
			popup.trove:connect(option.SelectionGained, function()
				hovered = true
				paint()
			end)
			popup.trove:connect(option.SelectionLost, function()
				hovered = false
				paint()
			end)

			popup.trove:connect(option.Activated, function()
				if multi then
					chosen[name] = not chosen[name] or nil
				elseif chosen[name] and options.AllowNone then
					chosen[name] = nil
				else
					table.clear(chosen)
					chosen[name] = true
				end
				commit()
				if multi then
					for _, repaint in buttons do
						repaint()
					end
				else
					popup.close()
				end
			end)
			paint()
			buttons[name] = paint
		end

		popup.trove:connect(search:GetPropertyChangedSignal("Text"), function()
			local query = string.lower(search.Text)
			for _, option in list:GetChildren() do
				if option:IsA("GuiButton") then
					local found = string.find(string.lower(option.Name), query, 1, true)
					option.Visible = query == "" or found ~= nil
				end
			end
		end)

		if lastInputIsGamepad() then
			GuiService.SelectedObject = list:FindFirstChildWhichIsA("GuiButton")
		end
	end

	trove:connect(row.frame.Activated, openList)
	row.searchText ..= " " .. table.concat(values, " ")
	render()
	return row
end

return Dropdown
end

modules["Elements"] = function()
--[[
	Elements - the registry that gives every container (a Tab or a Section)
	one method per element: Tab:Toggle({...}), Section:Slider({...}).

	Adding an element is one file in this folder with a `new(container,
	options)` function and one line in REGISTRY. The wrapper below does what
	every element needs and none should repeat: register its Flag with the
	window's config and `Flags` table, make it searchable, and undo both when
	the element is destroyed.

	A handle is the row from Row.luau plus the element's Get and Set, so the
	contract is the same everywhere: Get, Set, Changed, SetTitle,
	SetDescription, SetDisabled, Destroy, Frame.
--]]

local REGISTRY = {
	Button = requireModule("Elements/Button"),
	ColorPicker = requireModule("Elements/ColorPicker"),
	Divider = requireModule("Elements/Divider"),
	Dropdown = requireModule("Elements/Dropdown"),
	Input = requireModule("Elements/Input"),
	Keybind = requireModule("Elements/Keybind"),
	Paragraph = requireModule("Elements/Paragraph"),
	Slider = requireModule("Elements/Slider"),
	Toggle = requireModule("Elements/Toggle"),
}

local Elements = {}

local function create(container: any, name: string, options: { [string]: any })
	local window = container.window
	local flag = options.Flag
	-- Checked before anything is built, so a rejected element leaves no row.
	if flag ~= nil and window.Flags[flag] ~= nil then
		error(`flag {flag} is already used`, 3)
	end

	local element = REGISTRY[name].new(container, options)
	if flag ~= nil then
		assert(element.Get, `{name} has no value to save under a Flag`)
		window.config:register(flag, element)
		window.Flags[flag] = element
		element.trove:add(function()
			window.config:unregister(flag)
			window.Flags[flag] = nil
		end)
	end

	if element.searchText then
		local entry = {
			frame = element.Frame,
			text = string.lower(element.searchText),
			section = container.section,
		}
		table.insert(container.entries, entry)
		element.trove:add(function()
			local index = table.find(container.entries, entry)
			if index then
				table.remove(container.entries, index)
			end
		end)
		window:applySearch()
	end
	return element
end

function Elements.install(container: any)
	for name in REGISTRY do
		container[name] = function(_, options: { [string]: any }?)
			return create(container, name, options or {})
		end
	end
end

function Elements.names(): { string }
	local list = {}
	for name in REGISTRY do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

return Elements
end

modules["Elements/Input"] = function()
--[[
	Input - free text or a number typed by the player.

	    Tab:Input({
	        Title = "Teleport to",
	        Placeholder = "Player name",
	        Flag = "TeleportTarget",
	        Callback = function(name) ... end,
	    })

	The Callback runs when typing finishes (focus lost), not on every
	keystroke, unless `Live = true`. With `Numeric = true` anything that is
	not a number is rejected and the box returns to the last good value,
	so the Callback never receives text it cannot use.

	Pressing the row focuses the box: the box is small, the row is the target.
--]]

local New = requireModule("Core/New")
local Row = requireModule("Elements/Row")

local Input = {}

function Input.new(container: any, options: { [string]: any })
	local numeric = options.Numeric == true
	local callback = options.Callback
	local row = Row.button(container, options)
	local value = if options.Default ~= nil then tostring(options.Default) else ""

	local box = New("TextBox", {
		Name = "Box",
		Size = UDim2.fromOffset(160, 32),
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		PlaceholderText = options.Placeholder or "",
		Text = value,
		Theme = {
			BackgroundColor3 = "background",
			TextColor3 = "text",
			PlaceholderColor3 = "textMuted",
		},
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

	local function accept(text: string): boolean
		return not numeric or text == "" or tonumber(text) ~= nil
	end

	function row:Get(): any
		return if numeric then tonumber(value) else value
	end

	function row:Set(text: any)
		local typed = if text == nil then "" else tostring(text)
		if not accept(typed) then
			box.Text = value
			return
		end
		value = typed
		box.Text = typed
		local result = self:Get()
		self.Changed:Fire(result)
		if callback then
			callback(result)
		end
	end

	row.trove:connect(row.frame.Activated, function()
		box:CaptureFocus()
	end)
	row.trove:connect(box.FocusLost, function()
		if box.Text ~= value then
			row:Set(box.Text)
		end
	end)
	if options.Live then
		row.trove:connect(box:GetPropertyChangedSignal("Text"), function()
			if box:IsFocused() and accept(box.Text) and box.Text ~= value then
				row:Set(box.Text)
			end
		end)
	end

	row.searchText ..= " " .. (options.Placeholder or "")
	return row
end

return Input
end

modules["Elements/Keybind"] = function()
--[[
	Keybind - a key the player chooses, and a Callback when it is pressed.

	    Tab:Keybind({
	        Title = "Fly key",
	        Default = Enum.KeyCode.F,
	        Flag = "FlyKey",
	        Callback = function() fly:Set(not fly:Get()) end,
	    })

	Press the row, then any key or gamepad button: Escape cancels and Backspace
	clears the bind. While it listens, `kit.capturing` stands every window's
	menu key down, so choosing RightShift does not also hide the window.

	Presses the game already consumed (typing in chat, a focused TextBox) never
	fire the Callback. With `Mode = "Hold"` the Callback receives true on press
	and false on release; the default "Press" mode calls it once per press.
--]]

local UserInputService = game:GetService("UserInputService")

local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")
local Row = requireModule("Elements/Row")

local Keybind = {}

local function keyFromName(name: string?): Enum.KeyCode?
	if name == nil or name == "" then
		return nil
	end
	for _, item in Enum.KeyCode:GetEnumItems() do
		if item.Name == name then
			return item
		end
	end
	return nil
end

function Keybind.new(container: any, options: { [string]: any })
	local kit = container.kit
	local hold = options.Mode == "Hold"
	local callback = options.Callback
	local row = Row.button(container, options)
	local trove = row.trove
	local key: Enum.KeyCode? = options.Default
	local listening = false

	local chip = New("TextLabel", {
		Name = "Key",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = "",
		Theme = { BackgroundColor3 = "background" },
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, chip)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, chip)

	local function render()
		chip.Text = if listening then "Press a key" elseif key then key.Name else "None"
		chip.TextColor3 = Theme.get(if listening then "accent" else "text")
	end

	function row:Get(): Enum.KeyCode?
		return key
	end

	function row:Set(newKey: Enum.KeyCode?)
		key = newKey
		render()
		self.Changed:Fire(key)
	end

	row.Encode = function(value: Enum.KeyCode?): string
		return if value then value.Name else ""
	end
	row.Decode = keyFromName

	local function stopListening()
		listening = false
		kit.capturing = false
		render()
	end

	trove:connect(row.frame.Activated, function()
		if listening then
			return
		end
		listening = true
		kit.capturing = true
		render()
	end)

	trove:connect(UserInputService.InputBegan, function(input: InputObject, processed: boolean)
		if listening then
			local pressed = input.KeyCode
			if pressed == Enum.KeyCode.Unknown then
				return
			end
			-- Deferred so the release of the chosen key, and this same press
			-- reaching a window's menu-key check, both see capturing still on.
			task.defer(stopListening)
			if pressed == Enum.KeyCode.Escape then
				return
			end
			row:Set(if pressed == Enum.KeyCode.Backspace then nil else pressed)
			return
		end
		if processed or kit.capturing or key == nil or input.KeyCode ~= key then
			return
		end
		if callback then
			callback(if hold then true else nil)
		end
	end)

	if hold then
		trove:connect(UserInputService.InputEnded, function(input: InputObject, processed: boolean)
			if not processed and key ~= nil and input.KeyCode == key and callback then
				callback(false)
			end
		end)
	end

	trove:add(function()
		if listening then
			kit.capturing = false
		end
	end)
	trove:connect(Theme.changed, render)
	render()
	return row
end

return Keybind
end

modules["Elements/Paragraph"] = function()
--[[
	Paragraph - a titled block of text: instructions, credits, a status line.

	    local status = Tab:Paragraph({ Title = "Status", Content = "Waiting for players" })
	    status:Set({ Content = "Round 3 of 5" })

	`Content` uses the description line, so it wraps and stays readable on a
	narrow window instead of truncating.
--]]

local Row = requireModule("Elements/Row")

local Paragraph = {}

function Paragraph.new(container: any, options: { [string]: any })
	local row = Row.frame(container, {
		Title = options.Title,
		Description = options.Content or options.Description,
	})
	row.description.TextSize = 14

	function row:Set(fields: { Title: string?, Content: string? })
		if fields.Title then
			self:SetTitle(fields.Title)
		end
		if fields.Content then
			self:SetDescription(fields.Content)
		end
	end

	return row
end

return Paragraph
end

modules["Elements/Row"] = function()
--[[
	Row - the one layout every element shares: title and description on the
	left, the element's control in `slot` on the right, and for stacked
	elements (Slider) a full-width `below` line under both.

	A button row is the element's hit area, 44 px tall at minimum, so a phone
	player taps the whole row rather than a 16 px icon. It draws five of the
	six states itself: rest, hover, press, keyboard or gamepad focus, and
	disabled. Selected belongs to the element (a toggle's knob, a dropdown's
	value), so the row leaves it alone.

	The description is always visible under the title. Nothing an element
	needs to say is hidden behind a hover that a touch screen never sends.
--]]

local UserInputService = game:GetService("UserInputService")

local Motion = requireModule("Core/Motion")
local New = requireModule("Core/New")
local Signal = requireModule("Core/Signal")
local Theme = requireModule("Core/Theme")

local ROW_SIZE = UDim2.new(1, 0, 0, 44)

-- The engine's selection outline would draw a second ring over the row's own.
local noSelection = Instance.new("Frame")
noSelection.BackgroundTransparency = 1

local Row = {}

local function isPress(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

local function build(row: any, options: { [string]: any }, stacked: boolean)
	local frame = row.frame
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, frame)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, frame)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, frame)

	local line = New("Frame", {
		Name = "Line",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, frame)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
	}, line)

	local words = New("Frame", {
		Name = "Words",
		LayoutOrder = 1,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, line)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, words)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, words)

	row.title = New("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Title,
		Theme = { TextColor3 = "text" },
	}, words)

	row.description = New("TextLabel", {
		Name = "Description",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Description or "",
		Visible = options.Description ~= nil,
		Theme = { TextColor3 = "textMuted" },
	}, words)

	row.slot = New("Frame", {
		Name = "Slot",
		LayoutOrder = 2,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, line)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, row.slot)

	if stacked then
		row.below = New("Frame", {
			Name = "Below",
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, frame)
	end
end

local function finish(row: any, options: { [string]: any })
	row.searchText = `{options.Title} {options.Description or ""}`
	row.Changed = Signal.new()
	row.trove:add(row.Changed)

	function row:SetTitle(text: string)
		self.title.Text = text
		self.frame.Name = text
	end

	function row:SetDescription(text: string?)
		self.description.Text = text or ""
		self.description.Visible = text ~= nil
	end

	-- The title binding restores "text" on a theme switch; this runs after it.
	local function shade()
		row.title.TextColor3 = Theme.get(if row.frame.Interactable then "text" else "textMuted")
	end
	row.trove:connect(Theme.changed, shade)

	function row:SetDisabled(disabled: boolean)
		self.frame.Interactable = not disabled
		shade()
	end

	function row:Destroy()
		self.trove:clean()
	end

	row.Frame = row.frame
	return row
end

function Row.frame(container: any, options: { [string]: any }, stacked: boolean?): any
	assert(type(options.Title) == "string", "every element needs a Title string")
	local row = { trove = container.trove:extend() }
	row.frame = New("Frame", {
		Name = options.Title,
		LayoutOrder = container:nextOrder(),
		Size = ROW_SIZE,
		AutomaticSize = Enum.AutomaticSize.Y,
		Theme = { BackgroundColor3 = "raised" },
	}, container.frame)
	row.trove:add(row.frame)
	build(row, options, stacked == true)
	return finish(row, options)
end

function Row.button(container: any, options: { [string]: any }): any
	assert(type(options.Title) == "string", "every element needs a Title string")
	local row = { trove = container.trove:extend() }
	local frame = New("TextButton", {
		Name = options.Title,
		LayoutOrder = container:nextOrder(),
		Size = ROW_SIZE,
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoButtonColor = false,
		Text = "",
		SelectionImageObject = noSelection,
		BackgroundColor3 = Theme.get("raised"),
	}, container.frame)
	row.frame = frame
	row.trove:add(frame)
	build(row, options, false)

	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 2,
		Enabled = false,
		Theme = { Color = "focus" },
	}, frame)

	local hovered, pressed, focused = false, false, false
	local function render()
		local enabled = frame.Interactable
		local role = "raised"
		if enabled and pressed then
			role = "stroke"
		elseif enabled and hovered then
			role = "hover"
		end
		Motion.play(frame, Motion.state, { BackgroundColor3 = Theme.get(role) })
		frame.BackgroundTransparency = if enabled then 0 else 0.4
		ring.Enabled = focused and enabled
	end

	local trove = row.trove
	trove:connect(frame.MouseEnter, function()
		hovered = true
		render()
	end)
	trove:connect(frame.MouseLeave, function()
		hovered, pressed = false, false
		render()
	end)
	trove:connect(frame.InputBegan, function(input: InputObject)
		if isPress(input) then
			pressed = true
			render()
		end
	end)
	trove:connect(UserInputService.InputEnded, function(input: InputObject)
		if pressed and isPress(input) then
			pressed = false
			render()
		end
	end)
	trove:connect(frame.SelectionGained, function()
		focused = true
		render()
	end)
	trove:connect(frame.SelectionLost, function()
		focused = false
		render()
	end)
	trove:connect(frame:GetPropertyChangedSignal("Interactable"), render)
	trove:connect(Theme.changed, render)
	return finish(row, options)
end

return Row
end

modules["Elements/Slider"] = function()
--[[
	Slider - a number between Min and Max, snapped to Step.

	    Tab:Slider({
	        Title = "Walk speed",
	        Min = 16,
	        Max = 120,
	        Default = 16,
	        Suffix = "studs/s",
	        Flag = "WalkSpeed",
	        Callback = function(speed) ... end,
	    })

	Three ways to change it, one per input: drag the track (mouse and touch),
	type into the value box (exact values on a phone, where dragging to 37 is
	fiddly), or select the track and press left and right (keyboard, gamepad).
	The arrows are bound through ContextActionService while the track is
	selected; UserInputService would see them already consumed by gamepad
	navigation, which moves the selection instead.

	The drag follows UserInputService.InputChanged, not the track's own
	events, because the pointer leaves the track on the first pixel of a fast
	drag and the track would stop hearing it.
--]]

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")
local Row = requireModule("Elements/Row")

local BAR_HEIGHT = 6
local KNOB = 16

local Slider = {}

local nextAction = 0

local function decimalsOf(step: number): number
	local text = string.format("%.6f", step):gsub("0+$", "")
	local dot = string.find(text, ".", 1, true)
	return if dot then #text - dot else 0
end

function Slider.new(container: any, options: { [string]: any })
	local minimum, maximum = options.Min, options.Max
	local numeric = type(minimum) == "number" and type(maximum) == "number"
	assert(numeric, "Slider needs numeric Min and Max")
	assert(maximum > minimum, "Slider Max must be greater than Min")
	local step = options.Step or 1
	local decimals = decimalsOf(step)
	local suffix = if options.Suffix then " " .. options.Suffix else ""
	local callback = options.Callback

	local row = Row.frame(container, options, true)
	local trove = row.trove

	local function snap(raw: number): number
		local snapped = minimum + math.round((raw - minimum) / step) * step
		local clamped = math.clamp(snapped, minimum, maximum)
		return tonumber(string.format(`%.{decimals}f`, clamped)) :: number
	end

	local value = snap(options.Default or minimum)

	local box = New("TextBox", {
		Name = "Value",
		Size = UDim2.fromOffset(88, 28),
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansMedium),
		TextSize = 14,
		Text = "",
		Theme = { BackgroundColor3 = "background", TextColor3 = "text" },
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, box)

	local hit = New("TextButton", {
		Name = "Track",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row.below)

	local bar = New("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		Theme = { BackgroundColor3 = "hover" },
	}, hit)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)

	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "accent" },
	}, bar)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)

	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(KNOB, KNOB),
		Theme = { BackgroundColor3 = "text" },
	}, hit)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, knob)
	local ring = New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 2,
		Enabled = false,
		Theme = { Color = "focus" },
	}, knob)

	local function render()
		local alpha = (value - minimum) / (maximum - minimum)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		if not box:IsFocused() then
			box.Text = string.format(`%.{decimals}f`, value) .. suffix
		end
	end

	function row:Get(): number
		return value
	end

	function row:Set(raw: number)
		value = snap(raw)
		render()
		self.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	local function setFromX(x: number)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local snapped = snap(minimum + alpha * (maximum - minimum))
		if snapped ~= value then
			row:Set(snapped)
		end
	end

	local dragging: InputObject? = nil
	trove:connect(hit.InputBegan, function(input: InputObject)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		if row.frame.Interactable then
			dragging = input
			setFromX(input.Position.X)
		end
	end)
	trove:connect(UserInputService.InputChanged, function(input: InputObject)
		if not dragging then
			return
		end
		local mouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local mouseDrag = mouse and dragging.UserInputType == Enum.UserInputType.MouseButton1
		if input == dragging or mouseDrag then
			setFromX(input.Position.X)
		end
	end)
	trove:connect(UserInputService.InputEnded, function(input: InputObject)
		if dragging and (input == dragging or input.UserInputType == dragging.UserInputType) then
			dragging = nil
		end
	end)

	trove:connect(box.FocusLost, function()
		local typed = tonumber((string.gsub(box.Text, "[^%d%.%-]", "")))
		if typed and row.frame.Interactable then
			row:Set(typed)
		else
			render()
		end
	end)

	nextAction += 1
	local action = `HubKitSlider{nextAction}`
	local function nudge(_, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local key = input.KeyCode
		local down = key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft
		row:Set(value + (if down then -step else step))
		return Enum.ContextActionResult.Sink
	end
	trove:connect(hit.SelectionGained, function()
		ring.Enabled = true
		ContextActionService:BindActionAtPriority(
			action,
			nudge,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Left,
			Enum.KeyCode.Right,
			Enum.KeyCode.DPadLeft,
			Enum.KeyCode.DPadRight
		)
	end)
	trove:connect(hit.SelectionLost, function()
		ring.Enabled = false
		ContextActionService:UnbindAction(action)
	end)
	trove:add(function()
		ContextActionService:UnbindAction(action)
	end)

	row.searchText ..= suffix
	render()
	return row
end

return Slider
end

modules["Elements/Toggle"] = function()
--[[
	Toggle - an on/off switch across the whole row.

	    local fly = Tab:Toggle({
	        Title = "Fly",
	        Flag = "Fly",
	        Callback = function(on) ... end,
	    })

	The knob moves as well as changing colour, so on and off differ for a
	player who cannot tell the two colours apart. A toggle built with
	`Default = true` runs its Callback once, deferred, because a switch drawn
	on must mean the feature is on. Other elements only show their Default.

	`Set` always runs the Callback, even with the value it already has. That
	is what makes loading a config start every saved feature, including the
	ones whose saved value matches the default.
--]]

local Motion = requireModule("Core/Motion")
local New = requireModule("Core/New")
local Theme = requireModule("Core/Theme")
local Row = requireModule("Elements/Row")

local TRACK_WIDTH = 40
local TRACK_HEIGHT = 24
local KNOB = 18
local INSET = 3

local Toggle = {}

function Toggle.new(container: any, options: { [string]: any })
	local callback = options.Callback
	local row = Row.button(container, options)
	local value = options.Default == true

	local track = New("Frame", {
		Name = "Track",
		Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT),
	}, row.slot)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)

	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(KNOB, KNOB),
	}, track)
	New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, knob)

	local function render()
		local enabled = row.frame.Interactable
		local fill = if value then "accent" else "hover"
		Motion.play(track, Motion.state, {
			BackgroundColor3 = Theme.get(if enabled then fill else "stroke"),
		})
		Motion.play(knob, Motion.state, {
			Position = UDim2.new(0, if value then TRACK_WIDTH - KNOB - INSET else INSET, 0.5, 0),
			BackgroundColor3 = Theme.get(if value then "onAccent" else "textMuted"),
		})
	end

	function row:Get(): boolean
		return value
	end

	function row:Set(on: boolean)
		value = on == true
		render()
		self.Changed:Fire(value)
		if callback then
			callback(value)
		end
	end

	row.trove:connect(row.frame.Activated, function()
		row:Set(not value)
	end)
	row.trove:connect(row.frame:GetPropertyChangedSignal("Interactable"), render)
	row.trove:connect(Theme.changed, render)
	render()

	if value and callback then
		task.defer(callback, true)
	end
	return row
end

return Toggle
end

modules[""] = function()
--[[
	HubKit - a UI library for script hubs: windows with tabs, sections,
	nine element types, notifications, dialogs, themes and saved configs.

	    local HubKit = loadstring(game:HttpGet(HUBKIT_URL))()
	    local Window = HubKit:CreateWindow({ Title = "My Hub", Icon = "sparkles" })
	    local Main = Window:Tab({ Title = "Main", Icon = "home" })
	    Main:Toggle({ Title = "Fly", Flag = "Fly", Callback = setFly })
	    Window:SettingsTab()

	The folder layout, the element contract and how to add an element are in
	library/hub-kit/README.md. dist/HubKit.luau is this folder bundled into one
	file by tools/bin/build-hub-kit.mjs; edit these sources, never the bundle.
--]]

local Icons = requireModule("Core/Icons")
local Theme = requireModule("Core/Theme")
local Config = requireModule("Core/Config")
local Elements = requireModule("Elements")
local Notifications = requireModule("Components/Notifications")
local Window = requireModule("Components/Window")

for _, palette in requireModule("Themes") do
	Theme.register(palette)
end

local kit = { windows = {}, capturing = false, popup = nil, toasts = nil }
function kit.notify(notice: { [string]: any })
	return Notifications.push(kit, notice)
end

local HubKit = {
	Version = "1.0.0",
	CanSaveConfigs = Config.available,
}

function HubKit:CreateWindow(options: { [string]: any })
	local window = Window.new(kit, options)
	table.insert(kit.windows, window)
	return window
end

function HubKit:Notify(notice: { [string]: any })
	return kit.notify(notice)
end

function HubKit:SetTheme(name: string)
	Theme.set(name)
end

function HubKit:AddTheme(palette: { [string]: any })
	Theme.register(palette)
end

function HubKit:GetThemes(): { string }
	return Theme.list()
end

function HubKit:GetIcons(): { string }
	return Icons.names()
end

function HubKit:GetElements(): { string }
	return Elements.names()
end

function HubKit:Unload()
	for _, window in table.clone(kit.windows) do
		window:Unload()
	end
	Notifications.clear(kit)
end

return HubKit
end

modules["Themes/Daylight"] = function()
-- A light palette for bright rooms and players who read better on white. Every
-- text role meets 4.5:1 on its surfaces; tools/tests/hub-kit.test.mjs checks each pair.
return {
	name = "Daylight",
	background = Color3.fromRGB(238, 240, 244),
	surface = Color3.fromRGB(250, 251, 252),
	raised = Color3.fromRGB(255, 255, 255),
	hover = Color3.fromRGB(231, 234, 239),
	stroke = Color3.fromRGB(206, 211, 220),
	text = Color3.fromRGB(20, 22, 27),
	textMuted = Color3.fromRGB(84, 90, 102),
	accent = Color3.fromRGB(22, 122, 94),
	accentHover = Color3.fromRGB(17, 99, 76),
	onAccent = Color3.fromRGB(255, 255, 255),
	focus = Color3.fromRGB(22, 122, 94),
	success = Color3.fromRGB(28, 128, 72),
	warning = Color3.fromRGB(156, 98, 12),
	danger = Color3.fromRGB(190, 52, 46),
	info = Color3.fromRGB(37, 99, 190),
}
end

modules["Themes/Ember"] = function()
-- Warm dark neutrals with an orange accent. Every text role meets 4.5:1 on the
-- surfaces it sits on; tools/tests/hub-kit.test.mjs checks each pair.
return {
	name = "Ember",
	background = Color3.fromRGB(21, 17, 15),
	surface = Color3.fromRGB(33, 27, 24),
	raised = Color3.fromRGB(45, 37, 33),
	hover = Color3.fromRGB(60, 50, 45),
	stroke = Color3.fromRGB(74, 62, 55),
	text = Color3.fromRGB(247, 241, 237),
	textMuted = Color3.fromRGB(178, 165, 156),
	accent = Color3.fromRGB(236, 124, 60),
	accentHover = Color3.fromRGB(246, 154, 102),
	onAccent = Color3.fromRGB(21, 17, 15),
	focus = Color3.fromRGB(246, 154, 102),
	success = Color3.fromRGB(104, 190, 120),
	warning = Color3.fromRGB(230, 176, 74),
	danger = Color3.fromRGB(232, 104, 96),
	info = Color3.fromRGB(110, 160, 230),
}
end

modules["Themes"] = function()
-- The first palette is the default; HubKit:AddTheme appends more at run time.
return {
	requireModule("Themes/Midnight"),
	requireModule("Themes/Daylight"),
	requireModule("Themes/Ember"),
}
end

modules["Themes/Midnight"] = function()
-- The default palette: cool neutrals and a green accent. Every text role meets
-- 4.5:1 on the surfaces it sits on; tools/tests/hub-kit.test.mjs checks each pair.
return {
	name = "Midnight",
	background = Color3.fromRGB(17, 19, 24),
	surface = Color3.fromRGB(27, 30, 37),
	raised = Color3.fromRGB(38, 42, 51),
	hover = Color3.fromRGB(52, 57, 68),
	stroke = Color3.fromRGB(62, 68, 80),
	text = Color3.fromRGB(241, 243, 247),
	textMuted = Color3.fromRGB(165, 171, 183),
	accent = Color3.fromRGB(46, 160, 127),
	accentHover = Color3.fromRGB(72, 201, 162),
	onAccent = Color3.fromRGB(9, 10, 13),
	focus = Color3.fromRGB(72, 201, 162),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	danger = Color3.fromRGB(224, 98, 92),
	info = Color3.fromRGB(88, 141, 214),
}
end

return requireModule("")
