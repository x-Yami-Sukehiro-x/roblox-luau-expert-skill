--[[
	HubKit - a UI library for script hubs: windows with tabs, sections,
	nine element types, notifications, dialogs, themes and saved configs.

	    local HubKit = loadstring(game:HttpGet(HUBKIT_URL))()
	    local Window = HubKit:CreateWindow({ Title = "My Hub", Icon = "sparkles" })
	    local Main = Window:Tab({ Title = "Main", Icon = "home" })
	    Main:Toggle({ Title = "Fly", Flag = "Fly", Callback = setFly })
	    Window:SettingsTab()

	The folder layout, the element contract and how to add an element are in
	library/hub-kit/README.md. dist/HubKit.luau is this folder bundled into one
	file by tools/bin/build-hub-kit.mjs; edit these sources, never the bundle.
--]]

local Icons = require(script.Core.Icons)
local Theme = require(script.Core.Theme)
local Config = require(script.Core.Config)
local Elements = require(script.Elements)
local Notifications = require(script.Components.Notifications)
local Window = require(script.Components.Window)

for _, palette in require(script.Themes) do
	Theme.register(palette)
end

local kit = { windows = {}, capturing = false, popup = nil, toasts = nil }
function kit.notify(notice: { [string]: any })
	return Notifications.push(kit, notice)
end

local HubKit = {
	Version = "1.0.0",
	CanSaveConfigs = Config.available,
}

function HubKit:CreateWindow(options: { [string]: any })
	local window = Window.new(kit, options)
	table.insert(kit.windows, window)
	return window
end

function HubKit:Notify(notice: { [string]: any })
	return kit.notify(notice)
end

function HubKit:SetTheme(name: string)
	Theme.set(name)
end

function HubKit:AddTheme(palette: { [string]: any })
	Theme.register(palette)
end

function HubKit:GetThemes(): { string }
	return Theme.list()
end

function HubKit:GetIcons(): { string }
	return Icons.names()
end

function HubKit:GetElements(): { string }
	return Elements.names()
end

function HubKit:Unload()
	for _, window in table.clone(kit.windows) do
		window:Unload()
	end
	Notifications.clear(kit)
end

return HubKit
