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
| W7 | "the pages", "sections", "categories" | tabs | see S1–S12 |
| W8 | "the little titles", "group names" | section heading | 12 px caption, muted, above a group |
| W9 | "on/off thing", "switch", "tick" | toggle | see T1–T30; a plain checkbox is C1–C20 |
| W10 | "the bar you drag", "number bar", "range" | slider | shows its value; arrow keys and gamepad step it |
| W11 | "list that opens", "picker", "choose one" | dropdown | closes on outside tap; long lists scroll; see D1–D12 |
| W12 | "the button" | button | label names the action: `Teleport to spawn` |
| W13 | "key box", "hotkey", "bind" | keybind chip | shows the key; press to rebind; Escape cancels |
| W14 | "search bar", "find box" | search box | filters as they type; clear button; D5 or D11 |
| W15 | "typing box", "where I put the name" | text box | placeholder, focus ring, inline error (N3) |
| W16 | "popup message", "alert", "notification" | toast / notice | see N1–N20 |
| W17 | "the hint when I hover" | tooltip | H1–H12; never the only place information lives; phones have no hover |
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
