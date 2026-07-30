# Two of three long calls had the pattern, one didn't — again

**Ships:** rubric generation now shows the same animated "scanning" indicator and up-front timing copy as scan/plan. Closes #52.

## The problem

Three actions in the app make a blocking LLM call the user waits on:
scan (~30-60s), rubric generation, and plan generation. Scan already
set an expectation up front ("live search, ~30-60s, real spend") and
plan generation already toggled `planStatus.className = 'status
scanning'` during the call, picking up the existing `.status.scanning`
amber color + animated dot-ellipsis (`@keyframes dots`). Rubric
generation did neither — no timing copy before the click, and its
status span was a static `<span class="hint">`, never wired to any
animated state, so a first-time user clicking "update my scoring" had
zero signal beyond a text swap that anything was happening at all.

This is the same shape of gap as #58 (one button skipping a pattern
the other two already had) — not a missing feature, a missing
application of an existing one.

## The fix

- `rubricStatus` couldn't just take `.status`'s class outright — it's
  an inline `<span>` next to the button, using `.hint` styling, not
  `.status`'s block layout. Instead, extended the CSS: the dot
  animation and amber color now also apply to `.hint.scanning`,
  reusing the same `@keyframes dots` rather than duplicating it.
- `generateRubricFromStance()` now adds/removes the `scanning` class
  around its `callLLM` call, same lifecycle as `planStatus` already
  had.
- Added the missing up-front timing line to both the rubric button
  ("~10-20s") and the plan button ("~20-40s"), matching scan's
  existing "~30-60s" disclosure — closing the third gap the issue
  named alongside the missing animation.

## What this taught me

When one of three near-identical call sites is missing a UX pattern
the other two already have, check whether the fix is "build something
new" or "wire up what's already sitting in the CSS." Here the
animation, the color variable, and the keyframes all existed — the gap
was purely that one status element's markup (`<span class="hint">`
instead of the pattern used elsewhere) never got the class toggled
onto it. Cheaper to extend the existing selector to cover both element
shapes than to restructure the markup to match the other two exactly.
