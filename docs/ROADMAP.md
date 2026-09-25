# Roadmap

Things worth adding to the skill stack later, with why and where the source
material is. Each is a gap found while building or researching; none is
started. When one ships, move it to the changelog and delete it here.

Two limits shape every addition:

- **Skill metadata budget.** Hosts show every skill's name and description
  from a shared list of about 8,000 characters and drop skills when it runs
  over. `node tools/bin/lint-skills.mjs` holds this stack to 7,000; at 6,474
  with 27 skills, a new skill needs a description of about 250 characters, or
  belongs as a reference inside an existing skill.
- **Evidence before advice.** New API claims are checked against the dump by
  `lint-prose.mjs`; new code ships with a behaviour test.

## New areas

| Area | Why | Where it would live | Source to start from |
|---|---|---|---|
| TextChatService | chat commands, channels and bubble chat come up often, and the legacy `Chat` service guidance is out of date | reference in `roblox-engine-api` | Roblox creator docs; flatbedj/roblox-skills `roblox-textchat-channels` |
| NPCs and pathfinding | `PathfindingService`, agent parameters, stuck detection and server-owned NPC movement have no coverage | new skill or `roblox-engine-api` reference | Roblox creator docs |
| Combat systems | server-authoritative hit detection, cooldowns and lag compensation, beyond the sanity checks in security | `roblox-game-security` or `roblox-game-design` reference | AshExplained/roblox-skills `roblox-combat-systems` (MIT) |
| Open Cloud | DataStore, MessagingService and place publishing over HTTP for tools and dashboards | `roblox-toolchain` reference | Roblox Open Cloud docs; flatbedj/roblox-skills `roblox-cloud` |
| Localization and accessibility | `LocalizationService`, translated strings, text that grows, colour-blind-safe status | `roblox-ui` reference | AshExplained/roblox-skills `roblox-localization-accessibility` (MIT) |
| Policy compliance | Community Standards, advertising rules, paid random items by region | `roblox-monetization` reference | AshExplained/roblox-skills `roblox-policy-compliance` (MIT), Roblox policy pages |
| Publishing and discovery | icons, thumbnails, names and descriptions that get clicked | `roblox-game-design` reference | AshExplained/roblox-skills `roblox-publishing-discovery` (MIT) |
| Admin tools | safe admin commands, audit logs, moderation, without a backdoor | `roblox-game-security` reference | AshExplained/roblox-skills `roblox-admin-tools-observability` (MIT) |
| Legacy migration | replacing deprecated APIs across a whole place with Studio MCP | `roblox-studio-mcp` reference | MSayib/roblox-dev-skill, its legacy migration reference (MIT) |

## Stronger checks

- **A Node port of `viewport_fit.py`**, held to it by `lint-parity.mjs`, so
  the check runs where only Node is available.
- **Studio device pass through MCP**: a scripted run of screen captures at
  each device profile using Roblox's `rbx-device-simulator-lua` skill,
  compared with `viewport_fit.py`.
- **Trigger evals for the new skills** run against a fresh model, recording
  which skill each prompt in `evals/triggers.md` actually loaded.
- **`E-HOVERONLY` lint rule**: a `MouseEnter` that shows information with no
  `SelectionGained` or long-press path in the same file, once it can tell a
  hover tint from hidden content without false alarms.

## More tested assets

- **A complete hub**: the feature assets wired to T, H and N recipes in one
  window that passes the UI rubric, the viewport check and the input matrix.
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
| MSayib/roblox-dev-skill (MIT) | Adopted as a source for `roblox-studio-mcp`: tool shapes, first-party Studio skills and safety rules, re-verified against Roblox's MCP page. Its Luau, networking and data references overlap skills here that are already dump-checked. |
| AshExplained/roblox-skills (MIT) | Adopted as a source for the Creator Store audit and for `roblox-game-design` topics. The remaining 30-odd skills are short playbooks with no verification; the useful ones are listed in the table above for later. |
| flatbedj/roblox-skills | License not stated on the repository page; not used. TextChatService and Open Cloud topics noted above. |
