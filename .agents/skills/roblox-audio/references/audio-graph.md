# Mixing, buses and the `AudioPlayer` graph

---

## Legacy mixing with `SoundGroup`

A `SoundGroup` is a bus. Sounds routed to it are attenuated by its `Volume`, and
groups nest.

```lua
local SoundService = game:GetService("SoundService")

local master = Instance.new("SoundGroup")
master.Name = "Master"
master.Parent = SoundService

local function bus(name: string): SoundGroup
    local group = Instance.new("SoundGroup")
    group.Name = name
    group.Parent = master          -- nesting is what makes Master work
    return group
end

local music = bus("Music")
local sfx = bus("SFX")
local ui = bus("UI")
local voice = bus("Voice")
```

Assign on creation and never touch a sound's own `Volume` from a settings menu:

```lua
sound.SoundGroup = sfx
```

**This is the whole reason buses exist.** A volume slider that walks every live
`Sound` and scales it has to know about sounds that do not exist yet, cannot
restore the original mix, and fights anything else adjusting volume. A slider
that sets `sfx.Volume` is one assignment and is always correct.

```lua
-- The settings menu, in full.
local function setBusVolume(name: string, value: number)
    local group = master:FindFirstChild(name)
    if group and group:IsA("SoundGroup") then
        group.Volume = math.clamp(value, 0, 1)
    end
end
```

A sound's effective volume is its own `Volume` times every group above it. Keep
per-sound `Volume` for *relative balance* — this gunshot is louder than that
footstep — and buses for *player control*.

Four or five buses is the right number. `Master`, `Music`, `SFX`, `UI`, and
`Voice` if you have any. More becomes a mixing desk nobody adjusts.

---

## Preloading

The first play of an unloaded asset stutters while it downloads. That is
invariably the sound that matters — the one at the start of the boss fight.

```lua
local ContentProvider = game:GetService("ContentProvider")

local critical = {}
for _, sound in soundTemplates:GetDescendants() do
    if sound:IsA("Sound") then
        table.insert(critical, sound)
    end
end

ContentProvider:PreloadAsync(critical)       -- YIELDS
```

`PreloadAsync` yields until everything is fetched, so run it behind a loading
screen and not in the middle of gameplay. Preload the sounds that must be
instant, not every sound in the game — over-preloading is a long loading screen
in exchange for assets nobody will hear this session.

`Sound.IsLoaded` is `[ReadOnly]` and tells you whether a particular asset is
ready, which is useful for a per-sound guard rather than a bulk wait.

---

## The modern graph

The new system is a signal graph. Nodes produce, process or consume audio, and a
`Wire` connects one node's output pin to another's input pin. Nothing is
implicit.

```lua
local player = Instance.new("AudioPlayer")
player.Asset = "rbxassetid://1234567"
player.Volume = 0.8
player.Parent = part

local emitter = Instance.new("AudioEmitter")     -- makes it positional
emitter.Parent = part

local toEmitter = Instance.new("Wire")
toEmitter.SourceInstance = player
toEmitter.TargetInstance = emitter
toEmitter.Parent = part

player:Play()
```

`Wire` carries `SourceInstance`, `SourceName`, `TargetInstance`, `TargetName`
and a `[ReadOnly] Connected`. `SourceName` and `TargetName` select which pin
when a node has more than one; leaving them default connects the primary pins.

Every node exposes `WiringChanged(connected, pin, wire, instance)`, which is how
you react to a graph being rewired at runtime rather than polling `Connected`.

### The three node roles

