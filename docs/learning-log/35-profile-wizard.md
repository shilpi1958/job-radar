# A "show more" toggle and a wizard look similar on paper, feel completely different in the browser

**Ships:** replaced the collapsed-behind-a-toggle profile section (from #99/#100) with a real linear wizard — one step's card visible at a time, completed/skipped steps collapse into an editable one-line summary, optional steps get an explicit "skip." Closes #109.

## The problem

#99/#100 fixed the original "7 panels dumped on the page at once" problem by wrapping skills/CV/GitHub in a container hidden until onboarding was "done," revealed by a single `▾ show proof points, CV upload, and GitHub` link. On paper this is progressive disclosure — the same idea a wizard uses. In practice it reads completely differently: it's still one flat page, just with some content hidden behind a link that looks like an afterthought, not a guided sequence. Direct feedback: *"i was imagining one card after another like an onboarding flow, this is not a good UX — ask all the details step by step and help user complete the profile."* The gap wasn't about which fields were visible — it was that nothing about the page *felt* like a flow with a beginning, middle, and end.

## The fix

- `WIZARD_STEPS = ['stance', 'apikey', 'skills', 'cv', 'github']`, each wrapped in a `.wizard-step[data-step]` container; only the container matching the current step gets `.active` (`display:block`), everything else stays `display:none`.
- `onboardingState()` extended from 3 fields (stance/rubric/key) to 6 — added `skillsDone`/`cvDone`/`githubDone`, each `true` if the user actually filled it in OR explicitly clicked "skip" (tracked via `skills_step_skipped`/`cv_step_skipped`/`github_step_skipped` settings flags). Skipping isn't silent — it's a real, remembered decision, not just "the user didn't get to it yet."
- `goToWizardStep(step)` is the single function that shows the right card, renders summary rows for every completed-or-skipped step *before* the current one (via `renderWizardSummaries`), and refreshes the horizontal step tracker/banner. Every next/back/skip button just calls this with a different target — no separate state to keep in sync.
- `firstIncompleteWizardStep()` — on page load, resume at the first step that's neither done nor skipped, not always step 1. A returning user who finished stance+key but hasn't decided on GitHub yet lands on GitHub, not back at the beginning.
- The existing per-field load/save logic (`loadStance`, `loadApiKeyStatus`, `loadCvStatus`, `loadGithubStatus`, and their debounced-save `input` handlers) was untouched — the wizard is purely a display-layer state machine on top of code that already worked. Three call sites that used to call the old `refreshOnboardingUI()` (both API-key save handlers, `generateRubricFromStance()`) now call `refreshWizardState()`, which re-runs the same refresh for whichever step is currently showing, without forcing navigation away from it.

## What this taught me

"Progressive disclosure" isn't one pattern — hiding content behind a toggle and stepping through content one screen at a time both technically show less at once, but they communicate completely different things to the user. A toggle says "there's more stuff here if you want it" (optional, browsable, low-stakes). A wizard says "here's what's next" (sequenced, guided, a real path to an end state). The fix here wasn't more hiding — it was replacing a link with a state machine that actually enforces the story "step 1, then step 2, then..." Feedback that names a UX *feeling* ("this doesn't feel like an onboarding flow") is worth taking literally rather than translating into the nearest technical equivalent of what already shipped.
