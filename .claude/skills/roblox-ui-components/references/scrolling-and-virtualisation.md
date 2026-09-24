# Scrolling frames and virtualised lists

Two separate topics that arrive together: configuring a `ScrollingFrame` so it
behaves, and not building four hundred of them.

---

## Configuring a `ScrollingFrame`

```lua
local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()                                   -- let the layout decide
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = Tokens.color.scrollbar
list.ScrollBarImageTransparency = 0.4
list.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar     -- see below
list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
```

| Property | Why it matters |
|---|---|
| `AutomaticCanvasSize` | Sizes the canvas from content. Set `CanvasSize` to zero on that axis or they fight |
| `ScrollingDirection` | Locks the axis. A list that scrolls sideways by a pixel feels broken |
| `VerticalScrollBarInset` | **The number one layout surprise.** `None` overlays content; `ScrollBar` reserves space; `Always` reserves it even when not scrollable |
| `VerticalScrollBarPosition` | `Right` or `Left` |
| `ElasticBehavior` | `WhenScrollable` prevents rubber-banding on a list that fits |
| `ScrollingEnabled` | Freeze scroll without hiding the frame |
| `CanvasPosition` | Read and write. This is scroll-to-item |
| `AbsoluteWindowSize` / `AbsoluteCanvasSize` | `[ReadOnly]`. Viewport and content extents |
| `TopImage` / `MidImage` / `BottomImage` | Custom three-slice scrollbar |

**`VerticalScrollBarInset` is worth internalising.** The default overlays the
bar on top of your content, so a row's right edge sits underneath it. If your
rows have anything on the right — a count, a chevron, a delete button — set
`ScrollBar` and get the space reserved.

> `SmoothScroll`, `ScrollVelocity`, `ScrollRate` and `MaxCanvasPosition` all
> exist in the dump and are all `{RobloxScript}`. A normal LocalScript cannot
> touch them, whatever a tutorial says.

### Scroll to an item

```lua
local function scrollTo(row: GuiObject)
    local top = row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y
    local target = math.clamp(
        top - (list.AbsoluteWindowSize.Y - row.AbsoluteSize.Y) / 2,
        0,
        math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
    )
    TweenService:Create(list, MOTION.travel, { CanvasPosition = Vector2.new(0, target) }):Play()
end
```

`AbsolutePosition` is measured in screen space, so the current `CanvasPosition`
has to be added back to get canvas space. Getting that wrong is why "scroll to
selected" jumps to the wrong place after the list has been scrolled once.

**`AbsolutePosition` and `AbsoluteSize` are zero on the frame an object is
created.** Layout has not run. Reading them in the same frame you parent
something gives you nothing — wait a frame, or drive from the layout's
`AbsoluteContentSize`.

---

## When to virtualise

Not at fifty rows. Probably at five hundred.

A `ScrollingFrame` holding N rows costs N times whatever a row costs, on every
frame, whether or not the row is on screen. A row is rarely one instance: a
frame, a label, an icon, a stroke, a corner and a padding is six, so a
400-row inventory is 2,400 instances.

Signals you have crossed the line:

- Opening the list drops frames.
- Memory climbs by megabytes when the panel opens and does not come back.
- The list takes visible time to build.

Before virtualising, try the cheaper fixes: fewer instances per row, `UIShadow`
instead of a shadow image, one `UIGradient` on the container rather than one per
row, and `Visible = false` on rows below the fold.

---

## The technique

Keep a pool of visible rows sized to the window plus a small overscan, and
re-point them at different data as the canvas moves. Row instances are recycled;
only their content changes.

```lua
local ROW_HEIGHT = 36
local OVERSCAN = 3          -- rows rendered beyond each edge

local pool = {}             -- reusable row instances
local bound = {}            -- rowInstance -> data index currently shown

local function ensureCanvas(count: number)
    -- Virtualised: nothing sizes the canvas for us, so we assert the height.
    list.AutomaticCanvasSize = Enum.AutomaticSize.None
    list.CanvasSize = UDim2.fromOffset(0, count * ROW_HEIGHT)
end

local function visibleRange(count: number): (number, number)
    local top = list.CanvasPosition.Y
    local height = list.AbsoluteWindowSize.Y

    local first = math.max(1, math.floor(top / ROW_HEIGHT) + 1 - OVERSCAN)
    local last = math.min(count, math.ceil((top + height) / ROW_HEIGHT) + OVERSCAN)
    return first, last
end

local function render(data: { any })
    local first, last = visibleRange(#data)
    local needed = last - first + 1

    while #pool < needed do
        table.insert(pool, createRow(list))
    end

    for offset = 0, needed - 1 do
        local index = first + offset
        local row = pool[offset + 1]

        row.Visible = true
        row.Position = UDim2.fromOffset(0, (index - 1) * ROW_HEIGHT)

        if bound[row] ~= index then
            bindRow(row, data[index])          -- only touch the row when it changed
            bound[row] = index
        end
    end

    for i = needed + 1, #pool do
        pool[i].Visible = false
        bound[pool[i]] = nil
    end
end

list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    render(currentData)
end)
```

Four things that make this correct rather than a sketch:

- **No `UIListLayout`.** Rows are positioned absolutely from their index. A
  layout would try to arrange the pool in pool order, which is not data order.
- **`AutomaticCanvasSize` is off** and the canvas height is asserted from the
  row count. Nothing is there to measure.
- **`bound` guards the rebind.** Without it every scroll event rewrites every
  visible row's text, which is most of the cost you were trying to avoid.
- **Overscan.** Without a few rows beyond each edge, fast scrolling shows blank
  strips while the next frame catches up.

### Variable row heights

The version above assumes a fixed `ROW_HEIGHT`, which is what makes the index
maths a division. Variable heights need a prefix-sum array of offsets and a
binary search to find the first visible index. Build the offset table once when
the data changes, not per frame.

If rows are variable because they hold wrapped text, measure with
`TextService:GetTextBoundsAsync` at data-load time and cache the result — see
`roblox-ui/references/typography.md`. Do not measure during scroll.

---

## Cleanup

A recycled row keeps its connections. Bind handlers **once** when the row is
created, and have them read the row's current index from state:

```lua
local function createRow(parent: Instance): GuiObject
    local row = rowTemplate:Clone()
    row.Parent = parent

    row.Button.Activated:Connect(function()
        local index = bound[row]
        if index then
            onSelect(currentData[index])
        end
    end)

    return row
end
```

Connecting inside `bindRow` instead adds one connection per row per scroll
event. That is the classic leak in every hand-rolled virtual list: it works, it
gets faster than the naive version, and it grows a connection table until the
session dies.

---

## Checklist

- [ ] `AutomaticCanvasSize` on with `CanvasSize` zeroed, or off with the height asserted — never both fighting.
- [ ] `VerticalScrollBarInset` chosen deliberately.
- [ ] `ScrollingDirection` locked to the axis you meant.
- [ ] No `{RobloxScript}` scroll property in the code.
- [ ] `AbsoluteSize` not read on the creation frame.
- [ ] Virtualisation only after cheaper per-row savings were taken.
- [ ] Recycled rows rebind content, not connections.
- [ ] A rebind guard so scrolling does not rewrite every visible row.
- [ ] Overscan on both edges.
