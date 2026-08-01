# Documenting a voice surfaces the places it quietly stopped applying

**Ships:** `docs/copy-guidelines.md`, plus fixes to two real drift points found while writing it — inconsistent icon prefixes on panel headings, and a split register across `alert()` calls. Closes #89.

## The problem

The app's copy voice is genuinely consistent almost everywhere — lowercase, terse fragments, real numbers instead of vague hedges, specific error causes. But nothing wrote the rules down, and reading every user-facing string end to end (rather than skimming a few examples) surfaced two places where the consistency had actually broken:

- **Panel `<h2>` headings**: of 13 headings, 4 used ◆, 2 used ▸, 7 used nothing — no discoverable rule. Meanwhile ▸ had a clean, 100%-consistent meaning everywhere *else* in the file (every single `.scan`-class button, no exceptions), so its two appearances in headings ("▸ AI key," "▸ welcome...") were actually diluting an otherwise-unambiguous signal rather than adding one.
- **`alert()` register**: 4 older calls were capitalized, full-sentence ("Could not find that job to flag."); 3 calls added in recent PRs were lowercase, fragment-style ("couldn't save — check your connection and try again"). Both registers existed side by side with no rule distinguishing them.

## The fix

- Wrote `docs/copy-guidelines.md` covering voice, numbers/costs/timing, errors, the `confirm()`-is-a-deliberate-exception rule, the icon-prefix table, and placeholder-vs-visible-copy — each rule grounded in an actual example already in the codebase, not invented from scratch.
- Removed the icon prefix from every panel `<h2>` — ▸ stays reserved for its one clean use (action buttons), and no new "panel marker" meaning was invented for an existing symbol.
- Resolved the `alert()` split in favor of the lowercase/fragment voice, keeping `confirm()` as the one deliberate exception (it's asking a real yes/no question, which earns a heavier register) — `alert()` is a one-way notification, functionally the same as an inline status line that happens to render as a native dialog, so it follows the same rules as everything else.

## What this taught me

Writing down an "already consistent" voice is a good forcing function for finding the two places it wasn't — a spot-check of a few examples would have missed both issues here, since the drift was in a code path (headings, one specific dialog type) that a skim wouldn't have systematically covered. My own first attempt at the `alert()` rule ("match `confirm()`'s register") was actually wrong on inspection — I'd misremembered which of my own recent PRs used which register, and only the full grep-and-count caught it. Worth distrusting "I recall this being consistent" and actually running the count before writing the rule down.
