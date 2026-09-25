--[[
	New(className, properties, parent) - one statement per instance.

	`Theme = { BackgroundColor3 = "surface" }` binds a property to a palette
	role instead of setting a colour, so a theme switch reaches it. Parent is
	assigned after every other property: an instance never appears on screen
	half-built, and nothing fires Changed for a value it is about to replace.
--]]

local Theme = require(script.Parent.Theme)

return function(className: string, properties: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for property, value in properties do
		if property == "Theme" then
			for themed, role in value do
				Theme.bind(instance, themed, role)
			end
		else
			instance[property] = value
		end
	end
	instance.Parent = parent
	return instance
end
