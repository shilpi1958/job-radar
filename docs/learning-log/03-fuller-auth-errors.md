# "couldn't send: [object Object]" isn't a debuggable error message

**Ships:** [`2831946`](https://github.com/shilpi1958/job-radar/commit/2831946) — Show fuller Supabase auth errors when magic-link send fails.

## The problem

After the [magic-link redirect fix](01-magic-link-fix.md), sign-in
still failed sometimes — but the UI only ever showed
`couldn't send: ${error.message}`. Supabase auth errors don't always
populate `.message` with something useful; the real signal (SMTP
rejection, rate limit, provider misconfiguration) can live in
`.code` or `.status`, or nowhere obvious at all if the error object is
shaped unexpectedly.

## The fix

```js
const detail = [error.message, error.code, error.status].filter(Boolean).join(' · ')
  || JSON.stringify(error, Object.getOwnPropertyNames(error));
status.textContent = `couldn't send: ${detail || 'unknown error — check Supabase Auth → SMTP (Resend) settings'}`;
console.error('signInWithOtp failed', error);
```

Three layers of fallback: message+code+status joined together, then a
full serialization of the error object as a last resort (plain
`JSON.stringify(error)` on an `Error` often produces `{}`, since the
useful fields live on the prototype — `Object.getOwnPropertyNames`
gets around that), then a pointer to the most likely real cause
(Supabase's free-tier default email being rate-limited or
misconfigured) baked directly into the fallback string. Also logs the
raw error to console for full detail during debugging.

## What this taught me

A generic catch-all error message is a debugging dead end for
whoever hits it next — including future me. The fix here isn't fancy,
just layered: try the structured fields first, fall back to a full
dump, and when even that's unhelpful, point at the most probable
actual cause instead of a bare "unknown error." That last part came
directly from knowing this project's specific failure mode (Supabase's
rate-limited default SMTP) rather than a generic try/catch — it's the
difference between an error message that's technically true and one
that's actually useful.
