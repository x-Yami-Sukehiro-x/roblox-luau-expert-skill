---
name: roblox-ui-from-scratch
description: Building a whole Roblox UI from a vague or one-line prompt - real content, the flow, every state. Use for make me a gui.
---

# UI from a short request

Use for a new screen or a substantial redesign when the user has supplied
little direction. A small edit stays with the skill that owns the component.
Read `../roblox-ui/SKILL.md` for the shared palette, layout and input rules;
this skill decides what the screen should contain and how someone uses it.

## Turn the available evidence into a screen

Start with the user's task, existing script and any screenshot. Identify the
surface (game UI, executor hub or Studio plugin), the most frequent action,
the state needed to perform it, and the result the player should see. A
screenshot supplies visual evidence; it does not prove a callback exists.

Write a short working brief in `PROJECT_CONTEXT.md`: purpose, real controls,
existing style choices, unproved behavior and the checks that would show it
works. Keep it proportional: a three-control menu needs a few lines.

- Infer labels and controls from actual functions, settings and source facts.
  Do not fill space with fake farms, invented remote calls or unsupported tabs.
- If the request only says "make me a GUI", a working shell can open, close,
  reopen and explain that no features are connected. Name that scope in the
  reply; do not present it as a functioning game script.
- If two plausible purposes need different builds, combine the one essential
  question with unresolved visual choices. Use the existing grouped guide in
  `../roblox-request-intake/references/visual-choices.md`. Prior choices and
  "choose for me" already settle it; do not restart the questionnaire.
- Match the project before choosing defaults. Translate "premium" into
  readable grouping, consistent states and dependable feedback, not a larger
  feature list, a glowing logo or copy that makes unproved claims.

Three vague requests worked through to a brief (an executor hub from a
script, a game shop from an item module, a farming UI with no file at all)
are in [worked-briefs.md](references/worked-briefs.md).

## Arrange actions before styling them

Follow `../roblox-ui/references/build-order.md` using the nearest layout in
`../roblox-ui/references/blueprints.md`. Decide these from the content:

| Decision | Evidence that earns it |
|---|---|
| A visible primary action | The screen has one task the user is trying to finish |
| Several sections | Different jobs or dependencies, not equal numbers of rows |
| Tabs | Groups need separate space; a short list does not need navigation |
| Search | A long, changing list makes locating a known item difficult |
| A row description | A limit, consequence or prerequisite the label cannot express |
| A configuration panel | Repeated preferences worth keeping; see `roblox-script-feedback` |

Keep a hub's ordinary controls quiet. Preserve one clear type hierarchy without
making an arbitrary toggle a primary action. Place dependent controls beside
the setting they affect; show why an unavailable action cannot run.

For each control, name its input, state owner, effect and visible result.
Selection is persistent state; hover and focus are temporary. Closing the
window, disabling a feature and unloading the script are different actions.
Provide a reachable reopen control if Close only hides the window.

## Build on the working recipes

Use the user's selected recipe from
`../roblox-ui-components/references/style-recipes.md`; preserve its behavior
and change theme tokens where permitted. Compose real callbacks around it.
A script hub uses `../roblox-hub-library/SKILL.md` instead of inventing a second
control framework. Keep source functions and UI state separate so a layout
change does not rebuild or restart features.

Before assembling many controls, use `roblox-register-budget` to choose scoped
builders and state tables. Compile the delivered bundle: compiling separate
modules does not establish that their combined chunk fits.

Build the empty, unavailable, waiting and failed states that can occur in this
screen. Do not add artificial network delays or Retry buttons with no retry
operation. Notifications follow `../roblox-script-feedback/SKILL.md`.

## Prove the task, then judge the appearance

Run `node tools/bin/check-file.mjs <file>` on the actual final file and resolve
observed failures. Exercise that file's real callbacks using the available
Luau mocks; assert the state and every dependent label/value after each action.
Follow `../roblox-ui/references/functional-proof.md` for what those checks prove.

Use `roblox-ui-viewport` and `roblox-ui-interaction` to check the small landscape
phone, portrait where supported, baseline desktop and large desktop. Include
long labels, a long list scrolled to its last row, an open popup near an edge,
resize while open, close/reopen and unload. When applicable, test a pending
action that completes after close or unload; its result must belong to the
current lifetime before touching the UI.

If Studio is available, operate the controls and inspect the rendered result.
Without it, report source checks, computed fit and mocked callbacks separately;
actual rendering, touch gestures and controller navigation remain unverified.
Never call a linter score a visual-quality score.

## Works with

- `roblox-request-intake`: the grouped preference question and useful defaults.
- `roblox-ui`: tokens, layout order and the shared rubric.
- `roblox-ui-components`: recipes with established input and state behavior.
- `roblox-ui-viewport`: bounds, scrolling, popups and clipping.
- `roblox-ui-interaction`: keyboard, touch and gamepad behavior.
- `roblox-ui-ux-review`: an evidence-based review of the finished task flow.
- `roblox-script-feedback`: state messages and preferences that earn their place.
- `roblox-register-budget`: headroom in the final assembled script.
- `roblox-ux-design`: the flow and a structure where nothing gets clipped.
- `roblox-copy-craft`: labels and descriptions without generated phrasing.
