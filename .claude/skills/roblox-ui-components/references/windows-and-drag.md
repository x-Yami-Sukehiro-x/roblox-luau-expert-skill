# Draggable windows, panels and handles

Every script hub, every debug overlay and every in-game inventory that lets you
rearrange things needs dragging. Almost every one of them hand-rolls it from
`InputBegan` and a `RenderStepped` loop, gets the pointer-offset maths slightly
wrong, and drops the drag when the cursor leaves the frame.

`UIDragDetector` is first-party and does the hard parts. Reach for it first.

---

## The minimum

```lua
local drag = Instance.new("UIDragDetector")
drag.Parent = window          -- the frame that should MOVE
```

That is a draggable window. The detector moves its **parent**, and by default it
drags anywhere on that parent.

For a title-bar handle — drag by the bar, move the whole window — point the
detector at the thing that moves and use the bar as the input surface:

```lua
local drag = Instance.new("UIDragDetector")
drag.ReferenceUIInstance = titleBar    -- what you grab
drag.DragSpace = Enum.UIDragDetectorDragSpace.Reference
drag.Parent = window                   -- what moves
```

---

## The properties that matter

| Property | Type | Why you care |
|---|---|---|
| `DragStyle` | `Enum.UIDragDetectorDragStyle` | `TranslatePlane` (free), `TranslateLine` (one axis), `Rotate`, `Scriptable` |
| `ResponseStyle` | `Enum.UIDragDetectorResponseStyle` | `Offset` / `Scale` / `CustomOffset` / `CustomScale` — which half of `UDim2` it writes |
| `DragRelativity` | `Enum.UIDragDetectorDragRelativity` | `Absolute` or `Relative` to the parent's own transform |
| `DragSpace` | `Enum.UIDragDetectorDragSpace` | `Parent`, `LayerCollector`, or `Reference` |
| `BoundingUI` | `GuiBase2d?` | Confine the drag to this frame |
| `BoundingBehavior` | `Enum.UIDragDetectorBoundingBehavior` | `Automatic` / `EntireObject` / `HitPoint` |
| `MinDragTranslation` / `MaxDragTranslation` | `UDim2` | Clamp travel |
| `DragAxis` | `Vector2` | The axis for `TranslateLine` |
| `MinDragAngle` / `MaxDragAngle` | number | Clamp for `Rotate` |
| `DragUDim2` / `DragRotation` | `UDim2` / number | Read or write the current drag state |
| `CursorIcon` / `ActivatedCursorIcon` | string | Idle and dragging cursors |
| `Enabled` | boolean | Turn dragging off without unparenting |

**`ResponseStyle` is the one that silently ruins layouts.** `Offset` writes
pixels into `Position.Offset`; `Scale` writes fractions into `Position.Scale`.
If your window is positioned in scale for responsiveness and the detector writes
offset, the window drifts on every viewport change. Match the detector to how
the frame is positioned.

**Confine to the screen, not to nothing:**

```lua
drag.BoundingUI = screenGui                                      -- or a container frame
drag.BoundingBehavior = Enum.UIDragDetectorBoundingBehavior.EntireObject
```

`EntireObject` keeps the whole window on screen. `HitPoint` only keeps the
grabbed point on screen, which lets a window go 95% off the edge — occasionally
what you want for a dock-to-edge feel, usually not.

---

## Events, and the ordering trap

```lua
drag.DragStart:Connect(function(inputPosition: Vector2)
    window.ZIndex = nextTopZIndex()
end)

drag.DragContinue:Connect(function(inputPosition: Vector2)
    -- Fires every frame while dragging. Keep this cheap.
end)

drag.DragEnd:Connect(function(inputPosition: Vector2)
    saveWindowPosition(window.Position)
end)
```

`DragContinue` runs at frame rate. Writing to a DataStore, rebuilding a layout,
or measuring text in it will cost you the frame. Do the work in `DragEnd`.

---

## Raising the window on grab

A window manager needs the grabbed window to come to the front. With
`ZIndexBehavior.Sibling` — the default — a window's `ZIndex` orders it against
its siblings, so keep a counter:

```lua
local topZ = 10

local function raise(w: GuiObject)
    topZ += 1
    w.ZIndex = topZ
end
```

