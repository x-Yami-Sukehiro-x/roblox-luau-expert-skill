--!strict
-- lint: complete
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Placement = "N1" | "N2" | "N4" | "N7"
export type Severity = "info" | "success" | "warning" | "error"

export type ProgressHandle = {
	done: (message: string, severity: Severity?) -> (),
}

export type Notifier = {
	push: (message: string, severity: Severity?, key: string?) -> (),
	progress: (message: string) -> ProgressHandle,
	action: (message: string, actionLabel: string, onAction: () -> ()) -> (),
	destroy: () -> (),
}

-- The toast reads the same surface entry as the panel it sits beside, so fill,
-- edge and radius cannot drift apart between the two.
local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	action = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	success = "rbxassetid://88244323237265",
	warning = "rbxassetid://91165848022002",
	error = "rbxassetid://106305483906363",
	close = "rbxassetid://116396312853810",
	loading = "rbxassetid://71250150569964",
}

-- direction is which way the stack grows from its anchor; arrive is where a new
-- toast starts before it settles into its slot; timed stacks show a time-left bar.
local PLACEMENT = {
	N1 = {
		anchor = Vector2.new(0.5, 1),
		direction = -1,
		arrive = Vector2.new(0, 12),
		timed = false,
	},
	N2 = {
		anchor = Vector2.new(0.5, 0),
		direction = 1,
		arrive = Vector2.new(0, -8),
		timed = false,
	},
	N4 = {
		anchor = Vector2.new(1, 1),
		direction = -1,
		arrive = Vector2.new(24, 0),
		timed = true,
	},
	N7 = {
		anchor = Vector2.new(1, 0),
		direction = 1,
		arrive = Vector2.new(24, 0),
		timed = true,
	},
}

local MAX_VISIBLE = 3
local MAX_QUEUED = 10
local GAP = 8
local EDGE_INSET = 16
local MIN_HOLD = 1.5
local ACTION_HOLD = 6
local SETTLE_TIME = 0.12
local SPIN_DEGREES_PER_SECOND = 360
local FADE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)

type Request = {
	message: string,
	severity: Severity,
	key: string?,
	kind: "plain" | "progress" | "action",
	actionLabel: string?,
	onAction: (() -> ())?,
	toast: Toast?,
}

type Toast = {
	request: Request,
	count: number,
	card: CanvasGroup,
	content: Frame,
	icon: ImageLabel,
	label: TextLabel,
	timerBar: Frame?,
	dismiss: ImageButton?,
	offset: Vector2,
	velocity: Vector2,
	goal: Vector2,
	height: number,
	lifetime: number,
	remaining: number,
	held: boolean,
	connections: { RBXScriptConnection },
}

