#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║   CYBERDOTFILES v7 — APP LAUNCHER WITH FALLBACK (scripts/app-launch.sh)
# ╚══════════════════════════════════════════════════════════════════════╝
# Đảm bảo phím tắt mở ứng dụng (File Manager, Browser, Launcher, Terminal)
# luôn hoạt động ngay cả khi ứng dụng ưu tiên chưa được cài đặt.

set -u

ROLE="${1:-}"
shift || true

launch_first_available() {
    local role_name="$1"
    shift
    for candidate in "$@"; do
        local bin="${candidate%% *}"
        if command -v "$bin" >/dev/null 2>&1; then
            exec $candidate
        fi
    done
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "CyberDotfiles v7" "Không tìm thấy ứng dụng cho '$role_name' (đã thử: $*)"
    fi
    exit 1
}

case "$ROLE" in
    file-manager|fm)
        launch_first_available "Quản lý File" \
            "nautilus --new-window" \
            "dolphin" \
            "thunar" \
            "pcmanfm" \
            "nemo" \
            "kitty -e yazi" \
            "kitty -e ranger"
        ;;
    browser|web)
        launch_first_available "Trình duyệt Web" \
            "google-chrome-stable" \
            "google-chrome" \
            "chromium" \
            "brave" \
            "firefox"
        ;;
    launcher|menu)
        launch_first_available "App Launcher" \
            "rofi -show drun" \
            "fuzzel" \
            "wofi --show drun"
        ;;
    terminal|term)
        launch_first_available "Terminal" \
            "kitty" \
            "foot" \
            "alacritty" \
            "wezterm"
        ;;
    *)
        echo "Cách dùng: $0 {file-manager|browser|launcher|terminal}" >&2
        exit 2
        ;;
esac
