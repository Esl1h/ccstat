# AGENTS.md

Instructions for coding agents working in this repository.

## What this project is

`ccstat` is a V CLI: a Claude Code statusline command. It parses the JSON
Claude Code writes to the command's stdin on every turn
(https://code.claude.com/docs/en/statusline.md) and prints a compact,
color-coded status line. The whole point is startup speed: measured at
2 to 3 ms per invocation on this machine (100-run average via `date
+%s%N`, including the shell's own pipe and process-spawn cost), while a
statusline command runs constantly and an interpreted one costs 80-300ms
just to boot.

## V is under-represented in your training data, verify, never guess

Same standing rule as `vai`, `redact`, `vjsonrpc`. Compile after every
meaningful change: `v test .`. This repo has no heavy dependency
(`net.http` and friends), so it compiles in seconds, not the
dozens-of-seconds `vai` needs, if a build here ever takes that long,
something is wrong (check for an accidentally-added `vai` import; see Do
not, below).

## The statusline JSON contract, verify against the real page, not memory

Every field ccstat reads was confirmed against
https://code.claude.com/docs/en/statusline.md directly (not from a
subagent's paraphrase, the first research pass came back flagged by the
harness as possibly containing an instruction-shaped pattern from the
fetched page, most likely a false positive triggered by the page's own
"Documentation Index" preamble, but it was independently re-verified
against the primary source before writing any code against it. If you
research this contract again, fetch the page yourself and don't take a
second-hand summary of it at face value, regardless of the source).

Facts worth remembering, since the contract is large and mostly optional:

- Almost everything is conditionally present: `rate_limits` only appears
  for Pro/Max subscribers (or behind a spend-limit gateway) and only after
  the session's first API response; `prompt_cache` needs Claude Code
  v2.1.251+; `pr` only exists with an open PR/MR and disappears once it
  merges or closes; `effort` only appears for models that support it;
  `context_window.current_usage` and the two percentage fields are `null`
  before the first API call and again right after `/compact`.
- `workspace.git_worktree` is the name of a *linked* worktree (`git
  worktree add`), absent in the main working tree. It is not the branch;
  there is no branch field in the contract at all (the docs' own example
  scripts run `git branch --show-current` for it). ccstat shows it as
  `wt:<name>` and deliberately does not run `git`, so the hot path stays a
  single JSON parse.
- `cost.total_cost_usd` is already the authoritative, pre-computed session
  total. Don't recompute it from `context_window.current_usage` and a
  pricing table, that's redundant and can drift from what Claude Code
  itself reports.
- `context_window.used_percentage` is calculated from input tokens only
  (`input_tokens + cache_creation_input_tokens + cache_read_input_tokens`),
  not from `total_input_tokens + total_output_tokens`. Don't recompute it
  either; just display the field.

## Gotchas found in this codebase

- `json2.Any` map access needs the same `or {}` / `if v := m[key] {}`
  discipline as `vai`, `redact`, `vjsonrpc` found, a missing key on a
  sum-typed map value silently returns the first-declared variant's zero
  value if you skip it. Every optional field here is read through
  `if v := obj[key] { ... }`, never a bare index.
- json2 bakes ANSI color escapes and a multi-line context into its decode
  error messages even when piped (same finding as `vjsonrpc`);
  `parse_status` flattens that to one plain line (`one_line_error`) so a
  bad payload shows `ccstat: <reason>` instead of a colored block.
- `${x:.0f}` / `${x:.4f}`-style printf format specifiers work directly
  inside V string interpolation, confirmed by probe before writing
  `format.v`. No manual rounding/string-building needed for the percentage
  and dollar-amount display.

## Design decisions worth knowing before changing scope

- **No dependency on `vai`.** The first draft considered using
  `vai.cost()` to compute a cache-savings breakdown, or `vai.local` for a
  cross-session total. Both were cut: `cost.total_cost_usd` already covers
  the single-session case correctly and independently recomputing it adds
  drift risk for no benefit, and a cross-session total needs a filesystem
  scan of every project's transcripts that shouldn't run on every
  keystroke-driven statusline re-render without first measuring whether
  it's actually fast enough. If a future `ccstat --daily`-style mode wants
  cross-session totals, that's the natural place for `vai.local` to come
  in, gated behind an explicit flag so the hot path stays untouched.
- **Two-line output, not one.** Identity (model, dir, worktree/repo, PR) on
  line 1, usage (context bar, cost, cache, rate limit) on line 2. Matches
  the pattern in Claude Code's own multi-line example on the docs page.
- **Absent field means the segment doesn't print, never a placeholder
  like "n/a" or "0%"**, except the context bar itself, which does show
  `ctx: n/a` when `used_percentage` is null, since leaving the whole
  second line ambiguous (is it 0% or unknown?) is worse than being
  explicit about not knowing yet.

## Build and test

```sh
make check   # fmt-check + vet + test
make test    # v test .
make fmt     # v fmt -w .
```

## Do not

- Add `vai` (or any dependency) to `v.mod` without a concrete reason tied
  to a feature actually being built, see the cross-session-total note
  above for why this was deliberately kept dependency-free.
- Recompute anything Claude Code's JSON already gives you a precomputed
  answer for (`total_cost_usd`, `used_percentage`). Display it; don't
  second-guess it.
- Read `transcript_path` for anything the top-level JSON already covers.
  It exists for callers that want to compute something Claude Code
  doesn't already surface, not as ccstat's primary data source.
