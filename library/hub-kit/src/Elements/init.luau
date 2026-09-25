--[[
	Elements - the registry that gives every container (a Tab or a Section)
	one method per element: Tab:Toggle({...}), Section:Slider({...}).

	Adding an element is one file in this folder with a `new(container,
	options)` function and one line in REGISTRY. The wrapper below does what
	every element needs and none should repeat: register its Flag with the
	window's config and `Flags` table, make it searchable, and undo both when
	the element is destroyed.

	A handle is the row from Row.luau plus the element's Get and Set, so the
	contract is the same everywhere: Get, Set, Changed, SetTitle,
	SetDescription, SetDisabled, Destroy, Frame.
--]]

local REGISTRY = {
	Button = require(script.Button),
	ColorPicker = require(script.ColorPicker),
	Divider = require(script.Divider),
	Dropdown = require(script.Dropdown),
	Input = require(script.Input),
	Keybind = require(script.Keybind),
	Paragraph = require(script.Paragraph),
	Slider = require(script.Slider),
	Toggle = require(script.Toggle),
}

local Elements = {}

local function create(container: any, name: string, options: { [string]: any })
	local window = container.window
	local flag = options.Flag
	-- Checked before anything is built, so a rejected element leaves no row.
	if flag ~= nil and window.Flags[flag] ~= nil then
		error(`flag {flag} is already used`, 3)
	end

	local element = REGISTRY[name].new(container, options)
	if flag ~= nil then
		assert(element.Get, `{name} has no value to save under a Flag`)
		window.config:register(flag, element)
		window.Flags[flag] = element
		element.trove:add(function()
			window.config:unregister(flag)
			window.Flags[flag] = nil
		end)
	end

	if element.searchText then
		local entry = {
			frame = element.Frame,
			text = string.lower(element.searchText),
			section = container.section,
		}
		table.insert(container.entries, entry)
		element.trove:add(function()
			local index = table.find(container.entries, entry)
			if index then
				table.remove(container.entries, index)
			end
		end)
		window:applySearch()
	end
	return element
end

function Elements.install(container: any)
	for name in REGISTRY do
		container[name] = function(_, options: { [string]: any }?)
			return create(container, name, options or {})
		end
	end
end

function Elements.names(): { string }
	local list = {}
	for name in REGISTRY do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

return Elements
