---
name: roblox-script-feedback
description: When a script needs notifications, status, saved configs and keybinds, and when it does not. Use when adding toggles or settings.
---

# Feedback and saved preferences

Use when choosing whether a script needs notifications, progress, settings or
saved configurations. These are decisions about what the user needs to know
and repeat. A one-button tool does not automatically need a notification
framework, a settings tab or disk storage.

## Put feedback where it answers the action

| Situation | Smallest useful feedback |
|---|---|
| Toggle changes a visible setting | Its selected state and value; no duplicate success toast |
| Slider changes continuously | Live value beside the slider; no toast per step |
| An action takes time | Pending state at its trigger, then the actual result |
| Background work finishes away from the current view | One concise notification if the result matters |
| Repeated progress such as items counted | An updating count; a summary at completion when useful |
| Invalid input | The field's explanation, preserving what the user typed |
| Unsupported feature or missing capability | A persistent reason beside the disabled action |
| Config save fails | Persistent unsaved state and a usable retry; a toast alone is insufficient |
| A decision is required before continuing | A focused choice with meaningful labels |

Do not report success merely because a callback ran, a remote fired or a task
started. Name the evidence of completion: a returned local result, a confirmed
state change or a source-established acknowledgement. If the outcome is
unknown, report that status rather than "Done". Do not invent a server
acknowledgement that the supplied source does not contain.

An unavailable optional capability disables that operation with a reason.
A missing capability essential to the script fails clearly before mutation;
do not leave a live-looking toggle or silently substitute a different feature.

## Notifications that earn an interruption

When a toast is warranted, use the chosen tested style in
`../roblox-ui-components/references/style-recipes.md` and the lifetime rules in
`../roblox-ui-components/references/toasts.md`. A style choice does not require
a toast for every action.

- Emit on a meaningful transition, not each frame or each retry. Collapse
  repeated causes and cap both the visible stack and queued work.
- A message describes the result in the game's terms: "Route finished" or
  "Couldn't save settings". Delete welcome banners, success narration and
  adjectives such as "advanced", "intelligent" or "ultimate".
- Keep unresolved errors reachable in the relevant control or status area.
  Automatic dismissal must not erase the only recovery action.
- Do not steal focus for a background notice. Respect insets, phone controls,
  text growth and the readable hold time after arrival.
- Cancel pending notices when their owning script unloads. An old completion
  must not announce success for a newly started run with the same name.

## Add configuration only for repeatable choices

Reuse the project's configuration system. Add persistence when the user asks
for it or repeatedly chosen preferences would otherwise need tedious setup.
For a small tool, in-memory state across close/reopen can be enough. Describe
which lifetime is supported; `getgenv()` alone does not save across sessions.

Separate three things before deciding what to save:

| Kind | Examples | Default treatment |
|---|---|---|
| Preferences | Theme, overlay range, chosen route, keybind | Persist if useful and supported |
| Active operations | Farming currently running, a held key, a pending action | Keep runtime state; restart only under an explicit restore policy |
| Runtime references | Current target Instance, connections, closures, temporary identifiers | Never serialize |

Each saved field needs a stable key, accepted type/range, default and restore
behavior. Do not build a schema framework for two values. When files can
outlive releases, a small version field and a known migration are clearer
than guessing what stale values mean. Scope game-specific choices to the
proven game/place scope, and ignore unknown fields rather than executing them.

A hub built on HubKit already has named configs (`library/hub-kit/src/Core/Config.luau`).
A script without a hub library uses the tested
[assets/settings-file.luau](assets/settings-file.luau): one JSON file, each
stored value accepted only if it matches its default's type, an unreadable
file copied aside before anything overwrites it, `save()` returning whether
the write succeeded, and `persistent` false when the executor has no file
functions, so the window can say once that settings last for this session.

Loading preferences and applying an active feature are distinct decisions.
Preserve the library's documented setter/callback contract. In HubKit, `Set`
runs the callback; do not silently change it to restore a visual-only toggle.
Keep operations that must not auto-start out of saved flags, or use an
explicit start action. A toggle shown on must reflect a running feature;
failed restoration must leave an accurate state with a reason.

If the user requests auto-start, load validated preferences after controls and
dependencies exist, then start each selected feature once in dependency order.
Handle unavailable dependencies visibly. Reapplying a config must not create
duplicate connections or loops, and unload must still stop the restored work.

Filesystem and decode calls are boundaries: detect the exact capabilities
used and check failure results. Missing storage may leave usable session-only
controls, clearly marked as unsaved. Preserve a malformed config for recovery;
do not overwrite it with defaults merely because loading failed. Debounce
autosave or save at a meaningful commit point, not every slider movement.
Only show "Saved" after the write reports success; that is not proof against
later external file changes or storage failure.

## Verify the decisions that can fail

Exercise the actual implementation with rapid repeated actions, a failed
operation, a delayed completion after unload and a burst of duplicate notices.
For disk configs, include missing file, malformed data, rejected field values,
missing/write-failing capability, reapply and a config from another game scope.
Check state, visible feedback and callback counts. Use the relevant subset;
no disk-config tests are needed for a tool with no disk persistence.

Report what was actually run. A mocked write failure tests recovery logic;
it does not establish compatibility with the user's executor filesystem.

## Works with

- `roblox-ui-components`: notification recipes and control states.
- `roblox-ui-tooltips`: short explanations where the action happens.
- `roblox-hub-library`: existing flag, callback and config contracts.
- `roblox-executor-reliability`: rerun, ownership and unload of restored features.
- `roblox-code-craft`: concise names, errors and comments.
- `roblox-ui-ux-review`: evidence for feedback and recovery recommendations.
- `roblox-executor-quality`: the premium bar's checks 8 and 9, which these rules decide.
