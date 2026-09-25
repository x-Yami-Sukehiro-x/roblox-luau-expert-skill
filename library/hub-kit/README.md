# HubKit

A UI library for Roblox script hubs, in the shape of WindUI or Obsidian: a
draggable window with a tab sidebar, sections, nine element types,
notifications, dialogs, three themes and saved configs. It is written as
ordinary ModuleScripts in folders, and `dist/HubKit.luau` is the same code
bundled into one file for an executor.

It exists as the worked example for the `roblox-hub-library` skill: a model
asked to build or improve a hub library reads this folder instead of
inventing one. Every file passes the stack's UI, slop and format linters,
and the bundle runs 107 behaviour assertions headless on every commit.

## Try it

**In an executor**, run the example. It loads the bundle from this
repository and builds a demo hub that uses every element:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/x-Yami-Sukehiro-x/roblox-luau-expert-skill/main/library/hub-kit/example/Example.luau"))()
```

**In Roblox Studio**, without an executor:

1. In **Explorer**, under **ReplicatedStorage**, press **+** and add a
   **ModuleScript**. Rename it `HubKit` with F2.
2. Open it and replace its contents with the whole of `dist/HubKit.luau`.
3. Under **StarterPlayer > StarterPlayerScripts**, add a **LocalScript** and
   paste `example/Example.luau` into it.
4. Press **Play**. The demo window opens in the middle of the screen. The
   Output window shows nothing unless something is wrong.

Studio has no `writefile`, so the Settings tab says saving is off there.
That is the kit reporting the missing function, not a bug.

With Rojo, `rojo build library/hub-kit -o HubKit.rbxm` builds the folder as
a ModuleScript tree instead of the bundle.

## Folder layout

```
src/
  init.luau              HubKit:CreateWindow, :Notify, :SetTheme, :AddTheme, :Unload
  Core/
    New.luau             New(class, properties, parent), with Theme = { Property = "role" }
    Theme.luau           palettes by role; bind, set, get, changed
    Trove.luau           one clean() releases connections, instances, threads
    Signal.luau          the Changed event on element handles
    Motion.luau          three timings and the Reduce Motion switch
    Drag.luau            drag by a handle, clamped to the screen; tap versus drag
    Config.luau          flags to JSON under HubKit/<folder>/ via writefile
    Mount.luau           gethui() in an executor, PlayerGui in Studio
    Icons.luau           verified Lucide ids by name
  Themes/
    Midnight.luau        the default dark palette
    Daylight.luau        a light palette
    Ember.luau           a warm dark palette
  Components/
    Window.luau          topbar, sidebar, search, compact mode, menu key, unload
    Tab.luau             sidebar button and scrolling page
    Section.luau         titled, collapsible group of rows
    Popup.luau           the floating panel dropdowns and colour pickers open
    Dialog.luau          a question with a safe answer
    Notifications.luau   queued toasts, icon and colour per kind
    OpenButton.luau      the chip that reopens a hidden window on touch screens
    SettingsTab.luau     theme, menu key, configs, unload
  Elements/
    init.luau            the registry that gives containers Tab:Toggle(...) and the rest
    Row.luau             the layout and five states every element shares
    Button.luau  Toggle.luau  Slider.luau  Dropdown.luau  Input.luau
    Keybind.luau  ColorPicker.luau  Paragraph.luau  Divider.luau
example/Example.luau     every element in one hub
tests/                   behaviour tests run by tools/tests/hub-kit.test.mjs
dist/HubKit.luau         the bundle; generated, never edited by hand
```

## Building a hub

```lua
local HubKit = loadstring(game:HttpGet(HUBKIT_URL))()

local Window = HubKit:CreateWindow({
	Title = "Farm Hub",
	Subtitle = "v1.2",
	Icon = "sparkles",
	Folder = "FarmHub",                  -- configs save under HubKit/FarmHub/
	ToggleKey = Enum.KeyCode.RightShift, -- the default
})

local Main = Window:Tab({ Title = "Main", Icon = "home" })
local Movement = Main:Section({ Title = "Movement" })

Movement:Toggle({
	Title = "Fly",
	Description = "WASD to steer, Space and Shift to climb",
	Flag = "Fly",
	Callback = function(on)
		fly.set(on)
	end,
})

