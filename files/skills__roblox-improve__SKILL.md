---
name: roblox-improve
description: Reviewing Roblox code, features or UI and ranking changes by impact, with evidence and the fix. Use for review this, improve it.
---

# Reviewing and suggesting improvements

"Can you improve this?" gets one of two bad answers: a list of twenty generic
tips that fit any script, or a rewrite nobody asked for. The useful answer
is three to five changes, ranked, each with the line it is about, what goes
wrong for a player, and the fix. This skill is how to find those.

It covers three kinds of request:

- **Code**: "review this", "is this good", "make it better", "optimise it".
- **Features**: "what should I add", "ideas for my game or hub".
- **UI and UX**: "does this look good", "how do I make it feel better".

## The method

1. **Establish what it is.** Game server code, game client code, a
   ModuleScript, an executor script, a hub. Who uses it, and which side owns
   each value it touches (the first question in the router). A review that
   gets the side wrong gets every finding wrong.
2. **Measure before reading.** Run `node tools/bin/check-file.mjs <file>` or
   `python tools/py/check_file.py <file>` and keep its counts. Counts are
   evidence; "this looks messy" is not.
3. **Read for defects by category**, in the order in
   [review-checklist.md](references/review-checklist.md): correctness,
   security and trust, data, lifetime and leaks, performance, input and fit,
   then code craft.
4. **Gate every finding.** Before it goes in the reply it must pass all four:
   - both sides of any paired logic traced, and they disagree;
   - the odd shape is not deliberate (checked the call sites and comments);
   - a concrete failure: these inputs, this state, this wrong result;
   - the API claim checked against the dump, not memory.
   What fails the gate is not reported. The common false alarms are in
   [false-positives.md](references/false-positives.md).
5. **Give each finding a severity**: *Blocker* (exploitable, loses data, or
   leaks without bound), *Correctness* (a real bug with a scenario), or
   *Advisory* (style, a micro-optimisation, a preference). Advisory items are
   offered, never presented as defects.
6. **Rank by harm to the player, then by size of fix.** A one-line fix to a
   Blocker goes first; a rewrite for an Advisory goes last or nowhere.
7. **Suggest features only from evidence**: the game's loop, where players
   get stuck, what the hub lacks against its own purpose.
   [feature-suggestions.md](references/feature-suggestions.md) has the method
   and the lists.

## The reply

```
Three changes, most important first.

1. Blocker - `ShopService.luau:42`: the server trusts the price the client sends,
   so an exploiter buys anything for 0 Coins. Read the price from ItemConfig on
   the server. (8 lines, whole function below.)
2. Correctness - `Toggle.luau:88`: the connection made on every respawn is never
   disconnected; after ten deaths the toggle fires ten times. Store it and
   disconnect it in the CharacterRemoving handler.
3. Correctness - on a 640 x 360 phone the shop panel is 720 px wide and runs off
   screen. Scale width 0.9 with a UISizeConstraint max of 720.

Also worth doing, smaller: [two or three one-liners].
Checked: check-file (0 errors, 2 warnings, quoted), lint-roblox-ui (26/32).
Not checked: a live server with real latency.
```

For a review-only request, give recommendations. When the user asked for fixes
or improvements, apply the supported changes in severity order, smallest region
each, and repost whole files; do not ask again for work already requested.

## What not to do

- **No generic advice.** "Add comments", "use better names", "consider
  performance" with no line and no failure is noise.
- **No findings from memory of an API.** Verify with
  `node tools/bin/verify-api.mjs`, or say it is unverified.
- **No rewrite for style.** The user's conventions win (`roblox-code-craft`,
  "match the file you are editing").
- **No inflated severity.** An Advisory dressed as a Blocker costs trust the
  real Blocker needs.
- **Never claim a score or a test that did not run.** Name each check and
  quote its output; say which were not run.

## UI and UX reviews

A UI review uses the counted rubric (`node tools/bin/lint-roblox-ui.mjs`),
then the checks no linter can count, in
[ux-review.md](references/ux-review.md): the first thirty seconds, feedback
for every action, the six states, copy that names things, the phone pass,
and how an action *feels* (hit feedback, timing, sound).

Use `../roblox-ui-ux-review/SKILL.md` to distinguish screenshot, source,
computed-fit and runtime evidence, trace clipping to its owner, and compare
the same state before and after a change.

## Works with

- `roblox-code-craft`: what well-written Luau looks like, and the slop tells to remove.
- `roblox-game-security`: validating remotes and server authority behind every security finding.
- `roblox-performance`: measuring before calling anything slow.
- `roblox-ui`: the rubric and design direction behind UI findings.
- `roblox-ui-interaction`: the input contract behind "the button does nothing".
- `roblox-game-design`: loops and retention behind feature suggestions for games.
- `roblox-hub-library`: the audit for an existing hub's UI.
- `roblox-executor-reliability`: the regression matrix behind executor feature findings.
- `roblox-debugging`: when a review turns into finding one specific bug.
- `roblox-attempt-memory`: recording which suggestions were applied and what happened.
- `roblox-ui-ux-review`: useful formatting, UI and UX findings with specific evidence.
- `roblox-script-feedback`: whether notifications and configs improve the actual flow.
