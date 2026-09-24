# Auto-update from GitHub

Edit files in this folder and the plugin in Codex and the ChatGPT desktop app
follows, through the public repository
[x-Yami-Sukehiro-x/roblox-luau-expert-skill](https://github.com/x-Yami-Sukehiro-x/roblox-luau-expert-skill).
Nothing has to be rebuilt or reinstalled by hand.

## The chain

1. **You edit.** Here, by hand or through a Claude session. Committing is not
   required.
2. **Publish.** A scheduled task runs `tools/bin/auto-update.mjs` every 20
   minutes and at sign-in. It calls `tools/bin/publish-github.mjs`, which
   snapshots the working tree the way `git add -A` would and pushes it to
   GitHub's `main` as one commit authored by the account's noreply address. The
   local history and its commit identities never leave this PC.
3. **Build.** `.github/workflows/plugin.yml` runs every gate in
   `tools/bin/check-all.mjs`. Only if all of them pass does it run
   `tools/bin/build-plugin-branch.mjs` and commit the result to the `plugin`
   branch. A failing gate changes nothing downstream, and GitHub emails the
   account the failure.
4. **Install.** The same task then runs `tools/bin/sync-plugin.mjs`: it refreshes
   Codex's copy of the `plugin` branch and reinstalls the plugin when the build
   differs. Every build's version carries its source commit, for example
   `5.2.0+g3f9c2e1`, so the Plugins page shows which one is installed. Chats
   started after the reinstall read the new files; restart the desktop app if an
   open chat still shows the old behaviour.
5. **The GPT** reads the same branch live through an Action, below.

Worst case from an edit to an installed plugin is about 35 minutes: up to 20 for
the next pass, a few for the workflow, then the wait inside the same pass. To
skip the wait:

```bash
node tools/bin/auto-update.mjs
```

Every pass appends one line to `auto-update.log` inside the `.git` folder. That
line says what was pushed, whether the build arrived and which version is
installed, or which step failed.

## What stops a publish

- **GitHub's `main` moved somewhere else**, such as an edit on github.com. The
  publisher refuses to overwrite it. Bring that change into this folder, then
  run `node tools/bin/publish-github.mjs --adopt` once.
- **Something that looks like a credential**, or the local git email address,
  anywhere in the tree. The message names the file.
- **Machine-local files** are never published: this checkout's Claude
  permission file, settings.local.json, and everything `.gitignore` excludes,
  including `dist/`.

## Setup on this PC

Done once, on 2026-09-23:

```bash
node tools/bin/publish-github.mjs
node tools/bin/sync-plugin.mjs
powershell -ExecutionPolicy Bypass -File tools/bin/install-auto-update.ps1
```

The first push asks Git Credential Manager to sign in as `x-Yami-Sukehiro-x`
through the browser; it remembers that sign-in afterwards. `sync-plugin.mjs`
adds the marketplace `roblox-luau-expert-github` and installs
`roblox-luau-expert` from it. It finds the Codex CLI inside the Codex desktop
app's folder under your local app data, or wherever `CODEX_BIN` points.

To stop the automatic passes:

```bash
powershell -ExecutionPolicy Bypass -File tools/bin/install-auto-update.ps1 -Remove
```

## Another PC

Without this folder, add the branch as a marketplace and install from it:

```bash
codex plugin marketplace add x-Yami-Sukehiro-x/roblox-luau-expert-skill --ref plugin
```

```bash
codex plugin add roblox-luau-expert@roblox-luau-expert-github
```

`codex plugin marketplace upgrade roblox-luau-expert-github` followed by the same
`plugin add` brings it up to date; nothing there runs that for you.

Codex clones the whole repository before switching to the branch. If the add
fails with `Filename too long`, the Codex folder sits deep enough to cross
Windows' 260-character path limit; `git config --global core.longpaths true`
lifts it.

## The GPT

A custom GPT cannot have its knowledge files replaced by anything but the
editor, so the knowledge files stay a snapshot. An Action makes the current
files readable anyway, whole rather than as retrieval fragments. It was added
to the Roblox Scripting GPT on 2026-09-23 by importing the schema's raw GitHub
URL; to add it again:

1. **My GPTs**, open the GPT, **Edit**, **Configure**, **Create new action**.
2. **Authentication**: None. The repository is public.
3. **Schema**: paste all of `docs/portability/gpt-github-action.json`.
4. **Update**.

The Action has two operations: `listSkillFiles` returns every file's flat name,
and `getSkillFile` returns one file in full. A slash cannot pass through the
path parameter, so the roblox-ui skill's SKILL.md is published as
skills__roblox-ui__SKILL.md. Three files over the Action's response limit are
listed under `tooLargeForAnAction` in the index; they stay in the knowledge
files.

## Claude Code

Claude Code is installed from this folder, so it already sees every edit. To
install it from GitHub instead, run `/plugin marketplace add
x-Yami-Sukehiro-x/roblox-luau-expert-skill` in an interactive `claude` session
and turn on auto-update for that marketplace under **Marketplaces** in
`/plugin`; third-party marketplaces start with it off. Claude Code then updates
only when the `version` in `.claude-plugin/plugin.json` changes, not on every
push.
