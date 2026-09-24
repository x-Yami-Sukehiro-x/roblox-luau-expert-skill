local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end
local function near(a, b) return math.abs(a - b) < 0.01 end

local world = HARNESS.world()
local humanoid = world.player.Character.Humanoid
__recipe()
local speed = world.genv.Features.Speed

check("running it sets walk speed and jump height", humanoid.WalkSpeed == 40 and humanoid.JumpHeight == 16)
check("jump power reaches the same height for JumpPower games", near(humanoid.JumpPower, math.sqrt(2 * 196.2 * 16)))

humanoid.WalkSpeed = 8
check("a game stun or sprint script is overridden", humanoid.WalkSpeed == 40)

world.key(Enum.KeyCode.G)
check("G puts back the values the game had", humanoid.WalkSpeed == 16 and humanoid.JumpPower == 50 and near(humanoid.JumpHeight, 7.2))
humanoid.WalkSpeed = 8
check("while off the game's writes stand", humanoid.WalkSpeed == 8)

humanoid.WalkSpeed = 16
speed.walk = 60
speed.set(true)
check("a hub slider sets a new speed through set(true)", humanoid.WalkSpeed == 60)
speed.walk = 70
speed.set(true)
speed.set(false)
check("re-applying keeps the game's own original", humanoid.WalkSpeed == 16)

speed.set(true)
local body = world.respawn(world.player)
check("the speed carries over a respawn", body.Humanoid.WalkSpeed == 70)
humanoid.WalkSpeed = 3
check("the old body is no longer watched", humanoid.WalkSpeed == 3)

__recipe()
local again = world.genv.Features.Speed
check("running it again replaces the old session", again ~= speed and speed.alive == false and body.Humanoid.WalkSpeed == 40)
again.unload()
again.unload()
check("unload restores the game's speed and leaves nothing", body.Humanoid.WalkSpeed == 16 and world.genv.Features.Speed == nil)
world.key(Enum.KeyCode.G)
check("after unload the key does nothing", body.Humanoid.WalkSpeed == 16)

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
