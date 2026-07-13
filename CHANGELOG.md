# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `moshi-doctor` prints its hard-failure summary to stdout instead of stderr,
  so it now appears in the right-click menu's `moshi-doctor | less` popup (the
  exit code still carries the machine-readable signal).

### Changed

- `moshi-status` and `moshi-toggle` compute the state color/label once and
  emit a single `printf` / `display-message` instead of three near-identical
  branches; rendered output is unchanged.

## [0.3.0] - 2026-07-12

### Changed

- `tmux-moshi.tmux` sets its defaults with direct `tmux set-option -goq` calls
  instead of the show-then-set `set_default_option` helper, halving the tmux
  round trips at load. `-o` preserves any pre-set value — including an empty
  `@moshi_toggle_key`, which still disables the binding.
- `moshi-doctor` version check simplified to `major >= 3` (the `minor >= 0` arm
  was always true), and a non-numeric major (e.g. tmux master's `next-3.6`) now
  degrades to a clean warning instead of a shell error.
- `docs/SPEC.md` is marked as a historical design doc (implemented as of v0.1.0
  and published to GitHub/TPM), with notes on the superseded out-of-scope
  passages; README documents current behavior.

### Fixed

- `moshi-doctor` expands a literal leading `~/` in `@moshi_toggle_command` /
  `@moshi_pair_check_command` before resolving the runner, so configs like
  `~/bin/my-moshi-toggle` no longer false-warn "not found".
- README no longer claims the pairing probe runs only once at load — since
  0.2.0 it also runs after every toggle and via the right-click *Refresh
  pairing* menu item.

## [0.2.1] - 2026-07-06

### Fixed

- `moshi-doctor` now also checks the current session's `status-left`/
  `status-right` when verifying the indicator is spliced into the status line,
  instead of only the global scope.

## [0.2.0] - 2026-06-27

### Added

- `scripts/moshi-doctor` — health check for tmux version, plugin load, status-line
  wiring, external-command resolution, and live daemon/pairing state. Also the
  *Status / doctor* item in the new right-click menu.
- Right-click menu on the indicator (`MouseDown3Status`): toggle, refresh pairing,
  or open the doctor. The right-click release is consumed too.
- `@moshi_status_compact` — icon-only status variant (colour conveys state) for
  narrow clients such as a phone bar.

### Changed

- `moshi-toggle` now refreshes the cached pairing (`@moshi_paired`) after flipping
  the daemon, so the landed-state message is accurate even with a custom
  `@moshi_toggle_command`.
- CI pins ShellCheck to 0.11.0 (matching local) and lints `scripts/moshi-doctor`.

### Fixed

- CI ShellCheck failure (SC2015) from the `A && B || C` cleanup idiom in
  `tests/check.sh`; rewritten as an explicit `if`.

## [0.1.0] - 2026-06-27

### Added

- TPM plugin (`tmux-moshi.tmux`) that defines `@moshi_*` options, exports the
  `@moshi_status` status format (with a `range=user` clickable wrapper), seeds the
  cached `@moshi_paired` pairing state, and binds a prefix toggle key plus a
  click-to-toggle mouse handler with a release-consume no-op.
- `scripts/moshi-status` — styled 3-state daemon indicator (off / on-unpaired /
  on-paired), driven by configurable icon, colors, and `pgrep` match.
- `scripts/moshi-toggle` — flips the daemon via the configured command, discards
  its output, and reports the landed state on the status line.
- `scripts/moshi-seed-pairing` — caches the pairing probe result into
  `@moshi_paired`.
- Integration test suite (`tests/check.sh`) running against an isolated tmux
  server with a faked daemon process and pairing probe.
- CI (ShellCheck + tests) and a tag-triggered release workflow.

[Unreleased]: https://github.com/cengebretson/tmux-moshi/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/cengebretson/tmux-moshi/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/cengebretson/tmux-moshi/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/cengebretson/tmux-moshi/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/cengebretson/tmux-moshi/releases/tag/v0.1.0
