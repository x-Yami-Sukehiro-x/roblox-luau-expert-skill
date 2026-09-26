# Sources

Every external source consulted, what was taken from it, and — equally
important — what was **rejected and why**.

**All figures verified 2026-09-10 via the GitHub API.** Popularity and recency
numbers live only in this file. In skill prose they rot silently, so
`lint-prose.mjs` fails any skill file that states one without a date beside it.

Nothing was copied wholesale. Public skill repositories were studied for
**structure and coverage gaps**; the prose in this stack is original.

---

## Ground truth

The stack vendors two sources, because one is not enough.

| Source | ★ | Licence | Vendored as | Used for |
|---|---|---|---|---|
| [MaximumADHD/Roblox-Client-Tracker](https://github.com/MaximumADHD/Roblox-Client-Tracker) | 539 | none stated | `tools/api-dump/` | **The accuracy backbone.** `API-Dump.txt`, `FVariables.txt`, `LuauTypes.d.luau`, `version.txt`. Rebuilt every client release |
| [Roblox/creator-docs](https://github.com/Roblox/creator-docs) | 828 | CC-BY-4.0 | `tools/api-dump/datatypes/` | **Datatypes.** The API dump contains classes and enums *only* — `CFrame`, `TweenInfo`, `RaycastParams` and `SharedTable` are absent from it entirely |
| [luau-lang/luau](https://github.com/luau-lang/luau) | 5,852 | MIT | — | Language reference, compiler limits |
| [create.roblox.com/docs](https://create.roblox.com/docs) | — | — | — | Studio MCP capabilities and the "only connect clients you trust" caveat, quoted verbatim |
| [luau.org](https://luau.org) | — | — | — | `buffer` and `vector` signatures, syntax extensions, native codegen |

### What the dump caught

- `RunService.Stepped` / `.RenderStepped` / `.Heartbeat` are **not** `[Deprecated]`
  — superseded by name only. Calling them a defect in review is a false positive.
- Security is **direction-aware**. `Workspace.StreamingEnabled` is readable by
  any script and `Plugin`-gated for writes; a single "security level" model
  would misreport it.
- `Players:CreateHumanoidModelFromDescription` is `[Deprecated]` — and was being
  recommended by this stack's own UI reference until v3 pointed the linter at it.
- `GuiService.SafeZoneOffsetsChanged` is `{RobloxScript}`, so a normal
  LocalScript cannot connect to it, despite being the event most guides name.
- Member names are not all identifiers: `Studio.Auto-Recovery Interval (Minutes)`,
  `PVInstance.Pivot Offset`. A `\w+` capture silently loses 64 members.

### What only the datatype reference could settle

`SharedTable.increment` and `.update` are the only race-free read-modify-write
operations across Actors, and neither appears in the API dump. Nor do
`RaycastParams.RespectCanCollide` or `.BruteForceAllSlow`, which v2 claimed were
"verbatim from the vendored dump".

---

## Skill repositories studied for structure

| Repo | ★ | Status | Taken |
|---|---|---|---|
| [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | 927 | active 2026-09-10 | Router-plus-focused-skills topology; routing on detected context rather than making the user name a skill |
| [brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill) | 160 | active 2026-03-04 | Coverage checklist. Its reference breakdown surfaced the monetization, animation and testing gaps |
| [MSayib/roblox-dev-skill](https://github.com/MSayib/roblox-dev-skill) | 14 | active 2026-09-05 | **The API-dump-monitor idea.** Its release-tracking approach is the model for `tools/bin/update-dump.mjs` |
| [anthropics/skills](https://github.com/anthropics/skills) | — | active | SKILL.md frontmatter conventions |

---

## Reference material

| Source | ★ | Status | Used for |
|---|---|---|---|
| [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/) | — | — | Naming and layout baseline in `roblox-code-craft` |
| [Kampfkarren/kampfkarren-luau-guidelines](https://github.com/Kampfkarren/kampfkarren-luau-guidelines) | 97 | 2025-01-08 | Practitioner Luau conventions |
| [docs.sunc.io](https://docs.sunc.io/) | — | — | Executor API surface; the sUNC-vs-UNC divergence, quoted |
| [unified-naming-convention/NamingStandard](https://github.com/unified-naming-convention/NamingStandard) | 132 | **ARCHIVED 2024-05-04** | Historical UNC only, recorded as history in `recon/landscape.md` |
| [Pseudoreality/Roblox-Identities](https://github.com/Pseudoreality/Roblox-Identities) | 71 | active 2026-09-10 | The named identities and capability matrix, which supersedes the obsolete "0–8, higher is more" model |
| [luau/UniversalSynSaveInstance](https://github.com/luau/UniversalSynSaveInstance) | 430 | active 2026-09-09 | `recon/saveinstance-decompile.md` |
| Roblox DevForum — memory-leak threads | — | — | The connection-leak playbook; confirmed `Player` objects are not destroyed on leave |
| [Designing UI — Tips and Best Practices](https://devforum.roblox.com/t/designing-ui-tips-and-best-practices/3074034) | — | Roblox Engine UI team | Mobile-first sizing, `AnchorPoint`, safe areas |

> That DevForum post states the topbar as 36px; community replies report 58px.
> The stack now uses `GuiService.TopbarInset` (a `Rect`, `[ReadOnly]`) and tells
> you never to hardcode either.

---

## Libraries surveyed

Status verified 2026-09-10. Listed so the stack can say "active" or "archived"
without carrying a number that rots.

### UI — game side

| Library | ★ | Last push | Verdict |
|---|---|---|---|
| Fusion | 795 | 2026-02-02 | Active. The most-adopted Roblox-native reactive option |
| React-lua | 568 | 2025-05-23 | Going stale; caveated where recommended |
| Iris | 349 | 2026-09-04 | Active — debug tooling, not player UI |
| Vide | 323 | 2026-08-05 | Active |
| Charm | 253 | 2026-06-22 | Active. State only, no renderer |
| ui-labs | 189 | 2026-08-13 | Active storybook (GPL-3.0 — check before vendoring) |
| flipbook | 125 | 2026-09-09 | Active storybook |
| **Roact** | 625 | 2023-12-13 | **ARCHIVED.** Still the top search result; React-lua succeeds it |

### UI — executor hub side

| Library | ★ | Last push | Verdict |
|---|---|---|---|
| WindUI (`Footagesus`) | 350 | 2026-08-01 | Active |
| Obsidian (`deividcomsono`) | 141 | 2026-09-07 | Active. Maintained Linoria fork; config-save built in |
| Fluent (`dawid-scripts`) | 120 | 2024-05-09 | Stale |
| LinoriaLib (`violin-suzutsuki`) | 96 | 2024-08-09 | Stale — the original. Active forks exist |
| Rayfield | 77 | 2026-06-14 | Active |

### Data

ProfileStore 333 (Apache-2.0, 2025-07-31) · ProfileService 326 (2024-10-13,
**superseded by ProfileStore**, same author) · Lyra 152 (MIT, 2026-03-25) ·
Lapis 81 (MIT, 2025-02-12)

### Networking

Blink 182 (MIT, 2026-08-24 — `1Axen/blink`, **not** `jackdotink`, a commonly
cited wrong path) · Zap 187 (MIT, 2026-06-23) · ByteNet 179 (MIT, 2025-08-01)

### Cleanup and async

Trove — ships **inside** `Sleitnick/RbxUtil` 463 (2026-08-11); it is **not** a
standalone repo · Janitor 148 (MIT, 2026-07-28) · Promise 352 (2024-08-06)

### Frameworks

roblox-ts 1,298 (2026-09-10) · Flamework 158 (2025-09-04) · Matter 115
(2024-12-31) · **Knit 630 — ARCHIVED 2024-07-31**

### Tooling

StyLua 2,287 (2026-09-10) · Rojo 1,726 (2026-07-06) · Lune 947 (2026-07-03) ·
selene 813 (2026-05-21) · luau-lsp 533 (2026-09-10) · Wally 495 (2026-01-28) ·
Rokit 451 (2026-05-09) · jest-lua 60 (2024-12-23)

---

## MCP servers

Full comparison: [`mcp.md`](mcp.md).

**Recommended:** the **built-in Roblox Studio MCP server**. First-party, ships in
Studio, nothing to install.

**Audited and cleared:** [Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp)
— 209★, MIT, active 2026-09-09. Source read: **no telemetry or analytics of any
kind**; outbound hosts are npm, GitHub and Roblox first-party only; loopback HTTP
gated by a `0600` shared-secret token with constant-time comparison; credentials
(`ROBLOSECURITY`, `ROBLOX_OPEN_CLOUD_API_KEY`) are opt-in and never required;
ships a `SECURITY.md` and dedicated security test suites.

---

## Public agent skills assessed for v5

Read in full and mined for what this stack did not already have. Adopted as
**rules inside the Roblox skills**, not as dependencies: a stack that only works
when five other skills are installed is not portable to a GPT, Codex or Cursor,
and portability is the whole point of `docs/portability/`.

| Skill | Verdict | What was taken |
|---|---|---|
| `shut-up-and-code` | **Adopted** | The per-clause test. This stack scored a comment as one block, so a four-line comment with one real line and three of restatement passed by dilution. Now `E-CLAUSE`, in both linters, and §3a of `anti-slop-code.md`. Also its framing — "name what the reader loses without it" — which is a sharper test than "why, not what" |
| `verification-before-completion` | **Adopted** | Its iron law, narrowed to something checkable: a claim needs a command **in the same reply**. Became the P0 "Claims need a receipt" section, delivery-checklist §6a, and the `--compare` mode on both linters. The general version is advice; the `--compare` output is a number |
| `evolutionary-naming` | **Adopted in part** | One idea: a name that is a lie costs more than a name that is obviously provisional. Applied where it bites hardest here — a decompiled `v14` renamed to `damageRemote` on evidence that only established "a remote" is worse than `unknownRemote`. In `anti-slop-code.md` §6. The seven-step process itself is for human-paced refactoring and does not fit a single-reply workflow |
| `karpathy-guidelines` | **Already covered** | "Simplicity first", "surgical changes", "every changed line traces to the request" are the ceremony budget and the edit discipline, already counted rather than advised. Nothing new to take |
| `systematic-debugging` | **Already covered** | `roblox-request-intake/references/error-triage.md` is the same loop against Roblox's actual error strings, which is more useful here than the general form |

### Assessed and rejected

Judged from their stated scope, not read line by line, because the scope
decides it:

- **`avoid-ai-design`, `hallmark`, `impeccable`, `professional-web-craft`,
  `ui-craft`, `ui-ux-pro-max`, `frontend-design`** — all web. Their anti-slop
  instincts are right and their specifics are HTML, CSS, Tailwind and shadcn.
  Roblox has no cascade, no media queries, no DOM: the equivalents are
  `UIListLayout`, `UIFlexItem`, `UISizeConstraint` and `ScreenInsets`, and a
  rule written for one is wrong for the other. `roblox-ui/references/` is the
  translation, and it is already the larger body of work.
- **`clean-code`, `refactoring`, `defensive-programming`, `documentation`,
  `peer-code-review`, `code-clarity`** — general and sound, and every rule that
  applies to Luau is already in `roblox-code-craft` with a counter behind it.
  Adding them would add prose that agrees with prose already here.
- **`anti-reverse-engineering`** — defensive hardening of a binary you ship.
  Adjacent to `roblox-game-security` and aimed at a different artefact; Roblox
  gives you no binary to harden.
- **`pythonic-deslop`, `typescript-strict`, `javascript-strict`, `go-mastery`,
  `swift-strict`, `c-lang`, `ruby`** — other languages.
- **`dataviz`, `postgres-strict`, `api-design`, `observability`,
  `concurrency`, `algorithms`, `clean-architecture`, `performance`,
  `security`** — no Roblox surface, or a Roblox surface already covered by the
  matching skill here.

The test applied throughout: **does it change what a file looks like when it
ships, in a way something here can check?** Three did. The rest either already
hold, or hold somewhere this stack does not go.

---

## Rejected, with reasons

### Archived or superseded

Still widely recommended online, which is why each is listed explicitly.

| Project | ★ | Why |
|---|---|---|
| `Roblox/studio-rust-mcp-server` | 486 | **Archived 2026-04-03.** Superseded by the built-in Studio server |
| `Roblox/roact` | 625 | **Archived 2023-12-13.** React-lua succeeds it |
| `Sleitnick/Knit` | 630 | **Archived 2024-07-31.** Documented as legacy, not recommended for new work |
| `Roblox/testez` | 209 | **Archived 2024-03-05.** jest-lua is current |
| `LPGhatguy/aftman` | 198 | **Archived 2025-07-09.** Rokit is the successor |
| `unified-naming-convention/NamingStandard` | 132 | **Archived 2024-05-04.** sUNC is the live standard |

### Too small to have been reviewed by anyone

Each executes arbitrary Luau in your Studio session, so adoption matters as a
proxy for scrutiny: `hope1026/weppy-roblox-mcp` (61★, AGPL-3.0, not audited,
redundant) · `dmae97/roblex-studio-mcp-server` (7★, dead since 2025-04) ·
`drgost1/robloxstudio-mcp` (6★, single-day history) ·
`aaronaalmendarez/roblox-mcp` (2★) · `Justice219/roblox-studio-mcp` (2★,
created and abandoned the same day).

### Skill repos not used

`AshExplained/roblox-skills` (6★, single-day push) ·
`afrxo/roblox-agent-skills` (1★) · `zilibobi/roblox-skills` (0★) ·
`CyanoTex/Roblox-Claude-Code-Skills` (repository did not resolve) ·
`synpixel/roblox-luau-style-guide` (1★, dead since 2023).

---

## Claims deliberately not made

- **No UNC/sUNC percentage figures.** Self-reported, shift after every Roblox
  update, and stale within weeks.
- **No executor ranking.** `recon/landscape.md` teaches feature detection
  instead, which makes the question mostly moot.
- **No numeric thread-identity table.** The authoritative source publishes named
  identities and capabilities but not the numeric mapping, so the stack tells you
  to read the value at runtime rather than hardcode one that may be wrong.
- **No `Players:BanAsync` config-key guarantee.** The dump types the parameter as
  an open table and does not enumerate its keys, so the field names in
  `roblox-game-security` are labelled **recalled, not verified**.
- **No Material Design token values.** M3's cubic-beziers do not map onto
  Roblox's fixed `Enum.EasingStyle` set. The stack ships duration *bands* and an
  intent map instead of borrowed numbers.

---

## UI research

**Official documentation** —
[`creator-docs/content/en-us/ui/`](https://github.com/Roblox/creator-docs/tree/main/content/en-us/ui):
`animation.md`, `appearance-modifiers.md`, `9-slice.md`, `list-flex-layouts.md`,
`size-modifiers.md`, `scrolling-frames.md`, `rich-text.md`, `2D-paths.md`,
`styling/`.

> Two corrections applied: the docs summarise `UIGradient.TileMode` and `.Type`
> without their real enum names. They are `Enum.GradientTileMode` and
> `Enum.GradientType`. The dump settled it.

**Release threads** — the Roblox announcements for **native UI shadows and
individual corners** (`UIShadow`, per-corner `UICorner`) and for **upgraded UI
gradients** (`Type`, `TileMode`, `Scale`, plus `Path2D` support). Source for the
gradient performance rules: animate geometry rather than colour sequences, keep
stop counts low, bound the total live gradient count.

**Structural debt** — the `avoid-ai-design` skill's tells catalogue is the model
for `anti-slop-catalog.md`'s coded, severity-tiered format. Its *tells* are
web-specific (Inter, shadcn, indigo gradients) and transfer to Roblox not at all;
the format does, and is far more actionable than prose. The Roblox tells (R1–R17)
are original.

**Script-hub UI libraries — measured, not recalled (2026-09-19).** Every table
row in `docs/portability/gpt/UIs/catalog.md` comes from two checks run that day:
the GitHub API for stars, licence and last push, and `grep` over the single file
each library's users actually `loadstring`. The file and its byte count are
printed beside every row so the measurement can be repeated.

The finding that justified the folder: across WindUI `dist/main.lua`, Obsidian
`Library.lua` and the `source.lua` of Rayfield, Kavo and Orion — 2.2 MB of Lua —
there are **zero** uses of `Activated` and **zero** of `SelectionGained`, and
`UISizeConstraint` appears four times, all in WindUI. Five independent libraries
agreeing is what consensus looks like from the inside; here it is one mistake
copied four times, and a model trained on public hub scripts learned it as the
norm.

Rayfield's analytics are quoted from its own `source.lua` by line number rather
than characterised, because it is the kind of claim that should be checkable:
`usageAnalytics` defaults true, and the file fetches and executes a reporter
from its own repository which posts to a Cloudflare Worker.

**Toast / notification libraries — none adopted.** A GitHub survey on 2026-09-10
returned nothing above two stars, all unmaintained. There is no credible
open-source Roblox toast library, so `toasts.md` and `library/src/Toast.luau` are
a build guide and a reference implementation, not a recommendation.

**Toast UX** — cross-referenced rather than taken from one source: LogRocket
(when a toast is the wrong pattern, duration, what must not go in one), Canva
Apps design guidelines, and general stacking-limit conventions. Consensus taken:
3–6s duration band, max ~3 visible, pause on hover, never colour-alone for
severity, honour reduced motion.

**Motion principles** — Material Design 3 and M1 for the intent→direction
mapping: ease-out entering, ease-in leaving, ease-in-out between states, exits
shorter than entries.

## Added for 5.8, checked 2026-09-25

| Source | Licence | Used for |
|---|---|---|
| [OpenAI: build skills](https://learn.chatgpt.com/docs/build-skills) and [plugins](https://developers.openai.com/plugins/build/plugins) | — | The start-up skill list is capped at 2% of the context window or 8,000 characters; descriptions are shortened and then skills dropped when it runs over. Plugins discover skills from `skills/`. Basis for `lint-skills.mjs` and the rewritten descriptions |
| [Agent Skills specification](https://agentskills.io/specification) | — | Name and description limits (64 and 1,024 characters), SKILL.md under 500 lines and about 5,000 tokens, references one level deep |
| [Claude Code skills](https://code.claude.com/docs/en/skills) | — | The skill listing shares about 1% of the context window with every installed skill |
| [Roblox Studio MCP](https://create.roblox.com/docs/studio/mcp) | — | The documented tool list, `studio_id`, `datamodel_type`, search limits; `roblox-studio-mcp` |
| [MSayib/roblox-dev-skill](https://github.com/MSayib/roblox-dev-skill) | MIT | Studio MCP argument shapes, Roblox's first-party `rbx-*` skills, the drifting `script_grep` line numbers and the agent-to-Studio safety rules, each re-checked against Roblox's page. Facts only; the prose here is original |
| [Roblox: third-party vulnerabilities](https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities) | — | Imported-asset audits, sandboxing and capabilities |
| [AshExplained/roblox-skills](https://github.com/AshExplained/roblox-skills) | MIT | Coverage gaps: imported-asset audits, economy, retention and genre topics for `roblox-game-design`. Its `set_active_studio` step does not exist in Roblox's tool list and was not carried over |
| [web.dev and MDN on viewport units](https://developer.mozilla.org/en-US/docs/Web/CSS/length#relative_length_units_based_on_viewport) | — | `dvh` and `svh` for the designer's full-height layout on phones whose browser bars change the viewport |

## Added for 5.9, checked 2026-09-26

| Source | Licence | Used for |
|---|---|---|
| [OpenAI: build skills](https://learn.chatgpt.com/docs/build-skills) and [plugins](https://developers.openai.com/plugins/build/plugins) | — | Re-checked: the 2% or 8,000-character start-up list, trigger words first, and portable plugins discovering skills in `skills/` without a manifest field. 34 skills now total 6,496 characters |
| [Roblox creator-docs](https://github.com/Roblox/creator-docs) | CC-BY-4.0 docs | Pathfinding limits (3,000 studs, about 20,000 nodes), the 8-second `MoveTo` timeout, `TakeDamage` and `ForceField`, TextChatService hooks and where each runs, text filtering duties, `BanAsync` fields, `PolicyService` fields, `GetGuiObjectsAtPosition` coordinates, `RunContext` |
| [Footagesus/WindUI](https://github.com/Footagesus/WindUI) | MIT | The folder split HubKit follows (components, elements, modules, themes) and darklua bundling as the alternative. No code copied |
| [nonlooped/roblox-suite](https://github.com/nonlooped/roblox-suite) | MIT | Leads for `roblox-npc-ai`: follower shape, blocked-path handling, scaling. Its `Path.CalculationSecondsTimeout` is not in the dump and was not used |
| [andrian-syh/roblox-best-practices-skill](https://github.com/andrian-syh/roblox-best-practices-skill) | MIT | The severity taxonomy, near-miss pairs and four-part gate adapted in `roblox-improve/references/false-positives.md`; the combat case's intent-then-validate order |
| [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 | The feedback-tier model and trauma camera shake, translated to Roblox in `roblox-combat/references/game-feel.md` and `roblox-improve/references/ux-review.md` |
| [brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill), [zilibobi/roblox-skills](https://github.com/zilibobi/roblox-skills) | none stated | Not used |
| [afrxo/roblox-agent-skills](https://github.com/afrxo/roblox-agent-skills) | MIT | Reviewed; its Luau types, Fusion and toolchain material overlaps skills here already checked against the dump |


## Added for 5.10, checked 2026-09-26

| Source | Licence | Used for |
|---|---|---|
| [OpenAI: build skills](https://learn.chatgpt.com/docs/build-skills) | — | Re-checked: the start-up list uses at most 2% of the model's context window, or 8,000 characters when the window is unknown; descriptions are shortened first, then skills omitted with a warning; trigger words go first. 46 skills now total 6,976 characters |
| [Luau 0.739 compiler](https://github.com/luau-lang/luau/releases/tag/0.739), vendored in `tools/runtime/` | MIT | The `-O0` listing's `GETGLOBAL` and `SETGLOBAL` operands behind `W-SCOPE`; the measured hub (199 top-level locals compile at 206 registers, the 201st fails); a test in which `-O2` inlining did not raise a caller's register use |
| [sUNC documentation](https://docs.sunc.io/), as summarised in `roblox-executor/references/api/` | — | `hookmetamethod`, `getnamecallmethod`, `checkcaller` and `newcclosure` for `remote-spy.luau`; `filtergc` table options for `table-finder.luau`; `getconnections` fields for archetype 7; `restorefunction`'s whole-chain behaviour, which is why the spy leaves a pass-through hook instead |
