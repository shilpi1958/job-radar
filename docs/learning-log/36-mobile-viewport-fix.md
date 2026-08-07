# Every media query in the file was correct and none of them ever ran

**Ships:** adds the missing `<meta name="viewport">` tag, and fixes the onboarding step tracker overflowing horizontally on real mobile widths. Closes #57.

## The problem

Testing at a real 375px mobile width (rather than a shrunk desktop screenshot) showed the sidenav rendering as its full desktop form — fixed 200px width, vertical column, not the horizontal wrapped row `@media (max-width: 720px)` describes. The CSS for that breakpoint was correct; it simply never activated on a real device.

The cause: `index.html` had no `<meta name="viewport" content="width=device-width, initial-scale=1">` tag anywhere. Without it, mobile browsers lay out the page against a virtual "desktop" viewport (typically ~980px) and scale the whole render down to fit the physical screen — so `max-width: 720px` never matches, no matter how narrow the actual device is. This is a single missing tag, but it meant *every* media query in the file — there was only the one — had been dead code since the responsive sidenav work shipped, undetected because nothing in this project had tested at an actual mobile viewport width until now.

Fixing the viewport tag alone surfaced a second, previously-invisible bug: the profile wizard's 5-step tracker (`.onboard-steps`, from #109) is a `display:flex` row with no wrap and 4 fixed-width connector spacers between steps — fine at desktop width, but wider than a real phone screen. With the viewport tag now honest about the actual screen size, this correctly triggered `body.scrollWidth` (681px) exceeding the viewport (375px), forcing the whole page to scroll horizontally.

## The fix

- Added the viewport meta tag — the actual root-cause fix; everything else follows from browsers finally sizing the layout correctly.
- Inside the existing `@media (max-width: 720px)` block: `.onboard-steps{flex-direction:column}` to stack steps instead of forcing them into one row, and `.onboard-connector{display:none}` since the connector lines were a "this leads to that" cue between horizontally-adjacent steps — meaningless once steps stack vertically.

## What this taught me

A responsive breakpoint that looks correct in the CSS can still be completely inert if something upstream (here, a missing one-line meta tag) prevents the browser from ever evaluating widths honestly. "The CSS handles mobile" was true in isolation and false end-to-end — the only way to catch that gap was testing at an actual narrow viewport rather than reading the stylesheet and reasoning about what it *should* do. The second bug (step tracker overflow) was invisible until the first fix made real mobile widths reachable at all — fixing the root cause didn't just fix the sidenav, it made a whole class of previously-untestable mobile bugs testable for the first time.
