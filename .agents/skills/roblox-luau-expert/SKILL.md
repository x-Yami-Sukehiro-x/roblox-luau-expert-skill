---
name: roblox-luau-expert
description: Router and hard rules for all Roblox and Luau work — game scripting, engine APIs, Luau types, networking and replication, DataStores, performance, GUI, anti-exploit, and client/executor scripting. Use for any Roblox question, any .lua/.luau file in a Roblox project, and any mention of Luau, Rojo, RemoteEvent, DataStore, Humanoid, Instance, sUNC, or an executor. Enforces API verification against a vendored API dump so Roblox APIs are checked rather than recalled.
---

# Roblox Luau Expert — router

Entry point for the stack. Thin on purpose: diagnose, enforce the accuracy
rules, load the skill that owns the problem.

For a non-trivial build, supplied dump, repair or cross-chat continuation, read
`references/task-contract.md` first. Keep source facts, unknowns, previous
corrections and acceptance checks together. Load all relevant specialists: an
executor interface requires both executor and UI workflows. Reading unrelated
skills is not a substitute for applying the ones the task needs.

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

Any Roblox class, property, function, event or enum you are not **certain**
of gets checked first:

```powershell
node tools/bin/verify-api.mjs <Name>              # in this repo
node $CLAUDE_PLUGIN_ROOT/tools/bin/verify-api.mjs <Name>   # installed as a plugin
```

It prints the real signature plus the security level, capability, parallel
safety, deprecation and yield behaviour. **Exit code 1 means the name is not
in the dump.** That is the signal you were about to invent an API. Say it does
not exist. Do not write it anyway with a hedge.

Fast path when you only need existence: `grep` `references/verified/api-index.txt`
for a `Class.Member`, `references/verified/enum-index.txt` for an enum item such as
`Enum.EasingStyle.Quad`, and `references/verified/class-hierarchy.txt` when the first
grep misses - members are indexed against the class that **declares** them, so
`Workspace.Raycast` is absent and `WorldRoot.Raycast` is not.

No Node available - a custom GPT's Code Interpreter, for instance - and the same
three questions are answered offline from those files:

```bash
python tools/py/verify_api.py Humanoid.WalkSpeed     # exists, deprecated, gated
python tools/py/verify_api.py Enum.EasingStyle.Quad  # real enum item
python tools/py/verify_api.py --exec hookmetamethod  # documented executor call
python tools/py/verify_api.py --scan Script.luau     # every name this file establishes
```

`--scan` resolves each local this file binds to a class - `game:GetService`,
`Instance.new`, a type annotation - and checks every member read off it, walking
the inheritance chain. It says which receivers it resolved, so what it did not
check is visible rather than implied.

Executor functions are a **separate** ground truth and a separate command:

```powershell
node tools/bin/verify-executor-api.mjs <name>     # sUNC reference; exit 1 if absent
```

Same contract, different source. `verify-api.mjs` correctly reports every
executor function as missing, because the API dump does not contain them — that
is not the signal, and using the wrong tool is how a real function gets called
imaginary.

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
| "out of local registers", won't compile | `roblox-luau-language` → `roblox-luau-language/references/compiler-limits.md` |
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
| animating UI, tweens, springs, janky motion | `roblox-ui-motion` |
| toast, notification, popup, button, slider, modal, divider, outline | `roblox-ui-components` |
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
| "you said you redesigned it and you didn't" | this file, the delivery pass, step 12 |
| picking a UI library, or "my UI looks like every other script hub" | `docs/portability/gpt/UIs/catalog.md` |
| "too many comments", "stop over-explaining", obvious comments | `roblox-code-craft` → `roblox-code-craft/references/anti-slop-code.md` |
| "the formatting is clustered", breaks on lines that do not need them | `roblox-code-craft` → `roblox-code-craft/references/formatting.md` |
| a draft buried in capability checks, `pcall`s and prose errors | `roblox-code-craft` → `roblox-code-craft/references/anti-slop-code.md` |
| executor, sUNC, `hookfunction`, `getgc`, ESP, script hub | `roblox-executor` |
| "it resets when I change it" (client-side) | `roblox-executor` → `roblox-executor/references/technique/value-persistence.md` |
| "where is this game's anti-cheat" | `roblox-executor` → `roblox-executor/references/recon/anticheat-recon.md` |
| user pasted decompiled source, a dump, or the game's scripts | `roblox-executor` → `roblox-executor/references/technique/decompiled-source.md` |
| "which executor call reaches this", a draft with fallback chains | `roblox-executor` → `roblox-executor/references/technique/source-to-api.md` |
| vague, non-technical, or "it doesn't work" with no detail | `roblox-request-intake` |
| a pasted error message and nothing else | `roblox-request-intake` → `roblox-request-intake/references/error-triage.md` |

