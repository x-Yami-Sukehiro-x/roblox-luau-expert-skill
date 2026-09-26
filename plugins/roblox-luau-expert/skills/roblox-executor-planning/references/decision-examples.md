# Decisions that change the implementation

These are fictional examples of evidence, not game paths to paste into a script.
Use the actual names and call sites in the supplied game.

## A table field is not necessarily the active setting

Source shows a camera controller copying `CameraSettings.Sway` into a local at
startup, then reading that local on each update. Editing the table is easy, but
the visible sway will not change through that path after initialization.

Decision: inspect the controller's established setter or captured setting. A
probe comparing the active local with the table field can discriminate the
paths. Do not also edit the field, constant and upvalue "to cover everything".
If only the table can be identified, report that the reader remains unresolved.

Acceptance: sway changes while the camera is active; disabling restores the
captured baseline; leaving the camera mode and re-entering behaves as specified.
A printed field value is not this acceptance test.

## A smaller number is not a faster server action

Source shows `nextRollAt` gating a button, an exact request for one roll, and an
incoming result event. The server handler is absent.

Decision: the source can support an action queue that waits for completion if
the call contract and guards are complete. It cannot establish that reducing
`nextRollAt` changes the server's accepted rate. Keep observed pacing and a
stop condition. A missing result leaves the action pending or failed; it must
not become an unbounded retry loop or a second concurrent request.

Acceptance: one accepted request produces one matched result, no second request
starts while the first is pending, stopping prevents the next action, and a
timeout leaves an honest state. Label animation, request count and reward
count are three different observations.

## Two features share a camera

Free camera writes `Camera.CFrame`. Spectate sets `CameraSubject` and returns
control to the normal camera scripts. Independent "restore original" closures
can undo whichever feature was activated most recently.

Decision: choose one camera owner with explicit modes. Entering a second mode
releases the first mode's writers before capturing its baseline. On unload,
restore only owned state; do not overwrite another tool's newer camera choice.

Acceptance: activate A, then B, disable B, respawn, rerun and unload twice. State
and displayed mode agree after each transition. Do not add a notification for
every camera update to conceal an ownership conflict.

## Missing evidence has a precise next step

Source names two closures with the same constant and both contain `0.25` twice.
The requested effect depends on one timer slot.

Decision: neither first match nor every matching number identifies the timer.
Observe a distinguishing state transition or obtain the caller that identifies
the active closure. If a probe still cannot distinguish the slots, return that
result without writing. Renaming `u3` to `cooldown` does not make slot 3 proven.

Acceptance: the observation can explain why exactly one candidate has the
required role. A second constant common to both candidates adds no distinction.

## Strong features can come from combining existing facts

The dump provides replicated resource positions, a current objective identifier
and an already functioning local map. A useful feature may combine them into
an objective-filtered route with distance and streaming status. It does not
require a fabricated remote or a stronger damage number.

Decision: first establish the resource-to-objective relation and what happens
when a resource disappears. Reuse the existing map's coordinate conversion if
its caller contract is known. Keep server-owned collection outside this local
display feature unless the actual action is separately established.

Acceptance: a changed objective replaces stale markers, streamed-out resources
are shown as unknown rather than falsely complete, and unload removes only the
feature's markers and subscriptions.