If windows live in separate `ScreenGui` instances instead, order them with
`ScreenGui.DisplayOrder` and raise that. Do not mix the two schemes — a
`DisplayOrder` difference beats any `ZIndex` inside, and debugging a window that
will not come forward because of a `DisplayOrder` you forgot is a bad afternoon.

---

## Resize handles

There is no first-party resize detector. Build one from a drag detector in
`Scriptable` style, or from raw input on a corner grip.

```lua
local MIN = Vector2.new(220, 140)

local grip = Instance.new("Frame")          -- bottom-right corner, ~14x14
grip.AnchorPoint = Vector2.new(1, 1)
grip.Position = UDim2.fromScale(1, 1)
grip.Size = UDim2.fromOffset(14, 14)
grip.BackgroundTransparency = 1
grip.Parent = window

local resizer = Instance.new("UIDragDetector")
resizer.DragStyle = Enum.UIDragDetectorDragStyle.Scriptable
resizer.Parent = grip

local startSize, startDrag
resizer.DragStart:Connect(function(inputPosition)
    startSize = window.AbsoluteSize
    startDrag = inputPosition
end)

resizer.DragContinue:Connect(function(inputPosition)
    local delta = inputPosition - startDrag
    window.Size = UDim2.fromOffset(
        math.max(MIN.X, startSize.X + delta.X),
        math.max(MIN.Y, startSize.Y + delta.Y)
    )
end)
```

`Scriptable` tells the detector not to move anything itself — you get the input
stream and decide. That is also how you implement snapping, magnetism to screen
edges, or a drag that scrubs a value instead of moving a frame.

**Enforce a minimum size.** A window that can be resized to zero cannot be
resized back, because the grip has gone with it.

---

## Touch and gamepad

A drag detector handles mouse and touch. Two things it does not solve:

**Touch targets.** A 14-pixel corner grip is unusable with a thumb. Give the
grip an invisible larger hit area, or expose resize through a menu on touch:

```lua
grip.Size = UDim2.fromOffset(28, 28)      -- hit area
-- draw the visible 14x14 chevron as a child, centred
```

**Gamepad has no pointer.** Dragging is not a gamepad interaction. On console,
either fix the layout or offer discrete "move window" commands bound to the
D-pad while the window is selected. `GuiService:IsTenFootInterface()` tells you
when you are in that world.

For gesture handling beyond drag — pinch to zoom a map, two-finger pan — the
raw events are on `GuiObject`: `TouchPan`, `TouchPinch`, `TouchRotate`,
`TouchSwipe`, `TouchTap`, `TouchLongPress`. Each reports an
`Enum.UserInputState`, so gate on `Change` and `End` rather than treating every
fire as a completed gesture.

---

## Persisting position

A hub window that forgets where you put it is worse than one that never moved.

```lua
drag.DragEnd:Connect(function()
    Config.set("window.main.position", {
        x = window.Position.X.Offset,
        y = window.Position.Y.Offset,
    })
end)
```

On restore, **clamp into the current viewport before applying**. A position saved
on a 2560-wide monitor puts the window off-screen on a laptop, and the player
cannot drag back something they cannot see.

```lua
local viewport = workspace.CurrentCamera.ViewportSize
local saved = Config.get("window.main.position")
if saved then
    window.Position = UDim2.fromOffset(
        math.clamp(saved.x, 0, math.max(0, viewport.X - window.AbsoluteSize.X)),
        math.clamp(saved.y, 0, math.max(0, viewport.Y - window.AbsoluteSize.Y))
    )
end
```

Config persistence for hub UI is covered in `roblox-ui/references/gui-architecture.md`.

---

## Checklist

- [ ] `UIDragDetector` rather than a hand-rolled input loop.
- [ ] `ResponseStyle` matches how the frame is positioned (scale vs offset).
- [ ] `BoundingUI` set, with `EntireObject`, so a window cannot be lost off-screen.
- [ ] Raise on `DragStart` via one counter; `ZIndex` or `DisplayOrder`, not both.
- [ ] `DragContinue` does no expensive work; persistence happens in `DragEnd`.
- [ ] Resize enforces a minimum size.
- [ ] Grips have a touch-sized hit area larger than their visual.
- [ ] Restored positions are clamped into the current viewport.
- [ ] Console has a path that does not require a pointer.
