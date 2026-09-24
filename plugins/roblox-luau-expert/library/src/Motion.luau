--!strict
--[[
	Motion — tweens by intent, springs by SmoothDamp, one reduced-motion switch.

	Explained in: roblox-ui-motion/SKILL.md
	  easing choices      -> references/easing-and-timing.md
	  spring behaviour    -> references/springs-and-smoothdamp.md
	  stagger, enter/exit -> references/choreography.md

	Two things this exists to prevent:
	  1. One TweenInfo used for everything (catalog tell R12).
	  2. Tweens used where the target changes mid-flight, which snaps because a
	     restarted tween discards velocity. Motion.spring carries it.
--]]

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Motion = {}

-- // INTENT -> TWEENINFO // --
-- Named by what the motion means, never by its shape. Retuning the whole
-- interface is an edit here.

local PRESETS = table.freeze({
	-- State feedback on something already on screen. Above ~0.1s feels laggy.
	instant = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Arriving: Out, so it is mostly there within the first third.
	enter = TweenInfo.new(0.20, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	-- Leaving: In, and shorter than the entry — already understood.
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	-- Between two states with no clear start or end.
	move = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	-- Large surfaces changing.
	panel = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
})

export type Intent = "instant" | "enter" | "exit" | "move" | "panel"

-- // REDUCED MOTION // --
-- GuiService.ReducedMotionEnabled is [Hidden] [ReadOnly] but readable from a
-- normal LocalScript. There is NO ReducedMotionChanged event — property signal.
-- UserGameSettings.ReducedMotion is {RobloxScript}-gated and unreachable.

local reduced = false

do
	local ok, value = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	reduced = ok and value == true

	if ok then
		GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
			local readOk, current = pcall(function()
				return GuiService.ReducedMotionEnabled
			end)
			if readOk then
				reduced = current == true
			end
		end)
	end
end

function Motion.isReducedMotion(): boolean
	return reduced
end

--[[ Override the player setting, for a game-level accessibility option. ]]
function Motion.setReducedMotion(value: boolean)
	reduced = value
end

-- Reduced motion collapses duration; it never removes the state change. The
-- element still arrives, it just does not travel.
local INSTANT = TweenInfo.new(0.01, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local function infoFor(intent: Intent): TweenInfo
	if reduced then
		return INSTANT
	end
	local preset = PRESETS[intent]
	if not preset then
		error(`Motion: unknown intent "{intent}"`, 3)
	end
	return preset
end

--[[
	Tween by intent.

	    Motion.tween(frame, "enter", { GroupTransparency = 0 }):Play()
--]]
function Motion.tween(instance: Instance, intent: Intent, goals: { [string]: any }): Tween
	return TweenService:Create(instance, infoFor(intent), goals)
end

--[[
	Play and resolve only on genuine completion.

	Tween.Completed fires with Cancelled too; chaining without checking runs the
	next step on a cancelled tween.
--]]
function Motion.play(
	instance: Instance,
	intent: Intent,
	goals: { [string]: any },
	onComplete: (() -> ())?
): Tween
	local tween = Motion.tween(instance, intent, goals)

	if onComplete then
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				onComplete()
			end
		end)
	end

	tween:Play()
	return tween
end

-- // SPRINGS // --
-- TweenService:SmoothDamp is a first-party critically damped spring. Verified
-- ungated and {Safe} in parallel contexts. Use it whenever the target can
-- change while the motion is running.

export type Spring = {
	setTarget: (self: Spring, target: any) -> (),
	getValue: (self: Spring) -> any,
	snap: (self: Spring, value: any) -> (),
	destroy: (self: Spring) -> (),
}

local EPSILON = 0.001

-- SmoothDamp's documented type support is number, Vector2, Vector3 and CFrame.
-- UDim2 is NOT among them, so springing Position directly is not safe. Spring a
-- plain number with Motion.springValue and compose the UDim2 yourself — see
-- Toast.luau, which springs a Y offset rather than a Position.
local function magnitude(value: any): number
	local kind = typeof(value)
	if kind == "number" then
		return math.abs(value)
	elseif kind == "Vector2" or kind == "Vector3" then
		return value.Magnitude
	elseif kind == "CFrame" then
		return value.Position.Magnitude
	end
	return math.huge -- unknown type: never auto-settle
end

local function difference(a: any, b: any): number
	if typeof(a) == "number" then
		return math.abs(a - b)
	end
	local ok, result = pcall(function()
		return magnitude(a - b)
	end)
	return ok and result or math.huge
end

