# Making job radar accessible beyond English

job radar is English-first: type keywords, read results, edit prompts in
English. That's a real barrier — most of India searches for jobs by voice, in
Hindi, Kannada, Tamil, and dozens of other languages, not by typing English.
Typing in a second language is the wall, not intelligence or intent.

This isn't "add a translate button." Pulling it apart, there are four
distinct barriers an English-first product puts up, and each needs its own
fix — solving one doesn't solve the others.

## The four barriers

**1. Input barrier** — can't type/read English well enough to search.
You know what job you want. You just can't type "AI product manager robotics
OR deep tech" in English. → [#39](https://github.com/shilpi1958/job-radar/issues/39):
speak your search criteria in your own language, get the same matched results
anyone typing in English would get.

**2. Comprehension barrier** — can't understand what the product generated
for you. The plan hands you a project like "benchmark inference cost/latency
across quantization strategies" — technically correct English, and still
opaque if you're not fluent in it. Understanding the output is a different
skill from producing input, and job radar's plan generation assumes both.
→ [#45](https://github.com/shilpi1958/job-radar/issues/45): ask "what does
this mean?" about a specific project, in your language, and get an answer
grounded in that project — without leaving the app.

**3. Trust barrier** — can't verify a translation is faithful enough to rely
on. This shows up hardest where a mistranslation is expensive: editing a
prompt template that runs on every future scan, not just a one-off search.
Word-level correctness and meaning-level correctness aren't the same thing —
you can get every word "right" and still lose what someone meant, especially
on entities (names, numbers, tools) and intent (a flipped negation, a
reversed direction). → [#42](https://github.com/shilpi1958/job-radar/issues/42):
transcribe and translate independently, diff entities and numbers
deterministically, check semantic intent with an LLM, and ask rather than
guess whenever something's flagged.

**4. Output barrier** — even correct, faithfully-translated English text is
still a wall if you don't read fluently. → [#40](https://github.com/shilpi1958/job-radar/issues/40):
read matched results back via text-to-speech, in the language you searched
in, so the loop never requires reading English at all.

## Status

| # | Barrier | Issue | Status |
|---|---------|-------|--------|
| 1 | Input | [#39](https://github.com/shilpi1958/job-radar/issues/39) | building |
| 2 | Comprehension | [#45](https://github.com/shilpi1958/job-radar/issues/45) | scoped |
| 3 | Trust | [#42](https://github.com/shilpi1958/job-radar/issues/42) | scoped |
| 4 | Output | [#40](https://github.com/shilpi1958/job-radar/issues/40) | scoped |

Building #1 end-to-end first — a real, working voice search loop is worth
more than four half-built pieces. #2–#4 are fully scoped (see linked issues
for the actual design decisions, not just the idea) as evidence of the
thinking even where the code isn't there yet.

## Why job radar specifically

This isn't a voice demo bolted onto a blank project. job radar already has
real auth (Supabase magic-link), a live scan pipeline, prompt customization,
and a proof-of-work generation loop — the four barriers above are fixes to
an app that already works end to end in English, not a greenfield build. The
infrastructure being extended (Supabase, the scan/plan prompt system) is
infrastructure that already existed before this work started.
