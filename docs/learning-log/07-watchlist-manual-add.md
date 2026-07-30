# Removing a path can remove a capability you meant to keep

**Ships:** minimal manual "track a company" input restored on Watchlist. Closes #28.

## The problem

#24 removed the watchlist's free-text company input and its own
independent search, replacing it with a "+ watchlist" button on scan
result cards — tracking a company now happens by finding it, not by
typing a name from memory. That was the right call: it matched the
real flow (scan → notice → track) and killed a chunk of dead,
disconnected search logic (`DEFAULT_PROMPT_WATCHSCAN`, the watchlist's
own scan-log dedup, its status line).

But the fix conflated two things that looked like one: "the watchlist
shouldn't run its own search" and "you can't add a company you haven't
already seen in a scan result." The first was the actual problem. The
second was a side effect nobody decided on — a company with zero
current open postings never produces a scan card, so it could never be
tracked ahead of time, even for a company the user already knows about
and wants to watch for future openings.

## The fix

Added back a single text input on the Watchlist view — name in, Enter
to add, straight to `addWatchCompany` (which never went away; only its
UI trigger did). No search, no live API call, no `DEFAULT_PROMPT_WATCHSCAN`
revival. The "+ watchlist" button on scan cards stays the primary path;
this is just the manual escape hatch for the case it can't cover.

## What this taught me

A removal PR's diff is easy to read as one coherent change because it
lands in one commit, but "remove the search" and "remove the ability to
add a company you haven't seen yet" were two separate capabilities
riding on the same input field. Deleting the field deleted both, and
only one was intended. Worth asking, next time a UI element is doing
double duty: which of its jobs am I actually trying to kill?