local function zeroOf(value: any): any
	local kind = typeof(value)
	if kind == "number" then
		return 0
	elseif kind == "Vector2" then
		return Vector2.zero
	elseif kind == "Vector3" then
		return Vector3.zero
	elseif kind == "CFrame" then
		return CFrame.identity
	end
	error(
		`Motion.spring: "{kind}" is not a SmoothDamp-supported type. `
			.. `Use number, Vector2, Vector3 or CFrame — for UDim2, spring a number `
			.. `with Motion.springValue and build the UDim2 from it.`,
		3
	)
end

--[[
	A spring that writes `property` on `instance` every frame while moving, and
	disconnects itself once settled. Idle springs cost nothing.

	    local follow = Motion.spring(frame, "Position", 0.12)
	    follow:setTarget(UDim2.fromScale(0.5, 0.5))   -- may change any time

	smoothTime is roughly seconds-to-target. 0.04-0.08 immediate, 0.10-0.15
	snappy, 0.18-0.25 weighty.
--]]
function Motion.spring(
	instance: Instance,
	property: string,
	smoothTime: number,
	maxSpeed: number?
): Spring
	local current: any = (instance :: any)[property]
	local target: any = current
	local velocity: any = zeroOf(current)
	local connection: RBXScriptConnection? = nil

	local self = {}

	local function stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function stepOnce(dt: number)
		-- Under reduced motion, skip the travel entirely.
		if reduced then
			current = target
			velocity = zeroOf(current)
			;(instance :: any)[property] = current
			stop()
			return
		end

		current, velocity =
			TweenService:SmoothDamp(current, target, velocity, smoothTime, maxSpeed, dt)
		;(instance :: any)[property] = current

		if difference(current, target) < EPSILON and magnitude(velocity) < EPSILON then
			current = target
			;(instance :: any)[property] = current
			stop()
		end
	end

	local function start()
		if connection or not instance.Parent then
			return
		end
		connection = RunService.PreRender:Connect(stepOnce)
	end

	function self:setTarget(newTarget: any)
		if difference(newTarget, target) < EPSILON then
			return
		end
		target = newTarget
		start()
	end

	function self:getValue(): any
		return current
	end

	function self:snap(value: any)
		stop()
		current, target = value, value
		velocity = zeroOf(value)
		;(instance :: any)[property] = value
	end

	function self:destroy()
		stop()
	end

	return (self :: any) :: Spring
end

-- // STAGGER // --

--[[
	Reveal items in reading order, with the total capped so a long list does not
	become a wait. Guards each delayed callback — the list may have closed.
--]]
function Motion.stagger(
	items: { GuiObject },
	intent: Intent,
	goals: { [string]: any },
	totalBudget: number?
)
	local count = #items
	if count == 0 then
		return
	end

	if reduced then
		for _, item in items do
			for property, value in goals do
				(item :: any)[property] = value
			end
		end
		return
	end

	local budget = totalBudget or 0.25
	local step = math.min(0.03, budget / count)

	for index, item in items do
		task.delay(step * (index - 1), function()
			if not item.Parent then
				return -- destroyed while waiting
			end
			Motion.tween(item, intent, goals):Play()
		end)
	end
end

--[[
	A spring over a bare number, not bound to a property.

	Use this when the value you want to spring is not a SmoothDamp-supported
	type — the common case being UDim2 Position. Spring the offset, compose the
	UDim2 in the callback.

	    local y = Motion.springValue(0, 0.14, function(value)
	        frame.Position = UDim2.new(1, 0, 0, value)
	    end)
	    y:setTarget(120)
--]]
function Motion.springValue(
	initial: number,
	smoothTime: number,
	onUpdate: (value: number) -> ()
): Spring
	local current = initial
	local target = initial
	local velocity = 0
	local connection: RBXScriptConnection? = nil

	local self = {}

	local function stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function stepOnce(dt: number)
		if reduced then
			current, velocity = target, 0
			onUpdate(current)
			stop()
			return
		end

		current, velocity = TweenService:SmoothDamp(current, target, velocity, smoothTime, nil, dt)
		onUpdate(current)

		if math.abs(current - target) < EPSILON and math.abs(velocity) < EPSILON then
			current = target
			onUpdate(current)
			stop()
		end
	end

	function self:setTarget(newTarget: any)
		local value = newTarget :: number
		if math.abs(value - target) < EPSILON then
			return
		end
		target = value
		if not connection then
			connection = RunService.PreRender:Connect(stepOnce)
		end
	end

	function self:getValue(): any
		return current
	end

	function self:snap(value: any)
		stop()
		current, target, velocity = value :: number, value :: number, 0
		onUpdate(current)
	end

	function self:destroy()
		stop()
	end

	return (self :: any) :: Spring
end

Motion.presets = PRESETS

return Motion
