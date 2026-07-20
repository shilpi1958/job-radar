# Why OpenAI needed a proxy when Anthropic didn't

**Ships:** [`d250896`](https://github.com/shilpi1958/job-radar/commit/d250896) — Add OpenAI BYOK with provider dropdown and auth-gated proxy.

## The constraint

The whole app's AI architecture rests on one property: users paste
their own API key into `localStorage`, and calls go straight from
their browser to the provider — no server of ours ever touches the
key. Anthropic explicitly supports this via the
`anthropic-dangerous-direct-browser-access: true` header, documented
for exactly this BYOK pattern.

OpenAI's API has no equivalent. Its CORS policy doesn't allow direct
browser calls to `api.openai.com`, full stop. So "just add a provider
dropdown and call OpenAI directly" — the same pattern used for
Anthropic — doesn't work; the browser blocks the request before it
even reaches OpenAI.

## The fix: a proxy that still doesn't touch the key

A Supabase Edge Function (`supabase/functions/openai-proxy/index.ts`)
sits between the browser and OpenAI, but is deliberately built to
preserve the BYOK privacy property rather than undermine it:

- The user's OpenAI key travels in a custom header
  (`X-User-OpenAI-Key`) **per request** — the function never writes it
  anywhere, never logs it, just forwards it upstream to OpenAI and
  relays the response back.
- The function requires a valid Supabase session
  (`Authorization: Bearer <jwt>`) before it will proxy anything —
  checked via `supabase.auth.getUser()`. Without a logged-in user, the
  function returns 401 before ever touching OpenAI. This stops the
  proxy from being an open relay anyone could point arbitrary requests
  through using our Supabase project's compute.
- CORS headers are set explicitly on every response (including the
  `OPTIONS` preflight) since the whole point of this function is to be
  callable from the browser.

## What this taught me

"Bring your own key, never touches our server" is a promise about
*storage and logging*, not about *network topology* — a request can
pass through infrastructure we operate without us ever persisting or
even reading the secret it carries, as long as the proxy is built to
forward-and-forget. The interesting design constraint wasn't "how do
we call OpenAI," it was "how do we call OpenAI without turning this
Edge Function into either a stored-secret liability or an open proxy
anyone can abuse" — auth-gating solved the second, per-request headers
solved the first.
