# Build order

A fixed procedure for constructing any Roblox interface. Follow it in order.
Each step ends in a **gate** — a question answerable yes or no without design
judgement. A no means fix it now, not later.

The defaults settle routine measurements. The user's task and existing project
still decide the content and hierarchy. A small UI needs a small implementation;
do not add dummy sections or controls to satisfy a count.

---

## Step 0 — Read before writing

State what the player can accomplish in one sentence. Identify the primary
action and its result, the source of displayed values, and how the player opens,
closes and returns to this view. For a supplied screenshot or script, preserve
the useful content and working behavior before changing its presentation.

If the project already has UI, open one existing file and record:

- its colour source (a `Tokens`-like module, a `StyleSheet`, or literals)
- its corner radius
- its spacing values
- its font
- how it names instances

**Gate 0:** can you name the player's task, the primary action's real effect,
and the project's existing radius and spacing unit?
If yes, use them and skip step 1. If there is no existing UI, continue.

Matching an existing convention beats every rule in this file. A correctly
designed panel that matches nothing around it is a worse result than a plainer
one that fits.

---

## Step 1 — Pick the direction

From `design-directions.md`. If the user expressed no preference, the answer is
**Slate**. If they named a colour, keep a direction's structure and substitute
only the accent.

Copy the direction's `PRIMITIVE` block into `Tokens.luau` — or, if not using the
library, define the same nine neutrals, three accents and one spacing unit as
constants at the top of the file.

**Gate 1:** is there exactly one place in the code where a colour literal
appears? If a `Color3.fromRGB` call exists anywhere below that block, move it.

---

## Step 2 — Establish the surface count

Decide how many surface levels this interface has. **Two or three. Never more,
never one.**

| Surfaces | Use for |
|---|---|
| 2 (`page`, `base`) | a HUD, a single panel, a toast |
| 3 (`page`, `base`, `raised`) | a menu with controls in it, a shop, a settings screen |
| +`overlay` | only the modal or dropdown currently on top — never two at once |

Write them down before building anything. Every frame you create afterwards gets
assigned to one of them, and a frame that does not fit a level is a frame that
should not exist.

**Gate 2:** does every `Frame` in the plan map to one named level?

---

## Step 3 — Structure before appearance

Build the whole hierarchy with **no colours, no corners, no strokes, no
gradients**. Plain frames, correct sizes, correct layouts.

```
ScreenGui                       ResetOnSpawn = false, ScreenInsets = CoreUISafeInsets
└── Root                        the panel: fromScale size, AnchorPoint 0.5, UISizeConstraint
    ├── Header                  fixed height, UIListLayout Horizontal
    ├── Body                    UIFlexItem FlexMode = Fill, so it absorbs the remainder
    └── Footer                  fixed height, UIListLayout Horizontal
```

Rules, applied without exception:

- `UDim2.fromScale` for anything that should grow; offset only for hairlines,
  icon boxes and minimum control heights.
- `UISizeConstraint` on the root, always. Min and max both set.
- `UIListLayout` or `UIGridLayout` for every container with more than one child.
  `SortOrder = Enum.SortOrder.LayoutOrder`, and every child gets a `LayoutOrder`.
- `UIPadding` on every container that holds text or a list.
- `AutomaticSize` where content decides the size, and then no explicit `Size` on
  that axis.

**Gate 3:** inspect the hierarchy for conflicting size owners, then resize in
Studio at the viewports in `self-review.md`. Does anything overflow, overlap,
or collapse to zero? A mental estimate is a source review, never a device test.
Without a renderer, report this gate as untested and continue the checks you can
run. Appearance applied to broken structure is wasted work.

---

## Step 4 — Assign hierarchy

Name the **one** element on this screen that matters most. There is always
exactly one: the primary action, the player's balance, the current objective.

Give it at least two of these three, and give it to nothing else:

- the largest type size on screen
- the accent colour
- the most surrounding space

Everything else steps down. A secondary action is the same size in a quieter
colour. Tertiary is smaller and quieter still.

**Gate 4:** cover the screen and uncover it. What do you see first? If the answer
is "everything at once" or "the background", step 4 is not done.

---

## Step 5 — Apply spacing rhythm

Every gap and pad comes from the scale: **4, 8, 12, 16, 24, 32**. No other
number appears.

Assign by relationship, not by habit:

| Between | Gap |
|---|---|
| a label and its own control | 4 |
| two rows in the same group | 8 |
| two controls side by side | 12 |
| a group and the next group | 24 |
| panel edge and its contents | 16 |
| page edge and the panel | 32 |

The rule underneath: **related things closer, unrelated things further.** A
section gap that is the same as a row gap throws away the only grouping signal
the player gets for free.

