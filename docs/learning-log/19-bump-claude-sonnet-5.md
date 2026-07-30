# The model string was three generations behind, silently

**Ships:** bumped `callLLM()`'s Claude call from `claude-sonnet-4-6` to `claude-sonnet-5`; upgraded the scan's web search tool to the dynamic-filtering variant it unlocks. No issue number — caught while scoping #56 (cost tracking), which needed the real current model to price against.

## The problem

The Anthropic call in `callLLM()` was still pinned to `claude-sonnet-4-6` — Sonnet 5 is current. Nothing in the app broke from this; a stale-but-valid model ID doesn't throw, it just quietly serves an older, more expensive-per-quality model indefinitely. It surfaced only because #56 (show a running cost estimate) needed to know which model's pricing to use, and pricing lookup exposed that the code wasn't calling what "current" actually meant anymore.

## The fix

- `body.model`: `'claude-sonnet-4-6'` → `'claude-sonnet-5'`.
- Checked the request body for anything Sonnet 5 would reject — no `temperature`/`top_p`/`top_k`, no `thinking`/`budget_tokens` config — so the swap alone doesn't 400.
- Upgraded `web_search_20250305` (basic) to `web_search_20260209` (dynamic filtering), since that variant requires Sonnet 5 and the scan's whole job is finding relevant results efficiently — a free win riding along with the model bump, not a separate ask.

## What this taught me

A hardcoded model string has no expiry warning — it degrades silently to "not the best available" rather than failing loudly, so nothing forces a revisit unless something else (here, a pricing lookup for an unrelated feature) happens to touch it. Worth periodically checking hardcoded model IDs the same way dependency versions get checked, since neither the code nor the user gets a signal that one has gone stale.
