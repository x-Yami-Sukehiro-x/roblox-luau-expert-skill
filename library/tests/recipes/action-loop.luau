local results = {}
local function check(name, ok) table.insert(results, (ok and "PASS " or "FAIL ") .. name) end

local createLoop = __recipe()
local folder = {}
local coins = {
	{ Name = "Coin1", Parent = folder },
	{ Name = "Coin2", Parent = folder },
	{ Name = "Coin3", Parent = nil },
}
local acted = {}
local waits = {}
local alive = true
local loop

-- The harness runs spawned threads inline, so the test ends the loop from its
-- wait: the Nth wait stops it, the way a player's toggle would.
local stopAfter = 0
task.wait = function(seconds)
	table.insert(waits, seconds)
	if #waits >= stopAfter then loop.stop() end
end

loop = createLoop({
	interval = 0.5,
	targets = function() return coins end,
	act = function(coin) table.insert(acted, coin.Name) end,
	ready = function() return alive end,
})

check("nothing runs before start", not loop.running() and loop.actions() == 0)

stopAfter = 3
loop.start()
check("acts on every current target, skipping one already removed", acted[1] == "Coin1" and acted[2] == "Coin2" and not table.find(acted, "Coin3"))
check("waits the game's interval after each action", waits[1] == 0.5 and waits[2] == 0.5)
check("stops acting once stopped", #acted == 3 and loop.actions() == 3)
check("and reports that it is not running", not loop.running())

acted, waits = {}, {}
alive = false
stopAfter = 2
loop.start()
check("does not act while the game's precondition is false", #acted == 0 and #waits == 2)

alive = true
acted, waits = {}, {}
stopAfter = 1
coins[2].Parent = nil
loop.start()
check("a stop from the first wait ends the pass before the next target", #acted == 1 and acted[1] == "Coin1")

loop.stop()
loop.stop()
check("stopping twice is harmless", not loop.running())

local failed = 0
for _, line in results do print(line) if line:sub(1, 4) == "FAIL" then failed += 1 end end
print(#results - failed .. " passed, " .. failed .. " failed")
