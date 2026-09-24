--!strict
--[[
	Toast — a notification system that handles the parts naive versions miss.

	Explained in: roblox-ui-components/references/toasts.md

	The five hard parts, all handled here:
	  1. Reflow when a MIDDLE toast expires — position is derived from index and
	     driven by a spring, because the target moves while it is moving.
	  2. Duplicates collapse on a key with a count, rather than stacking.
	  3. The timer pauses on hover, storing REMAINING time (not a deadline).
	  4. Visible set is capped; overflow queues; the queue is capped too, and a
	     high-severity toast preempts.
	  5. Every toast tears down fully, including on early removal.

	Usage:
	    local Toast = require(path.to.Toast)
	    Toast.success("Purchased Dragon Sword")
	    Toast.push({ message = "+1 Coin", severity = "success", key = "coin" })
--]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Icons = require(script.Parent.Icons)
local Motion = require(script.Parent.Motion)
local Tokens = require(script.Parent.Tokens)

local Toast = {}

-- // CONFIGURATION // --

local MAX_VISIBLE = 3
local MAX_QUEUED = 10
local ENTER_TRAVEL = 20 -- studs of slide on entry; small, not across the screen
local SPRING_TIME = 0.14 -- reflow feel

export type Severity = "info" | "success" | "warning" | "error"

-- Severity changes BEHAVIOUR, not just tint. Never colour alone for meaning:
-- every level carries an icon image as well.
local SEVERITY = table.freeze({
	info = {
		colour = Tokens.status.info,
		icon = Icons.info,
		priority = 1,
		dismissable = false,
	},
	success = {
		colour = Tokens.status.success,
		icon = Icons.circleCheck,
		priority = 1,
		dismissable = false,
	},
	warning = {
		colour = Tokens.status.warning,
		icon = Icons.triangleAlert,
		priority = 2,
		dismissable = false,
	},
	error = {
		colour = Tokens.status.danger,
		icon = Icons.circleX,
		priority = 3,
		dismissable = true,
	},
})

export type Options = {
	message: string,
	severity: Severity?,
	key: string?, -- dedup key; repeats increment a count
	duration: number?, -- omit to derive from message length
	dismissable: boolean?, -- show a close control, suppress the timer
}

type Entry = {
	options: Options,
	severity: Severity,
	count: number,
	frame: CanvasGroup,
	label: TextLabel,
	spring: Motion.Spring,
	remaining: number,
	paused: boolean,
	dying: boolean,
	height: number,
	connections: { RBXScriptConnection },
	y: number,
	xOffset: number,
	springs: { Motion.Spring },
	applyPosition: (self: Entry) -> (),
}

-- // STATE // --

local visible: { Entry } = {}
local queued: { Options } = {}
local byKey: { [string]: Entry } = {}
local container: Frame? = nil
local heartbeat: RBXScriptConnection? = nil

-- // HELPERS // --

--[[ 3-6s band, scaled to how long the message takes to read. ]]
local function durationFor(message: string, severity: Severity): number
	local words = select(2, message:gsub("%S+", "")) + 1
	local base = math.clamp(2.5 + words * 0.35, 3, 8)

	if severity == "error" then
		base += 3
	elseif severity == "warning" then
		base += 1.5
	end

	-- No hover-to-pause on touch, so give touch players longer.
	if not GuiService.TouchControlsEnabled then
		return base
	end
	return base + 1
end

local function ensureContainer(): Frame
	if container and container.Parent then
		return container
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10) :: PlayerGui?
	if not playerGui then
		error("Toast: PlayerGui never appeared", 2)
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "ToastLayer"
	screen.ResetOnSpawn = false
	-- Keeps toasts clear of notches, the topbar and mobile controls. Never
	-- hardcode a topbar height; GetGuiInset is the live source of truth.
	screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 1000
	screen.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Toasts"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -Tokens.toast.edgeInset, 0, Tokens.toast.edgeInset)
	-- Scale-capped rather than a bare 320 offset: on a 360px phone a fixed
	-- 320 plus the edge inset runs off the screen, and a toast that is partly
	-- off-screen is a toast nobody reads.
	frame.Size = UDim2.new(1, -Tokens.toast.edgeInset * 2, 0, 0)
	frame.Parent = screen

	local width = Instance.new("UISizeConstraint")
	width.MaxSize = Vector2.new(Tokens.toast.width, math.huge)
	width.MinSize = Vector2.new(Tokens.toast.minWidth, 0)
	width.Parent = frame

	container = frame
	return frame
end

--[[ Recompute every visible toast's target from its index.

	This is the whole reflow mechanism: nothing stores its own position, so a
	toast dying in the MIDDLE of the stack simply changes the indices below it
	and their springs carry them up.
]]
local function reflow()
	local offset = 0
	for _, entry in visible do
		entry.spring:setTarget(offset)
		offset += entry.height + Tokens.toast.gap
	end
end

local function indexOf(entry: Entry): number?
	return table.find(visible, entry)
