#!/bin/bash
# ============================================================
# apps.sh — CyberTung Smart Launcher v2.0
# Arch Linux + Hyprland
#
# Tất cả app đều đi qua smartd.sh để được throttle tự động
# Thêm app mới: chỉ cần thêm 1 dòng case, không sửa gì khác
#
# Dùng:
#   apps.sh browser    ← mở Thorium
#   apps.sh discord    ← mở Vesktop
#   apps.sh spotify    ← mở Spotify
#   apps.sh term       ← mở Kitty
#   apps.sh files      ← mở Thunar
#   apps.sh code       ← mở VS Code
#   apps.sh purge      ← dọn rác khẩn cấp
#   apps.sh status     ← xem trạng thái
# ============================================================

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
SMARTD="$SCRIPTS/smartd.sh"

# Hàm wrapper — mọi app Electron đều đi qua đây
launch() {
    "$SMARTD" launch "$@"
}

# ──────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────
case "$1" in

    # ── BROWSERS ──────────────────────────────────────────
    browser|thorium)
        launch thorium-browser \
            --ozone-platform=wayland \
            --enable-features=UseOzonePlatform \
            --process-per-site \
            --disable-background-networking=false
        ;;

    chrome)
        launch google-chrome-stable \
            --ozone-platform=wayland \
            --enable-features=UseOzonePlatform
        ;;

    firefox)
        launch firefox \
            --MOZ_ENABLE_WAYLAND=1
        ;;

    # ── COMMUNICATION ─────────────────────────────────────
    discord|vesktop)
        launch vesktop \
            --ozone-platform=wayland \
            --disable-gpu \
            --disable-dev-shm-usage \
            --no-sandbox
        ;;

    telegram)
        launch telegram-desktop \
            -workdir ~/.local/share/TelegramDesktop/
        ;;

    signal)
        launch signal-desktop \
            --ozone-platform=wayland
        ;;

    # ── MEDIA ─────────────────────────────────────────────
    spotify|music)
        launch spotify \
            --ozone-platform=wayland \
            --no-zygote \
            --disable-gpu
        ;;

    # ── DEV TOOLS ─────────────────────────────────────────
    code|vscode)
        launch code \
            --ozone-platform=wayland \
            --enable-features=UseOzonePlatform
        ;;

    obsidian|notes)
        launch obsidian \
            --ozone-platform=wayland
        ;;

    # ── TERMINAL & FILES ──────────────────────────────────
    term|terminal)
        kitty &
        ;;

    files|file-manager)
        thunar &
        ;;

    # ── SYSTEM TOOLS ──────────────────────────────────────
    purge)
        "$SCRIPTS/purge.sh"
        ;;

    status)
        "$SMARTD" status
        ;;

    log)
        "$SMARTD" log
        ;;

    # ── GENERIC — launch bất kỳ app nào qua smartd ────────
    # Dùng: apps.sh run <tên_app> [args...]
    # Ví dụ: apps.sh run figma-linux --disable-gpu
    run)
        shift
        launch "$@"
        ;;

    # ──────────────────────────────────────────────────────
    # THÊM APP MỚI Ở ĐÂY — chỉ cần 1 dòng
    # Template:
    #   myapp) launch myapp [--flags] ;;
    #
    # Ví dụ:
    #   zoom)       launch zoom ;;
    #   figma)      launch figma-linux --disable-gpu ;;
    #   postman)    launch postman ;;
    #   notion)     launch notion-app --ozone-platform=wayland ;;
    # ──────────────────────────────────────────────────────

    *)
        echo ""
        echo "CyberTung apps.sh v2.0"
        echo ""
        echo "Dùng:"
        echo "  apps.sh browser    ← Thorium (có throttle)"
        echo "  apps.sh discord    ← Vesktop (có throttle)"
        echo "  apps.sh spotify    ← Spotify (có throttle)"
        echo "  apps.sh code       ← VS Code (có throttle)"
        echo "  apps.sh obsidian   ← Obsidian (có throttle)"
        echo "  apps.sh telegram   ← Telegram"
        echo "  apps.sh term       ← Kitty terminal"
        echo "  apps.sh files      ← Thunar"
        echo "  apps.sh purge      ← Dọn rác khẩn cấp"
        echo "  apps.sh status     ← Xem trạng thái"
        echo "  apps.sh log        ← Xem log realtime"
        echo "  apps.sh run <app>  ← Launch bất kỳ app qua smartd"
        echo ""
        ;;
esac
