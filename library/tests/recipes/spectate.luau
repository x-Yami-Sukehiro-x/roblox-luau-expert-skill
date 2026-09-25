local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local world = HARNESS.world()
local players = HARNESS.services.Players
local camera = world.camera
local alice = world.join("Alice")
local bob = world.join("Bob")
__recipe()
local spectate = world.genv.Features.Spectate

check("running it watches the first other player", spectate.on and spectate.target == alice and camera.CameraSubject == alice.Character.Humanoid)

world.key(Enum.KeyCode.RightBracket)
check("] moves to the next player", spectate.target == bob and camera.CameraSubject == bob.Character.Humanoid)
world.key(Enum.KeyCode.RightBracket)
check("] past the last wraps to the first", spectate.target == alice)
world.key(Enum.KeyCode.LeftBracket)
check("[ from the first wraps to the last", spectate.target == bob)

camera.CameraSubject = world.player.Character.Humanoid
check("the camera script pointing back at us is undone", camera.CameraSubject == bob.Character.Humanoid)

local bobBody = world.respawn(bob)
check("the target's new body is followed after they respawn", camera.CameraSubject == bobBody.Humanoid)

local ownBody = world.respawn(world.player)
check("our own respawn does not end spectating", camera.CameraSubject == bobBody.Humanoid)

world.key(Enum.KeyCode.P)
check("P returns the camera to our current body, not the dead one", spectate.on == false and camera.CameraSubject == ownBody.Humanoid)
camera.CameraSubject = alice.Character.Humanoid
check("while off the camera is left alone", camera.CameraSubject == alice.Character.Humanoid)
camera.CameraSubject = ownBody.Humanoid

HARNESS.input.InputBegan:Fire({ KeyCode = Enum.KeyCode.P }, true)
check("P typed into chat does not toggle", spectate.on == false)
world.key(Enum.KeyCode.RightBracket)
check("] does nothing while off", spectate.on == false and camera.CameraSubject == ownBody.Humanoid)

world.key(Enum.KeyCode.P)
check("P again watches the first player", spectate.target == alice)
world.leave(alice)
check("the target leaving moves to the next player", spectate.target == bob and camera.CameraSubject == bobBody.Humanoid)
world.leave(bob)
check("the last player leaving returns the camera to us", spectate.on == false and camera.CameraSubject == ownBody.Humanoid)

local carol = world.join("Carol")
spectate.follow(carol)
check("a hub list can pick a player by name", spectate.target == carol and camera.CameraSubject == carol.Character.Humanoid)

__recipe()
local again = world.genv.Features.Spectate
check("running it again replaces the old session", again ~= spectate and spectate.alive == false and #HARNESS.input.InputBegan.handlers == 1)
check("one removal watcher after a rerun", #players.PlayerRemoving.handlers == 1)

again.unload()
again.unload()
check("unload twice is harmless and hands the camera back", world.genv.Features.Spectate == nil and camera.CameraSubject == ownBody.Humanoid and #players.PlayerRemoving.handlers == 0)
world.key(Enum.KeyCode.P)
check("after unload the key does nothing", camera.CameraSubject == ownBody.Humanoid)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
