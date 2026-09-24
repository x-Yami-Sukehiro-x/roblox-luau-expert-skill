<!-- GENERATED FILE - do not edit.
     Source: .claude/skills/ (source paths below)
     Rebuild: node tools/bin/build-portable.mjs
     Verify:  node tools/bin/build-portable.mjs --check -->

# Style pack

Read this before building or restyling UI. It holds the style picker question, the everyday words users say, what each picked code (T1-T10, M0-M12, N1-N10, O1-O5, P1-P3, S1-S3) builds, and the tested recipe for every code in full. Recolour a recipe only through its THEME block.

## Source: .claude/skills/roblox-request-intake/references/visual-choices.md

# Ask with examples, not design vocabulary

For new UI or a requested visual redesign, offer one grouped preference question
when toggle, motion or notification styles are unresolved. Do not ask again if
the user already chose, supplied a reference, asked you to decide, or wants an
existing interface matched. A bug fix does not need a style questionnaire.

## The guide and its link

The guide is the **Roblox UI style picker**: playable, labeled examples of ten
toggles (T1–T10), thirteen menu movements (M0–M12) picked separately for
opening and closing, ten notification styles (N1–N10), five ways to hide and
bring back the whole UI (O1–O5), three button feels (P1–P3), three tab switches
(S1–S3) and a window diagram that numbers its parts (W1–W22). The user picks,
presses **Copy my picks**, and pastes a summary such as
`Opening: M3 — Gentle pop`.

- **Hosted link:** <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>. Use this
  exact URL. It is a public GitHub Pages site that anyone can open, rebuilt
  from `docs/visual-guide/index.html` on every push.
- **Offline copy:** `docs/visual-guide/index.html` in this repository, the GPT
  knowledge file `roblox-ui-style-picker.html`, and the plugin's
  `skills/roblox-request-intake/assets/roblox-ui-style-picker.html`. Offer it
  when the user says the hosted link does not open or asks for the file. In a
  GPT, find the knowledge file under `/mnt/data/` with Code Interpreter (or
  extract it from the ZIP), verify it exists, and link the real attachment:
  "Download and open this in your browser". Elsewhere, attach or give the path.
- Never invent another URL, and never claim a private page is public.
- If neither link is available, describe the options in plain words below; do
  not pretend the user saw an animation, and do not stall unrelated work.

## The question

Ask once, in one message, with the link first:

> Before I build it: open the style picker (link) and pick the toggle, how the
> menu opens and closes, and the notification you like — then paste your picks
> here. Or just describe it in your own words, or say "choose for you". My
> suggestion is **T1 + M1 + N1 + O1** (for a script hub, **N4** for
> notifications).

**The question is the final reply of the turn**, with the hosted link written
out in it. Hosts such as ChatGPT fold progress notes away, so a link placed in
an early note and followed by "checking the guidance…" is a link the user never
sees. Stop there: build nothing until they answer or say "choose for you".
Ask through the host's question tool where available. Source inspection and
the task contract can happen in the same turn, before the question. If the
preference is optional and no answer arrives, use the stated default and never
claim it was the user's choice. Record picks in `PROJECT_CONTEXT.md` or the
portable context record, and carry them into every later edit of that UI.

## Reading the answer

Each code has one exact build in
`../../roblox-ui-components/references/style-recipes.md`, with a tested recipe
in `../../roblox-ui-components/assets/`. Build from the recipe; recolour only
through its `THEME` block.

Users also answer in their own words. Map them, say the mapping back in one
clause, and ask only if two readings produce different work:

| They say | Code |
|---|---|
| little sliding pill, iPhone switch | T1 |
| boxy / square switch | T2 |
| checkbox, square with a tick | T3 |
| two buttons, off and on side by side | T4 |
| button that lights up, stays pressed | T5 |
| eye icon, icon that switches | T6 |
| switch with a tick in the circle | T7 |
| switch with ON / OFF written in it | T8 |
| little light that turns on | T9 |
| round tick, circle checkbox | T10 |
| no animation, just appear | M0 |
| fade, gently appears | M1 |
| slides up a little | M2 |
| little pop, zooms in a bit | M3 |
| slides in from the side | M4 |
| opens out of the button | M5 |
| bouncy, springy | M6 |
| slides in from the right | M7 |
| comes up from the bottom, phone sheet | M8 |
| drops down from the top | M9 |
| zooms in toward me | M10 |
| bounces up a little | M11 |
| rows come in one by one | M12 |
| message at the bottom | N1 |
| message near the top | N2 |
| next to what I changed | N3 |
| popups stacked in the corner, like most script hubs | N4 |
| bar across the top that stays | N5 |
| popup in the middle, "are you sure" | N6 |
| popups in the top corner | N7 |
| one small line at the top that swaps | N8 |
| loading, then done | N9 |
| popup with an undo button | N10 |
| close it and a button brings it back | O1 |
| shrink into the button, minimise | O2 |
| fold up to the title bar | O3 |
| a tab on the side to pull it back | O4 |
| loading screen before the hub | O5 |
| changes colour when pressed | P1 |
| pushes in, clicky | P2 |
| lifts on hover | P3 |
| line under the tab | S1 |
| pill behind the tab | S2 |
| just highlight the tab | S3 |

Mixed answers are normal: "T1 but square" is T2; "M2 with less movement" is M2
at 8 px; "like N4 but at the top" is N7. "Pop in, fade out" is opening M3 and
closing M1 — one presenter with a separate `closeStyle`. For names of
window parts and words like "cleaner" or "make it pop", use `ui-words.md`.
Never ask someone to choose Cubic versus Quint or supply spring constants.

## Preserve function while changing style

Keep callbacks, selected values, keyboard/gamepad focus and touch activation
independent of the skin. Selected is persistent for a toggle or tab, not a
one-shot button. Hover must not erase focus, and refresh must not erase the
active state. An action button updates its own appearance, not a different
toggle's knob. Test focus on the launcher, close, each choice and toggle
separately.

One current owner per animated property; rapid open/close cannot let a stale
completion hide a new view. Cancel active animations on unload. Reduced motion
overrides the chosen style and still applies the final state. The guide
communicates intent; it does not prove Roblox geometry, engine timing or
accessibility behavior.

Notifications use the panel's surface entry. Show what happened with text and
an icon, queue bursts, bound the visible count, reflow smoothly and keep
primary controls clear. Time lifetime from arrival, pause for interaction, and
keep actionable errors until dismissed or resolved. Test a long message, a rapid
burst, dismissal during entrance, reflow and unload with pending timers.

---

## Source: .claude/skills/roblox-request-intake/references/ui-words.md

# UI words people use, and what they mean

Users describe interfaces by what they see, not by class names. Read the
description, pick the matching part, and say back the interpretation in one
short clause: "the X in the corner — the close button — is now 44 px". Ask only
when two readings would produce different work. Never correct the user's word.

The guide's "Point at it" diagram numbers these parts, so a user can answer
"W3" instead of finding a word.

## Parts of a window

| Code | They might say | It is | Build notes |
|---|---|---|---|
| W1 | "the bar at the top", "top part" | header | one horizontal row: title, slack, controls |
| W2 | "the name at the top", "the heading" | title | largest type, `TextYAlignment Center` |
| W3 | "the X", "exit button", "close thing" | close button | 44×44 button, 16 px image mark |
| W4 | "the dash", "hide button", "make it small" | minimise button | same size as close; collapses to the launcher |
| W5 | "the bit you grab to move it", "drag bar" | drag handle | whole header drags; grip icon optional |
| W6 | "the side menu", "list on the left" | sidebar / tab rail | vertical tabs; selection persists |
| W7 | "the pages", "sections", "categories" | tabs | see S1–S3 |
| W8 | "the little titles", "group names" | section heading | 12 px caption, muted, above a group |
| W9 | "on/off thing", "switch", "tick" | toggle | see T1–T6 |
| W10 | "the bar you drag", "number bar", "range" | slider | shows its value; arrow keys and gamepad step it |
| W11 | "list that opens", "picker", "choose one" | dropdown | closes on outside tap; long lists scroll |
| W12 | "the button" | button | label names the action: `Teleport to spawn` |
| W13 | "key box", "hotkey", "bind" | keybind chip | shows the key; press to rebind; Escape cancels |
| W14 | "search bar", "find box" | search box | filters as they type; clear button |
| W15 | "typing box", "where I put the name" | text box | placeholder, focus ring, inline error (N3) |
| W16 | "popup message", "alert", "notification" | toast / notice | see N1–N6 |
| W17 | "the hint when I hover" | tooltip | never the only place information lives; phones have no hover |
| W18 | "scroll thing" | scrollbar | thin, only where content overflows |
| W19 | "dark background behind the popup" | backdrop / scrim | dims the game; a tap on it cancels |
| W20 | "button that opens the menu", "toggle UI button" | launcher | stays on screen when the window is closed |
| W21 | "colour wheel", "pick a colour" | colour picker | preview swatch plus hex or RGB entry |
| W22 | "little tag", "badge", "label pill" | badge | status word plus colour, never colour alone |

## Words about how it looks or feels

| They say | Usually means | Do |
|---|---|---|
| "cleaner", "less cluttered" | fewer elements, more space | remove borders on inner blocks, widen spacing one step, merge duplicate labels |
| "make it pop" | contrast, not more colour | one accent element, larger title, darker page behind a lighter panel |
| "more modern" | restraint and consistent radius | two radii, one accent, no gradients on every surface |
| "rounder" | corner radius | raise panel radius, keep controls smaller than panels |
| "smoother" | motion that does not jump | Out easing, interruption continuity, no restart snaps; ask only if unclear |
| "snappier", "faster" | shorter motion | 0.12 to 0.20 s; M1 or M0 |
| "less busy" | fewer things moving at once | fade content, move only the container |
| "bouncy", "springy" | a settle, not a cartoon | M6, one overshoot |
| "glassy", "blurry background" | translucency | Roblox GUI has no backdrop blur; a translucent surface over a darker scrim is the honest version, and say so |
| "glow", "neon" | an accent edge | accent `UIStroke` on the one focal element, not everywhere |
| "like Apple" | quiet, pill switches, soft fades | T1, M1, P1, S2 |
| "like a game menu" | bold, big type, press feedback | P2, S1, larger title |
| "match my UI", "same style as this" | reuse their tokens | read their colours, radii and fonts from the provided script first |
| "the colours are off", "doesn't match" | surfaces or toasts using other values | one token entry per surface; toasts share the panel's entry |
| "it's too big on my phone" | fixed offsets or missing size bounds | `UISizeConstraint` with both bounds; test at 390×844 |
| "the title looks off" | vertical alignment | header row `VerticalAlignment Center`, title `TextYAlignment Center` |

