#!/usr/bin/env bash
# CYBERDOTFILES v8 — chụp màn hình nhẹ: screenshot.sh {area|screen}
# Khác grimblast: nén PNG mức 1 (mặc định mức 6 ngốn CPU vài giây ở 1440p, làm cả
# compositor đứng hình), chạy nice, và huỷ êm khi bấm Esc.
set -u
DIR="$HOME/Pictures/Screenshots"; mkdir -p "$DIR"
OUT="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"
case "${1:-area}" in
    area)   geo="$(slurp -d)" || exit 0; args=(-g "$geo") ;;
    screen) args=() ;;
    *) echo "Cách dùng: $0 {area|screen}" >&2; exit 2 ;;
esac
nice -n 10 grim -l 1 "${args[@]}" "$OUT" || exit 1
wl-copy --type image/png < "$OUT"
notify-send -u low -t 2000 -i "$OUT" "📸 Đã chụp" "$(basename "$OUT")"
