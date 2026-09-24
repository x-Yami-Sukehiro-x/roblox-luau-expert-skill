# syn Library & Related

## syn.request
```lua
table syn.request(options: {
    Url: string,
    Method?: string,          -- "GET", "POST", etc.
    Headers?: table,
    Body?: string,
    Cookies?: table
}) -- yields
```
Performs an HTTP request outside of Roblox HttpService restrictions.  
Returns a table with StatusCode, StatusMessage, Headers, Body, Success, etc.

## syn.queue_on_teleport
```lua
void syn.queue_on_teleport(script: string)
```
Queues Lua source to run after the next teleport.

## syn.clear_teleport_queue
```lua
void syn.clear_teleport_queue()
```

## syn.get_thread_identity / syn.set_thread_identity
```lua
number syn.get_thread_identity()
void syn.set_thread_identity(identity: number)
```
Legacy aliases for `getthreadidentity` / `setthreadidentity`. Call `task.wait()` after setting, for full effect on older builds.

> **The "0-8, higher = more privileges" model these functions were documented with is obsolete.** Identities are named, not a ladder, and access is decided by *capabilities* — `CommandBar` holds `Plugin` and `LocalUser` but not `RobloxScript`, while `ElevatedGameScript` is the reverse. Never hardcode a numeric identity; read the current one, change it, restore it. See `../recon/thread-identity.md`.

## syn.protect_gui / syn.unprotect_gui
```lua
void syn.protect_gui(gui: Instance)
void syn.unprotect_gui(gui: Instance) -- deprecated
```
Hides a ScreenGui from many detection methods by redirecting parent.

## syn.crypt.*
- `syn.crypt.encrypt(data, key)`
- `syn.crypt.decrypt(data, key)`
- `syn.crypt.hash(data)`
- `syn.crypt.base64.encode / decode`
- Additional V3 helpers: hex, lz4, derive, seal, sign, etc.

## identifyexecutor
<!-- lint: fragment -->
```lua
string, string identifyexecutor()
```
Returns name and version of the current executor (e.g. "Synapse X", "3.x").
