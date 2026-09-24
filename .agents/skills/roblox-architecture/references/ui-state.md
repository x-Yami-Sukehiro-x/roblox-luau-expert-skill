# Where UI state lives

"Where should this code go" has one dominant real-world instance: a menu needs
to show something the server owns, the player can change it, and three other
parts of the interface care. Answer that badly and the UI layer becomes the
place all the game's state quietly ends up.

---

## The one rule

**The UI renders state. It does not own state.**

A player's coin balance is owned by the server, mirrored into a client-side
store, and *displayed* by a label. The label does not hold the number. If you
find yourself reading a value back out of a `TextLabel` to decide something, the
state has escaped into the view and the next feature that needs it will read the
label too.

```
server (authority)
   -> replication (remote / attribute / value object)
      -> client store (the client's mirror; one owner)
         -> view (labels, bars, buttons)
```

Every arrow is one-directional. Input goes back up as an *intent* — "the player
pressed Buy" — never as a new value.

---

## Three layers, three jobs

| Layer | Owns | Must not |
|---|---|---|
| **Store** | The client's copy of state, and the only place it is written | Touch `Instance`s |
| **Controller** | Wiring: subscribes to remotes, writes the store, handles input | Hold state of its own |
| **View** | Turning state into instances | Decide anything |

The value of the split is testability. A store is a plain table with functions —
it runs under `luau` with no DataModel, which is what
`roblox-toolchain/references/luaurc.md` and the CI story depend on. A view is
untestable and does not need to be, because it contains no decisions.

```lua
--!strict
-- Store: no Instances anywhere in this file.
local Signal = require(ReplicatedStorage.Packages.Signal)

local Wallet = {}
Wallet.changed = Signal.new()

local balance = 0

function Wallet.get(): number
    return balance
end

function Wallet.set(value: number)
    if value == balance then return end      -- do not fire for a no-op
    balance = value
    Wallet.changed:Fire(balance)
end

return Wallet
```

```lua
-- View: no decisions, no arithmetic that matters.
local function mountWallet(label: TextLabel, trove)
    local function render(value: number)
        label.Text = formatCurrency(value)
    end

    render(Wallet.get())                      -- paint the current state first
    trove:Add(Wallet.changed:Connect(render))
end
```

**Render once on mount, then subscribe.** A view that only subscribes shows
nothing until the next change, which is the most common "my UI is blank until I
do something" bug.

---

## Do not scatter `GetPropertyChangedSignal` across the view

Replicated values arriving as attributes or `ValueBase` objects tempt you to
bind labels straight to them. Three labels bound to the same attribute is three
connections, three places to change when the source moves, and no single place
to look when the number is wrong.

Bind **once**, into the store:

```lua
-- Controller: the only place that knows how the value arrives.
local function bindWallet(player: Player, trove)
    local function pull()
        Wallet.set(player:GetAttribute("Coins") or 0)
    end

    pull()
    trove:Add(player:GetAttributeChangedSignal("Coins"):Connect(pull))
end
```

Now the transport is one line to change if it becomes a remote, and every view
keeps working.

---

## Declarative libraries

Everything above is the imperative approach: you create instances and update
them. Declarative libraries invert that — you describe what the UI *is* for a
given state and the library reconciles the instances.

| Library | Model | Notes |
|---|---|---|
| **Fusion** | Fine-grained reactive `Value` / `Computed` / `Spring` | The most-adopted Roblox-native option. Its API changed substantially at 0.3 — check which version a tutorial targets |
| **Vide** | Solid-style reactive `source` / `effect` | Small, fully typed, concise |
| **React-lua** | Facebook React 17, translated | Familiar if you know React. The largest concept surface |
| **Charm** | Atomic state only, no renderer | Pairs with React-lua or a custom view |

Adoption and recency figures live in `docs/SOURCES.md`, dated, because they rot.

A sketch, so the shape is concrete:

```lua
-- Fusion: state is a Value; the label is derived from it.
local coins = Value(0)

local label = New("TextLabel")({
    Text = Computed(function(use)
        return formatCurrency(use(coins))
    end),
})

coins:set(120)          -- the label updates; nothing else was told to
```

```lua
-- Vide: the same idea, closer to Solid.
local coins = source(0)

local label = create("TextLabel")({
    Text = function()
        return formatCurrency(coins())
    end,
})

coins(120)
```

### Whether to adopt one

They genuinely remove a class of bug: forgetting to update a label when state
changes becomes impossible, because the label *is* a function of the state.

They also cost. A framework is a dependency you now track, a paradigm every
contributor must learn, and — with the reactive ones — a debugging experience
where "why did this update" is answered by a graph rather than a call stack.

- **A HUD and a settings menu** do not need one. The store-and-subscribe pattern
  above is a hundred lines and everyone can read it.
- **A UI with deeply nested derived state** — an inventory with filters, sorting,
  equipped state, and a comparison panel — is where a reactive library starts
  paying for itself.
- **A team that already knows React** should probably use React-lua rather than
  learn a second model.

**Do not mix two.** Half a UI in Fusion and half hand-rolled means two update
models, two cleanup stories, and a boundary where neither works.

`Roact` is archived. React-lua is its successor, and Roact is still the top
search result — check before following any tutorial that names it.

### Tokens still apply

A declarative renderer does not replace the design spine. `Tokens.luau` is still
where colour and spacing live; the difference is that a `Computed` reads them
instead of an assignment. Everything in `roblox-ui/references/gui-architecture.md`
about the three token tiers holds either way.

---

## Cleanup

Whatever the layer, a UI that is rebuilt on respawn or on menu open must not
leave connections behind. One Trove per mounted view, destroyed when the view
is:

```lua
local function openMenu()
    local trove = Trove.new()
    local gui = template:Clone()
    trove:Add(gui)                       -- destroyed with the trove

    mountWallet(gui.Coins, trove)
    mountInventory(gui.Grid, trove)

    return function()
        trove:Destroy()                  -- gui, connections, threads, all of it
    end
end
```

Return the teardown rather than relying on the caller to remember. This is the
same shape as the modal focus trap in `roblox-ui/references/input-surfaces.md`,
for the same reason: the code that set something up is the code that knows how
to undo it.

Declarative libraries handle instance cleanup for you and **not** anything else
you started — a `task.spawn`, a remote connection, a sound. Those still need an
owner.

---

## Checklist

- [ ] No state read back out of a `TextLabel` or any other instance.
- [ ] One store per domain; the store has no `Instance` references.
- [ ] Replicated values bound once in a controller, not per view.
- [ ] Views render on mount and then subscribe.
- [ ] Input travels up as intent, never as a computed new value.
- [ ] One UI paradigm, not two.
- [ ] Every mounted view owns a Trove and returns its teardown.
- [ ] Non-instance resources cleaned up explicitly even under a declarative library.
