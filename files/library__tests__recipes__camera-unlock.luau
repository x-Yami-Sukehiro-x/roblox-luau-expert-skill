local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local player = world.player
local camera = world.camera
player.CameraMaxZoomDistance = 20
player.CameraMode = Enum.CameraMode.LockFirstPerson
__recipe()
local unlock = world.genv.Features.CameraUnlock

check("running it unlocks zoom and third person", player.CameraMaxZoomDistance == 1000 and player.CameraMinZoomDistance == 0.5 and player.CameraMode == Enum.CameraMode.Classic)
check("the field of view is set", camera.FieldOfView == 80)

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMaxZoomDistance = 20
camera.FieldOfView = 70
check("a game locking first person or the zoom again is undone", player.CameraMode == Enum.CameraMode.Classic and player.CameraMaxZoomDistance == 1000)
check("a sprint FOV change is undone", camera.FieldOfView == 80)

world.key(Enum.KeyCode.Z)
check("Z puts back the game's own camera settings", player.CameraMaxZoomDistance == 20 and player.CameraMode == Enum.CameraMode.LockFirstPerson and camera.FieldOfView == 70)
player.CameraMaxZoomDistance = 30
check("while off the game's writes stand", player.CameraMaxZoomDistance == 30)
HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.Z }, true)
check("Z typed into chat does not toggle", unlock.on == false)

world.key(Enum.KeyCode.Z)
unlock.fov = 100
unlock.set(true)
check("a hub slider sets a new FOV through set(true)", camera.FieldOfView == 100)
unlock.set(false)
check("re-applying keeps the game's own original", camera.FieldOfView == 70 and player.CameraMaxZoomDistance == 30)

unlock.set(true)
local replacement = Instance.new("Camera")
replacement.FieldOfView = 65
world.workspace.CurrentCamera = replacement
check("a replaced camera gets the FOV too", replacement.FieldOfView == 100)
check("the old camera gets its own value back", camera.FieldOfView == 70)

__recipe()
local again = world.genv.Features.CameraUnlock
check("running it again replaces the old session", again ~= unlock and unlock.alive == false and #HARNESS.input.InputBegan.handlers == 1)
check("a rerun does not save the unlocked values as the originals", again.on and player.CameraMaxZoomDistance == 1000)

again.unload()
again.unload()
check("unload twice is harmless and restores the game's settings", world.genv.Features.CameraUnlock == nil and player.CameraMaxZoomDistance == 30 and replacement.FieldOfView == 65)
world.key(Enum.KeyCode.Z)
check("after unload the key does nothing", player.CameraMaxZoomDistance == 30)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
