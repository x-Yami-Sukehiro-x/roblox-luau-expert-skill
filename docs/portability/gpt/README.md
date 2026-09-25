# Updating Roblox Scripting GPT

Target: the Roblox Scripting GPT editor (**My GPTs**, the GPT, **Edit**).

The authoritative rules are `../rules.md`; specialist sources live under
`.claude/skills/`. Generated instructions and knowledge must not be hand-edited.
The GPT does not track this repository or acquire new files automatically.

## Build and validate

```bash
node tools/bin/generate-tables.mjs --check
node tools/bin/build-portable.mjs
node tools/bin/build-portable.mjs --check-archive
node tools/bin/check-all.mjs
```

Use `--list` to see the current Instructions size. The build enforces the
8,000-character cap. `--check` compares generated rules, the Codex skill mirror,
source hashes and any archive present. `--check-archive` also requires the ZIP.
The package manifest records exact source and archive hashes; a clean text
check alone cannot prove that the GPT has the same files.

Node on this Windows host may need `--use-system-ca` for HTTPS through the
system trust store. Keep certificate verification enabled. Official Luau 0.739
executables are bundled for Windows/Linux x64; `LUAU_BIN` overrides the runtime.
`python tools/py/check_luau.py <file>` compiles without running user code. Missing
tools or unreachable services are incomplete checks, never passes.

## Upload set

| File | Purpose |
|---|---|
| `instructions.md` | Paste whole into Instructions; routing and essential behavior |
| `knowledge/gpt-knowledge.md` | The complete portable rules and skill index |
| `knowledge/ui-pack.md` | Existing curated UI examples, anatomy and library comparisons |
| `knowledge/workflow-pack.md` | Directly readable task, UI and executor workflows with source paths |
| `knowledge/style-pack.md` | The style picker question, everyday UI words, what each picked code builds, and every tested recipe in full |
| `knowledge/roblox-ui-style-picker.html` | The playable style picker page, handed to the user as a download when the hosted link does not open |
| `knowledge/roblox-luau-expert-skill.zip` | Full skills, references, library, API snapshot and executable checks |
| `package-manifest.json` | Upload beside the knowledge files to identify and verify the package |

The archive and manifest are deterministic for identical source bytes. Test
results and earlier ZIP files are excluded to prevent recursive packaging and
to keep one test run from invalidating the tested package.

## Editor procedure

1. Open Configure. Preserve the existing name, access level, capabilities and
   the Action.
2. Replace Instructions with the generated file. Check that it was not truncated.
3. Inspect Knowledge. Remove obsolete copies individually and verify each card
   disappears before uploading; uploads append instead of replacing by name.
   The editor has previously needed a hover to reveal a card's remove control.
4. Upload the six files under `knowledge/` plus `package-manifest.json`.
   Verify all seven cards finish processing, with no duplicate older files.
   On 23 September 2026 the live GPT held only `ui-pack.md` and
   `gpt-knowledge.md`; an interrupted update had removed the other three.
   Confirm the count after saving, not before.
5. Keep Code Interpreter & Data Analysis enabled. It unpacks the archive and
   runs `tools/py/roblox_lint.py`, `format_lint.py`, `ui_lint.py`, and
   `verify_api.py`, plus `check_luau.py` after the final edit, and
   `dump_index.py` over a decompiled dump the user uploads. Web Search supports current documentation checks.
6. Test fresh Preview conversations. Run the same practical UI request and
   source-evidence request on a lighter and a stronger available model. Record
   the visible model label; do not invent a backend model version.
7. Inspect the generated files and tool outputs. Repair demonstrated failures,
   rebuild/re-upload affected files, and rerun the affected prompts.
8. Select Update and verify the editor's saved confirmation. Keep access Only
   me unless the user requests a different audience.

The Action reads current files live from the repository's `plugin` branch, so
the GPT is not limited to the snapshot in Knowledge. It is imported from URL
(`docs/portability/gpt-github-action.json` on the public repository's `main`),
authentication None; operations `listSkillFiles` and `getSkillFile`. Setup and
limits: `../auto-update.md`. Last recorded state, 25 September 2026 (5.8.0,
skill bundles, Studio MCP, game design, mobile-ready picker): instructions 7,961
characters, SHA-256 prefix `d0208da9ccdfab39`, seven knowledge files matching
the build byte for byte, the
Action on `raw.githubusercontent.com`, access invite-only. Read back through the
gizmo API after saving.

A saved confirmation proves the editor accepted the update. Model use of the
files must be established separately in Preview, preferably by reading package
contents and running the shipped tools against the actual generated output.

## Regression prompts and evidence

Use `evals/ui-behavior.md` and `evals/executor-evidence.md`. Give the model only
the prompt and raw input, not the expected answers. Retain complete responses
and generated code outside the package; the `test-results/` folder is excluded.

Evaluate APIs, exact source contracts, working callbacks, teardown and rerun,
selection/focus separation, evidence honesty and carried context. Judge rendered
quality at 1920x1080, 1280x720, 800x600 and 390x844 in Roblox when available.
A mockup is not a Roblox render; static counters do not prove clean UX. Record
unavailable runtime/device checks explicitly.

## Retirement and the plugin

OpenAI retires custom GPTs on 11 December 2026. The replacement is the plugin
described in `../openai-plugin.md`. Keep this GPT current until the plugin is
installed and tested, because migrating makes the GPT read-only.

## Context and continued improvement

The GPT's configuration reports memory enabled, and the instructions ask it to
save confirmed picks and corrections there. Memory is the user's to review and
can be off; it does not carry previous conversations into a new one on its
own. Maintain the project context record described in the task-contract
reference, then supply it in a new conversation. Knowledge is static until explicitly updated. Preserve
confirmed user corrections with evidence and a regression case, not an invented
promise that a model will never repeat a mistake.

For each improvement: reproduce, change the owning reference, rerun existing
and new cases, regenerate all hosts, and sync the six GPT files. Do not weaken
an established acceptance case merely to make a new result pass.

Official product references: [GPTs and memory](https://help.openai.com/en/articles/8554407-gpts-in-chatgpt),
[editing and testing GPTs](https://help.openai.com/en/articles/8554397-creating-a-gpt).
