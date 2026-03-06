#!/bin/bash
# ============================================================
# wallpaper.sh — CyberTung Wallpaper Manager v2
# Swww + Pywal — không dùng Waybar
# ============================================================

WALL_DIR="$HOME/Pictures/Wallpapers"
BACKUP_WALL_URL="https://raw.githubusercontent.com/flandre-scarlet65/wallpapers/main/cyberpunk-city.jpg"

mkdir -p "$WALL_DIR"

# ── Tải ảnh mặc định nếu thư mục rỗng ────────────────────
if [ -z "$(ls -A "$WALL_DIR" 2>/dev/null)" ]; then
    echo -e "\033[1;33m⚠️  Thư mục ảnh trống, đang tải hình mặc định...\033[0m"
    curl -sL -o "$WALL_DIR/cyber-default.jpg" "$BACKUP_WALL_URL" \
        && echo -e "\033[1;32m✅ Đã tải hình mặc định\033[0m" \
        || echo -e "\033[1;31m❌ Không tải được hình mặc định\033[0m"

    echo -e "\033[1;34m❓ Tải bộ sưu tập wallpaper Jakboot? (y/n, tự bỏ qua sau 10s)\033[0m"
    read -t 10 -p "> " wp_choice
    if [[ "$wp_choice" == "y" ]]; then
        echo -e "\033[1;33m⏳ Đang tải...\033[0m"
        git clone --depth 1 \
            https://github.com/jak606/Void-Dots-Wallpapers.git \
            "$WALL_DIR/Jakboot"
    fi
fi

# ── Chọn ảnh ──────────────────────────────────────────────
if [ -f "$1" ]; then
    SELECTED_WALL="$1"
else
    SELECTED_WALL=$(find "$WALL_DIR" -type f \
        \( -name "*.jpg" -o -name "*.png" \
           -o -name "*.jpeg" -o -name "*.webp" \) \
        | shuf -n 1)
fi

if [ -z "$SELECTED_WALL" ]; then
    echo -e "\033[1;31m❌ Không tìm thấy hình nền trong $WALL_DIR\033[0m"
    exit 1
fi

echo -e "\033[1;32m🚀 Hình nền: $(basename "$SELECTED_WALL")\033[0m"

# ── Đảm bảo swww daemon đang chạy ────────────────────────
pgrep -x swww-daemon &>/dev/null || { swww-daemon & sleep 0.5; }

# ── Set wallpaper ─────────────────────────────────────────
swww img "$SELECTED_WALL" \
    --transition-type grow \
    --transition-duration 2 \
    --transition-fps 60

# ── Pywal — generate color scheme ────────────────────────
if command -v wal &>/dev/null; then
    wal -i "$SELECTED_WALL" -q
    echo -e "\033[1;32m✅ Pywal colors updated\033[0m"
fi

# ── EWW không cần reload khi đổi màu ────────────────────
# (EWW dùng màu cứng trong eww.css, không theo pywal)

echo -e "\033[1;32m✅ Xong!\033[0m"
