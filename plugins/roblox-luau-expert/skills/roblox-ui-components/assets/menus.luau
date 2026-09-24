--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

type FirstStyles = "M0" | "M1" | "M2" | "M3" | "M4" | "M5" | "M6"
type SecondStyles = "M7" | "M8" | "M9" | "M10" | "M11" | "M12"
type LaterStyles = "M13" | "M14" | "M15" | "M16" | "M17" | "M18"
type LastStyles = "M19" | "M20" | "M21" | "M22" | "M23" | "M24"
export type MenuStyle = FirstStyles | SecondStyles | LaterStyles | LastStyles

-- `scrim` is the full-screen frame M19 dims behind the panel.
export type PresenterOptions = {
	closeStyle: MenuStyle?,
	rows: { CanvasGroup }?,
	scrim: GuiObject?,
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
	unfold = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	fold = TweenInfo.new(0.18, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	bounce = TweenInfo.new(0.45, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	jelly = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
	snapIn = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	snapOut = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	slowIn = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	slowOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
}

-- How dark M19's scrim gets: half the game still shows through.
local SCRIM_TRANSPARENCY = 0.5

-- The sizes a panel pops from and shrinks to, shared by the styles built on
-- the gentle pop (M3) and the grow from a button (M5).
local POP_IN, POP_OUT = 0.96, 0.98
local GROW_IN, GROW_OUT = 0.9, 0.95

type Pose = {
	enter: (size: Vector2) -> Vector2,
	exit: (size: Vector2) -> Vector2,
	enterScale: number,
	exitScale: number,
	enterRotation: number,
	exitRotation: number,
	fades: boolean,
	enterTiming: TweenInfo,
	exitTiming: TweenInfo,
	fadeTiming: TweenInfo,
	scaleTiming: TweenInfo?,
	settlePosition: boolean,
	settleScale: boolean,
	unfold: "X" | "Y" | "none",
	dims: boolean,
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
		enterRotation = 0,
		exitRotation = 0,
		fades = true,
		enterTiming = MOTION.enter,
		exitTiming = MOTION.exit,
		fadeTiming = MOTION.enter,
		settlePosition = false,
		settleScale = false,
		unfold = "none",
		dims = false,
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
	M3 = pose({ enterScale = POP_IN, exitScale = POP_OUT }),
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
	M5 = pose({ enterScale = GROW_IN, exitScale = GROW_OUT }),
	M6 = pose({ enterScale = 0.94, exitScale = POP_OUT, settleScale = true }),
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
	M13 = pose({
		enter = function()
			return Vector2.new(-24, 0)
		end,
		exit = function()
			return Vector2.new(-12, 0)
		end,
	}),
	M14 = pose({
		enter = function()
			return Vector2.new(24, 0)
		end,
		exit = function()
			return Vector2.new(12, 0)
		end,
	}),
	M15 = pose({
		enter = function()
			return Vector2.new(0, -12)
		end,
		exit = function()
			return Vector2.new(0, -8)
		end,
	}),
	M16 = pose({
		enterRotation = -4,
		exitRotation = 2,
		enterScale = POP_IN,
		exitScale = POP_OUT,
		settleScale = true,
	}),
	M17 = pose({
		unfold = "Y",
		fades = false,
		enterTiming = MOTION.unfold,
		exitTiming = MOTION.fold,
	}),
	M18 = pose({
		unfold = "X",
		fades = false,
		enterTiming = MOTION.unfold,
		exitTiming = MOTION.fold,
	}),
	M19 = pose({ enterScale = POP_IN, exitScale = POP_OUT, dims = true }),
	M20 = pose({
		enter = function()
			return Vector2.new(0, 24)
		end,
		exit = function()
			return Vector2.new(0, 12)
		end,
		enterScale = GROW_IN,
		exitScale = GROW_OUT,
		enterTiming = MOTION.drawerIn,
	}),
	M21 = pose({
		enter = function()
			return Vector2.new(0, -40)
		end,
		exit = function()
			return Vector2.new(0, -12)
		end,
		enterTiming = MOTION.bounce,
	}),
	M22 = pose({ enterScale = 0.8, exitScale = GROW_OUT, scaleTiming = MOTION.jelly }),
	M23 = pose({
		enterScale = POP_OUT,
		exitScale = POP_OUT,
		enterTiming = MOTION.snapIn,
		exitTiming = MOTION.snapOut,
		fadeTiming = MOTION.snapIn,
	}),
	M24 = pose({
		enterTiming = MOTION.slowIn,
		exitTiming = MOTION.slowOut,
		fadeTiming = MOTION.slowIn,
	}),
}

local ROW_STEP = 0.03
local ROW_BUDGET = 0.25

-- `panel` is the window's outermost CanvasGroup, placed by Position rather than
-- by a parent layout. For M5, set its AnchorPoint on the side facing the button
-- that opens it: UIScale grows the panel out of its anchor. A UIScale used for
-- screen-size scaling belongs on a parent frame, not on the panel. M12 needs
-- the rows it reveals, each a CanvasGroup. M17 and M18 resize the panel, so
-- its contents must be sized in offset or they squash instead of being revealed.
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
	local scrim: GuiObject? = if options then options.scrim else nil
	if style == "M19" or closeStyle == "M19" then
		assert(scrim, "M19 needs options.scrim")
		scrim.BackgroundTransparency = 1
		scrim.Visible = false
	end

	local scale = Instance.new("UIScale")
	scale.Name = "OpenScale"
	scale.Parent = panel

	local home = panel.Position
	local fullSize = panel.Size
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

	-- A folded size on one axis, and the position that keeps the right edge
	-- still: the top for a roll (Y), the centre for a stretch (X).
	local function folded(axis: "X" | "Y"): (UDim2, UDim2)
		local anchor, pixels = panel.AnchorPoint, panel.AbsoluteSize
		if axis == "Y" then
			local size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 0)
			return size, shifted(Vector2.new(0, -anchor.Y * pixels.Y))
		end
		local size = UDim2.new(0, 0, fullSize.Y.Scale, fullSize.Y.Offset)
		return size, shifted(Vector2.new((0.5 - anchor.X) * pixels.X, 0))
	end

	local function dim(show: boolean, timing: TweenInfo)
		if not scrim then
			return
		end
		scrim.Visible = true
		play(scrim, timing, { BackgroundTransparency = if show then SCRIM_TRANSPARENCY else 1 })
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
			panel.Position, panel.Size, scale.Scale, panel.Rotation = home, fullSize, 1, 0
			dim(true, MOTION.reduced)
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 0 }), function()
				phase = "open"
			end)
			return
		end

		local chosen = POSE[style]
		if fromClosed then
			panel.Position = shifted(chosen.enter(panel.AbsoluteSize))
			scale.Scale = chosen.enterScale
			panel.Rotation = chosen.enterRotation
			panel.GroupTransparency = if chosen.fades then 1 else 0
			if chosen.unfold ~= "none" then
				panel.Size, panel.Position = folded(chosen.unfold)
			end
		end
		local moveTiming = if chosen.settlePosition then MOTION.settle else chosen.enterTiming
		local growTiming = if chosen.settleScale
			then MOTION.settle
			else chosen.scaleTiming or chosen.enterTiming
		local move = play(panel, moveTiming, { Position = home, Size = fullSize })
		play(panel, chosen.fadeTiming, { GroupTransparency = 0 })
		play(scale, growTiming, { Scale = 1 })
		play(panel, growTiming, { Rotation = 0 })
		if chosen.dims then
			dim(true, MOTION.enter)
		end
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
			home, fullSize = panel.Position, panel.Size
		end
		ticket += 1
		stop()
		phase = "closing"

		local function hide()
			panel.Visible = false
			panel.Position, panel.Size, scale.Scale, panel.GroupTransparency = home, fullSize, 1, 1
			panel.Rotation = 0
			if scrim then
				scrim.Visible = false
			end
			phase = "closed"
		end

		if closeStyle == "M0" then
			hide()
			return
		end
		if GuiService.ReducedMotionEnabled then
			dim(false, MOTION.reduced)
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 1 }), hide)
			return
		end

		local chosen = POSE[closeStyle]
		play(scale, chosen.exitTiming, { Scale = chosen.exitScale })
		play(panel, chosen.exitTiming, { Rotation = chosen.exitRotation })
		if chosen.fades then
			play(panel, chosen.exitTiming, { GroupTransparency = 1 })
		end
		dim(false, chosen.exitTiming)
		if chosen.unfold ~= "none" then
			local size, position = folded(chosen.unfold)
			settleWhen(play(panel, chosen.exitTiming, { Size = size, Position = position }), hide)
			return
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
