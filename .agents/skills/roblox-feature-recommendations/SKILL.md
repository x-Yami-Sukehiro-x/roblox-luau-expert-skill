---
name: roblox-feature-recommendations
description: Suggesting features a decompiled dump makes possible, ranked by evidence and payoff. Use for what can I make for this game.
---

# Suggest what this game can actually support

Use for "what features can you make from this dump?", "suggest OP features", or
"what should I add?" when the supplied source is the basis for the answer. For
reviewing an existing script's defects, use `roblox-improve`; for building a
selected feature, use `roblox-decompiled-features`.

Do not generate a genre-based list and search afterward for words to justify it.
Start with the source's actual data, controls and behavior.

## Build a capability inventory

```powershell
python tools/py/dump_index.py <dump> --inventory
```

Read the relevant implementations and callers. For each useful capability,
record a file/line, what is visible to the client, its actual reader or action,
what resets it, and what the source cannot establish. Include failed regions,
missing modules and stale-version uncertainty. Tool scores rank search hits;
they are not feasibility or confidence scores.

The inventory lists call sites, interactions, numbers, tags and engine
features. Beyond it, some code shapes signal a feature: a client cooldown
before a request, a module table of numbers, a client hit check, an attribute
the client reads on world objects, a UI gate. [source-signals.md](references/source-signals.md)
maps each shape to what it suggests and what to read next, lists genre words
to search for (as searches, never as suggestions), and shows which
combinations of proven facts make the strongest features.

Look for combinations that reduce effort or reveal useful information: an
objective identifier with replicated positions, a cooldown read with an existing
HUD, an inventory view with local sort/filter logic, or an established action
with a completion event. Read [ranking-examples.md](references/ranking-examples.md)
for examples of combining evidence without inventing authority.

## Give each idea a real implementation boundary

For each candidate, establish:

- **Player benefit:** a concrete action becomes easier, faster to understand or
  less repetitive. "Advanced utility" and "premium optimization" say nothing.
- **Evidence:** the exact source locations that establish its data and mechanism.
- **Authority:** local presentation, conditional local simulation, an existing
  request path, or an outcome requiring server acceptance.
- **Cost and fragility:** missing identity facts, changing instances, shared
  writers, streaming, per-frame work and dependence on unstable implementation.
- **Verification:** the observable result that would distinguish success from a
  cosmetic label or a request being sent.

Then choose one readiness:

| Readiness | Meaning |
|---|---|
| **Buildable from this source** | Every required client-side fact is established; runtime compatibility and stated checks still need verification |
| **Needs one observation** | Name the specific missing fact and the probe that would resolve it |
| **Unsupported by this source** | A needed mechanism or server outcome is absent or contradicted; do not present this as ready to build |

Prefer high benefit with strong evidence and few fragile dependencies. Do not
assign numerical confidence percentages without measured data. A feature can
have a supported local part and an unsupported server claim; split those parts
instead of rating the entire idea "possible".

## Recommend a useful shortlist

Usually three to five ideas are enough; use fewer when the source supports
fewer. Give each idea a plain name, benefit, evidence, boundary and next check.
Separate ideas requiring a probe from the buildable list. Explain the best
starting choice in one sentence and identify any shared dependencies or
conflicting writers before suggesting a bundle.

"OP" changes the ambition of the benefit, not the standard of evidence. Do not
rename an unlimited client counter as infinite money, a predicted hit as accepted
damage, or a reduced local timer as a server cooldown bypass. A useful tracker,
route aid or reliable action queue may be a stronger recommendation than a
dramatic feature the supplied code cannot support.

Keep user-facing descriptions about behavior. Put API names and evidence in the
technical note, not a control subtitle. Avoid invented quality labels, generic
descriptions, stacks of synonyms or an assertion that the feature is "undetected".

If the user requested only suggestions, deliver the ranked findings without
rewriting their script. If they also authorized implementation, proceed with
the supported selected scope; do not stop for an approval the user already gave.

## Works with

- `roblox-decompiled-features`: contracts and live identity behind each suggestion.
- `roblox-executor-planning`: choosing the first useful mechanism to implement.
- `roblox-runtime-probes`: one observation for a conditional recommendation; the tested remote spy and table finder.
- `roblox-improve`: defect fixes and feature additions ranked separately.
- `roblox-code-craft`: precise names and descriptions without inflated claims.
- `roblox-executor-reliability`: cost of writers, lifecycle and feature composition.
