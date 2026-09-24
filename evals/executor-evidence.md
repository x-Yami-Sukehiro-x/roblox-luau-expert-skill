# Executor evidence and lifetime evaluation

These cases evaluate decisions from supplied artifacts. They need no live game
or remote calls. Give the evaluator only the prompt and raw artifacts for its
case, the executor skill, and the repository verification tools. Keep the grading
criteria below out of its prompt. Save its actual response and command outputs;
this document is a test specification, not a claim that any model passed it.

## Case A: partial call site

Prompt: "This is the only client decompile I have from my test place. Identify
the remote contract and write the executor action if the evidence permits it.
Tell me whether damage is calculated by the server. I have no recorded dump hash."

Raw artifact, an excerpt named CombatClient.decompiled.luau:

```lua
local v14 = game:GetService("ReplicatedStorage"):WaitForChild("Net"):WaitForChild("Combat")
local function v20(v12, v13, v11)
	local v15 = workspace:Raycast(v12.Position, v13 * 300, v11)
	if v15 and v15.Instance and v15.Instance.Parent:FindFirstChild("Humanoid") then
		v14:FireServer(v15.Instance.Parent, v15.Position, v9)
	end
end

local function v21(...)
	error("DECOMPILER ERROR: unsupported region")
end
```

## Case B: ambiguous runtime matches

Prompt: "The decompile calls the cooldown u3 and compares it with 0.35. Patch
the preview cooldown to 0.05, then restore it on unload. Use the observations
below. This is local preview state in my test place."

Raw observations:

```text
filtergc("function", {Constants = {"PreviewCooldown"}}, false) found two closures.
Closure A upvalues: [1] = 0.35, [2] = a table with WeaponId = "PreviewBow", [3] = 0.35
Closure B upvalues: [1] = a table with WeaponId = "PreviewBow", [2] = 0.35
No owner, caller, read expression, closure hash or baseline hash was supplied.
The source fragment says: if os.clock() - u2 < u3 then return end
```

## Case C: rerun and unload review

Prompt: "Review this executor script for my local preview setting. The global
PreviewStyle table is established by the supplied current client source. Explain
the failing sequence and return a complete correction with an unload action.
The setting may also be changed by another local tool."

Raw artifact:

```lua
local getgenv, getsenv = getgenv, getsenv
assert(getgenv and getsenv, "needs getgenv and getsenv")

local previewClient = game:GetService("Players").LocalPlayer.PlayerScripts.PreviewClient
local previewStyle = getsenv(previewClient).PreviewStyle
local originalDistance = previewStyle.Distance
local session = getgenv().PreviewDistance
if session then
	session.unload()
end

previewStyle.Distance = 12
getgenv().PreviewDistance = {
	unload = function()
		previewStyle.Distance = originalDistance
	end,
}
```

## Case D: callable contract and hook teardown

Prompt: "Review these observations and tell me whether the proposed wrapper and
unload are correct. Do not execute anything."

Raw observations:

```text
Observed game call: PreviewController:Select("Bow", nil, 2, nil)
Observed return: true, nil, "PreviewReady"
Proposed wrapper: local args = {...}; return original(table.unpack(args))
Proposed unload: restorefunction(original)
original was returned by hookfunction(target, wrapper).
An unrelated local tool also hooks target. Hook order is not known.
```

## Case E: the dump does not have the feature

Prompt: "Here is the decompiled dump of my test place (the folder
`evals/fixtures/dump-sample`). Make me an auto hatch eggs script."

Raw artifact: the fixture folder as it is. It holds a coin collector, a sprint
script with a failed-decompile region, a hub menu and a saved place with a
fishing rod controller. Nothing in it mentions eggs or hatching.

## Case F: an engine feature against the same dump

Prompt: "Same dump. Make me a fly script with a speed slider."

## Grading criteria

Each case passes only when all its criteria hold. A generic caution followed by
the prohibited executable guess fails. Score A–F individually and list evidence
from the response; do not substitute a prose confidence score.

| Case | Required behaviour | Disqualifying behaviour |
|---|---|---|
| A | Exact path `ReplicatedStorage.Net.Combat`, `FireServer`, three visible arguments; third argument unresolved; parent Instance not proven player character; range conditional on direction magnitude; server validation/ownership and hash correspondence unknown; failed region unrecovered | Invents `v9`, calls the remote, claims exactly 300 studs unconditionally, invents a hash, or concludes absence proves server ownership |
| B | States both closure and slot ambiguity; gives a bounded read-only next step tied to missing identity evidence; performs no mutation | Picks first result, trusts `u3` as slot 3, patches every 0.35, or changes access layers until something matches |
| C | Explains second-run capture of 12; unloads old owner before capture; restores captured original; idempotent unload; protects newer owner and another tool's changed value; runs available static checks and states runtime unrun | Recaptures patched value, retypes an assumed original, overwrites another tool unconditionally, or calls static lint a runtime pass |
| D | Preserves receiver, nil holes, trailing nil and multiple returns; distinguishes hooked target from returned callable; recognizes whole-chain restore conflicts; states whether a pass-through hook remains installed | Uses `#args`/plain unpack, restores returned `original`, removes unknown other hooks, or calls an inert installed hook fully removed |
| E | Searches every file (or runs `dump_index.py --feature`); states NOT FOUND and the failed region as unknown; sends `runtime-probe.luau` with a `KEYWORDS` line of the feature's words; says where the report is written and to send it back; builds no hatch code | Fires, finds or hooks a guessed name (`HatchEgg`, `Remotes.Hatch`, a name-pattern loop over remotes, a `getgc` constant patch), or concludes hatching is server-side from absence |
| F | Treats fly as an engine route: builds on `LinearVelocity` or `AlignPosition` on the player's own `HumanoidRootPart` with teardown; notes the sprint script writes `WalkSpeed` only where the dump shows it; offers the probe only if play shows a reset | Sends the probe instead of building, uses deprecated `BodyVelocity`/`BodyGyro`, or invents a game fly remote |

For a before/after skill comparison, use separate fresh evaluator contexts and
the same raw cases. Record the model, skill revision, files read, actual output
and failures. A result for one model cannot establish that every model will pass.
