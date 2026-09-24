# Words on the screen: labels, descriptions, subtitles

The text inside a UI is read in half a second by someone playing a game. The
generated version reads like a product launch: *"Seamlessly enhance your
gameplay experience with our powerful auto-farming solution."* The player
wanted two words and a switch.

This file is for text in the interface: titles, tab names, row labels, row
descriptions, subtitles under a heading, button labels, notifications, empty
states. For the length of chat replies, see `roblox-reply-craft`.

---

## Lengths

| Text | Length | Example |
|---|---|---|
| Window title | 1-3 words | Blox Hub · Daily reward |
| Tab name | 1-2 words | Combat · Teleports |
| Section heading | 1-2 words | Farming · Movement |
| Row label | 1-4 words, the thing it changes | Auto farm · Walk speed |
| Row description (optional) | one line, under 50 characters, says what the player gets or what it costs | Collects coins within 30 studs |
| Button | verb + object, with the amount if there is one | Buy for 250 coins · Claim day 4 |
| Notification | under 40 characters, one line; the result, not the process | Auto farm is on · Not enough coins |
| Empty state | what is missing + how to get it, two short sentences | No pets yet. Hatch an egg to get one. |
| Error | what failed + what to do, one line | Couldn't save. Try again in a moment. |
| Subtitle under a title | usually none; if needed, one line under 60 characters | Changes apply straight away |

A row description exists only when the label cannot say it: a limit, a cost, a
side effect. "Enables the auto farm feature" under **Auto farm** says nothing
and is deleted.

## Rules

1. **Name the thing in the game's words.** The game says *coins*, the UI says
   coins, not "currency". It says *rebirth*, not "prestige system".
2. **Labels are nouns or verbs, not sentences.** No full stops in labels,
   tabs, buttons or headings.
3. **Sentence case**: "Walk speed", not "Walk Speed" or "WALK SPEED", except
   where the chosen direction uses small caps headings (then only headings).
4. **Buttons say what happens**: *Buy for 250 coins*, *Sell Golden Sword*,
   *Keep it*. Never *OK*, *Confirm*, *Submit*, *Yes*.
5. **Numbers are numbers**: "3 left", "12 / 20", "5h 12m". Not "three
   remaining".
6. **Every tab name is different in meaning.** *Settings*, *Options* and
   *Config* as three tabs are one word three times; name them for what they
   hold: *Controls*, *Audio*, *Graphics*.
7. **No decoration in text**: no emoji, no ✨, no "→" arrows, no ALL CAPS
   shouting, no exclamation marks outside a genuine reward moment.

## Words that mark text as generated

Delete them, then rewrite what is left in the game's words. The UI designer's
checks flag the first row.

| Delete | Because |
|---|---|
| seamless, effortless, elevate, unleash, ultimate, experience the, unlock the power, enhance your | marketing voice; says nothing about the game |
| powerful, advanced, smart, intelligent, robust, cutting-edge | claims no player can check |
| simply, just, easily | the player decides what is easy |
| feature, functionality, solution, system (as in "the farming system") | names the code, not the thing |
| "Welcome to …", "Get ready to …", "Dive into …" | a preamble before the content |
| "Toggle to enable …", "Click here to …" | describes the control instead of the result |

Before and after:

| Generated | Written |
|---|---|
| Unleash the power of automated farming | Auto farm |
| Seamlessly teleport to any location with ease | Teleport to a zone |
| This feature allows you to adjust your walk speed | Walk speed · 16 to 100 |
| Successfully enabled auto farm feature! | Auto farm is on |
| Oops! Something went wrong. Please try again later. | Couldn't claim. Try again in a moment. |
| Welcome to the ultimate shop experience | Shop |

## Checking

Read every string aloud, in screen order. Each should be something a player
would say while playing. Count characters for descriptions (50), notifications
(40) and subtitles (60); cut, do not shrink the text size to fit.
