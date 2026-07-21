# The database was multi-user before the product was

**Ships:** per-user scoring rubric + stance, onboarding gate, Profile/Settings split. Closes #6.

## The problem

RLS, per-user tables, magic-link auth — all of it was real and working
(verified directly in earlier work on this project). But the actual
scoring logic underneath all of it was still single-user: two constants,
`CANDIDATE_STANCE_TEXT` and `RUBRIC_TEXT`, described one specific
person's career goals and a fixed point-weighted rubric, and every scan,
plan, and watchlist call for *every* signed-in user got the same two
constants injected. The infrastructure said "multi-user." The product
said "built for one person, everyone else inherits her identity."

This came out of a structured product review (asked "how would a senior
PM at a company like LinkedIn review this") rather than from a bug
report — nothing was throwing errors, the app worked exactly as
designed. The gap only became visible by asking what happens to a
*second* real user, not by testing the one persona it was built for.

## The fix, and why it's shaped this way

Three linked decisions, each deliberately kept small rather than solved
in one sweeping rewrite:

1. **The AI generates the rubric, not code.** Rather than writing logic
   to infer "how important is location to this person" from their
   answers, one model call turns plain-language input into both a
   stance paragraph and a weighted rubric, generated once at
   profile-save time and reused across scans — same cost shape as the
   old hardcoded constants, just personalized. Point weights stay
   hidden from the user; they answer plain questions, not "tune these
   four sliders."

2. **Fallback, not a breaking migration.** `buildStanceAndRubric()`
   falls back to the original constants if a user hasn't generated
   their own yet — so existing usage (mine) kept working through the
   whole build, and a new user who skips setup doesn't hit a broken
   scan, just a generic one.

3. **The onboarding gate had to check the *right* thing.** First pass
   gated on `job_stance` (raw textarea) being non-empty. That was
   wrong: typing text alone doesn't generate anything, so a user who
   typed a sentence and wandered off would pass the gate while still
   silently scoring against the generic fallback with no indication
   that's what was happening. Fixed to gate on `generated_rubric`
   existing — the thing that actually changes scan behavior, not the
   raw input that precedes it.

## What surfaced along the way (and why those got fixed too, not filed separately)

Two more problems showed up only once the onboarding gate made a new
user actually *look* at the Profile tab for the first time:

- **AI keys were the first thing shown**, before any explanation of
  what the app does or why a key is needed. Reordered so stance/skills
  come first, keys reframed as "the activation step," not the opener.
- **AI keys, GitHub, and prompt templates were mixed into "Profile"**
  alongside actual candidate data (stance, skills, CV) — one flat list
  conflating "who you are" with "how the app is wired up." Split into
  a separate Settings tab.

Both were fixed inline rather than filed as separate issues, because
they were direct consequences of the same change (surfacing the
Profile tab to new users) — filing them separately would have meant
shipping a visibly broken first-run experience and coming back to fix
it in a follow-up, instead of just finishing the thought.

## What this taught me

A README claim like "multi-user" can be true at the infrastructure
layer and false at the product layer simultaneously, and nothing in
normal usage will surface the gap — the one user testing it is the
one user the hardcoded logic was written for, so it always looks
correct. The way this actually got caught was structured review from
an outside frame ("how would a PM evaluate this for a second user"),
not testing. Also: fixing a gate condition matters as much as adding
the gate — checking the wrong signal (raw input vs. an actual
generated result) reintroduces the exact silent-fallback problem the
gate was built to prevent.
