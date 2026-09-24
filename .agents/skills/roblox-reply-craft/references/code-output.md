# Code that pastes and runs

A script can be correct and still fail the user: it arrives split across three
blocks, with line numbers in front, curly quotes, a blank line between every
statement, or `-- rest of the code stays the same`. A non-programmer cannot
repair any of that. This is the delivery standard for every code block.

---

## One file, one block

- **One fenced block per file**, tagged `lua` (chat renderers and executors
  both handle `lua`; `luau` is fine where the host highlights it). Put the
  file name on the line above the block in bold, not inside it as a comment.
- **The whole file.** For someone who does not code, never send a fragment,
  a diff, `-- ...` or "keep the rest the same". If the file is long, it is
  still one block.
- **Nothing inside the block that is not code**: no "Here's the code:", no
  Markdown bullets, no line numbers, no `>` quote markers, no trailing
  "Let me know" text.
- **The same code once.** If a download is also offered, the block is the same
  file, not a second version.

## Characters that break a paste

| Problem | Looks like | Why it breaks |
|---|---|---|
| Smart quotes | `“Hello”`, `‘x’` | Not string delimiters in Luau: a syntax error |
| HTML entities | `&lt;`, `&gt;`, `&amp;` | Pasted literally: `if a &lt; b` does not compile |
| Line numbers | `12  local x = 1` | Every line becomes an error |
| Non-breaking spaces | invisible | Some editors reject them; they break `==` alignment and search |
| A leading indent on every line | the whole block shifted right | Harmless in Luau, but the next edit misaligns |
| Mixed tabs and spaces | uneven indentation | The format linter flags it; editors show it wrong |

## Layout inside the block

The house format is StyLua's with tabs and 100 columns
(`roblox-code-craft/references/formatting.md`). The ones that make code look
"spaced out" or "clustered":

- **One blank line between logical blocks. Never two in a row.** No blank line
  right after `function ...`, `then`, `do` or `{`, and none right before `end`
  or `}`.
- **A call that fits on one line stays on one line.**
  `local frame = Instance.new("Frame")`, never split over three lines.
- **Tables are expanded** one field per line when they are config or props; a
  short list (`{ 1, 2, 3 }`) stays inline.
- **No blank line between every statement.** Statements that do one thing
  together (create, size, parent) sit together.

Check before sending, and fix what it reports:

```bash
node tools/bin/lint-luau-format.mjs Script.luau
python tools/py/format_lint.py Script.luau
```

## Long scripts

- Keep under the local-register budget while writing
  (`roblox-luau-language/references/compiler-limits.md`), and run
  `node tools/bin/check-registers.mjs` on anything over a few hundred lines.
- A script too long for one reply is split by **file**, never mid-file: a
  ModuleScript per block, each whole, with where each goes.

## After the block

Where it goes in Studio's words, and what success looks like: what to press,
what appears, what the Output shows. Then at most three assumptions.
