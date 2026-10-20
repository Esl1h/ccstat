# ccstat

[![CI](https://github.com/Esl1h/ccstat/actions/workflows/ci.yml/badge.svg)](https://github.com/Esl1h/ccstat/actions/workflows/ci.yml)

A [V](https://vlang.io) statusline command for [Claude Code](https://claude.com/claude-code): model, working directory, repository name, linked git worktree (when inside one), an open PR badge, a color-coded context-usage bar, session cost, prompt-cache hit rate, and 5-hour rate-limit usage.

The reason to write this in V instead of Python or Node: a statusline command runs on every turn. An interpreted script costs 80-300ms just to boot before it does anything. This is a static binary, no runtime, measured at 2 to 3 ms per invocation including the shell's own pipe and process-spawn overhead (100-run average with `date +%s%N`).

No git branch: Claude Code's statusline JSON has no branch field (`workspace.git_worktree` is the linked-worktree name, absent in the main working tree), and running `git` on every render would cost more than this binary does. The docs' own examples shell out to `git branch --show-current` for that.

## Install

Prebuilt binaries for Linux (amd64) and macOS (arm64) are attached to each [release](https://github.com/Esl1h/ccstat/releases) (use `ccstat-macos-arm64` on a Mac):

```sh
curl -fsSLo ~/.local/bin/ccstat https://github.com/Esl1h/ccstat/releases/latest/download/ccstat-linux-amd64
chmod +x ~/.local/bin/ccstat
```

Or build from source:

```sh
git clone https://github.com/Esl1h/ccstat
cd ccstat
make build
sudo make install   # installs to /usr/local/bin, override with PREFIX=
```

Then point Claude Code at it in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "ccstat"
  }
}
```

## Scope

`ccstat` reads exactly what Claude Code already sends on stdin (documented at [code.claude.com/docs/en/statusline](https://code.claude.com/docs/en/statusline)) and formats it. It does not recompute cost or re-read the session transcript: `cost.total_cost_usd` is already the authoritative number for the running session, and `context_window` already carries the pre-calculated usage percentage. Every field is optional in the real contract (most are absent until the first API response, version-gated, or subscriber-only), and a missing or `null` field just means that segment of the line doesn't print, never a crash or a placeholder.

Not built: a cross-session total (e.g. "spent today across every session"). Claude Code's own JSON only ever describes the current session; a running total would need to read every `~/.claude/projects/**/*.jsonl` file on every invocation, and doing that without measuring the cost first risks making a tool whose entire pitch is speed slow in practice. If this is wanted later, it belongs behind an opt-in flag, not the default path, see AGENTS.md.

## Development

```sh
make check   # fmt-check + vet + test
make test
make fmt
```

Try it against a real payload without configuring Claude Code:

```sh
echo '{"model":{"display_name":"Sonnet"},"cost":{"total_cost_usd":0.0123},"context_window":{"used_percentage":8}}' | ./ccstat
```

## License

MIT
