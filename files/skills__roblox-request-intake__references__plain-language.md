# Writing back to someone who does not code

The code being correct is half the delivery. The other half is that the person
who asked can actually get it running.

---

## The placement block

Every script handed over gets one. Use Studio's own labels, capitalised the way
Studio capitalises them, in click order.

> **Where this goes**
>
> 1. In Studio, open the **Explorer** panel (View then Explorer if it is hidden).
> 2. Find **StarterPlayer**, open it, and find **StarterPlayerScripts** inside.
> 3. Hover over **StarterPlayerScripts** and click the **+** button.
> 4. Choose **LocalScript**.
> 5. Rename it to **ShopMenu** — click it once, then press F2.
> 6. Delete the line already in it, and paste this in.
> 7. Press **Play** to test.

Seven numbered steps is not too many. Two sentences of prose is too few, because
the person who needs the block does not know where StarterPlayerScripts is.

---

## Script types, explained once

Only explain when the user has shown they do not know. Explaining twice reads as
condescension.

> Roblox runs two kinds of code. A **Script** runs on the server — the shared,
> trusted copy that decides things like how much money you have. A
> **LocalScript** runs on each player's own device, and handles what only they
> see, like menus. This one is a LocalScript because it draws a menu.

The one-line version, for a user who clearly knows:

> LocalScript, in `StarterPlayerScripts`.

---

## Naming the parents in plain words

| Studio name | What it is, in one clause |
|---|---|
| `Workspace` | the 3D world — everything you can see and walk on |
| `ServerScriptService` | server code, which players cannot read or change |
| `ReplicatedStorage` | shared things both the server and players can reach |
| `StarterPlayerScripts` | code that starts for each player when they join |
| `StarterCharacterScripts` | code that restarts every time they respawn |
| `StarterGui` | screens that are copied to each player |
| `PlayerGui` | the live copy of a player's screens while they play |
| `ReplicatedFirst` | loads before anything else — loading screens live here |
| `Lighting` | sky, time of day, fog, and post-processing effects |

---

## Jargon policy

First use gets four to eight words of explanation, in the same sentence. After
that, use the term normally.

> The script listens to a **RemoteEvent** — the channel players use to ask the
> server to do something — and checks the request before acting on it.

Never explain the same term twice in one reply. Never stack three explanations
into one sentence.

Terms that almost always need the four-word gloss for a non-technical user:
RemoteEvent, DataStore, yield, instance, parent, pcall, module, replication,
client, server, nil.

Terms that do not, because the everyday meaning is close enough: button, menu,
text, colour, size, sound, animation, folder, save, load.

---

## Words to avoid

| Do not write | Because |
|---|---|
| "simply", "just", "obviously", "trivially" | If it were, the question would not exist |
| "as you know" | They may not |
| "basic" for their question | It is not basic to them |
| "you should already have" | They may not, and now they are stuck |
| unexplained abbreviations — `SSS`, `RS`, `PS` | The Explorer does not use them |
| "boilerplate" without saying what to do with it | Ambiguous: keep it or replace it? |

---

## Say what success looks like

Without this, a working script and a broken one look identical.

> **When it works:** pressing **Right Shift** slides a panel in from the left
> with three tabs across the top. Clicking a tab swaps the contents. Pressing
> Right Shift again slides it away. Nothing appears in the Output window — no
> news is good news here.

Include, where it applies:

- What to press or click.
- What appears, and roughly where.
- How long it takes, if it is not instant.
- What the Output window should show — including "nothing".
- What it does on a phone, if that differs.

---

## Reporting a problem you cannot fix

Be specific about what is blocked, offer the nearest thing that works, and do
not soften it into vagueness.

> The saving part needs to run on the server, and the script you sent is a
> LocalScript, so it cannot save. Two options: I can split this into a
> LocalScript for the menu plus a Script for the saving — that is the normal
> way — or if the values only matter for this session, it can stay as one file.
> The split is what most games do. Want me to write both halves?

---

## Diagnosing without the file

Users frequently describe a problem without providing anything to read. Lead
with the most likely cause, not with a request.

Structure:

1. The single most likely cause, and its fix.
2. The second most likely, one line.
3. What to send if neither lands — named exactly.

> Most likely: the script runs before the player's character exists, so
> `Character` is empty. Adding `player.CharacterAdded:Wait()` before that line
> fixes it. Second most likely: it is a `Script` where it needs to be a
> `LocalScript`. If neither is it, paste the red line from the **Output** window
> (View then Output) and I will read it directly.

---

## Follow-ups

| They say | Do |
|---|---|
| "where do I put this" | Give the placement block. They did not read it, or it was not there |
| "it says [error]" | Go to `error-triage.md`. Do not ask for more first |
| "can you make it [colour]" | One token change. Show only the changed line, name the file |
| "can you add [feature]" | Add it to the existing code and repost the whole file. Never a diff fragment a beginner has to splice |
| "this is too long" | They want the file, not an explanation. Lead with the code |
| "i don't understand" | Re-explain the one step they stopped at, not all of them |

**Repost whole files.** Asking someone who does not code to merge a fragment is
how a working script becomes a broken one.
