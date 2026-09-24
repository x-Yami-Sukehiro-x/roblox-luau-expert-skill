# Working from decompiled source

When the user supplies source, derive the implementation from the relevant call
sites and readers. A decompile is reconstructed evidence; its completeness,
version and live runtime correspondence still need checking.

**Source the user provides outranks every template in this stack.** The rule in
the skill root — "templates are illustrative, never answers" — lets this file take over
when real source arrives. A generic aimbot skeleton written next to a paste of
the game's actual combat module is a worse answer than no answer, because it
looks researched and is not.

Related: `../recon/saveinstance-decompile.md` covers obtaining a dump. This file
covers reading one and writing against it.

---

## Order of work

0. **Search** the whole dump for the requested feature and reach a verdict:
   FOUND builds, PARTIAL or NOT FOUND sends the runtime probe instead of
   guessed names. → `feature-search.md`
1. **Read** before writing a line. → the extraction pass below.
2. **Map** each symbol in the dead source onto a live runtime object.
3. **Resolve** unknown arguments, ambiguous candidates and stale evidence before
   mutating or making a remote call. Continue independent work while a gap remains.
4. **Write** against the real names, argument shapes and confirmed value layer.
5. **Feature-detect** every executor function and plan unload before applying changes.
6. **State what was checked** and what the source or runtime did not establish.

Skipping step 1 is what produces a script that calls `FireServer` on a remote
that takes three arguments with one.

### Ambiguity is a stop condition for mutation

Resolve closure identity and value identity separately. A constant shared by
two closures does not select either. Two numeric slots with the same value do
not identify which one is the cooldown. A decompiler label such as `u3` cannot
break either tie, even when a candidate happens to have that value in slot 3.
An adjacent table carrying the expected item ID may identify the item, but
does not prove the numeric field's role. Do not turn a plausible match into
"source-established" identity by writing a filter that happens to select it.

If the reader, owner or observed call relationship is missing, give the bounded
read-only inspection needed to establish it and withhold the mutation. In
`os.clock() - u2 < u3`, the label `u2` does not prove that runtime slot 2 is the
timestamp; a table in slot 2 is not evidence supporting that arithmetic mapping.
Record unresolved candidates explicitly. An assert after an invented selection
predicate does not repair the unsupported assumption.

---

## What decompiler output actually is

A reconstruction from bytecode, not the original file. Knowing which parts
survived and which were rebuilt decides what you can trust.

### Strong evidence when visible and consistently reconstructed

| Thing | Why it survives |
|---|---|
| **String constants** | Stored in the constant table verbatim |
| **Number constants** | Same |
| **Global names** | Looked up by name at runtime |
| **Instance names in `WaitForChild("X")`** | They are string constants |
| **Method names** | `:FireServer` is a constant in the namecall |
| **Table key names** | String keys are constants |
| **Fixed arguments at a call site** | Visible operands establish order; final calls and varargs may expand |

These are what you build on. A remote name, an attribute key, a config field, an
error message. Follow computed strings and alias assignments instead of guessing
their resolved values. An incomplete region can also obscure how a constant is used.

### Rebuilt — read for shape, not for detail

| Thing | What happens |
|---|---|
| **Local names** | Gone. Become `v1`, `v2`, `var_3` |
| **Upvalue names** | Gone. Become `u1`, `u2` |
| **Parameter names** | Gone. Become `p1`, `p2`, `arg1` |
| **Comments** | Gone entirely |
| **Loop form** | `for`, `while` and `repeat` compile similarly; the decompiler picks one |
| **`if/elseif` chains** | May come back as nested `if`s, or with inverted conditions |
| **`and`/`or` shortcuts** | Often expand into explicit branches |
| **Default arguments** | Appear as `if p1 == nil then p1 = x end` |

Use intact call sites to cross-check reconstructed control flow. Neither the
spelling nor the structure is guaranteed when the decompiler reports a failure.

### Lies outright — verify before relying on it

- **Constant folding.** `60 * 60` was compiled to `3600`; you cannot tell which
  the author wrote. A "3600" you see may be one hour or may be two constants.
- **Inlined functions.** A small helper called once may have been inlined and
  will not appear as a function at all.
- **Dead branches removed.** A `if false then` block is gone. Its absence is not
  evidence it never existed.
- **Operator precedence in the output.** Some decompilers emit parentheses
  wrongly on reconstructed expressions. Read the intent, and test the arithmetic
  rather than trusting the transcription.
- **Vararg handling.** `...` forwarding is frequently mangled. If a function
  looks like it takes no arguments and is called with three, believe the call
  site.
- **Multiple returns.** `return f()` versus `return (f())` is a real semantic
  difference that decompilers routinely get wrong.

### The output failed here

Fragments like `-- DECOMPILER ERROR`, `--[[ unhandled op ]]`, a function body
that is a single `error()`, or a sudden run of `L_12_` gibberish mean that region
did not decompile. **Do not guess what was there.** Say that section is
unrecovered in this output. Constants can guide further inspection but cannot
reconstruct the missing control flow or payload by themselves:

