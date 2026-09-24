# Faster replies

The model's speed is fixed; what it reads and writes is not. Almost all the
waiting in a Roblox reply is spent on three things: reading files that did not
change the answer, writing text nobody needed, and running checks one after
another. Cut those and the same answer arrives sooner.

---

## Read less

1. **The router first, then only what it names.** A toggle colour change needs
   `roblox-ui` and the toggle recipe, not the executor skill, the persistence
   skill and three design references.
2. **Read a reference once per conversation.** If it is already in context,
   use it.
3. **Search, then read the part.** For a long file, find the section
   (`grep -n`) and read that range, not the whole file.
4. **In a custom GPT**, open the packs with Code Interpreter once, read the
   named sections, and say which ones you read. Do not re-open the archive for
   each question.

## Write less

1. **Start from a recipe.** A picked code (T1, M4, D2) has a tested
   implementation in `style-pack.md` / `roblox-ui-components/assets/`, and fly,
   ESP and the other character features are assets in
   `roblox-executor-features`. `python tools/py/recipe.py T1 M4 fly` names the
   files; paste them with the THEME or constants changed.
2. **No drafts in the reply.** Work out the design, then write the file once.
   Showing a first version and then "here is an improved version" doubles the
   length and the wait.
3. **Generate repetition with data.** Twenty similar rows are a table and a
   loop, not twenty blocks of property assignments. This is also what keeps a
   script under the local-register limit.
4. **No ceremony in code**: no narrating comments, no guards for impossible
   cases, no success prints (`roblox-code-craft`). Each costs time to write
   and to read.
5. **No preamble, no summary.** The reply shape is: one line, code, placement,
   up to three assumptions.

## Check in parallel, once

Run every check on the final file in one call and report what it prints. Do
not run a check on a draft you are about to change.

```bash
node tools/bin/check-file.mjs F      # slop, format, UI, API, compile, registers
python tools/py/check_file.py F      # the same where there is no Node
```

The request-to-files routes and the lookup tool are in `fast-path.md`.

## Ask at most one question, and only when it saves a rebuild

A clarifying question costs a full round trip. Decide defaults and state them
(`roblox-request-intake`); ask only when two readings would produce different
work, and then ask everything in one grouped question.

## For the user: what makes their replies faster

Say this when they ask how to speed things up, in their words:

- Send the error text or the script with the request, so no turn is spent
  asking for it.
- Answer the style question with codes ("T1, M4, N1") or "choose for me".
- For a long conversation, start a new chat for a new feature: a shorter
  history is read faster on every turn.
- Ask for one feature per message when each is large.
