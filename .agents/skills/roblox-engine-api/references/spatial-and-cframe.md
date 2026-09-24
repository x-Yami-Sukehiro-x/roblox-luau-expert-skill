# Spatial queries and CFrame

Method signatures below are verbatim from `tools/api-dump/API-Dump.txt`
(`WorldRoot` — the class `Workspace` inherits from, so all of these are
`workspace:Method(...)`).

`RaycastParams`, `OverlapParams`, `RaycastResult` and `CFrame` are **datatypes**,
and the API dump contains classes and enums only — it has no datatype entries
at all. Those come from `tools/api-dump/datatypes/`, vendored from Roblox's own
datatype reference. `node tools/bin/verify-api.mjs RaycastParams` resolves them
and reports which source answered.

---

## Raycasting

```lua
Raycast(origin: Vector3, direction: Vector3, raycastParams: RaycastParams?) -> RaycastResult?
```

**`direction` carries the length.** It is not normalized internally — the ray
stops at `origin + direction`. A unit vector casts one stud.

```lua
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { character }
params.IgnoreWater = true
params.RespectCanCollide = true          -- skip CanCollide = false parts
params.BruteForceAllSlow = false

local result = workspace:Raycast(origin, direction.Unit * 500, params)
if result then
    print(result.Instance, result.Position, result.Normal, result.Material, result.Distance)
end
```

`RaycastResult` fields: `Instance`, `Position`, `Normal`, `Material`,
`Distance`. The result is nil when nothing is hit — always branch.

`FilterType` is `Exclude` or `Include`. The old names `Blacklist`/`Whitelist`
are the deprecated spelling.

**Reuse `RaycastParams`.** Constructing one per cast in a per-frame loop is
wasteful; mutate `FilterDescendantsInstances` on a cached instance instead.

**Deprecated, do not write:** `FindPartOnRay`, `FindPartOnRayWithIgnoreList`,
`FindPartOnRayWithWhitelist`, `FindPartsInRegion3` and its variants. All still
present in the API, all flagged `[Deprecated]`, all superseded by the calls on
this page.

---

## Shapecasts

Same shape as a raycast, but sweeping a volume. All return `RaycastResult?`.

```lua
Blockcast(cframe: CFrame, size: Vector3, direction: Vector3, params: RaycastParams?) -> RaycastResult?
Spherecast(position: Vector3, radius: number, direction: Vector3, params: RaycastParams?) -> RaycastResult?
Shapecast(part: BasePart, direction: Vector3, params: RaycastParams?) -> RaycastResult?
```

Use these instead of firing five rays in a fan. A `Spherecast` for a projectile
with volume is both more correct and cheaper than a ray plus a radius fudge.

`Shapecast` takes the geometry from an existing part, so a complex hitbox does
not need to be approximated.

---

## Overlap queries

```lua
GetPartBoundsInBox(cframe: CFrame, size: Vector3, overlapParams: OverlapParams?) -> { BasePart }
GetPartBoundsInRadius(position: Vector3, radius: number, overlapParams: OverlapParams?) -> { BasePart }
GetPartsInPart(part: BasePart, overlapParams: OverlapParams?) -> { BasePart }
```

`GetPartBounds*` test **bounding boxes**, which is fast and approximate.
`GetPartsInPart` tests actual geometry, which is accurate and slower. Pick
deliberately: an explosion radius wants bounds, a precise trigger volume wants
`GetPartsInPart`.

```lua
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.FilterDescendantsInstances = { attacker }
overlap.MaxParts = 50                    -- 0 means unlimited; cap it
overlap.RespectCanCollide = false

for _, part in workspace:GetPartBoundsInRadius(blastCentre, 20, overlap) do
    local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then ... end
end
```

**Set `MaxParts`.** The default is unlimited, and one query inside a crowd can
return thousands of parts.

**A character returns many parts.** Deduplicate by `Model` before applying
damage, or one explosion hits a player fifteen times.

```lua
local hitModels: { [Model]: true } = {}
for _, part in parts do
    local model = part:FindFirstAncestorOfClass("Model")
    if model and not hitModels[model] then
        hitModels[model] = true
        applyDamage(model)
    end
end
```

---

## `.Touched` is not a spatial query

`.Touched` fires from the physics solver. It requires both parts to be
`CanTouch`, fires many times per contact, misses fast-moving parts entirely
(tunnelling), and does not fire between two anchored parts.

Use it for "something bumped this", never for "is anything inside this volume".
For the latter, use an overlap query on a timer, or `GetPartsInPart`.

