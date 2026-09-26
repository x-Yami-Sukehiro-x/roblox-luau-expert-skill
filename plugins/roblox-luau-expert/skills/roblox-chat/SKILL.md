---
name: roblox-chat
description: Roblox chat - TextChatService commands, channels, tags, and filtering every player-typed string. Use for chat commands, pet names.
---

# Chat and player text

Two jobs share this skill because they share one rule: **text a player
typed is shown to anyone else only after Roblox has filtered it.** Chat
messages sent through TextChatService are filtered for you. Everything else
(a pet's name, a sign, a clan tag, a bulletin board, text loaded from a
DataStore) is yours to filter, and Roblox removes experiences that do not.

## TextChatService in one picture

A player's message goes: sending client (`TextChannel:SendAsync`), then the
server (`TextChannel.ShouldDeliverCallback` decides who gets it, filtering is
applied), then every receiving client (`TextChatService.OnIncomingMessage`,
then `TextChatService.MessageReceived`). Where each hook runs matters:

| Hook | Define it on | Use it for |
|---|---|---|
| `TextChatCommand.Triggered` | server | slash commands; check who sent it |
| `TextChannel.ShouldDeliverCallback` | server | team chat, proximity chat, muting |
| `TextChatService.OnIncomingMessage` | client | tags and colours on messages |
| `TextChannel:DisplaySystemMessage` | client | local notices in the chat window |
| `TextChatService:DisplayBubble` | client | a bubble over an NPC |

Callbacks must not yield. Anything slow (group rank, a DataStore) is looked
up when the player joins and stored as an attribute the callback reads.

## Commands

A `TextChatCommand` parented to `TextChatService`, with `PrimaryAlias`
(`/give`) and optionally `SecondaryAlias`, fires `Triggered` with the
sender's `TextSource` and the unfiltered text. Handle it in a server Script,
resolve the player with `Players:GetPlayerByUserId(textSource.UserId)`, and
check that player's permission **on the server** before doing anything. The
built-in commands (`/mute`, emotes) are a Studio setting on
`TextChatService.CreateDefaultCommands`, not something a script turns on.

[commands-and-channels.md](references/commands-and-channels.md) has an admin
command, a team channel and chat tags.

## Filtering player text

On the server, after the player submits (never per keystroke):

```lua
local TextService = game:GetService("TextService")

local function filterForEveryone(text: string, author: Player): string?
	local ok, result = pcall(TextService.FilterStringAsync, TextService, text, author.UserId)
	if not ok then
		return nil
	end
	local shown
	ok, shown = pcall(result.GetNonChatStringForBroadcastAsync, result)
	return if ok then shown else nil
end
```

- **Broadcast** (a sign, a pet name everyone sees):
  `GetNonChatStringForBroadcastAsync`.
- **One viewer** (a private note): `GetNonChatStringForUserAsync(viewerId)`.
- **Failure shows nothing.** If filtering errors, show a placeholder or
  keep the old text, never the unfiltered string.
- **Filter again when loading.** A name saved last month is filtered when
  it is shown today, because filters change.
- **Rate-limit** text inputs that other players see, on the server.

[filtering.md](references/filtering.md) has the full flow: TextBox,
remote, validation, filter, display.

## Common mistakes

- Showing a player's typed text in a BillboardGui straight from the
  TextBox, even "just for testing".
- Filtering on the client (it cannot) or trusting a client that says the
  text is filtered.
- Yielding inside `OnIncomingMessage` (the chat window stalls).
- Two TextChannels with the same name, which confuses the default window.
- Using the old `Chat` service's methods for new work.

## Works with

- `roblox-networking`: the remote that carries typed text to the server.
- `roblox-game-security`: validating and rate-limiting that remote.
- `roblox-ui`: text inputs, chat-adjacent UI and localization of the words.
- `roblox-monetization`: PolicyService, and what may be shown to whom.
- `roblox-data-persistence`: saving names and messages, filtered again on load.
- `roblox-engine-api`: the services and signals chat code uses.
