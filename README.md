# Roblox Luau Expert

A 21-skill stack covering Roblox and Luau at depth — ordinary game development
**and** client/executor scripting — with a verification layer so Roblox APIs are
**checked against ground truth rather than recalled**, and linters that hold the
stack's own prose, examples and colour palettes to that same standard.

Runs on Claude Code natively, and generates matching rule files for Codex,
Cursor and a custom GPT from one source, plus an OpenAI plugin for when custom
GPTs retire on 11 December 2026.

For UI, users pick styles by looking rather than by knowing the words: the
[Roblox UI style picker](https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/)
(offline copy `docs/visual-guide/index.html`) labels every toggle, checkbox,
dropdown, menu movement, notification, hide style, button feel, tab switch and
tooltip with a code (215 of them), and each code has a tested recipe in
`.claude/skills/roblox-ui-components/assets/`. Fly, noclip, speed, ESP and the
other character features are tested, paste-whole scripts in
`.claude/skills/roblox-executor-features/assets/`. The
[UI designer](https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/designer.html)
lets them drag a whole screen together from windows, rows, controls and 1,559
verified Roblox icons, then copy it for their AI to rebuild exactly.

Pinned to Roblox API dump `0.739.0.7390687`.

---

## The problem this solves

This snapshot has 925 classes and 8,461 API members. Roblox renames things and
gates a large fraction behind security levels. Recall is not reliable at that
scale, and neither is a document written six months ago.

v2 of this stack vendored the API dump and shipped tools to query it. It then
never pointed those tools at its own prose — and a recommendation to call
`Players:CreateHumanoidModelFromDescription` survived in the same repository
that generates the table listing it as `[Deprecated]`.

So the spine of v3 is two linters that run over the stack itself.

```bash
node tools/bin/lint-prose.mjs         # every API claim, against the dump
node tools/bin/lint-luau-blocks.mjs   # every shipped example, against luau
```

Both currently report **0 errors, 0 warnings**. What they caught on the way
there is in [docs/CHANGELOG.md](docs/CHANGELOG.md).

---

## The problem v4 solves

v3 was accurate and still produced generic UI, because accuracy was never the
constraint there. Its 2,178 lines of UI guidance were almost entirely
**advisory** — "pick a direction", "make the steps mean something", "decide what
wins". Advice is an instruction to exercise judgement, and judgement is exactly
what a weaker model cannot supply. It follows the guidance, produces the same
grey card grid, and honestly reports that it applied it.

The same root cause produced three more failures: vague and non-technical
requests had no owner, decompiled source the user pasted was ignored in favour
of a template, and nothing carried the stack to the other tools in use.

v4 replaces judgement calls with lookups, procedures, numbers and countable
checks.

```bash
node tools/bin/lint-luau-slop.mjs <file.luau>    # counts the ceremony budget over real code
node tools/bin/lint-roblox-ui.mjs <file.luau>    # counts the UI rubric over real code
python tools/py/roblox_lint.py <file.luau>       # the same budget, in a sandbox with no Node
python tools/py/ui_lint.py <file.luau>           # the same rubric, in a sandbox with no Node
node tools/bin/verify-asset-ids.mjs <file.luau>  # asks Roblox whether each asset id is real
node tools/bin/lint-ui-directions.mjs            # every stated contrast ratio, recomputed
node tools/bin/verify-executor-api.mjs <name>    # the executor half's invention gate
node tools/bin/lint-links.mjs                    # every file the stack points at
```

| Instead of | v4 ships |
|---|---|
| "pick a style direction" | six directions, every RGB value, font, radius and type scale stated, contrast verified |
| "make hierarchy clear" | a ten-step build order, each step gated by a yes/no question |
| "check it does not look generated" | a rubric of counts — and `lint-roblox-ui.mjs`, which resolves what the file builds, whichever idiom builds it, so the score cannot be estimated or dodged |
| "use a real icon" | 81 verified lucide ids, and `verify-asset-ids.mjs`, which asks Roblox whether an id exists and is an image |
| "match the notification to the panel" | one entry that decides fill, stroke and shadow for every surface at that height |
| "inspect the game first" | an eleven-row extraction pass over the source the user actually pasted |
| "ask if unclear" | a default for every decision, and four questions that may be asked |
| "comment the why, not the what" | a budget with numbers in it, and `lint-luau-slop.mjs`, which counts header lines, provenance comments, capability checks, `pcall`s and message length |
| "pick the right executor function" | a layer-to-call map read off the dump, and a ban on runtime fallback chains |

---

## Ground truth

