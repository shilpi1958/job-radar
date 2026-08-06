# A placeholder that never gets cleared isn't a placeholder, it's a default

**Ships:** staged profile onboarding (stance + AI key first, everything else collapsed behind a toggle until both are done), removal of a hardcoded-resume fallback that could leak into real users' plan-generation prompts, and one centralized onboarding-state helper. Closes #99.

## The problem

Tracing sign-in end to end: the sign-in gate itself (Google OAuth + magic-link fallback) is a clean single screen. But the very next thing a new user sees — Profile, forced by the onboarding gate — was 7 panels in one scroll: banner, "how it works", stance textarea, skills textarea, CV upload, AI key form, GitHub form. The onboarding banner names 2 required steps, but the screen didn't visually distinguish those 2 from the 5 that don't block anything.

Worse: `DEFAULT_SKILLS`, a hardcoded block of the developer's own resume, was used both as the skills textarea's initial value *and* as `buildCandidateContext()`'s fallback when the box was empty. A placeholder that a save-on-input handler never actually clears (nothing forces the user to touch the box) isn't really a placeholder — it's the default value that ships to the model. Any real user who left "what you've got" blank would have someone else's career history silently included in their own plan-generation prompt.

## The fix

- Reordered the profile view so AI key (required, currently step 2) sits directly under stance (step 1) — no skills/CV/GitHub in between.
- Wrapped skills/CV upload/GitHub in a `#profileRest` container, hidden until onboarding is complete, with a `▾ show more` toggle for anyone who wants them early.
- Deleted `DEFAULT_SKILLS` outright rather than shortening it — the box now defaults to empty with a placeholder-style hint, matching how `stanceBox` already worked correctly.
- Replaced three separate call sites that each re-derived "is onboarding done" (`showApp()`, both API-key save handlers, `generateRubricFromStance()`) with one `onboardingState()` / `refreshOnboardingUI()` pair — a single place that reads `generated_rubric` + key presence and drives both the banner and the profile section's visibility.

Considered auto-generating the rubric on debounce after the user stops typing in the stance box, to remove the "click update my scoring" step entirely. Rejected it: that call spends real money on the user's own API key, and the copy guidelines already commit to stating costs and timing plainly rather than hiding them — firing a paid model call silently in the background during typing pauses is the opposite of that.

## What this taught me

The bug and the UX friction were the same root cause: nobody had drawn a line between "what's required before you can do anything" and "what's available once you're set up." Without that line, the panels all render together (friction), and the fallback logic reaches for *something* to fill an empty field instead of treating empty as a real, valid state (the leak). Staging the UI and fixing the fallback ended up being the same fix, not two.
