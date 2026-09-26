# Worked source traces

These small artifacts are fictional. Their names are evidence only inside the
example; never transplant their paths into a user's game.

## A setting with two different readers

```lua
local bow = require(script.Parent.TrainingBow)
local reloadDuration = bow.ReloadDuration

local function updatePreview(deltaTime)
	previewOffset += bow.Sway * deltaTime
end

local function reloadPreview()
	previewReloading = true
	task.wait(reloadDuration)
	previewReloading = false
end
```

| Observation | Consequence |
|---|---|
| `updatePreview` reads `bow.Sway` each call | The active `bow` table is a candidate for a local sway adjustment |
| `reloadDuration` is copied when the script starts | Editing `bow.ReloadDuration` later does not update this reader |
| `require` is visible, its module body is missing | The table shape, initialization side effects and other consumers are unknown |
| Both functions manipulate preview state | No evidence establishes a server reload or weapon advantage |

Next step: read the module and callers, then identify the live reader's table or
captured scalar. The snippet alone does not establish a public function to call,
a safe reload cancellation path, or an upvalue index. A targeted probe can read
the candidate relationships; it must not call `reloadPreview` to "see what it does".

## A complete request is still not a completed action

```lua
local pendingRequest

local function requestRoute(routeId)
	if pendingRequest or not routes[routeId] then
		return
	end
	requestNumber += 1
	pendingRequest = requestNumber
	routeRequest:FireServer(routeId, requestNumber)
end

routeResult.OnClientEvent:Connect(function(requestId, accepted)
	if requestId ~= pendingRequest then
		return
	end
	pendingRequest = nil
	if accepted then
		showRouteAccepted()
	end
end)
```

The trace establishes two explicit outgoing arguments, a one-request latch, a
sequence number, and a matching incoming result. It does not establish the
remote paths, `routes` contents, route availability rules, or what the server
changes on acceptance. Follow the aliases before implementing.

An action queue should preserve the existing request path and wait for the
matching result. Seeing some `routeResult` event does not prove this request
completed. Reusing a stale sequence number or calling `FireServer` directly may
bypass the local latch and leave the game's display inconsistent. A timeout does
not prove the request was rejected; keep that uncertainty visible and avoid an
automatic resend until the contract establishes it is safe.

## A failed function cannot establish a payload

The dump contains:

```text
ShopClient:18  local request = ReplicatedStorage.Network.ShopRequest
ShopClient:43  -- DECOMPILER ERROR: purchase body could not be reconstructed
ShopClient:71  button.Text = "Buy crate"
```

Observed: a referenced object and a UI label. Unknown: live class, method, arity,
payload, prerequisites and completion behavior. Even a runtime observation that
the object is a `RemoteEvent` establishes none of the missing argument contract.

A useful next step is a targeted capture of the normal purchase call in a place
the user controls, or fresh source for the exact calling region. If observation
requires a hook, the probe skill treats it as instrumentation with a lifecycle,
not as a read-only inventory scan. Do not fill the missing function with a
plausible `FireServer("Crate", 1)`.

## One matching value can still be the wrong value

An identified closure has two numeric upvalues equal to `0.4`. One is a preview
cooldown and one is a smoothing rate. A second closure from an old character has
the same constants and values.

Find which closure belongs to the current character, then establish which slot
has the intended role from a source relationship or a normal state transition.
If both remain indistinguishable, the correct next artifact is a narrow report
of that ambiguity. A function hash, common key or constant that is identical
across both candidates cannot resolve it. Capturing originals makes restoration
possible; it does not make a speculative write justified.
