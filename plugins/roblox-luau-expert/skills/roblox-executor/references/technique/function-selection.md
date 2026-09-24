# Function Selection Guide — Which Executor API to Use

Pick the tool that matches **where the value lives and which boundary it must cross**. Always classify client-feasibility first (`client-feasibility.md`).

## Diagnosis first

| Symptom | Read this |
|---|---|
| "I changed it and the game reset it" | `value-persistence.md` |
| "It works on my screen but not for others" | `replication-exploitation.md` |
| "Speed / fly gets corrected" | `replication-exploitation.md` — check `workspace.AuthorityMode` **first** |
| "The anti-cheat detects me" | `../recon/detection-surface.md` |
| "Where is the anti-cheat / what's its hash" | `../recon/anticheat-recon.md` — run the passive recon script first |
| "I can't find the anti-cheat anywhere" | `../recon/anticheat-recon.md`, then `actors-parallel.md` |
| "Out of local registers" / won't compile | `roblox-luau-language/references/compiler-limits.md` |
| "What should I call this" / naming | `roblox-code-craft/references/naming.md` |
| Error messages, prints, warns, comments | `roblox-code-craft/references/diagnostics.md` |
| "This looks AI-generated" / review my code | `roblox-code-craft/references/code-signature.md` |
| "Build me a GUI / hub" | `roblox-ui/references/gui-architecture.md` (structure) then `roblox-ui/references/gui-design.md` (style) |
| "My toggles reset every execute" | `roblox-ui/references/gui-architecture.md` — flag registry + autoload |
| "I want to work with packets / desync" | `raknet.md` |

---

## Task → function

### Finding a game's function or config table
- **Primary**: `filtergc("function", {Constants = {...}, Upvalues = {...}}, false)`
- **Tables**: `filtergc("table", {KeyValuePairs = {...}}, false)`
- Identify exactly one source-backed candidate before mutation; never pick the first match
- A deliberate `getgc(true)` implementation needs the same identity checks, not a silent fallback
- Known script: `getsenv(script)` reads its environment directly
- `getloadedmodules()` returns ModuleScript instances; `debug.getprotos` needs an established closure
- Full options: `../api/environment.md`

### Changing a value the game actually reads
- **Primary**: `debug.setupvalue` (any type) or `debug.setconstant` (number/string/boolean/nil only)
- Guard unknown mixed closures with `islclosure(f)` before a Luau-only debug operation
- If the upvalue is a **table**, write the field directly; it is shared by reference
- Enumerate indexes with `getupvalues` / `getconstants`; never hardcode them
- Full reference: `../api/debug.md`

### Spoofing a property's apparent value
- **Primary**: `hookmetamethod(game, "__index", ...)` + `__newindex` to block writes
- Fallback: `getrawmetatable` + `setreadonly(mt, false)`
- Attributes: `__namecall` hook filtering on `"GetAttribute"` / `"SetAttribute"`
- Hidden properties: `gethiddenproperty` / `sethiddenproperty` (prefer over `setscriptable`)
- Understand the limit: this changes what the game *sees when it asks*, not what it computes

### Disabling a reset loop or anti-cheat check
- **Primary**: `getconnections(signal)` → `conn:Disable()`
- **`:Disable()`, never `:Disconnect()`** — `Disable` leaves `.Connected == true`
- **Not found on Heartbeat/Stepped/RenderStepped?** → `getrendersteppedlist()` for `BindToRenderStep` callbacks
- Attribute the writer with `getcallingscript()` inside a `__newindex` hook
- Guard on `conn.LuaConnection` — C connections have nil `Function`/`Thread` and can crash iteration

### Blocking or editing remotes
- **Primary**: `hookmetamethod(game, "__namecall", ...)` + `getnamecallmethod()` + `checkcaller()`
- Filter on `FireServer` / `InvokeServer`
- Read an existing handler first: `getcallbackvalue(remote, "OnClientInvoke")`
- Never attempt to hook `OnServerEvent` — that callback lives on the server

