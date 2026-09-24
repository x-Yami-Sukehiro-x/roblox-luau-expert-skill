--!strict
--[[
	Panel — a surface with layered strokes and a native shadow.

	Explained in: roblox-ui-components/references/shadows-and-elevation.md
	             roblox-ui-components/references/outlines-and-dividers.md

	Deliberate choices:
	  - UIShadow, not a 9-slice ImageLabel. It follows the parent's corner radius
	    automatically, needs no asset, and costs one instance instead of one
	    instance plus an upload. The old ImageLabel technique is documented as a
	    fallback, not as the recommendation.
	  - Layered strokes (outer shadow + inner highlight) read as a bevelled edge
	    for two instances, instead of one flat 1px box on everything (R1).
	  - BorderStrokePosition.Inner keeps the panel exactly its declared Size, so
	    it stays aligned with siblings inside a UIListLayout.
	  - Shadow values come from Tokens.elevation, so depth is a scale rather than
	    a number chosen per component.
--]]

local Tokens = require(script.Parent.Parent.Tokens)

local Panel = {}

export type Options = {
	size: UDim2?,
	elevation: ("base" | "raised" | "overlay")?,
	padding: number?,
	bevel: boolean?,
	-- Depth level from Tokens.elevation. Defaults to a level implied by
	-- `elevation`, so the common case needs neither.
	depth: ("flush" | "raised" | "floating" | "overlay")?,
}

-- A panel raised in colour is usually raised in depth too, so the caller only
-- has to say one thing.
local DEPTH_FOR_ELEVATION: { [string]: string } = {
	base = "flush",
	raised = "raised",
	overlay = "overlay",
}

local function surfaceFor(elevation: string): Color3
	if elevation == "raised" then
		return Tokens.surface.raised
	elseif elevation == "overlay" then
		return Tokens.surface.overlay
	end
	return Tokens.surface.base
end

--[[
	    local panel = Panel.new({ elevation = "raised", bevel = true })
	    panel.Parent = screenGui
--]]
function Panel.new(options: Options?): Frame
	local settings = options or {}
	local elevation = settings.elevation or "base"

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.BackgroundColor3 = surfaceFor(elevation)
	frame.BorderSizePixel = 0
	frame.Size = settings.size or UDim2.fromScale(1, 1)

	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = Tokens.radius.panel
	corner.TopRightRadius = Tokens.radius.panel
	corner.BottomLeftRadius = Tokens.radius.panel
	corner.BottomRightRadius = Tokens.radius.panel
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	local amount = settings.padding or Tokens.space.loose
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.Parent = frame

	-- Inner stroke: the panel stays exactly its declared Size.
	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	edge.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	edge.Thickness = 1
	edge.Color = Tokens.stroke.base
	edge.Transparency = 0.35
	edge.ZIndex = 1
	edge.Parent = frame

	-- Optional second stroke, outside and darker, for a bevelled read.
	if settings.bevel then
		local outer = Instance.new("UIStroke")
		outer.Name = "Bevel"
		outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outer.BorderStrokePosition = Enum.BorderStrokePosition.Outer
		outer.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
		outer.Thickness = 2
		outer.Color = Tokens.stroke.shadow
		outer.Transparency = 0.55
		outer.ZIndex = 0 -- beneath the inner edge
		outer.Parent = frame
	end

	-- Native shadow. Follows the corner radius above without being told, which
	-- is the thing the 9-slice technique could never do.
	local depth = settings.depth or DEPTH_FOR_ELEVATION[elevation] or "flush"
	local level = Tokens.elevation[depth]

	if level and level.blur > 0 then
		local shadow = Instance.new("UIShadow")
		shadow.Name = "Shadow"
		shadow.Color = Tokens.stroke.shadow
		shadow.BlurRadius = UDim.new(0, level.blur)
		shadow.Offset = UDim2.fromOffset(0, level.offset)
		shadow.Transparency = level.transparency
		shadow.Parent = frame
	end

	return frame
end

--[[ A vertical stack inside a panel — the common case, so it is one call. ]]
function Panel.stack(options: Options?, gap: number?): (Frame, UIListLayout)
	local frame = Panel.new(options)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap or Tokens.space.base)
	layout.Parent = frame

	return frame, layout
end

return Panel
