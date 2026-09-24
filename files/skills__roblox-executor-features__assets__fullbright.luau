local TOGGLE_KEY = Enum.KeyCode.B
local DAYLIGHT = {
	Brightness = 2,
	ClockTime = 14,
	FogEnd = 100000,
	GlobalShadows = false,
	Ambient = Color3.fromRGB(178, 178, 178),
	OutdoorAmbient = Color3.fromRGB(178, 178, 178),
}

local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Fullbright then
	features.Fullbright.unload()
end

local fullbright = { on = false, alive = true }
local original: { [string]: any } = {}
local watchers: { RBXScriptConnection } = {}
local toggle: RBXScriptConnection

local function dim()
	for _, watcher in watchers do
		watcher:Disconnect()
	end
	table.clear(watchers)
	for property, value in original do
		Lighting[property] = value
	end
	table.clear(original)
end

-- Day and night cycles rewrite ClockTime every few frames; each watcher writes
-- the daylight value straight back.
local function brighten()
	for property, value in DAYLIGHT do
		original[property] = Lighting[property]
		Lighting[property] = value
		table.insert(
			watchers,
			Lighting:GetPropertyChangedSignal(property):Connect(function()
				Lighting[property] = value
			end)
		)
	end
end

function fullbright.set(on: boolean)
	fullbright.on = on
	dim()
	if on then
		brighten()
	end
end

function fullbright.unload()
	fullbright.alive = false
	fullbright.set(false)
	toggle:Disconnect()
	if features.Fullbright == fullbright then
		features.Fullbright = nil
	end
end

toggle = UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == TOGGLE_KEY then
		fullbright.set(not fullbright.on)
	end
end)

features.Fullbright = fullbright
fullbright.set(true)
