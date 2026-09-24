# Maintaining this stack

Roblox ships weekly. A stack that claims to be accurate has to be re-checked, and
the whole point of the tooling is that re-checking is cheap.

---

## The routine

```bash
node tools/bin/update-dump.mjs --check       # is the vendored dump behind upstream?
node tools/bin/update-dump.mjs               # refresh, print the diff, regenerate tables
node tools/bin/lint-prose.mjs                # every API claim, against the new dump
node tools/bin/lint-luau-blocks.mjs          # every shipped example, against luau
node tools/bin/lint-ui-directions.mjs        # every stated contrast ratio, recomputed
node tools/bin/lint-links.mjs                # every file the stack points at
node tools/bin/lint-roblox-ui.mjs library/src  # the UI rubric over the shipped components
node tools/bin/verify-executor-api.mjs --audit # every accepted executor global is documented
node tools/bin/run-library-tests.mjs         # 42 assertions over library/src
node tools/bin/build-portable.mjs --check    # are AGENTS.md / Cursor / GPT files current
```

The last two are not dump-dependent, but they belong in the same pass because
they fail for the same reason: something changed in one place and not the
others. `lint-ui-directions` recomputes every contrast ratio stated in
`design-directions.md`; `build-portable --check` fails when a generated host
file has drifted from `docs/portability/rules.md`.

Or all of it at once:

```bash
node tools/bin/check-all.mjs
```

Run the linters **after** every dump refresh, not before. A Roblox release
can deprecate something the prose recommends, gate something it says is callable,
or remove a member an example uses. That is exactly the drift this stack exists
to catch, and it is invisible until the dump moves.

`update-dump` prints added / removed / newly-deprecated members between the two
versions. That diff is usually more useful than the dump itself.

---

## What the linters check

`lint-prose.mjs` walks every `.md` under `.claude/skills/` except the generated
`references/verified/`, extracts API references from backticked spans and fenced
Luau, and resolves each through the dump and the datatype reference.

| Code | Meaning | Fails the run |
|---|---|---|
| `E-MISSING` | Name absent from both ground-truth sources | yes |
| `E-DEPRECATED` | `[Deprecated]` member presented as the recommendation | yes |
| `E-SECURITY` | Security-gated member presented as callable from a normal script | yes |
| `E-WRITETIME` | `[ReadOnly]` / `[NotScriptable]` / write-gated property assigned at runtime | yes |
| `W-ALIAS` | Aliased members described as distinct events | no |
| `W-UNDATED` | A popularity or recency figure with no date in the file | no |

`lint-luau-blocks.mjs` parses every fenced Luau block with the `luau` binary and
resolves annotated types through the dump.

| Code | Meaning |
|---|---|
| `E-SYNTAX` | The block does not parse |
| `E-TYPE` | A member assigned or called on a variable whose annotation lacks it |
| `E-UNDECLARED` | An identifier used but never declared, in a block marked complete |
| `E-EXECUTOR-GLOBAL` | An executor global used outside an executor context |

### Caveat detection

Both linters scope their "did the author already flag this" check to the
**enclosing markdown section**, not a fixed line radius. A note ten lines below
under the same heading still counts.

This matters more than it sounds. A linter that reports things the author
already handled teaches you to stop reading its output, at which point it is
worse than not having one.

### Opting out

- A documentation block that is a signature listing or a partial snippet gets
  `<!-- lint: fragment -->` on the line above its fence. That is an HTML comment,
  so it is invisible in rendered markdown.
- A block that claims to be complete opts *in* to undefined-identifier checking
  with `-- lint: complete` inside it.
- A prose finding that is genuinely intentional goes in `tools/lint-allow.txt`,
  as `CODE symbol # reason`. **Every entry needs a reason**; the linter rejects
  the file if it finds one without. An unreasoned allowlist entry is not an
  allowlist, it is a hiding place.

Before adding a suppression, check the finding is really intentional. The value
of this tooling is that its errors are real, and each suppression spends a
little of that.

---

## Adding a skill

