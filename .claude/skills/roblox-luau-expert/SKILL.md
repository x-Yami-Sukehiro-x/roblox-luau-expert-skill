---
name: roblox-luau-expert
description: Router for every Roblox or Luau task - .lua/.luau files, Roblox Studio, Rojo, RemoteEvent, DataStore, UI, executor or sUNC scripts. Loads the right specialist skills, verifies every API against the Roblox API dump, and runs the delivery checks.
---

# Roblox Luau Expert — router

Entry point for the stack. Thin on purpose: diagnose, enforce the accuracy
rules, load the skill that owns the problem.

For a non-trivial build, supplied dump, repair or cross-chat continuation, read
`references/task-contract.md` first. Keep source facts, unknowns, previous
corrections and acceptance checks together. Load all relevant specialists: an
executor interface requires both executor and UI workflows. Reading unrelated
skills is not a substitute for applying the ones the task needs.

Before any repair, retry or redesign, read the project's attempt ledger and
`plan` the approach (`roblox-attempt-memory`): an approach that already failed
is not tried again without new evidence, and every fix becomes a check.

## Question zero — is the request buildable yet?

If the request is vague, non-technical, emotional, or written by someone who
does not use programming terminology — "make me a gui", "it's broken", "make it
look better" — load **`roblox-request-intake`** first. It translates the request,
supplies technical defaults, offers the visual guide for unresolved toggle and
motion preferences, and sets the reply shape. Ask those preferences together
before UI code; accept everyday words or “choose for me.” Preserve existing
choices and do not answer a vague request with a list of technical questions.

## Two more questions, asked before anything else

**1. Which side of the boundary owns this value?**
Server, client, or neither. Almost every Roblox bug is a boundary bug wearing a
costume — "it resets", "others can't see it", "the exploiter has infinite
money" are all the same question asked three ways.

**2. Is this game code or executor code?**
Game code runs inside a place you control and answers to the engine's rules.
Executor code runs in a client you do not control and answers to a different
rule set entirely. The APIs, the risks, and the correct advice diverge
completely. Never blend them in one answer without saying which is which.

---

## Accuracy rules — not optional

Roblox has ~925 classes and ~8,400 members, renames things, and gates a large
fraction behind security levels. Recall is not good enough. The stack ships
ground truth; use it.

### Rule 1 — verify before you write

Any Roblox class, member or enum you are not **certain** of gets checked
first: `node tools/bin/verify-api.mjs <Name>` (Python:
`python tools/py/verify_api.py <Name>`, or `--scan <file>` for every name a
file uses). **Exit code 1 means the name is not in the dump**: say it does not
exist rather than writing it with a hedge. Executor functions are a separate
source and a separate command, `verify-executor-api.mjs`. The fast grep
paths, the scan and the executor check in full:
`references/verifying-apis.md`.

### Rule 2 — three checks on every Roblox API you hand over

| Check | Source | What it stops |
|---|---|---|
| Does it exist? | `verify-api.mjs`, `references/verified/api-index.txt` | Invented APIs |
| Is it deprecated? | `references/verified/deprecated-apis.md` | `BodyVelocity`, `FindPartOnRay`, `wait`, `spawn` |
| Can this script reach it? | `references/verified/security-tagged-apis.md` | Recommending a `RobloxScript`-gated API to a LocalScript |

The third one is the subtle one. `Workspace.AuthorityMode` is a real property
that a normal Script **cannot read** — it is `RobloxScript`-gated. Real, and
still wrong to hand a game developer. Check the tag, not just the name.

Gating has a **direction**, and conflating the two produces wrong advice.
`Workspace.StreamingEnabled` is readable by any script and `Plugin`-gated only
for **writes** — which is different again from `[ReadOnly]`, where nobody may
write. `verify-api.mjs` reports this as `SECURITY read` / `SECURITY write` /
`SECURITY R/W`; the generated table splits on it too.

### Rule 3 — executor APIs have different ground truth

sUNC and executor functions are **absent from the API dump by design**. Verify
those against `roblox-executor/references/api/`. Never validate one against the
other's source. Feature-detect every executor-specific call before using it.

### Rule 4 — say when you do not know

An honest "that function does not exist; here is what does" beats a plausible
invention every time. This applies hardest to executor work, where availability
varies per executor and per update.

---

## Router — symptom to skill