```lua
for _, constant in debug.getconstants(someFunction) do
    if typeof(constant) == "string" then
        print(constant)
    end
end
```

---

## The extraction pass

Read the source once, recording the rows relevant to the requested feature.
For each claim retain `file:line` or the smallest exact excerpt, plus **observed**,
**inferred** or **unknown**. A missing row stays unknown; filling a table is not a
reason to invent a value. This is working evidence, not a comment header in code.

| # | Extract | Where to look |
|---|---|---|
| 1 | **Every remote, with its exact name** | `ReplicatedStorage` children; `WaitForChild` string constants |
| 2 | **Call form per remote** — `FireServer` or `InvokeServer` | The namecall at each call site |
| 3 | **Argument count and order per remote** | Every relevant call site, including nil holes, varargs and final-call expansion |
| 4 | **Argument types** | How each argument is built just above the call |
| 5 | **Client-side validation before the call** | The `if` guarding it; server checks remain unknown without server evidence |
| 6 | **Config and stat tables** | `ModuleScript`s with large literal tables |
| 7 | **The value layer** — property, attribute, upvalue or module field | Where the number is stored, not where it is read |
| 8 | **What resets it, and how often** | Loops on `Heartbeat`, `RenderStepped`, or a remote handler |
| 9 | **Any client-side anti-cheat** | Loops reading `WalkSpeed`, position deltas, or `getfenv` |
| 10 | **Attribute and tag keys** | `GetAttribute`, `SetAttribute`, `CollectionService` calls |
| 11 | **What is absent or stale** | Missing modules, failed regions, snapshot scope and recorded hashes |
| 12 | **Callable contract** | Dot versus colon, explicit receiver, argument construction, returns and yields |
| 13 | **Lifetime and restoration** | Respawn/replacement paths, captured originals, hook ownership and unload |

Row 11 is the one that gets skipped and it is the most valuable. **The dump is
the client's view.** `ServerScriptService` and `ServerStorage` never replicate.
Absence in a partial dump does **not** establish where a calculation runs: it may
be in a missing module, inactive closure, another VM or failed region. Say
"not established by this dump". When server ownership is established, changing a
client copy does not change the server's result — `client-feasibility.md`.

If a requested remote argument, callable receiver or mutation target is unknown,
do not ship guessed executable code for that part. Name the missing definition or
provide a bounded read-only diagnostic — for a feature the dump does not contain,
that diagnostic is `../../assets/runtime-probe.luau` (`feature-search.md`). Neither a UI button nor a plausible
placeholder completes an unimplemented feature.

---

## Reading argument shape from the call site

The call site is authoritative; the handler may be server-side and absent.

```lua
-- decompiled, names lost
local v14 = game:GetService("ReplicatedStorage"):WaitForChild("Net"):WaitForChild("Combat")
local v15 = workspace:Raycast(v12.Position, v13 * 300, v11)
if v15 and v15.Instance and v15.Instance.Parent:FindFirstChild("Humanoid") then
    v14:FireServer(v15.Instance.Parent, v15.Position, v9)
end
```

What that visible call site establishes:

- The remote is `ReplicatedStorage.Net.Combat`, and those are exact strings.
- The client calls `FireServer`, not `InvokeServer`; confirm the live class if needed.
- It passes **three** explicit arguments: a parent Instance, a `Vector3`, and `v9`.
- Argument one is the hit instance's **parent**, checked for a child named
  `Humanoid`; the snippet alone does not prove a player character or Model class.
- Argument two is the **hit position** from the raycast.
- The client guard requires that child. The server's acceptance checks are absent.
- The ray direction is `v13 * 300`. Its length is 300 studs only if `v13` is a
  unit direction; its magnitude is not shown here.

Trace `v9` and `v13` to their assignments. Until then argument three's type and
meaning, and the ray's maximum range, remain unknown.

---

## Mapping dead source onto live objects

The source tells you what exists. These get you a handle on the running copy.

### The script's own environment

```lua
local target = game:GetService("Players").LocalPlayer.PlayerScripts:FindFirstChild("CombatClient")
if target and typeof(getsenv) == "function" then
    local env = getsenv(target)
    for key, value in env do
        print(key, typeof(value))
    end
end
```

`getsenv` gives you the globals of a running `LocalScript`, which is where a
module-level table lives if it was declared without `local`. Most are declared
`local`, so this often comes back sparse — that is expected, not a failure.

### Find a function by what the source showed you

Search by **constant**, never by index. Constants come straight from the source
you just read and survive a game update far better than an offset.

```lua
if typeof(filtergc) ~= "function" then
    warn("this executor lacks filtergc")
    return
end

-- The source showed a function containing the string "NotEnoughAmmo".
local candidates = filtergc("function", {
    Constants = { "NotEnoughAmmo" },
}, false)
assert(#candidates == 1, "ammo closure missing or ambiguous")
local fn = candidates[1]
```

### Read its upvalues, match them to the source

```lua
if fn and islclosure(fn) then
    for index, value in debug.getupvalues(fn) do
        print(index, typeof(value), value)
    end
end
```

