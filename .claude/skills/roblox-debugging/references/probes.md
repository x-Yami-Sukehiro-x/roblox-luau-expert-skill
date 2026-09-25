# Probes

A probe answers one question and is removed after. Each shape below is
small enough to paste in one place and read in one line of output.

## The value, where it is used

```lua
print("[shop] buy", itemId, "price", price, "coins", player:GetAttribute("Coins"))
```

Print the values the decision depends on, labelled, at the line that
decides. A bare `print("here")` proves the line ran and nothing else.

## The assumption, where it is made

```lua
assert(character.Parent ~= nil, "character left the world before the teleport")
```

An `assert` stops at the first wrong assumption with a message naming it,
instead of three lines later with a nil error about something else.

## Who writes this property

```lua
local humanoid = character:WaitForChild("Humanoid")
local watch = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	print("WalkSpeed ->", humanoid.WalkSpeed, debug.traceback("", 2))
end)
task.delay(10, function()
	watch:Disconnect()
end)
```

The traceback names the script that wrote it. Disconnect after the question
is answered.

## What arrives at the server

```lua
remote.OnServerEvent:Connect(function(player, ...)
	print("[remote]", remote.Name, player.Name, select("#", ...), ...)
end)
```

`select("#", ...)` counts arguments, including trailing nils that `print`
does not show.

## How long it takes

```lua
local started = os.clock()
rebuildLeaderboard()
print(string.format("[timing] leaderboard %.2f ms", (os.clock() - started) * 1000))
```

For anything per frame, use the MicroProfiler with
`debug.profilebegin("Leaderboard")` and `debug.profileend()` instead; a
print every frame changes the timing it measures.

## What is under the pointer

```lua
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local point = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
for _, object in playerGui:GetGuiObjectsAtPosition(point.X, point.Y) do
	print(object:GetFullName(), object.Active, object.ZIndex)
end
```

`GetMouseLocation` counts from the top of the screen, while
`GetGuiObjectsAtPosition` counts from below the GUI inset, so the inset is
subtracted first. The first objects printed are the ones on top.

## Collecting logs in code

```lua
local LogService = game:GetService("LogService")
local lines = {}
local listener = LogService.MessageOut:Connect(function(message, kind)
	table.insert(lines, `{kind.Name}: {message}`)
end)
```

For a debug panel, or for reading errors back in an automated test.
Disconnect it with the panel.
