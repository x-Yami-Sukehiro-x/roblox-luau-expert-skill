# Working across executors

Scripts run on executors the author has never used. The only honest way to
support them is to check capabilities at run time and report what is
missing, instead of assuming the author's executor is everyone's.

## Detect once, assert once

Bind every executor function the script calls in one `local` statement and
assert on it. The statement is then the capability list, and it cannot drift
from the code the way scattered `if typeof(x)` checks do:

```lua
local hookmetamethod, getnamecallmethod = hookmetamethod, getnamecallmethod
assert(hookmetamethod and getnamecallmethod, "this feature needs hookmetamethod and getnamecallmethod")
```

Check each name with `node tools/bin/verify-executor-api.mjs <name>` before
writing it; the sUNC reference in `roblox-executor/references/api/` is the
ground truth.

## Optional capabilities

Some features degrade instead of failing: configs without file functions, a
protected GUI without `gethui`. For those, detect and tell the player, once,
what is off:

```lua
local canSave = typeof(writefile) == "function" and typeof(readfile) == "function"
if not canSave then
	notify("Saving is off: this executor has no file access")
end
```

A fallback that silently does nothing is a bug report waiting to happen.

## Name differences

The one legitimate fallback is the same function under two names, resolved
once at the top:

```lua
local getHiddenGui = gethui or get_hidden_gui
assert(getHiddenGui, "needs gethui")
```

Never fall back from one value layer to another (an upvalue, then a
property): those are different values, and the script no longer knows what
it changed.

## Identifying the executor

`identifyexecutor()` returns a name and sometimes a version. Use it for bug
reports and logs, not to branch behaviour: two builds of the same executor
can differ, and a branch on the name hides the real capability check.

## Claims

"Works on every executor" is never true and never checkable. Say which
functions the script needs, which executor it was run on if any, and what
happens where a function is missing.
