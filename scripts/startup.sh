#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║   CYBERDOTFILES v7 — SESSION STARTUP ORCHESTRATOR (scripts/startup.sh)
# ╚══════════════════════════════════════════════════════════════════════╝
# Được kích hoạt bởi `hl.on("hyprland.start", ...)` trong `modules/autostart.lua`.
# Nguyên tắc:
#   1. Khởi động đúng thứ tự phụ thuộc (D-Bus env -> Polkit -> Wallpaper -> Bar/Notif -> Input/Idle/Power).
#   2. Chống chạy trùng tuyệt đối (kiểm tra pgrep / flock trước khi khởi chạy).
#   3. Không dùng sleep tùy tiện; cô lập lỗi từng thành phần.
#   4. Ghi log chẩn đoán vào ~/.cache/cyberdotfiles/startup.log.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.cache/cyberdotfiles"
LOG_FILE="$LOG_DIR/startup.log"
LOCK_FILE="$LOG_DIR/startup.lock"

mkdir -p "$LOG_DIR" "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers"

# Ngăn 2 tiến trình startup.sh chạy chồng lên nhau cùng lúc
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

log_msg() {
    printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

spawn_once() {
    local proc_match="$1"
    shift
    local bin="$1"
    if ! command -v "$bin" >/dev/null 2>&1; then
        log_msg "SKIP: '$bin' chưa được cài đặt."
        return 0
    fi
    if pgrep -x "$proc_match" >/dev/null 2>&1; then
        log_msg "OK: '$proc_match' đã chạy sẵn (PID: $(pgrep -x "$proc_match" | tr '\n' ' '))."
        return 0
    fi
    log_msg "START: $*"
    setsid "$@" 9>&- >>"$LOG_FILE" 2>&1 < /dev/null &
}

log_msg "================ BẮT ĐẦU KHỞI ĐỘNG PHIÊN HYPRLAND v7 ================"

# ── PHA 1: ĐỒNG BỘ BIẾN MÔI TRƯỜNG D-BUS & SYSTEMD ─────────────────────────
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE \
        XDG_SESSION_DESKTOP \
        HYPRLAND_INSTANCE_SIGNATURE \
        XCURSOR_THEME \
        XCURSOR_SIZE \
        HYPRCURSOR_THEME \
        HYPRCURSOR_SIZE \
        XMODIFIERS \
        QT_IM_MODULE \
        GTK_IM_MODULE \
        SDL_IM_MODULE >>"$LOG_FILE" 2>&1 || true
    log_msg "OK: Đã đồng bộ biến môi trường D-Bus / systemd."
fi

# ── PHA 2: POLKIT AUTHENTICATION AGENT ─────────────────────────────────────
if systemctl --user list-unit-files hyprpolkitagent.service >/dev/null 2>&1; then
    systemctl --user start hyprpolkitagent.service >>"$LOG_FILE" 2>&1 \
        && log_msg "OK: Đã kích hoạt systemd user service hyprpolkitagent." \
        || log_msg "WARN: Không thể khởi động hyprpolkitagent.service."
elif [ -x /usr/lib/hyprpolkitagent/hyprpolkitagent ]; then
    spawn_once "hyprpolkitagent" /usr/lib/hyprpolkitagent/hyprpolkitagent
elif command -v hyprpolkitagent >/dev/null 2>&1; then
    spawn_once "hyprpolkitagent" hyprpolkitagent
fi

# ── PHA 3: TRUNG TÂM THÔNG BÁO (SWAYNC) & THANH TRẠNG THÁI (WAYBAR) ────────
# Khởi động SwayNC trước Waybar để module `custom/notification` (`swaync-client -swb`) kết nối ngay
spawn_once "swaync" swaync
spawn_once "waybar" waybar

# ── PHA 4: HÌNH NỀN (AWWW-DAEMON & WALLPAPER.SH) ───────────────────────────
if [ -x "$SCRIPT_DIR/wallpaper.sh" ]; then
    log_msg "START: $SCRIPT_DIR/wallpaper.sh"
    bash "$SCRIPT_DIR/wallpaper.sh" 9>&- >>"$LOG_FILE" 2>&1 &
fi

# ── PHA 5: BỘ GÕ TIẾNG VIỆT (FCITX5), IDLE DAEMON & CLIPBOARD ──────────────
if command -v fcitx5 >/dev/null 2>&1; then
    if ! pgrep -x "fcitx5" >/dev/null 2>&1; then
        log_msg "START: fcitx5 -d"
        fcitx5 -d 9>&- >>"$LOG_FILE" 2>&1 &
    else
        log_msg "OK: fcitx5 đã chạy sẵn."
    fi
fi

spawn_once "hypridle" hypridle

if command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1; then
    if ! pgrep -f "wl-paste.*cliphist store" >/dev/null 2>&1; then
        log_msg "START: wl-paste --type text/image --watch cliphist store"
        setsid wl-paste --type text --watch cliphist store 9>&- >>"$LOG_FILE" 2>&1 < /dev/null &
        setsid wl-paste --type image --watch cliphist store 9>&- >>"$LOG_FILE" 2>&1 < /dev/null &
    else
        log_msg "OK: wl-paste cliphist watcher đã chạy sẵn."
    fi
fi

# ── PHA 6: QUẢN LÝ NĂNG LƯỢNG TỰ ĐỘNG (POWER-AUTO.SH) ──────────────────────
if [ -x "$SCRIPT_DIR/power-auto.sh" ]; then
    if ! pgrep -f "power-auto.sh" >/dev/null 2>&1; then
        log_msg "START: $SCRIPT_DIR/power-auto.sh"
        setsid bash "$SCRIPT_DIR/power-auto.sh" 9>&- >>"$LOG_FILE" 2>&1 < /dev/null &
    else
        log_msg "OK: power-auto.sh đã chạy sẵn."
    fi
fi

log_msg "================ HOÀN TẤT KHỞI ĐỘNG PHIÊN HYPRLAND v7 ================"
