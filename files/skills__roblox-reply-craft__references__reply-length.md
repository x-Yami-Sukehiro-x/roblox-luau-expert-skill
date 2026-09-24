# Reply length and wording

The user asked for a script. Every sentence around it is something they have
to read before they can use it. Generated replies pad in the same places every
time: an opening that agrees with the request, a heading per paragraph, a
restatement of the code in prose, and a closing offer. Remove those and the
reply is mostly code, which is what was asked for.

---

## The shape

1. **One line**: what was built. "A hub with auto farm and walk speed, T1
   toggles and N4 notifications."
2. **The code**, whole, one block per file (`code-output.md`).
3. **Where it goes**, in Studio's words, and what success looks like.
4. **Up to three assumptions**, each one line, phrased so the user can reject
   it without knowing terms.

A fix to an error: the cause in one sentence, the whole corrected file, what
to check. A question: the answer first, then the reason if it is not obvious.

## Lengths

| Text | Limit |
|---|---|
| Summary line | one sentence |
| A description of a file, feature or toggle | one line, under 80 characters |
| A caption under an image or a file | under 60 characters |
| An assumption | one line |
| Explanation of a term on first use | 4 to 8 words, in the same sentence |
| The whole reply, excluding code | about 120 words for a normal build |

## Cut these

| Cut | Example |
|---|---|
| Openers | "Certainly!", "Great question!", "Sure, here's…", "I'd be happy to…" |
| Restating the request | "You want a toggle that turns on auto farm. Here is a toggle that turns on auto farm." |
| Narrating the code in prose | "First we get the Players service, then we create a ScreenGui…" |
| Headings on a short reply | "## Overview", "## Implementation", "## Conclusion" |
| Filler adjectives | robust, seamless, powerful, comprehensive, elegant, clean |
| Hedges | "This should work", "hopefully", "you may want to consider" |
| Closers | "I hope this helps!", "Let me know if you have any questions!", "Happy coding!" |
| Emoji and decorative symbols | ✅ 🚀 ✨ → |
| Repeated warnings | the same caveat in the intro and the outro |

## Keep these

- What was **not** checked, and what the user must test themselves.
- The one assumption that would change the build if wrong.
- The exact thing to click or press to see it working.

## Before and after

> **Generated**: Certainly! I'd be happy to help you create an amazing auto
> farm toggle for your game! 🚀 Below you'll find a robust, fully-featured
> implementation that seamlessly integrates with your existing UI. Let's dive
> in! ## Overview … ## Conclusion — I hope this helps! Let me know if you have
> any questions!

> **Written**: An auto farm toggle (T1) that collects coins within 30 studs.
> *[code]* LocalScript in StarterPlayerScripts. Press Play, switch it on: coins
> near you disappear into your total. Assumes coins are Parts tagged `Coin`.
