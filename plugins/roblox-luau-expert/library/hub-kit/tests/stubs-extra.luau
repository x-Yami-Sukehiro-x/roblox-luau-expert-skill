-- ====== HubKit additions to library/tests/stubs.luau ======
-- The shared stubs model signals and property writes for the style recipes.
-- HubKit also needs values that behave like the engine's: a Color3 with HSV
-- and hex, KeyCodes with a Name, typeof that says "Instance", JSON, and
-- ContextActionService priority bindings a test can press.

local nativeTypeof = typeof
function typeof(value)
	local meta = getmetatable(value)
	if type(meta) == "table" and meta.__type then
		return meta.__type
	end
	return nativeTypeof(value)
end

local baseNew = Instance.new
Instance.new = function(className)
	local instance = baseNew(className)
	getmetatable(instance).__type = "Instance"
	if className == "ScreenGui" then
		instance.AbsoluteSize = { X = 1280, Y = 720 }
	end
	return instance
end

local colourMeta = { __type = "Color3" }
colourMeta.__index = colourMeta
colourMeta.__eq = function(a, b)
	return math.abs(a.R - b.R) < 1e-6 and math.abs(a.G - b.G) < 1e-6 and math.abs(a.B - b.B) < 1e-6
end
local function rgb(r, g, b)
	return setmetatable({ R = r, G = g, B = b }, colourMeta)
