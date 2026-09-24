# MCP servers for Roblox work

Vetted on stars, licence, maintenance and **actual source behaviour** — not on
README claims. Audit date: 2026-09-09.

---

## Recommendation

**Use the built-in Studio MCP server.** It ships inside Roblox Studio, so there
is no third-party code in the path at all. Add `Chrrxs/robloxstudio-mcp`
only if you specifically need the profiler, memory breakdown, breakpoints or
multiplayer playtest control that the built-in server does not expose.

---

## 1. Built-in Roblox Studio MCP — recommended

First-party. Nothing to install.

**Enable:** Studio → **Assistant** panel → **Manage MCP Servers** →
toggle **Enable Studio as MCP server**. The quick-connect list names Claude Code
explicitly and writes the stdio config for you.

**Transport:** stdio. Works with any client that supports stdio transport.
Documented quick-connect clients: Antigravity, Codex CLI, Claude Code, Claude
Desktop, Cursor, Gemini CLI, VS Code.

**Capabilities:**

| Area | What it does |
|---|---|
| Scripts | read, multi-line edit, search by name, grep across code |
| Assets | AI-generated meshes and materials, Creator Store search and insert |
| Data | instance hierarchy, property inspection, subagents |
| Execution | run Luau in Edit, Client and Server contexts |
| Testing | play-mode control, viewport screenshots, keyboard/mouse simulation, console logs |
| Docs | Roblox API reference and skill guidance lookup |

**Roblox's own caveat, verbatim:** *"Make sure to only connect clients you
trust"* — a connected client can read and modify content in your open places.

**Data:** first-party. Studio is already talking to Roblox; this adds no new
third party.

> The standalone [`Roblox/studio-rust-mcp-server`](https://github.com/Roblox/studio-rust-mcp-server)
> (486★) was **archived in April 2026** and superseded by the built-in server.
> Any guide still recommending it is out of date.

---

## 2. `Chrrxs/robloxstudio-mcp` — optional, audited, safe

208★ · MIT · v3.1.3 · pushed 2026-09-09 · actively maintained

Fills real gaps: `capture_micro_profiler`, `capture_script_profiler`,
`get_memory_breakdown`, `breakpoints`, `get_runtime_logs`, `solo_playtest`,
`multiplayer_playtest`, and per-peer `eval_server_runtime` /
`eval_client_runtime`. If you are doing performance work, this is why you would
add it.

```bash
npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```

### Source audit — 2026-09-09, v3.1.3

The README makes no privacy claim either way, so the source was read.

| Check | Finding |
|---|---|
| Telemetry / analytics | **None.** No PostHog, Segment, Mixpanel, Sentry, Amplitude, Datadog, or any beacon. Zero matches across all source. |
| Outbound hosts | `registry.npmjs.org` (install), `github.com` / `api.github.com` (plugin download), and **Roblox first-party only** — `apis.roblox.com`, `users.roblox.com`, `thumbnails.roblox.com`, `contentdelivery.roblox.com`, `itemconfiguration.roblox.com`, `create.roblox.com`, `fts.rbxcdn.com`. No third-party endpoint. |
| Local surface | HTTP on loopback, bridging to a Studio plugin. |
| Local auth | Shared-secret token, stored `~/.robloxstudio-mcp/auth-token` mode `0600`, constant-time comparison. Source comment states the intent plainly: gate the surface *"so that localhost malware and cross-origin web pages"* cannot drive it. |
| CORS | `ROBLOX_STUDIO_ALLOWED_ORIGINS` allowlist. |
| Credentials | **Opt-in only, never required.** `ROBLOX_OPEN_CLOUD_API_KEY` and `ROBLOSECURITY` are read from the environment for asset upload. |
| Governance | `SECURITY.md` with private vulnerability reporting; dedicated security test suites (`http-security`, asset-security, port isolation). |

**Verdict: safe to run, with three things to know.**

1. **`ROBLOSECURITY` is a full Roblox account credential.** The server can use
   one for asset upload. Do not set it. Use `ROBLOX_OPEN_CLOUD_API_KEY` instead
   — scoped, revocable, and the right tool. Neither is needed for normal use.
2. **`ROBLOX_STUDIO_NO_AUTH=1` disables the local auth gate.** Do not set it.
   The gate is what stops other local processes and web pages driving your
   Studio session.
3. **It executes arbitrary Luau in your Studio session by design.** That is the
   feature. It carries the same trust requirement as the first-party server.

---

## 3. Context7 — already connected

Live library documentation. Useful for Luau, Rojo, Wally and library APIs where
you want current docs rather than recalled ones. Nothing to install here; it is
already in this environment.

---

## Rejected

| Server | ★ | Why |
|---|---|---|
| `hope1026/weppy-roblox-mcp` | 61 | Maintained, but the built-in server plus Chrrxs already covers the ground. Not audited. |
| `dmae97/roblex-studio-mcp-server` | 7 | Last pushed 2025-04. Abandoned. |
| `drgost1/robloxstudio-mcp` | 6 | Single-day commit history. |
| `aaronaalmendarez/roblox-mcp` | 2 | No review surface at that adoption. |
| `Justice219/roblox-studio-mcp` | 2 | Created and last pushed the same day. |

At two to seven stars, nobody has meaningfully reviewed the code, and these all
execute arbitrary Luau in your Studio session. Adoption is not a quality signal
in general, but it is a proxy for *how many people would have noticed something
bad* — and at that level, the answer is none.

---

## Wiring

**There is no `.mcp.json` in this repository, deliberately.** An earlier
version of this file claimed there was; there was not, and shipping one would
wire an MCP server into every project that installs this stack without the
user asking for it.

`docs/mcp.json.example` carries both entries — the built-in Studio server and
the optional audited third-party one, the latter commented out — for copying
into your own configuration.

Studio's own quick-connect is the least error-prone route — it writes the
correct command for your install. Use the example file only if you are wiring by
hand or replicating a setup.

## General rule for any Roblox MCP server

Every one of these can read and modify your open place, and most can execute
Luau in it. Before adding one:

1. Check the star count and the last push date.
2. Read the source for outbound hosts, not just the README.
3. Grep for telemetry libraries by name.
4. Check whether credentials are required or optional — required is a red flag.
5. Prefer the first-party server unless you need a specific missing capability.
