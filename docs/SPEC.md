# Spec: `tmux-moshi` plugin

Status: **historical design doc** — implemented as of v0.1.0 and published to
GitHub/TPM; sections below reflect the original proposal. See `README.md` for
current behavior and the full option list.
Author target: in-tree plugin alongside `tmux-attention` and `tmux-fzf-jump`.

## 1. Goal

Consolidate the scattered Moshi agent-hook **notification daemon** indicator + toggle
into one self-contained tmux plugin with default options, mirroring the conventions
already used by `plugins/tmux-attention` (set-default-option entry script, exported
status format, `VERSION`/`CHANGELOG`/`tests/check.sh`).

This is **consolidation + parameterization**, not new behavior. Pure relocation of
working code into a plugin boundary.

## 2. Scope

### In scope (the "notification daemon" concern)
- 3-state status indicator (`off` / `on unpaired` / `on paired`).
- Toggle action (daemon off/on) with landed-state feedback on the status line.
- Click-to-toggle on the indicator (status mouse range) + mouse-release consume.
- `prefix`-key toggle binding (opt-in / configurable).
- Seeding the cached `@moshi_paired` option at load.

### Out of scope (deliberately — different concern)
- `phone_autoview.sh` / `phone_autoview_cleanup.sh`, `@phone_max_cols`,
  `@fzf_pane_switch_exclude-sessions phone-*`. This is **session mirroring**, not the
  notify daemon. It couples to fzf-jump and client-size hooks. If ever extracted, it
  belongs in a separate `tmux-moshi-remote` plugin, not this one.
- Publishing to GitHub/TPM as a reusable package. Bespoke deps (`moshi-notify`,
  `moshi-hook`) mean no external audience. Load it locally by path.
  *(Superseded — see the status banner above: the plugin was ultimately published
  to GitHub and installable via TPM.)*

