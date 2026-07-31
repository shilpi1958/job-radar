# Fifteen round trips for five jobs was never a five-job problem

**Ships:** `mergeIntoStack` now upserts jobs and inserts scan results in two batched calls instead of a sequential per-job loop. Flagged in the engineering trace, not a numbered issue.

## The problem

`mergeIntoStack` processed each freshly-scanned job in a `for...of` loop, awaiting three sequential round trips per job: a `select` to find any existing row with the same company+title (needed for `smartMerge`'s "don't overwrite a good location/url with a blank one" rule), an `upsert`, and an insert into `job_scan_results`. A 5-result scan meant up to 15 sequential, awaited round trips — none overlapping, none batched — sitting between the model call finishing and the results actually appearing.

## The fix

- `upsertJobsBatch(jobs)`: one `select ... in('company', [...])` to fetch every existing row these jobs might collide with, then one multi-row `upsert` with the same `onConflict: 'company,title'` key the single-row version used — safe because `jobs.company,title` already has a `unique` constraint (`sql/01_schema.sql`). `smartMerge`'s per-job inherit-on-blank logic is unchanged, just applied client-side against a batch-fetched lookup table instead of a per-job query.
- `insertJobScanResultsBatch(rows)`: one multi-row insert instead of N single-row inserts, using the job IDs the batch upsert returned.
- `mergeIntoStack` now filters eligible jobs once, batch-upserts them, maps the returned rows back to each job by `company::title` key, builds all the `job_scan_results` rows, and inserts them in one call.
- Removed `upsertJob` and `insertJobScanResult` (the old single-row functions) since nothing else called them — dead code once the loop was gone, not kept around as unused scaffolding.

Verified the filter semantics (`!key.trim() || broken.includes(key)`) and the `smartMerge` inherit-on-blank behavior are byte-for-byte the same as before — this is a pure round-trip reduction, not a behavior change.

## What this taught me

The N+1 pattern here wasn't a missing feature — Supabase's `upsert`/`insert` already accept arrays, they just weren't being called that way. The refactor was mostly "do the same select-then-merge logic, but against a batch-fetched lookup table instead of one row at a time" — the actual merge logic didn't need to change at all, only where the round trip happened. Worth checking, for any per-item DB loop: is the constraint actually per-item, or just written that way?