### Finding a game's anti-cheat
- **Start passive**: run the recon script in `../recon/anticheat-recon.md` — enumerates, hashes, reads constants, counts connections; no hooks
- `getscripts()` returning nothing is **not** evidence there is no anti-cheat — a destroyed script Instance leaves running closures
- Hidden by `Parent = nil` → `getnilinstances()`; Instance destroyed → `getgc(true)` / `filtergc`
- Fingerprint with `getscripthash` (script) and `getfunctionhash` (function); identify by `debug.getconstants`, since names get stripped
- Then: **hook the reporting chokepoint, not each check** — and pre-hook `debug.info` from `getrenv()` first, or the self-integrity check catches you

### Anti-cheat inside an Actor
- `getactors()` to detect, `run_on_actor(actor, source, ...)` to inject
- State must cross via `create_comm_channel()` — upvalues do not
- `run_on_actor` takes a **source string**, not a closure
- Full pattern: `actors-parallel.md`

### Visual ESP / overlays
- **Primary**: `Drawing.new("Line"|"Text"|"Circle"|"Square"|"Quad"|"Triangle"|"Image")`
- No DataModel presence for a game to enumerate
- Track every owned object and destroy it on unload; never clear another script's Drawing cache
- Alternative when 3D attachment is required: `BillboardGui` / `Highlight`
- Full property matrix: `../api/drawing.md`

### Packet-level work
- Feature-detect: `typeof(raknet) == "table"` and each function individually
- Observe before modifying: `raknet.add_send_hook` + `add_receive_hook` logging session
- Standing blocks: `raknet.block(id, true)` over per-packet checks
- **Never touch `0x9B` (ID_LUAU_CHALLENGE)**
- Teardown only owned hooks; single receive slots and global clears need whole-slot ownership
- Full API and ID tables: `raknet.md`

### Input simulation
- `isrbxactive()` **must be true** or every other input function silently no-ops
- `mouse1click`, `mousemoveabs`, `mousemoverel`, `mousescroll`
- Under Server Authority, only Input Action System inputs reach the server

### Protecting your GUI
- `gethui()` — hidden container, preferred over `CoreGui` and `PlayerGui`
- `protect_gui` / `syn.protect_gui` where implemented
- `cloneref` when a game compares instance identity

### Persistence and transport
- Across teleports: `queue_on_teleport(codeString)`
- HTTP: `request({Url = ..., Method = ..., Headers = ..., Body = ...})`
- Live connection: `WebSocket.connect(url)`
- Client config before launch: `setfflag(name, value)` — auto-execute + auto-launch only

---

## Decision flow

1. Is the feature client-feasible at all? → `client-feasibility.md`
2. Is the game running Server Authority? → read `workspace.AuthorityMode` before promising movement changes
3. Where does the value live — property, attribute, upvalue, constant, module table, or server? → `value-persistence.md` ladder
4. Does it reset? → identify the writer/replacement; prefer its source-defined setter or config
5. Does it need to reach other players? → only a remote the server accepts, or physics on an owned assembly
6. Does it need to avoid detection? → `../recon/detection-surface.md`

---

## Anti-patterns

- Writing a property in a loop without also finding what writes it back
- Reaching for `__index` spoofing when the value is an upvalue — it will lose to the reset loop
- Hardcoding a `debug.setconstant` index instead of enumerating by value
- `hookfunction` on a function the game hashes, when a `setupvalue` would leave the hash intact
- `:Disconnect()` where `:Disable()` is correct
- Passing an unknown C closure to a debug operation that requires a Luau closure
- `:FireServer` on a remote before understanding the server's validation
- Assuming `sethiddenproperty`, `setsimulationradius`, or Actor injection grants server authority — none do
- Leaving Drawing objects, hooks, or packet hooks alive after unload
- Presenting an executor-specific function as universal

Always verify a function exists before calling it:
```lua
if typeof(getrendersteppedlist) == "function" then
    -- safe to use
end
```
