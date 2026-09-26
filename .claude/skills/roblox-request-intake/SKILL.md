---
name: roblox-request-intake
description: Turning vague Roblox requests into buildable work - defaults, the style picker question, plain words. Use for make me a gui, it's broken.
---

# Request intake

Most Roblox requests arrive under-specified. That is normal and it is not the
user's job to fix. **Their vocabulary is the game, not the engine.** "Make it
look better" is a complete request from someone who can see the problem and has
no words for it.

This skill exists so under-specification never becomes either a stall
("what framework would you like?") or a guess that misses.

---

## The rule

> **Translate, decide, build, state.** Ask one grouped question when a missing
> fact changes the work, or unresolved UI style choices benefit from a preview.
> For toggle, animation and notification preferences, read
> `references/visual-choices.md`. For everyday names of UI parts ("the X", "the
> bar you drag"), read `references/ui-words.md`.

Four steps, in order, every time:

1. **Translate** the request into a concrete deliverable.
   → `references/vague-to-spec.md`
2. **Decide** technical defaults. For new or redesigned UI, show the visual guide
   and ask about unresolved toggle/motion styles together. Respect prior choices.
   → `references/defaults.md`, `references/visual-choices.md`
3. **Build** it whole. Not a sketch, not a "here's the idea" — the working
   thing, including the states nobody asked for.
4. **State** the assumptions in one short block at the end, phrased so the user
   can reject one without knowing any terminology.

The state step is what makes deciding safe. An assumption said out loud is a
question the user can answer *after* seeing something working, which is the only
point at which most people can answer it.

---

## When to ask, and it is rarer than it feels

For missing implementation facts, ask only when **both** are true:

- The two readings lead to materially different builds — different files,
  different place in the hierarchy, different data model.
- No default resolves it. (`references/defaults.md` resolves most of them.)

| Situation | Ask? | Why |
|---|---|---|
| "make me a shop" — server currency or free? | **No** | Default: server-authoritative. Build it, say so. |
| "add a gui" — which surface? | **No** | Default: `ScreenGui` HUD. Build it, say so. |
| "save my data" — what data? | **Yes, once** | Nothing to persist without knowing the fields. |
| New or redesigned UI with unresolved toggle/motion styles | **Yes, grouped** | Link labeled interactive examples; accept everyday words or “choose for me.” |
| "fix my script" with no script attached | **Yes, once** | Nothing to read. Ask for the file or the red text. |
| "make a game" with no genre | **Yes, once** | Genre changes everything downstream. |
| "make my exploit script" with no target game | **Yes, once** | Client techniques depend entirely on the target's structure. |

When you ask, **ask in their words, and offer options rather than a blank**:

> Quick one — is this an obby, a simulator, or a tycoon? Any of them work, they
> just get built differently.

Not: *"What genre, and do you want a data persistence layer?"*

---

## Never ask the user these

They are engine decisions dressed up as preferences. Decide them and move on.

- Which UI framework. (Answer: plain Instance code unless the project already
  uses one.)
- `Script` or `LocalScript`. Derived from what the code does — see
  `references/plain-language.md`.
- Where a file goes in the hierarchy.
- Easing enum names, duration constants, colour ramps, radius or spacing units.
  Ask about the visible result using the preview guide, then choose these values.
- Whether to use `task.spawn` or `coroutine`.
- Whether to add error handling. (Yes.)
- Whether to handle mobile. (Yes.)
- Whether to handle the empty and error states. (Yes.)

---

## Emotional signals are technical signals

The way frustration is phrased usually names the defect.

| They say | It usually means | Go to |
|---|---|---|
| "it looks terrible / cheap / AI-made" | No visual hierarchy; uniform surfaces | `roblox-ui` → `references/self-review.md` |
| "it doesn't work" | An error they have not read, or a silent nil | `references/error-triage.md` |
| "you didn't fix it" | The fix addressed a different layer than the bug | `references/error-triage.md` — "still broken" protocol |
| "it's broken on my phone" | Offset-only sizing | `roblox-ui` → tell R3 |
| "it lags" | Per-frame work or an unbounded connection | `roblox-performance` |
| "it resets" | Client write that does not replicate | `roblox-networking` or `roblox-executor` |
| "people are cheating" | Client authority over a server value | `roblox-game-security` |
| "it works in Studio but not the real game" | Studio runs server and client in one process | `roblox-networking` |

Full list with the reply to each: `references/vague-to-spec.md`.

---

## Writing back to someone who does not code

Detailed in `references/plain-language.md`. The short version:

- **Name Studio's own labels.** "In the Explorer, right-click
  `StarterPlayerScripts`" beats "put this in the client scripts folder".
- **Say what to click, in order.** Insert what, name it what, paste where, press
  which button to test.
- **One paragraph of what it does, in game terms**, before the code.
- **No unexplained jargon.** First use gets four words of explanation, then use
  the term normally. Do not explain it twice.
- **Never say "simply", "just", or "obviously".** If it were obvious the request
  would not exist.
- **Say what to expect when it works.** Without that, a working script and a
  broken one look identical to someone who does not know what to look for.

---

## Scope discipline

Under-specified does not mean "build everything you can imagine".

Build the thing asked for, completely — including its non-happy states, mobile
layout and teardown, because those are part of "working", not extras. Do not add
a settings menu to a request for a button.

If something genuinely needed is missing — a shop with no currency source —
build the shop, stub the currency behind one clearly-marked function, and say
which one line to point at real data.

---

## Handing off

Intake is a doorway. Once the request is concrete, load the skill that owns it
via the router in `roblox-luau-expert`. Intake stays loaded for the write-back:
the answer still has to be readable by the person who asked.

## Works with

- `roblox-ui`: weak-prompt.md turns a one-line UI request into a shippable screen.
- `roblox-game-design`: defaults for "make me a game" once the genre is known.
- `roblox-attempt-memory`: "it's broken again" starts from the ledger.
- `roblox-reply-craft`: the reply shape.
- `roblox-improve`: for make it better, a ranked list instead of a rewrite.
- `roblox-hub-library`: when the vague request is a script hub.
- `roblox-ui-from-scratch`: real controls and testable behavior from a short UI request.
