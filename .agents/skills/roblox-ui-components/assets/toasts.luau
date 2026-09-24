--!strict
-- lint: complete
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Placement = "N1" | "N2" | "N4" | "N7" | "N11" | "N12" | "N13" | "N14" | "N19"
export type Severity = "info" | "success" | "warning" | "error"

export type ProgressHandle = {
	done: (message: string, severity: Severity?) -> (),
}

-- `title` is shown by N13 and ignored elsewhere. N17 is `countdown` on any
-- placement: the seconds left are written after the message.
export type Notifier = {
	push: (message: string, severity: Severity?, key: string?, title: string?) -> (),
	progress: (message: string) -> ProgressHandle,
	action: (message: string, actionLabel: string, onAction: () -> ()) -> (),
	countdown: (message: string, seconds: number, onZero: (() -> ())?) -> (),
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

type Look = "plain" | "pill" | "titled" | "edge" | "deck"

type Layout = {
	anchor: Vector2,
	direction: number,
	arrive: Vector2,
	timed: boolean,
	look: Look,
}

-- direction is which way the stack grows from its anchor; arrive is where a new
-- toast starts before it settles into its slot; timed stacks show a time-left bar.
local function stackAt(
	anchor: Vector2,
	direction: number,
	arrive: Vector2,
	timed: boolean,
	look: Look
): Layout
	return { anchor = anchor, direction = direction, arrive = arrive, timed = timed, look = look }
end

local BOTTOM_RIGHT = Vector2.new(1, 1)
local FROM_RIGHT = Vector2.new(24, 0)

local PLACEMENT: { [Placement]: Layout } = {
	N1 = stackAt(Vector2.new(0.5, 1), -1, Vector2.new(0, 12), false, "plain"),
	N2 = stackAt(Vector2.new(0.5, 0), 1, Vector2.new(0, -8), false, "plain"),
	N4 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "plain"),
	N7 = stackAt(Vector2.new(1, 0), 1, FROM_RIGHT, true, "plain"),
	N11 = stackAt(Vector2.new(0, 1), -1, Vector2.new(-24, 0), true, "plain"),
	N12 = stackAt(Vector2.new(0.5, 1), -1, Vector2.new(0, 12), false, "pill"),
	N13 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "titled"),
	N14 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "edge"),
	N19 = stackAt(BOTTOM_RIGHT, -1, FROM_RIGHT, true, "deck"),
}

local MAX_VISIBLE = 3
local MAX_QUEUED = 10
local GAP = 8
local EDGE_INSET = 16
local MIN_HOLD = 1.5
local ACTION_HOLD = 6
local SETTLE_TIME = 0.12
local SPIN_DEGREES_PER_SECOND = 360
-- N19: how far each older card peeks out, and how much smaller it is per step.
local DECK_PEEK = 8
local DECK_SHRINK = 0.05
local FADE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)

