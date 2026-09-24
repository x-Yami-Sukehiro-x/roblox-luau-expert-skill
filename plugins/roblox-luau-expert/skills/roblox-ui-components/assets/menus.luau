--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

type FirstStyles = "M0" | "M1" | "M2" | "M3" | "M4" | "M5" | "M6"
export type MenuStyle = FirstStyles | "M7" | "M8" | "M9" | "M10" | "M11" | "M12"

export type PresenterOptions = {
	closeStyle: MenuStyle?,
	rows: { CanvasGroup }?,
}

export type Presenter = {
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	destroy: () -> (),
}

local MOTION = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	drawerIn = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	drawerOut = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	settle = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	reduced = TweenInfo.new(0.08, Enum.EasingStyle.Linear),
}

type Pose = {
	enter: (size: Vector2) -> Vector2,
	exit: (size: Vector2) -> Vector2,
	enterScale: number,
	exitScale: number,
	fades: boolean,
	enterTiming: TweenInfo,
	exitTiming: TweenInfo,
	settlePosition: boolean,
	settleScale: boolean,
}

local function still(): Vector2
	return Vector2.zero
end

local function pose(overrides: { [string]: any }): Pose
	local base = {
		enter = still,
		exit = still,
		enterScale = 1,
		exitScale = 1,
		fades = true,
		enterTiming = MOTION.enter,
		exitTiming = MOTION.exit,
		settlePosition = false,
		settleScale = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return (base :: any) :: Pose
end

-- Where each style starts when opening and where it goes when closing, as an
-- offset from the resting position. Exits travel less than entrances; the
-- drawers and sheets leave the way they came and stay opaque while moving.
local POSE: { [string]: Pose } = {
	M1 = pose({}),
	M2 = pose({
		enter = function()
			return Vector2.new(0, 12)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
	M3 = pose({ enterScale = 0.96, exitScale = 0.98 }),
	M4 = pose({
		enter = function(size: Vector2)
			return Vector2.new(-(size.X + 24), 0)
		end,
		exit = function(size: Vector2)
			return Vector2.new(-(size.X + 24), 0)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M5 = pose({ enterScale = 0.9, exitScale = 0.95 }),
	M6 = pose({ enterScale = 0.94, exitScale = 0.98, settleScale = true }),
	M7 = pose({
		enter = function(size: Vector2)
			return Vector2.new(size.X + 24, 0)
		end,
		exit = function(size: Vector2)
			return Vector2.new(size.X + 24, 0)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M8 = pose({
		enter = function(size: Vector2)
			return Vector2.new(0, size.Y + 24)
		end,
		exit = function(size: Vector2)
			return Vector2.new(0, size.Y + 24)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M9 = pose({
		enter = function(size: Vector2)
			return Vector2.new(0, -(size.Y + 24))
		end,
		exit = function(size: Vector2)
			return Vector2.new(0, -(size.Y + 24))
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M10 = pose({ enterScale = 1.06, exitScale = 1.03 }),
	M11 = pose({
		enter = function()
			return Vector2.new(0, 24)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
		settlePosition = true,
	}),
	M12 = pose({
		enter = function()
			return Vector2.new(0, 8)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
}

local ROW_STEP = 0.03
local ROW_BUDGET = 0.25

-- `panel` is the window's outermost CanvasGroup, placed by Position rather than
-- by a parent layout. For M5, set its AnchorPoint on the side facing the button
-- that opens it: UIScale grows the panel out of its anchor. A UIScale used for
-- screen-size scaling belongs on a parent frame, not on the panel. M12 needs
-- the rows it reveals, each a CanvasGroup.
local function createPresenter(
	panel: CanvasGroup,
	style: MenuStyle,
	options: PresenterOptions?
): Presenter
	local closeStyle: MenuStyle = style
	if options and options.closeStyle then
		closeStyle = options.closeStyle
	end
	local rows: { CanvasGroup } = if options and options.rows then options.rows else {}

	local scale = Instance.new("UIScale")
	scale.Name = "OpenScale"
	scale.Parent = panel

	local home = panel.Position
	local phase: "closed" | "opening" | "open" | "closing" = "closed"
	local ticket = 0
	local running: { Tween } = {}

	panel.Visible = false
	panel.GroupTransparency = 1
	scale.Scale = 1

	local function stop()
		for _, tween in running do
			tween:Cancel()
		end
		table.clear(running)
	end

	local function play(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
		local tween = TweenService:Create(target, timing, goals)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function shifted(offset: Vector2): UDim2
		return home + UDim2.fromOffset(offset.X, offset.Y)
	end

	-- Every tween checks the ticket it was started with, so a close that is
	-- interrupted by a reopen can never hide the panel it no longer owns.
	local function settleWhen(tween: Tween, onSettled: () -> ())
		local mine = ticket
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				onSettled()
			end
		end)
	end

	local function revealRows()
		local step = math.min(ROW_STEP, ROW_BUDGET / math.max(#rows, 1))
		local mine = ticket
		for index, row in rows do
			row.GroupTransparency = 1
			task.delay(step * (index - 1), function()
				if mine ~= ticket or not row.Parent then
					return
				end
				play(row, MOTION.enter, { GroupTransparency = 0 })
			end)
		end
	end

	local function open()
		if phase == "open" or phase == "opening" then
			return
		end
		ticket += 1
		stop()
		local fromClosed = phase == "closed"
		phase = "opening"
		panel.Visible = true

		if style == "M0" then
			panel.Position, scale.Scale, panel.GroupTransparency = home, 1, 0
			phase = "open"
			return
		end
		if GuiService.ReducedMotionEnabled then
			panel.Position, scale.Scale = home, 1
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 0 }), function()
				phase = "open"
			end)
			return
		end

		local chosen = POSE[style]
		if fromClosed then
			panel.Position = shifted(chosen.enter(panel.AbsoluteSize))
			scale.Scale = chosen.enterScale
			panel.GroupTransparency = if chosen.fades then 1 else 0
		end
		local moveTiming = if chosen.settlePosition then MOTION.settle else chosen.enterTiming
		local growTiming = if chosen.settleScale then MOTION.settle else chosen.enterTiming
		local move = play(panel, moveTiming, { Position = home })
		play(panel, MOTION.enter, { GroupTransparency = 0 })
		play(scale, growTiming, { Scale = 1 })
		if style == "M12" then
			revealRows()
		end
		settleWhen(move, function()
			phase = "open"
		end)
	end

	local function close()
		if phase == "closed" or phase == "closing" then
			return
		end
		if phase == "open" then
			home = panel.Position
		end
		ticket += 1
		stop()
		phase = "closing"

		local function hide()
			panel.Visible = false
			panel.Position, scale.Scale, panel.GroupTransparency = home, 1, 1
			phase = "closed"
		end

		if closeStyle == "M0" then
			hide()
			return
		end
		if GuiService.ReducedMotionEnabled then
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 1 }), hide)
			return
		end

		local chosen = POSE[closeStyle]
		play(scale, chosen.exitTiming, { Scale = chosen.exitScale })
		if chosen.fades then
			play(panel, chosen.exitTiming, { GroupTransparency = 1 })
		end
		local target = shifted(chosen.exit(panel.AbsoluteSize))
		settleWhen(play(panel, chosen.exitTiming, { Position = target }), hide)
	end

	return {
		open = open,
		close = close,
		isOpen = function()
			return phase == "open" or phase == "opening"
		end,
		destroy = function()
			ticket += 1
			stop()
			scale:Destroy()
		end,
	}
end

return createPresenter
