# Admin commands and bans without a backdoor

An admin system is a remote that does powerful things. Built carelessly it
is the backdoor an exploiter is looking for. Built this way it is not.

## Rules

1. **Who is an admin is decided on the server**, from a list the server
   holds (user ids, a group rank read once on join). Never from an
   attribute the client set, a GUI the client has, or an argument it sends.
2. **Every command re-checks** the caller's rank on the server, every time.
   Showing an admin panel only to admins is a convenience, not security.
3. **No command runs code.** A remote that takes a string and runs it
   (`loadstring`, `require` of an id the client chose) is a backdoor however
   well the caller is checked; it is also what audits of Toolbox models look
   for (`audit-imported-assets.md`).
4. **Targets and arguments are validated** like any remote: types, ranges,
   the target exists and is in the server.
5. **Every action is logged** with who, what, whom and when, on the server.

## Commands through chat

`roblox-chat/references/commands-and-channels.md` has a `/kick` built on
`TextChatCommand`: the server resolves the sender from `TextSource.UserId`
and checks the admin list before acting. That is the whole pattern; a panel
is the same with a RemoteEvent in place of the command.

## Bans that last

`Players:BanAsync` (server only) bans across the experience and survives
server restarts, which a table of banned ids in a script does not:

```lua
local Players = game:GetService("Players")

local function ban(moderator: Player, target: Player, days: number, reason: string)
	local ok, failure = pcall(Players.BanAsync, Players, {
		UserIds = { target.UserId },
		Duration = if days < 0 then -1 else math.floor(days * 86400),
		DisplayReason = reason,
		PrivateReason = `by {moderator.UserId}`,
		ExcludeAltAccounts = false,
		ApplyToUniverse = true,
	})
	if not ok then
		warn(`ban of {target.UserId} failed: {failure}`)
	end
end
```

From Roblox's reference for the method:

- It needs `Players.BanningEnabled`, a Studio setting.
- `Duration` is in seconds; `-1` is permanent.
- `DisplayReason` (shown to the banned user) is filtered and at most 400
  characters. `PrivateReason` is never sent to the client, up to 1000
  characters.
- Bans propagate to suspected alternate accounts unless
  `ExcludeAltAccounts` is true.
- It calls a web service, so it can fail and is throttled: `pcall`, and
  report the failure to the moderator.
- In Studio and team tests it runs but does not ban anyone in production.

`Players:UnbanAsync` reverses a ban, and `Players:GetBanHistoryAsync` returns
a user's past bans for choosing a longer one for repeat offences. The
Creator Hub's Bans page manages the same bans without code.

## Checklist

- [ ] Admin identity from a server-side list or a rank read on join.
- [ ] Every command handler checks the caller again.
- [ ] No remote executes strings or requires client-chosen ids.
- [ ] Arguments validated; targets must be players in the server.
- [ ] Actions logged on the server.
- [ ] Bans through `BanAsync`, wrapped in `pcall`.
