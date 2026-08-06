# "One place" in a single-file app means one section, not one file

**Ships:** moved `RUBRIC_GENERATION_PROMPT` (previously defined ~550 lines away, inline above the one function that uses it) up into the existing prompts section alongside `CANDIDATE_STANCE_TEXT`, `RUBRIC_TEXT`, `DEFAULT_PROMPT_SCAN`, `DEFAULT_PROMPT_PLAN`. Closes #106.

## The problem

Auditing "everything the model gets told" required knowing to look in two places: the well-organized prompts section near the top of the script (already had a header comment, already grouped `CANDIDATE_STANCE_TEXT`/`RUBRIC_TEXT`/the two `DEFAULT_PROMPT_*` templates/`PROMPT_DEFS` together), and a completely separate definition of `RUBRIC_GENERATION_PROMPT` sitting inline right above `generateRubricFromStance()`, ~550 lines later in the file. Nothing was wrong with either location individually — the constant was placed right next to its one caller, which is a reasonable default — but it meant the "prompts live here" section wasn't actually true.

## The fix

- Moved `RUBRIC_GENERATION_PROMPT` into the main prompts section, positioned right after `RUBRIC_TEXT` since it's what *produces* a personalized rubric before `RUBRIC_TEXT`'s generic fallback would ever be needed.
- Expanded the section's header comment to state the invariant explicitly and name the two real categories that exist: `DEFAULT_PROMPT_*` (user-editable, registered in `PROMPT_DEFS`, has a Prompts-tab override UI) vs. internal-only prompts like this one (fixed, one-shot, deliberately *not* in `PROMPT_DEFS` since there's no override UI for them — leaving it out avoids implying it's editable when it isn't).
- Left `PROMPT_DEFS` itself untouched rather than adding a `rubric` entry to it — that registry drives actual UI rendering (`renderPromptEditor(key, el)`), and adding an entry with no corresponding "which key gets rendered" call site would be a decoration, not a behavior change.

## What this taught me

In a single-file app, "consolidate X into one place" doesn't mean physically colocating every file that touches X — most of this codebase's prompt infrastructure (the registry, the override-lookup function, the template-filling function) was already properly consolidated; only one constant had drifted out because it was placed next to its caller instead of next to its siblings. The fix was small specifically because the surrounding organization was already good — the header comment doing the real work here is naming *why* two categories exist, not just moving text around.
