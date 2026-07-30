# The real error was already there — it just got thrown away

**Ships:** scan and plan failures show the actual error message instead of a generic "try again"; API key save warns on an obviously wrong format. Closes #51.

## The problem

`callLLM()` already does the right thing — it reads the actual error
from a failed HTTP response (Anthropic's `data.error.message`, or
OpenAI's proxy error, or an HTTP status fallback) and throws it as a
real `Error` with a specific message. But both call sites that matter
most, `runScan()` and the plan generator, wrapped their `callLLM` call
in a `try/catch` that discarded `e.message` entirely and replaced it
with a hardcoded string — `'scan failed — the search may have returned
an unexpected format. try again.'` for scan, `'plan generation failed
— try again'` for plan.

Both catch blocks only ever fire from `callLLM` throwing (the JSON
parsing beneath it has its own inner try/catch and recovers instead of
re-throwing), so every single error passing through that outer catch
was already a real, specific, useful message — an invalid key, a rate
limit, a network failure — and it got thrown away in favor of the same
unhelpful text regardless of what actually happened. A user with a
typo'd key and a user who hit a transient rate limit saw identical
copy and got identical (bad) advice: just try again.

Interestingly, `generateRubricFromStance()` — the third LLM call site
in the app — already did this correctly (`` `couldn't generate:
${e.message}` ``). The bug wasn't a missing pattern, it was two of
three call sites not using a pattern the third one already had.

## The fix

- `runScan()` and plan generation: `` `${action} failed — ${e.message
  || 'unknown error'}` `` instead of a fixed string, matching the
  rubric-generation call site.
- Added a lightweight format check on API key save — Claude keys
  should start `sk-ant-`, OpenAI keys `sk-` — appended as a warning to
  the save confirmation, not a hard block (key formats change; this is
  a nudge to double-check, not a validator that can be wrong and block
  a legitimate key).
- The format-check warning needed a second pass: writing it directly
  into `status.textContent` before calling `loadApiKeyStatus()` got it
  silently overwritten, since that function unconditionally resets the
  same element's text right after. Had to append the warning *after*
  that call instead.

## What this taught me

"The error message must not exist" was the wrong assumption — it
existed the whole time, one layer down, and got discarded by a catch
block that treated all failures as interchangeable. Worth checking,
before writing a generic error string: is there already a specific one
available two stack frames down that's just not being passed through?
And a smaller, sharper lesson from the format-check bug: when a
function unconditionally overwrites a DOM element's state on every
call (`loadApiKeyStatus()` resets `apiKeyStatus.textContent`
regardless of what it currently says), anything written to that
element right before calling it is dead on arrival — order the write
after the reset, not before.
