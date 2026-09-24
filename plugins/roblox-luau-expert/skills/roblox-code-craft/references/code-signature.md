# Code Signature — matching context, and the review pass

`naming.md` and `diagnostics.md` cover how to write things. This file covers two other jobs: **fitting into code that already exists**, and **checking output before handing it over**.

---

## What this file is and isn't

This is about clarity and consistency. Code that is specific, navigable, and consistent with its surroundings is easier to patch, easier for a colleague to pick up, and — as a consequence, not as a goal — does not read as machine-generated.

**This file does not manufacture inconsistency.** The detection literature correctly observes that humans are stylistically erratic: the same concept named `user_data`, `usrRecord`, and `temp_payload` in one file depending on the author's mood. Imitating that would make code harder to navigate, which is the exact opposite of the point. No deliberate imperfections, no classifier evasion. Quality is the route.

---

## The primacy rule

The clearest signal in all the detection research is not about any single convention:

> Code generated in isolation has different patterns from the code around it — different naming conventions, different error handling, different logging formats. **These stylistic discontinuities are the clearest signal of all.**

Which means one rule outranks every table in `naming.md`:

> ### Read the neighbouring code first, and match it.
>
> The existing file's conventions beat the official style guide, which beats this skill's defaults.

A correctly-styled function that looks nothing like the file around it is **worse** than a slightly-off one that blends. It is also worse for the user: mixed conventions in one file are exactly what makes a codebase hard to navigate.

The style-guide literature says the same thing directly — project-specific guides take precedence in any conflict.

---

## Procedure before writing into an existing file

1. **Read enough surrounding code to see the conventions actually in use.** Casing, comment density, error style, log prefixes, layout, how modules are required, whether types are annotated.
2. **Mirror them**, including choices the official style guide would disagree with. If the file uses `snake_case` locals, the new function uses `snake_case` locals.
3. **Reuse what exists.** Before writing a helper, check whether the project already has one. Three ways to do the same thing in one repo is a tell and a maintenance problem.
4. **Match the abstraction level.** Do not introduce a class into a file of plain functions, or a metatable pattern into a file that uses closures.
5. **If the file's convention is genuinely harmful, say so once** — in the response, not by silently diverging mid-file. Silent divergence gives the user a file with two conventions and no explanation.

For a **new** file with no neighbours: apply the defaults in `naming.md` and `diagnostics.md`.

---

## The tell catalogue

Nine signals that mark code as machine-written, each with its counter. Useful as a review checklist against my own output.

| # | Tell | Counter |
|---|---|---|
| 1 | **Obvious comments, uniformly formatted** — `-- increment the counter` above `counter += 1`, in identical style across every file | Comment the *why*; omit where the code says it |
| 2 | **Same problem solved several ways** — three HTTP approaches, two date helpers, four validation patterns in one project | Find and reuse what exists before adding |
| 3 | **Unused dependencies** — `require`s that nothing calls | Luau's `ImportUnused` (9) catches these |
| 4 | **Generic names and numeric suffixes** — `data2`, `result_final`, `handleClick2`, `newFunction` | The ubiquitous-language test in `naming.md` |
| 5 | **Tests that assert nothing** — coverage-shaped files verifying `true == true` | Assert real behaviour, or write no test |
| 6 | **`TODO` in delivered code** — `-- TODO: add real validation` in a live path | Resolve it or track it properly |
| 7 | **Giant undifferentiated commits** — 40,000-line "initial commit", then "fixes" | Scope each change to one concern |
| 8 | **Dead load-bearing code** — fully-built helpers, routes, components wired to nothing | Build what has a caller |
| 9 | **Silent error handling** — `pcall` everywhere, success value never checked | Check every success value; see `diagnostics.md` |

**Diagnostic threshold:** four or more, distributed uniformly across a project. Any one in isolation is normal — everyone leaves an unused import occasionally. It is the *uniform distribution* of several that identifies the author.

### The three the linter catches for free

`ImportUnused` (9), `LocalUnused` (7), and `FunctionUnused` (8) mechanically catch tells 3 and 8, with no judgement required. Turning on Luau's lints is the cheapest quality win available. Full table in `naming.md`.

---

## Pre-delivery pass

Run before handing over code:

- **Names** — every identifier passes the ubiquitous-language test: would it fit unchanged in another project? If yes, rename.
- **`pcall`** — every first return value is checked.
- **Errors** — argument validation uses `error(msg, 2)`; messages name the failing value; each has a stable greppable prefix.
- **Comments** — none restate the line below; the ones present explain a *why* that isn't obvious.
- **Imports** — nothing required that isn't used.
- **Dead code** — nothing defined that nothing calls.
- **`TODO`** — none.
- **Style** — matches the neighbouring file, and any deliberate divergence was stated in the response.

---

## Over-engineering

Not on the nine-tell list but closely related, and the most common way generated code goes wrong in practice: building more than was asked for.

- An abstraction with one caller is not an abstraction, it is indirection.
- A configuration option nobody requested is a branch nobody tests.
- A class where a function would do adds a lifetime to manage.
- Defensive handling for conditions that cannot occur adds paths that cannot be verified.

Build what the task needs. If a generalisation looks likely to be needed, say so rather than pre-building it.

This interacts with the register limit: speculative helpers and wrapper layers burn locals and instructions in a language that caps both per function — see `roblox-luau-language/references/compiler-limits.md`.

---

## Related references
- `naming.md` — identifiers, ubiquitous-language test, the Luau lint table
- `diagnostics.md` — errors, warnings, prints, comments, `pcall` discipline
- `roblox-architecture/SKILL.md` — layout, reuse-before-inventing, cleanup
- `roblox-luau-language/references/compiler-limits.md` — what speculative abstraction costs in Luau