Two vendored sources, because one is not enough:

| Source | Covers | Why |
|---|---|---|
| `tools/api-dump/API-Dump.txt` | 925 classes, 636 enums, 8,461 members | Security levels, deprecation, parallel safety, capabilities |
| `tools/api-dump/datatypes/` | 48 datatypes, 365 members | **The dump has no datatypes at all** — `CFrame`, `TweenInfo`, `RaycastParams` and `SharedTable` are invisible to it |

That second row is not a detail. v2 claimed `RaycastParams.RespectCanCollide` was
"verbatim from the vendored dump"; the dump contains classes and enums only, so
that claim could not have been true. Datatypes now have their own ground truth
and `verify-api` says which source answered.

```bash
node tools/bin/verify-api.mjs GuiService.TopbarInset
#   Property GuiService.TopbarInset: Rect [ReadOnly] {UI}
#     NOT ASSIGNABLE at runtime: [ReadOnly]

node tools/bin/verify-api.mjs SharedTable.increment
#   SharedTable.increment   (datatype SharedTable, functions)
#     source: tools/api-dump/datatypes - the API dump does not cover datatypes

node tools/bin/verify-api.mjs GetPlayerHealth
#   NOT FOUND in the Roblox API dump.       <- exit code 1
```

That non-zero exit is the "you were about to invent an API" signal.

The dump also encodes things most documentation does not:

- **Deprecation** — 651 members across 148 classes.
- **Security direction.** `Workspace.StreamingEnabled` is readable by any script
  but `Plugin`-gated for **writes**, which is different again from `[ReadOnly]`
  and different again from `[LoadOnly]`. The tools report each separately,
  because conflating them is how you end up recommending an unreachable API.
- **Parallel safety** — members explicitly `Safe` or `Unsafe` under Actors.
- **Script capabilities** across the API surface.

---

## Install

**As a plugin — recommended, works in every project:**

```
/plugin marketplace add x-Yami-Sukehiro-x/roblox-luau-expert-skill
/plugin install roblox-luau-expert@roblox-luau-expert-marketplace
```

**Repo-local — already done.** The skills live in `.claude/skills/`, so they
load whenever Claude Code runs with this repo as the working directory.

**Copy into `~/.claude/skills/`:**

```powershell
.\install.ps1              # copy
.\install.ps1 -Symlink     # link instead (needs Developer Mode)
.\install.ps1 -Uninstall
```

`install.ps1` now copies `tools/` and `library/` alongside the skills. It did
not before, which left the router instructing Claude to run a verification
script that was not on disk.

---

## The skills

One thin router loads always; the rest load on demand.

