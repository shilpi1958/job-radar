# A per-user fix upstream doesn't erase the persona baked in downstream

**Ships:** scan keywords, location, and focus-area chips default to empty instead of one person's job search. Closes #50.

## The problem

`#6` (closed) made the scoring rubric and stance per-user — a real fix, no
longer hardcoded to one candidate. But the Scan view itself still
defaulted `kw` to `"AI product manager robotics OR deep tech OR
early-stage builder"`, `loc` to `"Bengaluru or Remote India"`, and
pre-checked the `deeptech` and `builder` focus-area chips —
all the same original persona's specific search, untouched by that
earlier fix because it lived in a different part of the file (the
input `value` attributes and `activeTags` initial set, not the rubric
prompt constants #6 actually touched).

The result: onboarding correctly asks a new user "what are you looking
for" and generates a personal rubric from their answer, then the very
next screen a new user hits — Scan — quietly assumes they're
searching for robotics PM roles in Bengaluru unless they notice and
clear three separate fields first. The app fixed *scoring* per-user
and left the *search itself* pointed at a stranger.

## The fix

- `kw` and `loc` inputs: `value="..."` → `placeholder="e.g. '...'"`,
  so the example stays visible as guidance but submits as empty
  unless the user actually types something.
- Removed `active` from the `deeptech`/`builder` preset chips, and
  emptied `activeTags`'s initial `Set(['deeptech','builder'])` to
  match — no focus area is pre-selected.
- Verified `focusAreasText()` already degrades gracefully to a general
  fallback string when `activeTags` is empty and no keywords are
  typed, so a blank-everything scan doesn't break, it just searches
  more broadly — no new validation needed.

## What this taught me

While reading `focusAreasText()`'s fallback, found it and the actual
scan/plan prompt templates (`DEFAULT_PROMPT_SCAN` etc.) still say
"her"/"she" throughout — a deeper, separate instance of the exact same
class of bug, just living in the prompt text sent to the model rather
than the UI defaults. Flagged as its own follow-up rather than folding
it into this fix, since rewriting ~18 occurrences across prompt
templates is a materially different, larger diff than swapping `value`
for `placeholder`. Worth remembering: "per-user now" claims from an
earlier fix are a claim about the code that fix touched, not a
guarantee about every other place the same assumption was baked in.
