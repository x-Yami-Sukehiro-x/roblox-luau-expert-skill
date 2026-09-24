# Receipts, ledgers and idempotency

`MarketplaceService.ProcessReceipt` is the only place a developer product
purchase becomes real. It is also the most retried callback in the engine.

---

## What you are handed

`receiptInfo` is a plain table. The fields that matter:

| Field | Use |
|---|---|
| `PurchaseId` | **Unique per purchase.** The ledger key. The whole design rests on this |
| `PlayerId` | `UserId` of the buyer. May not be in this server, or any server |
| `ProductId` | Which developer product |
| `CurrencySpent` | Robux amount |
| `CurrencyType` | `Enum.CurrencyType` |
| `PlaceIdWherePurchased` | Which place in the universe |

`PurchaseId` is the field people skip because the handler appears to work
without it. It is the only field that makes retries safe.

---

## The whole handler

```lua
--!strict
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Grants = require(script.Parent.Grants)

local purchaseStore = DataStoreService:GetDataStore("PlayerPurchases")

-- A ledger entry is a single player's set of fulfilled PurchaseIds, stored
-- alongside the data the grant mutates so both move in one transaction.
local LEDGER_LIMIT = 60          -- keep the newest N; see "Ledger growth"

local Granted = Enum.ProductPurchaseDecision.PurchaseGranted
local NotYet = Enum.ProductPurchaseDecision.NotProcessedYet

local function processReceipt(receiptInfo): Enum.ProductPurchaseDecision
    local grant = Grants.forProduct(receiptInfo.ProductId)
    if not grant then
        -- Money has been taken for something we cannot deliver. Do NOT report
        -- success: that would end the retries and keep the Robux.
        warn(("[Receipts] unknown ProductId %d for user %d, purchase %s")
            :format(receiptInfo.ProductId, receiptInfo.PlayerId, receiptInfo.PurchaseId))
        return NotYet
    end

    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return NotYet          -- they left. Roblox will retry when they return.
    end

    local key = ("user_%d"):format(receiptInfo.PlayerId)
    local alreadyHad = false

    local ok, err = pcall(function()
        purchaseStore:UpdateAsync(key, function(old)
            local data = old or { purchases = {}, order = {}, coins = 0, items = {} }

            if data.purchases[receiptInfo.PurchaseId] then
                alreadyHad = true
                return nil         -- returning nil cancels the write entirely
            end

            -- Record and grant in the SAME transform. A crash between them is
            -- not possible because there is no "between".
            data.purchases[receiptInfo.PurchaseId] = os.time()
            table.insert(data.order, receiptInfo.PurchaseId)
            grant.apply(data, receiptInfo)

            while #data.order > LEDGER_LIMIT do
                local oldest = table.remove(data.order, 1)
                data.purchases[oldest] = nil
            end

            return data
        end)
    end)

    if not ok then
        warn(("[Receipts] UpdateAsync failed for purchase %s: %s")
            :format(receiptInfo.PurchaseId, tostring(err)))
        return NotYet          -- nothing was written; a retry is safe
    end

    if alreadyHad then
        -- Already fulfilled on an earlier call. Report success so Roblox stops
        -- retrying; the player has the goods.
        return Granted
    end

    Grants.reflectToSession(player, receiptInfo)     -- update the live session
    return Granted
end

MarketplaceService.ProcessReceipt = processReceipt
```

---

## Why each part is there

**`return nil` inside the transform cancels the write.** That is
`UpdateAsync` semantics, and it is what makes the duplicate case cost nothing —
no write, no budget consumed, no version created.

**The `pcall` wraps `UpdateAsync`, and its result is checked.** A `pcall` whose
return value is discarded is worse than no `pcall`: it converts a loud failure
into a silent one. If the store call failed, nothing was recorded and nothing
was granted, so `NotProcessedYet` is exactly right.

**`alreadyHad` is set inside the transform and read after.** The transform may
run several times under contention; the flag reflects the last run, which is the
one that decided.

**The live session is updated separately from the durable write.** The
`UpdateAsync` is the source of truth. `reflectToSession` is a cache refresh so
the player sees their coins immediately — if it fails, the next load is still
correct.

**`grant.apply(data, receiptInfo)` mutates the same `data` table.** The grant is
part of the transaction, not a call that happens afterwards.

---

## Ledger growth

A `PurchaseId` set that only grows will eventually push a heavy spender's key
past the 4 MB DataStore value limit. Two viable strategies:

