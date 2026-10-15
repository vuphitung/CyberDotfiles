#!/usr/bin/env bash
# wallpaper.sh v6 — đặt hình nền + sinh màu pywal + reload kitty
# Dùng:  wallpaper.sh [file]   (không tham số: ảnh lần trước, hoặc ngẫu nhiên)
WALL_DIR="${CYBER_WALL_DIR:-$HOME/Pictures/Wallpapers}"
LAST="$HOME/.cache/wal/.last_wall"

# swww đã đổi tên thành awww — ưu tiên tên mới, fallback tên cũ
if command -v awww >/dev/null; then WW=awww; WWD=awww-daemon
elif command -v swww >/dev/null; then WW=swww; WWD=swww-daemon
else notify-send -u critical "wallpaper" "Thiếu awww/swww"; exit 1; fi

# Chờ daemon sẵn sàng (thay cho `sleep 3` cố định); tự bật nếu chưa chạy
if ! "$WW" query >/dev/null 2>&1; then
    pgrep -x "$WWD" >/dev/null || setsid "$WWD" >/dev/null 2>&1 &
    for _ in $(seq 1 50); do "$WW" query >/dev/null 2>&1 && break; sleep 0.1; done
fi
"$WW" query >/dev/null 2>&1 || { notify-send -u critical "wallpaper" "$WWD không phản hồi"; exit 1; }

# Chọn ảnh
WALL="${1:-}"
[ -z "$WALL" ] && [ -f "$LAST" ] && WALL=$(cat "$LAST")
if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    WALL=$(find "$WALL_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | shuf -n1)
fi
[ -f "$WALL" ] || { notify-send -u critical "wallpaper" "Không tìm thấy ảnh trong $WALL_DIR"; exit 1; }

"$WW" img "$WALL" --transition-type wave --transition-duration 1 --transition-fps 60
mkdir -p "$(dirname "$LAST")"
printf '%s\n' "$WALL" > "$LAST"

# Sinh màu — nếu pywal lỗi thì vẫn giữ wallpaper, chỉ báo cảnh báo
if command -v wal >/dev/null; then
    wal -i "$WALL" -n -q || notify-send -u low "wallpaper" "pywal lỗi (xem: coredumpctl)"
    pids=$(pgrep -x kitty) && kill -SIGUSR1 $pids
fi

notify-send -u low -t 2000 "🎨 Wallpaper" "$(basename "$WALL")"
