# Read-mostly data was being read fresh every single time it was needed

**Ships:** a per-key cache on `settingGet`/`settingSet`/`settingDelete`, a dedicated cache for `getPortfolio()`, and two sequential-query pairs turned into `Promise.all`. Flagged in the engineering trace, not a numbered issue.

## The problem

Several pieces of data don't change except through an explicit user save — `generated_stance`, `generated_rubric`, prompt overrides, the portfolio list — but every call site that needed them fetched fresh from Supabase every time, with no session-level memory of "I already asked for this." Two concrete costs, called out in the engineering trace:

- `buildStanceAndRubric()` is called independently from `runScan()` and the plan-generation handler — each does its own pair of `settingGet` calls for the same two keys, seconds apart in the same session.
- `getPortfolio()` gets called four separate times across one plan-generate-and-render cycle: once to compute `alreadyTargeted` for the prompt, once in `attachBuildButtons`, once in `renderOlderBuilds`, once in `renderWatchChips` — none of them sharing results even when they run back-to-back.

Separately, `buildStanceAndRubric()` and `getSkillTally()` each awaited two independent queries one after another instead of firing them together.

## The fix

- `settingGet`/`settingSet`/`settingDelete` (the function underlying 18 call sites across the file — scan_log, cv_filename, prompt overrides, generated_stance/rubric, everything) now share a `Map`-based cache keyed by setting name. `settingGet` checks the cache first; `settingSet`/`settingDelete` clear the entry *before* the write is even awaited, so a concurrent read never serves stale data — worst case it just re-fetches once more than strictly necessary.
- `getPortfolio()` gets the same treatment with its own `portfolioCache` variable, cleared by `addPortfolioRepo()` the moment a new repo is actually inserted.
- `buildStanceAndRubric()` and `getSkillTally()` now fire their independent queries via `Promise.all` instead of sequential `await`s.

This is deliberately generic rather than scoped to the two call sites the trace named — caching at the `settingGet` layer means every one of its 18 callers benefits, not just the two that happened to get profiled.

## What this taught me

The cache invalidation here is trivial precisely because none of this data has a "stale but still valid for N seconds" requirement — it's either current (nothing's changed) or explicitly invalidated (something just got written). That's the easy case for caching: when correctness only requires "don't serve data from before the last write," a `Map` cleared on write is enough — no TTL, no staleness policy to get wrong.
