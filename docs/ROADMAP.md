# Roadmap

Things worth adding to the skill stack later, with why and where the source
material is. Each is a gap found while building or researching; none is
started. When one ships, move it to the changelog and delete it here.

Two limits shape every addition:

- **Skill metadata budget.** Hosts show every skill's name and description
  from a shared list of about 8,000 characters and drop skills when it runs
  over. `node tools/bin/lint-skills.mjs` holds this stack to 7,000; at 6,496
  with 34 skills, a new skill needs a description of about 180 characters
  and probably a trim elsewhere, or belongs as a reference inside an
  existing skill. The router is at 18,737 characters of a 20,000 warning.
- **Evidence before advice.** New API claims are checked against the dump by
  `lint-prose.mjs`; new code ships with a behaviour test.

## New areas

| Area | Why | Where it would live | Source to start from |
|---|---|---|---|
| Open Cloud | DataStores, MessagingService and place publishing over HTTP for tools and dashboards | `roblox-toolchain` reference | Roblox Open Cloud docs; `nonlooped/roblox-suite` `roblox-open-cloud` (MIT) |
| Physics and vehicles | constraints-based cars and boats, ragdolls, collision groups for gameplay | `roblox-engine-api` reference or a new skill | Roblox creator-docs; `nonlooped/roblox-suite` `roblox-physics` (MIT) |
| Publishing and discovery | icons, thumbnails, names and descriptions that get clicked | `roblox-game-design` reference | `AshExplained/roblox-skills` `roblox-publishing-discovery` (MIT) |
| Inventory and trading | item ids, stacking, server-owned trades with two-sided confirmation | `roblox-data-persistence` or `roblox-game-design` reference | the combat and data cases in `andrian-syh/roblox-best-practices-skill` (MIT) |
| Proximity and voice chat | `ShouldDeliverCallback` by distance, voice settings | `roblox-chat` reference | Roblox creator-docs `chat/examples/proximity-chat.md` |
| Legacy migration | replacing deprecated APIs across a whole place with Studio MCP | `roblox-studio-mcp` reference | `MSayib/roblox-dev-skill`, its legacy migration reference (MIT) |

## HubKit

- **More elements**: a Stepper (the worked case in the element contract), a
  progress bar, an image and a code block with copy.
- **Tabs on the top** for landscape phones, as an option on CreateWindow.
- **Localized strings** through `Translator:FormatByKey` for the kit's own
  words ("Search this tab", "Saving is off").
- **A Studio device pass** of the example through Studio MCP screen captures
  at each device profile, compared with the headless tests.
- **Luau type checking** of the sources once a `luau-analyze` binary is
  vendored beside the runtime.

## Stronger checks

- **A Node port of `viewport_fit.py`**, held to it by `lint-parity.mjs`, so
  the check runs where only Node is available.
- **Trigger evals run against a fresh model**, recording which skill each
  prompt in `evals/triggers.md` actually loaded.
- **`E-HOVERONLY` lint rule**: a `MouseEnter` that shows information with no
  `SelectionGained` or long-press path in the same file, once it can tell a
  hover tint from hidden content without false alarms.
- **Behaviour tests for the reference code** in `roblox-npc-ai` and
  `roblox-combat` (the follower, the melee handler), with PathfindingService
  and spatial-query stubs.

## More tested assets

- **Executor features**: waypoints (save and return), teleport to a player
  by name, and a chat-command bridge for hubs without a UI.
- **Game systems as tested modules**: daily reward with streak, quest board,
  currency service with analytics logging, each with a behaviour test.

## Hosts

- **Custom GPT retirement on 2026-12-11**: the ChatGPT plugin replaces it;
  move any remaining GPT-only instructions into the router before then.
- **Scheduled plugin updates**: the four-hourly task still uses "Upload new
  version", which fails while a duplicate plugin named `roblox-luau-expert`
  exists. The Plugin Creator chat route works; switching the task to it sends
  messages on the owner's behalf, so it waits for their approval.
- **The style picker and designer**: a "your screen" device preset in the
  designer that uses the visitor's own viewport, and a check in CI that loads
  both pages at phone, tablet and desktop sizes and fails on overflow.

## Public skills reviewed and not adopted

Recorded so they are not re-evaluated from scratch.

| Source | Decision |
|---|---|
| MSayib/roblox-dev-skill (MIT) | Adopted as a source for `roblox-studio-mcp`. Its Luau, networking and data references overlap skills here that are already dump-checked. |
| AshExplained/roblox-skills (MIT) | Adopted as a source for the Creator Store audit and `roblox-game-design`. The remaining skills are short playbooks with no verification. |
| nonlooped/roblox-suite (MIT) | Used as leads for `roblox-npc-ai`; one API it names is not in the dump. Open Cloud and physics noted above. |
| andrian-syh/roblox-best-practices-skill (MIT) | Review taxonomy adapted in `roblox-improve`. Its style rules (doc comments on every function) conflict with this stack's ceremony budget and were not taken. |
| gamedev-skills/awesome-gamedev-agent-skills (Apache-2.0) | Feedback tiers adopted. Its Roblox skills are thin compared with the dump-checked ones here. |
| afrxo/roblox-agent-skills (MIT) | Overlaps existing Luau, UI and toolchain skills. |
| flatbedj/roblox-skills, brockmartin/roblox-game-skill, zilibobi/roblox-skills | No licence stated; not used. |
