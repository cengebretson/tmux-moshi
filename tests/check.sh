#!/bin/sh
# Integration suite for tmux-moshi. Runs against an isolated tmux server and
# fakes the daemon process / pairing probe so it needs neither moshi-hook nor
# moshi-notify. Mirrors the harness style of tmux-attention.

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
REAL_TMUX="$(command -v tmux)"
TMP_BIN="$(mktemp -d "${TMPDIR:-/tmp}/tmux-moshi-bin.XXXXXX")"
SOCKET_PATH="$TMP_BIN/tmux.sock"
daemon_pid=""

cleanup() {
	"$REAL_TMUX" -S "$SOCKET_PATH" kill-server >/dev/null 2>&1 || true
	if [ -n "$daemon_pid" ]; then
		kill "$daemon_pid" >/dev/null 2>&1 || true
	fi
	rm -rf "$TMP_BIN"
}

trap cleanup EXIT INT TERM

pass() { printf 'ok - %s\n' "$1"; }
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }

assert_eq() {
	if [ "$2" = "$1" ]; then
		pass "$3"
	else
		printf 'expected: %s\nactual:   %s\n' "$1" "$2" >&2
		fail "$3"
	fi
}

assert_contains() {
	case "$2" in
		*"$1"*) pass "$3" ;;
		*)
			printf 'missing: %s\nfrom:    %s\n' "$1" "$2" >&2
			fail "$3"
			;;
	esac
}

assert_not_contains() {
	case "$2" in
		*"$1"*)
			printf 'unexpected: %s\nin:         %s\n' "$1" "$2" >&2
			fail "$3"
			;;
		*) pass "$3" ;;
	esac
}

# Cross-checks the literal fallback baked into each script (used when the
# plugin never loaded, e.g. moshi-doctor diagnosing a broken install) against
# tmux-moshi.tmux's canonical `set-option -goq` default, so the two can't
# silently drift apart. See CLAUDE.md's "literal fallbacks" design note.
assert_fallbacks_match() {
	opt_name="$1"
	shift
	canonical="$(grep -m1 "\"@${opt_name}\"" "$ROOT_DIR/tmux-moshi.tmux" | awk -F'"' '{print $(NF - 1)}')"
	for f in "$@"; do
		actual="$(grep -m1 "@${opt_name})" "$f" | awk -F'"' '{print $(NF - 1)}')"
		assert_eq "$canonical" "$actual" "@${opt_name} fallback in $(basename "$f") matches the plugin default"
	done
}

tmux_test() { "$REAL_TMUX" -S "$SOCKET_PATH" "$@"; }

# A tmux shim on PATH so the plugin scripts talk to the isolated server.
cat >"$TMP_BIN/tmux" <<EOF
#!/bin/sh
exec "$REAL_TMUX" -S "$SOCKET_PATH" "\$@"
EOF
chmod +x "$TMP_BIN/tmux"

PATH="$TMP_BIN:$PATH"
export PATH

tmux_test -f /dev/null new-session -d -s tmux-moshi-test

# --- syntax ----------------------------------------------------------------
bash -n "$ROOT_DIR/tmux-moshi.tmux"
pass "tmux-moshi.tmux has valid bash syntax"
for s in moshi-status moshi-toggle moshi-seed-pairing moshi-doctor; do
	bash -n "$ROOT_DIR/scripts/$s"
	pass "scripts/$s has valid bash syntax"
done

# --- default-value drift guard ----------------------------------------------
# Every script keeps its own literal fallback for these options so it works
# standalone (e.g. moshi-status called directly by the status line, or
# moshi-doctor diagnosing an install where the plugin never loaded). Assert
# each script's fallback still matches tmux-moshi.tmux's default instead of
# trusting the copies to stay in sync.
assert_fallbacks_match moshi_icon "$ROOT_DIR/scripts/moshi-status" "$ROOT_DIR/scripts/moshi-toggle"
assert_fallbacks_match moshi_daemon_match "$ROOT_DIR/scripts/moshi-status" "$ROOT_DIR/scripts/moshi-toggle" "$ROOT_DIR/scripts/moshi-doctor"
assert_fallbacks_match moshi_color_off "$ROOT_DIR/scripts/moshi-status" "$ROOT_DIR/scripts/moshi-toggle"
assert_fallbacks_match moshi_color_unpaired "$ROOT_DIR/scripts/moshi-status" "$ROOT_DIR/scripts/moshi-toggle"
assert_fallbacks_match moshi_color_paired "$ROOT_DIR/scripts/moshi-status" "$ROOT_DIR/scripts/moshi-toggle"
assert_fallbacks_match moshi_toggle_command "$ROOT_DIR/scripts/moshi-toggle" "$ROOT_DIR/scripts/moshi-doctor"
assert_fallbacks_match moshi_pair_check_command "$ROOT_DIR/scripts/moshi-doctor" "$ROOT_DIR/scripts/moshi-seed-pairing"

# --- plugin entry: defaults, exported formats, bindings --------------------
"$ROOT_DIR/tmux-moshi.tmux"

assert_eq "󰄛" "$(tmux_test show-option -gqv @moshi_icon)" "default icon is set"
assert_eq "moshi-hook serve" "$(tmux_test show-option -gqv @moshi_daemon_match)" "default daemon match is set"
assert_eq "N" "$(tmux_test show-option -gqv @moshi_toggle_key)" "default toggle key is set"

