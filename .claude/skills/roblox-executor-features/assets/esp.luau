local TOGGLE_KEY = Enum.KeyCode.H
-- The engine draws at most 31 Highlights at once and silently skips the rest,
-- so the nearest players get them.
local HIGHLIGHT_LIMIT = 31
local REFRESH_SECONDS = 0.25
local ENEMY_FILL = 0.6
local TAG_SIZE = UDim2.fromOffset(200, 20)
local TAG_OFFSET = Vector3.new(0, 3, 0)
local COLOURS = {
	enemy = Color3.fromRGB(208, 88, 82),
	friend = Color3.fromRGB(72, 178, 112),
	text = Color3.fromRGB(243, 245, 248),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local getgenv, gethui = getgenv, gethui
assert(getgenv and gethui, "needs getgenv, gethui")

local features = getgenv().Features or {}
getgenv().Features = features
if features.Esp then
	features.Esp.unload()
end

type Marker = { highlight: Highlight, tag: BillboardGui, label: TextLabel }

local player = Players.LocalPlayer
local esp = { on = false, alive = true }
local markers: { [Player]: Marker } = {}
local connections: { RBXScriptConnection } = {}
local sinceRefresh = 0

local function track(other: Player)
	if other == player or markers[other] then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = `{other.Name}Highlight`
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = gethui()
	local tag = Instance.new("BillboardGui")
	tag.Name = `{other.Name}Tag`
	tag.AlwaysOnTop = true
	tag.Size = TAG_SIZE
	tag.StudsOffsetWorldSpace = TAG_OFFSET
	tag.Enabled = false
	tag.Parent = gethui()
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.TextSize = 14
	label.TextColor3 = COLOURS.text
	label.TextStrokeTransparency = 0
	label.Text = other.DisplayName
	label.Parent = tag
	markers[other] = { highlight = highlight, tag = tag, label = label }
end

local function untrack(other: Player)
	local marker = markers[other]
	if marker then
		marker.highlight:Destroy()
		marker.tag:Destroy()
		markers[other] = nil
	end
end

-- Teammates get an outline only, so friend and enemy differ in shape as well
-- as colour.
local function refresh()
	local here = Workspace.CurrentCamera.CFrame.Position
	local ranked: { { marker: Marker, distance: number } } = {}
	for other, marker in markers do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		marker.highlight.Enabled = false
		marker.tag.Enabled = esp.on and root ~= nil
		if esp.on and root then
			local distance = (root.Position - here).Magnitude
			local friend = player.Team ~= nil and other.Team == player.Team
			local colour = if friend then COLOURS.friend else COLOURS.enemy
			marker.highlight.Adornee = character
			marker.highlight.FillColor = colour
			marker.highlight.OutlineColor = colour
			marker.highlight.FillTransparency = if friend then 1 else ENEMY_FILL
			marker.tag.Adornee = root
			marker.label.Text = `{other.DisplayName}  {math.floor(distance)} studs`
			table.insert(ranked, { marker = marker, distance = distance })
		end
	end
	table.sort(ranked, function(a, b)
		return a.distance < b.distance
	end)
	for index = 1, math.min(#ranked, HIGHLIGHT_LIMIT) do
		ranked[index].marker.highlight.Enabled = true
	end
end

function esp.set(on: boolean)
	esp.on = on
	refresh()
end

function esp.unload()
	esp.alive = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for other in markers do
		untrack(other)
	end
	if features.Esp == esp then
		features.Esp = nil
	end
end

for _, other in Players:GetPlayers() do
	track(other)
end
table.insert(connections, Players.PlayerAdded:Connect(track))
table.insert(connections, Players.PlayerRemoving:Connect(untrack))

-- A quarter-second refresh is plenty for labels and costs a fraction of a
-- per-frame loop over every player.
table.insert(
	connections,
	RunService.Heartbeat:Connect(function(deltaTime)
		sinceRefresh += deltaTime
		if sinceRefresh >= REFRESH_SECONDS then
			sinceRefresh = 0
			refresh()
		end
	end)
)

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == TOGGLE_KEY then
			esp.set(not esp.on)
		end
	end)
)

features.Esp = esp
esp.set(true)
