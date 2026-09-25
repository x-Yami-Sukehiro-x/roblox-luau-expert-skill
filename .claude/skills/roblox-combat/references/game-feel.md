# Hit feedback

The tier model and the trauma shake are adapted from the `game-feel` skill in
`gamedev-skills/awesome-gamedev-agent-skills` (Apache-2.0), translated to
Roblox's APIs.

## Tiers

Every hit event gets one tier, so the whole game stays proportional.

| Tier | Events | Feedback |
|---|---|---|
| Light | a normal hit, a pickup | a sound, a spark at the contact point |
| Medium | a strong hit, a block broken | plus a white flash on the target for about 0.05 s, a small camera shake, a damage number |
| Heavy | a critical, a finishing blow, a boss hit | plus a bigger shake and a pause of about 0.1 s in the attacker's animation |

Everything returns to rest: a flash fades, a shake decays, a number rises and
disappears. Juice that stays becomes the new normal and stops meaning
anything.

## Camera shake by trauma

Hits add *trauma* (0 to 1); it decays every frame; the shake is trauma
squared, so small hits barely move the camera and big ones punch. Smooth
noise, not a new random offset every frame, or the camera buzzes.

```lua
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera
local trauma = 0
local DECAY = 1.4
local MAX_ANGLE = math.rad(2.5)

local function addTrauma(amount: number)
	trauma = math.min(trauma + amount, 1)
end

local function shakeCamera(deltaTime: number)
	if trauma <= 0 then
		return
	end
	trauma = math.max(trauma - DECAY * deltaTime, 0)
	local shake = trauma * trauma
	local now = os.clock() * 20
	local pitch = math.noise(now, 0) * MAX_ANGLE * shake
	local yaw = math.noise(0, now) * MAX_ANGLE * shake
	camera.CFrame *= CFrame.Angles(pitch, yaw, 0)
end

RunService:BindToRenderStep("HitShake", Enum.RenderPriority.Camera.Value + 1, shakeCamera)
```

Bound after the camera's own update, it offsets the finished camera for
this frame only, so the camera scripts are not fought. Unbind it with
`RunService:UnbindFromRenderStep("HitShake")` when the combat system is
torn down. Scale `addTrauma` by a player setting ("Screen shake: 0 to 100%")
and skip it when `GuiService.ReducedMotionEnabled` is on.

## Hit pause

A heavy hit reads as heavy when the attacker's animation holds for a moment.
`AnimationTrack:AdjustSpeed(0)` then back to 1 after about 0.1 s does it
without touching the simulation. Only the attacker's track pauses; pausing
the world or `workspace` time does not exist in Roblox and is not needed.

## Numbers and flashes

A damage number is a BillboardGui that rises and fades over about 0.6 s,
with a small random sideways drift so stacked hits fan out instead of
overlapping. A flash is a `Highlight` on the target with `FillTransparency`
tweened from 0.3 to 1 over 0.1 s. Both run on the client that sees them,
from the server's damage message.