end

local dismiss -- forward declaration; pump and dismiss are mutually recursive

local function pumpQueue()
	while #visible < MAX_VISIBLE and #queued > 0 do
		local next = table.remove(queued, 1)
		if next then
			Toast.push(next)
		end
	end
end

--[[ Remove a toast, animating out and tearing down everything it owns. ]]
function dismiss(entry: Entry)
	if entry.dying then
		return
	end
	entry.dying = true

	if entry.options.key then
		byKey[entry.options.key] = nil
	end

	local at = indexOf(entry)
	if at then
		table.remove(visible, at)
	end

	reflow() -- survivors close the gap immediately
	pumpQueue()

	local function destroy()
		for _, connection in entry.connections do
			connection:Disconnect()
		end
		table.clear(entry.connections)
		entry.spring:destroy()
		for _, spring in entry.springs do
			spring:destroy()
		end
		table.clear(entry.springs)
		entry.frame:Destroy()
	end

	if Motion.isReducedMotion() then
		destroy()
		return
	end

	-- Exit: fade plus a small slide toward the anchor edge, In easing.
	entry.xOffset = ENTER_TRAVEL
	entry:applyPosition()
	Motion.play(entry.frame, "exit", { GroupTransparency = 1 }, destroy)
end

--[[ One timer loop for every toast, rather than a thread each. ]]
local function ensureHeartbeat()
	if heartbeat then
		return
	end

	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		for index = #visible, 1, -1 do
			local entry = visible[index]
			if entry.paused or entry.dying or entry.options.dismissable then
				continue
			end

			entry.remaining -= dt
			if entry.remaining <= 0 then
				dismiss(entry)
			end
		end

		if #visible == 0 and #queued == 0 and heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end)
end

-- // BUILD // --

local function buildFrame(options: Options, severity: Severity): (CanvasGroup, TextLabel, number)
	local spec = SEVERITY[severity]

	-- CanvasGroup so the whole toast fades as one composited layer: one tween
	-- instead of one per child, and no half-faded contents.
	local group = Instance.new("CanvasGroup")
	group.Name = "Toast"
	group.BackgroundColor3 = Tokens.toast.background
	group.BackgroundTransparency = 0
	group.BorderSizePixel = 0
	group.AnchorPoint = Vector2.new(1, 0)
	group.Size = UDim2.new(1, 0, 0, 0)
	group.AutomaticSize = Enum.AutomaticSize.Y
	group.GroupTransparency = 1

	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = Tokens.radius.panel
	corner.TopRightRadius = Tokens.radius.panel
	corner.BottomLeftRadius = Tokens.radius.panel
	corner.BottomRightRadius = Tokens.radius.panel
	corner.Parent = group

	-- Inner, so the toast stays exactly its declared size inside the stack.
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	stroke.Thickness = 1
	stroke.Color = Tokens.stroke.base
	stroke.Transparency = 0.4
	stroke.Parent = group

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Tokens.space.base)
	padding.PaddingBottom = UDim.new(0, Tokens.space.base)
	padding.PaddingLeft = UDim.new(0, Tokens.space.base)
	padding.PaddingRight = UDim.new(0, Tokens.space.base)
	padding.Parent = group

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Tokens.space.snug)
	layout.Parent = group

	-- Severity accent bar. Paired with an icon so meaning is never colour-alone.
	local bar = Instance.new("Frame")
	bar.Name = "Accent"
	bar.LayoutOrder = 0
	bar.BackgroundColor3 = spec.colour
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(0, 3, 1, 0)
	bar.Parent = group

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.LayoutOrder = 1
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(16, 16)
	icon.Image = spec.icon
	icon.ImageColor3 = spec.colour
	icon.Parent = group

	local label = Instance.new("TextLabel")
	label.Name = "Message"
	label.LayoutOrder = 2
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.Y
	-- Width is the container minus padding, bar, icon and gaps.
	label.Size = UDim2.new(1, -(Tokens.space.base * 2 + 3 + 16 + Tokens.space.snug * 2), 0, 0)
	label.FontFace = Tokens.font.body
	label.TextSize = Tokens.text_size.body
	label.TextColor3 = Tokens.text.primary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Text = options.message
	label.Parent = group

	-- AutomaticSize has not resolved yet; estimate for the first reflow and
	-- correct it once the layout reports a real size.
	local estimatedHeight = 44

	return group, label, estimatedHeight
end

-- // PUBLIC // --