**Gate 5:** list every distinct spacing number in the file. Are they all on the
scale, and are there at least three different ones? One value used everywhere is
catalog tell R6.

---

## Step 6 — Type scale

Five sizes maximum, from the direction: caption / body / emphasis / title /
display.

- `TextScaled = false` on everything that is a sentence or a label.
- `TextScaled = true` on exactly one thing: a single number or word that must
  fill a fixed badge regardless of digit count.
- `UITextSizeConstraint` on anything that scales, `MinTextSize` 12 or above.
- Body text at 14. Captions at 12 and nothing smaller.
- Numbers that update in place need consistent digit width, or they jitter —
  keep the label a fixed width and right-align rather than letting it resize.

**Gate 6:** count the distinct `TextSize` values in the file. Five or fewer, all
from the scale? Count the `TextScaled = true` assignments. Zero or one?

---

## Step 7 — Surfaces, strokes and depth

Now apply appearance, in this order:

1. **Background colours** from the levels chosen in step 2.
2. **Corner radius** — the direction's two values. Controls get one, panels get
   the other. Nothing gets a third.
3. **Stroke** — the direction's stroke policy, and nothing beyond it. In most
   directions that means a border on panels and none on controls.
4. **Depth** — `UIShadow` on at most two elevations, and only one element on
   screen at `overlay`.

The rule that prevents the default card look: **a container and a control must
not be the same object with different children.** If every frame has the same
radius, the same 1px stroke and the same fill step, nothing has rank. Separate
them with background step and space, then add an edge to the one thing that
genuinely needs one.

**Gate 7:** how many distinct corner radii are in the file? Two. How many frames
have a `UIStroke`? Fewer than half. How many elements sit at `overlay`? At most
one.

---

## Step 8 — States, then motion

Account for all six states before anything gets animated. Persistent selection
applies to tabs, toggles and chosen rows; a one-shot action such as Close has no
selected value. Loading is additional state for asynchronous work.

| State | Must differ visibly |
|---|---|
| rest | the baseline |
| hover | background one step up |
| press | background one step down, plus a `UIScale` of about `0.97` |
| focus | a visible ring — `UIStroke` with `BorderStrokePosition = Outer` on a panel, `Inner` inside anything that clips (`clipping.md`) |
| disabled | `Interactable = false`, muted text, reduced background |
| selected | accent applied, and a shape or weight change as well as colour |

Then motion, and only these three:

- open: 0.20 s, Cubic, Out
- close: 0.15 s, Cubic, In
- press feedback: 0.08 s, Quad, Out

Nothing else moves. No idle loops, no pulsing, no rotating gradients. If a value
can change mid-motion — a panel being dragged, a bar following a live number —
use a spring instead of a tween, because a restarted tween discards velocity and
snaps. See `../../roblox-ui-motion/references/springs-and-smoothdamp.md`.

Honour reduced motion: read `GuiService.ReducedMotionEnabled` at startup and
observe its property changes. Collapse travel and stagger when enabled; the
element must still reach its final state. Own and disconnect that listener.

**Gate 8:** pick any button in the file. Can you point at the line that changes
its appearance for each meaningful state and explain any non-applicable state?
`AutoButtonColor` does not count — it only tints, and it fights every state you
set yourself.

---

## Step 9 — Non-happy states

Build these now, not when they are reported as bugs.

| State | What it needs |
|---|---|
| loading | a visible indicator, not a blank panel |
| empty | a sentence saying why it is empty and what to do |
| error | what failed, and a retry control |
| too many | search or paging once a list can exceed about 30 rows |
| disabled / locked | the requirement shown, not just a greyed control |
| offline | the connection went away mid-interaction |

**Gate 9:** can you trigger each applicable state and recover from it? An error
label that no failure path shows, or a retry button with no callback, fails.
Follow `functional-proof.md` for delayed responses, stale results and closing
during a request. Local-only controls do not need invented network requests.

---

## Step 10 — The mechanical review

Run `self-review.md` and report the score the tool actually prints. Its source
checks locate defects; they cannot determine whether the interface works or
looks good when rendered.

```bash
node tools/bin/lint-roblox-ui.mjs <the file you just wrote>
```

**Gate 10:** the counter run, its output reported, zero errors or named deliberate
exceptions. Separately report rendered viewports and executed interactions from
`functional-proof.md`. An unavailable test stays untested; it is not a pass.

---

## What this procedure does not decide

- What the interface is *for*. That comes from the request.
- The copy. Write labels that say what will happen — `Buy for 250 Gems`, not
  `Confirm`.
- Which content is on which tab.

The measurements above are the defaults. Content grouping, useful feedback and
the player's next action still require a decision grounded in this game.