## 3. External dependencies (unchanged, injected via options)
- `moshi-hook` — brew-managed daemon (`moshi-hook serve`) + `moshi-hook status`.
- `moshi-notify` — fish function performing the actual toggle (run via login fish).
Plugin must **degrade gracefully** when absent: indicator renders `off`, toggle is a
no-op with a clear message. (Current `moshi_status.sh` already exits "off" when the
daemon isn't running, so the indicator side is already safe.)

## 4. Proposed layout (mirrors tmux-attention)

```
plugins/tmux-moshi/
  tmux-moshi.tmux        # entry: set defaults, export @moshi_status, seed pairing, bind keys/mouse
  scripts/
    moshi-status         # was scripts/moshi_status.sh — emits styled 3-state glyph
    moshi-toggle         # was scripts/moshi_toggle.sh — toggles, reports landed state
    moshi-seed-pairing   # the load-time `moshi-hook status` -> @moshi_paired probe
  README.md
  CLAUDE.md
  VERSION                # SemVer, start 0.1.0
  CHANGELOG.md           # Keep a Changelog; [Unreleased] maintained per-change
  tests/check.sh         # isolated-server integration suite (copy attention harness)
```

## 5. Public options (defaults set in `tmux-moshi.tmux`)

| Option | Default | Purpose |
|---|---|---|
| `@moshi_icon` | `󰄛` | indicator glyph |
| `@moshi_color_off` | `#6c7086` | dim — daemon stopped |
| `@moshi_color_unpaired` | `#f9e2af` | amber — up, not paired |
| `@moshi_color_paired` | `#a6e3a1` | green — up + paired |
| `@moshi_daemon_match` | `moshi-hook serve` | `pgrep -f` pattern for "is the daemon up" |
| `@moshi_toggle_command` | `fish -l -c 'moshi-notify toggle'` | how to flip the daemon |
| `@moshi_pair_check_command` | `moshi-hook status` | probed at load; `paired` -> `@moshi_paired yes` |
| `@moshi_toggle_key` | `N` | prefix key to bind; empty string disables |
| `@moshi_enable_mouse` | `on` | bind click-to-toggle + release-consume |
| `@moshi_range_name` | `moshi` | `range=user|X` name the mouse binding matches |
| `@moshi_status` | *(exported)* | the format you splice into `status-right` |

**Exported format** (the key integration point), e.g.:

```tmux
set -gq @moshi_status "#[range=user|#{@moshi_range_name}]#(<plugin>/scripts/moshi-status)#[norange]"
```

So themes reference `#{E:@moshi_status}` and get the clickable range for free; the
script emits the `#[fg=…]<icon> on/off` body using the color options above.

## 6. What the plugin owns vs. what stays in your config

### Moves INTO the plugin
| Today | Becomes |
|---|---|
| `scripts/moshi_status.sh` | `scripts/moshi-status` (reads color/icon/match options) |
| `scripts/moshi_toggle.sh` | `scripts/moshi-toggle` (reads toggle command + colors) |
| `tmux.conf` `@moshi_paired` seed (`run-shell -b "moshi-hook status …"`) | `scripts/moshi-seed-pairing`, called from `.tmux` entry |
| `tmux.conf` `bind N …` | conditional bind via `@moshi_toggle_key` |
| `tmux.conf` `MouseDown1Status { if … }` | conditional bind via `@moshi_enable_mouse` (preserves `select-window -t=` fallback) |
| `tmux.conf` `MouseUp1Status` / `MouseUp1StatusRight` no-ops | bound by `.tmux` entry |

### STAYS in your config (plugin can't own placement)
- The **splice point** in each `status-right`: `appearance1.conf` line ~27 and
  `appearance2.conf` line ~84 become `#{E:@moshi_status}` but keep their surrounding
  separators (`│`), `bg/fg` context, and spacing — theme decides *where* it sits.
- The **phone-width gate** in `appearance2.conf`
  (`#{?#{e|>=:#{client_width},#{@phone_max_cols}}, … ,}`) wrapping the indicator —
  stays; that's theme/phone policy, not daemon logic.

### Caller-side after migration (`tmux.conf`)
```tmux
set -g @plugin 'tmux-moshi'        # or load by path: run '~/.config/tmux/plugins/tmux-moshi/tmux-moshi.tmux'
# optional overrides:
# set -g @moshi_toggle_key 'N'
# set -g @moshi_enable_mouse 'on'
```
Net `tmux.conf` change: delete ~10 lines (seed + 3 binding blocks), add 1 plugin line.

## 7. Behavior parity checklist (must match current)
- [ ] Indicator: dim off / amber on-unpaired / green on-paired, same hexes.
- [ ] `prefix N` toggles; instant "toggling…" flash, then landed-state message.
- [ ] Click the glyph toggles (fires `Status` key via `range=user`), `select-window`
      preserved for the rest of the window list.
- [ ] Mouse **release** consumed (`MouseUp1Status` + `…StatusRight`) — no stray click
      leaking into the active pane.
- [ ] Brew/`moshi-notify` stdout suppressed (no chatter in pane).
- [ ] `@moshi_paired` seeded at load, backgrounded (Keychain can be slow).
- [ ] Graceful no-op when `moshi-hook` / `moshi-notify` not installed.

## 8. Risks / open questions
- **Mouse-key ownership.** The plugin claims `MouseDown1Status` (with `select-window`
  fallback) + the two `MouseUp` keys. Confirm nothing else in the config wants those.
  `MouseDown1StatusLeft` (fzf-jump) is a *different* key and is untouched.
- **Format option timing.** `@moshi_status` must be set *before* the appearance files
  reference it, or expose it lazily. attention sets `@tmux_attention_status` in its
  `.tmux` entry which loads via TPM near the bottom — verify ordering vs. `source-file
  appearance.conf`. May need the option set early (top of entry) and the theme to use
  `#{E:@moshi_status}` (extended) so it resolves at redraw, not source, time.
- **Load mechanism.** TPM `@plugin` (needs a git repo) vs. local `run '…/tmux-moshi.tmux'`
  by path. Given bespoke deps, **local path load** is simpler and avoids a throwaway
  GitHub repo. (attention/fzf-jump are real `cengebretson/*` repos; this one need not be.)
  *(Superseded — see the status banner above: it became a real GitHub repo with
  both TPM and local-path install paths.)*
- **Naming.** `tmux-moshi` vs `tmux-moshi-notify`. Prefer `tmux-moshi` and reserve room
  for a sibling `tmux-moshi-remote` if phone-autoview is ever extracted.

## 9. Effort estimate
Small. Two ~20-line scripts get parameterized, one ~40-line `.tmux` entry, plus
README/VERSION/CHANGELOG and a copied test harness. Roughly a half-day including
parity testing on an isolated tmux server (`tests/check.sh`).