Window:SettingsTab()
Window.OnUnload:Connect(function()
	fly.set(false)
end)
Window:LoadAutoload()
```

`Window.Flags.Fly` is the Fly toggle's handle, for reading or setting it from
anywhere in the hub.

## Elements

Every element is created on a Tab or a Section and returns a handle with the
same contract: `Get()`, `Set(value)`, `Changed` (a signal), `SetTitle`,
`SetDescription`, `SetDisabled`, `Destroy` and `Frame`. `Title` is required;
`Description` adds a wrapped second line; `Flag` saves the value in configs.

| Element | Options beyond Title, Description, Flag, Callback | Value |
|---|---|---|
| `Button` | `Icon` for the right-hand mark | none; `Press()` runs it |
| `Toggle` | `Default` | boolean |
| `Slider` | `Min`, `Max`, `Default`, `Step`, `Suffix` | number, snapped to Step |
| `Dropdown` | `Values`, `Default`, `Multi`, `AllowNone`; `Refresh(values)` | string or nil; array for Multi |
| `Input` | `Placeholder`, `Default`, `Numeric`, `Live` | string, or number when Numeric |
| `Keybind` | `Default` KeyCode, `Mode = "Hold"` | KeyCode or nil |
| `ColorPicker` | `Default` Color3 | Color3, saved as hex |
| `Paragraph` | `Content`; `Set({ Title, Content })` | none |
| `Divider` | none | none |

Two rules decide when a Callback runs:

- **`Set` always runs it**, even with the value the element already holds.
  That is what makes loading a config start every saved feature.
- **Creating an element does not**, except a Toggle with `Default = true`,
  which runs its Callback once, deferred: a switch drawn on must mean the
  feature is on. A Slider's Default is only what it shows; the kit does not
  write 16 to a WalkSpeed the game set to 20.

## Configs

Configs are JSON files in the executor's workspace folder, under
`HubKit/<Folder>/<name>.json`. Each flagged element saves through its own
`Encode` and loads through `Decode`, so colours are hex strings and keys are
KeyCode names. A config that names a flag the hub no longer has loads the
rest and skips that one.

Without `writefile` (Studio, or an executor that lacks it) `save`, `load`
and `delete` return `false` and a sentence to show the player. Nothing
pretends to have saved.

## Themes

A palette defines fifteen roles: `background`, `surface`, `raised`, `hover`,
`stroke`, `text`, `textMuted`, `accent`, `accentHover`, `onAccent`, `focus`,
`success`, `warning`, `danger`, `info`. `HubKit:AddTheme(palette)` refuses one
that misses a role. Every shipped palette keeps text at 4.5:1 or better on
every surface it sits on, and the test suite checks each pair.

## Adding an element

1. Add a Stepper module file to `src/Elements/` with `Stepper.new(container, options)`. Build
   it on `Row.button` or `Row.frame`, give it `Get` and `Set`, fire
   `self.Changed` and the Callback from `Set`, and connect everything through
   `row.trove`.
2. Add `Stepper = require(script.Stepper)` to `REGISTRY` in `src/Elements/init.luau`.
   Every Tab and Section now has `:Stepper({...})`, with Flag and search
   handled by the registry.
3. Add assertions to `tests/hub-kit.luau`, then run
   `node tools/bin/build-hub-kit.mjs` and `node --test tools/tests/hub-kit.test.mjs`.

## Bundling

`node tools/bin/build-hub-kit.mjs` resolves every `require(script...)` the way
Rojo lays the folder out and writes `dist/HubKit.luau`. A require it cannot
resolve statically is an error at build time. `--check` fails when the
bundle is older than the sources, and CI runs it.

## Testing and its limits

`node --test tools/tests/hub-kit.test.mjs` checks that the bundle is current
and compiles, that every theme meets its contrast pairs, that every icon id
is one already verified as a real image, and runs two suites under the
engine stubs in `library/tests/stubs.luau`: 95 assertions on the kit
(elements, popups, search, configs, themes, notifications, drag clamping,
compact mode, unload releasing every input connection) and 12 on the
example (respawn, rerun, unload restoring what it changed).

The stubs model signals and property writes, not rendering. They cannot show
that a label is clipped or a colour looks wrong. Before shipping a change
that moves pixels, open it in Studio and look at it at 1920 x 1080, 1280 x
720 and a 390 x 844 phone in the Device Emulator.
