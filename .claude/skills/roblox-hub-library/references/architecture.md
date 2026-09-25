# Hub library architecture

How HubKit (`library/hub-kit/` at the plugin root) is put together, and why,
so the same structure can be rebuilt under another name or extended without
breaking what it guarantees. WindUI (`Footagesus/WindUI`, MIT) uses a similar
split into `components/`, `elements/`, `modules/` and `themes/`; nothing here
copies its code.

## Layers

| Layer | Files | Knows about |
|---|---|---|
| Entry | `init.luau` | Window, Notifications, Theme, Config, Elements |
| Components | `Window`, `Tab`, `Section`, `Popup`, `Dialog`, `Notifications`, `OpenButton`, `SettingsTab` | Core, Elements, each other downward |
| Elements | `init` (registry), `Row`, one file per element | Core, Popup |
| Core | `New`, `Theme`, `Trove`, `Signal`, `Motion`, `Drag`, `Config`, `Mount`, `Icons` | nothing above Core |
| Themes | one palette per file | nothing |

Requires only point down or sideways within a layer. `Section` requires
`Elements`, and `Elements` never requires `Section`; a cycle would make the
bundle's loader assert.

## The container interface

A Tab and a Section are both *containers*. Elements are written against
these fields and nothing else, which is why one registry serves both:

```lua
container = {
	kit = kit, -- shared state: windows, the open popup, capturing, toasts
	window = window, -- Flags, config, applySearch
	frame = listFrame, -- where rows are parented; has a UIListLayout
	trove = trove, -- owns everything this container makes
	entries = searchEntries, -- rows the window search filters
	section = sectionOrNil, -- so search can hide a section with no matches
	nextOrder = function(self)
		self.order += 1
		return self.order
	end,
}
```

`Elements.install(container)` adds one method per element. Each method calls
`create`, which:

1. rejects a `Flag` that is already used, **before** building anything, so a
   rejected element leaves no half-built row;
2. calls the element's `new(container, options)`;
3. registers the flag with the window's config and `Flags` table;
4. adds a search entry;
5. puts the undo for 3 and 4 in the element's own trove.

## Ownership and teardown

Every instance and connection is added to a trove, and troves nest:
window, then tab, then element or section, then popup. `Trove:clean()`
releases newest first, so a connection on a frame is released before the
frame. A Trove's `clean` also handles threads (`task.cancel`), Signals, nested
troves and plain functions.

Two teardown details that matter in an executor:

- **A thread cannot cancel itself.** A toast's dismiss timer may be the
  thread running the dismissal; HubKit checks `coroutine.running()` before
  `task.cancel`.
- **Instances are not weak keys.** Theme bindings hold instances strongly
  and release each on its `Destroying` event. A weak-keyed table of Instances
  can lose an entry while the instance is still on screen, and that instance
  then misses every theme switch.

The test suite counts `UserInputService` connections before building a hub
and after unloading it, and fails if they differ.

## Rerun safety

Running a hub script twice is the most common way a player "breaks" it:
two windows, two sets of connections, features toggled by both. The hub,
not the library, keeps a handle in `getgenv()` and unloads the previous
session first:

```lua
local session = if typeof(getgenv) == "function" then getgenv() else _G
if session.MyHub then
	session.MyHub:Unload()
end
session.MyHub = Window
Window.OnUnload:Connect(function()
	if session.MyHub == Window then
		session.MyHub = nil
	end
end)
```

`_G` is the Studio fallback, so the same script is testable there.

## Where the ScreenGuis live

`library/hub-kit/src/Core/Mount.luau` returns `gethui()` when the executor has it and the local
player's `PlayerGui` otherwise. Every kit ScreenGui sets `ResetOnSpawn =
false`, `ScreenInsets = CoreUISafeInsets` and its own `DisplayOrder`:
window 100, popups 110, dialogs 120, notifications 130. Separate ScreenGuis
keep a dropdown from being clipped by the tab's ScrollingFrame and keep a
dialog above every popup.

## Search

The window search filters the selected tab's entries by a lower-cased
"title description" string with a plain `string.find`. While a query is
active, a collapsed section still shows its matching rows, a section with
no matches hides, and an empty-state line names the query. Clearing the
box restores the collapsed state.

## Bundling

Executors run one file, so the folder is bundled. HubKit's
`tools/bin/build-hub-kit.mjs`:

- resolves each `require(script...)` statically with Rojo's layout rules
  (`library/hub-kit/src/Elements/init.luau` *is* `Elements`, so
  `script.Toggle` inside it is the Toggle module beside it);
- rejects anything it cannot resolve: a variable, a string path, a
  `Parent` above the root;
- wraps each module in a function in one table, loads them on first
  require, caches the result and asserts on a require cycle;
- has `--check`, which CI runs so the bundle can never trail the sources.

For a library that uses string requires (`require("./Toggle")`), darklua's
`bundle` rule with `require_mode: "path"` does the same job; WindUI builds
that way.

## Studio and executor from one source

The same sources run as a ModuleScript tree in Studio (Rojo, or the bundle
pasted into one ModuleScript) and as the bundle in an executor. Three things
make that true, and none of them is a silent fallback:

- `Mount` picks `gethui()` or `PlayerGui`;
- `Config` reports saving as off when file functions are missing;
- the example requires `ReplicatedStorage.HubKit` when it exists and
  otherwise loads the bundle from its URL.
