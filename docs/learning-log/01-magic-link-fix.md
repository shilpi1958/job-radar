# Fixing magic-link auth poisoned by leftover `#error` hashes

**Ships:** [`5f07c56`](https://github.com/shilpi1958/job-radar/commit/5f07c56) — Fix magic-link auth poisoned by leftover #error hashes.

## The bug

Supabase magic-link auth redirects the user back to the app with either
`?code=...` (success, PKCE flow) or `#error=...` in the URL. The original
code passed `window.location.href` — the *current* URL, error hash and
all — as the `emailRedirectTo` target:

```js
db.auth.signInWithOtp({ email, options: { emailRedirectTo: window.location.href } });
```

If a user's first link expired or was reused, the page picked up an
`#error=...` hash. Requesting a *second* link then baked that stale
error hash into the new redirect URL too — so even a fresh, valid
magic-link click landed back on a URL Supabase read as an error state.
The user was stuck: every subsequent link looked expired, because the
redirect target itself carried the old failure forward.

## The fix

- `emailRedirectTo` now always points at a clean, hash-free URL
  (`origin + pathname`), not `location.href`.
- Switched the client to PKCE flow (`flowType: 'pkce'`) with
  `detectSessionInUrl: true`.
- Added `recoverSessionFromUrl()` to handle a still-possible mangled
  case (`&sb=#access_token=...`, where an error hash and a real token
  end up concatenated) by extracting tokens directly and calling
  `setSession()`, then stripping auth params from the URL with
  `history.replaceState` so a page refresh doesn't re-trigger the same
  parsing.

## What this taught me

Auth redirect URLs are stateful in a way that's easy to miss: the
"current URL" isn't a neutral value to echo back, because it can carry
forward whatever error state got you there in the first place. The bug
wasn't in the token exchange logic — it was in constructing the
redirect target from mutable browser state instead of a clean,
canonical one. Any place a URL both **reads** app state (via query/hash)
and gets **reused** as a redirect target is worth checking for this same
poisoning pattern.