- **Bounded window** (above). Keep the newest N ids and drop older ones. Roblox
  does not retry a purchase indefinitely, so an id that fell out of a 60-entry
  window is not going to come back. Simple, and what most games should do.
- **Separate ledger key.** Keep purchase ids under their own key, out of the
  profile. Costs a second DataStore round trip and — importantly — **breaks the
  atomicity** unless you are careful, because the grant and the record are now
  two writes. Only worth it if you need a full audit trail, and then the record
  should be written *before* the grant with a reconciliation pass for orphans.

The bounded window is the right default. If you are unsure, take it.

---

## Session-locked profiles

If player data is already in ProfileStore or Lyra, use the transaction you have
rather than opening a second one:

```lua
local profile = Profiles[player]
if not profile or not profile:IsActive() then
    return NotYet          -- the session lock is not held; do not write
end

if profile.Data.purchases[receiptInfo.PurchaseId] then
    return Granted
end

profile.Data.purchases[receiptInfo.PurchaseId] = os.time()
grant.apply(profile.Data, receiptInfo)
return Granted
```

`IsActive()` — or whatever the library's equivalent is — is the check that
matters. Writing to a profile whose session lock has been released means the
write is discarded, and returning `PurchaseGranted` after that takes money for
nothing.

The library saves periodically rather than immediately, so there is a window
where the grant is in memory but not on disk. That is acceptable *only* because
the ledger entry is in the same table: if the server dies before the save, the
grant is lost **and** so is the ledger record, and the retry re-grants cleanly.
Splitting them across two stores is what breaks that property.

---

## Failure modes, ranked by how often they bite

**1. No ledger at all.** Duplicated items, inflated economy. The default
outcome of a handler that looks correct.

**2. Ledger written outside the grant transaction.** Halves the duplicate rate
and introduces a rarer, worse bug: paid-for-nothing.

**3. `PurchaseGranted` returned on an unknown product id.** Silently keeps money
for undeliverable goods. Usually introduced when someone gets tired of retry
warnings in the log.

**4. `pcall` result ignored.** The store threw, nothing saved, success reported.

**5. Two scripts assigning `ProcessReceipt`.** The second wins; the first
handler's products stop being fulfilled entirely. There is no error.

**6. Granting from a `RemoteEvent` the client fires after a prompt.** Free items
for anyone with an executor. `PromptProductPurchaseFinished` on the client is a
UI signal, not an authorisation.

**7. Ledger keyed on `ProductId` instead of `PurchaseId`.** Player buys the same
product twice, legitimately, and the second purchase is swallowed as a duplicate.

---

## Refunds and chargebacks

Roblox does not notify your game when a purchase is refunded. There is no
callback and no field to poll.

What follows from that:

- **Consumables are safe.** Spend-on-receipt currency cannot be clawed back
  because it is already spent.
- **Permanent grants are not.** A refunded permanent unlock stays unlocked.
- **Do not build a refund flow that grants Robux.** You cannot.

The practical mitigation is to keep the receipt log — `PurchaseId`, `PlayerId`,
`ProductId`, `CurrencySpent`, timestamp — so support requests can be answered
from evidence rather than memory.

---

## Testing

`ProcessReceipt` does not fire in Studio for a real purchase, so the handler is
easy to ship untested. Make it testable by keeping the decision logic pure:

```lua
-- Receipts.processReceipt(receiptInfo, deps) with deps injected means the
-- retry, the unknown-product path and the ledger-hit path can all be tested
-- with a table instead of a DataStore.
```

The three cases worth a test each:

1. A fresh `PurchaseId` grants once and records.
2. The **same** `PurchaseId` twice grants once and returns `PurchaseGranted` both times.
3. A store failure returns `NotProcessedYet` and leaves no record.

Case 2 is the whole point of the file. If nothing else is tested, test that.

---

## Checklist

- [ ] Every grant is keyed on `PurchaseId`, not `ProductId`.
- [ ] The ledger write and the grant are in one `UpdateAsync` transform, or one profile write.
- [ ] `NotProcessedYet` on: player absent, store error, unknown product, inactive profile.
- [ ] `pcall` results are checked, never `local _ =`.
- [ ] Exactly one `ProcessReceipt` assignment in the codebase.
- [ ] Ledger size is bounded.
- [ ] Nothing is granted in response to a client message.
- [ ] Every receipt is logged with its `PurchaseId`.
- [ ] The double-fire case has a test.