If you do use it, debounce, and never yield inside the handler:

```lua
local touchDebounce: { [BasePart]: number } = {}

part.Touched:Connect(function(hit)
    local now = os.clock()
    if touchDebounce[hit] and now - touchDebounce[hit] < 0.5 then return end
    touchDebounce[hit] = now
    task.spawn(handleTouch, hit)
end)
```

---

## CFrame

A `CFrame` is a position plus a 3×3 rotation. It is the right type for anything
oriented; `Vector3` alone loses the facing.

```lua
CFrame.new(position)
CFrame.new(x, y, z)
CFrame.lookAt(from, target, up?)          -- faces `target`
CFrame.fromEulerAnglesXYZ(rx, ry, rz)     -- radians
CFrame.Angles(rx, ry, rz)                 -- same thing, XYZ order
CFrame.fromAxisAngle(axis, angle)
CFrame.fromMatrix(pos, right, up, back?)
CFrame.identity
```

### Composition order matters

<!-- lint: fragment -->
```lua
cf * offset      -- offset is applied in cf's LOCAL space
offset * cf      -- offset is applied in WORLD space
```

This is the single most common CFrame confusion. "Move the gun 2 studs forward
from where the character is facing" is local:

```lua
local muzzle = root.CFrame * CFrame.new(0, 0, -2)     -- -Z is forward
```

"Rotate around the world Y axis regardless of facing" is world:

```lua
local spun = CFrame.Angles(0, math.rad(90), 0) * part.CFrame
```

### Useful members

<!-- lint: fragment -->
```lua
cf.Position          -- Vector3
cf.LookVector        -- forward, equals -Z axis
cf.RightVector       -- +X
cf.UpVector          -- +Y
cf.Rotation          -- rotation only, position zeroed
cf:Inverse()
cf:ToWorldSpace(other)
cf:ToObjectSpace(other)
cf:PointToWorldSpace(v3)
cf:PointToObjectSpace(v3)
cf:VectorToWorldSpace(v3)      -- rotation only, ignores translation
cf:Lerp(goal, alpha)
cf:ToEulerAnglesXYZ()          -- returns three numbers
cf:GetComponents()             -- 12 numbers
cf:Orthonormalize()
```

**`-Z` is forward in Roblox.** `LookVector` is `-Z`, which is why muzzle offsets
use a negative Z.

### Things that go wrong

**Setting `Position` on a part with a rotation loses nothing; setting `CFrame`
replaces both.** Mixing them mid-update produces a part that snaps orientation.

**Repeated multiplication drifts.** Accumulating thousands of small rotations
denormalizes the matrix. Rebuild from a canonical source periodically, or call
`Orthonormalize()`.

**Euler angles are order-dependent and gimbal-locked.** For interpolation use
`:Lerp()` on CFrames, not lerped Euler triples.

**`CFrame.lookAt` errors when `from == target`** (zero direction), and behaves
badly when the direction is parallel to `up`. Guard both:

```lua
local direction = target - from
if direction.Magnitude < 1e-4 then return end
local cf = CFrame.lookAt(from, target)
```

**Moving a welded assembly by setting a child's CFrame fights the welds.** Set
the `PrimaryPart`'s CFrame, or use `Model:PivotTo(cframe)`, which moves the whole
model coherently:

```lua
model:PivotTo(CFrame.new(spawnPosition))
local pivot = model:GetPivot()
```

`PivotTo` / `GetPivot` replaced `SetPrimaryPartCFrame` / `GetPrimaryPartCFrame`
and work without a `PrimaryPart` set.

---

## Vector3 notes

```lua
Vector3.new(x, y, z)
Vector3.zero, Vector3.one, Vector3.xAxis, Vector3.yAxis, Vector3.zAxis
v.Magnitude, v.Unit
v:Dot(other), v:Cross(other), v:Lerp(other, alpha)
v:FuzzyEq(other, epsilon?)
```

**`.Unit` on a zero vector produces NaN.** Check `Magnitude` first — this is a
frequent source of parts vanishing to a NaN position.

```lua
local delta = target - origin
local direction = if delta.Magnitude > 1e-6 then delta.Unit else Vector3.zAxis
```

**Compare squared magnitudes** when you only need an ordering or a threshold —
it skips a square root:

<!-- lint: fragment -->
```lua
if (a.Position - b.Position).Magnitude <= RANGE then          -- one sqrt
-- in a hot loop, prefer:
local offset = a.Position - b.Position
if offset:Dot(offset) <= RANGE * RANGE then
```
