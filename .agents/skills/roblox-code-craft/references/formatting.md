# Formatting

Correct code that is laid out badly reads as generated before a single rule
about comments has been broken. The two complaints that come back are opposites
of each other:

> "it's clustered"

> "putting things on new lines that doesn't need to have a new line"

Both are the same missing standard, and both are countable.

```powershell
node tools/bin/lint-luau-format.mjs path/to/Script.luau
python tools/py/format_lint.py path/to/Script.luau      # identical rules, no Node
```

Eight points, four rows. Everything this stack ships scores 8/8.

---

## The standard is StyLua's, with this repo's config

```toml
# stylua.toml
column_width = 100
indent_type = "Tabs"
indent_width = 4
```

**If StyLua is available, it is the answer** — run `stylua src/` and stop
reading. The linter exists for the case it is not: a file handed back in a chat
window, which nobody pipes through a formatter. It counts the subset of StyLua's
behaviour that is decidable from the text, plus two rules StyLua has no opinion
about (blank-line runs and blank lines against a brace).

---

## 1. A break must buy something

This is the one the complaint is about.

```lua
-- WRONG. 52 columns of code spread over four lines.
local TweenService =
	game:GetService(
		"TweenService"
	)

local frame = Instance.new(
	"Frame"
)

frame.Size = UDim2.fromOffset(
	320,
	180
)
```

```lua
-- RIGHT
local TweenService = game:GetService("TweenService")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 180)
```

**A call whose joined form fits in 100 columns goes on one line.** `E-SPLIT`
joins the construct, measures it, and fails when it fits. The number it prints
is the joined width, so the finding is its own proof.

### What is allowed to stay expanded

| Expanded | Why |
|---|---|
| A table literal | StyLua keeps a constructor expanded once it has a trailing comma, and a config block is read down the left edge |
| Anything over 100 columns joined | It genuinely does not fit |
| A parameter list over 100 columns | One parameter per line, closing `)` on its own line with the return type |

<!-- lint: fragment -->
```lua
-- RIGHT: 109 columns joined, so it wraps - and it wraps one per line.
function Motion.stagger(
	items: { GuiObject },
	intent: Intent,
	goals: { [string]: any },
	totalBudget: number?
)
```

Not this, which is the same line break decided by where the margin happened to
fall:

<!-- lint: fragment -->
```lua
-- WRONG
function Motion.stagger(items: { GuiObject }, intent: Intent,
	goals: { [string]: any }, totalBudget: number?)
```

---

## 2. One blank line separates. Two is spacing by feel

```lua
-- WRONG
local Players = game:GetService("Players")


local function buildPanel(parent: Instance)

	local frame = Instance.new("Frame")
	frame.Parent = parent

	return frame

end
```

Three defects, all counted:

- **`E-BLANKRUN`** — two blank lines in a row. StyLua collapses them; so should
  you.
- **`E-BLANKEDGE`** — a blank line directly after the line that opens a block,
  or directly before the line that closes it. It pads the brace rather than
  separating anything.

```lua
-- RIGHT
local Players = game:GetService("Players")

local function buildPanel(parent: Instance)
	local frame = Instance.new("Frame")
	frame.Parent = parent
	return frame
end
```

### And the opposite — `W-DENSE`

Thirty-six consecutive lines with no blank line anywhere is the "clustered"
half. Blank lines mark where one idea ends: the service block, then the tokens,
then each element and its modifiers.

**Lines inside a table literal do not count.** `library/src/Icons.luau` is a flat
table of 81 icons and is dense on purpose; data is not clustered code.

The grouping that reads well for UI construction, and the one the exemplars use:

```lua
local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 2
title.Text = "Field Kit"
title.Parent = header

local slack = Instance.new("Frame")
slack.Name = "Slack"
slack.LayoutOrder = 3
slack.Parent = header
```

One element per group, its properties under it, a blank line between. Never a
blank line *inside* a group — the reader is scanning for the next `Instance.new`.

---

## 3. Line hygiene

| Rule | Code |
|---|---|
| 100 columns of **code**. Comments are never reflowed, by StyLua or by this | `W-WIDTH` |
| One space after a comma, none before | `W-COMMA` |
| No trailing whitespace | `W-TRAILWS` |
| No trailing semicolons — Luau does not need them | `W-SEMICOLON` |
| One newline at end of file, no blank lines after it | `W-EOF` |
| Never a space before a tab in an indent | `E-MIXEDINDENT` |

`Color3.fromRGB(31,34,41)` is the commonest of these and the easiest to fix.

**Tabs, because the file already uses them.** The primacy rule outranks the
config: a file indented with spaces stays indented with spaces, and you say so
once rather than reformatting it under the user.

---

## What this is not

It is not about taste, and it is not a reason to reformat somebody's file. The
edit discipline in `anti-slop-code.md` §2a still holds and outranks this:

> **Do not reformat lines you did not change.** Whitespace churn hides the one
> real line, so a diff that also reflows 200 lines gets approved unread.

Formatting rules apply to **what you write**. A file you were asked to change
gets its own convention matched, and if that convention is genuinely harmful you
say so once instead of silently fixing it.

---

## Related references
- `anti-slop-code.md` — the ceremony budget, and the edit discipline above
- `code-signature.md` — matching an existing file
- `roblox-toolchain` — StyLua, selene, and running both in CI