## When the words do not match anything here

Describe the two closest readings in plain words and offer the guide:

> Do you mean the bar across the top of the window, or the message that pops up
> at the top of the screen? The guide's "Point at it" picture numbers both —
> W1 and N2.

---

## Source: .claude/skills/roblox-ui-components/references/style-recipes.md

# Style recipes: what each guide label builds

The visual guide (hosted at <https://x-yami-sukehiro-x.github.io/roblox-luau-expert-skill/>,
offline copy `docs/visual-guide/index.html`) shows every option with a code:
**T** toggles, **M** menu movement (opening and closing can differ), **N**
notifications, **O** how the whole UI hides and comes back, **P** press feel,
**S** tab switch, and **W** for the parts of a window. When a user answers
"T2 + M4 + N4", that answer is a contract. This file says exactly what each code
builds and which tested recipe builds it.

The recipes live beside this file in `../assets/`. Each is one self-contained
file with its own `THEME` block, so a single-file LocalScript or executor script
can paste the part it needs above the UI build. Every recipe is run by
`node tools/bin/run-recipe-tests.mjs` against the engine stubs and scores full
marks on the slop, format and UI rubrics.

## Rules for using a recipe

1. **Paste the recipe, do not rewrite it.** Copy the recipe's functions into
   the script unchanged and call them. The label means these numbers: a "T2"
   built as a pill, or an "M3" that bounces three times, is not what the user
   chose. On 23 September 2026 a lighter model that rewrote the recipes instead
   of pasting them shipped a toast slide-in that never moved, a tab underline
   that blinked instead of sliding, a focus ring drawn on the whole panel, and
   error toasts that vanished after three seconds.
2. **Recolour only through `THEME`.** Replace its values with the project's
   palette, or the user's named colour. Keep sizes, timings and state logic.
3. **Keep one owner per animated property.** The recipes already cancel and
   ticket their own tweens; do not add a second tween on the same property.
4. **Reduced motion is built in.** Each recipe reads
   `GuiService.ReducedMotionEnabled` and keeps the final state without travel.
5. **Prove the wiring on the final file.** A recipe proves itself, not your
   adaptation. After adapting, run the callbacks against the real script
   (`../../roblox-ui/references/functional-proof.md`).

If the user gave no answer and asked you to decide, use **T1 + M1 + N1 + O1 +
P1 + S1**; for an executor hub use **N4** instead of N1. Say which you used,
once.

## Toggles — `../assets/toggles.luau`

`createToggle(parent, label, style, initial, onChanged)` returns
`{ row, set, get, setEnabled, destroy }`. Every row is 44 px tall so the whole
row is the touch target, and each style shows state by shape or words as well
as colour.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| T1 | "little sliding pill", "iPhone switch" | sliding switch | track 44×24 pill, knob 18, knob x 3 → 23, 0.12 s Quad Out |
| T2 | "boxy switch", "square slider" | square switch | as T1, track radius 6, knob radius 4 |
| T3 | "checkbox", "square with a tick" | tick box | box 22×22 radius 6, 2 px edge, tick image 16 grows 0.8 → 1 |
| T4 | "two buttons", "Off / On buttons" | segmented choice | group 112×36, indicator slides behind the chosen word; each half is its own button |
| T5 | "button that lights up", "stays pressed" | lit row | whole row takes the dim accent, edge turns accent, `ON` / `OFF` word |
| T6 | "eye icon", "icon that switches" | icon toggle | 32 px badge, 16 px eye / eye-off image, badge fills with accent |
| T7 | "tick in the circle", "switch with a check" | knob icon switch | T1 track; a 12 px tick (on) or cross (off) image inside the knob |
| T8 | "switch with words in it", "ON OFF slider" | word switch | track 56×24 pill, `ON` / `OFF` inside on the side the knob left, knob x 3 → 35 |
| T9 | "little light", "dot that turns on" | status light | 8 px dot plus `ON` / `OFF` word at the end of the row |
| T10 | "round tick", "circle checkbox" | round tick | T3 in a 22 px circle, tick 14 grows 0.6 → 1 |

Pressing the half of T4 that is already chosen leaves the value alone. T5 is
the only style where the row colour carries state; its word does too.

## Menu movement — `../assets/menus.luau`

`createPresenter(panel, openStyle, { closeStyle = ..., rows = ... })` takes the
window's outermost `CanvasGroup` and returns `{ open, close, isOpen, destroy }`.
Opening and closing are picked separately: "open with M3, close with M1" is
`createPresenter(panel, "M3", { closeStyle = "M1" })`. Entrances use Out easing;
exits use In easing and travel less.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| M0 | "just appear", "no animation" | instant | `Visible` only |
| M1 | "fade in", "gently appears" | fade | `GroupTransparency` 1 → 0, 0.20 s Cubic Out; out 0.15 s Cubic In |
| M2 | "slides up a little" | short rise | starts 12 px low with the fade; leaves 8 px low |
| M3 | "little pop" | gentle pop | `UIScale` 0.96 → 1 with the fade; leaves at 0.98 |
| M4 | "slides in from the side" | side drawer | from its own width + 24 px off the left, 0.28 s Out; out 0.20 s In; opaque |
| M5 | "opens out of the button" | grow from origin | `AnchorPoint` on the side facing the launcher; `UIScale` 0.9 → 1 with the fade; leaves at 0.95 |
| M6 | "bouncy but not cartoony" | settle | `UIScale` 0.94 → 1, 0.32 s Back Out: one small overshoot, no repeat |
| M7 | "slides in from the right" | right drawer | M4 mirrored: from its own width + 24 px off the right |
| M8 | "comes up from the bottom", "like a phone sheet" | bottom sheet | from its own height + 24 px below, 0.28 s Out; out 0.20 s In; opaque |
| M9 | "drops down from the top" | top drop | M8 from above |
| M10 | "zooms in toward me" | zoom settle | `UIScale` 1.06 → 1 with the fade; leaves at 1.03 |
| M11 | "bounces up a little" | springy rise | 24 px rise on 0.32 s Back Out, one overshoot; leaves 8 px low |
| M12 | "the rows come in one by one" | cascade | M2-style 8 px rise, then each row (a `CanvasGroup` in `rows`) fades in 0.03 s apart, 0.25 s cap |

Every style needs a way back: when the window closes, a launcher button (W20)
stays on screen. A keybind alone strands a phone player. Reopening during a
close continues from where the panel is, and a stale close can never hide the
reopened panel. A panel dragged while open keeps its new
position. With reduced motion every style becomes a 0.08 s fade. A `UIScale`
used for screen-size scaling belongs on a parent frame, not on the panel.

## Notifications — `../assets/toasts.luau` and `../assets/notices.luau`

Every notification shares the panel's surface entry: the same fill, edge and
10 px radius. Each carries an icon image as well as a hue, holds at least
1.5 s from arrival, and stays readable for 3 to 8 s by word count. Errors stay
until dismissed and get a 44 px dismiss button with a 16 px mark.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| N1 | "message at the bottom" | bottom toast | `createNotifier(screen, "N1")`: bottom centre, stacks upward, arrives from 12 px below |
| N2 | "message near the top" | top notice | `createNotifier(screen, "N2")`: top centre, stacks downward, arrives from 8 px above |
| N3 | "next to what I changed" | inline message | `createInlineMessage(parent, order)`: a reserved 20 px row, so nothing below moves |
| N4 | "popups stacked in the corner" | corner stack | `createNotifier(screen, "N4")`: bottom right, arrives from 24 px right, 2 px time-left bar |
| N5 | "bar across the top" | banner | `createBanner(screen)`: stays while a condition lasts, such as reconnecting |
| N6 | "popup in the middle", "are you sure?" | alert | `confirmAlert(screen, spec, onChoice)`: dims the game, buttons name the action |
| N7 | "popups in the top corner" | top-right stack | `createNotifier(screen, "N7")`: N4 anchored top right, stacks downward |
| N8 | "small status at the top", "one line that swaps" | compact status | `createCapsule(screen)`: one 36 px bar under the top bar; a new message replaces the old |
| N9 | "loading, then done" | progress toast | `notifier.progress(message)` spins a loading icon until `:done(result, severity)`; a failed result stays with a dismiss button |
| N10 | "popup with an undo button" | action toast | `notifier.action(message, "Undo", onUndo)`: holds at least 6 s, the button names the action and runs it once |

The stacked styles (N1, N2, N4) show three at a time, queue up to ten, collapse
a repeated `key` into `×2`, pause while hovered and reflow with a spring when a
middle toast leaves. Put the `ScreenGui` on `ScreenInsets = CoreUISafeInsets`
and `ResetOnSpawn = false`. N6 is only for something the player must answer:
its dim layer counts a tap outside as Cancel, and gamepad focus starts on the
safe choice.

## Hiding and bringing back the whole UI — `../assets/windows.luau`

`createWindow({ panel, launcher, header, body, opener }, style)` returns
`{ show, hide, toggle, isShown, destroy }`; wire the close or minimise button
and the keybind to `hide` / `toggle`. Every style leaves a way back on screen,
because a keybind alone strands a phone player.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| O1 | "close it, button to reopen" | close to launcher | runs the chosen M close through `opener`, then shows the launcher; the launcher opens it again |
| O2 | "shrink into the button", "minimise" | minimise into launcher | `UIScale` to 0.2 while travelling to the launcher's centre, 0.24 s In; grows back 0.28 s Out |
| O3 | "fold up to the title bar" | collapse to header | body fades, panel height folds to header + 24 px; unfolds on the same button |
| O4 | "tab on the side to pull it back" | edge pull tab | slides off the left edge; a 44×64 tab with a chevron image brings it back |
| O5 | "loading screen before the hub" | intro card | `playIntro(screen, title, onDone)`: 28 px title and a 2 px accent line that grows to 120 px, 0.6 s hold, returns `skip` |

## Press feel — `../assets/press-and-tabs.luau`

