-- The default palette: cool neutrals and a green accent. Every text role meets
-- 4.5:1 on the surfaces it sits on; tools/tests/hub-kit.test.mjs checks each pair.
return {
	name = "Midnight",
	background = Color3.fromRGB(17, 19, 24),
	surface = Color3.fromRGB(27, 30, 37),
	raised = Color3.fromRGB(38, 42, 51),
	hover = Color3.fromRGB(52, 57, 68),
	stroke = Color3.fromRGB(62, 68, 80),
	text = Color3.fromRGB(241, 243, 247),
	textMuted = Color3.fromRGB(165, 171, 183),
	accent = Color3.fromRGB(46, 160, 127),
	accentHover = Color3.fromRGB(72, 201, 162),
	onAccent = Color3.fromRGB(9, 10, 13),
	focus = Color3.fromRGB(72, 201, 162),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	danger = Color3.fromRGB(224, 98, 92),
	info = Color3.fromRGB(88, 141, 214),
}
