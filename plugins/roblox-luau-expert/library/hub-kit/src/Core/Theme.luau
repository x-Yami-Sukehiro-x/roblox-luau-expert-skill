--[[
	Theme - one palette at a time, addressed by role.

	Static colours are bound with `bind`, which remembers the instance and the
	role, so `set` recolours everything already on screen. Colours that depend
	on state (hover, on, disabled) are read with `get` inside a render function
	that also listens to `changed`, so a theme switch never strands a hovered
	row in the old palette.

	Every palette must define every role in ROLES. A missing one is an error at
	registration rather than a nil colour discovered on some later hover.
--]]

local Signal = require(script.Parent.Signal)

local ROLES = {
	"background",
	"surface",
	"raised",
	"hover",
	"stroke",
	"text",
	"textMuted",
	"accent",
	"accentHover",
	"onAccent",
	"focus",
	"success",
	"warning",
	"danger",
	"info",
}

local Theme = {}
Theme.ROLES = ROLES
Theme.changed = Signal.new()

local palettes = {}
local names = {}
local current

-- Strong keys released on Destroying. A weak-keyed table of Instances loses
-- entries whenever Luau collects the reference while the instance is alive.
local bindings = {}

function Theme.register(palette: { [string]: any })
	local name = palette.name
	assert(type(name) == "string", "a theme needs a name")
	for _, role in ROLES do
		if palette[role] == nil then
			error(`theme {name} has no {role} colour`, 2)
		end
	end
	if not palettes[name] then
		table.insert(names, name)
	end
	palettes[name] = palette
	current = current or palette
end

function Theme.set(name: string)
	local palette = palettes[name]
	if not palette then
		error(`no theme named {name}`, 2)
	end
	current = palette
	for instance, roles in bindings do
		for property, role in roles do
			instance[property] = palette[role]
		end
	end
	Theme.changed:Fire(name)
end

function Theme.get(role: string): Color3
	local colour = current[role]
	if colour == nil then
		error(`unknown theme role {role}`, 2)
	end
	return colour
end

function Theme.bind(instance: Instance, property: string, role: string)
	local roles = bindings[instance]
	if not roles then
		roles = {}
		bindings[instance] = roles
		instance.Destroying:Once(function()
			bindings[instance] = nil
		end)
	end
	roles[property] = role
	instance[property] = Theme.get(role)
end

function Theme.current(): string
	return current.name
end

function Theme.list(): { string }
	return table.clone(names)
end

return Theme
