# job radar

A private, multi-user job search tool: scans the web for roles matching your profile,
scores them against a rubric, tracks specific companies, generates a 6-month plan with
concrete technical side projects, and turns those projects into real GitHub repos.

## Architecture

- **Frontend:** single static file, `index.html` — no build step, no framework.
  Deployable as-is to GitHub Pages.
- **Database:** Supabase (Postgres). Job postings are shared across all users (the app
  gets smarter as more people use it — same posting gets deduped once). Everything else
  — CV, skills profile, scores, plans, watchlist, portfolio — is private per user via
  Postgres row-level security (`auth.uid() = user_id`).
- **Auth:** Supabase Auth, magic-link email. No passwords.
- **AI calls:** BYOK (bring your own key). Each user can paste an Anthropic and/or
  OpenAI API key in Profile, pick the active provider from a dropdown, and keys stay in
  `localStorage` only — never written to Supabase tables. Claude calls go straight from
  the browser to `api.anthropic.com` (`anthropic-dangerous-direct-browser-access`).
  OpenAI blocks browser CORS, so those calls go through the auth-gated Edge Function
  `openai-proxy`, which forwards the user's key from the `X-User-OpenAI-Key` header
  without storing it.
- **GitHub integration:** each user connects their own GitHub Personal Access Token
  (repo scope only), also `localStorage`-only, used to spin up a real private repo +
  README when they click "build this" on a generated side project.

## Setup (new Supabase project)

1. Create a project at supabase.com.
2. SQL Editor → run `sql/01_schema.sql`, then `sql/02_migration_auth.sql`, in that order.
   The second depends on tables the first creates.
3. Project Settings → API → copy the Project URL and the `sb_publishable_...` (anon) key.
4. In `index.html`, update `SUPABASE_URL` and `SUPABASE_KEY` near the top of the
   `<script>` block to match your project.
5. Auth → URL Configuration: add every origin you'll actually sign in from (production
   URL, `http://localhost:<port>/**` for local dev) to Redirect URLs — Supabase silently
   falls back to the Site URL for anything not on that list, so magic links sent while
   testing locally will otherwise land you back on production instead.
6. Auth → Email templates: default magic-link template works out of the box. Free tier
   rate-limits outbound email (a handful per hour) — fine for testing, but needs a
   custom SMTP provider before real traffic. This project uses
   [Resend](https://resend.com): Project Settings → Authentication → Emails → SMTP
   Settings → enable custom SMTP, host `smtp.resend.com`, port `465`, username
   `resend`, password = your Resend API key. `scripts/send-test-email.js` sends a
   one-off test email via the Resend SDK directly (not through Supabase) to sanity
   check the API key works before wiring it into Supabase's SMTP settings.
7. Deploy the OpenAI proxy (needed only if anyone will use the OpenAI provider):

   ```bash
   npx supabase login
   npx supabase link --project-ref <your-project-ref>
   npx supabase functions deploy openai-proxy
   ```

   The function lives at `supabase/functions/openai-proxy/`. It requires a logged-in
   user JWT and does not store OpenAI keys.

## Deploying

Push to GitHub, enable Pages (Settings → Pages → deploy from branch/root). No build step.
`index.html` at repo root becomes the site.

## What's in `legacy/`

`cloudflare_worker_UNUSED.js` — from an earlier shared-API-key architecture where a
Worker proxied requests and held one API key for everyone. Abandoned in favor of BYOK,
which is simpler and doesn't require you to pay for other people's usage. Kept for
reference only; not part of the running app.

## Known tradeoffs to revisit

- **RLS is real now** (per-user isolation is enforced at the database level), but there's
  no rate limiting on signups/scans per user yet — someone could hammer their own account
  with API calls. Not a data-leak risk, just a cost-control gap if this gets real traffic.
  Resend's free tier is also capped (100 emails/day) — fine for early usage, worth
  watching if signups pick up.
- **Operator analytics** live as plain SQL views (`analytics_usage_summary`,
  `analytics_search_trends`, `analytics_skill_demand`, `analytics_watched_companies`) —
  query them directly in the Supabase SQL Editor. No in-app admin dashboard yet.
- **Single HTML file, ~1800 lines.** Works, but the natural next step is splitting into
  `index.html` (structure only) + `css/style.css` + a handful of `js/*.js` modules
  (data layer, auth, scan, watchlist, plan, profile, portfolio, prompts-editor). Deferred
  deliberately — better done with a real terminal and live reload than blind in a chat
  transcript.
- **No rate limiting or abuse protection** on the BYOK flow beyond "it's their own key,
  their own bill."

## Prompt system

All four AI prompts (scan, six-month plan, watchlist scan) are stored as editable
templates in the app itself (Prompts tab) — not hardcoded strings you need to dig through
code to change. `{{PLACEHOLDER}}` tokens get substituted at call time; see `PROMPT_DEFS`
in the script for the full list per prompt.

## `docs/learning-log/`

A write-up per shipped PR — what broke or was missing, why the fix is shaped the way it
is, and what it taught. Not a changelog (that's `git log`); each entry explains the
reasoning a diff alone doesn't show. Numbered in ship order, one file per PR.
