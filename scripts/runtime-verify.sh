
#!/usr/bin/env bash
# CyberDotfiles v7 — Runtime Verification
# Read-only checks. Does not reload Hyprland or modify system configuration.

set -u

ROOT="${CYBERDOTFILES_ROOT:-$HOME/CyberDotfiles}"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cyberdotfiles"
LOG_FILE="$LOG_DIR/runtime-verify-$(date +%Y%m%d-%H%M%S).log"

PASS=0
WARN=0
FAIL=0
MANUAL=0

if [[ ! -d "$ROOT" ]]; then
    echo "ERROR: Repository not found: $ROOT"
    exit 2
fi

mkdir -p "$LOG_DIR"
exec > >(tee "$LOG_FILE") 2>&1

pass() {
    PASS=$((PASS + 1))
    printf '[PASS] %s\n' "$1"
}

warn() {
    WARN=$((WARN + 1))
    printf '[WARN] %s\n' "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf '[FAIL] %s\n' "$1"
}

manual() {
    MANUAL=$((MANUAL + 1))
    printf '[MANUAL] %s\n' "$1"
}

info() {
    printf '[INFO] %s\n' "$1"
}

section() {
    printf '\n========================================\n'
    printf '%s\n' "$1"
    printf '========================================\n'
}

has_command() {
    command -v "$1" >/dev/null 2>&1
}

check_command() {
    if has_command "$1"; then
        pass "Command available: $1"
    else
        fail "Missing command: $1"
    fi
}

check_process() {
    if pgrep -x "$1" >/dev/null 2>&1; then
        pass "Process running: $1"
    else
        warn "Process not running: $1"
    fi
}

check_service() {
    local service="$1"

    if systemctl is-active --quiet "$service"; then
        pass "Service active: $service"
    else
        warn "Service inactive: $service"
    fi
}

check_file() {
    if [[ -f "$1" ]]; then
        pass "File exists: ${1#"$ROOT"/}"
    else
        fail "Missing file: ${1#"$ROOT"/}"
    fi
}

# --------------------------------------------------
section "1. SYSTEM AND HYPRLAND"
# --------------------------------------------------

check_command hyprctl
check_command jq
check_command python3

if has_command hyprctl; then
    VERSION="$(hyprctl version 2>&1 || true)"

    if grep -q 'Hyprland 0\.57\.2' <<< "$VERSION"; then
        pass "Hyprland 0.57.2 detected"
    else
        warn "Hyprland version differs from target 0.57.2"
    fi

    printf '%s\n' "$VERSION" | head -5

    STATUS="$(hyprctl status 2>&1 || true)"

    if [[ -n "$STATUS" ]]; then
        pass "Hyprland IPC responds"
        printf '%s\n' "$STATUS" | head -10
    else
        fail "Cannot query Hyprland status"
    fi

    LUA_PROBE="$(hyprctl repl \
        'type(hl) .. ":" .. type(hl.bind)' 2>&1 || true)"

    if grep -q 'table:function' <<< "$LUA_PROBE"; then
        pass "Native Hyprland Lua API is available"
    else
        fail "Cannot verify native Lua API: $LUA_PROBE"
    fi

    CONFIG_ERRORS="$(hyprctl configerrors 2>&1 || true)"
    CONFIG_NORMALIZED="$(printf '%s' "$CONFIG_ERRORS" | tr -d '[:space:]')"

    if [[ -z "$CONFIG_NORMALIZED" ||
          "$CONFIG_NORMALIZED" == "[]" ]] ||
       grep -qiE 'no config errors|no errors found' <<< "$CONFIG_ERRORS"; then
        pass "Hyprland configuration has no reported errors"
    else
        fail "Hyprland configuration errors detected"
        printf '%s\n' "$CONFIG_ERRORS"
    fi
fi

# --------------------------------------------------
section "2. LUA CONFIGURATION FILES"
# --------------------------------------------------

check_file "$ROOT/config/hypr/hyprland.lua"
check_file "$ROOT/config/hypr/user.lua"
check_file "$ROOT/config/hypr/themes/tokens.lua"

MODULES=(
    init
    options
    environment
    monitor
    input
    appearance
    animations
    workspaces
    window-rules
    layer-rules
    binds
    autostart
)

for module in "${MODULES[@]}"; do
    check_file "$ROOT/config/hypr/modules/$module.lua"
done

# --------------------------------------------------
section "3. MONITOR AND SCALE"
# --------------------------------------------------

