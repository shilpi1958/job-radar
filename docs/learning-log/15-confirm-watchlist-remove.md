# The one no-confirmation destructive action, right next to the data that would've warned about it

**Ships:** confirm dialog before removing a watchlist company, naming how many portfolio projects target them if any. Closes #54.

## The problem

Clicking ✕ on a watchlist chip removed the company immediately —
`watchCompanies.splice(idx, 1)` fired straight from the click handler,
no `confirm()`, no undo. Every other destructive action in the app
(`markLinkBroken`) gates on a confirm dialog first; this was the one
exception, and a misclick silently dropped a tracked company with no
way to get it back except retyping the name.

The sharper version of the problem: the readiness-count work (#10,
already shipped) had already computed, right there in
`renderWatchChips()`, exactly how many portfolio projects target each
company. That number was rendered on the chip as a small `· N` but
never used to inform how risky a given removal actually was — removing
a company with 2 projects built toward it and removing one with zero
were treated identically.

## The fix

- Added `confirm()` before removal, reusing the `n` count already
  computed for the readiness signal (stashed on the chip as
  `data-count` so the click handler doesn't need to refetch anything).
- If `n > 0`, the confirm message names the count and clarifies that
  the portfolio repos themselves aren't deleted — just the visible
  link back to why they exist. If `n === 0`, it's a plain "stop
  tracking X?" with no extra weight, since there's nothing to lose
  context on.

## What this taught me

The data needed to make this confirmation genuinely useful (not just a
generic "are you sure?") was already sitting in the same function,
computed one issue ago for a different purpose. Worth checking, before
adding a confirmation dialog: is there already state nearby that would
make the warning specific instead of generic? A specific warning
("you'll lose the connection to 2 projects") is more likely to be read
than a boilerplate one a user has learned to reflexively click through.
