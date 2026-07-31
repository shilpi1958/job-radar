# Every page load was paying for a feature most sessions never touch

**Ships:** pdf.js and mammoth.js load on demand, on the first CV-upload attempt, instead of as blocking `<script>` tags in `<head>`. Flagged in the engineering trace, not a numbered issue.

## The problem

Both libraries — roughly a combined megabyte — were `<script src="...">` tags in `<head>`, with no `defer`/`async`, meaning they blocked HTML parsing and delayed first paint of the login screen on *every single visit*. Their only use in the entire app is `extractTextFromFile()`, called exactly when a user uploads a `.pdf` or `.docx` CV — an optional step most sessions never take. The cost was paid unconditionally by everyone, for a feature only some people use once.

## The fix

Removed both `<script>` tags from `<head>`. Added `loadCvParser(kind)` — a small function that injects the relevant `<script>` tag into `<head>` on first call and returns a cached promise so a second call doesn't re-inject or re-download. `extractTextFromFile()` now `await`s the appropriate loader right before it needs `pdfjsLib` or `mammoth`, only inside the `.pdf`/`.docx` branches — the `.txt` path (no external library needed) is untouched.

The existing `try/catch` in the upload handler already covered a load failure without changes — a network failure now surfaces as `"pdf reader failed to load"` through the same error-message path that previously only caught parse errors.

## What this taught me

A blocking script tag in `<head>` is a decision made once, early, that nobody revisits as the app grows — it doesn't announce itself as a cost the way a slow function call does, it's just quietly there on every load. Worth periodically checking `<head>` for scripts that serve only one specific, optional feature deep in the app; those are almost always safe to defer to the moment they're actually needed.
