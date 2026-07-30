# A caveat that only fires at zero results misses the case that actually needs it

**Ships:** scan surfaces a "some results may be missing" note when JSON recovery kicks in but still returns results, matching the pattern plan generation already had. Closes #53.

## The problem

Both `runScan()` and the plan generator fall back to entry-by-entry
recovery (`splitTopLevelObjects` / `recoverKeyedArray`) when the
model's JSON response fails to parse — good resilience, but the two
call sites surfaced it differently. Plan generation tracked a
`recovered` boolean independent of how many entries came out the other
side, and appended a caveat ("response ran long and got trimmed —
regenerate if anything looks missing") whenever recovery ran at all.

`runScan()` only set its `recoveredNote` when `freshJobs.length` was
literally zero — the case where recovery produced *some* results (the
much more common case, and the one where a user is most likely to
trust the list as complete) got no signal whatsoever. A scan that
silently dropped 2 of 7 postings due to a parse hiccup looked
identical to a clean scan that genuinely only found 5.

## The fix

Mirrored the plan flow's pattern exactly: track `recovered` as its own
boolean, set the moment the inner `JSON.parse` throws, independent of
what `splitTopLevelObjects` manages to salvage. The status line now
has three distinct states — clean parse (no caveat), recovered with
results (new: "response was malformed, recovered what could be parsed
— some results may be missing"), and recovered with nothing (existing:
"no entries could be recovered — try again").

## What this taught me

Two near-identical recovery mechanisms, written for two different call
sites, drifted into different UX despite doing the same underlying
thing — the plan flow's version was already correct and just needed
copying over, not redesigning. Worth checking, when two code paths do
structurally the same fallback: did one already solve the edge case
the other missed?
