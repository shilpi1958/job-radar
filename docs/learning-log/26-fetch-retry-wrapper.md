# Six network calls, zero retries — a transient blip cost a full re-click

**Ships:** a shared `fetchWithRetry` wrapper with exponential backoff, applied to every external network call in the app. Flagged in the engineering trace, not a numbered issue.

## The problem

Six external call sites — the Anthropic Messages API, the OpenAI proxy, and three separate GitHub endpoints (create repo, write README, fetch repo stats) — had no retry, backoff, or timeout of any kind. A single dropped packet or a transient 502 was indistinguishable from a genuine failure: the user saw the same error either way and had to manually re-click, paying for a second full-price model call or repeating a multi-step GitHub flow, for a problem that would very likely have resolved itself half a second later.

## The fix

Added `fetchWithRetry(url, options, maxRetries=2)`: up to 3 total attempts with exponential backoff (500ms, 1000ms). The retry decision is deliberately asymmetric:

- **Network errors, 429, and 5xx retry** — these are the class of failure a second attempt can plausibly fix.
- **4xx returns immediately, no retry** — a bad API key, malformed request, or 404 won't be fixed by trying the identical request again; retrying just burns time and, for the LLM calls, money.
- On the terminal attempt, if the failure was an HTTP response (not a thrown network error), the function returns that response rather than throwing — every caller's existing `if(!response.ok){ parse the error body }` logic keeps working unchanged. Only a genuine network-level failure (never got a response at all) throws.

Swapped all six call sites from `fetch(...)` to `fetchWithRetry(...)` with no other changes to the surrounding code — the function signature is a drop-in match for `fetch`.

Checked the two `POST`/`PUT` GitHub calls (repo creation, README write) for retry safety before wrapping them: repo creation isn't naturally idempotent, but a retry after a successful-but-lost first response would hit GitHub's "name already exists" 422 — which falls into the no-retry 4xx bucket, so it stops rather than creating a duplicate. The README `PUT` is idempotent by content, so retrying is unconditionally safe.

## What this taught me

The riskiest part of adding retry logic isn't the backoff math, it's making sure a naive "just wrap it and retry blindly" doesn't turn a possibly-succeeded write into an actually-duplicated one. Checking each call's idempotency (or what happens when a retry lands on top of a ghost success) before wrapping it is the step that's easy to skip and the one that matters most — a retry wrapper that's unsafe on writes is worse than no retry at all.
