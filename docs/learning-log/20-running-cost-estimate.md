# Warning about cost without ever showing a number is its own kind of unhelpful

**Ships:** a persisted, per-user running cost estimate shown in the sidenav. Closes #56.

## The problem

The app tells the user "real spend" / "costs credits" at scan, rescan
confirms, and the connections panel — repeatedly reminding them this
costs real money on their own key — but never showed an actual number
anywhere. A user had no way to sanity-check whether a session cost
them $0.50 or $15 without leaving the app to check their Anthropic or
OpenAI billing dashboard directly. Repeated warnings with no number to
act on create anxiety without giving the information needed to resolve it.

## The fix

- `callLLM()` already discarded the `usage` object from both the
  Anthropic and OpenAI responses — token counts were sitting right
  there, unused. Now both branches call a new `recordSpend(provider,
  inputTokens, outputTokens)` after a successful call.
- `recordSpend()` computes a rough cost from a small per-provider rate
  table (`$/million tokens`, matched to the pinned model strings —
  `claude-sonnet-5` and `gpt-4o`) and accumulates it into
  `app_settings` under `spend_total_usd`, same per-user persistence
  pattern as everything else in the app — survives sign-out, reload,
  across devices.
- Displayed as a small line in the sidenav (`~$X.XX spent (est.)`),
  above sign-out, visible from every view. Shows nothing at zero spend
  — no point cluttering a fresh user's nav with "$0.00."

## What this taught me

Before writing the pricing table, I had to fix a separate, unrelated
bug this surfaced: the app's Claude calls were still pinned to
`claude-sonnet-4-6`, not the current `claude-sonnet-5` — three model
generations stale, silently, with no error to force a revisit. That
became its own small fix landed first, since a cost estimate priced
against the wrong model would have been wrong from the start. Building
a feature that needs "the current price of what we're calling" is a
good forcing function for noticing what we're actually calling has
drifted.
