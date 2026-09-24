# Particles, beams, trails and highlights

Every class here creates something that outlives the frame that made it. The
whole file is about who owns that lifetime.

---

## `ParticleEmitter`

An emitter lives on a `BasePart` or an `Attachment` and emits from it. Two
distinct modes:

```lua
-- Continuous: Rate particles per second while Enabled.
emitter.Rate = 20
emitter.Enabled = true

-- Burst: N particles right now, regardless of Rate or Enabled.
emitter:Emit(35)
```

**`Emit` works while `Enabled = false`.** That is the correct shape for an
impact effect: a permanently-disabled emitter parked on the weapon, burst on
hit. No spin-up, no leak, no per-hit instance creation.

### The properties that decide how it looks

| Property | Type | Note |
|---|---|---|
| `Rate` | number | Per second. Multiply by `Lifetime` for the live count |
| `Lifetime` | `NumberRange` | A range, not a number. Equal min and max looks mechanical |
| `Speed` | `NumberRange` | Initial speed along `EmissionDirection` |
| `SpreadAngle` | `Vector2` | Degrees, X and Y. Zero is a laser, 180 is a sphere |
| `Size` | `NumberSequence` | Over each particle's own life |
| `Transparency` | `NumberSequence` | **Start and end at 1** — see below |
| `Color` | `ColorSequence` | Over life |
| `Rotation` / `RotSpeed` | `NumberRange` | Randomised spin |
| `Acceleration` | `Vector3` | Gravity, wind |
| `Drag` | number | Slows over life. Cheap realism |
| `LightEmission` | 0–1 | How much it ignores scene lighting. 1 reads as glowing |
| `LightInfluence` | 0–1 | How much scene lighting tints it |
| `ZOffset` | number | Push toward or away from camera to fix sorting |
| `Shape`, `ShapeStyle`, `ShapeInOut`, `ShapePartial` | enums | Volume emission |
| `FlipbookLayout`, `FlipbookMode`, `FlipbookFramerate` | | Sprite-sheet animation |

**Particles that pop are the giveaway.** A `Transparency` sequence that starts
at 0 makes every particle appear at full opacity instantly. Fade in and out:

```lua
emitter.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),      -- invisible at birth
    NumberSequenceKeypoint.new(0.15, 0.2), -- fade in fast
    NumberSequenceKeypoint.new(0.7, 0.3),  -- hold
    NumberSequenceKeypoint.new(1, 1),      -- fade out
})
```

Same reasoning for `Size` — particles that spring into existence at full size
look stamped on. A `NumberSequence` from a small value up and back down reads as
motion.

**`Lifetime` as a real range.** `NumberRange.new(0.6, 1.1)` desynchronises the
particles so they do not die in unison. `NumberRange.new(1, 1)` is the
single most recognisable "default emitter" tell after the flat transparency.

### Killing an emitter without killing the particles

```lua
-- WRONG - every particle in flight vanishes mid-air
emitter:Destroy()

-- RIGHT - stop emitting, let what exists finish, then clean up
emitter.Enabled = false
Debris:AddItem(emitter, emitter.Lifetime.Max)
```

`Debris:AddItem(instance, seconds)` is exactly the tool here: it schedules the
destroy without a thread you have to own. For anything more structured, put the
emitter in a Trove.

### Budget

Roughly `Rate * Lifetime.Max` particles are alive per emitter. Ten emitters at
`Rate = 50` and `Lifetime.Max = 2` is a thousand particles, and mobile GPUs pay
per particle in overdraw — a large, near-transparent particle costs far more
than its pixel count suggests.

Practical ceilings: keep steady-state particles in the low hundreds on a busy
screen, prefer a few large sprites over many small ones, and never scale an
effect's `Rate` with player count without a cap.

---

## Pooling

Anything spawning more than a few times a second should be reused rather than
created:

```lua
local Pool = {}
Pool.__index = Pool

function Pool.new(template: Instance, size: number)
    local self = setmetatable({ _template = template, _free = {} }, Pool)
    for _ = 1, size do
        local item = template:Clone()
        item.Parent = nil
        table.insert(self._free, item)
    end
    return self
end

function Pool:take(parent: Instance)
    local item = table.remove(self._free) or self._template:Clone()
    item.Parent = parent
    return item
end

function Pool:give(item: Instance, delay: number?)
    task.delay(delay or 0, function()
        if not item.Parent then return end      -- already destroyed
        item.Parent = nil
        table.insert(self._free, item)
    end)
end
```

`Instance.new` and `Clone` are not free, and neither is destroying. A pool turns
a per-hit allocation into a table pop.

**Reset state on `take`.** A pooled emitter that kept `Enabled = true` from its
last use starts emitting the moment it is parented.

---

## `Beam`

A beam draws between two `Attachment`s. It does not have a position of its own —
move the attachments.

```lua
local beam = Instance.new("Beam")
beam.Attachment0 = originAttachment
beam.Attachment1 = targetAttachment
beam.Width0 = 0.6
beam.Width1 = 0.15
beam.FaceCamera = true          -- almost always what you want
beam.Segments = 10
beam.CurveSize0 = 0
beam.CurveSize1 = 0
beam.Texture = "rbxassetid://..."
beam.TextureMode = Enum.TextureMode.Wrap
beam.TextureSpeed = 2           -- scrolls along the beam
beam.LightEmission = 1
beam.Parent = originAttachment
```

