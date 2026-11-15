#!/usr/bin/env bash
# CYBERDOTFILES v9 — chế độ hiệu ứng theo pin (CPU/nguồn do TLP lo, xem system/tlp/)
#   power-auto.sh           daemon: nghe udev, tự đổi hiệu ứng khi rút/cắm sạc hoặc pin đổi mức
#   power-auto.sh apply     áp dụng ngay một lần
#   power-auto.sh toggle    ép bật/tắt chế độ lite bằng tay (Super+Shift+B)
# Dùng pin <= 30% -> lite (tắt blur/shadow/animation); thoát lite khi pin >= 35% hoặc cắm sạc.
set -u
LOW=30; BACK=35
RT="${XDG_RUNTIME_DIR:-/tmp}"; MODE="$RT/cyber-mode"; FORCE="$RT/cyber-force-lite"

apply() {
    local st=Unknown cap=100 cur mode=full b
    for b in /sys/class/power_supply/BAT*; do
        [ -r "$b/capacity" ] && { st="$(<"$b/status")"; cap="$(<"$b/capacity")"; break; }
    done
    cur="$(cat "$MODE" 2>/dev/null || echo full)"
    if [ "$st" = Discharging ]; then
        if [ "$cap" -le "$LOW" ] || { [ "$cur" = lite ] && [ "$cap" -lt "$BACK" ]; }; then mode=lite; fi
    fi
    [ -e "$FORCE" ] && mode=lite
    [ "$mode" = "$cur" ] && return 0
    echo "$mode" > "$MODE"
    hyprctl reload >/dev/null 2>&1          # Lua đọc $MODE khi nạp lại
    command -v notify-send >/dev/null && notify-send -u low -t 2500 "Chế độ $mode" "Pin ${cap}% · $st"
}

case "${1:-daemon}" in
    apply)  apply ;;
    toggle) if [ -e "$FORCE" ]; then rm -f "$FORCE"; else touch "$FORCE"; fi; apply ;;
    daemon)
        exec 7>"$RT/cyber_power_auto.lock"; flock -n 7 || exit 0
        apply
        while true; do      # sự kiện udev, dự phòng 60s; không polling nặng
            read -r -t 60 _ <&3; [ $? -eq 1 ] && sleep 60
            sleep 1; apply
        done 3< <(stdbuf -oL udevadm monitor -u -s power_supply 2>/dev/null 7>&-)   # 7>&-: con không giữ khoá
        ;;
esac
