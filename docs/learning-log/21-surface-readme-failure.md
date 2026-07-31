# A silent console.warn is invisible to the person who needed to know

**Ships:** a visible warning when repo creation succeeds but the README write fails. Flagged in the engineering trace, not a numbered issue.

## The problem

`buildProjectRepo()` creates the GitHub repo, then does a second, dependent `PUT` for the starter README. If that second call failed, the only trace was `console.warn('repo created but README failed:', ...)` — the function continued exactly as if both steps succeeded, showed "repo created →," and moved on. A user has no reason to open dev tools after a successful-looking action; the repo silently ends up with no README and nothing tells them.

## The fix

Track the README outcome as a boolean instead of only logging it, and render a small inline warning (`⚠ no README`, with a title tooltip explaining why) next to the repo link when it failed. The repo link itself still shows — the repo genuinely was created, that part didn't fail — but the caveat that content is missing is now visible instead of buried in a console log nobody's watching after a "success" state.

## What this taught me

The repo-creation and README-write are two separate points of failure chained together, and the code treated only the first as worth surfacing. Any two-step external call where step two isn't essential to "did the thing basically work" is a place to check: does a partial success get reported as success, or as partial?
