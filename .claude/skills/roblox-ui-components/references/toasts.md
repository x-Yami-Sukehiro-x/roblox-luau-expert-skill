# Toasts and notifications

There is **no credible open-source Roblox toast library.** A GitHub survey on
2026-09-10 returned nothing above two stars, all of it unmaintained. So this is a build
guide, not a recommendation — re-check before treating that as still true.

Roblox does ship one first-party path, `StarterGui:SetCore("SendNotification", ...)`.
It is worth knowing and worth rejecting: it renders in the CoreGui style you cannot
theme, gives you no control over stacking, dedup, or duration beyond a `Duration`
field, and caps at three buttons. Use it for a throwaway debug ping, not for product
UI.

Working implementation: `library/src/Toast.luau`.

A toast is a transient, non-blocking message that appears, is readable without
interaction, and leaves on its own. Almost everything that goes wrong with them comes
from ignoring one of those three words.

---

## First: is a toast the right pattern?

For the decision across an entire script, use
`../../roblox-script-feedback/SKILL.md`. A toggle's visible selected state or a
slider's live value often supplies all the feedback needed; no toast is added
merely because a callback ran.

| Use | Pattern |
|---|---|
| Confirming something that happened | **toast** |
| Low-stakes information the player can miss | **toast** |
| Something requiring a decision | **modal** — blocks, waits |
| An ongoing condition (offline, event active) | **banner** — persistent, dismissible |
| A field is wrong | **inline** — next to the field |
| Something the player *must not* miss | **not a toast** |

The failure test: **if it would be a problem for the player to miss this, a toast is
wrong.** Toasts auto-dismiss and appear away from where the player is looking. A
failed purchase, a data-save error, or a ban warning does not belong in one.

Also wrong for toasts: anything long, anything with more than one action, and anything
requiring deliberation. A toast is read in about a second and a half at a glance.

---

## The five hard parts

Naive implementations get the happy path right and these wrong.

### 1. Reflow when a middle toast dies

Three toasts stacked. The **middle** one's timer expires. The one below must move up
into the gap while the one above stays put — and it must do so smoothly while a
fourth may be entering from the queue.

This is the part that separates a real system from a demo. Position must be **derived
from index**, not stored, and the movement must be a **spring** because the target can
change mid-flight (`roblox-ui-motion/references/springs-and-smoothdamp.md`).

```lua
-- Recompute every visible toast's target from its index. Springs handle the rest.
local function reflow(self)
    local offset = 0
    for index, entry in self._visible do
        entry.targetY = offset
        offset += entry.height + GAP
    end
    -- each entry's spring loop reads entry.targetY every frame
end
```

Animating position directly with a tween here produces the classic bug: a toast that
snaps when a second one expires during its move.

### 2. Duplicates

"+1 Coin" fired forty times in two seconds must not produce forty toasts.

Collapse on a **dedup key**. If a live toast has the same key, reset its timer and
increment a count badge rather than adding a new one.

```lua
local existing = self._byKey[key]
if existing then
    existing.count += 1
    existing.label.Text = ("%s (x%d)"):format(message, existing.count)
    existing.expiresAt = os.clock() + duration      -- refresh, do not stack
    return existing
end
```

Without this, any reward loop turns the screen into a wall of toasts.

### 3. Pause on hover

A player reading a toast when the timer expires loses it mid-sentence. Pause the timer
on `MouseEnter`, resume on `MouseLeave`.

Store **remaining time**, not an absolute deadline, or the pause maths breaks:

```lua
entry.frame.MouseEnter:Connect(function()
    entry.paused = true
    entry.remaining = entry.expiresAt - os.clock()
end)

entry.frame.MouseLeave:Connect(function()
    entry.paused = false
    entry.expiresAt = os.clock() + entry.remaining
end)
```

There is no hover on touch **or on gamepad**, so the pause mechanism simply does not
exist for two of the four input models. Both need a different affordance:

| Input | Pause | Dismiss |
|---|---|---|
| Mouse | hover | click, or auto |
| Touch | none — give a longer default duration | tap |
| Gamepad | none — pause while the toast is `GuiService.SelectedObject` | B / back |
| Keyboard | none | Esc dismisses the newest |

On a gamepad, do **not** steal focus for a toast. A toast is not worth interrupting
what the player was navigating. Make it selectable only when it carries an action,
and even then leave `GuiService.SelectedObject` alone unless the severity is `error`.

### 4. The queue

Cap what is **visible** and queue the rest. More than three or four on screen and
nobody reads any of them.

Height has to come from somewhere before the reflow maths can run. Either give every
toast a fixed height and accept truncation, or measure the wrapped text up front with
`TextService:GetTextBoundsAsync` — see `roblox-ui/references/typography.md`. Reading
`AbsoluteSize` on the frame you just created returns zero: layout has not run yet.

```lua
local MAX_VISIBLE = 3

function Toast.push(self, options)
    if #self._visible >= MAX_VISIBLE then
        table.insert(self._queue, options)
        return
    end
    self:_show(options)
end
```

When one leaves, pull the next from the queue. Two rules that matter:

- **Cap the queue too.** An unbounded queue after a burst means toasts still arriving
  thirty seconds later, describing things the player has forgotten. Drop the oldest
  low-priority entries past ~10.
- **A high-priority toast preempts.** An error should not wait behind three "+1 Coin"
  messages — insert it at the front, and if the visible set is full, evict the oldest
  low-priority one early.

### 5. Cleanup

Every toast is a `Frame`, at least two connections, a timer thread and possibly a
spring loop. A dismissed toast that leaves any of those behind is a slow leak that
only shows up after an hour of play.

Own the whole lifetime with a Trove per toast and destroy it on exit — including when
the toast is removed early by preemption or by the container closing.

