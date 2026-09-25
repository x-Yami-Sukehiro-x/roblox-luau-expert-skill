-- Every HubKit element in one hub. Executor: run this file as it is. Studio: a ModuleScript
-- named HubKit in ReplicatedStorage holding dist/HubKit.luau, this in StarterPlayerScripts.
-- Its effects are your own walk speed, field of view and a highlight, all undone on unload.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local KIT_URL = "https://raw.githubusercontent.com/x-Yami-Sukehiro-x/roblox-luau-expert-skill/"
	.. "main/library/hub-kit/dist/HubKit.luau"

local installed = ReplicatedStorage:FindFirstChild("HubKit")
local HubKit = if installed then require(installed) else loadstring(game:HttpGet(KIT_URL))()

-- A rerun replaces the running demo instead of stacking a second one on it.
local session = if typeof(getgenv) == "function" then getgenv() else _G
if session.HubKitDemo then
	session.HubKitDemo:Unload()
end

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local startingFov = camera.FieldOfView
local walkSpeed = 16
local glow = Instance.new("Highlight")
glow.Enabled = false

local Window = HubKit:CreateWindow({
	Title = "HubKit Demo",
	Subtitle = `v{HubKit.Version}`,
	Icon = "sparkles",
	Folder = "HubKitDemo",
})
session.HubKitDemo = Window

local function applySpeed(character: Model?)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = walkSpeed
	end
end

local respawned = player.CharacterAdded:Connect(function(character)
	applySpeed(character)
	glow.Adornee = character
end)

local Movement = Window:Tab({ Title = "Player", Icon = "user" })
Movement:Slider({
	Title = "Walk speed",
	Description = "Applied again after every respawn",
	Min = 8,
	Max = 64,
	Default = 16,
	Suffix = "studs/s",
	Flag = "WalkSpeed",
	Callback = function(speed: number)
		walkSpeed = speed
		applySpeed(player.Character)
	end,
})
Movement:Slider({
	Title = "Field of view",
	Min = 50,
	Max = 110,
	Default = math.round(startingFov),
	Flag = "FieldOfView",
	Callback = function(degrees: number)
		camera.FieldOfView = degrees
	end,
})

local Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
local outline = Visuals:Section({ Title = "Highlight my character" })
outline:Toggle({
	Title = "Highlight",
	Description = "Outlines your own character, visible through walls",
	Flag = "Highlight",
	Callback = function(on: boolean)
		glow.Adornee = player.Character
		glow.Parent = if on then Workspace else nil
		glow.Enabled = on
	end,
})
outline:ColorPicker({
	Title = "Outline colour",
	Default = Color3.fromRGB(72, 201, 162),
	Flag = "OutlineColour",
	Callback = function(colour: Color3)
		glow.OutlineColor = colour
		glow.FillColor = colour
	end,
})
outline:Dropdown({
	Title = "Draw",
	Values = { "Through walls", "Only when visible" },
	Default = "Through walls",
	Flag = "OutlineDepth",
	Callback = function(mode: string?)
		local depth = Enum.HighlightDepthMode
		glow.DepthMode = if mode == "Only when visible" then depth.Occluded else depth.AlwaysOnTop
	end,
})

local Showcase = Window:Tab({ Title = "Elements", Icon = "layout-list" })
local status = Showcase:Paragraph({
	Title = "Status",
	Content = "Change anything below and this line reports it.",
})
local function report(text: string)
	status:Set({ Content = text })
end

local buttons = Showcase:Section({ Title = "Buttons and notices" })
for _, kind in { "info", "success", "warning", "error" } do
	buttons:Button({
		Title = `Show a {kind} notice`,
		Callback = function()
			HubKit:Notify({
				Title = "HubKit",
				Content = `A {kind} notice with its own icon`,
				Kind = kind,
			})
		end,
	})
end
buttons:Button({
	Title = "Ask a question",
	Description = "Opens a dialog with a safe choice",
	Icon = "info",
	Callback = function()
		Window:Dialog({
			Title = "Reset the demo values?",
			Content = "Walk speed and field of view go back to where they started.",
			Buttons = {
				{
					Title = "Reset",
					Variant = "primary",
					Callback = function()
						Window.Flags.WalkSpeed:Set(16)
						Window.Flags.FieldOfView:Set(math.round(startingFov))
					end,
				},
				{ Title = "Keep", Cancel = true },
			},
		})
	end,
})

local inputs = Showcase:Section({ Title = "Inputs" })
inputs:Input({
	Title = "Nickname",
	Placeholder = "Type and press Enter",
	Callback = function(text: string)
		report(`Nickname is now "{text}"`)
	end,
})
inputs:Dropdown({
	Title = "Favourite features",
	Values = { "Fly", "Speed", "ESP", "Teleport", "Freecam" },
	Multi = true,
	Callback = function(picked: { string })
		report(`{#picked} picked: {table.concat(picked, ", ")}`)
	end,
})
inputs:Keybind({
	Title = "Wave key",
	Default = Enum.KeyCode.G,
	Callback = function()
		report("You pressed the wave key")
	end,
})
inputs:Divider()
inputs:Toggle({
	Title = "Grey out the status line",
	Description = "Shows what a disabled row looks like",
	Callback = function(on: boolean)
		status:SetDisabled(on)
	end,
})

Window:SettingsTab()

Window.OnUnload:Connect(function()
	respawned:Disconnect()
	walkSpeed = 16
	applySpeed(player.Character)
	camera.FieldOfView = startingFov
	glow:Destroy()
	if session.HubKitDemo == Window then
		session.HubKitDemo = nil
	end
end)

Window:LoadAutoload()
