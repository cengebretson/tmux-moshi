# tmux-moshi

A tmux status-line indicator and one-key/one-click toggle for the
[Moshi](https://getmoshi.app/) **agent-hook notification daemon** (`moshi-hook`),
which pushes agent notifications to the [Moshi iOS terminal app](https://getmoshi.app/).
It shows a 3-state `󰄛` glyph in the status bar, lets you flip the daemon off/on from
a key or a mouse click, and reports the landed state — without leaking the toggle
command's output into your active pane.

> Bespoke by design. It drives a personal `moshi-hook` brew service and a
> `moshi-notify` shell helper, so it is meant to be vendored into your own tmux
> config rather than installed by a general audience. Everything external is
> injected through options (see [Configuration](#configuration)), so you can point
> it at whatever your toggle/probe commands actually are.

## What it does

- **3-state indicator** rendered by `scripts/moshi-status`:
  - dim `󰄛 off` — daemon stopped
  - amber `󰄛 on` — daemon running but **not paired** (won't push)
  - green `󰄛 on` — daemon running **and paired**
- **Toggle** (`prefix` + `N` by default) flips the daemon and flashes the result.
- **Click-to-toggle**: the glyph is wrapped in a `range=user` region, so a
  left-click on it toggles too — and the button **release** is consumed so the
  click never leaks into the focused pane.
- **Cheap pairing**: the slow, Keychain-touching pairing probe runs once at load
  (backgrounded) into the cached `@moshi_paired` option; the per-redraw indicator
  only does an instant `pgrep`.

## Install

### TPM

```tmux
set -g @plugin 'cengebretson/tmux-moshi'
```

### Local / vendored (recommended here, given the bespoke deps)

```tmux
run-shell '~/path/to/tmux-moshi/tmux-moshi.tmux'
```

Then add the indicator to your status line (the plugin only *exports* the format;
your theme decides **where** it sits):

```tmux
set -ga status-right "#{E:@moshi_status}"
```

`@moshi_status` already includes the `range=user|moshi` wrapper, so the click
handler works wherever you place it. Surround it with your own separators/spacing.

## Configuration

Set any of these before the plugin loads:

| Option | Default | Purpose |
|---|---|---|
| `@moshi_icon` | `󰄛` | indicator glyph |
| `@moshi_color_off` | `#6c7086` | dim — daemon stopped |
| `@moshi_color_unpaired` | `#f9e2af` | amber — up, not paired |
| `@moshi_color_paired` | `#a6e3a1` | green — up + paired |
| `@moshi_daemon_match` | `moshi-hook serve` | `pgrep -f` pattern: "is the daemon up" |
| `@moshi_toggle_command` | `fish -l -c 'moshi-notify toggle'` | command that flips the daemon |
| `@moshi_pair_check_command` | `moshi-hook status` | probed once at load; a line matching `^status:\s+paired` sets paired |
| `@moshi_toggle_key` | `N` | prefix key to bind; empty string disables the binding |
| `@moshi_enable_mouse` | `on` | bind click-to-toggle + release-consume |
| `@moshi_range_name` | `moshi` | the `range=user|X` name the click handler matches |
| `@moshi_status` | *(exported)* | the format you splice into `status-right` |

The defaults assume Catppuccin Mocha hexes and a `moshi-notify` fish function; the
options above let you retarget all of it.

## Mouse

The indicator's click fires the `Status` mouse key (because of the `range=user`
wrapper) and toggles. The matching button **release** has no default binding, and
tmux would otherwise forward that raw mouse sequence into the focused pane — which
shows up as a stray click in whatever app is running. The plugin binds
`MouseUp1Status` / `MouseUp1StatusRight` to a no-op so the release is consumed, not
leaked. Non-indicator clicks on the window list keep the default `select-window`.

If you bind those mouse keys yourself, set `@moshi_enable_mouse off` and wire the
indicator click how you like (it just needs `mouse_status_range` == your
`@moshi_range_name`).

## Requirements

This plugin is the tmux-side presentation layer for a personal Moshi setup. It does
**not** ship the daemon or the toggle helper — those are external and injected through
options, so the plugin stays shell-agnostic and testable on its own.

- **[Moshi](https://getmoshi.app/)** — the iOS SSH/Mosh terminal for AI coding agents
  ([App Store](https://apps.apple.com/us/app/moshi-ssh-mosh-terminal/id6757859949)).
  The app receives the push notifications; the rest of this list is what produces them.
- **`tmux` >= 3.0** — uses `range=user` status ranges and `mouse_status_range`.
- **`moshi-hook`** — the agent-hook daemon (a Homebrew service by default). Probed by
  `@moshi_daemon_match` / `@moshi_pair_check_command` to render the indicator.
- **`moshi-notify`** — the shell helper that actually flips the daemon (default:
  `fish -l -c 'moshi-notify toggle'`). It lives in the user's dotfiles, **not** in this
  repo; the plugin only invokes it via `@moshi_toggle_command`. See
  [Configuration](#configuration) to retarget it.

Absent `moshi-hook` / `moshi-notify`, the plugin degrades gracefully: the indicator
reads `off` and the toggle is a harmless no-op. Everything machine-specific is an
option, so you can point the plugin at whatever your daemon and toggle command are.

## Development

```bash
tests/check.sh   # isolated tmux server; fakes the daemon + probe
```

See `CLAUDE.md` for versioning/release notes. Versions follow SemVer in `VERSION`;
pushing a `v*` tag publishes a GitHub release from the matching `CHANGELOG.md`
section.
