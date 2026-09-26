# Moving the GPT to an OpenAI plugin

OpenAI retires custom GPTs on **11 December 2026**
([retirement FAQ](https://help.openai.com/en/articles/20001519-custom-gpt-retirement-and-migration-faq)).
A GPT's replacement is a plugin: a package of skills that ChatGPT and Codex load
when a request matches a skill's description
([plugins](https://help.openai.com/articles/20001256),
[building plugins](https://developers.openai.com/plugins/build/plugins)).

There are two ways across. They are not exclusive, and the order matters.

## Route A — the built-in migration (keeps the GPT's own files)

1. Finish every edit to the GPT first. After migration the GPT is read-only
   until it retires, and its creator cannot delete it.
2. Make sure the GPT is published. Only-me or invite-only sharing counts;
   public sharing is not required. Drafts do not migrate.
3. When the option appears for your account: **My GPTs → Migrate to plugin**,
   review the details and follow the steps. The plugin starts private.
4. What carries over: the instructions become **one skill**, the knowledge files
   become that skill's reference files, connected apps come along. The chosen
   model, conversation starters, sharing and existing chats do not.
5. Test it with the same prompts as the GPT (below) before relying on it.

This route keeps the GPT's 8,000-character rule summary as the whole skill,
with the knowledge files beside it.

## Route B — the full plugin built from this repository (recommended)

`node tools/bin/build-openai-plugin.mjs` writes
`dist/openai-plugin/roblox-luau-expert/`: a portable `plugin.json`, all forty-six
skills under `skills/` with their references and the tested style recipes, the
Python and Node checkers, the library and the style picker. Each skill loads in
full when its description matches, so nothing is squeezed into 8,000
characters and nothing depends on retrieval finding the right fragment.

### How the plugin's skills reach the model

ChatGPT and Codex find the skills in the plugin's `skills/` folder. At the
start of a conversation the model sees only each skill's name and
description, from a list OpenAI caps at 2% of the context window or 8,000
characters; past that, descriptions are shortened first and then skills are
left out. A skill's full `SKILL.md` loads when the model picks it, and its
references when that file points at them
([Build skills](https://learn.chatgpt.com/docs/build-skills)).

So every skill here is written to be reached two ways:

- **Its own description**, short and with the trigger words first. All 46
  names and descriptions total 6,972 characters, under the cap with room for
  the user's other plugins; `node tools/bin/lint-skills.mjs` fails the build
  when they grow past 7,000, and the plugin build runs it on the copies it
  packs.
- **The router**, `roblox-luau-expert`, which triggers on any Roblox or Luau
  task and carries a skill map: which skills to open together for each kind
  of task, and every skill's path. Each skill ends with **Works with**, naming
  the partners it hands work to. A host that trims the list still reaches
  every skill through the router.

Install it for Codex and the ChatGPT desktop app:

- **Inside this repository:** `.agents/plugins/marketplace.json` already lists
  the built plugin. Build it, restart the ChatGPT desktop app, open the Plugins
  Directory, choose **Roblox Luau Expert (local build)** and install.
- **For every project:** copy `dist/openai-plugin/roblox-luau-expert` into
  `.codex/plugins/` in your home folder, then add the same entry to the
  personal marketplace file, `marketplace.json` in `.agents/plugins/` in your
  home folder, with `"path": "./.codex/plugins/roblox-luau-expert"`, and
  restart the desktop app.
- **Codex CLI:** `codex plugin marketplace add <path to this repository>`.

The desktop app is the documented path for a local plugin. Whether it
also appears in ChatGPT on the web depends on the account and plan; OpenAI's
page says availability varies, and personal skills in ChatGPT are listed for
Business, Enterprise, Healthcare and Edu. Check the Plugins page on the web
after installing rather than assuming.

Update it by hand the same way the GPT was updated: change the source, rebuild,
and reinstall. To have it follow this repository automatically through GitHub,
see [auto-update.md](auto-update.md).

### The copy uploaded at chatgpt.com/plugins

A plugin uploaded as a ZIP on the web (**Plugins**, **Personal**, **Created by
me**) does not follow GitHub. Each version is another upload: open the plugin,
**Plugin actions** (the three dots), **Upload new version**, and choose
`dist/openai-plugin/roblox-luau-expert-plugin.zip`.

```bash
node tools/bin/web-plugin-update.mjs --status   # builds the ZIP; exit 3 when this version was not uploaded
node tools/bin/web-plugin-update.mjs --record   # after the page shows the new Version
```

A scheduled Claude task in the desktop app (**Scheduled**, "ChatGPT plugin
auto-update") runs `--status` and, when an upload is needed, does the upload in
the signed-in Chrome through Claude in Chrome, checks the Version on the page
and records it. It runs only while the Claude desktop app is open.

Plugin names are unique per account. With two uploads named
`roblox-luau-expert`, every **Upload new version** fails with "A plugin named
`roblox-luau-expert` already exists", on either copy. Remove the copy you do
not use from the Personal list; the next upload then succeeds.

## Testing the replacement

Use the prompts in `evals/ui-behavior.md` (cases 5–7 exercise the picker, a
picked code and plain-word parts) and `evals/executor-evidence.md`. Check that
the plugin:

- selects the Roblox skills for a Roblox request without being named;
- links the picker before building new UI, and builds a picked code from its
  recipe;
- runs `tools/py/` checks on the final file and reports what ran;
- reads decompiled source for evidence before choosing one API per job.

Record the model shown in the product; the GPT's selected model does not carry
over.