---

## Duration

3–6 seconds is the usable band. Scale it to the message rather than picking one
number:

```lua
local function durationFor(message: string): number
    local words = select(2, message:gsub("%S+", "")) + 1
    return math.clamp(2.5 + words * 0.35, 3, 8)
end
```

- **Never auto-dismiss a toast with an action** the player might want to take. If it
  has a button, it needs a close control and no timer, or a long one.
- **Errors get longer**, or no timer at all.
- On touch, add ~1s — there is no hover-to-pause.

**1.5 seconds is the floor, and it is a gate.** `lint-roblox-ui.mjs` fails any
constant named for a toast lifetime that is set below it. Under 1.5 s the
message appears and leaves inside a glance, so the player registers that
*something* flashed and never learns what. A toast nobody reads is not a
cheaper toast; it is an animation.

### The timer starts before the toast has arrived

The trap that produces most sub-second toasts is arithmetic, not taste:

```lua
-- 0.85s of life, 0.20s of which is the entrance and 0.15s the exit.
-- Readable at rest: 0.50s.
tween(toast, OPEN):Play()
task.delay(TOAST_LIFETIME, function()
    tween(toast, CLOSE):Play()
end)
```

The delay runs from the moment the entrance *starts*. Whoever picked `0.85`
was thinking about how long the toast is on screen; what they set was how long
until it begins leaving. Either start the timer when the entrance finishes, or
budget for it:

```lua
local hold = durationFor(message)
task.delay(OPEN.Time + hold, dismiss)
```

Same mistake in the other direction: a hover-pause that resets `expiresAt`
without accounting for the exit tween makes a toast that never leaves.

---

## Placement

Placement is surface-specific and getting it wrong covers gameplay.

**Game HUD.** Top-centre or top-right for feedback; bottom-centre reads as more
prominent but collides with mobile controls. Whatever you choose must respect:

```lua
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
```

and, if positioning manually, `GuiService.TopbarInset` — a `Rect`, `[ReadOnly]`,
and the exact answer. **Do not hardcode a topbar height.** A staff post says 36px and
community replies say 58px; both are quoted as fact and neither is safe, because the
value varies by client and platform. `GuiService:GetInsetArea(insets)` gives the same
answer for a specific `Enum.ScreenInsets` mode.

Reflow when it changes rather than measuring once:

```lua
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(reflow)
```

Mobile virtual controls occupy the bottom-left and bottom-right corners. Anything
placed there is unreadable and blocks input on phones.

**Executor hub UI.** Usually bottom-right, parented via `gethui()` so it is not sitting
in `PlayerGui` for the game to enumerate.

**Studio plugin.** Inside the widget, not floating over Studio.

Growth direction should match the anchor: toasts anchored at the top grow **downward**,
anchored at the bottom grow **upward**. The newest should be nearest its anchor so the
eye lands on it first.

---

## Severity

Four levels is enough: `info`, `success`, `warning`, `error`.

**Never encode severity in colour alone.** Colour-blind players and anyone glancing
past it get nothing. Pair colour with an icon and, where it matters, a word.

Severity should change the toast's **behaviour**, not just its tint:

| Severity | Duration | Priority | Dismissable |
|---|---|---|---|
| `info` | short | low | auto |
| `success` | short | low | auto |
| `warning` | longer | medium | auto |
| `error` | longest or none | high, preempts | manual close |

---

## Motion

Enter and exit differ — see `roblox-ui-motion/references/choreography.md`.

- **Enter**: slide a short distance from the anchor edge plus fade, `Out` easing,
  ~0.18–0.22s. Slide **a small distance** — 12–20px, not across the screen.
- **Exit**: fade plus a small slide in the same direction, `In` easing, ~0.15s.
- **Reflow**: spring, because the target moves while it is moving.
- **Reduced motion**: fade only, no travel, honouring
  `GuiService.ReducedMotionEnabled`.

Fade the whole toast with `CanvasGroup.GroupTransparency` rather than tweening the
frame, label, icon and stroke separately — one tween, and no half-faded contents.

---

## Accessibility and polish

- Contrast at least 4.5:1 for body text against the toast background.
- Never colour alone for meaning.
- Honour reduced motion and `GuiService.PreferredTransparency` — a player who has
  turned transparency down should not get a glass toast they cannot read.
- Never stack a toast over the thing it describes.
- Keep the text short enough to read in one glance. If it does not fit in a line and a
  half, it is not a toast.

---

## API shape

Keep the call site trivial — a toast is fired from gameplay code that should not know
about queues:

```lua
Toast.info("Saved")
Toast.success("Purchased Dragon Sword")
Toast.warning("Inventory almost full")
Toast.error("Could not reach the server", { dismissable = true })

Toast.push({
    message = "+1 Coin",
    severity = "success",
    key = "coin",          -- dedup key: repeats increment a count
    duration = 3,
    icon = "rbxassetid://...",
    action = { text = "Undo", callback = undo },   -- suppresses the auto-timer
})
```

One module-level container, created lazily on first use, destroyed with the
controller that owns it.

---

## Checklist

- [ ] Would it be a problem if the player missed this? Then not a toast.
- [ ] Max visible capped; overflow queued; queue itself capped.
- [ ] Duplicates collapse on a key with a count, not stacked.
- [ ] Timer pauses on hover; touch has tap-to-dismiss.
- [ ] Reflow is spring-driven and derived from index.
- [ ] High severity preempts and can evict.
- [ ] Respects `ScreenInsets` and `GetGuiInset()`; clears mobile controls.
- [ ] Severity is not colour-alone.
- [ ] Reduced motion honoured.
- [ ] Every toast has a teardown covering early removal.
