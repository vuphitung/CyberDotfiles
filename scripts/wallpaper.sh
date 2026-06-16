#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║           CYBERTUNG — WALLPAPER + PYWAL v5              ║
# ║           Auto reload colors cho kitty, rofi, terminal  ║
# ╚══════════════════════════════════════════════════════════╝

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/wallpapers"
LAST_WALL="$HOME/.cache/wal/.last_wall"

# Dùng wall truyền vào hoặc lấy wall cuối
if [[ -n "$1" ]]; then
    WALL="$1"
elif [[ -f "$LAST_WALL" ]]; then
    WALL=$(cat "$LAST_WALL")
else
    WALL=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | shuf -n 1)
fi

[[ -z "$WALL" ]] && { echo "❌ Không tìm thấy wallpaper"; exit 1; }

echo "🖼  Đặt wallpaper: $(basename "$WALL")"

# ── 1. SET WALLPAPER ─────────────────────────────────────────
swww img "$WALL" \
    --transition-type wave \
    --transition-angle 30 \
    --transition-duration 1.2 \
    --transition-fps 60

# ── 2. PYWAL GENERATE COLORS ─────────────────────────────────
wal -i "$WALL" -n -q --backend haishoku 2>/dev/null \
    || wal -i "$WALL" -n -q

# ── 3. RELOAD KITTY ──────────────────────────────────────────
# Gửi signal cho tất cả kitty đang chạy
if pgrep -x kitty > /dev/null; then
    kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null
    echo "  ✅ Kitty colors reloaded"
fi

# ── 4. RELOAD WAYBAR / SWAYNC ────────────────────────────────
if pgrep -x waybar > /dev/null; then
    pkill -SIGUSR2 waybar 2>/dev/null
fi

# ── 5. XDG_COLORS (GTK apps) ─────────────────────────────────
# Uncomment nếu dùng gtk theme với pywal
# wal-gtk 2>/dev/null

# ── 6. LƯU WALL CUỐI ─────────────────────────────────────────
echo "$WALL" > "$LAST_WALL"

echo "  ✅ Wallpaper + colors đã cập nhật!"
notify-send "🎨 Wallpaper" "$(basename "$WALL")" \
    --icon="$WALL" \
    --urgency=low 2>/dev/null
