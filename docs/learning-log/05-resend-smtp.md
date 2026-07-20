# Free-tier email limits aren't a testing problem, they're a launch blocker

**Ships:** Resend as custom SMTP for Supabase Auth magic-link emails.

## The problem

Supabase's default auth email works out of the box, but it's rate
limited to a handful of sends per hour on the free tier. That's
invisible while building solo — you send one link, test, done — but
it's a hard wall the moment more than a couple of people try to sign
up in the same hour. This was flagged as a known gap in the README from
day one, but flagging a gap and closing it are different steps, and
this one sat open the longest of anything in the project.

## The fix

Two parts, kept deliberately separate:

1. **A standalone test script** (`scripts/send-test-email.js`) that
   sends a real email via the Resend SDK directly — no Supabase
   involved at all. This isolates one question: *does this API key
   work?* If the script fails, the problem is the Resend account/key.
   If it succeeds but Supabase still can't send, the problem is on the
   Supabase SMTP config side. Testing the two independently instead of
   only end-to-end made the failure surface much smaller to search
   whenever something didn't work.
2. **Supabase's SMTP settings**, pointed at Resend
   (`smtp.resend.com:465`, username `resend`, password = the API key).
   Verified by triggering a real magic-link send from the deployed app
   and confirming the email actually arrived — not just that Supabase
   returned success. Success responses and mail delivery are not the
   same guarantee.

## What this taught me

A "known tradeoff, revisit later" note in a README is easy to write
and easy to leave unrevisited — there's no forcing function until real
usage hits the limit. The actual fix here was small (an SMTP form and
a few settings), but it needed a verification step that wasn't "the
form saved without an error," it was "I received the email in my
actual inbox." Config that claims success and config that works are
different claims, and only one of them was worth trusting here.
