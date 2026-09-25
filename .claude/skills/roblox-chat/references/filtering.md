# Filtering player text, end to end

Roblox filters chat that goes through TextChatService. Every other string a
player typed and another player can see is the experience's to filter, and
Roblox's text filtering page is explicit that experiences which skip it are
removed until they add it.

## What needs filtering

- Names players give things: pets, plots, houses, clans, guilds.
- Signs, notes, bulletin boards, custom chat bubbles.
- Text stored and shown later (loaded from a DataStore).
- Text from outside the game (an HTTP response shown in game).
- Words the game generates from random characters.

## The flow

1. **Client**: a TextBox; on `FocusLost` with Enter, send the text through a
   RemoteEvent. Never filter as the player types.
2. **Server, validate**: a string, not empty, under a length cap, the player
   allowed to name this thing, and not faster than the rate limit.
3. **Server, filter**: `TextService:FilterStringAsync(text, player.UserId)`,
   then `GetNonChatStringForBroadcastAsync()` for text everyone sees. Both
   yield and both can fail; wrap each in `pcall`.
4. **Server, re-check after the yields**: the player may have left, the pet
   may be gone.
5. **Show the filtered string**, never the original. Store the original if
   the design needs it, and filter again each time it is shown.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local NamePet = ReplicatedStorage.Remotes.NamePet
local MAX_LENGTH = 20
local COOLDOWN = 10

local lastRename: { [Player]: number } = {}

NamePet.OnServerEvent:Connect(function(player: Player, petId: unknown, name: unknown)
	if type(petId) ~= "string" or type(name) ~= "string" or #name == 0 or #name > MAX_LENGTH then
		return
	end
	local now = os.clock()
	if now - (lastRename[player] or 0) < COOLDOWN then
		return
	end
	lastRename[player] = now

	local ok, result = pcall(TextService.FilterStringAsync, TextService, name, player.UserId)
	if not ok then
		return
	end
	local shown
	ok, shown = pcall(result.GetNonChatStringForBroadcastAsync, result)
	if not ok or player.Parent == nil then
		return
	end
	local pet = workspace.Pets:FindFirstChild(petId)
	if pet and pet:GetAttribute("OwnerId") == player.UserId then
		pet:SetAttribute("DisplayName", shown)
	end
end)
```

Clear `lastRename[player]` on `PlayerRemoving`.

## Choosing the method

| Who sees it | Method |
|---|---|
| Everyone in the server | `TextFilterResult:GetNonChatStringForBroadcastAsync()` |
| One specific player | `TextFilterResult:GetNonChatStringForUserAsync(viewerUserId)` |
| Chat messages | nothing: TextChatService filters them |

`GetChatForUserAsync` is deprecated; use the non-chat methods for text that
is not a chat message.