`attachPress(button, style)` returns a cleanup function.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| P1 | "changes colour when I press" | colour shift | hover lighter over 0.12 s, press darker over 0.08 s |
| P2 | "pushes in" | press-in | P1 plus `UIScale` 0.97 while held |
| P3 | "lifts when I hover" | lift | `UIScale` 1.02 and a visible edge on hover, 0.98 on press |

## Tab switch — `../assets/press-and-tabs.luau`

`createTabs(parent, names, style, onSelect)` returns `{ select, selected,
destroy }`. The selected tab persists; focus and hover never change it.

| Code | People say | What it is | Exact build |
|---|---|---|---|
| S1 | "a line under the tab" | underline slide | 2 px accent marker slides to the chosen tab, 0.20 s Cubic Out |
| S2 | "a pill behind the tab" | pill slide | full-height rounded marker slides behind the chosen tab |
| S3 | "just highlight it" | highlight only | colour and weight change, nothing travels |

## Window parts — the W codes

The guide's "Point at it" diagram numbers the parts of a hub window so a user
can say "make W3 bigger" instead of hunting for the word. The names and the
everyday words for each are in
`../../roblox-request-intake/references/ui-words.md`.

---

## Recipe: .claude/skills/roblox-ui-components/assets/menus.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

type FirstStyles = "M0" | "M1" | "M2" | "M3" | "M4" | "M5" | "M6"
export type MenuStyle = FirstStyles | "M7" | "M8" | "M9" | "M10" | "M11" | "M12"

export type PresenterOptions = {
	closeStyle: MenuStyle?,
	rows: { CanvasGroup }?,
}

export type Presenter = {
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	destroy: () -> (),
}

local MOTION = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	drawerIn = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	drawerOut = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	settle = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	reduced = TweenInfo.new(0.08, Enum.EasingStyle.Linear),
}

type Pose = {
	enter: (size: Vector2) -> Vector2,
	exit: (size: Vector2) -> Vector2,
	enterScale: number,
	exitScale: number,
	fades: boolean,
	enterTiming: TweenInfo,
	exitTiming: TweenInfo,
	settlePosition: boolean,
	settleScale: boolean,
}

local function still(): Vector2
	return Vector2.zero
end

