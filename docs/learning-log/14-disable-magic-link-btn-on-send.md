# The first button in the app was the one exception to its own pattern

**Ships:** magic-link send button disables during the async call, re-enables after. Closes #58.

## The problem

`scanBtn`, `genPlanBtn`, and `generateRubricBtn` all disable themselves
before their async call and re-enable after — a consistent pattern
across the app. `authSendBtn`, the very first button a user ever
clicks, didn't follow it: `db.auth.signInWithOtp()` fired with no
`btn.disabled = true` guard, so a double-click (plausible on a slow
connection, or just an impatient click before the "sending…" status
text registers) could fire two magic-link emails for one sign-in
attempt.

## The fix

Added the same disable-before/re-enable-after pattern already used
everywhere else in the app. Re-enables on both success and failure —
on failure so the user can fix a typo'd email and retry, on success so
a legitimate resend (email didn't arrive, went to spam) isn't blocked.

## What this taught me

Small, but worth noting: this was the one button in the entire app
that broke an otherwise consistent pattern, and it happened to be the
very first interaction a new user has. Consistency checks are cheap to
run by just grep-ing every `addEventListener('click'` handler for
whether it guards its own button — worth doing as a matter of course
whenever adding a new async action, not just when a bug report shows up.
