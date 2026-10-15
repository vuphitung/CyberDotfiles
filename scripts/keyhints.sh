#!/usr/bin/env bash
# keyhints.sh v6 — đọc phím tắt TRỰC TIẾP từ Hyprland (hyprctl binds), không parse file.
# Chỉ hiện bind có mô tả (bindd). Thêm phím mới = viết bindd, không cần sửa script.
command -v jq >/dev/null || { notify-send "keyhints" "Cần cài jq"; exit 1; }

mods() {  # modmask: shift=1 ctrl=4 alt=8 super=64
    local m=$1 o=""
    (( m & 64 )) && o+="Win+"
    (( m & 4  )) && o+="Ctrl+"
    (( m & 8  )) && o+="Alt+"
    (( m & 1  )) && o+="Shift+"
    printf '%s' "$o"
}

hyprctl binds -j \
 | jq -r '.[] | select((.description // "") != "") | "\(.modmask)\t\(.key)\t\(.description)"' \
 | sort -t$'\t' -k3 \
 | while IFS=$'\t' read -r m k d; do
     printf '%-22s ➜  %s\n' "$(mods "$m")${k^}" "$d"
   done \
 | rofi -dmenu -i -p "⌨ Phím tắt" -theme-str 'window {width: 640px;} listview {lines: 14;}' >/dev/null
