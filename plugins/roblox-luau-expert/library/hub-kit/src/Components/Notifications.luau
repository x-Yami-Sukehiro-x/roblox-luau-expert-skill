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

local Icons = require(script.Parent.Parent.Core.Icons)
local Motion = require(script.Parent.Parent.Core.Motion)
local Mount = require(script.Parent.Parent.Core.Mount)
local New = require(script.Parent.Parent.Core.New)
local Trove = require(script.Parent.Parent.Core.Trove)

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
