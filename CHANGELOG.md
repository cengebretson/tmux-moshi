# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/cengebretson/tmux-moshi/commits/main
