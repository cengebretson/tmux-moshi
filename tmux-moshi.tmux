#!/usr/bin/env bash
# tmux-moshi: status-line indicator + toggle for the Moshi agent-hook daemon.
#
# Loads defaults, exports the @moshi_status format (splice it into your
# status-right), seeds the cached pairing state, and binds a prefix key + a
# click-to-toggle mouse handler. See README.md for configuration.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set_default_option() {
	local option="$1"
	local value="$2"

	if ! tmux show-option -g "$option" >/dev/null 2>&1; then
		tmux set-option -gq "$option" "$value"
	fi
}

# --- Defaults (override any of these before the plugin loads) ---------------
set_default_option "@moshi_icon" "󰄛"
set_default_option "@moshi_color_off" "#6c7086"
set_default_option "@moshi_color_unpaired" "#f9e2af"
set_default_option "@moshi_color_paired" "#a6e3a1"
set_default_option "@moshi_daemon_match" "moshi-hook serve"
set_default_option "@moshi_toggle_command" "fish -l -c 'moshi-notify toggle'"
set_default_option "@moshi_pair_check_command" "moshi-hook status"
set_default_option "@moshi_toggle_key" "N"
set_default_option "@moshi_enable_mouse" "on"
set_default_option "@moshi_range_name" "moshi"

range_name="$(tmux show-option -gqv @moshi_range_name)"

# --- Exported status format -------------------------------------------------
# Splice into your theme's status-right with `#{E:@moshi_status}`. The
# range=user wrapper makes the glyph clickable (it fires the Status mouse key
# with mouse_status_range=<range_name>).
tmux set-option -gq @moshi_status \
	"#[range=user|${range_name}]#(${CURRENT_DIR}/scripts/moshi-status)#[norange]"

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
	tmux bind-key -n MouseDown1Status if-shell -F "#{==:#{mouse_status_range},${range_name}}" \
		"run-shell -b '${CURRENT_DIR}/scripts/moshi-toggle'" \
		"select-window -t="
	tmux bind-key -n MouseUp1Status set-option -gq @moshi_mouse_noop 1
	tmux bind-key -n MouseUp1StatusRight set-option -gq @moshi_mouse_noop 1
fi
