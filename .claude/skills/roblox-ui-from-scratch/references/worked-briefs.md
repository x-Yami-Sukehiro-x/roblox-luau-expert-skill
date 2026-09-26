# Worked briefs: three vague requests

Each request below arrived with nothing else, or with one file. The brief is
what was decided before building, in the order `../roblox-ui/references/weak-prompt.md`
sets, and what was stated back to the user. None of them needed a question
beyond the grouped style question, and two did not need that.

## "make me a gui" with an executor script attached

The script has `getgenv().Features` with `Fly`, `Noclip`, `Speed`, `ESP`
and `Fullbright`, each with `set(on)`, and a `WALK_SPEED` constant.

| Decision | Chosen | From |
|---|---|---|
| Surface | Executor hub under `gethui()` | `getgenv` in the script |
| Archetype | Script hub, no hero | `screen-archetypes.md` |
| Content | 5 toggles and 1 slider, named Fly, Noclip, Walk speed, ESP, Fullbright | The script's features and constant |
| Grouping | Movement (Fly, Noclip, Walk speed), Visuals (ESP, Fullbright) | What the player does |
| Library | HubKit | `roblox-hub-library`; not a second framework |
| Feedback | Toggle state only; a notice when a feature fails to start | `roblox-script-feedback` |
| Saved | Toggle and slider flags across reruns | HubKit config |

Stated back:

```text
Built as: HubKit hub, 2 tabs (Movement, Visuals), 6 controls wired to your Features table.
Fly and Noclip start off; Walk speed restores the game's value on unload.
Style: HubKit defaults. Say "different toggles" to pick from the visual guide.
```

## "make a shop ui, make it look good" in a game project

No files beyond a `ShopItems` ModuleScript with eight items (name, price,
icon id, description).

| Decision | Chosen | From |
|---|---|---|
| Surface | Game `ScreenGui` in `StarterGui`, LocalScript client | A game project |
| Archetype | Shop: item grid, detail panel, one Buy button | `screen-archetypes.md` |
| Hero | The selected item's detail panel and its Buy button | One accent, the purchase |
| Content | The eight real items; prices and descriptions from the module | Never placeholder items |
| Flow | Select, read price and effect, buy; pending state; owned; "120 more coins" when unaffordable | `roblox-ux-design/references/flows.md` |
| Authority | The server decides the purchase and the balance | The router's first question |
| States | Empty (no items loaded), pending, owned, unaffordable, failed | Built now |

The one grouped question was asked at the end: toggle, motion and
notification styles, with the picker link. Everything else was decided.

## "i need a ui for my farming script" with no file

Nothing to read. The request names the purpose: farming.

| Decision | Chosen | From |
|---|---|---|
| Surface | Executor hub | "my farming script" |
| Content | A shell: Auto farm toggle, Interval slider (0.5 to 5 s), Stop all button, status line | The minimum the purpose needs |
| Wiring | Each control calls one clearly named function the user fills in, and the status line says "Not connected to a farm yet" until they do | No invented remotes or fake farming |
| Asked | Paste the farming script, or the game's dump, to connect real features | The one missing fact that changes the work |

Stated back:

```text
Built as: a working window with the farm controls; nothing in it farms yet.
Paste your farming script or the game's scripts and I will connect each control.
```

A shell that says what it is beats a full window of features that do nothing.

## What every brief had

- The surface, archetype and grouping, decided from the request and files.
- Content from real sources, or a shell that says it is one.
- The flow in a few lines, and every state the flow creates.
- Who owns each value that matters.
- One question at most, asked at the end, with the decisions beside it.
