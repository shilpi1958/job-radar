# The warning existed one panel up from where the decision gets made

**Ships:** inline notice next to "generate plan" when no scan history exists yet. Closes #55.

## The problem

`genPlanBtn`'s handler builds `topAsks` from `getSkillTally()`, and
when there's no scan history it silently substitutes `'no scan data
yet — using general market knowledge instead'` into the prompt sent to
the model — a real degradation of the plan's core pitch ("built from
what you find, not guesses"). But that fallback string only lives
inside the prompt; nothing in the UI told the user, before they
clicked "generate plan," that skipping straight there without
scanning first would produce a meaningfully weaker plan.

The closest thing to a warning was one panel up — the gap-bars empty
state already said "run a few scans first" — but that's describing the
market-tally *display*, not a warning tied to the actual
plan-generation button a user is about to click. A user could read
that line, not connect it to the button below, and generate a plan
anyway without realizing what they were trading away.

## The fix

Added a dedicated notice (`planScanNotice`) directly above the
"generate plan" button, toggled by `renderGapBars()` — which already
runs on every switch to the Plan view and already fetches
`postingsAnalyzed`, so no new data fetch was needed, just reusing what
was already there. Shows only when `postingsAnalyzed === 0`; hides the
moment any scan history exists. Deliberately non-blocking — the button
stays clickable, the notice just sets the expectation first.

## What this taught me

The information needed to warn the user already existed and was
already being fetched on every relevant view load — the gap was purely
about *where* it was surfaced, not whether the data was available.
Worth checking, when a warning "should" exist somewhere: is the
underlying fact already computed one function up, just not routed to
the place the user actually makes the decision?
