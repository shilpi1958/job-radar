# The data to answer "am I ready" already existed — nobody had asked it

**Ships:** per-company project count on each watchlist chip. Closes #10.

## The problem

Watchlist, portfolio, and the plan were three disconnected tabs even
though the underlying data already linked them: tracking a company
feeds the plan, the plan's `target_company` field says which projects
aim at which company, and building one becomes a `portfolio_repos` row
with that same field. Nothing surfaced the join back to the user — you
could track five companies and have no idea which ones had zero
projects built toward them without cross-referencing three views by
hand.

The issue listed three possible directions and stayed a placeholder
until its blocking dependency (#17, spreading plan projects across
every tracked company instead of just one) landed. It has — confirmed
closed — so the readiness signal direction became answerable with data
that was already there, no new generation logic needed.

## The fix

Picked the cheapest, most honest of the three directions: a plain
count, not a score dressed up as more than it is. `renderWatchChips()`
now fetches the portfolio, counts `target_company` matches
case-insensitively per tracked company (excluding the `"general"`
bucket, which isn't aimed at anyone), and renders `· N` on each chip
with a title tooltip spelling out what it means. Refreshed both when
watch companies load and whenever the Watchlist view is switched to,
so a project built on the Plan tab and then coming back to Watchlist
shows the count updated without needing a reload.

Left the "gap nudge" and "portfolio grouped by company" directions
alone — the issue explicitly said not mutually exclusive, needs a real
design pass, and a chip count is the smallest slice that's still
honestly useful on its own.

## What this taught me

This issue sat as a placeholder for a reason — building the readiness
signal before #17 landed would have been misleading, since a "0
projects" count meant nothing when the plan could only ever target one
company at a time anyway. Worth checking a "not scoped yet" issue's
listed blockers before assuming staleness; sometimes the issue really
is just waiting on its own prerequisite, not abandoned.
