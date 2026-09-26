# Surviving a game update

A game update renames a remote, moves a module, changes a constant or
rewrites the function a feature patched. No script survives every update.
A good one fails in a way the player can report in one sentence, and never
does the wrong thing quietly.

## Resolve every target once, at start

Each feature's `start` looks up everything it will touch before it changes
anything, and asserts what it found:

```lua
-- lint: fragment
local function resolveCollect()
	local remote = ReplicatedStorage.Remotes:FindFirstChild("Collect")
	assert(remote and remote:IsA("RemoteEvent"), "Remotes.Collect is missing")
	return remote
end
```

The assertion's message is what the player will see in the toggle's status
through the feature registry, so it names the missing thing in the game's
words. A lookup scattered through a loop fails on the hundredth iteration
with `attempt to index nil`, which tells nobody anything.

## Find by what the source proved, not by position

| Target | Stable across updates | Breaks on the next update |
|---|---|---|
| A remote | Its name and class from the call site | `Remotes:GetChildren()[3]` |
| A module's table | `filtergc` with the keys the source showed | The fourth table from `getgc` |
| A closure | A constant unique to it in the source, with a unique-match assert | Its index in a `getgc` walk |
| An upvalue | The index matched by the value the source says it holds | A decompiler label such as `u3` |
| A constant | The value read, captured, restored | A retyped literal |

Two matches are an ambiguity, not a tie to break by picking the first.
Assert that exactly one matched and report the count when it is not:
`2 functions hold "SprintSpeed"; expected 1`.

## Notice that the script changed

When the dump was taken, `getscripthash(script)` gives a hash for each script
a feature was built from. Record it next to the feature:

```lua
-- lint: fragment
local BUILT_FROM = {
	["Sprint"] = { path = "PlayerScripts.SprintController", hash = "9f2c41..." },
}
```

At start, compare the live hash. A different hash does not prove the feature
is broken; it proves the evidence is older than the game. Mark the feature
`unverified` in its description and keep it off by default, rather than
refusing to run or trusting it. A missing `getscripthash` is reported once;
it is not a reason to skip the comparison silently.

Only compare against a hash actually recorded when the source was read.
Without one, say the source's freshness is unknown.

## When an update breaks a feature

1. The toggle already says what is missing (the resolve step's message).
2. Ask for a fresh dump of the scripts that feature was built from, or send
   a probe for the one fact that changed (`roblox-runtime-probes`).
3. Record the break in the attempt ledger with the old and new names, so the
   next fix starts from the difference, not from scratch.
4. Fix the lookup, not the feature: if the remote was renamed, the feature's
   logic is usually still right.
