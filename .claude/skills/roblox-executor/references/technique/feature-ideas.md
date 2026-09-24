# Suggesting features from a dump

For "what can I make for this game?", "suggest features from this code" and
"add every feature that is possible". The user has pasted or uploaded a
decompiled dump and has not named the features.

The failure this file prevents is the confident list: *auto farm, infinite
money, god mode, unlock all gamepasses*, written from the game's genre rather
than its code. Half of it names remotes that do not exist and half of it asks
the client for things only the server owns. Every suggestion here is a line
the dump shows, and says what the dump cannot show.

`feature-search.md` answers "can I do X?". This file answers "what could I
do?", and hands each chosen feature to `feature-search.md` to build.

---

## 1. Take the inventory

```bash
python tools/py/dump_index.py <dump file or folder> --inventory
python tools/py/dump_index.py <dump> --inventory --json     # for your own filtering
```

It prints five sections, each entry with `script:line`:

| Section | What it lists | What it can become |
|---|---|---|
| 1. Actions the client sends | Every `FireServer` / `InvokeServer` call site, grouped by remote, with arguments as written | Automate or repeat the action the game already performs |
| 2. Interactions | `.Triggered` (ProximityPrompt), `.MouseClick` (ClickDetector), `.Touched` listeners | Auto-interact through `fireproximityprompt`, `fireclickdetector`, `firetouchinterest` |
| 3. Numbers in client code | `SprintSpeed = 24`, `AttackCooldown = 0.5` and similar | Change this client's copy of a rule |
| 4. Tags and attributes | `CollectionService` tags and attribute names the client reads | ESP, highlight, collect or teleport targets |
| 5. Engine features | Fly, speed, jump, noclip, ESP, teleport, aim | Needs no game code at all |

No Python? Search the dump by hand for the same things, in the same order:
`FireServer`, `InvokeServer`, `.Triggered`, `.MouseClick`, `.Touched`,
`Cooldown =`, `Speed =`, `GetTagged`, `GetAttribute`. The rules below do not
change.

Read the failed-to-decompile count. A region that failed is unknown, not empty.

---

## 2. Classify every candidate before suggesting it

| Class | Feasible from the client? | Say |
|---|---|---|
| **Engine** (section 5) | Yes, on your own character and camera | "Works without game code; the game may reset it or notice." Check the dump for code that writes the same property |
| **Game action** (section 1) | The call is; the result is the server's choice | "Calls `CollectCoin` the way `CoinCollector:11` does; the server decides whether it counts" |
| **Interaction** (section 2) | If the executor has the `fire*` function | "Needs `fireproximityprompt`; the server may still check distance" |
| **Client rule** (section 3) | Changes this client's copy only | "Makes your sprint faster on your screen; if the server checks speed, it snaps back or gets flagged" |
| **Visual** (section 4, UI) | Yes | "Shows where `Chest` objects are; it does not open them" |
| **Server-owned** | **No** | One line why, never code |

**Server-owned, whatever the dump says:** currency, inventory, gamepasses and
developer products, other players' data, damage the server calculates, stats
the server saves, admin commands with no client call site. A remote that
*requests* one of these is a game action (class 2), and the answer depends on
the server's checks, which a client dump cannot show. Never present it as
"infinite money".

---

## 3. Write the suggestions

One table, strongest evidence first: game actions and interactions with call
sites, then engine features, then client rules, then visuals. Eight rows unless
the user asked for everything.

| Feature | Evidence | How | Cannot tell from the dump |
|---|---|---|---|
| Auto collect coins | `CoinCollector.txt:11` fires `CollectCoin(coin.Name, coin.Position)` | Repeat that call for each coin, same two arguments | Whether the server checks distance or rate |
| Faster sprint | `Sprint.txt:4` `SprintSpeed = 24` in a module table | Set the field on the table `filtergc` finds by its keys | Whether the server checks speed |
| Fly | Engine | `LinearVelocity` on your own root part | Whether the game kicks for it |

Rules for each row:

- **The feature name is in the user's words**, not the remote's: "Auto collect
  coins", not "CollectCoin spam".
- **Evidence is a line the inventory printed.** Copy the remote name, method,
  and argument list from the call site exactly. Decompiler labels (`v14`, `u3`,
  `p6`) are not names; describe what they hold.
- **How names one value layer and one API** (`function-selection.md`). A row
  that needs "try the upvalue, else the global" is not ready.
- **The last column is never empty.** The dump shows the client; the server's
  checks are always unknown.

Then the rejected list, one line each: "Infinite gems: the server owns gems;
the only gem remote, `BuyItem` at `Shop:40`, spends them."

---

## 4. Building what they pick

When the user picks rows, or says "all of them":

1. Run `feature-search.md` for each picked row. Only a FOUND verdict builds; an
   engine feature builds on its engine route.
2. Build the rows that pass, in one script, with one toggle each. Controls and
   hub styling follow `roblox-ui` and the user's picker codes.
3. List what was not built and why, in the same words as the rejected list.
4. Anything PARTIAL or NOT FOUND gets the runtime probe, not a guess.

---

## Checklist before sending suggestions

- [ ] The inventory was run, or the manual search done, and its counts are in the reply
- [ ] Every remote, tag, attribute and number named appears in the inventory output
- [ ] Every argument list is copied from a call site, with its `script:line`
- [ ] No row gives currency, items, passes or other players' data
- [ ] Every row says what the dump cannot show
- [ ] Failed-to-decompile regions are reported as unknown
- [ ] Nothing was suggested because games of this genre usually have it
