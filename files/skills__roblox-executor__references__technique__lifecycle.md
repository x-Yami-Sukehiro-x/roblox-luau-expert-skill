# Executor lifetime and restoration

Read when a script changes a value, installs a hook, draws UI, connects an event
or starts asynchronous work. A run that succeeds once is only the first case.

## Before the first mutation

1. Resolve required capabilities and the source-backed target. Missing or
   ambiguous targets stop with a named error, before any write or remote call.
2. Keep one task-specific owner under `getgenv()`. Unload its previous session
   **before capturing originals**; otherwise the second run saves the patched
   value and later "restores" the patch.
3. Capture originals from the exact object/slot being changed. Record only
   resources this session owns. Do not use a world-wide cache clear as cleanup.
4. Register each cleanup when the resource is acquired. If later initialization
   can fail across a real boundary, release acquired resources and surface that
   error. No blanket rollback around infallible setup or hidden success path.

## Unload contract

- It can be called twice and after partial setup. Mark the session inactive
  first; then stop producers, disconnect owned connections, dispose owned UI and
  Drawings, and restore owned changes. Clear the namespace only if it still points
  to this session, so an old callback cannot remove the new owner.
- Cancel owned tasks where supported and invalidate pending results. After every
  yield, check the session identity and the specific character, camera or target
  whose lifetime the operation depends on. A task that resumes after unload must
  not recreate UI, make a call or restore an obsolete value.
- Reacquire character-bound references on respawn. Read the current camera when
  needed or observe replacement. Do not retain a dead Humanoid or first camera.
- Restore the captured value on the captured object. If another writer changed
  that slot after this session, do not silently overwrite it: use an explicit
  ownership/conflict decision. Equality with the last written value is a useful
  conflict check, but cannot prove no other writer touched the same value.
- Re-enable only connections this session disabled that were originally enabled.
  Never blanket-disconnect the game's callbacks or re-enable an initially disabled
  connection. Do not call a global Drawing/cache cleanup that belongs to others.

## Hook ownership matters

Store the **hooked target** separately from the original callable returned by
`hookfunction`. The latter is for forwarding calls; it is not the target passed
to `restorefunction`. That API removes the entire hook chain back to its first
original and raises when its target is not hooked. Use it only when ownership of
that whole chain is established. It is not a safe per-script undo on a shared
metamethod. [sUNC restorefunction](https://docs.sunc.io/Closures/restorefunction/)

If the executor cannot remove this session's hook without disturbing another,
use a session-owned pass-through switch and disclose that the hook remains
installed. Reuse that installed dispatcher on rerun; do not stack another wrapper
and call it cleanup. Prefer a narrower setter or function hook when the source
allows it. A reference-count or owner flag is not evidence that no other script
installed a hook.

Forward the untouched argument and return contract. Direct `return original(...)`
preserves multiple returns. If arguments need storage, `table.pack` plus its `n`
and `table.unpack(arguments, 1, arguments.n)` preserve nil holes and trailing nils;
`{...}` plus `#arguments` does not.

## Runtime acceptance cases

Record actual observations when a Roblox client and the intended executor are
available. A syntax check, mock or linter is not that runtime.

| Case | Observable pass |
|---|---|
| Missing capability or ambiguous candidate | Named failure before changes; no guessed alternate layer |
| First run, action once | One intended effect; original game call and return behaviour preserved |
| Execute the script again | One active owner, UI and action subscription; original captured before the first patch remains restorable |
| Unload twice | No second mutation, error, duplicate cleanup or global resource deletion |
| Unload during a yield/tween | Resumed work does nothing to the old session or new UI |
| Respawn or camera replacement | New references used; old character/camera no longer drives UI or actions |
| Another owner changes a patched slot | Change is preserved or conflict is reported according to the stated policy |
| Unload after partial initialization | Only acquired resources are released; the failing boundary remains visible |

For UI, also run `roblox-ui`'s viewport and input checks. Report any unavailable
runtime cases as unrun, alongside the static checks that did execute.
