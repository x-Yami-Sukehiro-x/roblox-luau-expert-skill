-- Run after a feature "does nothing" and send back what it prints. It reads
-- only; nothing in the game or in the features is changed.
local WATCH_SECONDS = 5

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local getgenv = getgenv
assert(getgenv, "needs getgenv")

-- Optional: without them the report says "unknown" and is printed only.
local identifyexecutor, setclipboard = identifyexecutor, setclipboard

-- Features that cannot both act at once, and what the player sees.
local CONFLICTS = {
	{ "Fly", "Freecam", "freecam anchors the body; fly moves it again once freecam is off" },
	{ "Spectate", "Freecam", "freecam owns the camera; spectating shows again once it is off" },
	{ "Speed", "Fly", "fly sets its own speed; the walk speed applies again after landing" },
	{ "ClickTeleport", "Freecam", "teleports move the anchored body; the camera stays put" },
}

local WATCHED = {
	Humanoid = { "WalkSpeed", "JumpPower", "JumpHeight", "PlatformStand", "Sit" },
	HumanoidRootPart = { "Anchored", "CanCollide" },
	Camera = { "CameraType", "CameraSubject", "FieldOfView" },
	Player = { "CameraMaxZoomDistance", "CameraMode" },
	Lighting = { "ClockTime", "Brightness", "FogEnd" },
}

local player = Players.LocalPlayer
local features = getgenv().Features or {}
local report: { string } = {}
local writes: { [string]: number } = {}
local watchers: { RBXScriptConnection } = {}

local function add(line: string)
	table.insert(report, line)
end

local executor = if identifyexecutor then table.concat({ identifyexecutor() }, " ") else "unknown"
add(`feature doctor  PlaceId {game.PlaceId}  executor {executor}`)

add("== features")
local names = {}
for name in features do
	table.insert(names, name)
end
table.sort(names)
if #names == 0 then
	add("none loaded: run the feature script first, then this")
end
for _, name in names do
	local session = features[name]
	local state = if session.on then "on" else "off"
	if session.alive == false then
		state = "unloaded but still registered"
	end
	add(`{name}: {state}`)
end
for _, pair in CONFLICTS do
	local first, second = features[pair[1]], features[pair[2]]
	if first and second and first.on and second.on then
		add(`{pair[1]} and {pair[2]} are both on: {pair[3]}`)
	end
end

add("== character")
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = humanoid and humanoid.RootPart
if humanoid == nil or root == nil then
	add("no character with a Humanoid and a root part: features apply on the next spawn")
else
	add(`health {humanoid.Health}, state {humanoid:GetState()}`)
	if humanoid.SeatPart then
		add("seated: fly, noclip and teleports move the seat or nothing until you jump out")
	end
	if root.Anchored then
		add("the root is anchored, by freecam or by the game (a lobby, cutscene or stun)")
	end
	if humanoid.PlatformStand and not (features.Fly and features.Fly.on) then
		add("PlatformStand is on and fly is not: the game set it, so walking is disabled")
	end
end
if Workspace.StreamingEnabled then
	add("StreamingEnabled: distant parts and players are not loaded, so ESP and teleports see less")
end

local targets = {
	Humanoid = humanoid,
	HumanoidRootPart = root,
	Camera = Workspace.CurrentCamera,
	Player = player,
	Lighting = Lighting,
}
for label, properties in WATCHED do
	local target = targets[label]
	if target == nil then
		continue
	end
	for _, property in properties do
		local key = `{label}.{property}`
		writes[key] = 0
		table.insert(
			watchers,
			target:GetPropertyChangedSignal(property):Connect(function()
				writes[key] += 1
			end)
		)
	end
end

task.delay(WATCH_SECONDS, function()
	for _, watcher in watchers do
		watcher:Disconnect()
	end
	add(`== changes in {WATCH_SECONDS} s (more than 2: something keeps writing it)`)
	local changed = {}
	for key, count in writes do
		if count > 0 then
			table.insert(changed, key)
		end
	end
	table.sort(changed)
	for _, key in changed do
		add(`{key}: {writes[key]}`)
	end
	if #changed == 0 then
		add("nothing changed")
	end
	if setclipboard then
		add("(this report is on the clipboard)")
	end
	local text = table.concat(report, "\n")
	print(text)
	if setclipboard then
		setclipboard(text)
	end
end)