local function pose(overrides: { [string]: any }): Pose
	local base = {
		enter = still,
		exit = still,
		enterScale = 1,
		exitScale = 1,
		fades = true,
		enterTiming = MOTION.enter,
		exitTiming = MOTION.exit,
		settlePosition = false,
		settleScale = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return (base :: any) :: Pose
end

-- Where each style starts when opening and where it goes when closing, as an
-- offset from the resting position. Exits travel less than entrances; the
-- drawers and sheets leave the way they came and stay opaque while moving.
local POSE: { [string]: Pose } = {
	M1 = pose({}),
	M2 = pose({
		enter = function()
			return Vector2.new(0, 12)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
	M3 = pose({ enterScale = 0.96, exitScale = 0.98 }),
	M4 = pose({
		enter = function(size: Vector2)
			return Vector2.new(-(size.X + 24), 0)
		end,
		exit = function(size: Vector2)
			return Vector2.new(-(size.X + 24), 0)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M5 = pose({ enterScale = 0.9, exitScale = 0.95 }),
	M6 = pose({ enterScale = 0.94, exitScale = 0.98, settleScale = true }),
	M7 = pose({
		enter = function(size: Vector2)
			return Vector2.new(size.X + 24, 0)
		end,
		exit = function(size: Vector2)
			return Vector2.new(size.X + 24, 0)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M8 = pose({
		enter = function(size: Vector2)
			return Vector2.new(0, size.Y + 24)
		end,
		exit = function(size: Vector2)
			return Vector2.new(0, size.Y + 24)
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M9 = pose({
		enter = function(size: Vector2)
			return Vector2.new(0, -(size.Y + 24))
		end,
		exit = function(size: Vector2)
			return Vector2.new(0, -(size.Y + 24))
		end,
		fades = false,
		enterTiming = MOTION.drawerIn,
		exitTiming = MOTION.drawerOut,
	}),
	M10 = pose({ enterScale = 1.06, exitScale = 1.03 }),
	M11 = pose({
		enter = function()
			return Vector2.new(0, 24)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
		settlePosition = true,
	}),
	M12 = pose({
		enter = function()
			return Vector2.new(0, 8)
		end,
		exit = function()
			return Vector2.new(0, 8)
		end,
	}),
}

local ROW_STEP = 0.03
local ROW_BUDGET = 0.25

-- `panel` is the window's outermost CanvasGroup, placed by Position rather than
-- by a parent layout. For M5, set its AnchorPoint on the side facing the button
-- that opens it: UIScale grows the panel out of its anchor. A UIScale used for
-- screen-size scaling belongs on a parent frame, not on the panel. M12 needs
-- the rows it reveals, each a CanvasGroup.
local function createPresenter(
	panel: CanvasGroup,
	style: MenuStyle,
	options: PresenterOptions?
): Presenter
	local closeStyle: MenuStyle = style
	if options and options.closeStyle then
		closeStyle = options.closeStyle
	end
	local rows: { CanvasGroup } = if options and options.rows then options.rows else {}

	local scale = Instance.new("UIScale")
	scale.Name = "OpenScale"
	scale.Parent = panel

	local home = panel.Position
	local phase: "closed" | "opening" | "open" | "closing" = "closed"
	local ticket = 0
	local running: { Tween } = {}

	panel.Visible = false
	panel.GroupTransparency = 1
	scale.Scale = 1

	local function stop()
		for _, tween in running do
			tween:Cancel()
		end
		table.clear(running)
	end

	local function play(target: Instance, timing: TweenInfo, goals: { [string]: any }): Tween
		local tween = TweenService:Create(target, timing, goals)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function shifted(offset: Vector2): UDim2
		return home + UDim2.fromOffset(offset.X, offset.Y)
	end

	-- Every tween checks the ticket it was started with, so a close that is
	-- interrupted by a reopen can never hide the panel it no longer owns.
	local function settleWhen(tween: Tween, onSettled: () -> ())
		local mine = ticket
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				onSettled()
			end
		end)
	end

	local function revealRows()
		local step = math.min(ROW_STEP, ROW_BUDGET / math.max(#rows, 1))
		local mine = ticket
		for index, row in rows do
			row.GroupTransparency = 1
			task.delay(step * (index - 1), function()
				if mine ~= ticket or not row.Parent then
					return
				end
				play(row, MOTION.enter, { GroupTransparency = 0 })
			end)
		end
	end

	local function open()
		if phase == "open" or phase == "opening" then
			return
		end
		ticket += 1
		stop()
		local fromClosed = phase == "closed"
		phase = "opening"
		panel.Visible = true

		if style == "M0" then
			panel.Position, scale.Scale, panel.GroupTransparency = home, 1, 0
			phase = "open"
			return
		end
		if GuiService.ReducedMotionEnabled then
			panel.Position, scale.Scale = home, 1
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 0 }), function()
				phase = "open"
			end)
			return
		end

		local chosen = POSE[style]
		if fromClosed then
			panel.Position = shifted(chosen.enter(panel.AbsoluteSize))
			scale.Scale = chosen.enterScale
			panel.GroupTransparency = if chosen.fades then 1 else 0
		end
		local moveTiming = if chosen.settlePosition then MOTION.settle else chosen.enterTiming
		local growTiming = if chosen.settleScale then MOTION.settle else chosen.enterTiming
		local move = play(panel, moveTiming, { Position = home })
		play(panel, MOTION.enter, { GroupTransparency = 0 })
		play(scale, growTiming, { Scale = 1 })
		if style == "M12" then
			revealRows()
		end
		settleWhen(move, function()
			phase = "open"
		end)
	end

	local function close()
		if phase == "closed" or phase == "closing" then
			return
		end
		if phase == "open" then
			home = panel.Position
		end
		ticket += 1
		stop()
		phase = "closing"

		local function hide()
			panel.Visible = false
			panel.Position, scale.Scale, panel.GroupTransparency = home, 1, 1
			phase = "closed"
		end

		if closeStyle == "M0" then
			hide()
			return
		end
		if GuiService.ReducedMotionEnabled then
			settleWhen(play(panel, MOTION.reduced, { GroupTransparency = 1 }), hide)
			return
		end

		local chosen = POSE[closeStyle]
		play(scale, chosen.exitTiming, { Scale = chosen.exitScale })
		if chosen.fades then
			play(panel, chosen.exitTiming, { GroupTransparency = 1 })
		end
		local target = shifted(chosen.exit(panel.AbsoluteSize))
		settleWhen(play(panel, chosen.exitTiming, { Position = target }), hide)
	end

	return {
		open = open,
		close = close,
		isOpen = function()
			return phase == "open" or phase == "opening"
		end,
		destroy = function()
			ticket += 1
			stop()
			scale:Destroy()
		end,
	}
end

return createPresenter
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/notices.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

export type Severity = "info" | "success" | "warning" | "error"

local THEME = {
	scrim = Color3.fromRGB(9, 10, 13),
	surface = Color3.fromRGB(44, 48, 57),
	control = Color3.fromRGB(63, 68, 79),
	controlHover = Color3.fromRGB(78, 84, 97),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	accentHover = Color3.fromRGB(72, 201, 162),
	onAccent = Color3.fromRGB(9, 10, 13),
	focus = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	success = "rbxassetid://88244323237265",
	warning = "rbxassetid://91165848022002",
	error = "rbxassetid://106305483906363",
	close = "rbxassetid://116396312853810",
}

local ENTER = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local INSTANT = TweenInfo.new(0)

local function motion(timing: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then INSTANT else timing
end

local function holdFor(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.clamp(2 + words * 0.3, 3, 8)
end

local function iconLabel(parent: GuiObject, severity: Severity, order: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.LayoutOrder = order
	icon.Size = UDim2.fromOffset(16, 16)
	icon.BackgroundTransparency = 1
	icon.Image = ICON[severity]
	icon.ImageColor3 = THEME[severity]
	icon.Parent = parent
	return icon
end

local function rowLayout(parent: GuiObject, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

-- N3: the row is always present at its full height, so showing a message never
-- pushes the controls below it down.
local function createInlineMessage(parent: GuiObject, order: number)
	local ticket = 0

	local slot = Instance.new("CanvasGroup")
	slot.Name = "InlineMessage"
	slot.LayoutOrder = order
	slot.Size = UDim2.new(1, 0, 0, 20)
	slot.BackgroundTransparency = 1
	slot.GroupTransparency = 1
	slot.Parent = parent
	rowLayout(slot, 8)

	local icon = iconLabel(slot, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 12
	text.TextColor3 = THEME.textMuted
	text.Text = ""
	text.Parent = slot

	local function clear()
		ticket += 1
		TweenService:Create(slot, motion(EXIT), { GroupTransparency = 1 }):Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		local mine = ticket
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		TweenService:Create(slot, motion(ENTER), { GroupTransparency = 0 }):Play()
		if severity ~= "error" then
			task.delay(holdFor(message), function()
				if mine == ticket then
					clear()
				end
			end)
		end
	end

	return {
		show = show,
		clear = clear,
		destroy = function()
			ticket += 1
			slot:Destroy()
		end,
	}
end

-- Hover, press and focus for the dialog buttons; the focus ring is separate
-- from the fill so a pointer leaving never hides keyboard or gamepad focus.
local function actionButton(parent: GuiObject, text: string, primary: boolean, order: number)
	local rest = if primary then THEME.accent else THEME.control
	local hover = if primary then THEME.accentHover else THEME.controlHover
	local connections: { RBXScriptConnection } = {}

	local button = Instance.new("TextButton")
	button.Name = text
	button.LayoutOrder = order
	button.AutoButtonColor = false
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 44)
	button.BackgroundColor3 = rest
	button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	button.TextSize = 14
	button.TextColor3 = if primary then THEME.onAccent else THEME.text
	button.Text = text
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = button

	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = THEME.focus
	ring.Thickness = 2
	ring.Enabled = false
	ring.Parent = button

	local press = Instance.new("UIScale")
	press.Parent = button

	table.insert(connections, button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hover
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		button.BackgroundColor3 = rest
		press.Scale = 1
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			press.Scale = 0.97
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		press.Scale = 1
	end))
	table.insert(connections, button.SelectionGained:Connect(function()
		ring.Enabled = true
	end))
	table.insert(connections, button.SelectionLost:Connect(function()
		ring.Enabled = false
	end))
	return button, connections
end

-- N5: a strip for a condition that lasts, such as "Reconnecting". It stays until
-- the condition ends or the player dismisses it.
local function createBanner(screen: ScreenGui)
	local connections: { RBXScriptConnection } = {}

	local strip = Instance.new("CanvasGroup")
	strip.Name = "Banner"
	strip.AutomaticSize = Enum.AutomaticSize.Y
	strip.Size = UDim2.fromScale(1, 0)
	strip.BackgroundColor3 = THEME.surface
	strip.GroupTransparency = 1
	strip.Visible = false
	strip.Parent = screen

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = strip

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = strip
	rowLayout(strip, 12)

	local icon = iconLabel(strip, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.Size = UDim2.new(0, 0, 0, 44)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 14
	text.TextColor3 = THEME.text
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.Text = ""
	text.Parent = strip

	local fill = Instance.new("UIFlexItem")
	fill.FlexMode = Enum.UIFlexMode.Fill
	fill.Parent = text

	local dismiss = Instance.new("ImageButton")
	dismiss.Name = "Dismiss"
	dismiss.LayoutOrder = 3
	dismiss.Size = UDim2.fromOffset(44, 44)
	dismiss.AutoButtonColor = false
	dismiss.BackgroundTransparency = 1
	dismiss.Image = ""
	dismiss.Parent = strip

	local ink = Instance.new("ImageLabel")
	ink.AnchorPoint = Vector2.new(0.5, 0.5)
	ink.Position = UDim2.fromScale(0.5, 0.5)
	ink.Size = UDim2.fromOffset(16, 16)
	ink.BackgroundTransparency = 1
	ink.Image = ICON.close
	ink.ImageColor3 = THEME.textMuted
	ink.Parent = dismiss

	local ticket = 0
	local function hide()
		ticket += 1
		local mine = ticket
		local fade = TweenService:Create(strip, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				strip.Visible = false
			end
		end)
		fade:Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		strip.Visible = true
		TweenService:Create(strip, motion(ENTER), { GroupTransparency = 0 }):Play()
	end

	table.insert(connections, dismiss.Activated:Connect(hide))
	return {
		show = show,
		hide = hide,
		destroy = function()
			ticket += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			strip:Destroy()
		end,
	}
end

-- N8: one short status line in a compact bar under the top bar. A new message
-- replaces the old one instead of stacking; anything the player must act on
-- belongs in N4 or N6, not here.
local function createCapsule(screen: ScreenGui)
	local ticket = 0

	local capsule = Instance.new("CanvasGroup")
	capsule.Name = "Capsule"
	capsule.AnchorPoint = Vector2.new(0.5, 0)
	capsule.Position = UDim2.new(0.5, 0, 0, 12)
	capsule.AutomaticSize = Enum.AutomaticSize.X
	capsule.Size = UDim2.fromOffset(0, 36)
	capsule.BackgroundColor3 = THEME.surface
	capsule.GroupTransparency = 1
	capsule.Visible = false
	capsule.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = capsule

	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = THEME.edge
	edge.Parent = capsule

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = capsule
	rowLayout(capsule, 8)

	local icon = iconLabel(capsule, "info", 1)
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.LayoutOrder = 2
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.BackgroundTransparency = 1
	text.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	text.TextSize = 14
	text.TextColor3 = THEME.text
	text.Text = ""
	text.Parent = capsule

	local grow = Instance.new("UIScale")
	grow.Scale = 1
	grow.Parent = capsule

	local function hide(mine: number)
		local fade = TweenService:Create(capsule, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				capsule.Visible = false
			end
		end)
		fade:Play()
	end

	local function show(message: string, severity: Severity)
		ticket += 1
		local mine = ticket
		icon.Image = ICON[severity]
		icon.ImageColor3 = THEME[severity]
		text.Text = message
		if not capsule.Visible then
			capsule.Visible = true
			grow.Scale = 0.9
		end
		TweenService:Create(capsule, motion(ENTER), { GroupTransparency = 0 }):Play()
		TweenService:Create(grow, motion(ENTER), { Scale = 1 }):Play()
		task.delay(holdFor(message), function()
			if mine == ticket then
				hide(mine)
			end
		end)
	end

	return {
		show = show,
		destroy = function()
			ticket += 1
			capsule:Destroy()
		end,
	}
end

export type AlertSpec = {
	title: string,
	body: string,
	confirmText: string,
	cancelText: string,
}

-- N6: only for something the player must answer. The dim layer is a button so
-- a tap outside the dialog counts as Cancel instead of reaching the game; the
-- dialog is its sibling and Active, so a tap inside it never reaches the dim.
local function confirmAlert(
	screen: ScreenGui,
	spec: AlertSpec,
	onChoice: (confirmed: boolean) -> ()
)
	local connections: { RBXScriptConnection } = {}
	local answered = false

	local scrim = Instance.new("TextButton")
	scrim.Name = "AlertScrim"
	scrim.AutoButtonColor = false
	scrim.Text = ""
	scrim.Selectable = false
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = THEME.scrim
	scrim.BackgroundTransparency = 1
	scrim.ZIndex = 10
	scrim.Parent = screen

	local dialog = Instance.new("CanvasGroup")
	dialog.Name = "Alert"
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.Size = UDim2.fromScale(0.9, 0)
	dialog.BackgroundColor3 = THEME.surface
	dialog.GroupTransparency = 1
	dialog.Active = true
	dialog.ZIndex = 11
	dialog.Parent = screen

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(280, 0)
	bounds.MaxSize = Vector2.new(400, math.huge)
	bounds.Parent = dialog

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = dialog

	local pop = Instance.new("UIScale")
	pop.Scale = 0.96
	pop.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 24)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = dialog

	local column = Instance.new("UIListLayout")
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = dialog

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.fromScale(1, 0)
	title.BackgroundTransparency = 1
	title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	title.TextSize = 20
	title.TextColor3 = THEME.text
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = spec.title
	title.Parent = dialog

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.LayoutOrder = 2
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.fromScale(1, 0)
	body.BackgroundTransparency = 1
	body.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	body.TextSize = 14
	body.TextColor3 = THEME.textMuted
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.Text = spec.body
	body.Parent = dialog

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.LayoutOrder = 3
	actions.Size = UDim2.new(1, 0, 0, 44)
	actions.BackgroundTransparency = 1
	actions.Parent = dialog
	rowLayout(actions, 8).HorizontalAlignment = Enum.HorizontalAlignment.Right

	local cancel, cancelConnections = actionButton(actions, spec.cancelText, false, 1)
	local confirm, confirmConnections = actionButton(actions, spec.confirmText, true, 2)
	table.move(cancelConnections, 1, #cancelConnections, #connections + 1, connections)
	table.move(confirmConnections, 1, #confirmConnections, #connections + 1, connections)

	local function answer(confirmed: boolean)
		if answered then
			return
		end
		answered = true
		for _, connection in connections do
			connection:Disconnect()
		end
		if GuiService.SelectedObject == confirm or GuiService.SelectedObject == cancel then
			GuiService.SelectedObject = nil
		end
		TweenService:Create(scrim, motion(EXIT), { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(dialog, motion(EXIT), { GroupTransparency = 1 })
		fade.Completed:Once(function()
			dialog:Destroy()
			scrim:Destroy()
		end)
		fade:Play()
		onChoice(confirmed)
	end

	table.insert(connections, confirm.Activated:Connect(function()
		answer(true)
	end))
	table.insert(connections, cancel.Activated:Connect(function()
		answer(false)
	end))
	table.insert(connections, scrim.Activated:Connect(function()
		answer(false)
	end))

	TweenService:Create(scrim, motion(ENTER), { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(dialog, motion(ENTER), { GroupTransparency = 0 }):Play()
	TweenService:Create(pop, motion(ENTER), { Scale = 1 }):Play()
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = cancel
	end
end

return {
	createInlineMessage = createInlineMessage,
	createBanner = createBanner,
	createCapsule = createCapsule,
	confirmAlert = confirmAlert,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/press-and-tabs.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

export type PressStyle = "P1" | "P2" | "P3"
export type TabStyle = "S1" | "S2" | "S3"

local THEME = {
	control = Color3.fromRGB(44, 48, 57),
	controlHover = Color3.fromRGB(63, 68, 79),
	controlPressed = Color3.fromRGB(31, 34, 41),
	edge = Color3.fromRGB(118, 125, 139),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	focus = Color3.fromRGB(72, 201, 162),
}

local QUICK = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local INSTANT = TweenInfo.new(0)

local function animate(instance: Instance, timing: TweenInfo, goals: { [string]: any })
	local chosen = if GuiService.ReducedMotionEnabled then INSTANT else timing
	TweenService:Create(instance, chosen, goals):Play()
end

-- The scale a style shows for each pointer state: P1 never scales, P2 presses
-- in, P3 lifts on hover and settles on press.
local SCALE = {
	P1 = { rest = 1, hover = 1, pressed = 1 },
	P2 = { rest = 1, hover = 1, pressed = 0.97 },
	P3 = { rest = 1, hover = 1.02, pressed = 0.98 },
}

local function attachPress(button: GuiButton, style: PressStyle): () -> ()
	local connections: { RBXScriptConnection } = {}
	local hovered, pressed = false, false
	button.AutoButtonColor = false

	local size = Instance.new("UIScale")
	size.Name = "PressScale"
	size.Parent = button

	local rim = Instance.new("UIStroke")
	rim.Name = "LiftEdge"
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = THEME.edge
	rim.Transparency = 1
	rim.Parent = button

	local function paint()
		local steps = SCALE[style]
		local fill = if pressed then THEME.controlPressed
			elseif hovered then THEME.controlHover
			else THEME.control
		local scale = if pressed then steps.pressed elseif hovered then steps.hover else steps.rest
		local timing = if pressed then QUICK else RELEASE
		animate(button, timing, { BackgroundColor3 = fill })
		animate(size, timing, { Scale = scale })
		if style == "P3" then
			animate(rim, timing, { Transparency = if hovered and not pressed then 0 else 1 })
		end
	end

	table.insert(connections, button.MouseEnter:Connect(function()
		hovered = true
		paint()
	end))
	table.insert(connections, button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint()
	end))
	table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressed = true
			paint()
		end
	end))
	table.insert(connections, button.InputEnded:Connect(function()
		pressed = false
		paint()
	end))

	button.BackgroundColor3 = THEME.control
	size.Scale = 1
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		size:Destroy()
		rim:Destroy()
	end
end

export type Tabs = {
	select: (name: string) -> (),
	selected: () -> string,
	destroy: () -> (),
}

-- The marker is a sibling of the button row, not a child of its UIListLayout,
-- so it can slide freely; its target is read from the chosen tab's geometry.
local function createTabs(
	parent: GuiObject,
	names: { string },
	style: TabStyle,
	onSelect: (name: string) -> ()
): Tabs
	local connections: { RBXScriptConnection } = {}
	local buttons: { [string]: TextButton } = {}
	local current = names[1]
	local hovered: string? = nil

	local bar = Instance.new("Frame")
	bar.Name = "Tabs"
	bar.Size = UDim2.new(1, 0, 0, 44)
	bar.BackgroundTransparency = 1
	bar.Parent = parent

	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BorderSizePixel = 0
	marker.BackgroundColor3 = if style == "S2" then THEME.controlHover else THEME.accent
	marker.Visible = style ~= "S3"
	marker.ZIndex = 1
	marker.Parent = bar

	local markerCorner = Instance.new("UICorner")
	markerCorner.CornerRadius = UDim.new(0, if style == "S2" then 6 else 0)
	markerCorner.Parent = marker

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.fromScale(1, 1)
	row.BackgroundTransparency = 1
	row.ZIndex = 2
	row.Parent = bar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local function moveMarker(instant: boolean)
		local tab = buttons[current]
		local x = tab.AbsolutePosition.X - bar.AbsolutePosition.X
		local width = tab.AbsoluteSize.X
		local goal = if style == "S1"
			then { Position = UDim2.new(0, x, 1, -2), Size = UDim2.fromOffset(width, 2) }
			else { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0, width, 1, 0) }
		animate(marker, if instant then INSTANT else SLIDE, goal)
	end

	local function paint()
		for name, tab in buttons do
			local chosen = name == current
			tab.TextColor3 = if chosen or name == hovered then THEME.text else THEME.textMuted
			local weight = if chosen then Enum.Font.GothamBold else Enum.Font.GothamMedium
			tab.FontFace = Font.fromEnum(weight)
		end
	end

	local function select(name: string)
		if name == current or not buttons[name] then
			return
		end
		current = name
		paint()
		moveMarker(false)
		onSelect(name)
	end

	for index, name in names do
		local tab = Instance.new("TextButton")
		tab.Name = name
		tab.LayoutOrder = index
		tab.AutoButtonColor = false
		tab.Size = UDim2.fromScale(0, 1)
		tab.BackgroundTransparency = 1
		tab.TextSize = 14
		tab.Text = name
		tab.Parent = row

		local share = Instance.new("UIFlexItem")
		share.FlexMode = Enum.UIFlexMode.Fill
		share.Parent = tab

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.focus
		ring.Thickness = 2
		ring.Enabled = false
		ring.Parent = tab

		buttons[name] = tab
		table.insert(connections, tab.Activated:Connect(function()
			select(name)
		end))
		table.insert(connections, tab.MouseEnter:Connect(function()
			hovered = name
			paint()
		end))
		table.insert(connections, tab.MouseLeave:Connect(function()
			if hovered == name then
				hovered = nil
			end
			paint()
		end))
		table.insert(connections, tab.SelectionGained:Connect(function()
			ring.Enabled = true
		end))
		table.insert(connections, tab.SelectionLost:Connect(function()
			ring.Enabled = false
		end))
	end

	table.insert(connections, bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		moveMarker(true)
	end))
	paint()
	moveMarker(true)

	return {
		select = select,
		selected = function()
			return current
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			bar:Destroy()
		end,
	}
end

return {
	attachPress = attachPress,
	createTabs = createTabs,
}
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/toasts.luau

```lua
--!strict
-- lint: complete
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Placement = "N1" | "N2" | "N4" | "N7"
export type Severity = "info" | "success" | "warning" | "error"

export type ProgressHandle = {
	done: (message: string, severity: Severity?) -> (),
}

export type Notifier = {
	push: (message: string, severity: Severity?, key: string?) -> (),
	progress: (message: string) -> ProgressHandle,
	action: (message: string, actionLabel: string, onAction: () -> ()) -> (),
	destroy: () -> (),
}

-- The toast reads the same surface entry as the panel it sits beside, so fill,
-- edge and radius cannot drift apart between the two.
local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	action = Color3.fromRGB(72, 201, 162),
	info = Color3.fromRGB(88, 141, 214),
	success = Color3.fromRGB(72, 178, 112),
	warning = Color3.fromRGB(214, 158, 62),
	error = Color3.fromRGB(208, 88, 82),
}

local ICON = {
	info = "rbxassetid://120620848266512",
	success = "rbxassetid://88244323237265",
	warning = "rbxassetid://91165848022002",
	error = "rbxassetid://106305483906363",
	close = "rbxassetid://116396312853810",
	loading = "rbxassetid://71250150569964",
}

-- direction is which way the stack grows from its anchor; arrive is where a new
-- toast starts before it settles into its slot; timed stacks show a time-left bar.
local PLACEMENT = {
	N1 = {
		anchor = Vector2.new(0.5, 1),
		direction = -1,
		arrive = Vector2.new(0, 12),
		timed = false,
	},
	N2 = {
		anchor = Vector2.new(0.5, 0),
		direction = 1,
		arrive = Vector2.new(0, -8),
		timed = false,
	},
	N4 = {
		anchor = Vector2.new(1, 1),
		direction = -1,
		arrive = Vector2.new(24, 0),
		timed = true,
	},
	N7 = {
		anchor = Vector2.new(1, 0),
		direction = 1,
		arrive = Vector2.new(24, 0),
		timed = true,
	},
}

local MAX_VISIBLE = 3
local MAX_QUEUED = 10
local GAP = 8
local EDGE_INSET = 16
local MIN_HOLD = 1.5
local ACTION_HOLD = 6
local SETTLE_TIME = 0.12
local SPIN_DEGREES_PER_SECOND = 360
local FADE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)

type Request = {
	message: string,
	severity: Severity,
	key: string?,
	kind: "plain" | "progress" | "action",
	actionLabel: string?,
	onAction: (() -> ())?,
	toast: Toast?,
}

type Toast = {
	request: Request,
	count: number,
	card: CanvasGroup,
	content: Frame,
	icon: ImageLabel,
	label: TextLabel,
	timerBar: Frame?,
	dismiss: ImageButton?,
	offset: Vector2,
	velocity: Vector2,
	goal: Vector2,
	height: number,
	lifetime: number,
	remaining: number,
	held: boolean,
	connections: { RBXScriptConnection },
}

local function readingTime(message: string): number
	local words = select(2, message:gsub("%S+", ""))
	return math.max(MIN_HOLD, math.clamp(2 + words * 0.3, 3, 8))
end

local function createNotifier(screen: ScreenGui, placement: Placement): Notifier
	local layout = PLACEMENT[placement]
	local shown: { Toast } = {}
	local waiting: { Request } = {}
	local byKey: { [string]: Toast } = {}
	local loop: RBXScriptConnection? = nil

	local stack = Instance.new("Frame")
	stack.Name = "Notifications"
	stack.AnchorPoint = layout.anchor
	stack.Position = UDim2.new(
		layout.anchor.X,
		(0.5 - layout.anchor.X) * 2 * EDGE_INSET,
		layout.anchor.Y,
		(0.5 - layout.anchor.Y) * 2 * EDGE_INSET
	)
	stack.Size = UDim2.new(1, -EDGE_INSET * 2, 1, -EDGE_INSET * 2)
	stack.BackgroundTransparency = 1
	stack.Parent = screen

	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(240, 0)
	bounds.MaxSize = Vector2.new(360, math.huge)
	bounds.Parent = stack

	local function place(toast: Toast)
		local anchor = layout.anchor
		toast.card.Position = UDim2.new(anchor.X, toast.offset.X, anchor.Y, toast.offset.Y)
	end

	-- Targets come from list order, never from a stored slot, so the toast under
	-- one that leaves early moves up while it may still be arriving.
	local function restack()
		local travelled = 0
		for _, toast in shown do
			toast.goal = Vector2.new(0, travelled * layout.direction)
			travelled += toast.height + GAP
		end
	end

	local release: (toast: Toast) -> ()
	local present: (request: Request) -> ()

	local function step(dt: number)
		for index = #shown, 1, -1 do
			local toast = shown[index]
			local goal, velocity = toast.goal, toast.velocity
			toast.offset, toast.velocity =
				TweenService:SmoothDamp(toast.offset, goal, velocity, SETTLE_TIME, nil, dt)
			place(toast)
			local request = toast.request
			if request.kind == "progress" then
				toast.icon.Rotation = (toast.icon.Rotation + dt * SPIN_DEGREES_PER_SECOND) % 360
				continue
			end
			if toast.held or request.severity == "error" then
				continue
			end
			toast.remaining -= dt
			local timerBar = toast.timerBar
			if timerBar then
				timerBar.Size = UDim2.new(math.max(toast.remaining / toast.lifetime, 0), 0, 0, 2)
			end
			if toast.remaining <= 0 then
				release(toast)
			end
		end
		if #shown == 0 and loop then
			loop:Disconnect()
			loop = nil
		end
	end

	function release(toast: Toast)
		local index = table.find(shown, toast)
		if not index then
			return
		end
		table.remove(shown, index)
		if toast.request.key then
			byKey[toast.request.key] = nil
		end
		for _, connection in toast.connections do
			connection:Disconnect()
		end
		restack()

		local fade = TweenService:Create(toast.card, FADE_OUT, { GroupTransparency = 1 })
		fade.Completed:Once(function()
			toast.card:Destroy()
		end)
		fade:Play()

		local nextRequest = table.remove(waiting, 1)
		if nextRequest then
			present(nextRequest)
		end
	end

	local function addDismiss(toast: Toast)
		local dismiss = Instance.new("ImageButton")
		dismiss.Name = "Dismiss"
		dismiss.LayoutOrder = 4
		dismiss.Size = UDim2.fromOffset(44, 44)
		dismiss.AutoButtonColor = false
		dismiss.BackgroundTransparency = 1
		dismiss.Image = ""
		dismiss.Parent = toast.content

		local ink = Instance.new("ImageLabel")
		ink.Name = "Ink"
		ink.AnchorPoint = Vector2.new(0.5, 0.5)
		ink.Position = UDim2.fromScale(0.5, 0.5)
		ink.Size = UDim2.fromOffset(16, 16)
		ink.BackgroundTransparency = 1
		ink.Image = ICON.close
		ink.ImageColor3 = THEME.text
		ink.Parent = dismiss

		toast.dismiss = dismiss
		table.insert(toast.connections, dismiss.Activated:Connect(function()
			release(toast)
		end))
	end

	-- The row lives in its own frame so the timer bar can sit on the card's
	-- bottom edge; a child of a UIListLayout would be placed in the row.
	local function addTimer(toast: Toast)
		local timerBar = Instance.new("Frame")
		timerBar.Name = "TimeLeft"
		timerBar.AnchorPoint = Vector2.new(0, 1)
		timerBar.Position = UDim2.fromScale(0, 1)
		timerBar.Size = UDim2.new(1, 0, 0, 2)
		timerBar.BackgroundColor3 = THEME[toast.request.severity]
		timerBar.BorderSizePixel = 0
		timerBar.Parent = toast.card
		toast.timerBar = timerBar
	end

	local function addAction(toast: Toast, actionLabel: string, onAction: () -> ())
		local button = Instance.new("TextButton")
		button.Name = "Action"
		button.LayoutOrder = 3
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, 44)
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1
		button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		button.TextSize = 14
		button.TextColor3 = THEME.action
		button.Text = actionLabel
		button.Parent = toast.content

		table.insert(toast.connections, button.Activated:Connect(function()
			onAction()
			release(toast)
		end))
	end

	local function build(request: Request): Toast
		local card = Instance.new("CanvasGroup")
		card.Name = "Toast"
		card.AnchorPoint = layout.anchor
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Size = UDim2.fromScale(1, 0)
		card.BackgroundColor3 = THEME.surface
		card.GroupTransparency = 1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = card

		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = THEME.edge
		edge.Parent = card

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.AutomaticSize = Enum.AutomaticSize.Y
		content.Size = UDim2.fromScale(1, 0)
		content.BackgroundTransparency = 1
		content.Parent = card

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 12)
		padding.PaddingBottom = UDim.new(0, 12)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = content

		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.SortOrder = Enum.SortOrder.LayoutOrder
		row.Padding = UDim.new(0, 12)
		row.Parent = content

		local progress = request.kind == "progress"
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.LayoutOrder = 1
		icon.Size = UDim2.fromOffset(20, 20)
		icon.BackgroundTransparency = 1
		icon.Image = if progress then ICON.loading else ICON[request.severity]
		icon.Rotation = 0
		icon.ImageColor3 = THEME[request.severity]
		icon.Parent = content

		local label = Instance.new("TextLabel")
		label.Name = "Message"
		label.LayoutOrder = 2
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.fromScale(0, 0)
		label.BackgroundTransparency = 1
		label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		label.TextSize = 14
		label.TextColor3 = THEME.text
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = request.message
		label.Parent = content

		local fill = Instance.new("UIFlexItem")
		fill.FlexMode = Enum.UIFlexMode.Fill
		fill.Parent = label

		local lifetime = readingTime(request.message)
		if request.kind == "action" then
			lifetime = math.max(lifetime, ACTION_HOLD)
		end

		local toast: Toast = {
			request = request,
			count = 1,
			card = card,
			content = content,
			icon = icon,
			label = label,
			timerBar = nil,
			dismiss = nil,
			offset = Vector2.zero,
			velocity = Vector2.zero,
			goal = Vector2.zero,
			height = 48,
			lifetime = lifetime,
			remaining = lifetime,
			held = false,
			connections = {},
		}
		request.toast = toast

		local actionLabel, onAction = request.actionLabel, request.onAction
		if actionLabel and onAction then
			addAction(toast, actionLabel, onAction)
		end
		if request.severity == "error" then
			addDismiss(toast)
		elseif layout.timed and not progress then
			addTimer(toast)
		end

		table.insert(toast.connections, card.MouseEnter:Connect(function()
			toast.held = true
		end))
		table.insert(toast.connections, card.MouseLeave:Connect(function()
			toast.held = false
		end))
		local resized = card:GetPropertyChangedSignal("AbsoluteSize")
		table.insert(toast.connections, resized:Connect(function()
			toast.height = card.AbsoluteSize.Y
			restack()
		end))
		return toast
	end

	function present(request: Request)
		local toast = build(request)
		table.insert(shown, toast)
		if request.key then
			byKey[request.key] = toast
		end
		restack()
		toast.offset = toast.goal + layout.arrive
		place(toast)
		toast.card.Parent = stack
		TweenService:Create(toast.card, FADE_IN, { GroupTransparency = 0 }):Play()
		if not loop then
			loop = RunService.PreRender:Connect(step)
		end
	end

	local function enqueue(request: Request)
		if #shown < MAX_VISIBLE then
			present(request)
			return
		end
		if #waiting >= MAX_QUEUED then
			table.remove(waiting, 1)
		end
		table.insert(waiting, request)
	end

	local function push(message: string, severity: Severity?, key: string?)
		local repeated = if key then byKey[key] else nil
		if repeated then
			repeated.count += 1
			repeated.label.Text = `{repeated.request.message} ×{repeated.count}`
			repeated.remaining = repeated.lifetime
			return
		end
		enqueue({ message = message, severity = severity or "info", key = key, kind = "plain" })
	end

	-- A progress toast spins until `done`; a request still in the queue simply
	-- arrives already finished.
	local function progress(message: string): ProgressHandle
		local request: Request = { message = message, severity = "info", kind = "progress" }
		enqueue(request)
		return {
			done = function(result: string, severity: Severity?)
				request.kind = "plain"
				request.message = result
				request.severity = severity or "success"
				local toast = request.toast
				if not toast then
					return
				end
				toast.icon.Rotation = 0
				toast.icon.Image = ICON[request.severity]
				toast.icon.ImageColor3 = THEME[request.severity]
				toast.label.Text = result
				toast.lifetime = readingTime(result)
				toast.remaining = toast.lifetime
				if request.severity == "error" then
					addDismiss(toast)
				elseif layout.timed then
					addTimer(toast)
				end
			end,
		}
	end

	local function action(message: string, actionLabel: string, onAction: () -> ())
		enqueue({
			message = message,
			severity = "info",
			kind = "action",
			actionLabel = actionLabel,
			onAction = onAction,
		})
	end

	return {
		push = push,
		progress = progress,
		action = action,
		destroy = function()
			if loop then
				loop:Disconnect()
				loop = nil
			end
			for _, toast in shown do
				for _, connection in toast.connections do
					connection:Disconnect()
				end
			end
			table.clear(shown)
			table.clear(waiting)
			table.clear(byKey)
			stack:Destroy()
		end,
	}
end

return createNotifier
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/toggles.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local THEME = {
	row = Color3.fromRGB(31, 34, 41),
	rowHover = Color3.fromRGB(44, 48, 57),
	track = Color3.fromRGB(63, 68, 79),
	knob = Color3.fromRGB(243, 245, 248),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(118, 125, 139),
	accent = Color3.fromRGB(46, 160, 127),
	accentDim = Color3.fromRGB(28, 88, 74),
	focus = Color3.fromRGB(72, 201, 162),
}

local ICON = {
	check = "rbxassetid://86817768619372",
	cross = "rbxassetid://116396312853810",
	eye = "rbxassetid://127234874352422",
	eyeOff = "rbxassetid://85207295981701",
}

local STATE_MOTION = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NO_MOTION = TweenInfo.new(0)

export type ToggleStyle = "T1" | "T2" | "T3" | "T4" | "T5" | "T6" | "T7" | "T8" | "T9" | "T10"

export type Toggle = {
	row: TextButton,
	set: (value: boolean) -> (),
	get: () -> boolean,
	setEnabled: (enabled: boolean) -> (),
	destroy: () -> (),
}

-- Before the row is parented there is nothing on screen to animate, so the
-- first paint assigns directly instead of sliding in from the default values.
local function animate(instance: Instance, goals: { [string]: any })
	if not instance:IsDescendantOf(game) then
		for property, goal in goals do
			(instance :: any)[property] = goal
		end
		return
	end
	local timing = if GuiService.ReducedMotionEnabled then NO_MOTION else STATE_MOTION
	TweenService:Create(instance, timing, goals):Play()
end

local function round(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function newFrame(name: string, size: UDim2, colour: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	return frame
end

-- T1 and T2 differ only in corner radius; the knob position carries the state,
-- so the track colour is never the only signal.
local function switchSkin(row: TextButton, radius: UDim, knobRadius: UDim): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, radius)
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, knobRadius)
	knob.Parent = track

	return function(on: boolean)
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

local function tickSkin(row: TextButton): (boolean) -> ()
	local box = newFrame("Box", UDim2.fromOffset(22, 22), THEME.row)
	box.LayoutOrder = 0
	round(box, UDim.new(0, 6))
	box.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = box

	local tick = Instance.new("ImageLabel")
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(16, 16)
	tick.BackgroundTransparency = 1
	tick.Image = ICON.check
	tick.ImageColor3 = THEME.knob
	tick.Parent = box

	local grow = Instance.new("UIScale")
	grow.Parent = tick

	return function(on: boolean)
		animate(box, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
		animate(grow, { Scale = if on then 1 else 0.8 })
	end
end

local function lightSkin(row: TextButton, label: TextLabel): (boolean) -> ()
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.LayoutOrder = 2
	status.AutomaticSize = Enum.AutomaticSize.X
	status.Size = UDim2.fromScale(0, 1)
	status.BackgroundTransparency = 1
	status.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	status.TextSize = 12
	status.Text = "OFF"
	status.Parent = row

	return function(on: boolean)
		status.Text = if on then "ON" else "OFF"
		animate(status, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		label.FontFace = Font.fromEnum(if on then Enum.Font.GothamBold else Enum.Font.GothamMedium)
	end
end

local function iconSkin(row: TextButton): (boolean) -> ()
	local badge = newFrame("Badge", UDim2.fromOffset(32, 32), THEME.track)
	badge.LayoutOrder = 0
	round(badge, UDim.new(0, 6))
	badge.Parent = row

	local glyph = Instance.new("ImageLabel")
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromOffset(16, 16)
	glyph.BackgroundTransparency = 1
	glyph.Parent = badge

	return function(on: boolean)
		glyph.Image = if on then ICON.eye else ICON.eyeOff
		animate(glyph, { ImageColor3 = if on then THEME.knob else THEME.textMuted })
		animate(badge, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T7: the knob carries the answer as a tick or a cross.
local function knobIconSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(44, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	local mark = Instance.new("ImageLabel")
	mark.Name = "Mark"
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromOffset(12, 12)
	mark.BackgroundTransparency = 1
	mark.Parent = knob

	return function(on: boolean)
		mark.Image = if on then ICON.check else ICON.cross
		mark.ImageColor3 = if on then THEME.accent else THEME.textMuted
		animate(knob, { Position = UDim2.new(0, if on then 23 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T8: the word sits inside the track, on the side the knob has left.
local function wordSwitchSkin(row: TextButton): (boolean) -> ()
	local track = newFrame("Track", UDim2.fromOffset(56, 24), THEME.track)
	track.LayoutOrder = 2
	round(track, UDim.new(0.5, 0))
	track.Parent = row

	local word = Instance.new("TextLabel")
	word.Name = "Word"
	word.AnchorPoint = Vector2.new(0, 0.5)
	word.Size = UDim2.fromOffset(28, 24)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.TextColor3 = THEME.knob
	word.Text = "OFF"
	word.Parent = track

	local knob = newFrame("Knob", UDim2.fromOffset(18, 18), THEME.knob)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	round(knob, UDim.new(0.5, 0))
	knob.Parent = track

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		word.Position = UDim2.new(0, if on then 4 else 24, 0.5, 0)
		animate(knob, { Position = UDim2.new(0, if on then 35 else 3, 0.5, 0) })
		animate(track, { BackgroundColor3 = if on then THEME.accent else THEME.track })
	end
end

-- T9: a small light plus the word, so the state never rests on the colour.
local function statusDotSkin(row: TextButton): (boolean) -> ()
	local dot = newFrame("Dot", UDim2.fromOffset(8, 8), THEME.track)
	dot.LayoutOrder = 2
	round(dot, UDim.new(0.5, 0))
	dot.Parent = row

	local word = Instance.new("TextLabel")
	word.Name = "Status"
	word.LayoutOrder = 3
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	word.BackgroundTransparency = 1
	word.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	word.TextSize = 12
	word.Text = "OFF"
	word.Parent = row

	return function(on: boolean)
		word.Text = if on then "ON" else "OFF"
		animate(word, { TextColor3 = if on then THEME.focus else THEME.textMuted })
		animate(dot, { BackgroundColor3 = if on then THEME.focus else THEME.track })
	end
end

-- T10: T3's tick in a circle, for lists where square boxes feel heavy.
local function roundTickSkin(row: TextButton): (boolean) -> ()
	local ring = newFrame("Ring", UDim2.fromOffset(22, 22), THEME.row)
	ring.LayoutOrder = 0
	round(ring, UDim.new(0.5, 0))
	ring.Parent = row

	local outline = Instance.new("UIStroke")
	outline.Color = THEME.track
	outline.Thickness = 2
	outline.Parent = ring

	local tick = Instance.new("ImageLabel")
	tick.Name = "Tick"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(14, 14)
	tick.BackgroundTransparency = 1
	tick.Image = ICON.check
	tick.ImageColor3 = THEME.knob
	tick.Parent = ring

	local grow = Instance.new("UIScale")
	grow.Parent = tick

	return function(on: boolean)
		animate(ring, { BackgroundColor3 = if on then THEME.accent else THEME.row })
		animate(outline, { Color = if on then THEME.accent else THEME.track })
		animate(tick, { ImageTransparency = if on then 0 else 1 })
		animate(grow, { Scale = if on then 1 else 0.6 })
	end
end

-- T4 shows both words; each half is its own button so pressing the half that is
-- already selected leaves the value alone instead of flipping it.
local function segmentSkin(
	row: TextButton,
	choose: (boolean) -> (),
	watch: (GuiButton) -> (),
	connections: { RBXScriptConnection }
): (boolean) -> ()
	local group = newFrame("Segments", UDim2.fromOffset(112, 36), THEME.track)
	group.LayoutOrder = 2
	round(group, UDim.new(0, 6))
	group.Parent = row

	local indicator = newFrame("Indicator", UDim2.new(0.5, -4, 1, -8), THEME.accent)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.ZIndex = 1
	round(indicator, UDim.new(0, 4))
	indicator.Parent = group

	local halves: { TextButton } = {}
	for index, word in { "Off", "On" } do
		local half = Instance.new("TextButton")
		half.Name = word
		half.AutoButtonColor = false
		half.BackgroundTransparency = 1
		half.Position = UDim2.fromScale((index - 1) * 0.5, 0)
		half.Size = UDim2.fromScale(0.5, 1)
		half.ZIndex = 2
		half.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		half.TextSize = 14
		half.Text = word
		half.Parent = group
		watch(half)
		table.insert(connections, half.Activated:Connect(function()
			choose(word == "On")
		end))
		halves[index] = half
	end

	row.Selectable = false
	return function(on: boolean)
		animate(indicator, { Position = UDim2.new(if on then 0.5 else 0, 4, 0.5, 0) })
		halves[1].TextColor3 = if on then THEME.textMuted else THEME.text
		halves[2].TextColor3 = if on then THEME.text else THEME.textMuted
	end
end

local function createToggle(
	parent: GuiObject,
	labelText: string,
	style: ToggleStyle,
	initial: boolean,
	onChanged: (boolean) -> ()
): Toggle
	local value = initial
	local enabled = true
	local hovered, pressed, focused = false, false, false
	local connections: { RBXScriptConnection } = {}

	local row = Instance.new("TextButton")
	row.Name = labelText
	row.AutoButtonColor = false
	row.Text = ""
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = THEME.row
	row.BorderSizePixel = 0
	round(row, UDim.new(0, 6))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = row

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.LayoutOrder = 1
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = labelText
	label.Parent = row

	local fill = Instance.new("UIFlexItem")
	fill.FlexMode = Enum.UIFlexMode.Fill
	fill.Parent = label

	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Enabled = style == "T5"
	edge.Parent = row

	local focusRing = Instance.new("UIStroke")
	focusRing.Name = "FocusRing"
	focusRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	focusRing.Color = THEME.focus
	focusRing.Thickness = 2
	focusRing.Enabled = false
	focusRing.Parent = row

	-- T5 is the only style whose whole row is the "on" signal, so its lit
	-- colour outranks hover; the other styles leave the row neutral.
	local function paintRow()
		label.TextColor3 = if enabled then THEME.text else THEME.textMuted
		local lit = style == "T5" and value
		local surface = if lit then THEME.accentDim
			elseif pressed then THEME.row
			elseif hovered then THEME.rowHover
			else THEME.row
		animate(row, { BackgroundColor3 = surface })
		edge.Color = if not lit then THEME.track elseif hovered then THEME.focus else THEME.accent
	end

	-- One watcher per focusable button: hover, press and focus are separate
	-- flags, so losing hover never clears focus and a refresh keeps both.
	local function watch(button: GuiButton)
		table.insert(connections, button.MouseEnter:Connect(function()
			hovered = true
			paintRow()
		end))
		table.insert(connections, button.MouseLeave:Connect(function()
			hovered, pressed = false, false
			paintRow()
		end))
		table.insert(connections, button.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				pressed = true
				paintRow()
			end
		end))
		table.insert(connections, button.InputEnded:Connect(function()
			pressed = false
			paintRow()
		end))
		table.insert(connections, button.SelectionGained:Connect(function()
			focused = true
			focusRing.Enabled = focused
		end))
		table.insert(connections, button.SelectionLost:Connect(function()
			focused = false
			focusRing.Enabled = focused
		end))
	end

	local paintValue: (boolean) -> ()
	local function set(next: boolean)
		if not enabled or next == value then
			return
		end
		value = next
		paintValue(value)
		paintRow()
		onChanged(value)
	end

	if style == "T1" then
		paintValue = switchSkin(row, UDim.new(0.5, 0), UDim.new(0.5, 0))
	elseif style == "T2" then
		paintValue = switchSkin(row, UDim.new(0, 6), UDim.new(0, 4))
	elseif style == "T3" then
		paintValue = tickSkin(row)
	elseif style == "T4" then
		paintValue = segmentSkin(row, set, watch, connections)
	elseif style == "T5" then
		paintValue = lightSkin(row, label)
	elseif style == "T6" then
		paintValue = iconSkin(row)
	elseif style == "T7" then
		paintValue = knobIconSkin(row)
	elseif style == "T8" then
		paintValue = wordSwitchSkin(row)
	elseif style == "T9" then
		paintValue = statusDotSkin(row)
	else
		paintValue = roundTickSkin(row)
	end

	if style ~= "T4" then
		watch(row)
		table.insert(connections, row.Activated:Connect(function()
			set(not value)
		end))
	end

	paintRow()
	paintValue(value)
	row.Parent = parent

	return {
		row = row,
		set = set,
		get = function()
			return value
		end,
		setEnabled = function(next: boolean)
			enabled = next
			row.Active = next
			row.Interactable = next
			paintRow()
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			row:Destroy()
		end,
	}
end

return createToggle
```

---

## Recipe: .claude/skills/roblox-ui-components/assets/windows.luau

```lua
--!strict
-- lint: complete
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

export type WindowStyle = "O1" | "O2" | "O3" | "O4"

export type Opener = {
	open: () -> (),
	close: () -> (),
}

-- `launcher` is the on-screen button that brings the window back (O1, O2).
-- O3 keeps `header` on screen and folds `body` away. `opener` is a presenter
-- from menus.luau; without one, O1 shows and hides instantly.
export type WindowParts = {
	panel: CanvasGroup,
	launcher: GuiButton?,
	header: GuiObject?,
	body: CanvasGroup?,
	opener: Opener?,
}

export type Window = {
	show: () -> (),
	hide: () -> (),
	toggle: () -> (),
	isShown: () -> boolean,
	destroy: () -> (),
}

local THEME = {
	surface = Color3.fromRGB(44, 48, 57),
	edge = Color3.fromRGB(63, 68, 79),
	text = Color3.fromRGB(243, 245, 248),
	textMuted = Color3.fromRGB(150, 157, 170),
	accent = Color3.fromRGB(46, 160, 127),
	focus = Color3.fromRGB(72, 201, 162),
}

local ICON = {
	pullOut = "rbxassetid://101007429951147",
}

local MOTION = {
	enter = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	exit = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	grow = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	shrink = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	line = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	instant = TweenInfo.new(0),
}

local MINIMISED_SCALE = 0.2
local INTRO_HOLD = 0.6

local function timing(chosen: TweenInfo): TweenInfo
	return if GuiService.ReducedMotionEnabled then MOTION.instant else chosen
end

local function createWindow(parts: WindowParts, style: WindowStyle): Window
	local panel = parts.panel
	local connections: { RBXScriptConnection } = {}
	local shown = panel.Visible
	local ticket = 0
	local running: { Tween } = {}

	local scale = Instance.new("UIScale")
	scale.Name = "WindowScale"
	scale.Scale = 1
	scale.Parent = panel

	local home = panel.Position
	local fullSize = panel.Size

	local function stop()
		for _, tween in running do
			tween:Cancel()
		end
		table.clear(running)
	end

	local function play(target: Instance, info: TweenInfo, goals: { [string]: any }): Tween
		local tween = TweenService:Create(target, timing(info), goals)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function afterTween(tween: Tween, finish: () -> ())
		local mine = ticket
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == ticket then
				finish()
			end
		end)
	end

	-- The offset that puts the panel's anchor on the launcher's centre, so the
	-- window visibly shrinks into the button that will bring it back.
	local function towardLauncher(launcher: GuiButton): UDim2
		local target = launcher.AbsolutePosition + launcher.AbsoluteSize / 2
		local anchor = panel.AbsolutePosition + panel.AbsoluteSize * panel.AnchorPoint
		local delta = target - anchor
		return home + UDim2.fromOffset(delta.X, delta.Y)
	end

	local edgeTab: ImageButton? = nil
	if style == "O4" then
		local tab = Instance.new("ImageButton")
		tab.Name = "EdgeTab"
		tab.AnchorPoint = Vector2.new(0, 0.5)
		tab.Position = UDim2.new(0, 0, 0.5, 0)
		tab.Size = UDim2.fromOffset(44, 64)
		tab.AutoButtonColor = false
		tab.BackgroundColor3 = THEME.surface
		tab.Image = ""
		tab.Visible = not shown
		tab.Parent = panel.Parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = tab

		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = THEME.edge
		ring.Parent = tab

		local mark = Instance.new("ImageLabel")
		mark.Name = "Mark"
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.fromScale(0.5, 0.5)
		mark.Size = UDim2.fromOffset(16, 16)
		mark.BackgroundTransparency = 1
		mark.Image = ICON.pullOut
		mark.ImageColor3 = THEME.textMuted
		mark.Parent = tab

		table.insert(connections, tab.MouseEnter:Connect(function()
			mark.ImageColor3 = THEME.text
		end))
		table.insert(connections, tab.MouseLeave:Connect(function()
			mark.ImageColor3 = THEME.textMuted
		end))
		table.insert(connections, tab.SelectionGained:Connect(function()
			ring.Color = THEME.focus
		end))
		table.insert(connections, tab.SelectionLost:Connect(function()
			ring.Color = THEME.edge
		end))
		edgeTab = tab
	end

	local function setReturnControl(visible: boolean)
		if parts.launcher then
			parts.launcher.Visible = visible
		end
		if edgeTab then
			edgeTab.Visible = visible
		end
	end

	local function hide()
		if not shown then
			return
		end
		shown = false
		ticket += 1
		stop()

		if style == "O3" then
			local header, body = parts.header, parts.body
			assert(header and body, "O3 needs header and body")
			fullSize = panel.Size
			local collapsed = header.AbsoluteSize.Y + 24
			play(body, MOTION.exit, { GroupTransparency = 1 })
			local fold = play(panel, MOTION.shrink, {
				Size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, collapsed),
			})
			afterTween(fold, function()
				body.Visible = false
			end)
			return
		end

		if style == "O2" then
			local launcher = parts.launcher
			assert(launcher, "O2 needs a launcher")
			home = panel.Position
			play(scale, MOTION.shrink, { Scale = MINIMISED_SCALE })
			play(panel, MOTION.shrink, { GroupTransparency = 1 })
			local travel = play(panel, MOTION.shrink, { Position = towardLauncher(launcher) })
			afterTween(travel, function()
				panel.Visible = false
				panel.Position, scale.Scale = home, 1
				setReturnControl(true)
			end)
			return
		end

		if style == "O4" then
			home = panel.Position
			local offscreen = home - UDim2.fromOffset(panel.AbsoluteSize.X + 24, 0)
			local slide = play(panel, MOTION.shrink, { Position = offscreen })
			afterTween(slide, function()
				panel.Visible = false
				panel.Position = home
				setReturnControl(true)
			end)
			return
		end

		setReturnControl(true)
		if parts.opener then
			parts.opener.close()
		else
			panel.Visible = false
		end
	end

	local function show()
		if shown then
			return
		end
		shown = true
		ticket += 1
		stop()

		if style == "O3" then
			local body = parts.body
			assert(body, "O3 needs a body")
			body.Visible = true
			play(panel, MOTION.grow, { Size = fullSize })
			play(body, MOTION.enter, { GroupTransparency = 0 })
			return
		end

		setReturnControl(false)
		if style == "O2" then
			local launcher = parts.launcher
			assert(launcher, "O2 needs a launcher")
			panel.Position = towardLauncher(launcher)
			scale.Scale = MINIMISED_SCALE
			panel.GroupTransparency = 1
			panel.Visible = true
			play(scale, MOTION.grow, { Scale = 1 })
			play(panel, MOTION.grow, { Position = home, GroupTransparency = 0 })
			return
		end

		if style == "O4" then
			panel.Position = home - UDim2.fromOffset(panel.AbsoluteSize.X + 24, 0)
			panel.GroupTransparency = 0
			panel.Visible = true
			play(panel, MOTION.grow, { Position = home })
			return
		end

		if parts.opener then
			parts.opener.open()
		else
			panel.Visible = true
			panel.GroupTransparency = 0
		end
	end

	local function toggle()
		if shown then
			hide()
		else
			show()
		end
	end

	if parts.launcher then
		table.insert(connections, parts.launcher.Activated:Connect(show))
	end
	if edgeTab then
		table.insert(connections, edgeTab.Activated:Connect(show))
	end
	setReturnControl(not shown)

	return {
		show = show,
		hide = hide,
		toggle = toggle,
		isShown = function()
			return shown
		end,
		destroy = function()
			ticket += 1
			stop()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			scale:Destroy()
			if edgeTab then
				edgeTab:Destroy()
			end
		end,
	}
end

-- O5: a title card before the window's first opening. It never delays a
-- player who asked for less motion by more than the hold, and `skip` ends it
-- at once for a rerun or an impatient tap.
local function playIntro(screen: ScreenGui, title: string, onDone: () -> ()): () -> ()
	local finished = false

	local card = Instance.new("CanvasGroup")
	card.Name = "Intro"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AutomaticSize = Enum.AutomaticSize.XY
	card.BackgroundTransparency = 1
	card.GroupTransparency = 1
	card.Parent = screen

	local column = Instance.new("UIListLayout")
	column.HorizontalAlignment = Enum.HorizontalAlignment.Center
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Padding = UDim.new(0, 12)
	column.Parent = card

	local name = Instance.new("TextLabel")
	name.Name = "Title"
	name.LayoutOrder = 1
	name.AutomaticSize = Enum.AutomaticSize.XY
	name.BackgroundTransparency = 1
	name.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	name.TextSize = 28
	name.TextColor3 = THEME.text
	name.Text = title
	name.Parent = card

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.LayoutOrder = 2
	line.Size = UDim2.fromOffset(0, 2)
	line.BackgroundColor3 = THEME.accent
	line.BorderSizePixel = 0
	line.Parent = card

	local function finish()
		if finished then
			return
		end
		finished = true
		card:Destroy()
		onDone()
	end

	TweenService:Create(card, timing(MOTION.enter), { GroupTransparency = 0 }):Play()
	TweenService:Create(line, timing(MOTION.line), { Size = UDim2.fromOffset(120, 2) }):Play()
	task.delay(INTRO_HOLD, function()
		if finished then
			return
		end
		local fade = TweenService:Create(card, timing(MOTION.exit), { GroupTransparency = 1 })
		fade.Completed:Once(finish)
		fade:Play()
	end)
	return finish
end

return {
	createWindow = createWindow,
	playIntro = playIntro,
}
```
