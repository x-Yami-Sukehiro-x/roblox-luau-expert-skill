--!strict
--[[
	Layout — the constructors that get retyped in every Roblox UI file.

	Explained in: roblox-ui/references/build-order.md (steps 3 and 5)

	This is not an abstraction layer. It is the eight modifier instances that
	appear in every file, with the properties that are wrong by default already
	set:

	  - UIListLayout sorts by NAME unless told otherwise, which surprises
	    everyone exactly once and then silently reorders a menu later.
	  - UICorner has four separate radius properties, so a "set the radius" call
	    is four lines every time.
	  - UIPadding is four properties for what is almost always one number.
	  - ScrollingFrame needs CanvasSize cleared AND AutomaticCanvasSize set, and
	    omitting the first makes the second look broken.

	Every function returns the instance so it can be assigned, and parents it
	when a parent is given.
--]]

local Tokens = require(script.Parent.Tokens)

local Layout = {}

--[[
	Uniform padding. Pass one number, or a table of sides.

	    Layout.padding(panel, Tokens.space.loose)
	    Layout.padding(row, { left = 12, right = 12 })
--]]
export type Sides = { top: number?, bottom: number?, left: number?, right: number? }

function Layout.padding(parent: Instance, amount: number | Sides): UIPadding
	local padding = Instance.new("UIPadding")

	if typeof(amount) == "number" then
		local value = UDim.new(0, amount)
		padding.PaddingTop = value
		padding.PaddingBottom = value
		padding.PaddingLeft = value
		padding.PaddingRight = value
	else
		local sides = amount :: Sides
		padding.PaddingTop = UDim.new(0, sides.top or 0)
		padding.PaddingBottom = UDim.new(0, sides.bottom or 0)
		padding.PaddingLeft = UDim.new(0, sides.left or 0)
		padding.PaddingRight = UDim.new(0, sides.right or 0)
	end

	padding.Parent = parent
	return padding
end

--[[
	A vertical stack. SortOrder is LayoutOrder, because the default sorts by
	name and that is never what was meant.
--]]
function Layout.column(parent: Instance, gap: number?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap or Tokens.space.snug)
	layout.Parent = parent
	return layout
end

--[[ A horizontal row, vertically centred — the settings-row shape. ]]
function Layout.row(parent: Instance, gap: number?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap or Tokens.space.base)
	layout.Parent = parent
	return layout
end

--[[
	Let this child absorb the space its siblings do not use.

	This is what removes height arithmetic from a header/body/footer layout: the
	body is Fill, so adding a subtitle to the header cannot break it.
--]]
function Layout.fill(instance: GuiObject): UIFlexItem
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = instance
	return flex
end

--[[ One radius, all four corners. ]]
function Layout.corner(parent: Instance, radius: UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = radius
	corner.TopRightRadius = radius
	corner.BottomLeftRadius = radius
	corner.BottomRightRadius = radius
	corner.Parent = parent
	return corner
end

--[[
	Top-corners-only, for a bottom sheet. The bottom corners stay square
	because they sit on the screen edge and rounding them reads as a mistake.
--]]
function Layout.topCorner(parent: Instance, radius: UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.TopLeftRadius = radius
	corner.TopRightRadius = radius
	corner.BottomLeftRadius = UDim.new(0, 0)
	corner.BottomRightRadius = UDim.new(0, 0)
	corner.Parent = parent
	return corner
end

--[[
	An inner border. Inner keeps the instance exactly its declared Size, so it
	stays aligned with siblings inside a UIListLayout — an Outer stroke does not.
--]]
function Layout.stroke(parent: Instance, colour: Color3, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	stroke.Thickness = thickness or 1
	stroke.Color = colour
	stroke.Parent = parent
	return stroke
end

--[[ Min and max in pixels. Both, always — one without the other is half a guard. ]]
function Layout.bounds(parent: Instance, min: Vector2, max: Vector2): UISizeConstraint
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = min
	constraint.MaxSize = max
	constraint.Parent = parent
	return constraint
end

--[[
	A scrolling container sized by its content.

	CanvasSize must be cleared as well as AutomaticCanvasSize being set;
	leaving a stale CanvasSize is why "AutomaticCanvasSize does nothing" is a
	recurring complaint.
--]]
function Layout.scroller(parent: Instance, gap: number?): ScrollingFrame
	local scroller = Instance.new("ScrollingFrame")
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.CanvasSize = UDim2.new()
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollBarThickness = 4
	scroller.ScrollBarImageTransparency = 0.5
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.Parent = parent

	Layout.column(scroller, gap)

	return scroller
end

--[[
	A text label with the type scale applied. `role` names the step, so a
	retune is one edit in Tokens rather than a sweep for numbers.
--]]
export type TextRole = "caption" | "body" | "emphasis" | "title" | "display"

function Layout.label(parent: Instance, text: string, role: TextRole?): TextLabel
	local chosen: TextRole = role or "body"
	local size = Tokens.text_size[chosen]
	if not size then
		error(`Layout.label: unknown text role "{chosen}"`, 2)
	end

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.fromScale(1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.TextScaled = false
	label.FontFace = if chosen == "body" or chosen == "caption"
		then Tokens.font.body
		else Tokens.font.emphasis
	label.TextSize = size
	label.TextColor3 = if chosen == "caption" then Tokens.text.secondary else Tokens.text.primary
	label.Text = text
	label.Parent = parent

	-- Bound it, or the label becomes illegible on a phone and enormous on a TV.
	local bound = Instance.new("UITextSizeConstraint")
	bound.MinTextSize = math.max(12, size - 4)
	bound.MaxTextSize = size + 6
	bound.Parent = label

	return label
end

--[[
	The root panel every menu starts from: centred, bounded, padded, stacked.

	Returns the frame. Its children go straight in with a LayoutOrder.
--]]
function Layout.panelRoot(parent: Instance, minSize: Vector2?, maxSize: Vector2?): Frame
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = Tokens.surface.base
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(0.5, 0.65)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Parent = parent

	Layout.bounds(root, minSize or Vector2.new(300, 320), maxSize or Vector2.new(720, 820))
	Layout.corner(root, Tokens.radius.panel)
	Layout.padding(root, Tokens.space.loose)
	Layout.column(root, Tokens.space.base)

	return root
end

return Layout
