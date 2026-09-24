# Passes, products, prompts and ownership

Which product type to use is the first decision and it is not reversible: a game
pass and a developer product are different objects with different ids, and you
cannot convert one into the other after players have bought it.

---

## Choosing

Roblox calls these **GamePass** and **DeveloperProduct** in the API —
`Enum.InfoType.GamePass` and `Enum.InfoType.Product` respectively, which is its
own small trap when calling `GetProductInfoAsync`.

| | Game pass (`GamePass`) | Developer product (`DeveloperProduct`) | Subscription |
|---|---|---|---|
| Bought | Once, ever | Repeatedly | Recurring, real currency |
| Ownership | Roblox tracks it | **You** track it | Roblox tracks status |
| Server learns about it via | `UserOwnsGamePassAsync` | `ProcessReceipt` | `GetUserSubscriptionStatusAsync` |
| Survives your DataStore being wiped | Yes | No | Yes |
| Good for | Permanent unlocks: VIP, a tool, 2x speed | Currency, consumables, repeatable boosts | Ongoing membership |

The rule that follows from row four: **anything permanent should be a game
pass** if you can express it as one. Roblox is holding the record, which means a
data-loss incident does not cost the player something they paid for.

Anything consumable must be a developer product, because a game pass can only be
bought once.

---

## Prompting

All prompts are fire-and-forget. They open Roblox's own UI and return
immediately; the result arrives on an event.

```lua
local MarketplaceService = game:GetService("MarketplaceService")

MarketplaceService:PromptGamePassPurchase(player, gamePassId)
MarketplaceService:PromptProductPurchase(player, productId)
MarketplaceService:PromptPurchase(player, assetId)               -- catalog asset
MarketplaceService:PromptBundlePurchase(player, bundleId)
MarketplaceService:PromptSubscriptionPurchase(player, subscriptionId)
```

| Event | Signature |
|---|---|
| `PromptGamePassPurchaseFinished` | `(player, gamePassId, wasPurchased)` |
| `PromptProductPurchaseFinished` | `(userId, productId, isPurchased)` |
| `PromptPurchaseFinished` | `(player, assetId, isPurchased)` |
| `PromptBundlePurchaseFinished` | `(player, bundleId, wasPurchased)` |
| `PromptSubscriptionPurchaseFinished` | `(user, subscriptionId, didTryPurchasing)` |

Note the inconsistency, because it causes real bugs: `PromptProductPurchaseFinished`
hands you a **`userId` number**, while the others hand you a **`Player`**. Code
that assumes a `Player` and indexes `.Name` on it will throw.

### What these events are and are not

`PromptGamePassPurchaseFinished` firing with `wasPurchased = true` is a
reasonable moment to refresh your ownership cache and update the UI.

`PromptProductPurchaseFinished` is **not** how you grant a developer product.
The grant happens in `ProcessReceipt`, on the server, from `receiptInfo`. The
prompt event is a UI signal only. Granting from it on the client is a free item
dispenser; granting from it on the server still misses purchases that complete
after the player's client has gone.

The subscription event's parameter is named `didTryPurchasing`, not
`wasPurchased`, and it means what it says — the player reached the end of the
flow, not that the subscription is active. Confirm with
`GetUserSubscriptionStatusAsync`.

---

## Ownership checks

```lua
local owns = MarketplaceService:UserOwnsGamePassAsync(userId, gamePassId)  -- YIELDS
```

Three properties of this call decide how you use it:

- **It yields**, so anything you captured beforehand must be re-validated after.
- **It is rate-limited.** Calling it per frame, or per player on a busy join,
  will throttle.
- **It caches internally for a while**, which means a player who buys a pass
  mid-session may still read as not owning it for a short period.

That last one is why the ownership cache must be *invalidated by the purchase
event*, not just refreshed on a timer:

```lua
local ownership = {}          -- [userId] = { [gamePassId] = boolean }

local function ownsPass(userId: number, passId: number): boolean
    local forUser = ownership[userId]
    if forUser and forUser[passId] ~= nil then
        return forUser[passId]
    end

    local ok, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
    end)

    if not ok then
        -- Do not cache a failure as "does not own". Fail open or closed
        -- deliberately; silently denying a paid perk is the worse outcome.
        warn(("[Passes] ownership check failed for %d/%d: %s"):format(userId, passId, tostring(result)))
        return false
    end

    ownership[userId] = ownership[userId] or {}
    ownership[userId][passId] = result
    return result
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
    if not wasPurchased then return end
    ownership[player.UserId] = ownership[player.UserId] or {}
    ownership[player.UserId][passId] = true      -- trust the event over the cache
end)

Players.PlayerRemoving:Connect(function(player)
    ownership[player.UserId] = nil               -- or it grows for the server's life
end)
```

