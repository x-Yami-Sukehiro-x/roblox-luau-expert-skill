# Vague request to concrete spec

A lookup table. Left column is what people actually type. Right column is what
to build, decided, so there is nothing to deliberate about.

Everything here assumes the defaults in `defaults.md` unless the row overrides
them.

---

## "Make me a ___"

| They type | Build | Also build, unasked, because it is part of working |
|---|---|---|
| "a gui" / "a ui" | `ScreenGui` + one centred panel: header with title and close, content area, footer | Open/close key, mobile size, motion on open |
| "a menu" | Tabbed panel: tab rail + page container + footer | Tab state persists while open; keyboard and gamepad reachable |
| "a shop" | Server-authoritative purchase flow + grid of items + confirm modal | Insufficient-funds state, already-owned state, purchase failure toast |
| "an inventory" | Scrolling grid of slots from a server-held list | Empty state, loading state, slot count that adapts to width |
| "a leaderboard" | Sorted rows — rank, name, value — with pooled row instances | Empty state, "you" row highlighted, value formatting |
| "a settings menu" | Sectioned list of toggles and sliders, saved per player | Reset-to-default, immediate apply, persistence across rejoin |
| "a shop gui but for my simulator" | As shop, using the currency name from their own words | Same as shop |
| "a health bar" | HUD or billboard bar bound to `Humanoid.HealthChanged` | Smooth fill motion, damage flash, hide at full health if HUD |
| "a daily reward" | Server-side claim with a timestamp in the data store | Already-claimed state, time until next, streak reset |
| "a notification" | Toast system with a queue | Dedup, severity, auto-dismiss, manual dismiss |
| "a loading screen" | `ReplicatedFirst` screen removed once assets preload | A real progress signal, never a fake timer |
| "a game" | Ask the genre once. Then one working loop end to end | Spawn, the core verb, a progression hook, data saved |
| "an admin panel" | Command list gated by a server-side allowlist | Never trust a client claim of admin; log every command |
| "an exploit script" / "a script for X game" | Ask which game once, then `roblox-executor` | Feature detection, clean unload, `getgenv` namespacing |
| "a hub" | Executor UI with tabs, toggles, config persistence | Unload path, re-execution safety, usable at 360 px wide |

---

## "It's broken"

Never answer this with only a question. Answer with a **diagnostic plus the most
likely cause**, so the user's next message is useful even if they do not know
what to include.

> Two things narrow this down fast: the red text in the Output window
> (View then Output in Studio), and whether it worked before. Meanwhile, the
> most likely cause given what you described is —

| They type | Read as | First check |
|---|---|---|
| "it doesn't work" | An error is being thrown and not read | Ask for Output text; meanwhile check nil access at the top of the script |
| "nothing happens" | The script is not running, or the event never fires | Right script type in the right parent? Connection made before the event? |
| "it works in Studio but not the game" | Server and client split | Studio Play Solo fuses both. See `roblox-networking` |
| "it worked yesterday" | Roblox shipped, or the saved data changed shape | Check deprecations, check the data schema |
| "it only breaks sometimes" | A race after a yield, or missing data | Re-validate after every yield |
| "my friend can't see it" | Client-only change | `roblox-networking`, replication |
| "it resets when I change it" | Client write to a server-owned value | `roblox-executor`, value persistence |
| "half of it works" | One remote or one branch failing silently | Check every `pcall` result |

Full error table: `error-triage.md`.

---

## "Make it look better"

For unresolved toggle or motion preferences, show the labeled interactive guide
and ask one grouped question using `visual-choices.md` before UI code. A visible
example lets the user choose without design vocabulary. Match existing choices
and references; decide technical details yourself.

Order of operations, highest visible impact first:

1. **Hierarchy** — make one thing on the screen obviously the most important.
   Size, weight and space, not colour.
2. **Spacing rhythm** — every gap from one scale; related things closer than
   unrelated things.
3. **Surfaces** — two or three levels, with visibly different steps between them.
4. **Type scale** — four or five sizes, and no `TextScaled` on body text.
5. **One accent, three to five uses** — on what matters, nowhere else.
6. **States** — hover, press, disabled and selected visibly different.
7. **Motion** — one short tween on open, one on press. Nothing else.

Apply all seven, then run `roblox-ui` reference `self-review.md` and report the
score. Full procedure: `roblox-ui` reference `build-order.md`.

| Their phrasing | What is actually wrong, nearly always |
|---|---|
| "looks AI-generated" | Uniform surfaces, uniform spacing, no focal point |
| "looks cheap" | Default font at default size; grey on grey |
| "looks empty" | No content density and no empty-state copy |
| "looks cluttered" | No grouping; everything at one level of emphasis |
| "looks dated" | Hard corners with a flat 1px border on everything |
| "doesn't feel responsive" | No press state, and nothing moving under 120 ms |
| "too big" / "too small" | Offset-only sizing, or no `UIScale` for DPI |
| "make it pop" | Wants contrast, not saturation. Raise hierarchy, not colour count |
| "make it clean" | Wants fewer elements and more space, not more polish |
| "make it modern" | Wants soft depth, a real type scale, restrained colour |
| "make it look like [popular game]" | Copy the *structure* — where things sit, how dense — not the assets |

---

## Words users use for engine concepts

Translate silently. Do not correct their vocabulary; mirroring it is what makes
the answer readable, and the terms are unambiguous in context.

| They say | They mean |
|---|---|
| "the game" | The place, or the running server, from context |
| "the code" / "the script" | Possibly several scripts |
| "the gui" | A `ScreenGui` and everything under it |
| "button" | Any tappable thing — `TextButton` or `ImageButton` |
| "menu" | A panel, a whole screen, or a tab within one |
| "server" | Server-side code, or the running instance |
| "lag" | Frame rate, ping, or a slow response. Ask which only if the fix differs |
| "glitch" | Any unexpected behaviour |
| "coins" / "cash" / "gems" / "bucks" | The currency. **Use their word in the code** |
| "load" / "save" | Data persistence |
| "pet" / "unit" / "mob" | Whatever entity the game is about. Their word wins in naming |
| "inject" / "execute" | Run through an executor |
| "hook" | Intercept a function |
| "bypass" | Avoid a check, usually an anti-cheat |
| "dump" | `saveinstance` output, or decompiled source |

That last block matters for naming. Code that says `Currency` when the game says
`Gems` reads as imported from somewhere else — which is precisely the tell
catalogued in `roblox-code-craft`.

---

## One-word and fragment requests

| Input | Do |
|---|---|
| a pasted error, nothing else | Diagnose it. Give the fix and the line. No preamble |
| a pasted script, nothing else | Review it. Lead with the defect that will bite first |
| "help" | Ask what they are building, in one line |
| "?" | Re-state the last delivery in one sentence, then offer the next step |
| "make it better" after code | Apply the delivery checklist and the UI rubric; report what changed |
| "again" / "no" | The last output missed. Re-read the original request for the part that was dropped — do not re-generate the same thing differently |
| a game link or place id | Say what can be told from a link alone (very little) and ask which behaviour they care about |
| a screenshot of a UI | Describe what is wrong with it against the anti-slop catalog, then rebuild |

---

## The reply shape

Every answer to a vague request has the same four parts, in this order:

1. **One line of what you built**, in their words.
2. **The code**, complete and runnable.
3. **Where it goes**, in Studio's own labels.
4. **Assumptions**, as bullets, each phrased so it can be rejected without
   jargon. Three maximum — if there are more than three, the request needed a
   question.

No preamble before part 1. No summary after part 4.
