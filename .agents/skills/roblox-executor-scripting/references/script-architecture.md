# Script architecture for multi-game hubs

A hub that supports one game is a script. A hub that supports ten is a
program, and it needs the parts a program has: an entry point, routing,
modules, shared services and one teardown.

## Layout

```
loader.luau            the file the player executes: fetch, route, start
shared/
  ui.luau              the HubKit window, built once
  session.luau         the hub-loader session: own() and unload()
games/
  universal.luau       fly, ESP, speed: works anywhere
  <game>.luau          one module per supported experience
```

For a single file (most user requests), keep the same sections in one
script, in this order: services, capability bind and assert, session, UI,
features, unload.

## Routing by GameId

`assets/hub-loader.luau` is the tested loader. It takes a hub name, a table
from `game.GameId` to an entry, and a universal entry:

```lua
local loadHub = loadstring(game:HttpGet(LOADER_URL))()

local session = loadHub("FarmHub", {
	[GAME_ID] = { name = "The game's name", start = startGameFeatures },
}, { name = "Universal", start = startUniversalFeatures })
```

What it guarantees, each checked by `library/tests/recipes/hub-loader.luau`:

- the game's entry runs when its GameId matches, the universal one otherwise;
- a second run unloads the first session before starting;
- cleanups run newest first, each once;
- a `start` that errors halfway stays registered, so the next run still
  cleans up the features it had already started.

Every feature a module starts is paired with its cleanup at the moment it
starts: `session:own(function() fly.set(false) end)`.

## Fetching modules

A loader that fetches game modules over HTTP has three failure modes: the
URL moved, the host is down, or the module errors. Handle them as boundaries:

- **Pin to a commit**, not to `main`, for anything players rely on; a
  breaking push otherwise reaches every player at once.
- **One `pcall` around the fetch and compile**, reporting which module and
  why, then continuing with the universal set rather than stopping the hub.
- **Cache to the executor's workspace** (`writefile`) when file functions
  exist, so a CDN outage does not stop the hub; feature-detect them.

## Versions

Put a version string in the loader and show it in the window subtitle. When
players report a bug, the version is the first question, and a hub without
one cannot answer it.

## Shared state

Features communicate through the session or the UI's `Flags`, never through
new globals. `getgenv()` holds exactly one entry per hub: its session.

## Unsupported games

When the GameId is not in the table, say so once, in the window: "No game
features for this experience; universal features are on the Universal tab."
Do not guess which game module might work.
