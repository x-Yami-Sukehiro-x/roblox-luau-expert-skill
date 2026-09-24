# Nil Safety & Common Runtime Errors

Primary goal: never produce "attempt to index nil with X", "attempt to call a nil value", or silent wrong behavior from missing objects.

## Root causes of "attempt to index nil with X" (≈95% of cases)

1. Timing / replication — object not yet streamed or created
2. FindFirstChild / FindFirstChildOfClass returned nil and was not checked
3. Typo or wrong case in name
4. Object is in a different container than expected
5. ModuleScript does not return a table (or returns nil)
6. Character / Humanoid not loaded yet (especially on PlayerAdded)

## Mandatory patterns

### Wait for existence
```lua
local obj = parent:WaitForChild("Name", 10) -- timeout recommended
if not obj then
    warn("Missing critical object")
    return
end
```

### Safe child lookup
```lua
local function safeChild(parent: Instance, name: string): Instance?
    local obj = parent:FindFirstChild(name)
    if not obj then
        warn(("[safeChild] %s missing under %s"):format(name, parent:GetFullName()))
    end
    return obj
end
```

### Character lifecycle
```lua
local function onCharacter(character: Model)
    -- Every WaitForChild gets a timeout. Without one it waits forever on a
    -- character that was destroyed mid-load, and the thread never returns.
    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    if not humanoid or not root then
        return          -- the character went away while we waited
    end
    -- now safe
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
    onCharacter(player.Character)
end
```

### After any yield, re-validate
Player may have left, instance may have been destroyed, character may have respawned.

```lua
-- after task.wait, RemoteFunction yield, DataStore yield, etc.
if not player.Parent then return end
if not character.Parent then return end
```

### Strict mode + types
```lua
--!strict
local part: Part? = workspace:FindFirstChildOfClass("Part")
if part then
    part.Anchored = true  -- type refined
end
```

### Short-circuit and explicit checks
<!-- lint: fragment -->
```lua
-- Prefer
if humanoid and humanoid.Health > 0 then
-- over relying on truthiness for numbers (0 is truthy)
if count ~= nil and count > 0 then
```

### Modules
Always `return` a table from ModuleScripts. Callers should treat require results as potentially nil only if the module is optional.

### pcall for fallible APIs
DataStore, HttpService, MarketplaceService, etc.

```lua
local ok, result = pcall(function()
    return store:GetAsync(key)
end)
if not ok then
    warn("DataStore failed:", result)
    return
end
```

## Anti-patterns that cause nil slips
- Direct indexing of optional children: `workspace.Map.Door.Handle`
- Assuming Character exists immediately after PlayerAdded
- Storing Instance references across yields without re-checking .Parent
- Ignoring the second return value of loadstring / loadfile
- Treating 0 or "" as falsy

When writing any script, prefer WaitForChild + type assertion or explicit nil checks over raw indexing.
