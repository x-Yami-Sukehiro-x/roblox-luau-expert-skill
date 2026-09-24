-- ============================== assertions ==============================
local Toast = __modules["Toast"]
local visible, queued, byKey, dismiss = Toast._debug()

-- Springs only advance on PreRender. Pump frames so positions actually settle.
local function frames(count)
    for _ = 1, count or 3 do
        HARNESS.preRender:Fire(1 / 60)
    end
end

local pass, fail = 0, 0
local function check(label, ok, detail)
    if ok then
        pass += 1
        print(string.format("  PASS  %s", label))
    else
        fail += 1
        print(string.format("  FAIL  %s   %s", label, detail or ""))
    end
end

print("")
print("1. capacity: five pushed -> three visible, two queued")
for i = 1, 5 do Toast.info("message " .. i) end
local v, q = Toast.count()
check("3 visible", v == 3, string.format("got %d", v))
check("2 queued", q == 2, string.format("got %d", q))

print("")
print("2. dedup: forty pushes on one key collapse to a single entry")
Toast.destroy()
for _ = 1, 40 do
    Toast.push({ message = "+1 Coin", severity = "success", key = "coin" })
end
local v2, q2 = Toast.count()
local entries = select(1, Toast._debug())
check("1 visible", v2 == 1, string.format("got %d", v2))
check("0 queued", q2 == 0, string.format("got %d", q2))
check("count reached 40", entries[1] and entries[1].count == 40,
    string.format("got %s", tostring(entries[1] and entries[1].count)))
check("label shows the multiplier", entries[1] and string.find(entries[1].label.Text, "x40") ~= nil,
    tostring(entries[1] and entries[1].label.Text))

print("")
print("3. preempt: an error evicts a low-priority toast when full")
Toast.destroy()
for i = 1, 3 do Toast.info("info " .. i) end
Toast.error("server unreachable")
local v3 = Toast.count()
local live = select(1, Toast._debug())
local hasError = false
for _, entry in live do
    if entry.severity == "error" then hasError = true end
end
check("still capped at 3", v3 == 3, string.format("got %d", v3))
check("an error is on screen", hasError, "no error entry found")

print("")
print("4. reflow: dismissing the MIDDLE toast moves the one below up")
Toast.destroy()
for i = 1, 3 do Toast.info("row " .. i) end
frames(5)
local live4 = select(1, Toast._debug())
local thirdBefore = live4[3].y
local middle = live4[2]
dismiss(middle)
frames(5)
local live5 = select(1, Toast._debug())
local survivor = live5[2]
check("two remain", #live5 == 2, string.format("got %d", #live5))
check("survivor took the vacated slot", survivor ~= nil and survivor.y < thirdBefore,
    string.format("before=%s after=%s", tostring(thirdBefore), tostring(survivor and survivor.y)))

print("")
print("5. teardown: destroy clears everything")
Toast.destroy()
local v5, q5 = Toast.count()
check("0 visible", v5 == 0, string.format("got %d", v5))
check("0 queued", q5 == 0, string.format("got %d", q5))

print("")
print(string.format("%d passed, %d failed", pass, fail))
if fail > 0 then error(string.format("%d assertion(s) failed", fail)) end
