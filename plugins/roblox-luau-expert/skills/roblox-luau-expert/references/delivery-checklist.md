# Delivery checklist

The pass that runs before Roblox code leaves. Every item is here because it has
caused a real defect, not because it sounds rigorous.

Work top to bottom. Items 1–3 are the ones that produce *wrong* code; the rest
produce code that is right but hard to live with.

---

## 1. API verification

- [ ] Every Roblox class, property, method, event and enum in the answer either
      appears in `verified/api-index.txt` or was confirmed with
      `node tools/bin/verify-api.mjs <Name>`.
- [ ] Nothing in the answer appears in `verified/deprecated-apis.md`.
- [ ] Nothing in the answer is gated above the calling script's reach — check
      `verified/security-tagged-apis.md`. `RobloxScript`, `RobloxEngine`,
      `Plugin` and `LocalUser` tags are all unreachable from an ordinary
      `Script` or `LocalScript`.
- [ ] Anything called inside an `Actor` in parallel is `Safe` in
      `verified/parallel-safety.md`, or the code synchronizes first.
- [ ] Every executor-specific function is feature-detected, and verified against
      `roblox-executor/references/api/` rather than the API dump.

If a name cannot be verified, the answer says so. It does not ship with a hedge.

## 2. Failure paths

- [ ] Every `pcall` binds and branches on the first return. No `local _, x =`.
- [ ] Every yield (`task.wait`, `WaitForChild`, anything `Async`, any remote
      round-trip) is followed by re-validation: `player.Parent`, instance still
      parented, state unchanged.
- [ ] Every `WaitForChild` has a timeout and a branch for the nil case.
- [ ] Every `OnServerEvent` handler validates argument **type**, **range**,
      **ownership** and **rate** before doing work.
- [ ] No `RemoteFunction:InvokeClient` on the server.
- [ ] DataStore writes use `UpdateAsync` unless a blind overwrite is genuinely
      correct, and there is a `BindToClose`.

## 3. Lifetime

- [ ] Every `:Connect` has an owner and a teardown path — explicit
      `:Disconnect()`, or a Trove/Janitor destroyed at a known point.
- [ ] Every table keyed by `Player` or `Instance` is cleared on
      `PlayerRemoving` / destruction, or is weak-keyed.
- [ ] Every `:Destroy()` is followed by clearing the references you hold.
- [ ] No allocation inside a per-frame loop that could be hoisted —
      `GetChildren()`, table literals, string concatenation.

## 4. Correctness details that bite

- [ ] Where `false` is a legal value, test nil explicitly. In Luau, `0` and
      `""` are truthy; do not import another language's truthiness rules.
- [ ] No `table.remove` inside a forward loop over the same table.
- [ ] Direct paths are backed by source. Wait and revalidate where replication
      or character lifecycle makes presence uncertain; depth alone is no bug.
- [ ] Both-orders handling for `PlayerAdded`/`CharacterAdded` — connect the
      signal *and* handle the already-present case.
- [ ] Yielding handlers cannot commit stale state or admit unintended concurrent
      actions. `task.spawn` alone does not solve either; debounce where needed.

## 5. Craft

**Run the counter first, then review what its heuristics cannot establish:**

```powershell
node tools/bin/lint-luau-slop.mjs <file.luau>
```

Exit 1 means one of the counted rules below was broken; the output names which
line. Score is out of 22. The full budget is in
`roblox-code-craft/references/anti-slop-code.md`.

- [ ] The code matches the conventions of the file it is going into — casing,
      comment density, error style, log prefixes. This outranks every default
      below.
- [ ] Names come from the game's own vocabulary. If an identifier would fit
      unchanged in another project, it is too generic. `applyReloadPenalty`,
      not `processData`.
- [ ] Argument validation uses `error(msg, 2)` so the caller's line is blamed.
- [ ] Error and warn messages name the failing value and the subsystem.
- [ ] Comments explain why. None restate the line below.
- [ ] No comment says where the code came from. "Based on the uploaded X",
      "Source-established behavior", "This version…" go in the reply, not the
      file — the file is read by somebody who was not in the conversation.
- [ ] No header essay. Four comment lines on a script, twenty-four on a module.
- [ ] Capability checks are one bind and one `assert`, not one `if` per
      function. Two `if typeof(x) ~= "function"` statements per file, maximum.
- [ ] No `pcall` hiding deterministic coding errors. Property writes,
      arithmetic and constructors can raise; boundary recovery needs a reason.
- [ ] Error messages are one clause and twelve words. No advice, no `!`.
- [ ] A literal prefix used three times is a constant.
- [ ] No `print` announcing success.
- [ ] No unused `require`s, no unreferenced functions, no `TODO`s left behind.
- [ ] No abstraction without a second real caller.
- [ ] Working from decompiled source: no `v1`/`u2`/`p3` names survived into the
      script, and no job has two code paths —
      `roblox-executor/references/technique/source-to-api.md`.

## 6. Honesty

- [ ] Anything unverified is labelled unverified, in the answer, not silently.
- [ ] Executor advice states ban risk once, plainly, without moralising.
- [ ] Illustrative skeletons are labelled illustrative — a template that does
      not match the target game's actual layout is wrong even when it runs.
- [ ] If part of the request could not be done, that is stated explicitly along
      with what was done.

### 6a. Every claim has a command behind it

"Fixed", "redesigned", "optimised", "cleaned up", "verified", "now works" are
claims about work, not descriptions of it. Each one is cheap to check and
therefore cheap to be caught making up.

- [ ] Each claim states its evidence: command output, source inspection,
      runtime action or screenshot. Name checks that could not run. Static
      counters do not establish runtime behavior or visual quality.
- [ ] A score is quoted from a command's output, never estimated from reading.
- [ ] **A rewrite of an existing file is proved by a comparison**, not asserted:

      ```powershell
      node tools/bin/lint-luau-slop.mjs --compare before.luau after.luau
      node tools/bin/lint-roblox-ui.mjs --compare before.luau after.luau
      ```

      The first prints score, lines, comments, header, capability checks,
      `pcall`s, value layers and executor surface. The second separates
      structural rows — elements, type scale, radii, spacing, palette — from the
      score, because a one-line fix moves the score and a redesign moves the
      structure.

- [ ] `0 counted rows moved`, or `0 of them structural`, is reported as that.
      It means the measured properties were unchanged. Read the diff and test
      behavior; those counts do not cover every possible change.

---

## The five-question review pass

For reviewing someone else's Roblox code, in priority order:

1. Every `OnServerEvent` — type, range, ownership, rate?
2. Every `:Connect` — who disconnects it?
3. Every `pcall` — is the first return checked?
4. Every yield — is there a re-validation after it?
5. Every unfamiliar API — `verify-api.mjs`.

Then the two counters, which need no judgement at all:

```powershell
node tools/bin/lint-luau-slop.mjs <file.luau>
node tools/bin/lint-luau-format.mjs <file.luau>
node tools/bin/lint-roblox-ui.mjs <file.luau>     # if it draws UI
node tools/bin/verify-asset-ids.mjs <file.luau>   # if it names an asset id
```

Full defect catalog with wrong/right pairs: `common-mistakes.md`.
