# A full-price web-search call was the first place a bad input got caught

**Ships:** two non-blocking pre-flight checks before `runScan()` spends a real, web-search-enabled model call. Closes #79.

## The problem

An API key format is checked at save time, but nothing checked the scan request itself before it went out — an empty keyword/location combo, or a scan run before the user ever set up "what you're looking for" in Profile. Both cases still cost a full-price, ~30-60s, web-search-enabled call before the user found out the input (or the missing setup) was the actual problem. The onboarding gate in `showApp()` mostly prevents the second case for a truly new user, but doesn't cover every path back into it (e.g. a stance cleared later, an edge case in the gate itself) — nothing at the point of the scan click itself confirmed the state was still sane.

## The fix

Two `confirm()` checks added to the top of `runScan()`, both non-blocking (the user can proceed past either) and both firing *before* the `scan_log` fetch or the `callLLM` call — meaning a decline costs nothing:

- **No real search criteria**: if keywords, location, active focus-area tags, and custom tags are all empty, warn that the search will run as broadly as possible with nothing to narrow it.
- **No generated stance**: if `generated_stance` doesn't exist yet, warn that the scan will score against the generic placeholder persona instead of the user's own criteria, and point back to Profile.

Plan generation was considered for the same stance check but skipped — `showApp()` already forces any user without `generated_rubric` onto Profile before they can reach Scan *or* Plan at all, so by the time plan generation runs, the check would almost always be redundant with a gate that already ran.

## What this taught me

The cheapest fix for "an expensive call ran on a bad input" is usually not a smarter recovery path after the call — it's noticing, before it fires, that the state was never going to produce something useful. Both checks here reuse data (`activeTags`, `customTags`, `generated_stance`) that was already sitting in scope; neither needed new plumbing, just a decision to look at it one step earlier.
