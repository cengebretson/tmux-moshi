# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/cengebretson/tmux-moshi/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/cengebretson/tmux-moshi/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/cengebretson/tmux-moshi/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/cengebretson/tmux-moshi/releases/tag/v0.1.0
