# A banner that lies about being done is worse than no banner

**Ships:** onboarding banner and gating now check both required steps (scoring + API key), not just one. Closes #7.

## The problem

#7 was scoped wide originally — a full guided first-run flow — but most
of that had already landed piecemeal across earlier work: #6 added a
gated banner ("3 quick things first") that lands new users on Profile
until they've generated a scoring rubric, and #8 added cost/timing
copy next to the scan button. What was left wasn't a missing flow, it
was a banner that only checked one of its own three listed steps.

`generateRubricFromStance()` hid the onboarding banner unconditionally
on success — even though step 3 on the same banner ("connect an AI
key — required to scan") was never checked. A user could write their
stance, generate a rubric, watch the banner disappear, navigate to
Scan, click "run scan," and hit a jarring `alert()` telling them to go
back to Profile for a key. The banner claimed onboarding was done. It
wasn't.

## The fix

- Banner now tracks two real steps (dropped "proof points" from the
  numbered list — it's explicitly optional, doesn't belong in a gate),
  each independently checked: `generated_rubric` existing, and either
  API key being present in localStorage.
- `refreshOnboardingBanner(rubricDone, keyDone)` strikes through
  whichever step is done and only hides the banner when both are —
  called after rubric generation succeeds and after either key save,
  so it updates live without a reload.
- Added a plain-sight notice on the Scan panel itself
  (`scanKeyNotice`) that shows whenever no key is connected, toggled
  by the same `loadApiKeyStatus()` call that already runs on load and
  after every key save. The reactive `alert()` in `requireApiKey()`
  still exists as a backstop, but a user should see the gap before
  clicking, not after.

## What this taught me

A completion banner is a claim, and claims need to be checked against
the same state a later action depends on — not against whichever step
happened to finish first. The bug wasn't in the banner's copy or its
gating logic in the abstract, it was that "done" was wired to one
`await` out of three. Worth checking, for any multi-step gate: does
"hide" require all steps, or just the one that happened to complete
last?
