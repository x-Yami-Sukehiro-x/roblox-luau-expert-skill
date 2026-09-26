--[[
	OpenButton - the chip that brings a hidden window back.

	A phone has no menu key, so a hidden window with no on-screen way back is
	a hub the player can only reopen by re-executing. The chip sits at the top
	centre, below the Roblox topbar, and can be dragged anywhere; a tap that
	did not move reopens the window. On a keyboard device it also names the
	menu key, so the chip teaches the shortcut instead of replacing it.
--]]

local UserInputService = game:GetService("UserInputService")

local Drag = require(script.Parent.Parent.Core.Drag)
local Icons = require(script.Parent.Parent.Core.Icons)
local New = require(script.Parent.Parent.Core.New)
local Theme = require(script.Parent.Parent.Core.Theme)

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