local function readingTime(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.max(MIN_HOLD, math.clamp(2 + words * 0.3, 3, 8))
end

local function createNotifier(screen: ScreenGui, placement: Placement): Notifier
	local layout = PLACEMENT[placement]
	local shown: { Toast } = {}
	local waiting: { Request } = {}
	local byKey: { [string]: Toast } = {}
	local loop: RBXScriptConnection? = nil

	local stack = Instance.new("Frame")
	stack.Name = "Notifications"
	stack.AnchorPoint = layout.anchor
	stack.Position = UDim2.new(
		layout.anchor.X,
		(0.5 - layout.anchor.X) * 2 * EDGE_INSET,
		layout.anchor.Y,
		(0.5 - layout.anchor.Y) * 2 * EDGE_INSET
	)
	stack.Size = UDim2.new(1, -EDGE_INSET * 2, 1, -EDGE_INSET * 2)
	stack.BackgroundTransparency = 1
	stack.Parent = screen

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(240, 0)
	bounds.MaxSize = Vector2.new(360, math.huge)
	bounds.Parent = stack

	local function place(toast: Toast)
		local anchor = layout.anchor
		toast.card.Position = UDim2.new(anchor.X, toast.offset.X, anchor.Y, toast.offset.Y)
	end

	-- Targets come from list order, never from a stored slot, so the toast under
	-- one that leaves early moves up while it may still be arriving.
	local function restack()
		local travelled = 0
		for _, toast in shown do
			toast.goal = Vector2.new(0, travelled * layout.direction)
			travelled += toast.height + GAP
		end
	end

	local release: (toast: Toast) -> ()
	local present: (request: Request) -> ()

	local function step(dt: number)
		for index = #shown, 1, -1 do
			local toast = shown[index]
			local goal, velocity = toast.goal, toast.velocity
			toast.offset, toast.velocity =
				TweenService:SmoothDamp(toast.offset, goal, velocity, SETTLE_TIME, nil, dt)
			place(toast)
			local request = toast.request
			if request.kind == "progress" then
				toast.icon.Rotation = (toast.icon.Rotation + dt * SPIN_DEGREES_PER_SECOND) % 360
				continue
			end
			if toast.held or request.severity == "error" then
				continue
			end
			toast.remaining -= dt
			local timerBar = toast.timerBar
			if timerBar then
				timerBar.Size = UDim2.new(math.max(toast.remaining / toast.lifetime, 0), 0, 0, 2)
			end
			if toast.remaining <= 0 then
				release(toast)
			end
		end
		if #shown == 0 and loop then
			loop:Disconnect()
			loop = nil
		end
	end

	function release(toast: Toast)
		local index = table.find(shown, toast)
		if not index then
			return
		end
		table.remove(shown, index)
		if toast.request.key then
			byKey[toast.request.key] = nil
		end
		for _, connection in toast.connections do
			connection:Disconnect()
		end
		restack()

		local fade = TweenService:Create(toast.card, FADE_OUT, { GroupTransparency = 1 })
		fade.Completed:Once(function()
			toast.card:Destroy()
		end)
		fade:Play()

		local nextRequest = table.remove(waiting, 1)
		if nextRequest then
			present(nextRequest)
		end
	end

	local function addDismiss(toast: Toast)
		local dismiss = Instance.new("ImageButton")
		dismiss.Name = "Dismiss"
		dismiss.LayoutOrder = 4
		dismiss.Size = UDim2.fromOffset(44, 44)
		dismiss.AutoButtonColor = false
		dismiss.BackgroundTransparency = 1
		dismiss.Image = ""
		dismiss.Parent = toast.content

		local ink = Instance.new("ImageLabel")
		ink.Name = "Ink"
		ink.AnchorPoint = Vector2.new(0.5, 0.5)
		ink.Position = UDim2.fromScale(0.5, 0.5)
		ink.Size = UDim2.fromOffset(16, 16)
		ink.BackgroundTransparency = 1
		ink.Image = ICON.close
		ink.ImageColor3 = THEME.text
		ink.Parent = dismiss

		toast.dismiss = dismiss
		table.insert(toast.connections, dismiss.Activated:Connect(function()
			release(toast)
		end))
	end

	-- The row lives in its own frame so the timer bar can sit on the card's
	-- bottom edge; a child of a UIListLayout would be placed in the row.
	local function addTimer(toast: Toast)
		local timerBar = Instance.new("Frame")
		timerBar.Name = "TimeLeft"
		timerBar.AnchorPoint = Vector2.new(0, 1)
		timerBar.Position = UDim2.fromScale(0, 1)
		timerBar.Size = UDim2.new(1, 0, 0, 2)
		timerBar.BackgroundColor3 = THEME[toast.request.severity]
		timerBar.BorderSizePixel = 0
		timerBar.Parent = toast.card
		toast.timerBar = timerBar
	end

	local function addAction(toast: Toast, actionLabel: string, onAction: () -> ())
		local button = Instance.new("TextButton")
		button.Name = "Action"
		button.LayoutOrder = 3
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, 44)
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1
		button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		button.TextSize = 14
		button.TextColor3 = THEME.action
		button.Text = actionLabel
		button.Parent = toast.content

		table.insert(toast.connections, button.Activated:Connect(function()
			onAction()
			release(toast)
		end))
	end

	local function build(request: Request): Toast
		local card = Instance.new("CanvasGroup")
		card.Name = "Toast"
		card.AnchorPoint = layout.anchor
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Size = UDim2.fromScale(1, 0)
		card.BackgroundColor3 = THEME.surface
		card.GroupTransparency = 1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = card

		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = THEME.edge
		edge.Parent = card

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.AutomaticSize = Enum.AutomaticSize.Y
		content.Size = UDim2.fromScale(1, 0)
		content.BackgroundTransparency = 1
		content.Parent = card

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 12)
		padding.PaddingBottom = UDim.new(0, 12)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = content

		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.SortOrder = Enum.SortOrder.LayoutOrder
		row.Padding = UDim.new(0, 12)
		row.Parent = content

		local progress = request.kind == "progress"
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.LayoutOrder = 1
		icon.Size = UDim2.fromOffset(20, 20)
		icon.BackgroundTransparency = 1
		icon.Image = if progress then ICON.loading else ICON[request.severity]
		icon.Rotation = 0
		icon.ImageColor3 = THEME[request.severity]
		icon.Parent = content

		local label = Instance.new("TextLabel")
		label.Name = "Message"
		label.LayoutOrder = 2
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.fromScale(0, 0)
		label.BackgroundTransparency = 1
		label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		label.TextSize = 14
		label.TextColor3 = THEME.text
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = request.message
		label.Parent = content

		local fill = Instance.new("UIFlexItem")
		fill.FlexMode = Enum.UIFlexMode.Fill
		fill.Parent = label

		local lifetime = readingTime(request.message)
		if request.kind == "action" then
			lifetime = math.max(lifetime, ACTION_HOLD)
		end

		local toast: Toast = {
			request = request,
			count = 1,
			card = card,
			content = content,
			icon = icon,
			label = label,
			timerBar = nil,
			dismiss = nil,
			offset = Vector2.zero,
			velocity = Vector2.zero,
			goal = Vector2.zero,
			height = 48,
			lifetime = lifetime,
			remaining = lifetime,
			held = false,
			connections = {},
		}
		request.toast = toast

		local actionLabel, onAction = request.actionLabel, request.onAction
		if actionLabel and onAction then
			addAction(toast, actionLabel, onAction)
		end
		if request.severity == "error" then
			addDismiss(toast)
		elseif layout.timed and not progress then
			addTimer(toast)
		end

		table.insert(toast.connections, card.MouseEnter:Connect(function()
			toast.held = true
		end))
		table.insert(toast.connections, card.MouseLeave:Connect(function()
			toast.held = false
		end))
		local resized = card:GetPropertyChangedSignal("AbsoluteSize")
		table.insert(toast.connections, resized:Connect(function()
			toast.height = card.AbsoluteSize.Y
			restack()
		end))
		return toast
	end

	function present(request: Request)
		local toast = build(request)
		table.insert(shown, toast)
		if request.key then
			byKey[request.key] = toast
		end
		restack()
		toast.offset = toast.goal + layout.arrive
		place(toast)
		toast.card.Parent = stack
		TweenService:Create(toast.card, FADE_IN, { GroupTransparency = 0 }):Play()
		if not loop then
			loop = RunService.PreRender:Connect(step)
		end
	end

	local function enqueue(request: Request)
		if #shown < MAX_VISIBLE then
			present(request)
			return
		end
		if #waiting >= MAX_QUEUED then
			table.remove(waiting, 1)
		end
		table.insert(waiting, request)
	end

	local function push(message: string, severity: Severity?, key: string?)
		local repeated = if key then byKey[key] else nil
		if repeated then
			repeated.count += 1
			repeated.label.Text = `{repeated.request.message} ×{repeated.count}`
			repeated.remaining = repeated.lifetime
			return
		end
		enqueue({ message = message, severity = severity or "info", key = key, kind = "plain" })
	end

	-- A progress toast spins until `done`; a request still in the queue simply
	-- arrives already finished.
	local function progress(message: string): ProgressHandle
		local request: Request = { message = message, severity = "info", kind = "progress" }
		enqueue(request)
		return {
			done = function(result: string, severity: Severity?)
				request.kind = "plain"
				request.message = result
				request.severity = severity or "success"
				local toast = request.toast
				if not toast then
					return
				end
				toast.icon.Rotation = 0
				toast.icon.Image = ICON[request.severity]
				toast.icon.ImageColor3 = THEME[request.severity]
				toast.label.Text = result
				toast.lifetime = readingTime(result)
				toast.remaining = toast.lifetime
				if request.severity == "error" then
					addDismiss(toast)
				elseif layout.timed then
					addTimer(toast)
				end
			end,
		}
	end

	local function action(message: string, actionLabel: string, onAction: () -> ())
		enqueue({
			message = message,
			severity = "info",
			kind = "action",
			actionLabel = actionLabel,
			onAction = onAction,
		})
	end

	return {
		push = push,
		progress = progress,
		action = action,
		destroy = function()
			if loop then
				loop:Disconnect()
				loop = nil
			end
			for _, toast in shown do
				for _, connection in toast.connections do
					connection:Disconnect()
				end
			end
			table.clear(shown)
			table.clear(waiting)
			table.clear(byKey)
			stack:Destroy()
		end,
	}
end

return createNotifier
