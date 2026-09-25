--[[
	Icons - Lucide icons already uploaded to Roblox, by name.

	Every id here is copied from roblox-ui-components/references/icon-ids.txt,
	where each was confirmed as a real image, and verify-asset-ids.mjs checks
	them again in CI. A name that is not in the table is an error, never a
	blank ImageLabel. A full "rbxassetid://" string passes through, for icons
	a hub uploads itself.
--]]

local IDS = {
	["check"] = "rbxassetid://86817768619372",
	["chevron-down"] = "rbxassetid://71457658246709",
	["chevron-right"] = "rbxassetid://101007429951147",
	["circle-check"] = "rbxassetid://88244323237265",
	["eye"] = "rbxassetid://127234874352422",
	["folder"] = "rbxassetid://77937190465422",
	["home"] = "rbxassetid://109841253338329",
	["info"] = "rbxassetid://120620848266512",
	["keyboard"] = "rbxassetid://121978468376124",
	["layout-list"] = "rbxassetid://72384664085473",
	["log-out"] = "rbxassetid://140299936053191",
	["minus"] = "rbxassetid://95070996149109",
	["mouse-pointer-click"] = "rbxassetid://81854854241463",
	["octagon-alert"] = "rbxassetid://101226496664732",
	["palette"] = "rbxassetid://127369887384101",
	["pipette"] = "rbxassetid://104047428948587",
	["refresh-cw"] = "rbxassetid://106497040962250",
	["save"] = "rbxassetid://122894934359450",
	["search"] = "rbxassetid://72296609649861",
	["settings"] = "rbxassetid://106205298246017",
	["sliders-horizontal"] = "rbxassetid://125396339381135",
	["sparkles"] = "rbxassetid://105634041692696",
	["star"] = "rbxassetid://72669221096319",
	["swords"] = "rbxassetid://99199363807265",
	["trash-2"] = "rbxassetid://126010725826757",
	["triangle-alert"] = "rbxassetid://91165848022002",
	["user"] = "rbxassetid://114567720540659",
	["x"] = "rbxassetid://116396312853810",
	["zap"] = "rbxassetid://109718589733073",
}

local Icons = {}

function Icons.resolve(name: string): string
	if string.sub(name, 1, 13) == "rbxassetid://" then
		return name
	end
	local id = IDS[name]
	if not id then
		error(`no icon named {name}`, 2)
	end
	return id
end

function Icons.names(): { string }
	local list = {}
	for name in IDS do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

return Icons
