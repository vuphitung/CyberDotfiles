#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║   CYBERDOTFILES v7 — WALLPAPER & PYWAL MANAGER (scripts/wallpaper.sh)║
# ╚══════════════════════════════════════════════════════════════════════╝
# Dùng: wallpaper.sh [đường_dẫn_ảnh]
# Không tham số: khôi phục ảnh gần nhất từ ~/.cache/wal/.last_wall hoặc chọn ngẫu nhiên.

set -u

WALL_DIR="${CYBER_WALL_DIR:-$HOME/Pictures/Wallpapers}"
LAST="$HOME/.cache/wal/.last_wall"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/cyber_wallpaper.lock"

# Ngăn nhiều tiến trình wallpaper.sh chạy đè nhau
exec 8>"$LOCK_FILE"
flock -w 5 8 || exit 0

notify_err() {
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wallpaper" "$*"
    printf '❌ [wallpaper.sh] %s\n' "$*" >&2
}

# 1. Xác định binary awww / swww
if command -v awww >/dev/null 2>&1; then
    WW="awww"
    WWD="awww-daemon"
elif command -v swww >/dev/null 2>&1; then
    WW="swww"
    WWD="swww-daemon"
else
    notify_err "Thiếu gói awww/swww. Hãy cài đặt awww."
    exit 1
fi

# 2. Đảm bảo duy nhất một daemon chạy và sẵn sàng nhận IPC
if ! "$WW" query >/dev/null 2>&1; then
    # Dọn dẹp nếu có nhiều hơn 1 tiến trình daemon bị treo
    daemon_count=$(pgrep -xc "$WWD" 2>/dev/null || true)
    daemon_count=${daemon_count:-0}
    if [ "$daemon_count" -gt 1 ]; then
        pkill -x "$WWD" 2>/dev/null || true
    fi
    if ! pgrep -x "$WWD" >/dev/null 2>&1; then
        setsid "$WWD" 8>&- >/dev/null 2>&1 < /dev/null &
    fi
    # Chờ socket IPC sẵn sàng (tối đa 5 giây, kiểm tra mỗi 100ms)
    for _ in $(seq 1 50); do
        "$WW" query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

if ! "$WW" query >/dev/null 2>&1; then
    notify_err "Daemon $WWD không phản hồi qua Wayland socket."
    exit 1
fi

# 3. Chọn file hình nền hợp lệ
WALL="${1:-}"
if [ -z "$WALL" ] && [ -f "$LAST" ]; then
    CANDIDATE="$(head -n 1 "$LAST" 2>/dev/null || true)"
    [ -f "$CANDIDATE" ] && WALL="$CANDIDATE"
fi

if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    WALL="$(find "$WALL_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | shuf -n 1)"
fi

if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    notify_err "Không tìm thấy ảnh hợp lệ trong $WALL_DIR"
    exit 1
fi

# 4. Áp dụng hình nền với hiệu ứng chuyển mượt (nhẹ: fade 30fps)
if ! "$WW" img "$WALL" --transition-type fade --transition-duration 0.5 --transition-fps 30; then
    notify_err "Không thể tải ảnh: $WALL"
    exit 1
fi

# 5. Lưu trạng thái hình nền gần nhất (bảo toàn ~/.cache/wal/.last_wall)
mkdir -p "$(dirname "$LAST")"
printf '%s\n' "$WALL" > "$LAST"

# 6. Sinh bảng màu ANSI 16 màu bằng pywal cho Kitty (không ghi đè nền Sakura Glass)
if command -v wal >/dev/null 2>&1; then
    if wal -i "$WALL" -n -q >/dev/null 2>&1; then
        pids="$(pgrep -x kitty 2>/dev/null || true)"
        [ -n "$pids" ] && kill -SIGUSR1 $pids 2>/dev/null || true
    else
        command -v notify-send >/dev/null 2>&1 && notify-send -u low "Wallpaper" "Pywal không thể trích xuất màu từ ảnh này; giữ nguyên bảng màu cũ."
    fi
fi

command -v notify-send >/dev/null 2>&1 && notify-send -u low -t 2000 "🎨 Wallpaper" "$(basename "$WALL")"
exit 0
