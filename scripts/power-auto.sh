#!/usr/bin/env bash
# power-auto.sh — tự đổi power profile theo nguồn điện (chạy nền từ hyprland.conf)
#   cắm sạc  -> performance (i7-6600U lên ~3.1GHz)
#   dùng pin -> balanced    (~2GHz, đỡ hao pin)
# Lý do: profile power-saver/balanced kìm CPU rất mạnh trên máy 2 nhân, làm Chrome lag.
pgrep -fx "bash .*power-auto.sh" | grep -qv "^$$\$" && exit 0   # chỉ chạy 1 bản

apply() {
    local ac want cur
    ac=$(cat /sys/class/power_supply/{AC,ADP}*/online 2>/dev/null | head -1)
    [ "$ac" = "1" ] && want=performance || want=balanced
    cur=$(powerprofilesctl get 2>/dev/null)
    [ "$cur" != "$want" ] && powerprofilesctl set "$want" 2>/dev/null
}

apply
# Nghe sự kiện cắm/rút sạc từ udev
stdbuf -oL udevadm monitor -u -s power_supply 2>/dev/null | while read -r _; do
    sleep 1; apply
done
