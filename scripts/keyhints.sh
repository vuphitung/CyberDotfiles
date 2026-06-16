#!/bin/bash
# keyhints.sh — Hiển thị phím tắt qua Rofi
get_desc() {
    case "$1" in
        *kitty*)          echo "Mở Terminal" ;;
        *nautilus*)       echo "Quản lý File" ;;
        *rofi*)           echo "Tìm kiếm App" ;;
        *chrome*|*firefox*) echo "Trình duyệt" ;;
        *killactive*)     echo "Đóng cửa sổ" ;;
        *exit*)           echo "Đăng xuất" ;;
        *togglefloating*) echo "Cửa sổ nổi" ;;
        *fullscreen*)     echo "Toàn màn hình" ;;
        *grimblast*)      echo "Chụp màn hình" ;;
        *wlogout*)        echo "Menu nguồn" ;;
        *wallpaper*|*wall-picker*) echo "Đổi hình nền" ;;
        *movefocus*)      echo "Chuyển focus" ;;
        *swaync*)         echo "Thông báo" ;;
        *hyprlock*)       echo "Khóa màn hình" ;;
        *keyhints*)       echo "Xem phím tắt" ;;
        *)                echo "Lệnh hệ thống" ;;
    esac
}

tmp=$(mktemp)
grep -E '^bind[a-z]* *=' ~/.config/hypr/hyprland.conf 2>/dev/null | while read -r line; do
    content=$(echo "$line" | sed -E 's/^bind[a-z]* *= *//')
    mod=$(echo "$content" | cut -d',' -f1 | sed 's/\$mainMod/Win/g; s/SHIFT/Shift/g; s/CTRL/Ctrl/g; s/ //g')
    key=$(echo "$content" | cut -d',' -f2 | sed 's/ //g')
    cmd=$(echo "$content" | cut -d',' -f3-)
    [[ -z "$key" ]] && continue
    if [[ "$key" =~ ^[1-9]$ ]]; then
        [[ "$cmd" == *"movetoworkspace"* ]] && echo "Win+Shift+[1-9]  ➜  Di chuyển App sang Workspace" >> "$tmp"
        [[ "$cmd" == *"workspace"* && "$cmd" != *"movetoworkspace"* ]] && echo "Win+[1-9]  ➜  Chuyển Workspace" >> "$tmp"
        continue
    fi
    echo "$mod+$key  ➜  $(get_desc "$cmd")" >> "$tmp"
done

sort -u "$tmp" | rofi -dmenu -i -p "  Phím tắt" \
    -theme-str '
    window { width: 620px; border-radius: 12px; border: 1px; border-color: rgba(0,229,255,0.4); background-color: rgba(2,8,18,0.97); }
    inputbar { padding: 14px; background-color: rgba(0,229,255,0.06); border-radius: 12px 12px 0 0; }
    prompt { text-color: #00e5ff; font: "JetBrainsMono Nerd Font Bold 11"; margin: 0 10px 0 0; }
    entry { text-color: rgba(255,255,255,0.7); placeholder: "Tìm..."; placeholder-color: rgba(255,255,255,0.2); }
    listview { columns: 1; lines: 14; padding: 8px; spacing: 3px; }
    element { border-radius: 6px; padding: 7px 12px; }
    element selected { background-color: rgba(0,229,255,0.15); border: 1px; border-color: rgba(0,229,255,0.4); }
    element-text { text-color: rgba(255,255,255,0.6); font: "JetBrainsMono Nerd Font 10"; }
    element-text selected { text-color: #00e5ff; }
    '
rm -f "$tmp"