end
function colourMeta.Lerp(a, b, t)
	return rgb(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
function colourMeta.ToHSV(c)
	local maximum, minimum = math.max(c.R, c.G, c.B), math.min(c.R, c.G, c.B)
	local delta = maximum - minimum
	local hue = 0
	if delta > 0 then
		if maximum == c.R then
			hue = ((c.G - c.B) / delta) % 6
		elseif maximum == c.G then
			hue = (c.B - c.R) / delta + 2
		else
			hue = (c.R - c.G) / delta + 4
		end
		hue /= 6
	end
	return hue, if maximum == 0 then 0 else delta / maximum, maximum
end
function colourMeta.ToHex(c)
	return string.format("%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end
Color3 = {
	new = function(r, g, b)
		return rgb(r or 0, g or 0, b or 0)
	end,
	fromRGB = function(r, g, b)
		return rgb((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
	end,
	fromHSV = function(h, s, v)
		local sector = math.floor(h * 6) % 6
		local f = h * 6 - math.floor(h * 6)
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local rows = { { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } }
		local row = rows[sector + 1]
		return rgb(row[1], row[2], row[3])
	end,
	fromHex = function(hex)
		local code = string.gsub(hex, "#", "")
		assert(#code == 6, "harness fromHex expects six digits")
		return rgb(
			tonumber(string.sub(code, 1, 2), 16) / 255,
			tonumber(string.sub(code, 3, 4), 16) / 255,
			tonumber(string.sub(code, 5, 6), 16) / 255
		)
	end,
}

local function enumItems(enumName, names)
	local enum = {}
	local items = {}
	local meta = { __type = "EnumItem" }
	meta.__tostring = function(item)
		return `Enum.{enumName}.{item.Name}`
	end
	for value, name in names do
		local item = setmetatable({ Name = name, Value = value, EnumType = enumName }, meta)
		enum[name] = item
		table.insert(items, item)
	end
	enum.GetEnumItems = function()
		return table.clone(items)
	end
	return enum
end
Enum.KeyCode = enumItems("KeyCode", {
	"Unknown", "Escape", "Backspace", "Return", "RightShift", "LeftShift", "RightControl",
	"F", "G", "H", "E", "Q", "V", "X", "Z", "P", "Space", "Left", "Right", "Up", "Down",
	"DPadLeft", "DPadRight", "ButtonA", "ButtonB",
})
Enum.ContextActionPriority = { High = { Value = 3000 }, Default = { Value = 2000 } }
Enum.Font.BuilderSans = "Font.BuilderSans"
Enum.Font.BuilderSansMedium = "Font.BuilderSansMedium"
Enum.Font.BuilderSansBold = "Font.BuilderSansBold"
Enum.UserInputType.Gamepad1 = "UserInputType.Gamepad1"

-- Enough JSON for flat configs: strings, numbers, booleans, arrays, objects.
local function encode(value)
	local kind = type(value)
	if kind == "string" then
		return '"' .. string.gsub(value, '[%c"\\]', function(char)
			return string.format("\\u%04x", string.byte(char))
		end) .. '"'
	elseif kind == "number" or kind == "boolean" then
		return tostring(value)
	elseif kind == "table" then
		if #value > 0 or next(value) == nil then
			local parts = {}
			for _, item in value do
				table.insert(parts, encode(item))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local keys = {}
		for key in value do
			table.insert(keys, key)
		end
		table.sort(keys)
		local parts = {}
		for _, key in keys do
			table.insert(parts, encode(key) .. ":" .. encode(value[key]))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	error("harness JSON cannot encode " .. kind)
end

local function decode(text)
	local position = 1
	local function skip()
		position = string.find(text, "[^%s]", position) or #text + 1
	end
	local parse
	function parse()
		skip()
		local char = string.sub(text, position, position)
		if char == "{" then
			local result = {}
			position += 1
			skip()
			if string.sub(text, position, position) == "}" then
				position += 1
				return result
			end
			while true do
				local key = parse()
				skip()
				assert(string.sub(text, position, position) == ":", "harness JSON expected a colon")
				position += 1
				result[key] = parse()
				skip()
				local separator = string.sub(text, position, position)
				position += 1
				if separator == "}" then
					return result
				end
				assert(separator == ",", "harness JSON expected a comma")
			end
		elseif char == "[" then
			local result = {}
			position += 1
			skip()
			if string.sub(text, position, position) == "]" then
				position += 1
				return result
			end
			while true do
				table.insert(result, parse())
				skip()
				local separator = string.sub(text, position, position)
				position += 1
				if separator == "]" then
					return result
				end
				assert(separator == ",", "harness JSON expected a comma")
			end
		elseif char == '"' then
			local finish = string.find(text, '"', position + 1, true)
			local raw = string.sub(text, position + 1, finish - 1)
			position = finish + 1
			return (string.gsub(raw, "\\u(%x%x%x%x)", function(code)
				return string.char(tonumber(code, 16))
			end))
		elseif string.sub(text, position, position + 3) == "true" then
			position += 4
			return true
		elseif string.sub(text, position, position + 4) == "false" then
			position += 5
			return false
		end
		local number = string.match(text, "^-?[%d%.eE+-]+", position)
		assert(number, "harness JSON cannot read " .. string.sub(text, position, position + 10))
		position += #number
		return tonumber(number)
	end
	return parse()
end

local services = HARNESS.services
services.HttpService = {
	JSONEncode = function(_, value)
		return encode(value)
	end,
	JSONDecode = function(_, text)
		return decode(text)
	end,
}

local bound = {}
services.ContextActionService.BindActionAtPriority = function(_, name, callback, _, priority, ...)
	bound[name] = { callback = callback, priority = priority, keys = { ... } }
end
services.ContextActionService.UnbindAction = function(_, name)
	bound[name] = nil
end
HARNESS.bound = bound

services.UserInputService.KeyboardEnabled = true
services.UserInputService.lastInput = Enum.UserInputType.MouseButton1
services.UserInputService.GetLastInputType = function(self)
	return self.lastInput
end
services.GuiService.SelectedObject = nil

-- Record what task.delay was asked to wait, so hold times can be asserted.
HARNESS.delays = {}
local baseDelay = task.delay
task.delay = function(seconds, callback, ...)
	table.insert(HARNESS.delays, seconds)
	return baseDelay(seconds, callback, ...)
end
