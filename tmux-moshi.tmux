#!/usr/bin/env bash
# tmux-moshi: status-line indicator + toggle for the Moshi agent-hook daemon.
#
# Loads defaults, exports the @moshi_status format (splice it into your
# status-right), seeds the cached pairing state, and binds a prefix key + a
# click-to-toggle mouse handler. See README.md for configuration.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Defaults (override any of these before the plugin loads) ---------------
# -o skips options that are already set (even to an empty string, preserving
# the "empty @moshi_toggle_key disables the binding" contract); -q silences
# the "already set" complaint -o would otherwise print.
tmux set-option -goq "@moshi_icon" "󰄛"
tmux set-option -goq "@moshi_color_off" "#6c7086"
tmux set-option -goq "@moshi_color_unpaired" "#f9e2af"
tmux set-option -goq "@moshi_color_paired" "#a6e3a1"
tmux set-option -goq "@moshi_daemon_match" "moshi-hook serve"
tmux set-option -goq "@moshi_toggle_command" "fish -l -c 'moshi-notify toggle'"
tmux set-option -goq "@moshi_pair_check_command" "moshi-hook status"
tmux set-option -goq "@moshi_toggle_key" "N"
tmux set-option -goq "@moshi_enable_mouse" "on"
tmux set-option -goq "@moshi_range_name" "moshi"

range_name="$(tmux show-option -gqv @moshi_range_name)"

# --- Exported status format -------------------------------------------------
# Splice into your theme's status-right with `#{E:@moshi_status}`. The
# range=user wrapper makes the glyph clickable (it fires the Status mouse key
# with mouse_status_range=<range_name>).
tmux set-option -gq @moshi_status \
	"#[range=user|${range_name}]#(${CURRENT_DIR}/scripts/moshi-status)#[norange]"

# Compact variant (icon only — colour conveys state) for narrow clients, e.g. a
# phone bar gated on @phone_max_cols. Splice with `#{E:@moshi_status_compact}`.
tmux set-option -gq @moshi_status_compact \
	"#[range=user|${range_name}]#(${CURRENT_DIR}/scripts/moshi-status --compact)#[norange]"

# --- Seed cached pairing (backgrounded: the probe can touch the Keychain) ---
tmux run-shell -b "${CURRENT_DIR}/scripts/moshi-seed-pairing"

# --- Toggle keybinding (prefix + @moshi_toggle_key; empty string disables) --
toggle_key="$(tmux show-option -gqv @moshi_toggle_key)"
if [ -n "$toggle_key" ]; then
	tmux bind-key "$toggle_key" run-shell -b "${CURRENT_DIR}/scripts/moshi-toggle"
fi

# --- Mouse: click the indicator to toggle, and consume the button release so
# it does not leak a stray click into the active pane (see README "Mouse"). ---
if [ "$(tmux show-option -gqv @moshi_enable_mouse)" = "on" ]; then
	# Left-click the indicator: toggle. Anything else on the status line keeps the
	# default select-window behaviour.
	tmux bind-key -n MouseDown1Status if-shell -F "#{==:#{mouse_status_range},${range_name}}" \
		"run-shell -b '${CURRENT_DIR}/scripts/moshi-toggle'" \
		"select-window -t="

	# Right-click the indicator: a control menu (toggle / refresh pairing / doctor).
	tmux bind-key -n MouseDown3Status if-shell -F "#{==:#{mouse_status_range},${range_name}}" \
		"display-menu -T ' 󰄛 Moshi ' -x M -y M 'Toggle daemon' t 'run-shell -b \"${CURRENT_DIR}/scripts/moshi-toggle\"' 'Refresh pairing' r 'run-shell -b \"${CURRENT_DIR}/scripts/moshi-seed-pairing\"' '' 'Status / doctor' s 'display-popup -E \"${CURRENT_DIR}/scripts/moshi-doctor | less\"'"

	# Consume the button releases so a click never leaks into the active pane.
	tmux bind-key -n MouseUp1Status set-option -gq @moshi_mouse_noop 1
	tmux bind-key -n MouseUp1StatusRight set-option -gq @moshi_mouse_noop 1
	tmux bind-key -n MouseUp3Status set-option -gq @moshi_mouse_noop 1
	tmux bind-key -n MouseUp3StatusRight set-option -gq @moshi_mouse_noop 1
fi
