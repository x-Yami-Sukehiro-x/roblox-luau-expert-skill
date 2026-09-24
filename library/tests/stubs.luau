-- ====== Roblox stubs: enough to exercise Toast's bookkeeping headless ======
local function noop() end

local function newSignal()
    local s = { handlers = {} }
    function s:Connect(fn)
        table.insert(self.handlers, fn)
        local conn = { Connected = true }
        function conn:Disconnect()
            conn.Connected = false
            for i, h in s.handlers do
                if h == fn then table.remove(s.handlers, i) break end
            end
        end
        return conn
    end
    function s:Once(fn) return self:Connect(fn) end
    function s:Fire(...)
        for _, h in table.clone(self.handlers) do h(...) end
    end
    return s
end

local function colour(r, g, b)
    local c = { r = r, g = g, b = b }
    function c:Lerp() return c end
    return c
end
Color3 = { fromRGB = colour, new = colour }
UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = {
    new = function(a, b, c, d)
        return {
            X = { Scale = a or 0, Offset = b or 0 },
            Y = { Scale = c or 0, Offset = d or 0 },
        }
    end,
}
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end
UDim2.fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end
Vector2 = { new = function(x, y) return { X = x, Y = y } end, zero = { X = 0, Y = 0 } }
Vector3 = { zero = {} }
Rect = { new = function() return {} end }
CFrame = { identity = {} }
Font = { fromEnum = function(e) return e end, new = function() return {} end }
TweenInfo = { new = function(...) return { ... } end }
NumberSequenceKeypoint = { new = function(time, value) return { Time = time, Value = value } end }
NumberSequence = { new = function(points) return { Keypoints = points } end }
ColorSequenceKeypoint = { new = function(time, value) return { Time = time, Value = value } end }
ColorSequence = { new = function(points) return { Keypoints = points } end }

local function enumOf(name, items)
    local t = {}
    for _, item in items do t[item] = name .. "." .. item end
    return t
end
Enum = {
    Font = enumOf("Font", { "Gotham", "GothamMedium", "GothamBold" }),
    AutomaticSize = enumOf("AutomaticSize", { "None", "X", "Y", "XY" }),
    ScreenInsets = enumOf("ScreenInsets", { "CoreUISafeInsets", "None" }),
    ZIndexBehavior = enumOf("ZIndexBehavior", { "Sibling", "Global" }),
    ApplyStrokeMode = enumOf("ApplyStrokeMode", { "Contextual", "Border" }),
    BorderStrokePosition = enumOf("BorderStrokePosition", { "Outer", "Center", "Inner" }),
    StrokeSizingMode = enumOf("StrokeSizingMode", { "FixedSize", "ScaledSize" }),
    FillDirection = enumOf("FillDirection", { "Horizontal", "Vertical" }),
    VerticalAlignment = enumOf("VerticalAlignment", { "Center", "Top", "Bottom" }),
    HorizontalAlignment = enumOf("HorizontalAlignment", { "Center", "Left", "Right" }),
    SortOrder = enumOf("SortOrder", { "LayoutOrder", "Name" }),
    TextXAlignment = enumOf("TextXAlignment", { "Left", "Center", "Right" }),
    TextYAlignment = enumOf("TextYAlignment", { "Center", "Top", "Bottom" }),
    UIFlexMode = enumOf("UIFlexMode", { "None", "Grow", "Shrink", "Fill", "Custom" }),
    ScaleType = enumOf("ScaleType", { "Slice", "Stretch" }),
    UserInputType = enumOf("UserInputType", { "MouseButton1", "Touch" }),
    PlaybackState = enumOf("PlaybackState", { "Completed", "Cancelled", "Playing" }),
    EasingStyle = enumOf("EasingStyle", { "Linear", "Quad", "Cubic", "Sine" }),
    EasingDirection = enumOf("EasingDirection", { "In", "Out", "InOut" }),
    ElasticBehavior = enumOf("ElasticBehavior", { "WhenScrollable", "Always", "Never" }),
    TextTruncate = enumOf("TextTruncate", { "None", "AtEnd", "SplitWord" }),
    UserInputState = enumOf("UserInputState", { "Begin", "Change", "End", "Cancel" }),
    ContextActionResult = enumOf("ContextActionResult", { "Sink", "Pass" }),
    UIFlexAlignment = enumOf("UIFlexAlignment", { "None", "Fill", "SpaceAround", "SpaceBetween", "SpaceEvenly" }),
    ScrollingDirection = enumOf("ScrollingDirection", { "X", "Y", "XY" }),
    KeyCode = enumOf("KeyCode", { "Left", "Right", "Up", "Down", "Escape", "DPadLeft", "DPadRight", "ButtonB" }),
}
Enum.UserInputType.MouseMovement = "UserInputType.MouseMovement"

