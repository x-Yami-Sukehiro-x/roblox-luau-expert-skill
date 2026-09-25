# Recovering context

Work on one game runs across many conversations: a new chat, a conversation
compacted to a summary, the same project opened in Codex after Claude. None
of them remembers the others. What survives is what was written down.

## What to rebuild before the first reply

1. **The record.** `PROJECT_CONTEXT.md` from the project root, or the copy the
   user uploads. If there is none, say so and start one; do not reconstruct
   earlier decisions from guesses.
2. **The current code.** The file as it is now, not as a summary describes it.
   Summaries drop the detail that caused the last failure.
3. **The last result.** What happened when the user ran the latest version:
   the Output or console text, a screenshot, the doctor's report. If the user
   has not said, ask for exactly that, once.
4. **Open and failed entries.** Read every `open` entry and `search` the
   current complaint. Run `plan` on the approach you are about to take.

Then state, in two or three lines, what the record says and what you are about
to do. The user can correct a wrong premise before code is written.

## What never to do

- Claim to remember a conversation you cannot see. "Last time we..." is only
  true when the record or the visible conversation says it.
- Treat a summary's "fixed" as verified. A summary records what was claimed;
  the ledger's `Check` line says how to confirm it.
- Restart from the original request and rebuild from scratch. That discards
  every `rejected` design and `failed` approach the user already paid for.

## Where each host keeps it

| Host | The ledger | Lasting preferences |
|---|---|---|
| Claude Code | `PROJECT_CONTEXT.md` in the project | the memory directory, for the user's corrections and preferences that apply beyond this project |
| Codex | `PROJECT_CONTEXT.md` in the project | the same file; `AGENTS.md` here is generated and is not edited by hand |
| Cursor | `PROJECT_CONTEXT.md` in the project | the same file |
| custom GPT, ChatGPT plugin | the user uploads `PROJECT_CONTEXT.md` at the start of each chat | the GPT gives back an updated copy as a download at the end of each attempt |

Claude Code's memory is for things true across projects: the user wants
replies short, the user's executor lacks `hookmetamethod`. Game-specific facts
(this game resets WalkSpeed every 3 s) belong in that game's
`PROJECT_CONTEXT.md`, where they cannot leak into another project.

A GPT cannot write to its own knowledge or to another application's memory.
Saying the record was "saved" when it was only printed is a false claim;
hand over the file and say the user needs to upload it next time.

## At the end of every attempt

Write the entry before the reply ends, not when the user reports back: the
attempt as `open` with what it changed and how to check it. When the result
comes in, update the status and the Saw line. A conversation that ends
between the two still leaves the next one a record of what was tried.

## The rest of the record

The ledger is one section. The rest, from
`../../roblox-luau-expert/references/task-contract.md`: project and scope,
source revision, confirmed contracts (paths, remotes, argument shapes), UI
decisions (palette, picked style codes, target devices), validation. Keep it
short enough to read in a minute; merge entries rather than appending
duplicates.
