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
-- Real vector arithmetic: the executor assets steer physics with it.
local vectorMeta = {}
local function vector(x, y, z)
    local v = setmetatable({ X = x, Y = y, Z = z }, vectorMeta)
    return v
end
vectorMeta.__index = function(v, key)
    if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if key == "Unit" then
        local length = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
        return vector(v.X / length, v.Y / length, v.Z / length)
    end
    if key == "Dot" then return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end end
    if key == "Cross" then
        return function(a, b) return vector(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
    end
    return nil
end
vectorMeta.__add = function(a, b) return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__sub = function(a, b) return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMeta.__unm = function(a) return vector(-a.X, -a.Y, -a.Z) end
vectorMeta.__mul = function(a, b)
    if type(a) == "number" then return vector(a * b.X, a * b.Y, a * b.Z) end
    if type(b) == "number" then return vector(a.X * b, a.Y * b, a.Z * b) end
    return vector(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
vectorMeta.__div = function(a, b) return vector(a.X / b, a.Y / b, a.Z / b) end
vectorMeta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
Vector3 = {
    new = function(x, y, z) return vector(x or 0, y or 0, z or 0) end,
    zero = vector(0, 0, 0),
    one = vector(1, 1, 1),
    xAxis = vector(1, 0, 0),
    yAxis = vector(0, 1, 0),
    zAxis = vector(0, 0, 1),
}
Rect = { new = function() return {} end }
-- A CFrame here is a position plus look and right vectors; enough for
-- camera-relative steering and teleports, not for composing rotations.
local function frame(position, look, right)
    local up = right:Cross(look)
    return {
        Position = position,
        LookVector = look,
        RightVector = right,
        UpVector = up,
        Rotation = { LookVector = look, RightVector = right },
    }
end
CFrame = {
    identity = frame(vector(0, 0, 0), vector(0, 0, -1), vector(1, 0, 0)),
    new = function(x, y, z)
        local position = if type(x) == "table" then x else vector(x or 0, y or 0, z or 0)
        return frame(position, vector(0, 0, -1), vector(1, 0, 0))
    end,
    lookAlong = function(position, direction)
        local look = direction.Unit
        return frame(position, look, look:Cross(vector(0, 1, 0)).Unit)
    end,
    frame = frame,
}
Ray = { new = function(origin, direction) return { Origin = origin, Direction = direction } end }
RaycastParams = { new = function() return {} end }
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
    UserInputType = enumOf("UserInputType", { "MouseButton1", "MouseButton2", "Touch", "Gamepad1" }),
    PlaybackState = enumOf("PlaybackState", { "Completed", "Cancelled", "Playing" }),
    EasingStyle = enumOf("EasingStyle", { "Linear", "Quad", "Cubic", "Sine" }),
    EasingDirection = enumOf("EasingDirection", { "In", "Out", "InOut" }),
    ElasticBehavior = enumOf("ElasticBehavior", { "WhenScrollable", "Always", "Never" }),
    TextTruncate = enumOf("TextTruncate", { "None", "AtEnd", "SplitWord" }),
    UserInputState = enumOf("UserInputState", { "Begin", "Change", "End", "Cancel" }),
    ContextActionResult = enumOf("ContextActionResult", { "Sink", "Pass" }),
    UIFlexAlignment = enumOf("UIFlexAlignment", { "None", "Fill", "SpaceAround", "SpaceBetween", "SpaceEvenly" }),
    ScrollingDirection = enumOf("ScrollingDirection", { "X", "Y", "XY" }),
    KeyCode = enumOf("KeyCode", {
        "Left", "Right", "Up", "Down", "Escape", "DPadLeft", "DPadRight", "ButtonB",
        "F", "G", "H", "J", "E", "Q", "V", "X", "Z", "P", "Space", "LeftControl", "LeftShift", "RightShift",
        "LeftBracket", "RightBracket", "Thumbstick2", "Unknown",
    }),
    CameraType = enumOf("CameraType", { "Custom", "Scriptable", "Fixed" }),
    CameraMode = enumOf("CameraMode", { "Classic", "LockFirstPerson" }),
    MouseBehavior = enumOf("MouseBehavior", { "Default", "LockCenter", "LockCurrentPosition" }),
    HumanoidStateType = enumOf("HumanoidStateType", { "Jumping", "Freefall", "Running", "Physics", "Dead", "Seated" }),
    VelocityConstraintMode = enumOf("VelocityConstraintMode", { "Line", "Plane", "Vector" }),
    ActuatorRelativeTo = enumOf("ActuatorRelativeTo", { "Attachment0", "Attachment1", "World" }),
    OrientationAlignmentMode = enumOf("OrientationAlignmentMode", { "OneAttachment", "TwoAttachment" }),
    HighlightDepthMode = enumOf("HighlightDepthMode", { "AlwaysOnTop", "Occluded" }),
    RaycastFilterType = enumOf("RaycastFilterType", { "Exclude", "Include" }),
}
Enum.UserInputType.MouseMovement = "UserInputType.MouseMovement"
Enum.UserInputType.Keyboard = "UserInputType.Keyboard"

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
    fields.MouseMoved = newSignal()
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
            BasePart = { Part = true, MeshPart = true, UnionOperation = true },
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
    fields.GetDescendants = function()
        local list = {}
        for _, child in children do
            table.insert(list, child)
            for _, below in child:GetDescendants() do table.insert(list, below) end
        end
        return list
    end
    fields.DescendantAdded = newSignal()
    fields.ChildAdded = newSignal()
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

HARNESS = { heartbeat = heartbeat, preRender = preRender, drain = drain, input = services.UserInputService, services = services }

-- A local player standing in a world, for the executor feature scripts. Each
-- call replaces the previous world, and getgenv() keeps one table per world.
function HARNESS.world()
    local genv = {}
    getgenv = function() return genv end
    local function character(name)
        local model = Instance.new("Model")
        model.Name = name
        local humanoid = Instance.new("Humanoid")
        humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = 16, 50, 7.2
        humanoid.UseJumpPower, humanoid.MoveDirection, humanoid.Health = false, Vector3.zero, 100
        humanoid.ChangeState = function(self, state) self.lastState = state end
        humanoid.GetState = function(self) return self.lastState or Enum.HumanoidStateType.Running end
        humanoid.PlatformStand, humanoid.Sit = false, false
        humanoid.Parent = model
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.CanCollide, root.Anchored, root.Position = true, false, Vector3.new(0, 3, 0)
        root.Parent = model
        humanoid.RootPart = root
        local head = Instance.new("Part")
        head.Name = "Head"
        head.CanCollide = true
        head.Parent = model
        model.PivotTo = function(self, target) self.pivot = target end
        model.GetPivot = function(self) return self.pivot or CFrame.new(root.Position) end
        model.WaitForChild = function(self, childName) return self:FindFirstChild(childName) end
        return model, humanoid, root
    end
    -- The local player and the camera are instances, so a feature can watch
    -- their properties the way it would in the game.
    local player = Instance.new("Player")
    player.Name, player.DisplayName, player.UserId = "Player1", "Player1", 1
    player.CharacterAdded, player.Idled = newSignal(), newSignal()
    player.CameraMaxZoomDistance, player.CameraMinZoomDistance = 128, 0.5
    player.CameraMode = Enum.CameraMode.Classic
    player.Character = character("Player1")
    local camera = Instance.new("Camera")
    camera.CFrame, camera.ViewportSize, camera.FieldOfView = CFrame.identity, Vector2.new(1280, 720), 70
    camera.CameraType, camera.CameraSubject = Enum.CameraType.Custom, player.Character.Humanoid
    camera.ViewportPointToRay = function(_, x, y) return Ray.new(Vector3.new(x, 50, y), Vector3.new(0, -1, 0)) end
    local workspace = Instance.new("Workspace")
    workspace.CurrentCamera = camera
    workspace.Gravity = 196.2
    workspace.StreamingEnabled = false
    workspace.Raycast = function(_, origin, direction)
        return workspace.hit and { Position = workspace.hit, Instance = Instance.new("Part") } or nil
    end
    local lighting = Instance.new("Lighting")
    lighting.Brightness, lighting.ClockTime, lighting.FogEnd, lighting.GlobalShadows = 1, 20, 500, true
    lighting.Ambient, lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 20), Color3.fromRGB(40, 40, 40)
    local others = {}
    services.Players = {
        LocalPlayer = player,
        PlayerAdded = newSignal(),
        PlayerRemoving = newSignal(),
        GetPlayers = function()
            local list = { player }
            for _, other in others do table.insert(list, other) end
            return list
        end,
    }
    services.Workspace = workspace
    services.Lighting = lighting
    services.RunService.PreSimulation = newSignal()
    services.RunService.PreRender = newSignal()
    services.RunService.Stepped = newSignal()
    services.UserInputService = {
        InputBegan = newSignal(),
        InputEnded = newSignal(),
        InputChanged = newSignal(),
        JumpRequest = newSignal(),
        TouchTapInWorld = newSignal(),
        TouchEnabled = false,
        MouseEnabled = true,
        IsKeyDown = function(self, key) return self.down == key end,
        MouseBehavior = Enum.MouseBehavior.Default,
        GetMouseLocation = function() return Vector2.new(640, 360) end,
    }
    services.VirtualUser = {
        CaptureController = function(self) self.captured = true end,
        ClickButton2 = function(self) self.clicks = (self.clicks or 0) + 1 end,
    }
    HARNESS.input = services.UserInputService
    local world = { player = player, camera = camera, workspace = workspace, lighting = lighting, genv = genv }
    function world.join(name)
        local other = { Name = name, DisplayName = name, UserId = #others + 2, CharacterAdded = newSignal() }
        other.Character = character(name)
        table.insert(others, other)
        services.Players.PlayerAdded:Fire(other)
        return other
    end
    function world.leave(other)
        table.remove(others, table.find(others, other))
        services.Players.PlayerRemoving:Fire(other)
    end
    function world.respawn(who)
        local model = character(who.Name)
        who.Character = model
        -- The engine's camera script follows the local player's new body.
        if who == player then camera.CameraSubject = model.Humanoid end
        who.CharacterAdded:Fire(model)
        return model
    end
    function world.key(code, down)
        local signal = if down == false then services.UserInputService.InputEnded else services.UserInputService.InputBegan
        signal:Fire({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }, false)
    end
    return world
end

script = {}
script.Parent = {}
script.Parent.Parent = script.Parent
