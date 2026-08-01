# Copy guidelines

The app's voice is already consistent almost everywhere — this document writes
down the rules that were implicit, so future copy (new features, error
messages, button labels) has something to check itself against instead of
drifting. When in doubt, find the nearest existing string of the same *kind*
(a `.desc`, an error, a button label) and match it — these rules were
extracted from what's already there, not invented from scratch.

## Voice

- **Lowercase, always** — panel headings, button labels, status text, even
  the app name in the nav. "companies you're tracking," not "Companies
  You're Tracking." Sentence case and Title Case are both wrong here.
- **Second person, implicit** — "your proof points," "what you've got."
  Never third-person distancing ("the user's profile") or first-person
  plural ("we recommend").
- **No exclamation points, no marketing enthusiasm.** "scoring is
  personalized to your profile," not "Your scoring is now personalized!"
  Say what happened, plainly.
- **Fragments over flowing sentences** for descriptive text. "optional.
  pulls text from .pdf/.docx/.txt into every scan and plan. never leaves
  your storage." — three short fragments, not one sentence stitched
  together with "and."
- **Dashes connect related thoughts**, not semicolons: "hit '+ watchlist'
  on a scan result to add one — these are what your plan targets."

## Numbers, costs, and timing

State them plainly, as real numbers — never a vague hedge.

- ✅ "takes ~10-20s, one model call on your own key."
- ✅ "~\$0.60 spent (est.)"
- ❌ "this may take a moment"
- ❌ "this could cost a small amount"

If an estimate is genuinely uncertain, say so with a range or an
`(est.)`/`~` marker — don't drop the number and hedge instead.

## Errors

State the real cause and, where there is one, what to do about it. Never a
generic apology, never "Something went wrong."

- ✅ "couldn't save — check your connection and try again"
- ✅ "you already have 2 portfolio projects targeting them — removing them
  here won't delete those, but you'll lose the connection back to why you
  built them"
- ❌ "Something went wrong."
- ❌ "Error: operation failed"

Same lowercase, fragment-style voice as everything else — an error string
is not a special case that earns capitalization or a full sentence.

## `confirm()` is a deliberate exception; `alert()` is not

`confirm()` dialogs are capitalized, full-sentence, and end in a question
mark — e.g. *"Stop tracking Acme? You already have 2 portfolio projects
targeting them..."* This is different from the rest of the app's voice **on
purpose**: `confirm()` is asking the user a real yes/no question, and
matching that heavier register signals "this is a decision," not routine
copy.

`alert()` is not a question — it's a one-way notification, functionally the
same as a status line or an error string that happens to render in a native
dialog instead of inline. It follows the normal app voice: lowercase,
fragment-style, same as everything else. `` alert("couldn't save — check
your connection and try again") ``, not `` alert('Could not save. Please
try again.') ``.

## Icon prefixes

Icons are functional, not decorative — each one has exactly one meaning.
Don't reach for an icon because a string "needs a little more weight"; use
it only when it's actually signaling the thing it means everywhere else.

| Icon | Meaning | Where it appears |
|---|---|---|
| ▸ | Primary action button | Every `class="scan"` button, no exceptions — "▸ run scan," "▸ save," "▸ generate plan" |
| ★ | Watchlist (nav only) | The watchlist nav item |
| ◈ | Plan (nav only) | The plan nav item, and the "prompt used here" toggle |
| ◆ | Profile (nav only) | The profile nav item |
| ⚠ | Warning / hard gate | "⚠ gate: requires 3+ yrs as SWE," "⚠ no README" |
| ✓ | Confirmed / connected state | "✓ tracked," "✓ connected as username" |
| ✕ | Removal action | Chip-remove buttons |
| ○ | Neutral/dormant status | "○ quiet," "○ dormant" (repo activity) |

**Panel `<h2>` headings get no icon.** Icons on section headings ("◆ search
criteria," "▸ AI key") were an inconsistent later addition — some panels
had one, most didn't, and the icons used didn't map to any rule. Headings
are plain lowercase text; let the icon vocabulary above stay unambiguous
rather than trying to invent a new "panel marker" meaning for one of the
existing symbols.

## Placeholders vs. visible copy

A placeholder should hint at *shape*, never demonstrate a complete,
submittable-looking answer. If a placeholder reads as something a user
could plausibly mistake for pre-filled content, it's too long — move the
worked example into visible `.desc` text, explicitly labeled `example:
"..."`.

- ✅ Input placeholder: `role, background, hard no's, location — write it
  in your own words`
- ✅ Full worked example, in `.desc` text: `example: "I'm looking for
  early-stage, high-ownership PM roles..."`
- ❌ A complete first-person paragraph sitting inside the input's
  `placeholder` attribute

## Applying this to new copy

Before writing a new button label, panel heading, or error string, find the
nearest existing example of the same kind and match its register, icon
usage (or lack of it), and sentence shape. This document exists so that
match is a lookup, not a guess.