| The user says | Load |
|---|---|
| "attempt to index nil", crashes, `WaitForChild` hangs | `roblox-engine-api` |
| types, `--!strict`, generics, `buffer`, metatables, OOP | `roblox-luau-language` |
| "out of local registers", won't compile, or a long single-file script | `roblox-luau-language` → `roblox-luau-language/references/compiler-limits.md`; `tools/bin/check-registers.mjs` |
| raycasting, CFrame, Humanoid, tweens, camera, input | `roblox-engine-api` |
| module layout, "where does this code go", frameworks | `roblox-architecture` |
| DataStore, saving, data loss, ProfileService, session lock | `roblox-data-persistence` |
| RemoteEvent, replication, "doesn't show for other players" | `roblox-networking` |
| lag, memory climbing, MicroProfiler, parallel Luau | `roblox-performance` |
| GUI, ScreenGui, responsive, mobile, hub menu | `roblox-ui` → `roblox-ui/references/build-order.md` |
| "what colours / font / radius should I use" | `roblox-ui` → `roblox-ui/references/design-directions.md` |
| "build me a menu / shop / inventory / modal / HUD" | `roblox-ui` → `roblox-ui/references/blueprints.md` |
| "my UI looks AI-generated" / design review | `roblox-ui` → `roblox-ui/references/anti-slop-catalog.md` then `self-review.md` |
| "make it look better" (no other detail) | `roblox-request-intake` → `roblox-ui/references/build-order.md` |
| "make me a shop / hub / settings / HUD" with no layout given | `roblox-ui` → `roblox-ui/references/screen-archetypes.md` |
| "improve my UI", "it looks off", tab layout, sizes | `roblox-ui` → `roblox-ui/references/layout-ux.md` |
| blurry UI, cut-off dropdown, "the UI is bugged" | `roblox-ui` → `roblox-ui/references/crisp-ui.md` |
| "make me a gui" and nothing else; a one-line UI request | `roblox-ui` → `roblox-ui/references/weak-prompt.md` |
| outline, focus ring or shadow cut off at an edge | `roblox-ui` → `roblox-ui/references/clipping.md` |
| "cut off", "off the screen", "too big on mobile", "tiny on my monitor", any resolution | `roblox-ui-viewport` |
| "the button does nothing", "can't click it on mobile", "controller can't select it" | `roblox-ui-interaction` |
| a screenshot of a UI to recreate | `roblox-ui` → `roblox-ui/references/image-to-ui.md` |
| a pasted `roblox-ui-design` export or `ui-design.json` | `roblox-ui` → `roblox-ui/references/design-spec.md` |
| labels, descriptions, subtitles too long or too "AI" | `roblox-ui` → `roblox-ui/references/ui-copy.md` |
| which icon for a tab or feature | `roblox-ui-components/references/icon-meaning.md` |
| animating UI, tweens, springs, janky motion | `roblox-ui-motion` |
| toast, notification, popup, button, slider, modal, divider, outline | `roblox-ui-components` |
| tooltip, hover text, slider number, hint under a field, "why is it locked", H codes | `roblox-ui-tooltips` |
| icons, lucide, `rbxassetid`, an icon renders blank, `getcustomasset` | `roblox-ui-components/references/icons.md` |
| "the close button / title is positioned wrong" | `roblox-ui/references/blueprints.md` B1a |
| "the notification does not match my UI" | `roblox-ui-components/references/shadows-and-elevation.md` |
| a panel that scores badly, and what each finding looked like | `roblox-ui/references/ui-rewrite.md` |
| gamepass, dev product, shop, "they got the item twice", receipts | `roblox-monetization` |
| `ProcessReceipt`, purchase granted but nothing happened | `roblox-monetization` → `roblox-monetization/references/receipts.md` |
| animation not playing, priority, particles, beams, trails, highlights | `roblox-vfx-animation` |
| sound, music, volume slider, footsteps, audio stutters on first play | `roblox-audio` |
| MessagingService, teleport, reserved server, cross-server state | `roblox-networking` → `roblox-networking/references/cross-server.md` |
| "exploiters are doing X", securing remotes, anti-cheat design | `roblox-game-security` |
| Rojo, Wally, selene, StyLua, luau-lsp, tests, CI | `roblox-toolchain` |
| naming, error messages, "this looks AI-generated", review | `roblox-code-craft` |
| a comment whose first line is real and whose next three restate the code | `roblox-code-craft` → `roblox-code-craft/references/anti-slop-code.md` §3a |
| `v14`, `u3`, `p1` still in a script built from a dump | `roblox-code-craft` → `roblox-code-craft/references/anti-slop-code.md` §6 |
| "you said you redesigned it and you didn't" | this file, the delivery pass, step 9 |
| picking a UI library, or "my UI looks like every other script hub" | `docs/portability/gpt/UIs/catalog.md` |
| "too many comments", "stop over-explaining", obvious comments | `roblox-code-craft` → `roblox-code-craft/references/anti-slop-code.md` |
| "the formatting is clustered", breaks on lines that do not need them | `roblox-code-craft` → `roblox-code-craft/references/formatting.md` |
| a draft buried in capability checks, `pcall`s and prose errors | `roblox-code-craft` → `roblox-code-craft/references/anti-slop-code.md` |
| executor, sUNC, `hookfunction`, `getgc`, script hub | `roblox-executor` |
| fly, noclip, speed, infinite jump, ESP, click teleport, anti-AFK, fullbright, spectate, max zoom, FOV, freecam | `roblox-executor-features` (tested assets) |
| an executor feature "doesn't work", "works then resets", "broke after respawn", "broke my other feature" | `roblox-executor-reliability` |
| "you didn't fix it", "same problem again", "we already tried that", a new chat continuing old work | `roblox-attempt-memory` |
| "make me a game", game ideas, economy balance, retention, daily rewards | `roblox-game-design` |
| Studio is connected through MCP; "test it in Studio", playtest, screen capture | `roblox-studio-mcp` |
| a Toolbox or Creator Store model, "is this model safe", backdoors | `roblox-game-security` → `roblox-game-security/references/audit-imported-assets.md` |
| "it resets when I change it" (client-side) | `roblox-executor` → `roblox-executor/references/technique/value-persistence.md` |
| "where is this game's anti-cheat" | `roblox-executor` → `roblox-executor/references/recon/anticheat-recon.md` |
| user pasted decompiled source, a dump, or the game's scripts | `roblox-executor` → `roblox-executor/references/technique/decompiled-source.md` |
| "what features can I add from this dump", "add everything possible" | `roblox-executor` → `roblox-executor/references/technique/feature-ideas.md` |
| "which executor call reaches this", a draft with fallback chains | `roblox-executor` → `roblox-executor/references/technique/source-to-api.md` |
| vague, non-technical, or "it doesn't work" with no detail | `roblox-request-intake` |
| a pasted error message and nothing else | `roblox-request-intake` → `roblox-request-intake/references/error-triage.md` |
| any reply with code or a file; "too slow", "too long", "badly formatted", odd file names | `roblox-reply-craft` |

