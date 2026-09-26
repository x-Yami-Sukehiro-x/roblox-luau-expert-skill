-- lint: complete
-- Logs the game's own FireServer and InvokeServer calls for WATCH_SECONDS, then prints
-- them. The hook forwards every call unchanged and stays installed as a pass-through
-- after the window; a rerun reuses it rather than stacking a second one.
local WATCH_SECONDS = 20
local RECORD_LIMIT = 50
local FIELD_LIMIT = 8
local TEXT_LIMIT = 80
-- A remote's Name, such as "Collect", to log only that one; nil logs every remote.
local ONLY_NAME: string? = nil

local hookmetamethod, getnamecallmethod, checkcaller, newcclosure, getgenv =
	hookmetamethod, getnamecallmethod, checkcaller, newcclosure, getgenv
assert(
	hookmetamethod and getnamecallmethod and checkcaller and newcclosure and getgenv,
	"needs hookmetamethod, getnamecallmethod, checkcaller, newcclosure, getgenv"
)

type Call = {
	remote: Instance,
	method: string,
	arguments: { n: number, [number]: any },
	at: number,
}

local env = getgenv()
local spy = env.RemoteSpy
if spy == nil then
	spy = {}
	env.RemoteSpy = spy
	local original
	original = hookmetamethod(
		game,
		"__namecall",
		newcclosure(function(self, ...)
			local method = getnamecallmethod()
			local record = spy.record
			local outgoing = method == "FireServer" or method == "InvokeServer"
			if record and outgoing and not checkcaller() then
				record(self, method, table.pack(...))
			end
			return original(self, ...)
		end)
	)
end

if spy.finish then
	spy.finish()
end

-- Tables are read with next, never generalised iteration, so a game table's
-- __iter or __index cannot run from inside the report.
local function describe(value: any): string
	local kind = typeof(value)
	if kind == "string" then
		return string.format("%q", string.sub(value, 1, TEXT_LIMIT))
	elseif kind == "number" or kind == "boolean" or kind == "nil" then
		return tostring(value)
	elseif kind == "Instance" then
		return `{value.ClassName} {value:GetFullName()}`
	elseif kind == "table" then
		local fields = {}
		local key, field = next(value)
		while key ~= nil and #fields < FIELD_LIMIT do
			table.insert(fields, `{tostring(key)}: {typeof(field)}`)
			key, field = next(value, key)
		end
		local more = if key ~= nil then ", ..." else ""
		return `\{{table.concat(fields, ", ")}{more}\}`
	end
	return `{kind} {tostring(value)}`
end

local calls: { Call } = {}
local dropped = 0
local started = os.clock()

function spy.record(remote: Instance, method: string, arguments: { n: number, [number]: any })
	if ONLY_NAME ~= nil and remote.Name ~= ONLY_NAME then
		return
	end
	if #calls >= RECORD_LIMIT then
		dropped += 1
		return
	end
	table.insert(calls, {
		remote = remote,
		method = method,
		arguments = arguments,
		at = os.clock(),
	})
end

local function finish()
	spy.record = nil
	spy.finish = nil
	local seconds = math.floor(os.clock() - started)
	local limit = `{dropped} past the {RECORD_LIMIT} limit`
	print(`remote spy: {#calls} call(s) in {seconds} s, {limit}`)
	for _, call in calls do
		local described = {}
		for index = 1, call.arguments.n do
			table.insert(described, describe(call.arguments[index]))
		end
		local offset = string.format("+%.2fs", call.at - started)
		local arguments = table.concat(described, ", ")
		print(`  {offset}  {call.method}  {call.remote:GetFullName()}  ({arguments})`)
	end
end

-- A rerun has already finished this window, so its timer must not report twice.
spy.finish = finish
task.delay(WATCH_SECONDS, function()
	if spy.finish == finish then
		finish()
	end
end)