1. `.claude/skills/<name>/SKILL.md` with `name` and `description` frontmatter.
   The description decides whether the skill is ever loaded, so it must name the
   symptoms and API names a user would actually type.
2. `references/` for anything past ~250 lines. A single long SKILL.md is the
   shape four skills had in v2 and it is why their domains were thin.
3. Add a `## Load a reference when` table at the top of the SKILL.md.
4. Add a router row in `roblox-luau-expert/SKILL.md`.
5. Add a routing eval in `evals/triggers.md`.
6. Run both linters.

---

## Adding a claim about an API

Look it up first. Every time.

```bash
node tools/bin/verify-api.mjs GuiService.TopbarInset
node tools/bin/verify-api.mjs SharedTable.increment    # resolves via datatypes
node tools/bin/verify-api.mjs UIShadow --members
node tools/bin/verify-api.mjs Enum.GradientType
```

Exit code 1 means the name is in neither source. That is the signal you were
about to invent an API.

The tool reports more than existence: security level and **direction**,
capability, parallel safety, deprecation with a replacement where one is known,
whether the call yields, and whether a property can be assigned at runtime at
all. A member can exist and still be unreachable, and those are different
failures with different fixes.

**The dump covers classes and enums only.** Datatypes — `CFrame`, `TweenInfo`,
`RaycastParams`, `SharedTable` and 44 others — come from the vendored
creator-docs reference. `verify-api` says which source answered, and a claim
that cites the wrong one is the provenance bug v2 shipped.

---

## Regenerating the verified tables

```bash
node tools/bin/generate-tables.mjs           # rewrite references/verified/
node tools/bin/generate-tables.mjs --check   # prove they match the dump; exit 1 on drift
```

`references/verified/` is **derived data**. Never hand-edit it: change the dump
or the generator and re-run. `--check` in a review is how you prove the committed
tables were not edited by hand.

Seven files come out of it. Four are read by people; three exist so a tool with
no Node can answer the same questions: `enum-index.txt`, `class-hierarchy.txt`
and `gui-classes.txt` are what `tools/py/verify_api.py` and `tools/py/ui_lint.py`
read instead of parsing a megabyte of API dump in a sandbox.

---

## Changing a lint rule

Two of the linters have two implementations. **Change both, in the same commit.**

| Rule set | Node | Python |
|---|---|---|
| ceremony budget | `tools/bin/lint-luau-slop.mjs` | `tools/py/roblox_lint.py` |
| UI rubric | `tools/bin/lint-roblox-ui.mjs` + `tools/bin/lib/gui-model.mjs` | `tools/py/ui_lint.py` |

```bash
node tools/bin/lint-parity.mjs          # both pairs, every Luau file in the repo
node tools/bin/lint-parity.mjs --ui     # one pair, while iterating
```

It compares code, line and message, so a reworded finding fails until both sides
are reworded. That is deliberate: the Python side runs in the host nobody checks
by hand, and a port that quietly stopped firing would look exactly like clean
code for months.

**Add a fixture for any new rule.** `evals/fixtures/` holds files that trip
rules on purpose, and the parity gate reads that directory — a rule with no
fixture is a rule the gate never exercises.

---

## Release checklist

- [ ] `update-dump.mjs --check` reports up to date.
- [ ] `lint-prose.mjs` — zero `E-*`.
- [ ] `lint-luau-blocks.mjs` — zero findings.
- [ ] `generate-tables.mjs --check` — no drift.
- [ ] `run-library-tests.mjs` — 42 passed, 0 failed.
- [ ] `lint-parity.mjs` — 0 disagreements, both pairs.
- [ ] `lint-luau-slop.mjs` and `lint-roblox-ui.mjs` over
      `docs/portability/gpt/UIs/exemplars` — the scores printed in that folder's
      README are the ones the commands print.
- [ ] `evals/triggers.md` run in a fresh session; every row routes as stated.
- [ ] Version bumped in `.claude-plugin/plugin.json` **and** `marketplace.json`.
- [ ] `docs/CHANGELOG.md` says what changed and what was wrong before.
- [ ] Any new popularity figure in `docs/SOURCES.md` carries a date.