Two skills at once is normal. "Exploiters are duping items" is
`roblox-game-security` for the fix and `roblox-executor` for the threat model.

## Skill map: load them together

A host may shorten or drop skill descriptions when many skills are installed,
so do not wait for a specialist to trigger on its own. Open the bundle for
the task by path; each skill's **Works with** section names its partners.

| Task | Open together |
|---|---|
| any code you hand over | `roblox-code-craft`, `roblox-reply-craft` |
| any repair, retry or "still broken" | `roblox-attempt-memory` first, then the area's skills |
| a UI, game or hub | `roblox-ui`, `roblox-ui-components`, `roblox-ui-viewport`, `roblox-ui-interaction`; `roblox-ui-motion` and `roblox-ui-tooltips` when used |
| an executor feature or hub | `roblox-executor-features`, `roblox-executor-reliability`, `roblox-executor`, plus the UI row for the hub |
| saving, currency, shops | `roblox-data-persistence`, `roblox-monetization`, `roblox-game-design`, `roblox-game-security` |
| multiplayer and remotes | `roblox-networking`, `roblox-game-security`, `roblox-engine-api` |
| "make me a game" | `roblox-request-intake`, `roblox-game-design`, `roblox-architecture` |
| Studio is connected | `roblox-studio-mcp` to check the change in a real playtest |

Every skill, by path from this folder:

| Skill | Path |
|---|---|
| architecture | `../roblox-architecture/SKILL.md` |
| attempt memory | `../roblox-attempt-memory/SKILL.md` |
| audio | `../roblox-audio/SKILL.md` |
| code craft | `../roblox-code-craft/SKILL.md` |
| data persistence | `../roblox-data-persistence/SKILL.md` |
| engine API | `../roblox-engine-api/SKILL.md` |
| executor | `../roblox-executor/SKILL.md` |
| executor features | `../roblox-executor-features/SKILL.md` |
| executor reliability | `../roblox-executor-reliability/SKILL.md` |
| game design | `../roblox-game-design/SKILL.md` |
| game security | `../roblox-game-security/SKILL.md` |
| Luau language | `../roblox-luau-language/SKILL.md` |
| monetization | `../roblox-monetization/SKILL.md` |
| networking | `../roblox-networking/SKILL.md` |
| performance | `../roblox-performance/SKILL.md` |
| reply craft | `../roblox-reply-craft/SKILL.md` |
| request intake | `../roblox-request-intake/SKILL.md` |
| Studio MCP | `../roblox-studio-mcp/SKILL.md` |
| toolchain | `../roblox-toolchain/SKILL.md` |
| UI | `../roblox-ui/SKILL.md` |
| UI components | `../roblox-ui-components/SKILL.md` |
| UI interaction | `../roblox-ui-interaction/SKILL.md` |
| UI motion | `../roblox-ui-motion/SKILL.md` |
| UI tooltips | `../roblox-ui-tooltips/SKILL.md` |
| UI viewport | `../roblox-ui-viewport/SKILL.md` |
| VFX and animation | `../roblox-vfx-animation/SKILL.md` |

