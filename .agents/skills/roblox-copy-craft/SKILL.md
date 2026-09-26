---
name: roblox-copy-craft
description: Words without AI slop - labels, descriptions, notices, errors, names, comments, commit messages. Use for any text a reader sees.
---

# Words that read as written, not generated

Generated text has a sound: *"Seamlessly unleash the power of automated
farming!"* Players and reviewers hear it in half a second and stop trusting
everything near it, including code that works. The cure is not a thesaurus.
It is saying the specific thing: what the control changes, what failed,
what the value holds, what the commit fixed.

This skill covers every surface where words appear. Where a surface has its
own detailed rules, it points there:

| Surface | Detailed rules |
|---|---|
| Labels, tabs, buttons, descriptions, empty states in game UI | `roblox-ui/references/ui-copy.md` |
| A script hub's rows, tabs and notices | `roblox-hub-library/references/hub-anti-slop.md` |
| Tooltips, helper lines, locked reasons | `roblox-ui-tooltips` |
| Variable, function and table names | `roblox-code-craft/references/naming.md` |
| Comments and error messages in code | `roblox-code-craft/references/anti-slop-code.md` |
| The reply to the user | `roblox-reply-craft` |

## Five rules for every surface

1. **Name the effect, in the game's words.** `Collect coins within 50 studs`,
   not `Auto collection feature`. The game says coins, so the text says coins.
2. **Numbers over adjectives.** `Every 0.5 s`, `16 to 100`, `3 left`. Never
   fast, huge, many, instant.
3. **No self-praise.** Nothing is ultimate, powerful, seamless, smart,
   advanced, premium or OP in its own label. A player can check a number;
   they cannot check an adjective.
4. **One job per string.** A label names; a description adds the one fact the
   label cannot (a limit, a cost, a side effect); a notice reports a result.
   A description that repeats its label is deleted.
5. **Say what happened, not that something did.** `Couldn't save: no file
   access`, not `An error occurred`. `Auto farm stopped: Remotes.Collect is
   missing`, not `Something went wrong!`.

`lint-luau-slop` counts the tells in code: `W-HYPE` for marketing words in
`Text`, `Title`, `Description`, `Content`, `Subtitle` and `Name`,
`W-EMOJI` for decoration in messages, `W-SUCCESSPRINT`, `E-ERRPROSE`,
`W-GENERIC`, `E-PROVENANCE`, `E-EDITNOTE`. It runs inside `check-file`.

## Words that mark text as generated

| Delete | Because |
|---|---|
| seamless, effortless, unleash, elevate, powerful, cutting-edge, next-level, supercharge | Marketing voice; says nothing about the game (`W-HYPE`) |
| successfully, "has been enabled", "is now ready" | Narrates instead of reporting a result (`W-HYPE`, `W-SUCCESSPRINT`) |
| advanced, smart, intelligent, robust, premium, ultimate (as praise) | Claims no one can check. Fine as the game's own term: an "Ultimate" ability, Roblox Premium |
| comprehensive, various, several, a number of | Hides the count; give the number |
| "This feature allows you to", "Toggle to enable", "Click here to" | Describes the control, not the result |
| "Welcome to", "Get ready to", "Enjoy!" | A preamble before the content |
| emoji, `!`, ALL CAPS, `→` in labels | Decoration that carries no information |

In code and prose for developers, add: enhance, leverage, utilize, robust,
streamline, "it's worth noting", "in order to", "various improvements".

Before and after, across surfaces, are in [rewrites.md](references/rewrites.md).

## Names

A name says what the value holds in the game's vocabulary: `coinsPerSecond`,
`sprintController`, `remotes.collect`. Not `data`, `info`, `temp`, `result`,
`handler`, `manager`, `obj`, and not `plr`, `btn`, `pos`, `frame2`. From a
decompiled dump, `v14` becomes a name only after the source proves what it
holds; until then say it is unknown (`E-DECOMPNAME`).

## Comments

A comment carries a fact the code cannot show: an engine quirk, an ordering
constraint, why a number is what it is. It never narrates where the code
came from ("Based on the uploaded script", `E-PROVENANCE`), never logs an
edit ("-- Fixed:", `E-EDITNOTE`), and never restates the line below
(`E-RESTATE`). Four lines with one fact in them are one line.

## Commit messages, READMEs and changelogs

- **Subject:** imperative, specific, about 60 characters: `Stop the auto farm
  firing faster than the game's cooldown`. Not `Update files`, `Improve
  various things`, `feat: enhancements`.
- **Body:** why first, then what changed in behaviour; numbers only from
  checks that ran.
- **README:** what it is, what it does, how to use it, in that order; real
  counts; no emoji headings, no "blazing fast", no badge wall.
- **Changelog:** one line per change a user would notice, in their words.

## The check

Read every string aloud in the order a player meets it. Each should be
something a player would say while playing, or a developer would say in a
review. Then run `check-file` and read the words findings. A string that
survives both is done.

## Works with

- `roblox-code-craft`: names, comments and errors inside code.
- `roblox-ui`: UI copy lengths and rules.
- `roblox-hub-library`: hub rows, tabs and notices.
- `roblox-ui-tooltips`: helper lines and locked reasons.
- `roblox-script-feedback`: which notices exist at all.
- `roblox-reply-craft`: the words around the code in a reply.
- `roblox-executor-quality`: check 11 of the premium bar.