The `PlayerRemoving` cleanup is not optional. A table keyed by `UserId` that is
never cleared is a slow leak, and `Player` objects are not garbage-collected on
leave — see `roblox-performance`.

**`PlayerOwnsAsset` and `PlayerOwnsBundle` are `[Deprecated]`.** The live forms
are `PlayerOwnsAssetAsync` and `PlayerOwnsBundleAsync`.

---

## Product metadata

```lua
local info = MarketplaceService:GetProductInfoAsync(productId, Enum.InfoType.Product)  -- YIELDS
-- info.Name, info.Description, info.PriceInRobux, info.IconImageAssetId
```

`Enum.InfoType` is `Asset`, `Product`, `GamePass`, `Subscription` or `Bundle`,
and passing the wrong one returns information about a completely different
object with the same numeric id. That is the classic "my shop shows the wrong
icon" bug.

`GetProductInfo` without `Async` is `[Deprecated]`.

**Do not price your shop from `PriceInRobux` at runtime without caching.** It
yields, it is rate-limited, and a shop that calls it once per item per open will
throttle on a busy server. Fetch once at server start, cache, and accept that a
price change needs a server restart to appear.

**Never trust `PriceInRobux` for a grant decision.** The amount actually paid is
`receiptInfo.CurrencySpent`, and that is the only figure that reflects what
happened.

---

## `PolicyService`

Some players — by age, by region, by platform — must not be shown certain
things. This is a compliance requirement, not a preference, and guessing from
`Player.AccountAge` or locale is not a substitute.

```lua
local PolicyService = game:GetService("PolicyService")

local ok, policy = pcall(function()
    return PolicyService:GetPolicyInfoForPlayerAsync(player)   -- YIELDS
end)

if ok then
    -- policy.ArePaidRandomItemsRestricted   -> loot boxes, crates, gacha
    -- policy.AllowedExternalLinkReferences  -> which platforms you may link to
    -- policy.IsPaidItemTradingAllowed       -> player-to-player trading
    -- policy.IsSubjectToChinaPolicies
    if policy.ArePaidRandomItemsRestricted then
        hideLootBoxes(player)
    end
end
```

`ArePaidRandomItemsRestricted` is the one that matters most: if it is true, that
player must not be offered a paid random-outcome item. Fail **closed** — if the
call errors, hide the feature rather than showing it. A failed check that
reveals a restricted item is a compliance problem; one that hides an allowed
item is a minor annoyance.

`GetPolicyInfoForServerRobloxOnlyAsync` is `{RobloxScript}` and unavailable to
your game.

---

## Subscriptions

```lua
local status = MarketplaceService:GetUserSubscriptionStatusAsync(player, subscriptionId)  -- YIELDS
-- status.IsSubscribed, status.IsRenewing, status.ExpirationDetail
```

`IsSubscribed` and `IsRenewing` are different questions. A player who cancelled
but is still inside a paid period is subscribed and not renewing — they should
keep their benefits until expiry.

Related calls, all yielding: `GetSubscriptionProductInfoAsync`,
`GetUserSubscriptionDetailsAsync`, `GetUserSubscriptionPaymentHistoryAsync`,
`PromptCancelSubscription`.

Re-check status on join rather than trusting a stored flag: a subscription can
lapse while the player is offline, and your DataStore will not hear about it.

---

## Shop UI

The interface belongs in `roblox-ui`; two rules are monetization-specific.

**Never let the client compute what it receives.** The client asks for a
`productId`. The server decides what that id means. A shop that sends
`{ item = "sword", cost = 100 }` over a remote is not a shop.

**Purchase buttons need a loading state.** Between prompt and result there is a
window in which a player can press again. `component-states.md` covers the six
states; the `loading` one exists for exactly this. Disable on prompt, re-enable
on the `Finished` event *and* on a timeout, so a dismissed prompt does not leave
the button dead forever.

---

## Checklist

- [ ] Permanent unlocks are passes; consumables are products.
- [ ] Nothing is granted from a `Prompt...Finished` event.
- [ ] `PromptProductPurchaseFinished` is handled as `userId`, not `Player`.
- [ ] Ownership cached per session, invalidated by the purchase event, cleared on `PlayerRemoving`.
- [ ] Failed ownership checks are not cached as "does not own".
- [ ] `...Async` forms everywhere; no `[Deprecated]` `GetProductInfo` / `PlayerOwnsAsset`.
- [ ] `Enum.InfoType` matches the id being looked up.
- [ ] Prices cached, never used to decide a grant.
- [ ] `PolicyService` consulted for random paid items, and it fails closed.
- [ ] Subscription status re-checked on join, `IsRenewing` distinguished from `IsSubscribed`.
- [ ] Purchase buttons have a loading state with a timeout.
