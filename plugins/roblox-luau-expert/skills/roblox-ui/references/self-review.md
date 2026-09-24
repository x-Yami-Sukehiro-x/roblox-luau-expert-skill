# Self-review — the countable rubric

`anti-slop-catalog.md` describes what generated UI looks like. This rubric makes
source checks repeatable; visual hierarchy, accessibility and working behavior
still require inspection. Do not convert a source score into a quality guarantee.

Run it before any UI leaves. Report the score. A score without the failing rows
named is not a report.

**Most of it is automated.** `tools/bin/lint-roblox-ui.mjs` counts the rows it
can decide from the file and exits 1 on any error:

```bash
node tools/bin/lint-roblox-ui.mjs src/UI/ShopMenu.luau
node tools/bin/lint-roblox-ui.mjs src/UI           # a whole directory
python tools/py/ui_lint.py src/UI/ShopMenu.luau    # the same rubric, no Node
```

It prints the counts, the score, and which rows failed. Run it and report that;
the rows it cannot decide — hierarchy, copy, the device pass — are below and
still yours.

---

## Hard gates — any failure means it is not finished

These are not points. Each one is independently disqualifying, because each one
produces a visible defect a player will hit.

| # | Gate | How to check |
|---|---|---|
| H1 | No colour literal outside the token block | Search `Color3.fromRGB`. One block, or zero |
| H2 | Root has a `UISizeConstraint` with min and max | Search `UISizeConstraint` |
| H3 | Nothing is positioned by hand inside a container of siblings | Search for sibling frames with explicit `Position` and no layout |
| H4 | Every tappable element is at least 44 px on its smallest side | Read the sizes and the `UISizeConstraint` minimums |
| H5 | `Activated` is used, not `MouseButton1Click` | Search both |
| H6 | `ScreenGui.ResetOnSpawn = false` on anything persistent | Search `ResetOnSpawn` |
| H7 | Every connection is stored and disconnected | Count `:Connect(` against the teardown |
| H8 | No information carried by colour alone | Every status colour paired with an icon or a word |
| H9 | Primary text contrast at least 4.5:1 on its surface | `node tools/bin/lint-ui-directions.mjs`, or compute it |
| H10 | Every list has an empty state | Name the frame |

---

## Counted checks — 32 points

Two points each. Count, compare, score.

| # | Count this | Pass |
|---|---|---|
| C1 | Distinct `TextSize` values | 3 to 5 |
| C2 | `TextScaled = true` assignments | 0 or 1 |
| C3 | Distinct corner radius values | exactly 2 |
| C4 | Frames carrying a `UIStroke`, as a share of all frames | under 50% |
| C5 | Distinct spacing values used | 3 to 6, all from 4 / 8 / 12 / 16 / 24 / 32 |
| C6 | Uses of the accent colour | 3 to 5 |
| C7 | Surface levels used | 2 or 3, plus at most one `overlay` |
| C8 | Interactive elements with all meaningful states accounted for | 100%; selected only where it has meaning |
| C9 | Distinct tween durations | 2 to 4 |
| C10 | Elements that are the largest type size on screen | exactly 1 |

### The layout half

C1–C10 ask whether the design language is consistent. L1–L5 ask whether the
code says what it means. They are separated because a file can pass every
count above and still be full of numbers that nothing reads.

| # | Count this | Pass |
|---|---|---|
| L1 | `Size` components a `UIFlexItem` or a pinned `UISizeConstraint` already decides | 0 |
| L2 | `TextYAlignment` that fights the parent layout; `ZIndex` on an only child; `Position` set or tweened on a child of a layout, which the layout ignores | 0 |
| L3 | Text-bearing elements parented before their `Text` is set | 0 |
| L4 | Font glyphs used as icons; asset ids nobody has verified | 0 |
| L5 | Notification lifetimes under 1.5 s; `ScreenInsets` and `IgnoreGuiInset` both set | 0 |
| L6 | Opaque children reaching the edge of a rounded container that is not a `CanvasGroup`; `UICorner` on a `ScrollingFrame` | 0 |

Every L row is a **dead decision** — a value written into the file that the
engine ignores, or one that contradicts a value beside it. They matter for the
same reason an unused variable matters: the next reader cannot tell which of
the two numbers is the one that works, so they change the wrong one.

`lint-roblox-ui.mjs` decides all six.

**Score: 2 points per pass, 32 maximum.**

