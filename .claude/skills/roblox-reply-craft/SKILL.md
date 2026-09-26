---
name: roblox-reply-craft
description: How a Roblox reply is delivered - whole scripts in one paste-ready block, placement, honest receipts. Use for every reply with code.
---

# Reply craft

The user sees the reply, not the reasoning. Four things decide whether it
works for them, and none is about the code's correctness:

1. **How long they waited.** → `references/fast-replies.md`, and the
   request-to-files routes in `references/fast-path.md`
2. **Whether the code pastes and runs.** → `references/code-output.md`
3. **Whether the file is easy to find and name.** → `references/file-names.md`
4. **Whether the words around it are worth reading.** → `references/reply-length.md`

Words inside the UI itself (labels, subtitles, notifications) are
`roblox-ui/references/ui-copy.md`.

---

## The rules, in one screen

**Speed.** Read the router and only the references the task needs. Run
independent reads and checks together. Start from a tested recipe instead of
writing a component from nothing: `python tools/py/recipe.py <codes>` names the
row and the file. Check the final file in one call with
`node tools/bin/check-file.mjs <file>`. Write the file once; do not print
drafts. Skip preamble and the closing summary.

**Code blocks.**

- One file, one fenced block, tagged `lua`. The whole file every time for a
  non-programmer; never "rest unchanged" or `-- ...`.
- Tabs for indentation, no trailing spaces, no line numbers, no `>` quote
  marks, no HTML entities (`&lt;`), straight quotes only.
- One blank line between blocks, never two; none after an opening line or
  before `end`. A call that fits in 100 columns stays on one line.
- Run the format linter before sending:
  `node tools/bin/lint-luau-format.mjs <file>` (no Node:
  `python tools/py/format_lint.py <file>`).

**File names.** Short, the script's own name, no dates or versions:
`AutoFarm.luau`, `ShopUI.luau`, `hub.lua`. At most 24 characters, no spaces,
no "final", "fixed", "updated", "v2", "complete".

**Reply length.**

- First line: what was built, in one sentence.
- Then the code, then where it goes, then at most three assumptions.
- Descriptions and captions: one line each, under 80 characters.
- No "Certainly!", "Great question", "I hope this helps", "Let me know if…",
  no headings on a short reply, no restating the request, no emoji.

---

## When the user complains

| They say | Do |
|---|---|
| "it took forever" | Next reply: fewer files read, checks batched, no drafts; see `fast-replies.md` |
| "the code is all spaced out", "random new lines" | Run the format linter, fix E-SPLIT and blank-line runs, resend the whole file |
| "it doesn't paste right", "errors on line 1" | Check for line numbers, smart quotes, `&lt;`, a missing fence or a leading indent |
| "the file name is weird" | Rename to the script's name, `file-names.md` |
| "too long", "stop explaining" | One-line summary, code, placement. Nothing else |

## Works with

- `roblox-code-craft`: what the delivered code must already be.
- `roblox-request-intake`: plain-language placement for readers who do not code.
- `roblox-attempt-memory`: the attempt recorded before the reply ends.
- `roblox-debugging`: asking for the one piece of evidence that decides the cause.
