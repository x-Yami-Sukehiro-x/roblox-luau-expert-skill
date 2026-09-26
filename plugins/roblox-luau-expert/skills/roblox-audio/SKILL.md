---
name: roblox-audio
description: Roblox sound - Sound versus AudioPlayer and Wire graphs, music, effects, volume sliders, mixing, rolloff, footsteps. Use for any audio question.
---

# Audio

Two complete systems ship side by side. Knowing which one you are in is the
first decision, and the engine itself now labels the older one: every `Sound`
member carries the capability tag **`LegacySound`**, while the new graph classes
carry `Audio`.

---

## Load a reference when

| Need | File |
|---|---|
| the `AudioPlayer` / `Wire` graph, effects, buses | `references/audio-graph.md` |

---

## Which system

| | `Sound` (legacy) | `AudioPlayer` + `Wire` |
|---|---|---|
| Routing | Implicit, from `Parent` and `SoundGroup` | Explicit, one `Wire` per connection |
| Effects | A few `SoundEffect` children | Full graph: reverb, EQ, compressor, limiter, filter, pitch shift, analyzer |
| Per-player output | Not directly expressible | `AudioDeviceOutput.Player` |
| Positional | `Sound` under a `BasePart` | `AudioEmitter` + `AudioListener` |
| Occlusion / diffraction | `AcousticSimulationEnabled` only | Per-emitter `OcclusionEnabled`, `DiffractionEnabled`, `ReverbEnabled` |
| Complexity | Low | Real, and it buys real things |

**`Sound` is not deprecated and is the right answer for most games.** A UI click,
a footstep, a pickup chime — reaching for a node graph to play a 200ms sample is
over-engineering. Use `AudioPlayer` when you need something the legacy path
cannot express: per-player mixes, a real effects chain, voice, or analysis.

---

## Parenting decides everything

This is the fact that explains most "why is my sound 2D" and "why can everyone
hear it" confusion:

| `Sound.Parent` | Result |
|---|---|
| A `BasePart` or `Attachment` | **3D positional.** Attenuates with distance from that point |
| `SoundService` | **2D.** Same volume everywhere. Music, UI |
| A `GuiObject` | 2D |
| `nil` | Plays nowhere |

```lua
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://1234567"
sound.RollOffMode = Enum.RollOffMode.InverseTapered
sound.RollOffMinDistance = 8      -- full volume within this
sound.RollOffMaxDistance = 90     -- silent past this
sound.Parent = part               -- positional, because of this line
sound:Play()
```

`RollOffMinDistance` and `RollOffMaxDistance` are the live properties.
`MinDistance`, `MaxDistance`, `EmitterSize` and `Pitch` are all `[Deprecated]`
and most are `[LoadOnly]` — `PlaybackSpeed` replaces `Pitch`.

---

## Fire-and-forget one-shots

The naive one-shot leaks: create a sound, play it, and nothing destroys it.

```lua
-- WRONG - one orphaned instance per shot, forever
local s = Instance.new("Sound")
s.SoundId = id
s.Parent = part
s:Play()

-- RIGHT - the engine plays it as it is destroyed
local s = Instance.new("Sound")
s.SoundId = id
s.PlayOnRemove = true
s.Parent = part
s:Destroy()                  -- plays *because* of this
```

`PlayOnRemove` fires the sound at the moment the instance is destroyed, so
there is nothing left to clean up and nothing to forget. It is the correct shape
for impacts, pickups and gunshots.

For sounds you need to control while they play, own the lifetime explicitly:

```lua
sound.Ended:Once(function()
    sound:Destroy()
end)
```

`Ended` does not fire for a looped sound. A looped sound needs an owner — a
Trove tied to whatever the loop belongs to.

---

## Where to create it

| Situation | Create it |
|---|---|
| Only this player should hear it | Client |
| Everyone near a world event should hear it | Server, parented to the part |
| Everyone should hear it, position does not matter | Server, but consider a remote |

A `Sound` created on the server and parented into the world replicates and
plays for everyone. That is usually right for a world event and wasteful for UI.

Audio the local player alone should hear — their own UI, their own footsteps in
first person — belongs on the client. Creating it on the server means everyone
hears everyone's menu clicks.

---

## Standing rules

1. **Parent decides 2D versus 3D.** Not a property.
2. **`PlayOnRemove` for one-shots.** No instance survives, so none leaks.
3. **Every looped sound has an owner** that stops and destroys it.
4. **Preload before a moment that must not stutter.** First play of an
   unloaded asset hitches — `ContentProvider:PreloadAsync`.
5. **Route through `SoundGroup`s**, never set `Volume` on individual sounds from
   a settings menu.
6. **Never trust a client-reported sound** for anything gameplay-relevant.
7. **`RollOffMinDistance` / `RollOffMaxDistance` / `PlaybackSpeed`**, not the
   `[Deprecated]` `MinDistance` / `MaxDistance` / `Pitch`.
8. **Respect the player.** Provide volume controls and honour muting; audio that
   cannot be turned down gets the game closed.

## Works with

- `roblox-ui-components`: volume sliders and mute toggles from the tested recipes.
- `roblox-performance`: preloading and how many sounds play at once.
- `roblox-networking`: which side plays a sound so others hear it.
- `roblox-combat`: layered hit sounds scaled by how big the moment is.
