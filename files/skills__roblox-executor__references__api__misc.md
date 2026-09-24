# Miscellaneous Executor Functions

sUNC core plus widely-implemented extensions. Functions marked with a source attribution are **not** in sUNC — feature-detect before use.

---

## HTTP

<!-- lint: fragment -->
```lua
function request(options: {
    Url: string,
    Method?: string,
    Headers?: {[string]: string},
    Body?: string,
    Cookies?: {[string]: string},
}): {
    Success: boolean,
    StatusCode: number,
    StatusMessage: string,
    Headers: {[string]: string},
    Body: string,
}
```
Yields. Preferred over `HttpService` when the game restricts it.

```lua
local response = request({
    Url = "https://example.com",
    Method = "GET",
    Headers = { ["User-Agent"] = "Roblox/WinInet" }
})
```

---

## WebSocket

```lua
function WebSocket.connect(url: string): WebSocket
```
Connects to a `ws://` or `wss://` endpoint.

| Member | Signature |
|---|---|
| `.OnMessage` | signal — `(message: string)` |
| `.OnClose` | signal — `()` |
| `:Send(message: string)` | transmit |
| `:Close()` | terminate |

```lua
local ws = WebSocket.connect("wss://ws.postman-echo.com/raw")
ws.OnMessage:Connect(function(message) print(message) end)
ws:Send("Hello")      -- Output: Hello

ws.OnClose:Connect(function() print("Closed") end)
ws:Close()            -- Output: Closed
```

Always connect `OnClose` and handle reconnection — a dropped socket is silent otherwise.

---

## Identification

```lua
function identifyexecutor(): (string, string?)
```
Name and version. Use it to branch on executor-specific APIs, but **still feature-detect** — versions within one executor differ.

```lua
function isluau(): boolean   -- Synapse-lineage
```

---

## Signals & connections

```lua
function getconnections(signal: RBXScriptSignal): {Connection}
function getconnection(signal: RBXScriptSignal, index: number): Connection   -- Potassium
function firesignal(signal: RBXScriptSignal, ...)
function replicatesignal(signal: RBXScriptSignal, ...)
function getrendersteppedlist(): table   -- Potassium/Synapse-lineage
```

`Connection` fields: `Enabled`, `ForeignState`, `LuaConnection`, `Function`, `Thread`.
`Connection` methods: `:Fire(...)`, `:Defer(...)`, `:Disconnect()`, `:Disable()`, `:Enable()`.

> C / foreign connections have `nil` `Function` and `Thread`, and iterating them can crash on non-compliant executors. Guard on `conn.LuaConnection`.

> **`getrendersteppedlist` is the only way to see `BindToRenderStep` callbacks** — `getconnections` does not cover them. Essential when hunting a reset loop you cannot otherwise find (`../technique/value-persistence.md`).

`replicatesignal` is documented in `../technique/replication-exploitation.md` — it is one of the few genuine client→server channels.

---

## Fire helpers

<!-- lint: fragment -->
```lua
function fireclickdetector(detector: ClickDetector, distance?: number)
function fireproximityprompt(prompt: ProximityPrompt)
function firetouchinterest(part: BasePart, transmitter: BasePart, toggle: number)
```
These simulate the client's input. The server still decides whether to accept the result.

---

## Instance access

```lua
function getcallbackvalue(object: Instance, property: string): any?
```
Reads callback properties that are normally write-only (`OnInvoke`, `OnClientInvoke`, `OnServerInvoke` where present), exposing the assigned function.

```lua
local dummy_bindable = Instance.new("BindableFunction")
dummy_bindable.OnInvoke = function() print("Hello from callback!") end

local retrieved = getcallbackvalue(dummy_bindable, "OnInvoke")
retrieved() -- Output: Hello from callback!
```

Useful for reading a game's `RemoteFunction.OnClientInvoke` handler before deciding whether to hook it.

<!-- lint: fragment -->
```lua
function setnonreplicatedproperty(obj: Instance, prop: string, value: any)   -- Synapse-lineage
```
Sets a property **without replicating the write to the server**. Reduces your detection footprint. It does **not** make the server accept the value — see `../technique/value-persistence.md`, Cause B.

```lua
function isnetworkowner(part: BasePart): boolean            -- Potassium
function setsimulationradius(radius: number, maxRadius: number?)  -- executor-dependent
function getpcd(object: TriangleMeshPart): string           -- Potassium
function getbspval(object: Instance, property: string): string -- Potassium
function getspecialinfo(obj: Instance): table               -- Synapse-lineage
```
`getspecialinfo` returns special properties for `MeshPart`, `UnionOperation`, and `Terrain`.

---

## Metatable extras

<!-- lint: fragment -->
```lua
function makewriteable(object: table)   -- Potassium; unfreezes
function makereadonly(object: table)    -- Potassium; freezes past __metatable
```
Alongside the sUNC `getrawmetatable` / `setrawmetatable` / `isreadonly` / `setreadonly`.

---

## Input simulation

<!-- lint: fragment -->
```lua
function isrbxactive(): boolean
function mouse1click() / mouse1press() / mouse1release()
function mouse2click() / mouse2press() / mouse2release()
function mousemoveabs(x: number, y: number)
function mousemoverel(x: number, y: number)
function mousescroll(pixels: number)
```

> **`isrbxactive()` must return true or every other input function silently does nothing.** Check it first; a failing aimbot is usually an unfocused window, not a broken script.

These dispatch real OS-level input. Games that read `UserInputService` see them as genuine. Games running the Input Action System under Server Authority route input differently — see `../technique/replication-exploitation.md`.

