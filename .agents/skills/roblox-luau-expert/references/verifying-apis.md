# Verifying names before writing them

The full procedure behind the router's Rule 1. Roblox has about 925 classes
and 8,400 members, renames things, and gates many behind security levels, so
recall is not enough.

## Roblox APIs

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

## Executor functions

Executor functions are a **separate** ground truth and a separate command:

```powershell
node tools/bin/verify-executor-api.mjs <name>     # sUNC reference; exit 1 if absent
```

Same contract, different source. `verify-api.mjs` correctly reports every
executor function as missing, because the API dump does not contain them — that
is not the signal, and using the wrong tool is how a real function gets called
imaginary.