Compare runtime values and references against the source's usage. Decompiler
labels such as `u3` are not a promise that runtime slot 3 has that meaning.
Compiler optimization and reconstruction can change what is exposed. Identify the
closure first, then the intended slot by its role and value. Two matching numbers
are ambiguous, even if both equal the value you expected.

Locate a unique candidate before writing by index:

```lua
local cooldownIndex, originalCooldown
for index, value in debug.getupvalues(fn) do
    if value == 0.35 then
        assert(cooldownIndex == nil, "cooldown upvalue is ambiguous")
        cooldownIndex, originalCooldown = index, value
    end
end
assert(cooldownIndex, "cooldown upvalue not found")
```

This locates a candidate only after the function and cooldown role were
established. Capture the original before writing and use it for restoration;
read-only discovery must finish before any mutation starts.

### Find a module table

```lua
local candidates = filtergc("table", {
    Keys = { "FireRate", "Damage" },       -- key names from the source
}, false)
```

Keys narrow the candidates; they do not identify one weapon or the table used by
the current reader. Match source-backed discriminators and reference relationships.
Do not pick the first table or mutate every match. A module can have separate
returns per VM and per side, and a consumer may hold a cloned table.

---

## Writing the script from the source

Five rules, all of them about matching what you read rather than what is
convenient.

**1. Use the game's exact names.** `ReplicatedStorage.Net.Combat`, not
`ReplicatedStorage.RemoteEvent`. Naming things after the source is also what
makes the script readable later, and it is the naming rule from
`roblox-code-craft` applied to somebody else's code.

**2. Match argument order and type exactly.** If the source passes
`(model, Vector3, number)`, preserve those types and positions. A reconstructed
argument still needs its definition; do not substitute a plausible value.

**3. Preserve the client-side contract you found.** Check the same prerequisites,
including state changes after a yield. Client guards are evidence of that client
path, not proof of server acceptance, validation or a successful gameplay effect.

**4. Call the game's own functions rather than reimplementing them.** If the
source has a `fireWeapon` local that builds the arguments and fires the remote,
getting the exact live closure can preserve payload construction. Establish its
receiver, arguments and state dependencies from a call site first. A constant
match alone is not evidence that calling it with invented parameters is valid.

**5. Locate the writer when a loop resets your value.** Prefer its configuration
or an existing setter when the source provides one. Disable a connection or hook
only after establishing the exact writer and all its duties; disabling an entire
movement/update callback may also stop unrelated behaviour.

---

## Traps

**The source is older than the live game.** Dumps go stale within a patch.
Before relying on it, compare hashes:

```lua
local live = getscripthash(someScript)
-- compare against the hash recorded when the dump was taken
```

A changed hash means the source is a lead, not a specification. Re-verify every
remote name and argument count against the running client.
Without a recorded baseline hash, a live hash proves no match. State that version
correspondence is unverified; never invent a dump hash.

**Obfuscated or minified modules.** Some games ship client code through a
protector. Symptoms: enormous single-line tables, string constants that are
hex-encoded or built by a decoder function, control flow flattened into a
`while true do` with a state variable. Read the decoder and isolate its pure
string transformation if possible. Do not execute an unknown uploaded loader to
discover its behaviour; it may perform side effects unrelated to the request.

**The strings are constructed, not literal.** `"Combat"` may be built by
concatenation at runtime specifically to defeat a constant search. If
`filtergc` on a name fails and the source shows the name, look for the
concatenation and search for its parts instead.

**Two scripts with the same name.** Games often have a `Main` in three places.
Use the established instance path and runtime relationships. Hashes can support
identity, but identical scripts in different locations can share a hash.

**Incomplete capture.** Streaming can omit Workspace regions; loading state,
dump settings and VM boundaries can omit other evidence. Establish which
limitation applies before asking for a targeted new capture. Walking the map does
not recover arbitrary missing modules or server-only code.

**Server-side logic read as client-side.** A `ModuleScript` in
`ReplicatedStorage` may be required by both sides. Seeing damage arithmetic
there does **not** mean the client computes it — it means both sides can. The
server's copy is the one that counts.

---

## What to tell the user

When working from source they provided, say these three things explicitly:

1. **What the source established** — the exact remote names, argument shapes and
   value layer you found. This is the part they can verify.
2. **What the source could not establish** — anything server-side, anything in a
   failed decompile region, anything whose constants are constructed.
3. **What the script assumes**, if a gap had to be bridged. An assumption stated
   is testable; an assumption hidden inside working-looking code is not.

If the dump does not contain what the request needs, say so plainly and name
what would: a dump taken from a different area, the module that is missing, or
the acknowledgement that the logic is server-side and out of reach.

Report static API/lint checks separately from a Roblox/executor runtime test.
Passing the former proves neither remote acceptance nor visual/runtime behaviour.
Run the re-execution and unload cases in `lifecycle.md` when that runtime is
available; otherwise name them as unrun.

Primary references: [sUNC filtergc](https://docs.sunc.io/Environment/filtergc/),
[Luau optimizing compiler](https://luau.org/performance/#optimizing-compiler).
