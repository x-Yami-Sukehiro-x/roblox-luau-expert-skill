# A hub rewritten under budget

A measured example of the most common way a generated executor script runs
out of locals: a Rayfield-style hub with eight tabs of twelve toggles, forty
settings, thirty remotes and twelve feature loops, all declared at the top
level. Both files were compiled with the bundled Luau 0.739 compiler through
`node tools/bin/check-registers.mjs`.

## Before: 224 lines, 199 top-level locals

```lua
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({ Name = "Pet Sim Hub" })
local MainTab = Window:CreateTab("Main")
local MainSection = MainTab:CreateSection("Main")
-- ... seven more tabs and sections
local SETTING_0 = 0
local SETTING_1 = 5
-- ... 38 more
local Remote0 = ReplicatedStorage.Remotes:WaitForChild("Remote0")
-- ... 29 more
local MainToggle0 = MainTab:CreateToggle({ Name = "Main 0", CurrentValue = false, Callback = ... })
-- ... 95 more toggles, each kept in a local nothing reads
local function autoFarmLoop()
	print("Auto Farm", SETTING_1, Remote1)
end
-- ... 11 more
```

What the checker printed:

```
224: W-REGISTERS main chunk peaks at 206 of 255 registers (locals stop at 200); move locals into tables or functions now
1: I-LOCALS the main chunk declares 199 top-level locals: 113 library elements, 103 never used again (drop `local name =` from the unused ones), 40 literal settings (put them in one CONFIG table), 30 child lookups (put them in one table named for what they are, such as remotes), 12 local functions (make them fields of one table), 3 services, 1 other
```

It compiles, and it is finished: two more toggles give

```
225: E-COMPILE CompileError: Out of local registers when trying to allocate AnotherToggle: exceeded limit 200
```

## After: 116 lines, 9 top-level locals

Same tabs, same toggles, same settings, remotes and features:

```lua
local CONFIG = {
	setting0 = 0,
	setting1 = 5,
	-- ... 38 more
}

local remotes = {}
for index = 0, 29 do
	remotes[index] = ReplicatedStorage.Remotes:WaitForChild(`Remote{index}`)
end

local Features = {}
function Features.autoFarm()
	print("Auto Farm", CONFIG.setting1, remotes[1])
end
-- ... 11 more

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({ Name = "Pet Sim Hub" })

local function buildTab(name: string)
	local tab = Window:CreateTab(name)
	tab:CreateSection(name)
	for index = 0, 11 do
		tab:CreateToggle({
			Name = `{name} {index}`,
			CurrentValue = false,
			Callback = function(on)
				print(name, index, on)
			end,
		})
	end
end

buildTab("Main")
-- ... seven more
```

```
hub-after.luau  ok; highest: main chunk at 16/255
```

## What moved, in the order the checker ranked it

| Family | Before | After | Move |
|---|---|---|---|
| Library elements | 113 locals, 103 never read | 2 (`Rayfield`, `Window`) | Toggle returns dropped; tabs built inside `buildTab` |
| Literal settings | 40 locals | 1 (`CONFIG`) | Fields, names kept apart from the prefix |
| Child lookups | 30 locals | 1 (`remotes`) | One table filled in a loop |
| Local functions | 12 locals | 1 (`Features`) | `function Features.autoFarm()` |
| Services | 3 | 3 | Unchanged |

The rewrite is a rename plus two builder functions. Nothing about what the
hub does changed, which is what a register fix should look like in a diff.

A real hub's toggles are not identical, so the loop in `buildTab` becomes one
builder per tab (`buildFarmTab`, `buildPlayerTab`), each with its own locals.
The principle holds: the main chunk names families, and each builder's locals
die when it returns.