if has_command hyprctl && has_command jq; then
    MONITORS="$(hyprctl monitors -j 2>/dev/null || true)"

    if jq -e \
        'any(.[]; .name == "eDP-1"
         and .width == 2560
         and .height == 1440
         and (.scale >= 1.24 and .scale <= 1.26))' \
        <<< "$MONITORS" >/dev/null 2>&1; then

        pass "eDP-1 is 2560x1440 at scale 1.25"
    else
        warn "Monitor does not match the expected 2560x1440 / 1.25"

        jq -r '.[] | "\(.name): \(.width)x\(.height), scale=\(.scale)"' \
            <<< "$MONITORS" 2>/dev/null || true
    fi
fi

# --------------------------------------------------
section "4. KEYBIND REGISTRATION"
# --------------------------------------------------

BINDS="$(hyprctl binds -j 2>/dev/null || true)"

has_bind() {
    local key="$1"
    local mask="$2"

    jq -e --arg key "$key" --arg mask "$mask" \
        'any(.[];
            ((.key // "") | ascii_upcase) == $key
            and ((.modmask | tostring) == $mask)
        )' <<< "$BINDS" >/dev/null 2>&1
}

if [[ -n "$BINDS" ]] && jq -e 'type == "array"' \
    <<< "$BINDS" >/dev/null 2>&1; then

    if has_bind SPACE 64; then
        pass "SUPER + SPACE is registered"
    else
        fail "SUPER + SPACE is missing"
    fi

    if has_bind R 64; then
        pass "SUPER + R is registered"
    else
        fail "SUPER + R is missing"
    fi

    if has_bind F1 64; then
        pass "SUPER + F1 is registered"
    else
        warn "SUPER + F1 is missing"
    fi

    if has_bind S 65; then
        pass "SUPER + SHIFT + S is registered"
    else
        warn "SUPER + SHIFT + S is missing"
    fi
else
    fail "Cannot read Hyprland binds JSON"
fi

if grep -q 'rofi -show drun' \
    "$ROOT/config/hypr/modules/binds.lua" \
    "$ROOT/scripts/app-launch.sh" 2>/dev/null; then
    pass "Rofi application launcher is referenced in configuration"
else
    warn "Cannot find Rofi application launcher command"
fi

# --------------------------------------------------
section "5. CORE APPLICATIONS"
# --------------------------------------------------

COMMANDS=(
    waybar
    rofi
    swaync
    awww
    awww-daemon
    kitty
    fcitx5
    wl-copy
    cliphist
    grimblast
    hypridle
    python3
)

for cmd in "${COMMANDS[@]}"; do
    check_command "$cmd"
done

# --------------------------------------------------
section "6. DESKTOP PROCESSES"
# --------------------------------------------------

PROCESSES=(
    waybar
    swaync
    awww-daemon
    fcitx5
    hypridle
)

for proc in "${PROCESSES[@]}"; do
    check_process "$proc"
done

if pgrep -af '[h]yprpolkitagent' >/dev/null 2>&1; then
    pass "Hyprland Polkit agent running"
else
    warn "Hyprland Polkit agent not detected"
fi

if pgrep -af '[s]tartup.sh' >/dev/null 2>&1; then
    pass "CyberDotfiles startup script process detected"
else
    warn "No startup.sh process detected (it may already have exited)"
fi

# --------------------------------------------------
section "7. SYMLINK INTEGRATION"
# --------------------------------------------------

for name in hypr waybar swaync rofi; do
    LINK="$HOME/.config/$name"
    EXPECTED="$ROOT/config/$name"
    ACTUAL="$(readlink -f "$LINK" 2>/dev/null || true)"

    if [[ "$ACTUAL" == "$EXPECTED" ]]; then
        pass "Config symlink correct: $name"
    elif [[ -e "$LINK" ]]; then
        warn "Config exists but is not linked to repo: $name"
        info "Current target: $ACTUAL"
    else
        warn "Config link missing: $LINK"
    fi
done

# --------------------------------------------------
section "8. SCRIPT SYNTAX"
# --------------------------------------------------

shopt -s nullglob
SCRIPTS=("$ROOT"/scripts/*.sh)

if (( ${#SCRIPTS[@]} == 0 )); then
    warn "No shell scripts found"
else
    for script in "${SCRIPTS[@]}"; do
        if bash -n "$script" 2>/dev/null; then
            pass "Bash syntax: ${script##*/}"
        else
            fail "Bash syntax error: ${script##*/}"
            bash -n "$script"
        fi
    done
fi

# --------------------------------------------------
section "9. PYTHON SYNTAX"
# --------------------------------------------------

for script in theme-gen.py check_health.py; do
    FILE="$ROOT/scripts/$script"

    if [[ -f "$FILE" ]]; then
        if python3 - "$FILE" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY
        then
            pass "Python syntax: $script"
        else
            fail "Python syntax error: $script"
        fi
    else
        warn "Optional Python script missing: $script"
    fi
done

# --------------------------------------------------
section "10. SWAYNC CONFIGURATION"
# --------------------------------------------------

SWAYNC="$ROOT/config/swaync/config.json"

if [[ -f "$SWAYNC" ]]; then
    if python3 - "$SWAYNC" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    config = json.load(f)

widgets = config.get("widgets", [])
widget_config = config.get("widget-config", {})

assert "notifications" in widgets, "notifications widget is missing"
assert isinstance(widget_config.get("notifications"), dict), \
    "notifications widget config is missing"
assert widget_config.get("mpris", {}).get("autohide") is True, \
    "mpris autohide is not enabled"

print("Valid JSON; notification and MPRIS configuration verified")
PY
    then
        pass "SwayNC JSON and widget configuration valid"
    else
        fail "SwayNC JSON or widget configuration invalid"
    fi
else
    fail "SwayNC configuration file missing"
fi

# --------------------------------------------------
section "11. POWER AND BATTERY"
# --------------------------------------------------

if has_command tlp-stat; then
    if systemctl is-enabled --quiet tlp.service &&
       systemctl is-active --quiet tlp.service; then
        pass "TLP enabled and active"
    else
        fail "TLP is not enabled and active"
    fi
else
    fail "tlp-stat command not found"
fi

BATTERY_FOUND=0

for battery in /sys/class/power_supply/BAT*; do
    [[ -d "$battery" ]] || continue
    BATTERY_FOUND=1

    START_FILE="$battery/charge_control_start_threshold"
    STOP_FILE="$battery/charge_control_end_threshold"

    if [[ -r "$START_FILE" && -r "$STOP_FILE" ]]; then
        START="$(cat "$START_FILE")"
        STOP="$(cat "$STOP_FILE")"

        if [[ "$START" == "75" && "$STOP" == "80" ]]; then
            pass "$(basename "$battery") charge threshold is 75/80"
        else
            warn "$(basename "$battery") threshold is $START/$STOP, expected 75/80"
        fi
    else
        warn "Charge threshold interface unavailable: $battery"
    fi
done

if (( BATTERY_FOUND == 0 )); then
    warn "No battery detected"
fi

if systemctl is-active --quiet power-profiles-daemon.service; then
    warn "Power Profiles Daemon đang chạy: xung đột với TLP, nên tắt (sudo systemctl disable --now power-profiles-daemon)"
else
    pass "Power Profiles Daemon is not active"
fi

check_service thermald.service

# --------------------------------------------------
section "12. STARTUP LOG"
# --------------------------------------------------

STARTUP_LOG="$HOME/.cache/cyberdotfiles/startup.log"

if [[ -f "$STARTUP_LOG" ]]; then
    pass "Startup log exists"
    tail -12 "$STARTUP_LOG"
else
    warn "Startup log not found: $STARTUP_LOG"
fi

# --------------------------------------------------
section "13. ROOT STORAGE"
# --------------------------------------------------

df -h /

AVAILABLE_GB="$(df -Pk / | awk 'NR == 2 {printf "%.1f", $4 / 1048576}')"

if awk -v n="$AVAILABLE_GB" 'BEGIN {exit !(n >= 10)}'; then
    pass "Root filesystem has ${AVAILABLE_GB} GiB available"
else
    warn "Root filesystem has only ${AVAILABLE_GB} GiB available"
fi

# --------------------------------------------------
section "14. MANUAL INTERACTION TESTS"
# --------------------------------------------------

manual "Press SUPER + SPACE: Rofi application launcher must open"
manual "Press SUPER + R: resize submap must activate"
manual "Use arrow keys to resize, then ESC to exit the submap"
manual "Press SUPER + F1: keybinding help should open"
manual "Press SUPER + SHIFT + S: screenshot selection should work"
manual "Press SUPER + I: SwayNC notification center should open"
manual "Change wallpaper and verify awww transition"
manual "Test Vietnamese typing with Fcitx5"
manual "After next login, verify Waybar, SwayNC and wallpaper autostart"
manual "Connect AC power and verify charging stops at 80%"

# --------------------------------------------------
section "FINAL SUMMARY"
# --------------------------------------------------

printf 'PASS:   %d\n' "$PASS"
printf 'WARN:   %d\n' "$WARN"
printf 'FAIL:   %d\n' "$FAIL"
printf 'MANUAL: %d\n' "$MANUAL"

printf '\nReport saved to:\n%s\n' "$LOG_FILE"

if (( FAIL > 0 )); then
    printf '\nRESULT: FAILED — investigate FAIL entries before relying on v7.\n'
    exit 1
elif (( WARN > 0 )); then
    printf '\nRESULT: REVIEW — no hard failures, but inspect warnings.\n'
    exit 0
else
    printf '\nRESULT: STATIC/RUNTIME CHECKS PASSED — manual tests remain.\n'
    exit 0
fi
