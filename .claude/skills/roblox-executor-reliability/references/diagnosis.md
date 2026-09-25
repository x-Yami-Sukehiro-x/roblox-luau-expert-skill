# "It doesn't work"

The same complaint can have ten causes, and a new version of the script
guesses at one of them. Ask in this order, one question at a time, and let
each answer remove a branch.

## 1. Did it run?

Ask what the executor's console (F9, or the executor's own output) showed
when the script ran.

| Answer | Next |
|---|---|
| a red error line | read it. `needs gethui` is the capability assert: the executor lacks that function; say so, do not work around it. Anything else points at a line |
| nothing at all | the script may not have run: ask whether the executor reported running it, and whether it was the whole file |
| it ran, no error | question 2 |

## 2. Is the feature on, and is anything else on?

Send `../../roblox-executor-features/assets/feature-doctor.luau` and ask for
what it prints. Five seconds later it reports:

- the executor's name and version, when the executor says;
- each loaded feature: on, off, or unloaded but still registered (a stale
  rerun);
- pairs of features that are on together and interact, with what the player
  sees;
- the character: missing, seated, anchored, platform-standing without fly;
- whether streaming hides distant parts and players;
- every watched property that changed while it watched, with a count.

## 3. Read the doctor

| The doctor says | It means | Do |
|---|---|---|
| the feature is not listed | the feature script never finished | back to question 1 |
| "unloaded but still registered" | an old session is still in the namespace | rerun the feature; it unloads the old one |
| two features "are both on" | the pair interacts | turn one off, or accept the stated behaviour |
| "seated" or "anchored" | the body cannot move | leave the seat; wait for the game's anchor |
| a property changed 3 or more times | something keeps writing it | if a feature holds it, that is the fight; decide whether to hold harder or accept the game's value |
| a property changed once | one write, likely a respawn or round start | apply on that event |
| nothing changed, feature on, no effect | the effect is on the server's side, or the game checks elsewhere | the value is not client-owned; go to the dump |

## 4. Record, then change one thing

Write the failed attempt into the ledger before the next version:

```bash
node tools/bin/attempt-ledger.mjs add --status failed --title "speed does nothing in this game" --tried "speed.luau with WalkSpeed held by GetPropertyChangedSignal" --saw "doctor: Humanoid.WalkSpeed changed 40 times in 5 s"
```

Then change the one layer the evidence points at, and say in the reply which
evidence led there. `plan` the new approach first; if it matches a failed
entry, the evidence has to say what is different.

## What not to do

- Re-send the same script with cosmetic changes.
- Add a fallback that tries three places in turn (K8): after the next game
  update it edits the wrong object and reports success.
- Explain the failure as detection or a patched executor without evidence.
  "It worked and then it didn't" is usually respawn or a game script.
