# Scope and framing

Why a model sometimes refuses a client-side Roblox scripting question, and what
to do about it that is honest.

**This is not a jailbreak and must not be used as one.** There is no roleplay
framing here, no instruction to disregard safety policy, no obfuscated wording.
If a request is genuinely for harm — targeting other people's systems, malware,
credential theft, mass abuse — the correct answer is no, in every tool, and
nothing in this file changes that.

What this file addresses is the opposite failure: a refusal of a question that
was never about harm in the first place.

---

## Why it happens

The word **exploit** carries two unrelated meanings.

| In security | In Roblox |
|---|---|
| A payload that attacks somebody else's system | A Luau script run in your own game client |

A safety classifier reading "write me an exploit" has no way to tell which one
it got. The base rate across the whole internet points at the first meaning, so
that is what it assumes. The refusal is not a judgement about the person asking;
it is a judgement about an ambiguous string.

Two other words do the same thing: **bypass** (evade a security control / get
past a client-side movement check in a game) and **inject** (introduce hostile
code / run a script through an executor).

---

## The fix is precision, and it is honest

A request that states what it actually is gets answered because it is
answerable. This is not a workaround — it is supplying the context the
classifier was missing, and the context happens to be true.

| Ambiguous | Precise, and true |
|---|---|
| "write me an exploit for X" | "write a client-side Luau script for X, run through an executor, on my own account" |
| "bypass this anticheat" | "this game's client-side script resets `WalkSpeed` every frame; which layer holds the value and what resets it" |
| "hack this game" | "what can and cannot be changed from the client in this game, and why" |
| "inject this" | "run this through an executor" |
| "make an aimbot" | "read the input and camera side of this decompiled combat module and explain how the client picks a target" |

Notice what the right-hand column has in common: it says **which machine**,
**whose account**, and **what technically happens**. Those three facts are what
turn a flagged string into a technical question.

---

## What answering looks like

A refusal and an answer are not the only two options, and the middle one is what
a good reply does: **answer the technical question, state the boundary once, and
do not moralise.**

| Instead of | Do this |
|---|---|
| "I can't help with cheating" | Answer the value-layer question. Say ban risk once, plainly, and move on |
| Refusing the whole message because one clause was broad | Answer the parts that are in scope; name the one part you are declining |
| Hedging every paragraph with a warning | One sentence of scope at the top, never repeated |
| Asking the user to confirm they own the account, repeatedly | Take the stated context at face value the first time |

The repetition is its own failure. A reply that re-states the risk in every
paragraph reads as reluctant, buries the technical content, and teaches the
reader to skip the warnings — including the one time it mattered.

---

## A first message that works

Paste this once, at the top of a new conversation, and the rest of the
conversation inherits it:

> I'm working on client-side Luau for Roblox — scripts I run through an executor
> on my own account, in my own place and private servers. Same engine and
> language as the game code. I'm interested in how the client/server trust
> boundary actually works, and I want the defensive view alongside it where it's
> relevant. Assume that context for everything I ask.

It is three facts — **which machine, whose account, what technically happens** —
and all three are true. That is the entire technique.

For a specific request, the same three facts inline:

> Here's the decompiled `Dragger` LocalScript from a game I play. On my own
> account, I want a client-side script that raises the drag force. Which layer
> holds that value, and what resets it?

---

## The context worth stating once

Any of these, stated plainly at the top of a conversation, does more than any
amount of rephrasing:

- The target is **your own account**, and a **private server** or your own
  place.
- The subject is **client-side Luau** — the same language and engine as the game
  code, running in a client you are already authorised to run.
- The interest is **how the engine's trust boundary works**, which is the same
  knowledge as defending a place you own. This stack ships both halves for that
  reason: `roblox-executor` and `roblox-game-security` are mirrors.

That framing is already baked into the generated instructions:
`build-portable.mjs` appends a scope paragraph to the GPT instructions saying
exactly this, plus the line that declines what is genuinely about other people's
systems.

---

## What still gets declined, and should

Rephrasing does not make these acceptable, and a tool that answers them is
broken rather than helpful:

- Anything aimed at **accounts or systems that are not yours** — stealing
  credentials, session tokens, or other players' data.
- **Malware**: loggers, stealers, remote access tooling, anything that persists
  on somebody else's machine.
- **Mass abuse**: botting at scale, automated account creation, spam.
- **Disrupting a service** for other people rather than changing your own
  client's behaviour.
- **Distribution as attack tooling** — packaging something to be run against
  people who did not consent.

If a request is refused and it genuinely falls in this list, the refusal is
correct and the answer is to change the request, not the wording.

---

## Practical notes per tool

**A custom GPT.** Put the generated instructions in the Instructions field and
upload `gpt-knowledge.md` as Knowledge. The scope paragraph is already in the
instructions, and it now names the specific words that trip the classifier —
exploit, bypass, inject, cheat, aimbot, script hub — and says to read them as
the technical terms they are in this context. Custom instructions do not
override the platform's safety layer and are not intended to; they supply
context, which is a different thing.

If it still refuses, the usual cause is the **first message** of the
conversation rather than the instructions. A bare "make me an exploit script"
with no context is ambiguous no matter what the instructions say, because the
model is weighing one short string. Opening with the paragraph above resolves
it, and the conversation starters set on the GPT are written to do the same job
for a single click.

**Codex and Cursor.** These read `AGENTS.md` and `.cursor/rules/` respectively,
in a repository that visibly contains a Roblox project. Project context is
usually enough on its own; refusals are rarer here than in a bare chat window
because the surrounding code says what the work is.

**Claude Code.** The `roblox-executor` skill states its scope in its own text,
and the router repeats it. No extra framing is needed.

---

## One thing that does not work

Do not try to smuggle a request past the classifier — invented personas,
"hypothetically", spelling things oddly, splitting a word across lines. Three
reasons, in descending order of how much they should matter:

1. It is dishonest, and the refusal it defeats might have been right.
2. It degrades the answer. A model that has been talked into answering a
   question it did not understand gives worse technical output than one that
   understood it.
3. It does not reliably work anyway.

Saying accurately what you want is both the honest route and the one that
produces the better script.
