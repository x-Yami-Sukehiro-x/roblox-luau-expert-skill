# Input surfaces: mouse, touch, gamepad, console

A Roblox interface is played on four input models and most are built for one.
The failure is rarely "it does not work" — it is that the layout assumed a
cursor, or that nothing is focused when a gamepad player opens a menu and the
menu is simply unusable.

---

## Ask what the player is using, correctly

The common heuristic is wrong:

```lua
-- WRONG - "touch capable" is not "using touch". A Windows laptop with a
-- touchscreen reports both, and a player on a controller reports neither.
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
```

`UserInputService.PreferredInput` is the first-party answer. It is `[ReadOnly]`
and reports what the player is *actually* driving right now:

```lua
local UserInputService = game:GetService("UserInputService")

local function currentInput(): Enum.PreferredInput
    return UserInputService.PreferredInput
end
```

`Enum.PreferredInput` is `KeyboardAndMouse`, `Gamepad`, `Touch` or
`MicroGamepad`. It changes at runtime — a player can pick up a controller
mid-session — so react rather than branching once at startup:

```lua
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(applyInputMode)
```

The `*Enabled` properties still have a use: they answer *capability*, which is
the right question for "should I even build the touch controls". They are the
wrong question for "what should this button's hint glyph say".

`GuiService:IsTenFootInterface()` is a separate axis again — a console rendering
to a television. That changes type size and target size, not input model.

---

## Do not gate on the mouse-only events

`GuiButton.MouseButton1Click` fires for mouse only. `Activated` fires for mouse,
touch, gamepad A **and** keyboard Enter, and it hands you the input that caused
it:

```lua
button.Activated:Connect(function(inputObject: InputObject, clickCount: number)
    if clickCount == 2 then
        openDetail()
        return
    end
    select()
end)
```

Using the mouse-only event is the single most common reason a GUI is dead on
mobile and on console. `SecondaryActivated` is the right-click / equivalent.

`MouseEnter` and `MouseLeave` are genuinely mouse-only, and that is fine — hover
is a mouse concept. What is not fine is making hover the *only* way to reach
something.

---

## Gamepad navigation

Roblox will move a selection box between `GuiObject`s for you, but only if you
tell it what is selectable and where the selection starts.

```lua
local GuiService = game:GetService("GuiService")

for _, button in menu:GetChildren() do
    if button:IsA("GuiButton") then
        button.Selectable = true
        button.SelectionOrder = order[button.Name] or 0
    end
end

-- Something must be focused when the menu opens, or the pad does nothing.
GuiService.SelectedObject = firstButton
```

| Member | Role |
|---|---|
| `GuiObject.Selectable` | Can the selection land here at all |
| `GuiObject.SelectionOrder` | Lower sorts earlier when the engine picks a default |
| `GuiObject.NextSelectionUp` / `Down` / `Left` / `Right` | Explicit adjacency; overrides the automatic guess |
| `GuiObject.SelectionImageObject` | Your own selection highlight instead of the default box |
| `GuiService.SelectedObject` | The currently focused object. Read and write |
| `GuiService.GuiNavigationEnabled` | Master switch for engine-driven navigation |
| `GuiService.AutoSelectGuiEnabled` | Whether the engine picks a default focus on its own |

The automatic adjacency guess is geometric and it is usually right for a grid
and usually wrong for anything else. Set `NextSelection*` explicitly wherever
the reading order is not the spatial order.

### Trapping focus in a modal

There is no `SelectionGroup` property in the current API, and
`GuiService:AddSelectionParent` / `:RemoveSelectionGroup` are **`[Deprecated]`**.
The working approach is to make everything outside the modal unselectable while
it is open, and put focus back where it was on close:

```lua
local function openModal(modal: GuiObject, firstFocus: GuiObject)
    local restore = GuiService.SelectedObject
    local disabled = {}

    for _, d in screenGui:GetDescendants() do
        if d:IsA("GuiObject") and d.Selectable and not d:IsDescendantOf(modal) then
            d.Selectable = false
            table.insert(disabled, d)
        end
    end

    GuiService.SelectedObject = firstFocus

    return function()
        for _, d in disabled do
            d.Selectable = true
        end
        GuiService.SelectedObject = restore
    end
end
```

Return the teardown rather than remembering to undo it at three call sites, and
hand it to the modal's Trove.

**Do not fight the Roblox menu.** `GuiService.MenuIsOpen` is `[ReadOnly]` and
true while the player has the platform menu up. Pause your own input handling
while it is, or you will act on presses the player meant for the menu.

