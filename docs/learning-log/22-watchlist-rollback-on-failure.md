# Optimistic UI needs a pessimistic fallback, not just a happy path

**Ships:** watchlist add/remove now roll back the optimistic UI update and alert the user when the underlying database write fails. Flagged in the engineering trace, not a numbered issue.

## The problem

Three call sites — the scan-card "+ watchlist" button, the watchlist's manual add input, and the ✕ remove button — all followed the same pattern: mutate the local `watchCompanies` array and re-render immediately, then fire `addWatchCompany`/`removeWatchCompany` in the background. Both of those functions swallowed their own errors (`catch(e){ console.error(e); }`, no return value), so a failed write was invisible to the caller — the chip stayed exactly as optimistically drawn regardless of whether the database actually agreed. A user could believe a company was tracked (or removed) when the write silently never landed.

## The fix

- `addWatchCompany` / `removeWatchCompany` now return `true`/`false` based on whether the write actually succeeded, instead of just logging and returning nothing.
- All three call sites check that result: on failure, they undo their own optimistic mutation (re-add to the array on a failed remove, filter back out on a failed add) and tell the user directly — a `title` update on the button for the scan-card path, an `alert()` for the two watchlist-view paths, since those don't have an adjacent status element to write into.

## What this taught me

"Optimistic UI" is only half a pattern without the pessimistic half — updating immediately and hoping the write succeeds is fine, but it needs a real failure branch, not just a `console.error` that only a developer with dev tools open will ever see. Any function that returns nothing and only logs its own errors is a function whose callers can't tell success from failure — worth checking, for functions like this, whether every caller actually needs to know.
