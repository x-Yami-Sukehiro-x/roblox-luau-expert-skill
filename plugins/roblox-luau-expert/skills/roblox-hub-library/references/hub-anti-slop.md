# What makes a hub look generated

These are the tells that make a player close a hub before trying a feature,
and what replaces each. They add to `roblox-ui/references/anti-slop-catalog.md`,
which covers game UI in general.

| Tell | Why it reads as generated | Instead |
|---|---|---|
| A loading screen with a progress bar that fills on a timer | It measures nothing and delays everything | Build the window; show a toast if loading a library takes over a second |
| Rainbow, animated or gradient window borders | Motion that carries no information, and it costs a frame update | A 1 px stroke one step above the surface |
| Emoji or font glyphs as tab icons ("⚔", "★") | They sit on the text baseline and change weight between fonts | Image icons from a verified set (`library/hub-kit/src/Core/Icons.luau`) |
| A different accent colour per tab | Colour stops meaning "on" or "selected" | One accent role for the whole hub |
| 10 px text to fit more rows | Unreadable on a phone | 12 px floor, sections and search to fit more |
| "Made by" watermark over the content | Takes space from the player's controls | The credit in the subtitle or a Paragraph in Settings |
| A notification on every toggle | Twenty toasts nobody reads, and real errors get lost | Notify on results the player cannot see: saved, failed, loaded |
| A key system that gates nothing | A step between the player and the hub with no purpose | Nothing; or a real one the user asked for |
| Every label in capitals, or every one ending in "!" | Shouting | Sentence case, labels that name the thing |
| Tabs named Main, Misc, Other, Extra | The player cannot guess where anything is | Name tabs by what is in them: Movement, Visuals, Combat |
| Toggles that say "Enable X" | The switch already says enable | The feature's name: "Fly", "Infinite jump" |
| Blur or glass behind the window | Heavy, and unreadable over bright maps | A solid surface; transparency only on the dialog scrim |
| Sounds on hover | Noise on every mouse move | Silence, or one soft click on press |
| Success prints in the console | "Hub loaded!" says nothing the window does not | Nothing; the Output stays for errors |

## Copy

Rows read as the player's intent. Title is the feature, description is the
one fact the player needs before switching it on:

- "Fly" with "WASD to steer, Space and Shift to climb"
- "Walk speed" with "Applied again after every respawn"
- "Auto collect" with "Only coins within 60 studs"

Buttons that act say what they do: "Rejoin server", "Copy position",
"Unload". A dialog's buttons name the outcome ("Delete", "Keep"), never
"Yes", "No" or "OK".
