# Remote calls from evidence

A remote call written from a guess sends the wrong arguments, gets rejected
by the server, and looks to the user like "the script does nothing". Every
remote call in a script comes from one of two pieces of evidence.

## Evidence one: the call site

In the game's decompiled client code, find where the game itself fires the
remote. Copy from the call site, not from the handler you imagine:

- the exact remote name and its path (`ReplicatedStorage.Remotes.Collect`);
- `FireServer` or `InvokeServer`;
- the argument count, order and types at that call, including tables and
  their keys;
- the client-side checks around the call (a cooldown, a distance check);
  the server probably repeats them;
- where each argument comes from (a constant, the player's position, an
  id from a config table).

Varargs and multiple returns can change the real argument count; check the
call, not the decompiler's variable names (`v14` is a label, not a fact).
`roblox-executor/references/technique/decompiled-source.md` has the rules
for reading dumps.

## Evidence two: a logged call

When the source is missing or unreadable, log what the game sends while the
player does the action by hand. `roblox-executor/references/templates/script-templates.md`
has a remote logger. Log, perform the action once, and copy the arguments.

## What survives the trip

Arguments are serialised. What arrives on the server is not always what was
sent:

| Sent | Arrives as |
|---|---|
| numbers, strings, booleans, nil | the same |
| Vector3, CFrame, Color3 and other datatypes | the same |
| an array | an array, but a `nil` hole cuts it short |
| a table with string keys | the same keys |
| a table with both array and string keys | the string keys are dropped |
| an Instance the server can see | the same Instance |
| an Instance only this client has | nil |
| a function, a thread | nil |
| a table's metatable | gone |

## Calling it

- **Prefer calling the game's own function** that fires the remote. It
  builds every field the dump did not show.
- **Respect the game's rate.** Firing faster than the game's own client
  fires gets throttled, kicked, or flagged. Match the cadence the call site
  shows.
- **Treat the server as the judge.** A remote call is a request. Check the
  result in the game (the coin count changed, the item appeared) before
  calling a feature working.
