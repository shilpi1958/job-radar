# A placeholder that reads as already-correct is a trap, not a hint

**Ships:** stance textarea placeholder shortened to a structural hint; the worked example moved into visible `.desc` copy above it. Closes #59.

## The problem

`stanceBox`'s placeholder was a complete, well-formed first-person
paragraph — "I'm looking for early-stage, high-ownership PM roles in
deep-tech or robotics — not more healthcare, even though that's my
current industry..." — sitting inside the actual input field. Placeholder
text disappears the instant a user types and never submits on its own,
but a distracted or unsure new user skimming the page could plausibly
see a fully-formed paragraph already sitting in the box, assume it's
pre-filled or "close enough," and move on without writing anything of
their own — this is exactly the input that seeds the per-user scoring
rubric (#6), so getting it skipped or half-written has real downstream
effect.

## The fix

- Shortened the placeholder itself to a structural prompt: "role,
  background, hard no's, location — write it in your own words" —
  something that can't be mistaken for a real answer.
- Moved the full worked example into the `.desc` line above the
  textarea, explicitly labeled `<i>example: "..."</i>` — visible
  as guidance, not sitting inside the input where it looks like
  content.

## What this taught me

A placeholder's job is to hint at *shape*, not demonstrate a complete
answer — the more polished and complete a placeholder reads, the more
it risks being mistaken for something already done. Worth checking any
placeholder that's a full sentence (or several): would a skimming user
mistake this for already-filled-in content? If the answer's not
obviously no, it belongs in visible copy instead, labeled as an
example.
