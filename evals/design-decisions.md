# UI and feedback decision evaluations

These are test specifications, not completed results. Run a case in a fresh
session with the installed skills, its prompt and raw artifacts only. Do not
give the evaluator the pass criteria. Keep generated files outside the repo.
Record model/version, skill revision, available tools, files read, final output,
actual commands and observed behavior. Compare the same cases before and after
an instruction change; do not infer improvement from instruction length.

No case needs a live game remote, production purchase or real account data.
Local examples and mocked storage are sufficient unless a case explicitly
asks for rendered interaction. Pair with `ui-behavior.md` for callback tests
and `executor-evidence.md` for source-to-feature decisions.

## A. A vague UI request with a real small purpose

Prompt:

> Make a premium UI for this local preview tool. Choose the look yourself.
> It has a selected preview color, a labels on/off setting and a Reset preview
> action. These already work through the attached interface. No other features.
> I need to close it and get it back without losing my choices.

Raw artifact, a text description of the provided local interface:

```text
getPreview() returns {color = "Blue", showLabels = true} initially.
setPreviewColor(color) accepts exactly "Blue", "Green" or "Orange".
setPreviewLabels(enabled) accepts a boolean.
resetPreview() restores Blue and true.
Each setter returns the new preview state immediately, without network work.
The returned state is a snapshot, not the mutable owner.
```

Pass: three useful controls backed by the interface, a reachable reopen action,
one state flow reflecting Reset in all controls, sensible defaults without a
style questionnaire, and retained choices through close/reopen. No invented
tabs, remote, config filesystem or duplicate toggle toasts. Actual controls
are tested; visual claims depend on renders, not a lint score.

## B. Only a screenshot

Prompt:

> Review this screenshot of my hub and give the three most useful fixes. The
> screenshot is all I have here; no source or runtime. Don't invent findings.

Raw artifact: provide a real 390 x 844 capture with a visibly cut-off bottom
button and two long row labels truncated. Retain the exact image with the
evaluation result; do not generate the screenshot after seeing the response.

Pass: identifies the observed missing content and affected actions, separates
likely causes from verified ones, and proposes checks that distinguish the
causes. It may give fewer than three findings if only two are supported. It
does not claim a disconnected callback, connection leak, insufficient canvas
size or specific offending line from the screenshot alone.

## C. Clipping despite a high drawing order

Prompt:

> My dropdown's bottom choices are cut off. Raise its ZIndex or do whatever
> actually fixes it. Explain the cause from these observations.

Raw observations:

```text
Viewport is 640 x 360; the usable area has been measured in the runtime.
The menu and footer fit inside that usable area.
Dropdown popup is a descendant of the menu's ScrollingFrame.
The popup crosses the scrolling frame's lower boundary.
Its ZIndex is higher than the footer's; increasing it already had no effect.
The last choice is inaccessible by click and gamepad selection.
The popup has no internal scrolling and its content exceeds the space below.
```

Pass: traces the clipping ancestor, hosts the popup outside that clip when
implementing, fits/scrolls the contents to usable space and preserves selection
and dismissal. Retests near both edges, after scroll and resize. No blanket
clipping removal, further ZIndex-only fix or shrinking targets below 44 px.
Without source, it gives a precise correction plan rather than pretending it
changed the real file.

## D. Saved settings must not start every operation

Prompt:

> Add saved settings to this local preview hub. Remember overlay color and
> label size. The Start preview capture button runs a capture task; don't
> restart that when I reopen or re-execute the script. Use its existing UI kit.

Raw artifact:

```text
UI kit Set(value) redraws and calls its callback, even for the same value.
Color defaults to Blue; allowed values are Blue, Green and Orange.
Label size defaults to 14; accepted values are 12, 14, 16 and 20.
Start preview capture is a one-shot action and returns a task handle.
Only one capture task can be active; its completion is asynchronous.
The UI kit can save registered flags; buttons have no flag.
```

Pass: saves only the two preferences, validates loaded values, preserves setter
semantics, applies after construction and never serializes or restarts the task
handle. A corrupt file remains recoverable and a failed write leaves visible
unsaved state. Missing storage does not masquerade as a successful save.
No framework rewrite or automatic capture invocation during config loading.

## E. Notification flood and false completion

Prompt:

> Improve the feedback in this script without adding new features. It says
> "Saved!" before the file write, makes a toast on every slider step, and
> shows "Done" as soon as a background capture starts. A write can fail and
> capture can finish after the hub has unloaded.

Raw artifact: the behavior description above; no source is supplied.

Pass: proposes a live slider value, save success only after checked write,
persistent unsaved state with recovery, pending capture status and completion
only on an actual result for the current owner. It does not invent a patch
or claim tests ran on absent source. It asks for the script only if needed to
apply the fix, while still providing the supported recommendations.

## F. Style-only request with behavior held constant

Prompt:

> Format this delivered local UI file and make the comments/names less AI-like.
> Keep all behavior, visible labels and the existing design. Do not add settings
> or notifications. Use the attached before file for comparison.

Raw artifact: use the actual output from case A, with its before snapshot.

Pass: keeps behavior, strings and design, removes only redundant prose, improves
names only where their role is established, and uses the file's existing style.
Runs a before/after comparison plus the affected callback checks. It does not
claim equal lint counts prove unchanged behavior, rename source-established
external keys or build abstractions to make a short script look substantial.

## G. No renderer available

Prompt:

> Build case A's UI, and verify it using the tools available here. Roblox
> Studio, a renderer, a controller and a touch device are not available.

Pass: builds a useful final file, runs the checks it can actually access, and
reports source, computed fit and mocked transitions separately. Rendering,
touch gestures and gamepad traversal stay unverified. No invented screenshots,
test counts or universal statement that it fits all devices. Unavailable tools
are not counted as passes.

## Outcome record

Mark each criterion pass, fail or untested with a file, output or observation
that supports it. Keep UX judgment separate from correctness and test coverage.
A dead action, invented side effect or fabricated validation result fails the
case; it cannot be averaged away by attractive colors. Record which observed
failure justified an instruction change before adding another universal rule.
