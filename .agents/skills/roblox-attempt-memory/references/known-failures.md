# Known failures

Approaches that look right, keep being generated, and fail. Each is an entry
in the ledger format, so `attempt-ledger.mjs check` reads this file for every
project, and `plan` compares a new approach against every `Tried` line here.

Entries with an `Avoid` pattern are the ones a regular expression can find
without flagging correct code. The rest are caught by a named linter rule or
test, or only by reading; their `Check` line says which.

## Executor features

### K1 failed: flight with body movers
- Tried: fly by creating a BodyVelocity and a BodyGyro on the root part
- Saw: the movers are deprecated, and a BodyGyro needs hand-tuned torque or the body tips while flying
- Instead: LinearVelocity plus a rigid AlignOrientation under one Attachment (roblox-executor-features/assets/fly.luau)
- Avoid: `Instance\.new\(\s*["']Body(Velocity|Gyro|Position|AngularVelocity)["']`
- Check: node tools/bin/verify-api.mjs BodyVelocity

### K2 failed: flight by moving the root's CFrame every frame
- Tried: fly by adding a step to HumanoidRootPart.CFrame every RenderStepped frame
- Saw: gravity pulls the body down between writes, so it bobs, and a distance check sees a jump each frame
- Cause: each write fights the physics solver that still owns the root
- Instead: constraint flight (roblox-executor-features/assets/fly.luau)
- Check: roblox-executor-features/references/feature-catalog.md, "CFrame fly"

### K3 failed: a keybind that fires while typing in chat
- Tried: toggle a feature from a UserInputService.InputBegan handler that takes only the input argument
- Saw: typing the letter in chat or a TextBox toggled the feature
- Instead: take `(input, processed)` and return when `processed` is true
- Avoid: `(UserInputService|UIS|InputService)\.InputBegan:Connect\(function\(\s*\w+\s*\)`

### K4 failed: character parts read once at the top of the script
- Tried: store player.Character.HumanoidRootPart in a file-scope local and use it for the whole session
- Saw: the feature works until the first death, then acts on the destroyed body
- Instead: resolve the character when it is used, and re-apply on CharacterAdded
- Avoid: `^local\s+\w+\s*=\s*[\w.:()"']*Character[\w.:()"']*HumanoidRootPart`
- Unless: `CharacterAdded`

### K5 failed: a feature run by a loop on a global flag
- Tried: run the feature in `while getgenv().Enabled do ... task.wait() end`
- Saw: a second run starts a second loop beside the first, and nothing can stop either without the flag
- Instead: one connection stored in the session table, disconnected by unload (roblox-executor/references/technique/lifecycle.md)
- Avoid: `while\s+(getgenv\(\)|_G|shared)\.\w+\s+do`

### K6 failed: executor interface parented to CoreGui
- Tried: parent the hub's ScreenGui to game:GetService("CoreGui")
- Saw: whether CoreGui accepts it depends on the executor, and a PlayerGui copy is visible to the game's own scripts
- Instead: gethui(), bound and asserted once at the top
- Avoid: `\.Parent\s*=\s*game:GetService\(\s*["']CoreGui["']\s*\)` `\.Parent\s*=\s*game\.CoreGui\b`
- Unless: `gethui`

### K7 failed: restoring a retyped constant
- Tried: find the constant 1.2 with a search, then restore it by writing the literal 1.2 back
- Saw: the restore is right only while the game keeps 1.2; after an update it writes a stale number, in three separate places
- Instead: capture the value that was read and restore that variable
- Check: roblox-code-craft/references/anti-slop-code.md, the 330-line rewrite

### K8 failed: a fallback chain across value layers
- Tried: try getsenv, then upvalues, then a property, until one of them changes the value
- Saw: after a game update it edited a different object and still reported success
- Instead: the one layer the dump proves, with an assert when the target is absent (roblox-executor/references/technique/source-to-api.md)
- Check: roblox-executor/references/technique/source-to-api.md

### K9 failed: holding a value by writing it every frame
- Tried: keep WalkSpeed up by writing it in a Heartbeat loop
- Saw: a write every frame for a value the game changes a few times a minute, and the game's write still shows until the next frame
- Instead: write back from GetPropertyChangedSignal and rebind on respawn (roblox-executor-features/assets/speed.luau)
- Check: library/tests/recipes/speed.luau

### K10 failed: mouse-only click teleport
- Tried: teleport on Mouse.Button1Down to Mouse.Hit
- Saw: a phone has no mouse button, so the feature does nothing on touch
- Instead: UserInputService.TouchTapInWorld beside the mouse path (roblox-executor-features/assets/click-teleport.luau)
- Avoid: `\.Button1Down:Connect`

### K11 failed: a __namecall hook that also catches the script's own calls
- Tried: hookmetamethod on __namecall that rewrites every matching call
- Saw: the script's own FireServer calls pass through its hook and get rewritten too, or the hook recurses
- Instead: return the original call when checkcaller() is true (roblox-executor/references/api/closures.md)
- Avoid: `hookmetamethod\(`
- Unless: `checkcaller\(`

## Interfaces

### K12 failed: help text shown only on hover
- Tried: show a description on MouseEnter and hide it on MouseLeave
- Saw: phone and gamepad players never see it
- Instead: a long press on touch and SelectionGained for gamepad (roblox-ui-tooltips, H1)
- Check: read every MouseEnter handler; a hover tint is fine, hidden information is not

### K13 failed: ClipsDescendants to round a panel's contents
- Tried: set ClipsDescendants on a rounded panel so its square children follow the curve
- Saw: square corners still poke out; ClipsDescendants clips to the rectangle
- Instead: a CanvasGroup with the UICorner, or padding the children in by the radius
- Check: lint-roblox-ui.mjs E-CORNERBLEED

### K14 failed: an outer outline inside a scrolling list
- Tried: an Outer UIStroke (the default) as the border or focus ring of rows in a ScrollingFrame
- Saw: the first row's top and every row's sides are cut off where they meet the list's edge
- Instead: BorderStrokePosition Inner, or UIPadding on the list of at least the thickness
- Check: lint-roblox-ui.mjs E-STROKECLIP

### K15 failed: a fixed-pixel panel with nothing that scales it
- Tried: size the main panel with UDim2.fromOffset(600, 420) and no UIScale
- Saw: on a landscape phone the bottom of the panel and its buttons are off the screen
- Instead: scale size with a UISizeConstraint whose minimum fits 640 x 300, or one UIScale from the viewport
- Check: lint-roblox-ui.mjs E-MINFIT; python tools/py/viewport_fit.py

### K16 failed: connecting a template before cloning it
- Tried: connect Activated on a template row, then clone it for each item
- Saw: none of the cloned rows respond; Clone copies properties and children, not connections
- Instead: connect each clone after it is created, and keep the connection for teardown

### K17 failed: a scripted ScreenGui that resets on spawn
- Tried: build the interface from a script under a ScreenGui left at ResetOnSpawn true
- Saw: after the first death every button stops working; the script holds the destroyed copy
- Instead: ResetOnSpawn = false on any ScreenGui a script builds or keeps references into
- Check: lint-roblox-ui.mjs W-RESPAWN

### K18 rejected: a redesign that moved nothing structural
- Tried: answer "redesign it" with the same elements, type scale and palette, reformatted
- Saw: the user opened it and it looked the same
- Instead: change hierarchy, surfaces and layout, and report the structural rows
- Check: node tools/bin/lint-roblox-ui.mjs --compare before.luau after.luau
