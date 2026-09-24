--!strict
--[[
	Tokens — the three-tier design spine.

	Re-skin the entire interface by editing this one file. Nothing else in the
	library contains a colour literal.

	Explained in: roblox-ui/references/gui-architecture.md
	Rationale for the tiering: roblox-ui/references/anti-slop-catalog.md (R4, R6, R15)

	The three tiers:
	  1. PRIMITIVE — raw values. Never referenced outside this file.
	  2. SEMANTIC  — meaning ("the raised surface"). What components read.
	  3. COMPONENT — per-component overrides, only where one genuinely differs.

	Components read SEMANTIC. That indirection is what makes a re-theme one edit
	instead of forty.
--]]

-- // TIER 1: PRIMITIVE // --
-- Raw values with no meaning attached. Change these for a full re-skin.

local PRIMITIVE = {
	-- A neutral ramp. The steps are deliberately uneven: the jump from page to
	-- panel is larger than panel to control, so surfaces actually separate.
	-- Even 10-point steps are catalog tell R4.
	neutral = {
		[0] = Color3.fromRGB(9, 10, 13),
		[1] = Color3.fromRGB(19, 21, 26),
		[2] = Color3.fromRGB(31, 34, 41),
		[3] = Color3.fromRGB(44, 48, 57),
		[4] = Color3.fromRGB(63, 68, 79),
		[5] = Color3.fromRGB(96, 103, 117),
		[6] = Color3.fromRGB(150, 157, 170),
		[7] = Color3.fromRGB(205, 210, 219),
		[8] = Color3.fromRGB(243, 245, 248),
	},

	-- ONE accent. Used 3-5 times in the whole interface, never as decoration.
	accent = {
		dim = Color3.fromRGB(28, 88, 74),
		base = Color3.fromRGB(46, 160, 127),
		bright = Color3.fromRGB(72, 201, 162),
	},

	-- Status hues. Never the only signal for meaning — always paired with an
	-- icon or a word. See roblox-ui-components/references/toasts.md.
	status = {
		info = Color3.fromRGB(88, 141, 214),
		success = Color3.fromRGB(72, 178, 112),
		warning = Color3.fromRGB(214, 158, 62),
		danger = Color3.fromRGB(208, 88, 82),
	},

	-- One base unit. Every gap in the UI is a multiple of it, which is what
	-- produces rhythm rather than uniformity (R6).
	unit = 4,
}

-- // TIER 2: SEMANTIC // --
-- What things mean. This is the layer components are allowed to read.

local function step(multiplier: number): number
	return PRIMITIVE.unit * multiplier
end

local Tokens = {}

Tokens.surface = table.freeze({
	page = PRIMITIVE.neutral[0],
	sunken = PRIMITIVE.neutral[1],
	base = PRIMITIVE.neutral[2],
	raised = PRIMITIVE.neutral[3],
	overlay = PRIMITIVE.neutral[4],
})

Tokens.text = table.freeze({
	primary = PRIMITIVE.neutral[8],
	secondary = PRIMITIVE.neutral[6],
	muted = PRIMITIVE.neutral[5],
	onAccent = PRIMITIVE.neutral[0],
	danger = PRIMITIVE.status.danger,
})

Tokens.stroke = table.freeze({
	subtle = PRIMITIVE.neutral[3],
	base = PRIMITIVE.neutral[4],
	strong = PRIMITIVE.neutral[5],
	highlight = PRIMITIVE.neutral[6],
	shadow = PRIMITIVE.neutral[0],
	focus = PRIMITIVE.accent.bright,
})

-- Elevation. Blur and offset rise together while transparency FALLS, because a
-- higher surface casts a larger, softer, slightly stronger shadow. Raising blur
-- while keeping the shadow faint produces fog rather than height.
-- Only one element on screen should sit at `overlay`.
Tokens.elevation = table.freeze({
	flush = table.freeze({ blur = 0, offset = 0, transparency = 1 }),
	raised = table.freeze({ blur = 6, offset = 2, transparency = 0.86 }),
	floating = table.freeze({ blur = 18, offset = 6, transparency = 0.75 }),
	overlay = table.freeze({ blur = 40, offset = 14, transparency = 0.62 }),
})

Tokens.accent = table.freeze({
	dim = PRIMITIVE.accent.dim,
	base = PRIMITIVE.accent.base,
	bright = PRIMITIVE.accent.bright,
})

Tokens.status = table.freeze(PRIMITIVE.status)

-- Spacing. Named by role, not by number, so "tight" can be retuned globally.
Tokens.space = table.freeze({
	hairline = step(0.25),
	tight = step(1), --  4
	snug = step(2), --  8
	base = step(3), -- 12
	loose = step(4), -- 16
	section = step(6), -- 24
	page = step(8), -- 32
})

-- A real type scale with clear jumps. Not TextScaled (catalog tell R2).
Tokens.text_size = table.freeze({
	caption = 12,
	body = 14,
	emphasis = 16,
	title = 20,
	display = 28,
})

Tokens.radius = table.freeze({
	sharp = UDim.new(0, 0),
	control = UDim.new(0, 6),
	panel = UDim.new(0, 10),
	pill = UDim.new(0.5, 0),
})

Tokens.font = table.freeze({
	body = Font.fromEnum(Enum.Font.GothamMedium),
	emphasis = Font.fromEnum(Enum.Font.GothamBold),
})

-- // TIER 3: COMPONENT // --
-- Only where a component genuinely differs from the semantic layer. Keep this
-- small; a large tier 3 means the semantic layer is wrong.

Tokens.control = table.freeze({
	base = Tokens.surface.raised,
	hover = Tokens.surface.overlay,
	pressed = Tokens.surface.base,
	disabled = Tokens.surface.sunken,
})

-- Destructive actions get their own ramp rather than components lerping toward
-- white, so a re-skin can retune them independently.
Tokens.danger = table.freeze({
	base = PRIMITIVE.status.danger,
	hover = Color3.fromRGB(224, 112, 106),
	pressed = Color3.fromRGB(172, 68, 63),
})

Tokens.toast = table.freeze({
	background = Tokens.surface.overlay,
	-- A cap, not a fixed width. The container is scale-sized and bounded by
	-- these, so a phone narrower than `width` gets a narrower toast instead of
	-- one that runs off the edge.
	width = 320,
	minWidth = 240,
	gap = Tokens.space.snug,
	edgeInset = Tokens.space.loose,
})

return table.freeze(Tokens)
