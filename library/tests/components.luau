-- ========================= component assertions =========================
-- Layout, Toggle, Slider and TabBar carry real bookkeeping - quantisation,
-- silent restore, page visibility, unknown-name rejection - and every one of
-- those has been a shipped defect in somebody's Roblox menu.

local Layout = __modules["Layout"]
local Toggle = __modules["Toggle"]
local Slider = __modules["Slider"]
local TabBar = __modules["TabBar"]
local Tokens = __modules["Tokens"]

local cpass, cfail = 0, 0
local function expect(label, ok, detail)
    if ok then
        cpass += 1
        print(string.format("  PASS  %s", label))
    else
        cfail += 1
        print(string.format("  FAIL  %s   %s", label, detail or ""))
    end
end

local function pump(count)
    for _ = 1, count or 3 do
        HARNESS.preRender:Fire(1 / 60)
    end
end

print("")
print("6. Layout: the defaults that are wrong out of the box")

local host = Instance.new("Frame")
local column = Layout.column(host, 8)
expect("column sorts by LayoutOrder, not by name",
    column.SortOrder == Enum.SortOrder.LayoutOrder, tostring(column.SortOrder))
expect("column gap applied", column.Padding.Offset == 8, tostring(column.Padding.Offset))

local pad = Layout.padding(host, 16)
expect("uniform padding sets all four sides",
    pad.PaddingTop.Offset == 16 and pad.PaddingBottom.Offset == 16
        and pad.PaddingLeft.Offset == 16 and pad.PaddingRight.Offset == 16)

local sides = Layout.padding(host, { left = 12, right = 12 })
expect("per-side padding leaves the unnamed sides at zero",
    sides.PaddingLeft.Offset == 12 and sides.PaddingTop.Offset == 0)

local scroller = Layout.scroller(host)
expect("scroller clears CanvasSize as well as setting AutomaticCanvasSize",
    scroller.AutomaticCanvasSize == Enum.AutomaticSize.Y
        and scroller.CanvasSize.X.Offset == 0 and scroller.CanvasSize.Y.Offset == 0)

local caption = Layout.label(host, "hint", "caption")
expect("label reads its size from the token scale",
    caption.TextSize == Tokens.text_size.caption, tostring(caption.TextSize))
expect("label never ships TextScaled", caption.TextScaled == false)

local unknownOk = pcall(function()
    return Layout.label(host, "x", "enormous")
end)
expect("an unknown text role errors rather than silently defaulting", not unknownOk)

print("")
print("7. Toggle: silent restore, and no callback on a no-op set")

local fired = 0
local lastValue = nil
local toggle = Toggle.new(false, function(value)
    fired += 1
    lastValue = value
end)

toggle.instance.Activated:Fire()
expect("activating fires the callback once", fired == 1, string.format("got %d", fired))
expect("activating flips the state", toggle:get() == true and lastValue == true)

toggle:set(true)
expect("setting to the current value does not re-fire", fired == 1, string.format("got %d", fired))

toggle:set(false, true)
expect("silent set changes the value", toggle:get() == false)
expect("silent set does not fire - restoring a config must not run every handler",
    fired == 1, string.format("got %d", fired))

pump(4)
local knobX = toggle.instance.Track.Knob.Position.X.Offset
toggle:set(true, true)
pump(4)
expect("the knob moves, so the state is not carried by colour alone",
    toggle.instance.Track.Knob.Position.X.Offset ~= knobX)

toggle:destroy()
expect("destroy tears the instance down", toggle.instance.destroyed == true)

print("")
print("8. Slider: quantisation, clamping, and no 0.30000000000000004")

local seen = {}
local slider = Slider.new({ min = 0, max = 1, step = 0.05, initial = 0 }, function(value)
    table.insert(seen, value)
end)

slider:set(0.33)
expect("a value off the step grid is quantised to it",
    math.abs(slider:get() - 0.35) < 1e-9, tostring(slider:get()))

slider:set(5)
expect("above max clamps to max", slider:get() == 1, tostring(slider:get()))

slider:set(-5)
expect("below min clamps to min", slider:get() == 0, tostring(slider:get()))

local before = #seen
slider:set(0.5, true)
expect("silent set does not fire", #seen == before, string.format("got %d", #seen - before))
expect("silent set still applies", slider:get() == 0.5, tostring(slider:get()))

local badOk = pcall(function()
    return Slider.new({ min = 10, max = 2 }, function() end)
end)
expect("an inverted range errors at construction", not badOk)

slider:destroy()

print("")
print("9. TabBar: one page visible, and unknown names rejected")

local shell = Instance.new("Frame")
local switches = {}
local tabs = TabBar.new(shell, { "Combat", "Visuals", "Settings" }, function(name)
    table.insert(switches, name)
end)

HARNESS.drain()

expect("the first tab is current on open", tabs:current() == "Combat", tabs:current())
expect("its page is visible", tabs:page("Combat").Visible == true)
expect("the other pages are hidden",
    tabs:page("Visuals").Visible == false and tabs:page("Settings").Visible == false)

tabs:select("Visuals")
expect("selecting switches the visible page",
    tabs:page("Visuals").Visible == true and tabs:page("Combat").Visible == false)
expect("the switch callback fired once", #switches == 1 and switches[1] == "Visuals",
    string.format("got %d", #switches))

tabs:select("Visuals")
expect("re-selecting the current tab is a no-op", #switches == 1, string.format("got %d", #switches))

local missingOk = pcall(function()
    tabs:select("Nope")
end)
expect("selecting a tab that does not exist errors", not missingOk)

expect("page() returns nil for an unknown name", tabs:page("Nope") == nil)

tabs:destroy()
expect("destroy tears the container down", tabs.instance.destroyed == true)

print("")
print(string.format("%d passed, %d failed", cpass, cfail))
if cfail > 0 then error(string.format("%d component assertion(s) failed", cfail)) end