Two skills at once is normal. "Exploiters are duping items" is
`roblox-game-security` for the fix and `roblox-executor` for the threat model.

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

Run this every time. It is short because it only contains things that have
actually gone wrong.

1. **Every Roblox API verified** — exists, not deprecated, reachable at this
   security level. Executor calls feature-detected.
2. **`pcall` results checked** — never `local _, x = pcall(...)`.
3. **Yields followed by re-validation** — player still here, instance still
   parented.
4. **Connections disconnected** — or owned by a Trove/Janitor with a clear
   teardown.
5. **Errors name the failing value**, and argument validation uses
   `error(msg, 2)` so the caller's line is reported.
6. **Names come from the game's vocabulary** — if an identifier would fit
   unchanged in another project, it is too generic.
7. **No dead code** — unused `require`s, unreferenced functions, leftover
   `TODO`s.
8. **Comments say why, never what.** None that restate the line below.
9. **Checked against `references/common-mistakes.md`** for anything the code touches.
10. **Run the counter on every Luau file, do not estimate it.**

    ```powershell
    node tools/bin/lint-luau-slop.mjs <file.luau>     # always
    node tools/bin/lint-luau-format.mjs <file.luau>   # always
    node tools/bin/lint-roblox-ui.mjs <file.luau>     # if it draws UI
    node tools/bin/verify-asset-ids.mjs <file.luau>   # if it names an asset id
    ```

    Without Node - a custom GPT's Code Interpreter, a bare Python sandbox -
    use `tools/py/roblox_lint.py`, `tools/py/format_lint.py` and
    `tools/py/ui_lint.py` respectively, held finding-for-finding by
    `tools/bin/lint-parity.mjs`.

    Exit 1 means a counted rule was broken. Steps 5 to 8 above are the ones a
    model reports as passing without having checked; the first command is what
    makes that claim falsifiable. Budget and rules:
    `roblox-code-craft/references/anti-slop-code.md`.

    It counts the rubric in `roblox-ui/references/self-review.md` over the real
    file — type scale, radii, spacing, states, touch targets, teardown — and
    exits 1 on any error. Report the score it prints. A score you produced
    without running it is a guess wearing a number.
11. **If the reader may not code**: the reply carries a placement block in
    Studio's own labels and a line saying what success looks like.
    → `roblox-request-intake/references/plain-language.md`
12. **Match each claim to actual evidence.** Quote command outputs for static
    checks and observations for runtime or visual checks. Where the task was
    to change an existing file, inspect the diff and measure the change:

    ```powershell
    node tools/bin/lint-luau-slop.mjs --compare before.luau after.luau
    node tools/bin/lint-roblox-ui.mjs --compare before.luau after.luau
    ```

    The UI comparison separates structural rows - elements, type scale, radii,
    spacing set, palette - from the score, because a one-line fix moves the
    score and a redesign can move the structure. **`0 of them structural` means
    those counted properties did not change**, not that behavior and layout are
    identical. Report the measured numbers and the observed changes. Static
    lint cannot establish rendered quality or live executor compatibility.

Full detail in `references/delivery-checklist.md`.

---

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