---

## Filesystem

```lua
function readfile(path: string): string
function writefile(path: string, data: string)
function appendfile(path: string, data: string)
function delfile(path: string)
function isfile(path: string): boolean
function listfiles(folder: string): {string}
function makefolder(path: string)
function delfolder(path: string)
function isfolder(path: string): boolean
function loadfile(path: string): (function?, string?)
function getcustomasset(path: string): string
```
`getcustomasset` returns an `rbxasset://` content id for a local file, allowing unmoderated assets. Executors block dangerous extensions (`.exe`, `.dll`, `.bat` and similar).

**Every path is relative to the executor's sandboxed workspace folder.** You
cannot escape it, and you should not assume the real OS filesystem is reachable
at all — the sandbox root differs per executor.

`writefile` plus `loadfile` is the normal way to persist a script hub's
configuration between sessions. Treat anything you read back as untrusted input:
a config file is editable by the user and by anything else on their machine.

---

## Encoding & crypto

```lua
function base64encode(data: string): string
function base64decode(data: string): string
function lz4compress(data: string): string
function lz4decompress(data: string, size: number): string
```

`lz4decompress` requires the **original uncompressed size** — store it alongside the compressed blob.

```lua
crypt.base64encode(data: string): string
crypt.base64decode(data: string): string
crypt.encrypt(data: string, key: string, iv: string?, mode: string?): (string, string)
crypt.decrypt(data: string, key: string, iv: string, mode: string): string
crypt.generatebytes(size: number): string
crypt.generatekey(): string
crypt.hash(data: string, algo: string): string
```
AES with CBC / ECB / CTR / CFB / OFB / GCM modes. `crypt.encrypt` returns the base64 ciphertext **and** the IV. `generatekey` returns a base64 256-bit key suitable as the `key` argument.

---

## Console

<!-- lint: fragment -->
```lua
function rconsolecreate()
function rconsoledestroy()
function rconsoleclear()
function rconsoleprint(text: string)
function rconsolewarn(text: string)
function rconsoleerror(text: string)
function rconsolesettitle(title: string)
function rconsoleinput(): string
```
`rconsoleinput` yields until the user types a line. Some executors disable parts of this surface.

---

## Script inspection

```lua
function getscriptbytecode(script: LuaSourceContainer): string
function getscriptclosure(script: LuaSourceContainer): function
function getscripthash(script: LuaSourceContainer): string
function decompile(target: LocalScript | ModuleScript | function): string
function dumpstring(script: string | function): string
```
`decompile` yields; passing a function decompiles the script that owns it. Output quality varies widely by executor — expect unnamed locals and reconstructed control flow, and identify functions by their constants rather than their names.

---

## Drawing helpers

```lua
function cleardrawcache()
function isrenderobj(object: any): boolean
function getrenderproperty(drawing: DrawingObject, property: string): any
function setrenderproperty(drawing: DrawingObject, property: string, value: any)
```
Full class/property matrix in `drawing.md`.

---

## Client configuration

<!-- lint: fragment -->
```lua
function setfflag(FFlag: string, Value: string)   -- Synapse-lineage
```
Sets a FastFlag. **Must run before Roblox loads** — auto-execute plus auto-launch. Flags set after the client is up have no effect. Non-executor equivalent is `ClientSettings/ClientAppSettings.json`; Roblox ignores flags outside its allowlist.

Relevant to desync (`../technique/raknet.md`) and to reading the NextGen replicator state.

---

## Other

```lua
function queue_on_teleport(code: string)
function setclipboard(value: string)
function setrbxclipboard(data: string): boolean   -- rbxm/rbxmx model data
function messagebox(text: string, caption: string, flags: number): number
function saveinstance(options: table)             -- Synapse-lineage
function protect_gui(gui: Instance)               -- executor-dependent
function gethui(): Folder
```

`queue_on_teleport` runs queued source after the next teleport — the standard persistence mechanism across place hops. `messagebox` yields until dismissed and returns the user's input code.

```lua
queue_on_teleport([[
    -- code that runs after teleport
]])
```

---

## Alias spellings

The same function ships under more than one name across executors, and scripts
in the wild use whichever the author's executor had. These are the same
function, not different ones - but only one spelling exists on any given
executor, so feature-detect the spelling you call rather than assuming.

| Alias you will see | Canonical name here |
|---|---|
| `base64_encode` | `base64encode`, also `crypt.base64encode` |
| `base64_decode` | `base64decode`, also `crypt.base64decode` |
| `rconsoleinfo` | `rconsoleprint` |
| `rconsoleerr` | `rconsoleerror` |
| `rconsolename` | `rconsolesettitle` |
| `get_thread_identity` | `getthreadidentity` (Synapse lineage - `syn.get_thread_identity`) |
| `set_thread_identity` | `setthreadidentity` (Synapse lineage - `syn.set_thread_identity`) |
| `issynapsefunction` | `isexecutorclosure` |

```lua
-- Both spellings, one call site.
local encode = base64encode or base64_encode or (crypt and crypt.base64encode)
if typeof(encode) ~= "function" then
    warn("this executor exposes no base64 encoder")
    return
end
```

Older `syn.*` names are in `legacy-syn.md`. `tools/bin/verify-executor-api.mjs`
resolves every spelling in the table above.

---

## Related references
- `environment.md` — `getgenv`, `filtergc`, cache, reflection
- `closures.md` — hooking rules
- `debug.md` — upvalues, constants, protos, stack
- `../recon/detection-surface.md` — which of these are detectable
