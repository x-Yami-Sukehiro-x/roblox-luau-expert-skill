# Drawing Library (Executor)

Renders directly to the screen with no DataModel presence — nothing for a game to enumerate in `CoreGui` or `PlayerGui`. The default choice for ESP and overlays.

```lua
if typeof(Drawing) ~= "table" or typeof(Drawing.new) ~= "function" then
    return warn("Drawing unsupported on this executor")
end
```

## Constructor

```lua
function Drawing.new(type: string): DrawingObject
```
`type` is one of `"Line"`, `"Text"`, `"Image"`, `"Circle"`, `"Square"`, `"Quad"`, `"Triangle"`.

---

## Properties

### BaseDrawingObject — inherited by every class

| Property | Type |
|---|---|
| `Visible` | boolean |
| `ZIndex` | number |
| `Transparency` | number |
| `Color` | Color3 |
| `Destroy` | function |

### Line
| Property | Type |
|---|---|
| `From` | Vector2 |
| `To` | Vector2 |
| `Thickness` | number |

### Text
| Property | Type |
|---|---|
| `Text` | string |
| `TextBounds` | Vector2 *(read-only)* |
| `Font` | number |
| `Size` | number |
| `Position` | Vector2 |
| `Center` | boolean |
| `Outline` | boolean |
| `OutlineColor` | Color3 |

`TextBounds` updates after `Text` is set — read it to centre or lay out relative to the rendered size.

### Image
| Property | Type |
|---|---|
| `Data` | string |
| `Size` | Vector2 |
| `Position` | Vector2 |
| `Rounding` | number |

`Data` is raw image bytes, not an asset id — read a local file with `readfile` and assign the string.

### Circle
| Property | Type |
|---|---|
| `NumSides` | number |
| `Radius` | number |
| `Position` | Vector2 |
| `Thickness` | number |
| `Filled` | boolean |

`NumSides` controls smoothness. Low values are visibly polygonal; very high values cost frame time when many circles are on screen.

### Square
| Property | Type |
|---|---|
| `Size` | Vector2 |
| `Position` | Vector2 |
| `Thickness` | number |
| `Filled` | boolean |

`Position` is the **top-left corner**, not the centre. Offset by `Size / 2` when centring on a projected point.

### Quad
| Property | Type |
|---|---|
| `PointA` – `PointD` | Vector2 |
| `Thickness` | number |
| `Filled` | boolean |

### Triangle
| Property | Type |
|---|---|
| `PointA` – `PointC` | Vector2 |
| `Thickness` | number |
| `Filled` | boolean |

---

## Helper functions

```lua
function cleardrawcache()
function isrenderobj(object: any): boolean
function getrenderproperty(drawing: DrawingObject, property: string): any
function setrenderproperty(drawing: DrawingObject, property: string, value: any)
```

`getrenderproperty` / `setrenderproperty` reach properties that direct indexing may not expose on some executors. `cleardrawcache` destroys every Drawing object at once — the reliable teardown.

---

## Lifecycle discipline

Drawing objects are **not** garbage-collected with your script. They survive re-execution and stack up across reloads.

```lua
local objects = {}

local function make(kind)
    local obj = Drawing.new(kind)
    table.insert(objects, obj)
    return obj
end

local function unload()
    for _, obj in objects do
        pcall(function() obj:Destroy() end)
    end
    table.clear(objects)
    if typeof(cleardrawcache) == "function" then cleardrawcache() end
end
```

Track every object. Destroy on unload. Orphaned objects are both a memory leak and visible evidence of a previous session.

---

## Screen projection

```lua
local camera = workspace.CurrentCamera
local pos, onScreen = camera:WorldToViewportPoint(worldPosition)
if onScreen then
    obj.Position = Vector2.new(pos.X, pos.Y)
    obj.Visible = true
else
    obj.Visible = false
end
```

`pos.Z` is the depth in studs — divide by it to scale objects with distance. Always set `Visible = false` for off-screen targets rather than moving them off-view; hidden objects skip rendering entirely.

---

## Performance

- Reuse objects across frames. Creating and destroying per frame is the usual cause of ESP-related frame drops.
- Update on `RenderStepped`; anything slower visibly lags behind the camera.
- Cap the number of tracked entities. Fifty players × six objects each is 300 draw calls per frame.
- Prefer Drawing over `BillboardGui` / `Highlight` unless you specifically need 3D world attachment or occlusion.
