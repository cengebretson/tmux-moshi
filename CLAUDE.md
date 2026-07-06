# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code
in this repository.

See `README.md` for what the plugin does, its parts (status script, toggle,
pairing seed, mouse handling), and configuration.

## Layout

- `tmux-moshi.tmux` — plugin entry: sets default `@moshi_*` options, exports the
  `@moshi_status` format, seeds pairing, and binds the toggle key + mouse handlers.
- `scripts/moshi-status` — emits the styled 3-state indicator (read by `#()` in
  `@moshi_status`).
- `scripts/moshi-toggle` — flips the daemon, then reports the landed state.
- `scripts/moshi-seed-pairing` — caches the pairing probe into `@moshi_paired`.
- `scripts/moshi-doctor` — health check (tmux version, plugin load, status-line
  wiring, external deps, live state); also the right-click menu's doctor item.

All scripts use `#!/usr/bin/env bash` and read configuration from tmux options
(with literal fallbacks). The indicator/toggle/seed scripts always exit 0 so a
failed probe never surfaces an error in the status line; `moshi-doctor` is the
exception — it exits non-zero on hard failures so it is scriptable.

## Tests

Run the integration suite (spins up an isolated tmux server and fakes the daemon
process / pairing probe, so it needs neither `moshi-hook` nor `moshi-notify`):

```bash
tests/check.sh
```

`make test` runs the same suite; `make lint` runs ShellCheck over the scripts and
plugin entry. CI (`.github/workflows/ci.yml`) runs ShellCheck (pinned to v0.11.0 to
match local) and the suite on every push and pull request.

## Versioning and releases

SemVer. The current version lives in `VERSION`. Notes are tracked in a Keep a
Changelog `CHANGELOG.md`.

**Keep the changelog current:** every user-facing change adds a bullet to the
`## [Unreleased]` section of `CHANGELOG.md` in the same commit that makes the
change.

Cut a release with the `git release` helper (`~/.local/bin/git-release`, available
machine-wide in any repo):

```bash
git release <x.y.z|major|minor|patch> --push
```

It bumps `VERSION`, promotes + dates the `[Unreleased]` section, runs
`tests/check.sh`, commits, tags `v<x.y.z>`, and (with `--push`) pushes the branch +
tag. The tag triggers `.github/workflows/release.yml`, which re-runs the checks,
verifies the tag matches `VERSION`, and publishes a GitHub release from that
version's changelog section. Use `git release <x.y.z> --dry-run` to preview first.

## Pre-commit

`.pre-commit-config.yaml` runs ShellCheck over the scripts/entry/harness and then
the integration suite. Enable it once with `pre-commit install` (requires
[pre-commit](https://pre-commit.com) and `shellcheck` on PATH).
