---
name: roblox-monetization
description: Robux monetization - game passes, developer products, idempotent ProcessReceipt, subscriptions, pricing, PolicyService and paid random items. Use for shops and purchase bugs.
---

# Monetization

Every other bug in a Roblox game costs a player some time. A bug here costs
somebody money — either the player, who paid and got nothing, or you, who
granted an item and never got paid for it.

Two properties make purchase code correct. Everything below is in service of
them:

- **Idempotent.** Granting the same purchase twice must produce the same result
  as granting it once.
- **Durable.** The record that a purchase was granted must outlive the server
  that granted it.

Neither is optional and neither is the default.

---

## Load a reference when

| Need | File |
|---|---|
| the full receipt handler, ledger, and failure modes | `references/receipts.md` |
| passes vs products vs subscriptions, prompts, ownership checks | `references/products-and-passes.md` |
| paid random items, trading, ads and subscriptions by region and age | `references/policy-compliance.md` |

---

## The one fact that explains most of the bugs

**`ProcessReceipt` can fire more than once for the same purchase.**

Roblox retries it — after a network hiccup, after a server restart, after a
timeout it did not hear back from. That is not a bug in Roblox; it is the only
safe design for a callback that may or may not have completed. It means the
retry is *your* problem to make harmless.

```lua
-- WRONG. Correct-looking, ships constantly, and duplicates items.
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    grantCoins(player, PRODUCTS[receiptInfo.ProductId])
    return Enum.ProductPurchaseDecision.PurchaseGranted
end
```

A player who buys 100 coins once can end up with 200 or 300. There is no
warning, no error and no log line — it just happens to some fraction of your
purchases, and the fraction rises with server load.

The fix is a **ledger**: remember every `receiptInfo.PurchaseId` you have
already fulfilled, check it before granting, and write the record in the same
atomic operation that grants.

Full implementation: `references/receipts.md`.

---

## `NotProcessedYet` is not a failure

The return value is `Enum.ProductPurchaseDecision`, with exactly two members:

| Return | Meaning | Consequence |
|---|---|---|
| `PurchaseGranted` | I have durably recorded this and the player has the goods | Roblox takes the Robux and stops retrying |
| `NotProcessedYet` | I am not sure | Roblox keeps the Robux pending and **will call you again** |

`NotProcessedYet` is the correct answer to every uncertainty: the player left,
the DataStore call failed, the product id is not in your table, the grant threw.
Returning it costs nothing — Roblox retries, and the player is not charged for
something they did not receive.

**Never return `PurchaseGranted` on a path where the grant might not have been
saved.** That is the one irreversible mistake in this file: the Robux is taken,
the retry stops, and the player has nothing.

An unrecognised product id is the subtle case. It is tempting to grant nothing
and return `PurchaseGranted` to stop the retries. Do not — you have just taken
money for a product you no longer sell. Return `NotProcessedYet`, log loudly,
and fix the table.

---

## Order of operations

The grant and the ledger write must be **one** operation, not two.

```
WRONG   grant item  ->  write "granted" to the ledger
        (crash between the two = item granted, no record, retry grants again)

WRONG   write "granted"  ->  grant item
        (crash between the two = record exists, retry skips, player paid for nothing)

RIGHT   one UpdateAsync that reads the ledger, and inside the same transform
        both records the PurchaseId and applies the grant to the same data
```

If your player data lives in a session-locked profile (ProfileStore, Lyra —
see `roblox-data-persistence`), the grant belongs **inside** the profile update
rather than beside it. The profile is the transaction boundary you already have.

---

## Server only

`ProcessReceipt` is a server callback. There is exactly one of it per server —
assigning it twice silently replaces the first handler, so a second script that
sets it will break the first. Set it in one place.

The client's role is limited to asking:

```lua
MarketplaceService:PromptProductPurchase(player, productId)
```

Everything about what the player receives is decided on the server, from
`receiptInfo`. A `RemoteEvent` saying "I bought the thing, give me the thing" is
not a purchase flow — it is a free item dispenser. See `roblox-game-security`.

---

## Standing rules

1. **A ledger, keyed by `PurchaseId`, checked before every grant.**
2. **`NotProcessedYet` on any doubt.** It is free and it is retryable.
3. **Grant and record atomically**, inside the player's existing data
   transaction where one exists.
4. **One `ProcessReceipt` assignment** in the whole codebase.
5. **Never trust a client-reported purchase.** `receiptInfo` is the only source.
6. **`GetProductInfoAsync` and `PlayerOwnsAssetAsync`, not the `[Deprecated]`
   non-Async forms** (`GetProductInfo`, `PlayerOwnsAsset`, `PlayerOwnsBundle`).
7. **Cache ownership lookups per session**, and invalidate on the matching
   `Prompt...Finished` event — `UserOwnsGamePassAsync` yields and is rate-limited.
8. **Gate anything region-sensitive on `PolicyService`**, not on a guess.
9. **Log every receipt** with its `PurchaseId`. When a player says they paid and
   got nothing, that log is the only way to tell whether they are right.

## Works with

- `roblox-data-persistence`: the PurchaseId ledger saved with the grant.
- `roblox-game-design`: what is worth selling in this loop.
- `roblox-ui`: the shop and purchase confirmation archetypes.
- `roblox-game-security`: prices and grants decided by the server.