--[[ Push a toast. Returns nothing — call sites should not manage lifecycle. ]]
function Toast.push(options: Options)
	local severity: Severity = options.severity or "info"
	local spec = SEVERITY[severity]
	if not spec then
		error(`Toast.push: unknown severity "{tostring(options.severity)}"`, 2)
	end

	-- 1. Dedup. A reward loop must not paper the screen with identical toasts.
	local key = options.key
	if key then
		local existing = byKey[key]
		if existing and not existing.dying then
			existing.count += 1
			existing.label.Text = `{existing.options.message} (x{existing.count})`
			existing.remaining = durationFor(existing.options.message, existing.severity)
			existing.paused = false
			return
		end
	end

	-- 2. Capacity. Queue overflow; let high severity preempt.
	if #visible >= MAX_VISIBLE then
		local preempts = spec.priority >= 3
		if preempts then
			-- Evict the oldest lower-priority toast rather than making an error wait.
			for _, entry in visible do
				if SEVERITY[entry.severity].priority < spec.priority then
					dismiss(entry)
					break
				end
			end
		end

		if #visible >= MAX_VISIBLE then
			if #queued >= MAX_QUEUED then
				-- Drop the oldest low-priority queued item. An unbounded queue
				-- means toasts arriving long after the player has moved on.
				table.remove(queued, 1)
			end
			table.insert(queued, options)
			return
		end
	end

	-- 3. Build.
	local parent = ensureContainer()
	local frame, label, height = buildFrame(options, severity)
	frame.Parent = parent

	-- SmoothDamp does not support UDim2, so spring the Y OFFSET as a number and
	-- compose the Position from it. This is why Motion.springValue exists.
	local entry: Entry
	local spring = Motion.springValue(0, SPRING_TIME, function(y: number)
		entry.y = y
		entry:applyPosition()
	end)

	entry = {
		options = options,
		severity = severity,
		count = 1,
		frame = frame,
		label = label,
		spring = spring,
		remaining = options.duration or durationFor(options.message, severity),
		paused = false,
		dying = false,
		height = height,
		connections = {},
		springs = {},
		y = 0,
		xOffset = 0,
		applyPosition = function(self: Entry)
			self.frame.Position = UDim2.new(1, self.xOffset, 0, self.y)
		end,
	}

	table.insert(visible, entry)

	-- Correct the estimated height once the layout resolves, then reflow again.
	table.insert(
		entry.connections,
		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local actual = frame.AbsoluteSize.Y
			if actual > 0 and math.abs(actual - entry.height) > 1 then
				entry.height = actual
				reflow()
			end
		end)
	)

	-- 4. Pause on hover. Store REMAINING, not a deadline.
	table.insert(
		entry.connections,
		frame.MouseEnter:Connect(function()
			entry.paused = true
		end)
	)
	table.insert(
		entry.connections,
		frame.MouseLeave:Connect(function()
			entry.paused = false
		end)
	)

	-- Tap to dismiss — the only route on touch, where there is no hover.
	table.insert(
		entry.connections,
		frame.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				dismiss(entry)
			end
		end)
	)

	-- 5. Enter, then start the shared timer.
	if Motion.isReducedMotion() then
		frame.GroupTransparency = 0
		entry.xOffset = 0
		reflow()
	else
		-- Slide in from the anchor edge: a small travel, not across the screen.
		entry.xOffset = ENTER_TRAVEL
		entry:applyPosition()
		reflow()
		Motion.tween(frame, "enter", { GroupTransparency = 0 }):Play()

		-- Ease the horizontal travel back to rest alongside the fade.
		local slide = Motion.springValue(ENTER_TRAVEL, SPRING_TIME, function(x: number)
			entry.xOffset = x
			entry:applyPosition()
		end)
		slide:setTarget(0)
		table.insert(entry.springs, slide)
	end

	if key then
		byKey[key] = entry
	end

	ensureHeartbeat()
end

function Toast.info(message: string, options: Options?)
	local merged: Options = options or { message = message }
	merged.message, merged.severity = message, "info"
	Toast.push(merged)
end

function Toast.success(message: string, options: Options?)
	local merged: Options = options or { message = message }
	merged.message, merged.severity = message, "success"
	Toast.push(merged)
end

function Toast.warning(message: string, options: Options?)
	local merged: Options = options or { message = message }
	merged.message, merged.severity = message, "warning"
	Toast.push(merged)
end

function Toast.error(message: string, options: Options?)
	local merged: Options = options or { message = message }
	merged.message, merged.severity = message, "error"
	Toast.push(merged)
end

--[[ How many toasts are on screen and waiting.

	Useful for a dev HUD, and for tests. Does not expose the entries themselves.
--]]
function Toast.count(): (number, number)
	return #visible, #queued
end

--[[ Internal state, for tests only. Not part of the supported surface. ]]
function Toast._debug()
	return visible, queued, byKey, dismiss
end

--[[ Tear everything down. Call from the controller that owns the UI. ]]
function Toast.destroy()
	for index = #visible, 1, -1 do
		local entry = visible[index]
		for _, connection in entry.connections do
			connection:Disconnect()
		end
		entry.spring:destroy()
		for _, spring in entry.springs do
			spring:destroy()
		end
		entry.frame:Destroy()
	end

	table.clear(visible)
	table.clear(queued)
	table.clear(byKey)

	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end

	if container then
		local screen = container.Parent
		if screen then
			screen:Destroy()
		end
		container = nil
	end
end

return Toast