| Skill | Covers |
|---|---|
| **roblox-luau-expert** | Router. Hard accuracy rules, symptom table, delivery checklist, the generated `verified/` tables, and the ranked **common-mistakes** catalog |
| **roblox-luau-language** | Type system, strict mode, generics and type packs, refinements, metatables and OOP, `buffer`, `vector`, syntax extensions, GC, compiler limits and the register budget (`check-registers.mjs`) |
| **roblox-engine-api** | Instance lifecycle, attributes and tags, the frame pipeline, raycasts and shapecasts, CFrame, Humanoid and character lifecycle, animation, tweens, camera, streaming, chat, input |
| **roblox-architecture** | DataModel layout, module patterns, two-phase startup, Trove/Janitor, Promise and Signal, framework survey, testing seams |
| **roblox-data-persistence** | DataStore semantics, budgets, session locking, ProfileStore and Lyra, MemoryStore, migrations, diagnosing loss and duplication |
| **roblox-networking** | Remotes, `UnreliableRemoteEvent`, what actually replicates, network ownership, bandwidth, buffers, latency compensation, `BanAsync` |
| **roblox-performance** | MicroProfiler and ScriptProfiler, Stats, memory leaks, per-frame cost, streaming, parallel Luau and Actors, native codegen |
| **roblox-request-intake** | Vague, emotional and non-technical requests — translation to a spec, every default pre-decided, plain-language delivery with Studio placement steps, and error triage from pasted red text |
| **roblox-ui** | The **build order** (ten gated steps), **six fully specified design directions**, **nine blueprints**, the **countable self-review**, whole-screen archetypes, layout and tab-layout rules, blurry and broken UI fixes, rebuilding from a screenshot or a designer export, UI copy, plus scale vs offset, flex and wrapping, StyleSheet cascade, safe areas and the anti-slop catalog (R1–R17) |
| **roblox-ui-motion** | Intent-to-easing mapping, duration bands, **`SmoothDamp` springs** for interruptible motion, choreography and stagger, reduced motion |
| **roblox-ui-components** | **Tested recipes for every picker code**, toast/notification system, outlines and dividers, 9-slice panels, the six interaction states, a control catalog, and which icon means what |
| **roblox-ui-tooltips** | Which words-around-a-control to use (tooltip, info button, helper line, locked reason, coach mark), placement and flipping, touch and gamepad access, **slider value readouts**, and the tested H1–H12 recipes |
| **roblox-game-security** | The realistic client threat model, remote hardening, server-side sanity checks, detection vs enforcement, obfuscation reality check, audit checklist |
| **roblox-toolchain** | Rojo, Rokit, Wally, selene, StyLua, luau-lsp with sourcemaps, Lune, jest-roblox, CI, Studio MCP |
| **roblox-code-craft** | Naming, error and warning design, `pcall` discipline, comment policy, matching an existing file, AI-generated tells |
| **roblox-monetization** | `ProcessReceipt` idempotency and the PurchaseId ledger, passes vs products, prompts, ownership caching, `PolicyService` |
| **roblox-vfx-animation** | `AnimationTrack` lifecycle, priority and blending, markers, particles, beams, trails, highlights, pooling |
| **roblox-audio** | Legacy `Sound` vs the `AudioPlayer`/`Wire` graph, buses and mixing, rolloff, preloading, per-player output |
| **roblox-executor** | sUNC API surface, hooking, memory search, thread identity and capabilities, anti-cheat recon, detection surface, RakNet, saveinstance, **working from decompiled source**, hub UI libraries, **feature ideas from a dump** (`dump_index.py --inventory`) |
| **roblox-executor-features** | **Tested, paste-whole feature scripts**: fly (`LinearVelocity`), noclip, speed and jump, infinite jump, ESP, click teleport, anti-AFK, fullbright; the quality bar for mobile input, respawn, rerun and unload |
| **roblox-reply-craft** | Replies that arrive faster (**`check-file.mjs`** runs every check in one call, **`recipe.py`** names the file for a code), code blocks that paste cleanly, short file names, and no AI filler around the code |

`roblox-game-security` and `roblox-executor` are deliberate mirrors. Knowing
what a client can actually do is what makes the defence proportionate rather
than superstitious.

---

## Layout

```
.claude/skills/          the skills
.claude-plugin/          plugin + marketplace manifests
AGENTS.md                generated - Codex
.cursor/rules/           generated - Cursor
docs/
  portability/           rules.md is the single source for the three above
                         plus the custom-GPT instructions and knowledge file
  SOURCES, CHANGELOG, MCP notes, maintenance, briefs
library/
  src/                   vendored, parse-checked Luau you can require
    Tokens.luau            the design spine - re-skin by editing this alone
    Layout.luau            modifier constructors with the wrong defaults fixed
    Motion.luau            tweens by intent, SmoothDamp springs, reduced motion
    Toast.luau             notification system with queue, dedup, spring reflow
    Components/            Button, Divider, Panel, Toggle, Slider, Dropdown,
                           TabBar, Modal
  tests/                 headless harness - stubs, 42 assertions
tools/
  bin/                   Node CLIs, zero dependencies
  py/                    Python ports of the two linters and the API check,
                         for hosts with no Node - parity-gated against bin/
  ps1/                   thin PowerShell wrappers over the same tools
  api-dump/              vendored ground truth (dump, FVariables, datatypes)
  lint-allow.txt         linter suppressions, each with a stated reason
evals/                   routing and accuracy regression tests
```

---

## Tools

All Node, no dependencies. The `.ps1` files in `tools/ps1/` forward to the same
scripts and preserve exit codes, so older notes keep working.

`tools/py/` holds standard-library Python ports of the two linters and an
offline API check, for hosts that have Python and no Node - a custom GPT's Code
Interpreter, most of all. They are not approximations:
`tools/bin/lint-parity.mjs` runs every Luau file in the repository through both
implementations of both linters and fails on any difference in code, line or
message.

**Verify one name — exit 1 means you were about to invent it:**

```bash
node tools/bin/verify-api.mjs <Name>              # Roblox APIs, against the dump
node tools/bin/verify-executor-api.mjs <name>     # executor functions, against sUNC
```

**Check work before it ships:**

