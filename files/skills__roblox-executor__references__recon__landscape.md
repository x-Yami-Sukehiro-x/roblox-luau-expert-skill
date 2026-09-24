# The executor landscape

Current-state honesty, so answers do not cite dead standards or stale scores.
Everything here changes; **cite the mechanism, not the number**, and tell the
user where to check the live state rather than baking a figure into a script.

---

## The standards: UNC is dead, sUNC is live

**UNC** — the Unified Naming Convention, `unified-naming-convention/NamingStandard`
(132★) — was the original attempt at a shared executor API surface. It is
**archived as of 2024-05-04**. Anything presenting UNC as the current standard
is out of date.

**sUNC** — "senS' Unified Naming Convention", [docs.sunc.io](https://docs.sunc.io/) —
is its live successor, and it has deliberately diverged. In its own words:
*"Over time, sUNC has largely diverged from the original UNC to become better and
shaped by executor developers and users, hence why some functions have been
deprecated/removed and others may have been added."*

sUNC documents only functions it actively tests. A function's absence from sUNC
means it is untested by that suite, not necessarily that it does not exist.

The `api/` folder in this skill follows sUNC. Section coverage there: closures,
debug, drawing, encoding, environment, filesystem, instances, metatable,
miscellaneous, reflection, scripts, signals, websocket.

**On "UNC percentage" scores.** They are a test-suite pass rate, they shift after
every Roblox update, and vendors quote their own best-case figure. Never state a
percentage as a fact in an answer. If a user needs one, point them at a live
tracker or the executor's own channel and say the number moves weekly.

---

## Hyperion / Byfron

Roblox's client anti-tamper. Enough detail to answer accurately, not enough to
act on:

- Periodic memory-page scans cross-referencing executable pages against a
  whitelist; unapproved executable pages have execute permission revoked,
  crashing any thread that enters them.
- Randomly placed trap pages and execution verification.
- Manual PEB traversal to verify loaded modules against a whitelist, catching
  module stomping.
- Thousands of localised polymorphic integrity checks using dynamic constants
  and randomised bitwise operations, mutating per build — static patching and
  emulation are impractical.

**Practical consequence: executor stability is an executor problem, not a
scripting problem.** Claimed bypasses circulate constantly, are rarely verified,
and are typically short-lived. Nothing in this skill helps with process-level
injection, and questions about it should be answered by saying so.

The live day-to-day risk for a script author is **per-game detection and
bans** — a completely different mechanism, and the one `detection-surface.md`
and `anticheat-recon.md` actually address.

---

## Platform notes

- **Windows** is where the ecosystem lives, and where Hyperion is strongest.
- **UWP / Microsoft Store builds** historically had a different footing than the
  Win32 client. Verify current behaviour before relying on any difference.
- **macOS** has its own separate tooling.
- **Android** builds are a separate ecosystem again, with their own API gaps.
  Do not assume a Windows sUNC function exists on mobile — feature-detect.

---

## Choosing what to write against

Write against **sUNC names with feature detection**, not against a specific
executor. That single decision makes a script portable across the churn.

```lua
local function has(name: string): boolean
    -- Read the running environment, not the getgenv() table: some executors
    -- expose functions on the Roblox globals only, and the indexed form
    -- reports those as missing.
    return typeof((getfenv or getgenv)()[name]) == "function"
end

if not has("filtergc") then
    warn("this executor lacks filtergc; falling back to getgc scan")
end
```

When a user names their executor, the useful response is which *functions* they
have, not a ranking. Ask them to run a capability probe rather than trusting a
marketing claim:

```lua
local required = { "hookfunction", "getgc", "filtergc", "getrawmetatable",
                   "newcclosure", "checkcaller", "getnamecallmethod", "request" }
for _, name in required do
    print(name, typeof((getfenv or getgenv)()[name]) == "function" and "yes" or "MISSING")
end
```

---

## Legacy names you will still meet

**Synapse X** is discontinued. Its `syn.*` library persists as an alias layer in
many executors — documented in `../api/legacy-syn.md`. Prefer the modern name;
mention `syn.*` only when reading someone's legacy code.

**Rainer / Raindrop** were older free executors whose APIs overlapped early
UNC / Synapse-style naming. Functions you may see in archived scripts:
`getgenv`, `getrenv`, `getreg`, `getgc`, `getsenv`, `getmenv`,
`getrawmetatable`, `setrawmetatable`, `getnamecallmethod`, `setnamecallmethod`,
`newcclosure`, `newlclosure`, `iscclosure`, `islclosure`, `loadstring`,
`httpget` / `httpgetasync`, `setclipboard` / `toclipboard`, `mouse1click`, and
the identity probes `is_rainer` / `is_rainer_function` / `is_rainer_closure`.
Raindrop additionally had a small custom library (`Raindrop:AddCommand`,
`Raindrop:MessageBox`, `Raindrop:DownloadString`).

All superseded. Translate to sUNC names when modernising a script, and only
bring these up if the user posts code that uses them.

`identifyexecutor()` returns the executor name and version where supported —
useful for diagnostics, and worth logging in a hub so bug reports are actionable.

---

## How to answer "which executor should I use"

Do not rank them. The honest answer has three parts:

1. Which **functions** the script needs — that is the real requirement.
2. That support and stability change with every Roblox release, so any ranking
   is stale quickly.
3. Where to check live status, and that vendor-quoted compatibility figures are
   self-reported.

Writing portable, feature-detected scripts makes the question mostly moot, which
is a better outcome than answering it.
