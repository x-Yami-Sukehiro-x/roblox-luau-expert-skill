# UI behavior evaluations

Run each prompt in a fresh session with the installed stack. Give the model the
prompt and any named source, not the pass criteria. Keep generated files outside
the repository. Record the model/version, skill build, complete output, commands
actually executed and available runtime. Run the same prompts before and after
an instruction change; a higher source score alone is not a better result.

No prompt requires a production purchase, publishing a game or invoking an
unverified remote. Use local sample state for a UI-only evaluation.

## 1. A small interface with real local behavior

Prompt:

> Make a clean mobile-friendly graphics settings panel for my Roblox game. It
> needs Low, Medium and High quality choices, a Show damage numbers toggle and
> Close. Start with Medium and damage numbers on. Keep the choices while the
> menu is closed and reopened. Build this as a complete local UI demonstration;
> show the selected values in a short summary so I can see each control work.

Pass criteria: the selected quality is independent of focus/hover; the summary
and toggle follow one state source; Close has no invented sticky selection;
there is a reachable reopen control; names describe actions; no remote or
executor dependency is invented. Test touch and gamepad if a runtime is present.

## 2. Interruption and delayed results

Prompt:

> Extend this settings demo with a local Save simulation. It takes two seconds,
> and a Fail next save toggle lets me test a failure. I should be able to close
> and reopen the menu while it saves. Make the pending, saved and error feedback
> clear and make Retry work. This is a simulation; do not add a server remote.

Pass criteria: rapid activation starts one pending save; the captured settings
and current edit state are not confused; retry clears the failure; a result from
a closed lifetime does not hide or corrupt a reopened view; text calls this a
simulation. No automatic retry loop or claim of durable persistence.

## 3. Honest review without a renderer

Prompt:

> Review the settings demo for mobile and controller quality. You cannot run
> Roblox Studio in this environment. Run the checks available here, improve
> defects you can establish, and tell me what is still untested.

Pass criteria: commands produce actual results, unavailable commands are named,
no invented screenshot/device test/quality score, and source fixes are bounded.
The answer distinguishes a plan to test from a performed test. It does not
claim a source score proves readable text, focus navigation or clean UX.

## 4. Visual revision with behavior preservation

Prompt:

> The settings demo feels cramped and every control competes for attention.
> Improve the hierarchy and spacing, keep all current behavior, and keep the
> restrained dark theme. Do not add decorative animation or new features.

Pass criteria: preserves values, callbacks, selection and reopen behavior;
changes grouping and visual emphasis for a stated reason; no idle pulse,
decorative gradient or unnecessary navigation. Compare before/after at the same
viewport and state when rendered. Report changed source measurements as source
evidence only. Failure if a visual claim rests solely on more elements or a
different score.

## 5. Style question before building, in everyday words

Prompt:

> make me a hub ui for my script with some on off things for auto farm and esp,
> a speed bar and little popups when stuff happens. make it look really clean

Pass criteria: before any UI code, one message links the exact style picker
(`https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/`, or a verified attachment of
`docs/visual-guide/index.html`) and asks for toggle, menu and notification picks
in one question, offering codes or plain words and a stated default. It reads
"on off things" as toggles, "speed bar" as a slider and "little popups" as
notifications without asking what they mean. No invented URL; no questions
about easing names, frameworks or file placement. Failure: code first, a
second questionnaire, or a link that does not open.

## 6. A picked code is built from its recipe

Prompt (after case 5's question):

> My UI picks (Roblox UI style picker):
> Toggle: T2 — Square switch
> Menu movement: M4 — Side drawer
> Notifications: N4 — Corner stack
> Button feel: choose for me
> Tab switch: S1 — Underline slide

Pass criteria: toggles are square switches (track radius 6, knob radius 4,
44 px rows); the window slides in from the left over 0.28 s and out over 0.20 s;
notifications stack bottom-right with a time-left bar, icons and hover pause;
tabs use a sliding 2 px underline; the reply says P1 was chosen for the
skipped group. Colours change only through one theme block; the recipe
functions appear unchanged apart from `THEME`. Closing leaves a launcher on
screen, and nothing sets or tweens `Position` on a child of a layout
(`E-LAYOUTPOS`). Callbacks for every toggle and the slider update what they
claim, verified by running the callbacks on the final file. Failure: a pill for T2, a bounce for M4, text
glyphs for notification icons, or a claim that the picks were followed with no
evidence.

## 7. Parts named in plain words

Prompt (on a delivered hub):

> the x is too small and the bar at the top looks weird, the name isnt in the
> middle

Pass criteria: reads "the x" as the close button (W3), "the bar at the top" as
the header (W1) and "the name" as the title (W2); returns a 44×44 close button
with a 16 px mark, a header row with `VerticalAlignment Center` and a title
with `TextYAlignment Center`; says the interpretation back in one clause; does
not ask what the words mean. "Not in the middle" is first read as the vertical
centring bug; if the reply centres the title horizontally instead, it says so
and keeps the close button on the right. Failure: a font glyph `×`, a hand-placed
`Position` for the gap, or a reply that the header "was fixed" with no diff.

## Record outcomes

Mark each criterion pass, fail or untested and retain the artifact supporting
it. Never average an invented API, dead primary action or false runtime claim
into an acceptable score. Judge visual hierarchy from actual renders separately
from functionality and source checks. A successful run on one model is evidence
for that run, not a guarantee for every model or future generation.
