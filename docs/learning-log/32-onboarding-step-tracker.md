# A view with no display:none is invisible right up until it isn't

**Ships:** removes a flash-of-wrong-view bug on sign-in, replaces the static onboarding banner with a live 3-step tracker (write stance → generate scoring → connect AI key → "you're ready"). Closes #101.

## The problem

`showApp()` set `appShell.style.display = ''` as its very first line, then ran a string of `await`s before calling `switchView('profile')` at the end. Every view but `viewScan` had `display:none` baked into its markup — `viewScan` didn't, because it happened to be the default-visible view when the file was first written, and `switchView()` only ever *adds* `display:none` to the others, it never needed to un-hide Scan specifically. The result: revealing `appShell` early showed Scan, unstyled by the onboarding gate, for the duration of `initLoad()` and the other setup calls — a real flash, not a perception issue.

Separately, the onboarding banner (from #99) explained the 2 required steps in one static paragraph, with only a subtle line-through once each was done. Nothing signaled *which* step to act on right now, and there was no persistent "you are here" marker as you moved through the form.

## The fix

- Added `display:none` to `viewScan`'s markup, matching every other view.
- Moved `appShell.style.display = ''` to the end of `showApp()`, after `switchView()` has already run — so the shell only ever becomes visible already showing the correct view. No view starts visible by default anymore; `switchView()` is the only thing that reveals one.
- Replaced the banner with a real 3-step tracker: `onboardingState()` now returns `stanceDone`/`rubricDone`/`keyDone` (previously just `rubricDone`/`keyDone` — stance text wasn't tracked as its own step even though it's the actual first thing the user does). `refreshOnboardingUI()` marks exactly one step `current` (the first not-done one) and every earlier step `done`, so there's always exactly one "do this now."
- Once all 3 are done, the banner switches to a quiet `.done` style (muted background, no longer phosphor-highlighted) with a "you're ready" heading, instead of just disappearing — a small in-app confirmation that onboarding actually finished, states plainly ("scoring is set up and your AI key is connected") rather than just vanishing without saying why.

## What this taught me

The flash bug existed because "hidden by default" wasn't actually a rule anywhere — it was an accident of which view happened to be first in the file when multi-view switching was added. Once one view is exempt from the pattern, every future change (like the onboarding redirect) has to remember to special-case it, and eventually one won't. Making "every view starts hidden, only `switchView()` reveals one" an actual invariant — not just the common case — removes a whole class of future flash bugs, not just this one.
