# Commands, channels and tags

From Roblox's in-experience text chat guide and the TextChatService
reference; API names checked against the dump.

## An admin command

In Studio: add a `TextChatCommand` under `TextChatService`, name it
`KickCommand`, set `PrimaryAlias` to `/kick`. Then a server Script:

```lua
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ADMINS = { [1234567] = true }

local kick = TextChatService:WaitForChild("KickCommand") :: TextChatCommand

kick.Triggered:Connect(function(textSource: TextSource, text: string)
	local sender = Players:GetPlayerByUserId(textSource.UserId)
	if not sender or not ADMINS[sender.UserId] then
		return
	end
	local targetName = string.match(text, "^%S+%s+(%S+)")
	local target = targetName and Players:FindFirstChild(targetName)
	if target and target:IsA("Player") then
		target:Kick("Removed by an admin")
	end
end)
```

The admin list lives on the server. `AutocompleteVisible = false` keeps an
admin command out of the autocomplete menu for everyone; it still works when
typed in full. For bans that persist, use `Players:BanAsync` (see
`roblox-game-security/references/admin-commands.md`).

## A team channel

Create channels on the server, parented to `TextChatService`, and add each
player with `AddUserAsync` (it yields; call it from `PlayerAdded`). A channel
per team:

```lua
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local channel = Instance.new("TextChannel")
channel.Name = "RedTeam"
channel.Parent = TextChatService

local function join(player: Player)
	if player.Team and player.Team.Name == "Red" then
		channel:AddUserAsync(player.UserId)
	end
end
```

To limit who *receives* a message in an existing channel instead (proximity
chat, muted players), set `ShouldDeliverCallback` on the server. It runs for
every recipient's `TextSource` and returns whether that one gets the message.
It must not yield.

## Tags on messages

On the client, `TextChatService.OnIncomingMessage` returns a
`TextChatMessageProperties` with a new `PrefixText`. Read a value the server
set when the player joined; do not look anything up here, because the
callback must not yield.

```lua
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local source = message.TextSource
	local player = source and Players:GetPlayerByUserId(source.UserId)
	if player and player:GetAttribute("IsVIP") then
		local properties = Instance.new("TextChatMessageProperties")
		properties.PrefixText = `<font color="#D69E3E">[VIP]</font> {message.PrefixText}`
		return properties
	end
	return nil
end
```

`PrefixText` accepts rich text, which is how the tag gets its own colour.

## System messages and NPC bubbles

- A notice in one player's chat window: on that client,
  `TextChatService.TextChannels.RBXSystem:DisplaySystemMessage("Round starts in 10 seconds")`.
  `RBXSystem` exists when `CreateDefaultTextChannels` is on (the default).
- A bubble over an NPC: on the client, `TextChatService:DisplayBubble(npcHead, "Welcome!")`.

Neither goes through filtering, so neither may contain text a player typed.
