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

local Mount = require(script.Parent.Parent.Core.Mount)
local New = require(script.Parent.Parent.Core.New)
local Trove = require(script.Parent.Parent.Core.Trove)

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
