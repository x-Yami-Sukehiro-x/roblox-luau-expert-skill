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