`StarterGui.VirtualCursorMode` (`Default` / `Disabled` / `Enabled`) controls the
gamepad-driven pointer. Enable it deliberately for interfaces that genuinely
need free positioning — a map, a drag surface — and leave it off for menus,
where discrete selection is faster.

---

## Touch

**Targets.** 44 pixels of *effective* size is the floor. Effective means the hit
area, which can be larger than the visual: put the visual inside a transparent
frame that owns the input.

**The corners are taken.** Mobile virtual controls occupy the bottom-left
(movement) and bottom-right (jump). Anything you place there is either unusable
or steals the input. `GuiService.TouchControlsEnabled` tells you whether they are
present, and lets you turn them off if your interface takes over the screen.

**There is no hover.** Every affordance that only appears on hover is invisible
on touch. Tooltips need a long-press equivalent; a delete button that only
appears on row hover needs to be permanently visible or behind a swipe.

**Gestures.** The raw events live on `GuiObject` and each reports an
`Enum.UserInputState`:

| Event | Arguments |
|---|---|
| `TouchTap` | `(touchPositions)` |
| `TouchLongPress` | `(touchPositions, state)` |
| `TouchPan` | `(touchPositions, totalTranslation, velocity, state)` |
| `TouchPinch` | `(touchPositions, scale, velocity, state)` |
| `TouchRotate` | `(touchPositions, rotation, velocity, state)` |
| `TouchSwipe` | `(swipeDirection, numberOfTouches)` |

Gate on the state. Treating every `TouchPinch` fire as a finished gesture makes
zoom jump:

```lua
map.TouchPinch:Connect(function(_, scale, _, state)
    if state == Enum.UserInputState.Change then
        applyZoom(scale)
    elseif state == Enum.UserInputState.End then
        commitZoom()
    end
end)
```

`Enum.UserInputState` also has `Cancel`, which fires when the system takes the
gesture away — a call arriving, the app backgrounding. Treat `Cancel` like a
release that should not commit.

**Touch buttons for actions.** `ContextActionService:BindAction(name, fn, true, ...)`
creates a touch button automatically, and `SetTitle`, `SetImage` and
`SetPosition` style it. That is far less work than a hand-built mobile control,
and it disappears on platforms that do not need it.

---

## Safe areas and the notch

Covered in depth in `scaling-and-dpi.md`. The two properties that belong in any
input discussion:

```lua
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screenGui.ClipToDeviceSafeArea = true
```

`ScreenInsets` keeps content out of the reserved regions.
`ClipToDeviceSafeArea` stops it bleeding under a notch or rounded corner even
visually. `ScreenGui.SafeAreaCompatibility` (`None` / `FullscreenExtension`)
controls how older full-bleed layouts are treated.

---

## One state machine, four skins

The mistake is branching per platform at every call site. Resolve the input mode
once and let components read it:

```lua
local InputMode = {}
InputMode.current = UserInputService.PreferredInput

function InputMode.isPointer(): boolean
    return InputMode.current == Enum.PreferredInput.KeyboardAndMouse
end

function InputMode.isPad(): boolean
    return InputMode.current == Enum.PreferredInput.Gamepad
        or InputMode.current == Enum.PreferredInput.MicroGamepad
end
```

What actually changes between modes is small and worth listing:

| Concern | Mouse | Touch | Gamepad |
|---|---|---|---|
| Primary affordance | hover | permanent | focus ring |
| Minimum target | ~24px | 44px | irrelevant, focus is discrete |
| Dismiss | click outside, Esc | tap outside, back gesture | B button |
| Hints | none | none | glyphs next to actions |
| Tooltips | on hover | on long-press | on focus |

`HoverHapticEffect` and `PressHapticEffect` on `GuiButton` add haptics where the
device supports them — cheap polish on console and mobile, silently ignored
elsewhere.

---

## Checklist

- [ ] `UserInputService.PreferredInput`, not the `TouchEnabled`/`MouseEnabled` heuristic.
- [ ] Reacts to input mode changing mid-session.
- [ ] `Activated`, never `MouseButton1Click`, on anything a non-mouse player must reach.
- [ ] Something is focused when a menu opens on a gamepad.
- [ ] `NextSelection*` set wherever reading order is not spatial order.
- [ ] Modal focus is trapped and restored on close.
- [ ] `MenuIsOpen` respected.
- [ ] 44px effective touch targets; nothing important in the control corners.
- [ ] No affordance reachable only by hover.
- [ ] Gesture handlers branch on `Enum.UserInputState`, including `Cancel`.
- [ ] `ScreenInsets` and `ClipToDeviceSafeArea` set.