| Role | Classes |
|---|---|
| **Produce** | `AudioPlayer`, `AudioDeviceInput` (microphone), `AudioRecorder` |
| **Process** | `AudioFader`, `AudioEqualizer`, `AudioCompressor`, `AudioLimiter`, `AudioReverb`, `AudioEcho`, `AudioFilter`, `AudioDistortion`, `AudioChorus`, `AudioFlanger`, `AudioGate`, `AudioPitchShifter`, `AudioChannelMixer`, `AudioChannelSplitter`, `AudioAnalyzer` |
| **Consume** | `AudioEmitter` (into the 3D world), `AudioDeviceOutput` (straight to a player's speakers) |

Audio that is not wired to a consumer is silent. That is the single most common
first mistake with the graph, and it produces no error — there is simply nothing
to hear.

### Positional audio

`AudioEmitter` puts sound into the world; `AudioListener` takes it out. A
listener normally lives on the camera or the character.

```lua
emitter.DistanceAttenuationMode = Enum.DistanceAttenuationMode.InverseTapered
emitter.DistanceAttenuationBounds = NumberRange.new(8, 90)   -- min, max
emitter.OcclusionEnabled = Enum.SimulationMode.Enabled
emitter.ReverbEnabled = Enum.SimulationMode.Enabled
```

`OcclusionEnabled`, `DiffractionEnabled` and `ReverbEnabled` take
`Enum.SimulationMode` and are the graph's real advantage over `Sound`: audio
that is muffled by a wall, bends around a corner, and picks up the reverb of the
space it is in, without you scripting any of it.

`SimulationFidelity` is `[Deprecated]` — use the three per-effect switches.

`AudioEmitter.PositionType` / `AudioListener.PositionType` plus `PositionInstance`
decide what the node follows.

`AudioInteractionGroup` on both is a string tag: emitters are only heard by
listeners in a matching group. That is how you build a team voice channel, or
audio that only exists inside one instance of a level.

### Per-player output

```lua
local output = Instance.new("AudioDeviceOutput")
output.Player = somePlayer          -- this player's speakers, nobody else's
output.Parent = somewhere
```

This is the thing the legacy system cannot express at all: a server-side graph
whose result reaches exactly one player. Voice chat, per-player music states,
accessibility mixes.

### An effects chain

```lua
--  AudioPlayer -> AudioFader -> AudioCompressor -> AudioDeviceOutput
local function wire(from: Instance, to: Instance, parent: Instance): Wire
    local w = Instance.new("Wire")
    w.SourceInstance = from
    w.TargetInstance = to
    w.Parent = parent
    return w
end

wire(musicPlayer, fader, container)
wire(fader, compressor, container)
wire(compressor, output, container)
```

`AudioFader.Volume` is the graph's equivalent of a bus volume, and
`AudioFader.Bypass` — present on every processing node — turns a stage off
without unwiring it. Bypass is how you A/B an effect.

`AudioAnalyzer` reads the signal rather than changing it, which is what drives a
visualiser or a beat-reactive effect without a hand-rolled FFT.

---

## Choosing between them

Use the graph when you need one of these, and `Sound` when you do not:

- Per-player output.
- A real effects chain, especially compression on a mix that clips.
- Occlusion, diffraction or space-derived reverb.
- Microphone input or recording.
- Signal analysis.

Mixing both in one game is fine — they coexist — but pick one per subsystem.
Half a music system in each is how you end up with two volume sliders that do
different things.

---

## Common failures

**Sound on the wrong side of the network.** UI audio created on the server means
every player hears every other player's menu. Client audio for a world event
means only the actor hears the explosion.

**A looped sound with no owner.** Ambience started on a trigger and never
stopped keeps playing through death, teleport and the next area. Trove it.

**Volume set per-sound from a slider.** Covered above. Buses.

**No preload.** The tutorial voice line stutters on first play for every player,
every session.

**Rolloff left at defaults.** The default distances are rarely right for your
scale. A sound audible across a 2,000-stud map is not atmosphere, it is noise.

**Graph audio with nothing wired to a consumer.** Silent, no error.

**Ignoring the mute.** Players who have turned audio down have done so
deliberately. Do not route past the bus to make sure they hear something.

---

## Checklist

- [ ] Bus structure exists; sliders set `SoundGroup.Volume`, never per-sound `Volume`.
- [ ] One-shots use `PlayOnRemove`.
- [ ] Every looped sound is owned and stopped.
- [ ] Critical sounds preloaded behind a loading screen.
- [ ] Rolloff distances match the world's scale.
- [ ] UI and personal audio created on the client; world audio on the server.
- [ ] Graph nodes reach a consumer.
- [ ] No `[Deprecated]` `MinDistance` / `MaxDistance` / `Pitch`.