| Score | Verdict |
|---|---|
| 32 | source rubric passes; finish rendered and behavior checks |
| 26–30 | name the failing rows and fix them before delivering |
| 18–24 | the build order was not followed; go back to the step the failures point at |
| under 18 | rebuild from `build-order.md` step 3 |

---

## Which failure means which step

The rubric is diagnostic. Each row maps to the step that produces it.

| Failing | Go back to |
|---|---|
| C1, C2 | build order step 6 — type scale |
| C3, C4 | step 7 — surfaces and strokes |
| C5 | step 5 — spacing rhythm |
| C6, C10 | step 4 — hierarchy |
| C7 | step 2 — surface count |
| C8 | step 8 — states |
| C9 | step 8 — motion |
| H1 | step 1 — direction |
| H2, H3, H4 | step 3 — structure |
| H10 | step 9 — non-happy states |
| L1, L2 | step 3 — structure. One thing decides each number |
| L3 | step 9 — the state before the data arrives is a state |
| L4 | `roblox-ui-components/references/icons.md` |
| L6 | `roblox-ui-components/references/outlines-and-dividers.md` |
| L5 | `roblox-ui-components/references/toasts.md` |

---

## Device pass

Four viewports, checked by resizing rather than by reasoning.

| Viewport | Watch for |
|---|---|
| 1920 × 1080 | panel absurdly wide — the max in `UISizeConstraint` is missing |
| 1280 × 720 | the common desktop case; this is the baseline |
| 800 × 600 | footers overlapping content |
| 390 × 844 portrait | text under 12 px, targets under 44 px, anything cut off |

On the phone viewport specifically:

- Is any control reachable only by hovering? Hover does not exist there.
- Does the topbar cover anything? `ScreenInsets = CoreUISafeInsets`.
- Are primary actions in the lower half, where thumbs rest?
- Is anything destructive under a resting thumb? Move it.

Measure targets after scaling, not only their declared size. Use the longest
real label and inspect empty/error states as well as populated screens. Complete
the applicable behavior sequences in `functional-proof.md`; a screenshot of an
idle screen does not exercise a request, focus return or teardown.

---

## The reading test

One subjective check, kept because it catches what counting cannot, and phrased
so it still has a definite answer.

**Read the interface's labels aloud in order.** Do they describe what the player
can do here, in the game's own vocabulary?

Failures this catches:

- `Settings` / `Options` / `Configuration` as three separate tabs. Those are the
  same word. Name them for what is inside: `Controls`, `Audio`, `Graphics`.
- `Confirm` on a purchase button. `Buy for 250 Gems` says what happens.
- `Submit` anywhere. Nothing in a game is submitted.
- `Item 1`, `Item 2` in a shipped list.
- A currency called `Currency` when the game calls it Gems.

Generic copy is the tell that survives every visual fix, because it is the one
part of the interface that cannot be inherited from a token file.

---

## Reporting it

Keep the report brief and distinguish the evidence. For example, only if each
action was actually performed:

> **Source review: 32/32, zero reported errors.**
> Rendered at all four listed viewports; longest label and empty state inspected.
> Ran open/close, selection and retry; gamepad and executor rerun remain untested.

A score you did not run the linter for is a guess. Run it, paste the failing
rows, fix them, run it again.

If a check fails and it is deliberate, say which and why in the same three lines.
A stated exception is fine; an unmentioned one reads as an oversight.

---

## Reporting a redesign

A score is the wrong instrument for "redesign this". A panel can go from 30/32
to 32/32 by one added `UISizeConstraint` and still be the same panel, which is
how a reply comes to say the interface was redesigned when the interface was
not.

```bash
node tools/bin/lint-roblox-ui.mjs --compare old/Panel.luau new/Panel.luau
```

It prints the structural rows beside the score:

```
  elements               29 -> 41
  distinct TextSize       2 -> 3
  distinct radii          2 -> 2          unchanged
  spacing set     [8,12,16] -> [4,8,12,24]
  colour literals        10 -> 14
  connections            12 -> 18

  6/8 rows moved, 5 of them structural.
```

Report the changed rows as source evidence, then compare the rendered views at
the same viewport and state. Equal counts can hide a rearranged hierarchy;
changed counts can describe a worse layout. Neither number alone proves a
redesign improved the player's task. If rendering is unavailable, say so and
describe the specific layout decisions without claiming visual verification.

Two things that are *not* a redesign, and are both commonly delivered as one:
renaming the variables, and re-indenting the construction calls.
