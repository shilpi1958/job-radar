# A model can't be checked against ground truth, but it can be checked against itself

**Ships:** `scoreInconsistency(job)` — flags scan results where the model's own score contradicts its own stated gate or reasoning, surfaced as a `⚠ inconsistent` marker on the card plus a running lifetime count. Closes #104.

## The problem

`runScan()` makes one model call that both searches the web and scores each result 0-100 against a rubric — nothing downstream ever checks whether that score is sane. The concrete failure mode: a job comes back with `gate: "requires 3+ yrs SWE"` (the model's own stated hard blocker) and `score: 88` in the same object, and the card renders both a bright green 88% meter and a red gate warning with no reconciliation between them. A user skimming the meter first would trust a score the model itself had already contradicted three fields over.

"Is this score accurate" isn't checkable without ground truth (a human re-scoring every job) — that's a real eval, and it needs infrastructure this project deliberately deferred (PostHog, until the eventual multi-file refactor). But "does this score contradict the model's own other fields" needs no ground truth and no external service — the contradiction is entirely inside the response object already sitting in memory.

## The fix

- `scoreInconsistency(job)`: three checks against fields already on the job — score outside 0-100, `gate` set but `score >= 70`, or a score with neither `fit` nor `jd_summary` text to justify it. Pure function, no I/O.
- `scoreMeterHtml(job)` — pulled the previously-duplicated meter markup (it existed once in `render()` for scan results and again in `renderWatchResults()` for the watchlist, both computing `band`/`fillColor` independently) into one shared function that also renders the `⚠ inconsistent` marker when `scoreInconsistency()` returns non-null.
- A lifetime counter (`score_inconsistency_count`) accumulates in settings using the same read-modify-write pattern `recordSpend()` already uses for `spend_total_usd`, and surfaces as a quiet note above scan results whenever it's non-zero — visible when it matters, invisible otherwise.

## What this taught me

Deferring PostHog didn't mean deferring every form of score trust — the distinction that mattered was between "check against ground truth" (needs real infrastructure, real eval data, a human in the loop) and "check for self-contradiction" (needs nothing but the response object that already exists). Conflating the two would have meant either shipping nothing until the refactor, or half-building an eval pipeline the project explicitly isn't ready for. Separating them found a small, honest, zero-infra fix that's still worth having on its own.