- **`FaceCamera = false` gives a flat ribbon** that disappears edge-on. Set it
  true unless you specifically want a ribbon with a fixed orientation.
- **`CurveSize0` / `CurveSize1` bend it** into a bezier — a tether, a lightning
  arc, a grapple line. Zero is a straight line.
- **`Segments` costs.** Ten is plenty for a straight beam; raise it only when
  curving.
- **`TextureSpeed` animates without any script.** Scrolling a texture along the
  beam is free motion; a `RenderStepped` loop moving attachments is not.

## `Trail`

A trail follows two attachments as they move, drawing the swept area between
them. Put both on the same moving part — tip and base of a sword, wingtips.

```lua
trail.Attachment0 = tip
trail.Attachment1 = base
trail.Lifetime = 0.35           -- how long the ribbon persists behind
trail.MinLength = 0.1
trail.FaceCamera = true
trail.Enabled = false           -- on only during the swing
```

`Trail.Lifetime` is a plain number here, unlike `ParticleEmitter.Lifetime` which
is a `NumberRange`. Enable on the swing's start marker and disable on its end
marker — see `animation.md`.

## `Highlight`

An outline and fill on a whole model, drawn without touching materials.

```lua
local highlight = Instance.new("Highlight")
highlight.Adornee = model
highlight.FillColor = Color3.fromRGB(255, 220, 120)
highlight.FillTransparency = 0.8
highlight.OutlineColor = Color3.fromRGB(255, 245, 200)
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = model
```

`DepthMode` is the whole decision:

- `AlwaysOnTop` — visible through walls. Objectives, teammates, the thing the
  tutorial is pointing at.
- `Occluded` — hidden behind geometry. Interaction targets, selection.

**There is a hard engine limit on simultaneous highlights** (in the low
hundreds; the exact figure has moved between releases). Past it, highlights
silently stop rendering. Do not put one on every item in a large world — attach
it to the thing currently under the cursor and move the `Adornee`.

`Highlight` is a cheap, correct answer to "make this object stand out" that
people reach for `SelectionBox` or a duplicated glowing mesh to solve.

---

## Replication

Effects created on the server replicate to every client, cost bandwidth, and
appear one round trip late. Effects created on a client are free and instant and
only that client sees them.

The pattern that gets both:

```lua
-- Server: decide the outcome, tell everyone where.
ImpactEvent:FireAllClients(position, normal, materialKind)

-- Client: build the effect locally.
ImpactEvent.OnClientEvent:Connect(function(position, normal, materialKind)
    local emitter = impactPool:take(worldAttachmentAt(position, normal))
    emitter:Emit(PROFILES[materialKind].count)
    impactPool:give(emitter, PROFILES[materialKind].lifetime)
end)
```

Rules that follow:

- **The server sends facts, not instances.** A position and a kind, not a
  cloned emitter.
- **The effect is cosmetic.** Damage was already decided server-side. A client
  that never renders the effect takes the same damage.
- **Rate-limit the remote.** An effect event fired per bullet per player is a
  bandwidth problem before it is a visual one. Batch, or drop effects beyond a
  per-frame cap.
- **Cull by distance.** A client does not need particles for something 500 studs
  away. Check before building.

---

## Common failures

**An emitter parented to a destroyed part.** The part goes, the emitter goes,
particles vanish. Parent impact effects to a temporary attachment in
`workspace.Terrain` or a dedicated effects folder, not to the thing that just
exploded.

**`Rate` left on.** An emitter cloned from a template that had `Enabled = true`
and `Rate = 100`, parented and never disabled, emits until the server restarts.

**Per-frame `NumberSequence` rebuilds.** Constructing a `ColorSequence` or
`NumberSequence` every frame to animate an effect allocates hard. Build the
sequences once; animate `Transparency` on the parent, or swap between
pre-built sequences.

**Effects in `ReplicatedStorage` referenced by the client.** Fine, and worth
knowing: the client can read everything there. Effect templates are not secret,
so this is the right place for them — unlike anything gameplay-relevant. See
`roblox-architecture`.

**No cap on concurrent effects.** Twenty players using an ability at once
produces twenty times the effect. Cap the number of simultaneous instances of
any one effect and drop the excess; nobody can distinguish twenty explosions
from six.

---

## Checklist

- [ ] Every emitter, beam, trail and highlight has an owner and a death.
- [ ] `Enabled = false` then `Debris:AddItem`, never a bare `Destroy` on a live emitter.
- [ ] `Transparency` and `Size` sequences fade in and out; nothing pops.
- [ ] `Lifetime` is a real range, not equal min and max.
- [ ] Impact effects burst from a parked disabled emitter via `Emit`.
- [ ] Anything spawning frequently is pooled, and pooled state is reset on take.
- [ ] `Beam.FaceCamera` set deliberately.
- [ ] `Highlight.DepthMode` chosen, and the count bounded.
- [ ] The server sends facts; clients build their own effects.
- [ ] Effect remotes are rate-limited and distance-culled.
- [ ] Concurrent effect instances are capped.
