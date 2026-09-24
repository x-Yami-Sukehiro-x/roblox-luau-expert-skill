# Script Templates — illustrative only

> **These are illustrations, not answers.**
>
> Never paste a template as a response. Read the target game first, then compose from the reference signatures. A template that does not match the game's actual value layer, remote shape, or authority mode is wrong even if it runs without error.
>
> If a request *looks* like one of these templates, that is a reason to check the game's specifics — not a reason to skip checking.

What these are for: confirming individual call shapes. These fragments are not
complete programs: bind capabilities, establish target identity and compose the
ownership rules from `../technique/lifecycle.md` before delivery. Lines marked
`-- CHANGE:` require evidence from the actual game.

---

## 1. Remote logger

Shows: `__namecall` hook structure, the `checkcaller` guard, caller attribution, passthrough.

```lua
-- CHANGE: filter to the remotes you care about. Logging everything in a
-- busy game produces thousands of lines per second and lags the client.

local logged = {}
local old

old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- checkcaller() is mandatory: without it your own calls recurse
    if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        local src = getcallingscript()
        table.insert(logged, {
            remote = self:GetFullName(),
            method = method,
            args   = table.pack(...),
            origin = src and src:GetFullName() or "unknown",
        })
        -- CHANGE: print, write to file, or push to a UI instead
        print(method, self.Name, ...)
    end

    -- always pass through unless you specifically intend to block
    return old(self, ...)
end))

```

Bound the log and filter by the established remote instance before retaining
arguments. A client's argument shape does not prove what the server validates.
`old` is the pass-through callable, not a valid `restorefunction` target. Shared
metamethod teardown needs the hook-ownership decision in `lifecycle.md`.

---

## 2. Drawing ESP loop

Shows: object lifecycle, viewport projection, teardown discipline.

```lua
if typeof(Drawing) ~= "table" or typeof(Drawing.new) ~= "function" then
    return warn("Drawing unsupported")
end

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local boxes = {}          -- player -> Drawing object
local connection

local function acquire(player)
    if boxes[player] then return boxes[player] end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled    = false
    box.Color     = Color3.new(1, 1, 1)   -- CHANGE: team colours, health gradient, etc.
    box.Visible   = false
    boxes[player] = box
    return box
end

local function release(player)
    local box = boxes[player]
    if box then box:Destroy(); boxes[player] = nil end
end

connection = RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    for _, player in Players:GetPlayers() do
        if player == localPlayer then continue end

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local box  = acquire(player)

        if not root or not camera then box.Visible = false; continue end

        local pos, onScreen = camera:WorldToViewportPoint(root.Position)
        if not onScreen then box.Visible = false; continue end

        -- CHANGE: real box sizing needs the character's bounding box projected,
        -- not a constant. This is a placeholder so the shape is visible.
        local scale = 1000 / pos.Z
        box.Size     = Vector2.new(scale * 2, scale * 3)
        box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
        box.Visible  = true
    end
end)

local removingConnection = Players.PlayerRemoving:Connect(release)

local function unload()
    if connection then connection:Disconnect() end
    removingConnection:Disconnect()
    for player in boxes do release(player) end
end
```

The teardown is not optional. Orphaned Drawing objects survive script re-execution, stack up across reloads, and are both a memory problem and evidence.

---

## 3. Reset-resistant value patch

There is no generic executable patch: a constant, upvalue and Instance property
are different targets. Follow `../technique/source-to-api.md` to choose one
source-backed access path, identify the target and writer, capture its actual
original, and apply the narrow change. Never sweep every matching number or
silence all frame callbacks. A local read override does not alter a server-owned
value. Required rerun and restore cases: `../technique/lifecycle.md`.

---

## 4. Packet logger

Shows: feature detection, both hook directions, the mandatory `0x9B` exclusion, teardown.

```lua
local hasRaknet = typeof(raknet) == "table" and typeof(raknet.add_send_hook) == "function"
if not hasRaknet then
    return warn("raknet unsupported on this executor")
end

local ID_LUAU_CHALLENGE = 0x9B

local function describe(packet, direction)
    local id = packet.PacketId or packet.id
    -- Never block, alter, or interfere with the challenge channel.
    if id == ID_LUAU_CHALLENGE then return end

    -- CHANGE: filter to the IDs you are studying. Unfiltered output on a live
    -- server is thousands of packets per second.
    print(direction, string.format("0x%02X", id), packet.Size)
end

local function onSend(packet) describe(packet, "-->") end
raknet.add_send_hook(onSend)

-- receive hooks are a single slot on some builds: adding replaces the previous
if typeof(raknet.add_receive_hook) == "function" then
    raknet.add_receive_hook(function(packet) describe(packet, "<--") end)
end

local function unload()
    if typeof(raknet.remove_send_hook) == "function" then
        raknet.remove_send_hook(onSend)
    end
    if typeof(raknet.remove_receive_hook) == "function" then
        raknet.remove_receive_hook()
    end
end
```

Observe before you modify. Almost all useful packet work starts as a logging session that establishes which IDs the game actually uses and at what rate — modifying a packet whose format you have not read is the fastest route to a disconnect.

Feature-detect removal before installing a hook. A single receive-hook slot is
shared state: establish ownership before replacing or removing it. This fragment
does not establish that ownership and must not be shipped unchanged. Never clear
other scripts' hooks as part of this session's unload.

---

## Checklist before adapting any of these

1. Is the feature client-feasible at all? → `../technique/client-feasibility.md`
2. Is the game running Server Authority? → `../technique/replication-exploitation.md`
3. Where does the value actually live? → `../technique/value-persistence.md`
4. Which functions does this executor have? → feature-detect, do not assume
5. What does the teardown path look like? → write it before the feature works, not after
