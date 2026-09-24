# Dumping and reading a game

Before writing anything against a target game, read it. Most bad executor
answers come from guessing at a game's structure instead of looking.

This is the reconnaissance step that makes `../technique/value-persistence.md` and
`anticheat-recon.md` productive rather than exploratory.

---

## saveinstance — dump the place

`saveinstance` serialises the client's DataModel to an `.rbxlx` / `.rbxl` you
can open in Studio and read at leisure.

The maintained implementation is
[**UniversalSynSaveInstance**](https://github.com/luau/UniversalSynSaveInstance)
("USSI"), an independent revival — not affiliated with Roblox. Actively maintained
as of 2026-09-10; adoption figures are in `docs/SOURCES.md`.

```lua
if typeof(saveinstance) ~= "function" then
    warn("this executor lacks saveinstance")
    return
end

saveinstance({
    FilePath = "dumps/" .. game.PlaceId,
    Decompile = true,          -- attempt to recover LocalScript source
    SaveNonCreatable = true,
    IgnoreDefaultProperties = true,
    IgnoreList = { game:GetService("Chat") },
})
```

Option names vary between the built-in `saveinstance` and USSI. Feature-detect
and prefer the loader the user already has rather than assuming a signature.

**What you get and what you do not.**

- You get the client's view: `Workspace`, `ReplicatedStorage`,
  `StarterPlayerScripts`, `StarterGui`, and every `LocalScript` and
  `ModuleScript` the client holds.
- You do **not** get `ServerScriptService` or `ServerStorage`. They never
  replicate. Missing logic alone does not establish server ownership: the dump
  may be partial, stale or missing a module/closure. State the gap; when server
  ownership is established, `../technique/client-feasibility.md` explains its limit.
- Under `StreamingEnabled` you get only what has streamed in. Walk the map
  first, or the dump has holes.

---

## Decompilation

```lua
local source = decompile(someLocalScript)
local bytecode = getscriptbytecode(someLocalScript)
local hash = getscripthash(someLocalScript)
```

Decompiler output is a reconstruction, not the original source. Expect:

- **Names are gone.** Locals become `v1`, `v2`, upvalues `u1`, `u2`. Only
  globals, string constants and instance names survive.
- **Control flow is approximate.** Loops and conditionals are rebuilt from
  jumps; complex flow may come out as `while true do ... break end` chains.
- **Some constructs fail entirely** and appear as comments or garbage.

Read it for **structure and constants**, not to recompile. The string constants
are usually the most valuable part — remote names, attribute keys, error
messages, config keys — because those are what `filtergc` searches on.

If `decompile` is unavailable or fails, `getscriptbytecode` plus a constant dump
still gives you the strings:

```lua
for _, constant in debug.getconstants(someFunction) do
    if typeof(constant) == "string" then print(constant) end
end
```

---

## A reading order that works

1. **`ReplicatedStorage`** — remotes and shared modules. This is the boundary
   surface: every remote name here is something the client is allowed to call.
2. **The remote call sites.** Names guide discovery but do not establish payload
   shape or the server's trust model. Trace argument construction and client
   guards; server validation remains unknown without server evidence.
3. **`StarterPlayerScripts`** — the client logic. Where local values live, and
   where any client-side anti-cheat is.
4. **Module tables** — configs, catalogs, stat tables. Frequently the layer that
   actually holds the value you want to change.
5. **`Workspace`** — the world layout, spawn points, collectibles.

Then, and only then, decide which layer holds the value.
→ `../technique/value-persistence.md`

---

## Fingerprinting for later

Record these when you dump, so a later change is detectable and so a user can
hand you something concrete:

```lua
local scriptHash = getscripthash(target)          -- stable across sessions
local fnHash = getfunctionhash(someFunction)      -- per-function
```

`getscripthash` changes when the game updates its script — which is exactly what
you want to know before assuming last week's offsets still hold.

`anticheat-recon.md` covers using these to locate and identify an anti-cheat
specifically.

---

## Practical notes

- **Dumps are large.** A big game is hundreds of megabytes. Write to a
  subfolder, not the executor root.
- **Blocked extensions.** Executors refuse some file extensions for safety.
  `.rbxlx` and `.rbxl` are normally fine; see the filesystem section of
  `../api/misc.md`.
- **Dumping is observable.** It is a burst of instance traversal and file I/O.
  Do it in a private server on an account you are willing to lose, not mid-round
  in a live game.
- **Read the dump in Studio**, not in the executor console. Studio gives you
  search across all scripts, which is the whole point of dumping.