status="$(tmux_test show-option -gqv @moshi_status)"
assert_contains "range=user|moshi" "$status" "status format wraps a clickable user range"
assert_contains "moshi-status" "$status" "status format calls the status script"

status_compact="$(tmux_test show-option -gqv @moshi_status_compact)"
assert_contains "--compact" "$status_compact" "compact status format requests compact mode"
assert_contains "range=user|moshi" "$status_compact" "compact status format keeps the clickable range"

assert_contains "moshi-toggle" "$(tmux_test list-keys -T prefix)" "prefix toggle key is bound to the toggle script"
root_keys="$(tmux_test list-keys -T root)"
assert_contains "mouse_status_range" "$root_keys" "left-click toggle mouse binding is installed"
assert_contains "MouseUp1Status" "$root_keys" "left-click release consume binding is installed"
assert_contains "MouseDown3Status" "$root_keys" "right-click menu binding is installed"
assert_contains "display-menu" "$root_keys" "right-click opens a display-menu"
assert_contains "MouseUp3Status" "$root_keys" "right-click release consume binding is installed"

# --- configured overrides survive a re-source ------------------------------
tmux_test set-option -gq @moshi_icon "X"
"$ROOT_DIR/tmux-moshi.tmux"
assert_eq "X" "$(tmux_test show-option -gqv @moshi_icon)" "plugin preserves a configured icon override"
tmux_test set-option -gq @moshi_icon "󰄛"

# --- moshi-status: 3-state rendering + compact mode ------------------------
# OFF: a daemon match pattern no running process satisfies.
tmux_test set-option -gq @moshi_daemon_match "moshi-absent-daemon-$$"
off_out="$("$ROOT_DIR/scripts/moshi-status")"
assert_contains " off" "$off_out" "status renders off when the daemon is not running"
assert_contains "$(tmux_test show-option -gqv @moshi_color_off)" "$off_out" "off state uses the configured dim color"

compact_out="$("$ROOT_DIR/scripts/moshi-status" --compact)"
assert_contains "$(tmux_test show-option -gqv @moshi_color_off)" "$compact_out" "compact mode keeps the state color"
assert_not_contains "off" "$compact_out" "compact mode omits the on/off label"

# ON: start a fake long-lived process whose argv matches a unique pattern.
daemon_tag="moshi-fake-daemon-$$"
cat >"$TMP_BIN/$daemon_tag" <<'EOF'
#!/bin/sh
sleep 300
EOF
chmod +x "$TMP_BIN/$daemon_tag"
"$TMP_BIN/$daemon_tag" &
daemon_pid=$!
i=0
while [ "$i" -lt 50 ] && ! pgrep -f "$daemon_tag" >/dev/null 2>&1; do
	i=$((i + 1))
	sleep 0.1
done
tmux_test set-option -gq @moshi_daemon_match "$daemon_tag"

tmux_test set-option -gq @moshi_paired yes
paired_out="$("$ROOT_DIR/scripts/moshi-status")"
assert_contains " on" "$paired_out" "status renders on when the daemon is running"
assert_contains "$(tmux_test show-option -gqv @moshi_color_paired)" "$paired_out" "paired state uses the configured green color"

tmux_test set-option -gq @moshi_paired no
unpaired_out="$("$ROOT_DIR/scripts/moshi-status")"
assert_contains "$(tmux_test show-option -gqv @moshi_color_unpaired)" "$unpaired_out" "unpaired state uses the configured amber color"

kill "$daemon_pid" >/dev/null 2>&1 || true
daemon_pid=""

# --- moshi-toggle: runs the command and refreshes cached pairing -----------
toggle_mark="$TMP_BIN/toggled"
tmux_test set-option -gq @moshi_toggle_command "touch $toggle_mark"
tmux_test set-option -gq @moshi_pair_check_command "printf 'status: paired\n'"
tmux_test set-option -gq @moshi_daemon_match "moshi-absent-daemon-$$"
tmux_test set-option -gq @moshi_paired "stale"
"$ROOT_DIR/scripts/moshi-toggle"
if [ -f "$toggle_mark" ]; then
	pass "toggle runs the configured toggle command"
else
	fail "toggle runs the configured toggle command"
fi
assert_eq "yes" "$(tmux_test show-option -gqv @moshi_paired)" "toggle refreshes the cached pairing afterward"

# --- moshi-seed-pairing: maps probe output to @moshi_paired ----------------
tmux_test set-option -gq @moshi_pair_check_command "printf 'status: paired\n'"
"$ROOT_DIR/scripts/moshi-seed-pairing"
assert_eq "yes" "$(tmux_test show-option -gqv @moshi_paired)" "seed-pairing sets paired=yes on a paired probe"

tmux_test set-option -gq @moshi_pair_check_command "printf 'status: unpaired\n'"
"$ROOT_DIR/scripts/moshi-seed-pairing"
assert_eq "no" "$(tmux_test show-option -gqv @moshi_paired)" "seed-pairing sets paired=no on an unpaired probe"

# --- moshi-doctor: reports state and exits cleanly with the plugin loaded --
doctor_rc=0
doctor_out="$("$ROOT_DIR/scripts/moshi-doctor" 2>&1)" || doctor_rc=$?
assert_eq "0" "$doctor_rc" "doctor exits 0 with tmux present and the plugin loaded"
assert_contains "plugin loaded" "$doctor_out" "doctor confirms the plugin is loaded"
assert_contains "supports clickable status ranges" "$doctor_out" "doctor checks the tmux version"

printf 'all checks passed\n'
