# GitHub Pages was quietly reprocessing the site through Jekyll

**Ships:** [`72ee64c`](https://github.com/shilpi1958/job-radar/commit/72ee64c) — Add .nojekyll so GitHub Pages serves the site as static files.

## The problem

GitHub Pages runs every site through Jekyll by default before serving
it — even sites with no Jekyll config at all. For a single static
`index.html` with no build step, that's an invisible extra processing
pass: Jekyll ignores files/folders starting with `_` (and treats a few
other paths specially), which is irrelevant here today but is exactly
the kind of thing that silently breaks a future file you add without
knowing why.

## The fix

One empty file: `.nojekyll` at the repo root. Its presence alone tells
Pages "skip the Jekyll build, serve these files exactly as they are."

## What this taught me

Zero-config deploy platforms still have a default pipeline running
underneath — "no build step" for *my* code doesn't mean "no processing"
by the *host*. Worth checking what a deploy target does by default
before assuming raw files are served raw, especially for a project
that's deliberately building without a bundler.