Instance = {}
-- Instances proxy their properties through a shadow table so that `Parent`
-- assignment can register the child by name. Without that, a test can only
-- reach instances the constructor happened to return, which is how a component
-- ships with an unreachable focus ring nobody notices.
Instance.new = function(className)
    local fields = {
        ClassName = className,
        Name = className,
        AbsoluteSize = { X = 320, Y = 44 },
        AbsolutePosition = { X = 0, Y = 0 },
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 0, 0, 0),
        GroupTransparency = 1,
        Interactable = true,
        Visible = true,
        ZIndex = 1,
        destroyed = false,
    }
    local children = {}
    local changed = {}

    local inst
    inst = setmetatable({}, {
        __index = function(_, key)
            local value = fields[key]
            if value ~= nil then return value end
            return children[key]
        end,
        __newindex = function(_, key, value)
            if key == "Parent" then
                local previous = fields.Parent
                if previous ~= nil and previous.__detach then
                    previous.__detach(fields.Name, inst)
                end
                fields.Parent = value
                if value ~= nil and value.__attach then
                    value.__attach(fields.Name, inst)
                end
                return
            end
            local before = fields[key]
            fields[key] = value
            local signal = changed[key]
            if signal and before ~= value then signal:Fire() end
        end,
    })

    fields.__attach = function(name, child) children[name] = child end
    fields.__detach = function(name, child)
        if children[name] == child then children[name] = nil end
    end

    fields.MouseEnter = newSignal()
    fields.MouseLeave = newSignal()
    fields.InputBegan = newSignal()
    fields.InputEnded = newSignal()
    fields.SelectionGained = newSignal()
    fields.SelectionLost = newSignal()
    fields.Activated = newSignal()
    fields.Destroying = newSignal()
    fields.GetPropertyChangedSignal = function(_, property)
        local signal = changed[property] or newSignal()
        changed[property] = signal
        return signal
    end
    fields.FocusLost = newSignal()
    fields.Focused = newSignal()
    fields.CaptureFocus = function() fields.focused = true end
    fields.ReleaseFocus = function() fields.focused = false end
    fields.IsFocused = function() return fields.focused == true end
    fields.FindFirstAncestorWhichIsA = function(_, name)
        local layers = { ScreenGui = true, SurfaceGui = true, BillboardGui = true }
        local node = fields.Parent
        while node ~= nil do
            if node.ClassName == name or (name == "LayerCollector" and layers[node.ClassName]) then
                return node
            end
            node = node.Parent
        end
        return nil
    end
    fields.Destroy = function(self)
        fields.destroyed = true
        inst.Parent = nil
    end
    fields.WaitForChild = function() return Instance.new("Folder") end
    fields.IsA = function(_, name)
        local family = {
            GuiObject = { Frame = true, TextLabel = true, TextButton = true, TextBox = true, ImageLabel = true, ImageButton = true, ScrollingFrame = true, CanvasGroup = true },
            GuiButton = { TextButton = true, ImageButton = true },
            LayerCollector = { ScreenGui = true, SurfaceGui = true, BillboardGui = true },
        }
        return name == className or (family[name] ~= nil and family[name][className] == true)
    end
    fields.GetChildren = function()
        local list = {}
        for _, child in children do table.insert(list, child) end
        return list
    end
    fields.FindFirstChildWhichIsA = function(_, name)
        for _, child in children do
            if child:IsA(name) then return child end
        end
        return nil
    end
    fields.FindFirstChild = function(_, name) return children[name] end
    fields.Clone = function()
        local copy = Instance.new(className)
        for key, value in fields do
            local signal = type(value) == "table" and value.handlers ~= nil
            if key ~= "Parent" and type(value) ~= "function" and not signal then copy[key] = value end
        end
        return copy
    end
    fields.FindFirstChildOfClass = function(_, name)
        for _, child in children do
            if child.ClassName == name then return child end
        end
        return nil
    end
    fields.IsDescendantOf = function() return false end

    return inst
end

local heartbeat = newSignal()
local preRender = newSignal()

local services = {
    TweenService = {
        Create = function(_, inst, _, goals)
            local tween = { Completed = newSignal() }
            function tween:Play()
                for key, value in goals do inst[key] = value end
                tween.Completed:Fire(Enum.PlaybackState.Completed)
            end
            function tween:Cancel() end
            return tween
        end,
        -- Converge instantly. What is under test is the queue and reflow
        -- bookkeeping, not the interpolation curve.
        SmoothDamp = function(_, _, target) return target, 0 end,
    },
    RunService = { Heartbeat = heartbeat, PreRender = preRender },
    GuiService = {
        ReducedMotionEnabled = false,
        TouchControlsEnabled = false,
        GetPropertyChangedSignal = function() return newSignal() end,
    },
    Players = { LocalPlayer = { WaitForChild = function() return Instance.new("PlayerGui") end } },
    UserInputService = {
        InputBegan = newSignal(),
        InputChanged = newSignal(),
        InputEnded = newSignal(),
        TouchEnabled = false,
        MouseEnabled = true,
    },
    ContextActionService = {
        BindAction = noop,
        UnbindAction = noop,
    },
}

game = {
    GetService = function(_, name)
        local service = services[name]
        if not service then error("harness: unstubbed service " .. name) end
        return service
    end,
}

-- task is a Roblox global; the standalone luau binary has no scheduler, so
-- deferred work is queued and drained explicitly by the assertions. Running it
-- inline instead would hide ordering bugs that only appear with a real defer.
local deferred = {}
task = {
    defer = function(fn, ...) table.insert(deferred, { fn = fn, args = table.pack(...) }) end,
    delay = function(_, fn, ...) table.insert(deferred, { fn = fn, args = table.pack(...) }) end,
    spawn = function(fn, ...) fn(...) end,
    wait = noop,
    cancel = noop,
}

local function drain()
    while #deferred > 0 do
        local queue = deferred
        deferred = {}
        for _, entry in queue do
            entry.fn(table.unpack(entry.args, 1, entry.args.n))
        end
    end
end

HARNESS = { heartbeat = heartbeat, preRender = preRender, drain = drain, input = services.UserInputService }

script = {}
script.Parent = {}
script.Parent.Parent = script.Parent