### Always available here

- `references/common-mistakes.md` — the ranked defect catalog. Read it before
  writing non-trivial code, and consult it when reviewing.
- `references/delivery-checklist.md` — the pass that runs before code leaves.
- `references/verified/` — generated from the dump. **Grep these; do not read
  them end to end.** `references/verified/deprecated-apis.md` alone is 700 rows.

---

## Standing rules for code

**Match the file you are editing.** Its conventions beat the official style
guide, which beats these defaults. A correctly-styled function that looks
nothing like its neighbours is worse than a slightly-off one that blends.
Read enough surrounding code to see the casing, comment density, error style
and log prefixes actually in use, then mirror them. If a file's convention is
genuinely harmful, say so once rather than silently diverging.

Defaults for new files: `camelCase` locals and functions, `PascalCase` for
services, modules and class-likes, `LOUD_SNAKE_CASE` constants, `_camelCase`
private. Comments sparse and why-only: a comment earns its line by containing a fact
that is not in the code. No comment about where the script came from, what the
previous attempt did, or what the user uploaded — that belongs in the reply.
Full rules, with the counted budget: `roblox-code-craft`.

Non-negotiable at runtime:

- **The server is the only source of truth** for currency, inventory, damage,
  progression and position-that-matters. The client is input and display.
- **Validate every remote argument** — type, range, ownership, rate. A remote
  handler that trusts its arguments is a published exploit.
- **Every connection has an owner and a teardown path.** Undisconnected
  connections are the single most common real memory leak in Roblox.
- **Re-validate after every yield.** The player may have left, the character
  may have respawned, the instance may be destroyed.
- **Prefer `task.*`** over `wait` / `spawn` / `delay`. Those are deprecated and
  in the generated table.

---

## Before any code leaves — the delivery pass

Run it every time; it only lists things that have actually gone wrong. Full
detail: `references/delivery-checklist.md`.

1. Every Roblox API verified: exists, not deprecated, reachable at this
   security level. Executor calls feature-detected once.
2. `pcall` results checked; yields followed by re-validation.
3. Every connection disconnected or owned by a Trove or Janitor.
4. Errors name the failing value; names come from the game's vocabulary.
5. No dead code; comments say why, never what.
6. Checked against `references/common-mistakes.md` and the ledger
   (`roblox-attempt-memory`).
7. **Counted, not estimated**, on the final file:

    ```powershell
    node tools/bin/check-file.mjs <file.luau>      # slop, format, UI, API, compile, registers, fit, ledger
    python tools/py/check_file.py <file.luau>      # the same without Node
    node tools/bin/verify-asset-ids.mjs <file.luau> # if it names an asset id
    ```

    Report what it prints. A score produced without running it is a guess.
8. For a reader who may not code: a placement block in Studio's own labels
   and a line saying what success looks like.
9. For an edit: `--compare before after` and the measured change. `0 of
   them structural` means the counted properties did not change, not that
   behaviour is identical. Lint, mocks, Studio and a real device are
   different evidence; name what was not run.

## Scope note on the executor half

`roblox-executor` documents client-side scripting: the sUNC API surface,
hooking, memory search, anti-cheat reconnaissance, packet manipulation. It is
written for private and educational use on accounts and servers the reader
controls, and it states ban risk plainly rather than pretending it away.
Detection and enforcement are separate things — "it worked and I was not
banned" is not evidence of being undetected.

`roblox-game-security` is the mirror: the same knowledge pointed at defending
a place you own. Neither skill invents capabilities the other side does not
have; both are more useful for being accurate about the limits.

---

## Keeping this current

```powershell
node tools/bin/update-dump.mjs --check    # is the vendored dump behind?
node tools/bin/update-dump.mjs           # refresh, diff, regenerate verified/
```

The diff prints added, removed and newly-deprecated members between releases.
Roblox ships weekly; when an answer depends on something recent, check first.
