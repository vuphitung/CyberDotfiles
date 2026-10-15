#!/usr/bin/env bash
# perf-mode.sh — bật/tắt chế độ tiết kiệm (tắt animation/blur/shadow) cho HD 520.
cur=$(hyprctl getoption animations:enabled -j | jq -r '.int')
if [ "$cur" = "1" ]; then
    hyprctl --batch "keyword animations:enabled 0 ; keyword decoration:blur:enabled 0 ; keyword decoration:shadow:enabled 0" >/dev/null
    notify-send -u low "⚡ Chế độ tiết kiệm" "Đã tắt animation, blur, shadow"
else
    hyprctl reload >/dev/null
    notify-send -u low "✨ Chế độ đầy đủ" "Đã bật lại hiệu ứng"
fi
