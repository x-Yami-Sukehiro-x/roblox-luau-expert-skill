# Portability — one stack, four hosts

The skills in `.claude/skills/` are the stack. Three other hosts need the same
rules in their own format, and four hand-maintained copies drift within a month.
So they are generated.

```
docs/portability/rules.md          the single source - edit this
        |
        +-- AGENTS.md                              Codex
        +-- .agents/skills/                        Codex skill mirror
        +-- .cursor/rules/roblox-luau-expert.mdc   Cursor
        +-- docs/portability/gpt/                  everything a custom GPT needs
              instructions.md                      the 8,000-character field
              knowledge/gpt-knowledge.md           P1 and P2
              knowledge/ui-pack.md                 UIs/ flattened, uploadable
              knowledge/workflow-pack.md           task/UI/executor workflows
              knowledge/*.zip                      the whole repository
              package-manifest.json                source and archive hashes
```

The GPT half has its own folder because it is the one host where you paste and
upload by hand, months apart, and have to know which files. See
[gpt/README.md](gpt/README.md).

```bash
node tools/bin/build-portable.mjs            # regenerate all four
node tools/bin/build-portable.mjs --check    # exit 1 if any is stale
node tools/bin/build-portable.mjs --check-archive # require the upload ZIP too
node tools/bin/build-portable.mjs --list     # sizes, without writing
```

**Never edit a generated file.** Each carries a banner saying so, and `--check`
will fail the moment one diverges from the source.

---

## Tiers

`rules.md` tags every section `[P0]`, `[P1]` or `[P2]`. They are **cumulative
and non-overlapping** — a P1 section continues its P0 counterpart rather than
repeating it.

| Tier | Reaches | Why |
|---|---|---|
| P0 | everything, including the GPT instructions field | That field caps at 8,000 characters. P0 is what has to work as the only thing a weak model reads |

**The deciding question for P0, now that the field is full:** does a model get
this wrong without it? Server authority is in every Roblox tutorial written and
a model arrives already believing it, so in v5 the full runtime rules moved to
P1 and P0 kept a five-line summary. The comment budget, the UI order and the
one-API-per-job rule are not common knowledge, and they stayed.
| P1 | GPT knowledge, Codex, Cursor | The detail behind P0 |
| P2 | GPT knowledge, Codex, Cursor | Area-specific depth |

The build **fails** if P0 renders past the cap, which is the mechanism that
stops the spine quietly bloating until the GPT silently truncates it.

---

## Claude Code

Nothing to generate — the skills are native.

```
/plugin marketplace add x-Yami-Sukehiro-x/roblox-luau-expert-skill
/plugin install roblox-luau-expert@roblox-luau-expert-marketplace
```

Or `.\install.ps1` to copy into `~/.claude/skills/`, or just work inside this
repository, where `.claude/skills/` loads automatically.

---

## Codex

Codex reads `AGENTS.md` from the repository root.

1. Run the build. `AGENTS.md` is written at the root of this repo.
2. For **another** project, copy `AGENTS.md` into that project's root.
3. If the project already has an `AGENTS.md`, paste this one's contents under a
   `# Roblox Luau Expert` heading rather than overwriting — Codex reads the
   whole file.

The generated `.agents/skills/` mirror exposes the same specialist files to
Codex discovery. For global use, install the full support bundle so the verifier
can resolve its API dump, generated indexes and executor references. Copying
only a rule file leaves dead tool paths; do not remove verification to hide it.

---

## Cursor

Cursor reads `.cursor/rules/*.mdc`, with YAML frontmatter deciding when a rule
applies.

1. Run the build. `.cursor/rules/roblox-luau-expert.mdc` is written.
2. For another project, copy that one file into its `.cursor/rules/`.

The generated frontmatter sets:

```yaml
globs: ["**/*.luau", "**/*.lua", "**/*.project.json", "**/*.rbxmx", "**/wally.toml", "**/.luaurc"]
alwaysApply: false
```

So it attaches when a Luau or Rojo file is in context, rather than on every
request. Set `alwaysApply: true` in the copy if the whole repository is Roblox
and you want it unconditional — but edit the copy, not the generated original,
or the next build overwrites it.

---

## An OpenAI plugin

Custom GPTs retire on 11 December 2026. [`openai-plugin.md`](openai-plugin.md)
covers the built-in migration and the full plugin built by
`node tools/bin/build-openai-plugin.mjs`, which carries all twenty-seven skills.

## A custom GPT

Everything is in [`gpt/`](gpt/), which has its own README with the click order,
the current GPT id, and the reason the instructions are the size they are.

1. **Instructions** — paste `gpt/instructions.md` whole. The build keeps it under
   the 8,000-character cap, with the current size printed by `--list`.
2. **Knowledge** — upload everything in `gpt/knowledge/` plus `gpt/package-manifest.json`. The instructions tell
   the GPT to consult it when a task needs more depth than the spine carries.

Recommended GPT settings:

- **Capabilities**: leave Code Interpreter on. It is what lets the GPT unzip the
  archive in `gpt/knowledge/` and read individual skill files. Web Search on is
  useful for checking whether a library is still maintained.
- **Conversation starters**: four suggestions in [gpt/README.md](gpt/README.md).

Re-upload the knowledge files after every rebuild, **removing the previous ones
first** — ChatGPT adds uploads rather than replacing them by name. The GPT does
not track this repository.

On refusals to client-side scripting questions, see
[`scope-and-framing.md`](scope-and-framing.md). The short version: say which
machine, whose account, and what technically happens. That is both the honest
framing and the one that produces the better answer.

---

## Keeping them current

Add this to whatever runs before a commit:

```bash
node tools/bin/build-portable.mjs --check
```

It is the only thing standing between one source of truth and four slowly
diverging copies of it.
