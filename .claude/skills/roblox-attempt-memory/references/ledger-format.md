# Ledger format

The **Attempts** section of `PROJECT_CONTEXT.md`. Plain markdown a person can
read, in a shape `tools/bin/attempt-ledger.mjs` and
`tools/py/attempt_ledger.py` parse identically.

## Shape

```markdown
## Attempts

### A7 failed: hub buttons do nothing on phones
- Tried: connected each button's MouseButton1Down to its feature toggle
- Saw: taps highlight the button and nothing turns on; PC works
- Cause: MouseButton1Down never fires for touch
- Instead: Activated for the action, InputBegan for the pressed look
- Avoid: `MouseButton1Down`
- Check: tap each toggle in the device emulator; each changes its feature
- Date: 2026-09-25
```

- **Heading**: `### <ID> <status>: <title>`. IDs are letters then digits,
  unique in the file: `A1`, `A2`... for attempts. The title names the symptom
  in the user's words, not the fix.
- **Fields**: one line each, `- Name: value`, in any order. A repeated field
  joins onto the first.
- Any other `#`, `##` or `###` heading ends the entry, so notes can sit
  between sections.

## Statuses

| Status | Use it when | Required |
|---|---|---|
| `failed` | an approach was tried and did not produce the result | Tried, Saw |
| `rejected` | it worked and the user did not want it | Tried, Saw |
| `fixed` | a bug was found and removed | Avoid or Check |
| `works` | an approach is confirmed; keep using it | Tried |
| `open` | the problem is unresolved | Saw |

`check` enforces `failed`, `rejected` and `fixed` entries. `plan` compares new
approaches against `failed` and `rejected` ones.

## Fields

| Field | Holds | Written from |
|---|---|---|
| Tried | the approach, in one line: layer, API, value | what the code did, not what it was meant to do |
| Saw | the observation | the user's words, an error line, a measurement |
| Cause | why, when evidence shows it; otherwise `unknown` | a source line, a probe's output, a documented rule |
| Instead | the next approach, with where it lives | a tested asset, a reference, a changed layer |
| Never | a rule in one line, when Instead is not enough | |
| Avoid | backtick-quoted patterns that must not appear in code | the smallest expression that is the mistake |
| Unless | backtick-quoted patterns that switch Avoid off for a file | the fix's own signature |
| Check | the command or step that proves the fix still holds | a test, a lint code, an emulator step |
| Date | `YYYY-MM-DD` | |

## Writing Tried so `plan` can match it

`plan` compares meaningful words after dropping common ones and crude
suffixes, and calls it a repeat when three or more are shared and they make up
at least 60% of the shorter description. Name the parts that define the
approach: the property or API, the loop or event, the object.

| Weak | Strong |
|---|---|
| tried to fix the speed | set Humanoid.WalkSpeed once when the toggle turns on |
| changed the UI | replaced the Outer UIStroke on each row with a padded ScrollingFrame |
| used a different method | read the upvalue with debug.getupvalue on the sprint function |

## Patterns

`Avoid` and `Unless` hold regular expressions in backticks. They run against
each line of a Luau file with comments removed, in both Node and Python, so
use the common subset: `\b \s \d \w . * + ? [] () |` and escaped
punctuation. One line at a time: a pattern cannot span lines.

A pattern that matches correct code is worse than none; it teaches everyone
to ignore `check`. Test it on the fixed file (no hit) and on the broken one
(a hit), then run `attempt-ledger.mjs lint`, which also compiles every
pattern.

## Example: a design the user turned down

```markdown
### A12 rejected: hub opened as a full-screen overlay
- Tried: full-screen dark overlay with the hub centred at 60% width
- Saw: "too much, I want it small in the corner like before"
- Instead: M4 corner panel, 360 wide, kept from the first version
```

A `rejected` entry keeps the next redesign from drifting back to what the
user said no to.

## Example: a fixed bug with a test

```markdown
### A15 fixed: noclip left accessories colliding after unload
- Cause: unload set CanCollide = true on every part, including ones the game had off
- Check: library/tests/recipes/noclip.luau "V restores only what it switched off"
```