```bash
node tools/bin/lint-luau-slop.mjs <file.luau>     # counts the ceremony budget over real code
node tools/bin/lint-roblox-ui.mjs <file.luau>     # counts the UI rubric over real code
node tools/bin/lint-parity.mjs                    # proves the Python ports still agree
node tools/bin/lint-links.mjs                     # every file the stack points at
node tools/bin/lint-prose.mjs                     # API claims vs the dump
node tools/bin/lint-luau-blocks.mjs               # shipped examples vs luau
node tools/bin/lint-ui-directions.mjs             # stated contrast ratios, recomputed
node tools/bin/run-library-tests.mjs              # 42 assertions over library/src
```

**One command for all of it:**

```bash
node tools/bin/check-all.mjs          # fourteen gates, one verdict
node tools/bin/check-all.mjs --quick  # skip the slow ones
```

**Prove a change happened, rather than saying it did:**

```bash
node tools/bin/lint-luau-slop.mjs --compare before.luau after.luau
node tools/bin/lint-roblox-ui.mjs --compare before.luau after.luau
```

Both print the counts side by side and then how many moved. `0 counted rows
moved`, or `0 of them structural`, means the file was reformatted - which is
worth knowing before anyone calls it a rewrite.

**Keep the stack itself honest:**

```bash
node tools/bin/verify-executor-api.mjs --audit    # every accepted global is documented
node tools/bin/generate-tables.mjs --check        # tables match the dump
node tools/bin/build-portable.mjs --check         # the four host files are current
node tools/bin/update-dump.mjs --check            # is the vendored dump behind?
node tools/bin/update-dump.mjs                    # refresh, diff, regenerate
```

Every linter takes a path or a directory, so
`node tools/bin/lint-prose.mjs .claude/skills/roblox-ui` works.
`lint-luau-slop.mjs` also reads `--stdin`, for checking generated code before it
is written anywhere.

`update-dump` prints the added / removed / newly-deprecated diff between
releases, which is usually more useful than the dump itself. Roblox ships
weekly.

Sources: [`MaximumADHD/Roblox-Client-Tracker`](https://github.com/MaximumADHD/Roblox-Client-Tracker)
for the dump, [`Roblox/creator-docs`](https://github.com/Roblox/creator-docs)
for datatypes.

---

## MCP

Use the **built-in Roblox Studio MCP server** — first-party, nothing to install,
enabled from Studio's Assistant panel.

[docs/mcp.md](docs/mcp.md) has the full comparison, including a source-level
audit of the one third-party server worth considering and the reasons the others
were rejected. The standalone `Roblox/studio-rust-mcp-server` was archived in
April 2026; guides still recommending it are stale.

---

## Other hosts

The skills are native to Claude Code. The same rules reach three other tools,
generated from `docs/portability/rules.md` so they cannot drift:

| Host | File | Install |
|---|---|---|
| Codex | `AGENTS.md` | already at the repo root; copy into another project |
| Cursor | `.cursor/rules/roblox-luau-expert.mdc` | copy into that project's `.cursor/rules/` |
| a custom GPT | `docs/portability/gpt/` | its own folder — instructions to paste, knowledge to upload, and a README with the click order |
| an OpenAI plugin (ChatGPT, Codex) | `dist/openai-plugin/` | `node tools/bin/build-openai-plugin.mjs`, then [docs/portability/openai-plugin.md](docs/portability/openai-plugin.md) |

Sections are tiered. P0 is what fits the GPT's 8,000-character instructions cap
and **the build fails if it stops fitting**, which is what stops the spine
bloating until the field silently truncates. Full notes, including per-host
settings, in [docs/portability/README.md](docs/portability/README.md).

---

## Scope note

The executor half documents client-side scripting for private and educational
use, states ban risk plainly rather than pretending it away, and treats
detection and enforcement as the separate systems they are. It is paired with
`roblox-game-security` so the same knowledge serves defence.

[docs/portability/scope-and-framing.md](docs/portability/scope-and-framing.md)
covers the adjacent problem: the word "exploit" means both "a payload that
attacks somebody else's system" and "a Luau script in your own game client", and
a classifier cannot tell which one it received. The fix given there is precision
about which machine, whose account and what technically happens. It is not a
jailbreak, it says so, and it lists what stays declined.

---

## Provenance

Every external source — what it is, its licence, its status on a stated date,
and what was taken from it — is recorded in [docs/SOURCES.md](docs/SOURCES.md),
along with the sources that were evaluated and **rejected**, with reasons.

Popularity and recency figures live there and nowhere else. In skill prose they
rot silently, so `lint-prose` fails any file that states one without a date.

---

## License

[PolyForm Strict License 1.0.0](LICENSE.md): free for personal and other
noncommercial use; no selling, no changes, no redistribution. Third-party files
keep their own licenses, listed in [NOTICE.md](NOTICE.md).
