# A single flag shouldn't cost the same as loading the whole app fresh

**Ships:** flagging a broken link now removes just that one card instead of re-fetching and re-rendering the entire scan history. Closes #77.

## The problem

`markLinkBroken()` flagged one job (`broken_links.upsert`), then called `await loadStack()` — which re-queries the user's *entire* scan history via `getUnifiedJobs()` and rebuilds every card in `#results` via `innerHTML`. A single-row mutation was O(n) in both network cost and DOM rebuild cost, where n is the user's whole stacked results list, not the one card that actually changed.

Separately, the write's error was silently swallowed (`catch(e){ console.error(e); }`) — a failed `upsert` still proceeded to re-fetch and re-render as if the flag had actually landed, so a user could believe a link was marked broken when the write never persisted.

## The fix

- Added `data-job-key` to each card's root `div` so a specific card can be targeted for removal without touching the rest of the list.
- `markLinkBroken()` now checks the write's result explicitly; on failure it alerts the user and leaves everything untouched — no removal, no re-render, matching the rollback pattern already used for watchlist writes.
- On success, it filters the flagged job out of `currentResults` and removes just that one card from the DOM (`card.remove()`) — no `getUnifiedJobs()` call, no full re-render. `render()` only fires if the list just became empty, to show the empty-state message. `renderWatchResults()` was already synchronous (filters `currentResults` in memory, no DB call) — dropped the unnecessary `await`.

## What this taught me

`loadStack()` was reused here because it was the obvious existing tool for "make the results view correct again" — but "correct" only required removing one row, and the function's actual job is "fetch everything and rebuild everything." Reaching for the broad tool because it exists and happens to produce the right end state is a common way an O(1) fix turns into an O(n) one; worth asking, before calling a full-refresh function after a single-row mutation, whether the DOM can just be told what changed directly.
