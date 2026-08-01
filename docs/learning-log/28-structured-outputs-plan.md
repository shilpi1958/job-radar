# Recovery code treats the symptom; a schema treats the cause

**Ships:** the plan-generation call now constrains its response with `output_config.format` (structured outputs), so malformed JSON becomes structurally impossible instead of something to parse-and-recover from. Closes #78.

## The problem

Both `runScan()` and plan generation already had solid recovery paths for malformed JSON (`splitTopLevelObjects`, `recoverKeyedArray`/`recoverKeyedString`) — genuinely good defensive engineering. But recovery is downstream of the actual problem: the model was asked to emit raw JSON as free text with prompt instructions ("Return ONLY raw JSON, no markdown fences..."), and the app trusted that instruction, then patched around it when the model didn't fully comply. "Getting it right the first time" needed a mechanism that makes the wrong shape unreachable, not a better parser for when it happens anyway.

## The fix

- Added an optional `outputSchema` parameter to `callLLM()`. When present, it sets `body.output_config = { format: { type: 'json_schema', schema: outputSchema } }` on the Anthropic request — the Messages API validates the response against the schema server-side.
- Defined `PLAN_OUTPUT_SCHEMA`, mirroring `DEFAULT_PROMPT_PLAN`'s documented shape exactly: `skill_gaps[]`, `side_projects[]`, `cadence`, each nested object with `additionalProperties: false` and every field explicit in `required` — the two constraints the Anthropic schema format actually enforces (no `minLength`/`maxLength`/numeric bounds support, per the API's own limitations).
- Wired it into only the plan-generation call site — deliberately **not** the scan call, which combines `webSearch: true` with JSON output. Structured outputs and web search haven't been verified compatible together in this codebase, so scoping this PR to the simpler, tool-free case first avoids shipping an untested combination.
- Left the existing recovery code (`recoverKeyedArray`, `recoverKeyedString`) in place as a defensive fallback rather than deleting it — a `max_tokens` cutoff mid-response can still produce truncated JSON even with a schema constraining the *shape*, so the fallback still has a job, just a rarer one.
- The `outputSchema` parameter only applies to the Anthropic branch of `callLLM()` — the OpenAI branch is untouched, since its structured-outputs request shape differs and wasn't verified here.

## What this taught me

Two calls in this codebase looked like the same problem ("model sometimes returns malformed JSON") but weren't equally safe to fix the same way — one has a server-side tool in the loop, one doesn't. Reaching for the API-level fix on the tool-free call first, rather than applying the same change to both call sites at once, kept the verified surface area matched to what was actually verified. The untested combination (schema + web search) is now a named, flagged gap instead of a silent assumption.