type Request = {
	message: string,
	severity: Severity,
	key: string?,
	title: string?,
	kind: "plain" | "progress" | "action" | "countdown",
	actionLabel: string?,
	onAction: (() -> ())?,
	seconds: number?,
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
	depth: UIScale?,
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
	local spread = false

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
	-- one that leaves early moves up while it may still be arriving. A closed
	-- deck (N19) piles older cards behind the newest instead.
	local function restack()
		local travelled = 0
		for index, toast in shown do
			local behind = #shown - index
			local depth = toast.depth
			if depth and not spread then
				toast.goal = Vector2.new(0, behind * DECK_PEEK * layout.direction)
				depth.Scale = 1 - behind * DECK_SHRINK
				toast.card.ZIndex = MAX_VISIBLE - behind + 1
				continue
			end
			if depth then
				depth.Scale = 1
			end
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
			-- A countdown tracks real time, so hovering never pauses it.
			local counting = request.kind == "countdown"
			if (toast.held and not counting) or request.severity == "error" then
				continue
			end
			toast.remaining -= dt
			local timerBar = toast.timerBar
			if timerBar then
				timerBar.Size = UDim2.new(math.max(toast.remaining / toast.lifetime, 0), 0, 0, 2)
			end
			if counting then
				toast.label.Text = `{request.message} {math.max(math.ceil(toast.remaining), 0)}s`
			end
			if toast.remaining <= 0 then
				release(toast)
				local onZero = request.onAction
				if counting and onZero then
					onZero()
				end
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

	-- N13: a bold title over the message, both left-aligned beside the icon.
	local function addTitle(content: Frame, label: TextLabel, title: string)
		local words = Instance.new("Frame")
		words.Name = "Words"
		words.LayoutOrder = 2
		words.AutomaticSize = Enum.AutomaticSize.Y
		words.Size = UDim2.fromScale(0, 0)
		words.BackgroundTransparency = 1
		words.Parent = content

		local grow = Instance.new("UIFlexItem")
		grow.FlexMode = Enum.UIFlexMode.Fill
		grow.Parent = words

		local column = Instance.new("UIListLayout")
		column.SortOrder = Enum.SortOrder.LayoutOrder
		column.Padding = UDim.new(0, 4)
		column.Parent = words

		local heading = Instance.new("TextLabel")
		heading.Name = "Title"
		heading.LayoutOrder = 1
		heading.AutomaticSize = Enum.AutomaticSize.Y
		heading.Size = UDim2.fromScale(1, 0)
		heading.BackgroundTransparency = 1
		heading.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		heading.TextSize = 14
		heading.TextColor3 = THEME.text
		heading.TextWrapped = true
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.Text = title
		heading.Parent = words

		label.LayoutOrder = 2
		label.Size = UDim2.fromScale(1, 0)
		label.TextColor3 = THEME.textMuted
		label.Parent = words
	end

	local function build(request: Request): Toast
		local look = layout.look
		local pill = look == "pill"
		local card = Instance.new("CanvasGroup")
		card.Name = "Toast"
		card.AnchorPoint = layout.anchor
		card.AutomaticSize = if pill then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
		card.Size = if pill then UDim2.fromScale(0, 0) else UDim2.fromScale(1, 0)
		card.BackgroundColor3 = THEME.surface
		card.GroupTransparency = 1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = if pill then UDim.new(0.5, 0) else UDim.new(0, 10)
		corner.Parent = card

		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = THEME.edge
		edge.Parent = card

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.AutomaticSize = if pill then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
		content.Size = if pill then UDim2.fromScale(0, 0) else UDim2.fromScale(1, 0)
		content.BackgroundTransparency = 1
		content.Parent = card

		-- A pill is short and wide; the coloured edge (N14) needs room beside it.
		local vertical = if pill then 8 else 12
		local horizontal = if pill then 16 else 12
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, vertical)
		padding.PaddingBottom = UDim.new(0, vertical)
		padding.PaddingLeft = UDim.new(0, if look == "edge" then 16 else horizontal)
		padding.PaddingRight = UDim.new(0, horizontal)
		padding.Parent = content

		if look == "edge" then
			local strip = Instance.new("Frame")
			strip.Name = "Edge"
			strip.Size = UDim2.new(0, 4, 1, 0)
			strip.BackgroundColor3 = THEME[request.severity]
			strip.BorderSizePixel = 0
			strip.Parent = card
		end

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
		label.AutomaticSize = if pill then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
		label.Size = UDim2.fromScale(0, 0)
		label.BackgroundTransparency = 1
		label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		label.TextSize = 14
		label.TextColor3 = THEME.text
		label.TextWrapped = not pill
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = if request.kind == "countdown"
			then `{request.message} {math.ceil(request.seconds or 0)}s`
			else request.message

		local title = request.title
		if look == "titled" and title then
			addTitle(content, label, title)
		else
			label.Parent = content
			if not pill then
				local fill = Instance.new("UIFlexItem")
				fill.FlexMode = Enum.UIFlexMode.Fill
				fill.Parent = label
			end
		end

		local lifetime = readingTime(request.message)
		if request.kind == "action" then
			lifetime = math.max(lifetime, ACTION_HOLD)
		elseif request.kind == "countdown" then
			lifetime = request.seconds or lifetime
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
			depth = nil,
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
		if look == "deck" then
			local depth = Instance.new("UIScale")
			depth.Name = "Depth"
			depth.Parent = card
			toast.depth = depth
		end

		local actionLabel, onAction = request.actionLabel, request.onAction
		if actionLabel and onAction then
			addAction(toast, actionLabel, onAction)
		end
		if request.severity == "error" then
			addDismiss(toast)
		elseif (layout.timed or request.kind == "countdown") and not progress then
			addTimer(toast)
		end

		table.insert(toast.connections, card.MouseEnter:Connect(function()
			toast.held = true
			if look == "deck" then
				spread = true
				restack()
			end
		end))
		table.insert(toast.connections, card.MouseLeave:Connect(function()
			toast.held = false
			if look == "deck" then
				spread = false
				restack()
			end
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

	local function push(message: string, severity: Severity?, key: string?, title: string?)
		local repeated = if key then byKey[key] else nil
		if repeated then
			repeated.count += 1
			repeated.label.Text = `{repeated.request.message} ×{repeated.count}`
			repeated.remaining = repeated.lifetime
			return
		end
		enqueue({
			message = message,
			severity = severity or "info",
			key = key,
			title = title,
			kind = "plain",
		})
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

	-- N17: the seconds left follow the message and the bar drains in real time;
	-- `onZero` runs once when it reaches zero, never if the notifier is destroyed.
	local function countdown(message: string, seconds: number, onZero: (() -> ())?)
		enqueue({
			message = message,
			severity = "warning",
			kind = "countdown",
			seconds = seconds,
			onAction = onZero,
		})
	end

	return {
		push = push,
		progress = progress,
		action = action,
		countdown = countdown,
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
