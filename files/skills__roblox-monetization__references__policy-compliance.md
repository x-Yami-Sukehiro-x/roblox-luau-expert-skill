# Policy checks for paid features

Some features are allowed for one player and not for another, by country,
age group and platform. `PolicyService:GetPolicyInfoForPlayerAsync(player)`
returns a table saying which, and Roblox's reference names the features that
must check it. Field names below are from that reference.

## Which fields gate what

| Field | Check it before |
|---|---|
| `ArePaidRandomItemsRestricted` | any paid random item: loot boxes, gacha, eggs bought with Robux or with currency bought with Robux. When true, the player must not be able to use them |
| `IsPaidItemTradingAllowed` | trading items bought with Robux or Robux-bought currency |
| `AreAdsAllowed` | showing immersive ads |
| `IsEligibleToPurchaseSubscription` | offering a subscription |
| `IsEligibleToPurchaseCommerceProduct` | offering a commerce product |
| `IsContentSharingAllowed` | features that let players share content others see (screenshots, posts) |
| `IsSubjectToChinaPolicies` | anything that must change for the licensed China release |

`AllowedExternalLinkReferences` is a legacy field that always returns an
empty array; do not build on it.

## How to call it

On the server, once per player on join, cached for the session. It yields
and can fail, and a failure must not unlock a restricted feature:

```lua
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local policies: { [Player]: { [string]: any } } = {}

Players.PlayerAdded:Connect(function(player)
	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	-- Unknown means restricted: a failed lookup must not open a paid random item.
	policies[player] = if ok then info else { ArePaidRandomItemsRestricted = true, IsPaidItemTradingAllowed = false }
end)

Players.PlayerRemoving:Connect(function(player)
	policies[player] = nil
end)

local function mayOpenPaidEgg(player: Player): boolean
	local policy = policies[player]
	return policy ~= nil and policy.ArePaidRandomItemsRestricted == false
end
```

The server enforces it: the client may hide the button, but the purchase
handler is where `mayOpenPaidEgg` is checked.

## Design so restricted players still play

A restricted player sees the same game with the gated feature replaced, not
a broken shop: eggs bought with earned currency only, or a direct purchase
of the item instead of a random roll. Show odds for every random item to
everyone, restricted or not.
