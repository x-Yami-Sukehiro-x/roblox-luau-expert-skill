--[[
	SettingsTab - the tab every hub needs and nobody wants to write: theme,
	menu key, saved configs and unload.

	    Window:SettingsTab()

	The theme and menu key carry the flags "HubKit.Theme" and "HubKit.MenuKey",
	so a saved config restores the look and the key along with the features.
	Without executor file access the Configs section says so in one line
	instead of offering buttons that cannot work.
--]]

local Config = require(script.Parent.Parent.Core.Config)
local Theme = require(script.Parent.Parent.Core.Theme)

local SettingsTab = {}

function SettingsTab.build(window: any, options: { [string]: any })
	local tab = window:Tab({ Title = options.Title or "Settings", Icon = "settings" })

	local look = tab:Section({ Title = "Appearance" })
	look:Dropdown({
		Title = "Theme",
		Values = Theme.list(),
		Default = Theme.current(),
		Flag = "HubKit.Theme",
		Callback = function(name: string?)
			if name then
				Theme.set(name)
			end
		end,
	})

	local controls = tab:Section({ Title = "Controls" })
	local menuKey = controls:Keybind({
		Title = "Menu key",
		Description = "Shows and hides this window",
		Default = window.toggleKey,
		Flag = "HubKit.MenuKey",
	})
	menuKey.trove:add(menuKey.Changed:Connect(function(key: Enum.KeyCode?)
		window:SetToggleKey(key)
	end))

	local saves = tab:Section({ Title = "Configs" })
	if not Config.available then
		saves:Paragraph({
			Title = "Saving is off",
			Content = "This executor has no file access, so settings last until you leave.",
		})
	else
		local function report(ok: boolean, message: string)
			window:Notify({
				Title = "Configs",
				Content = message,
				Kind = if ok then "success" else "error",
			})
		end

		local name = saves:Input({ Title = "Config name", Placeholder = "farming" })
		local saved = saves:Dropdown({
			Title = "Saved configs",
			Values = window.config:list(),
			AllowNone = true,
		})
		local function refresh()
			saved:Refresh(window.config:list())
		end

		saves:Button({
			Title = "Save",
			Description = "Saves every setting under the name above",
			Icon = "save",
			Callback = function()
				report(window.config:save(name:Get()))
				refresh()
			end,
		})
		saves:Button({
			Title = "Load",
			Description = "Loads the config picked above",
			Icon = "folder",
			Callback = function()
				local pick = saved:Get()
				if pick then
					report(window.config:load(pick))
				else
					report(false, "Pick a saved config first")
				end
			end,
		})
		saves:Button({
			Title = "Load on start",
			Description = "The picked config loads each time the hub starts",
			Icon = "star",
			Callback = function()
				report(window.config:setAutoload(saved:Get()))
			end,
		})
		saves:Button({
			Title = "Delete",
			Description = "Removes the picked config file",
			Icon = "trash-2",
			Callback = function()
				local pick = saved:Get()
				if not pick then
					report(false, "Pick a saved config first")
					return
				end
				window:Dialog({
					Title = `Delete {pick}?`,
					Content = "The file is removed from your executor's workspace folder.",
					Buttons = {
						{
							Title = "Delete",
							Variant = "danger",
							Callback = function()
								report(window.config:delete(pick))
								refresh()
							end,
						},
						{ Title = "Keep", Cancel = true },
					},
				})
			end,
		})
	end

	local session = tab:Section({ Title = "Session" })
	session:Button({
		Title = "Unload",
		Description = "Closes the hub and disconnects everything it started",
		Icon = "log-out",
		Callback = function()
			window:ConfirmUnload()
		end,
	})
	return tab
end

return SettingsTab
