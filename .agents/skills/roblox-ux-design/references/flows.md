# Flows written out

Each flow is the few lines to write before building, then the states the
screen needs because of it. Copy the shape; replace the words with the
game's.

## Buying something

```
Open:     item row -> detail panel (price, what it does, owned or not)
Act:      "Buy for 250 coins"
Pending:  the button reads "Buying..." and ignores presses until the result
Result:   the row shows Owned; the balance updates from the server's value
Can't:    button disabled: "120 more coins"; never an error after the press
Fail:     "Couldn't buy: try again" on the button, which re-enables
```

States: affordable, unaffordable, pending, owned, failed. A second press while
pending does nothing; the server's answer decides owned, not the click.

## Deleting or spending something that cannot come back

```
Act:      "Delete Golden Sword" (the object in the label)
Confirm:  one dialog: "Delete Golden Sword? It can't be recovered."
          buttons "Delete" and "Keep"; Keep is the default focus
Result:   the row leaves the list; a short undo is better than the dialog
          when the game can undo
```

Never two confirmations. Never a confirmation for something undoable.

## Settings

```
Change:   applies at once, shown at once (slider value beside the slider)
Save:     automatic, after the player stops changing (not every tick)
Reset:    "Reset to defaults" at the bottom, with one confirmation
Leave:    nothing to apply; closing keeps every change
```

An Apply button exists only when a change is expensive or risky to preview
(a graphics mode that reloads). Then show what is unapplied.

## Search and filter

```
Show:     search when a list passes about 12 rows; filters when items
          have an obvious category
Type:     results update as the player types; the query stays when the
          panel closes and reopens
Empty:    "No pets named 'drag'" with a clear-search button
```

## A task with steps (trade, crafting, quest hand-in)

```
Steps:    visible as a short row: Offer -> Review -> Confirm
Back:     every step but the last can go back without losing input
Lock:     the final step shows exactly what changes hands, then one
          confirm; the other side's changes reset it
```

## First run

```
Open:     the window opens by itself once, on the most useful tab
Hint:     one line where the first action is ("Pick a zone to start")
Later:    never again automatically; the open button or key brings it back
```

No welcome screen, no tour, no loading bar that measures nothing.

## An executor hub

```
Open:     runs open; one key hides and shows it; a small open button on
          touch when hidden
Act:      a toggle is on only while its feature runs; a failure turns it
          off with the reason in its description
Save:     choices kept across reruns; across sessions when the executor
          can write files, and the window says once when it cannot
Leave:    close hides; Unload in Settings restores the game and removes
          everything
```
