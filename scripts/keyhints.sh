#!/bin/bash
# ============================================================
# keyhints.sh — CyberTung Keybind Hints v2
# Hiển thị phím tắt Hyprland qua Rofi
# ============================================================

get_desc() {
    case "$1" in
        *kitty*)          echo "Mở Terminal" ;;
        *dolphin*)        echo "Quản lý Tệp tin" ;;
        *nautilus*)       echo "Quản lý Tệp tin" ;;
        *rofi*)           echo "Tìm kiếm App" ;;
        *chrome*|*thorium*|*firefox*) echo "Trình duyệt Web" ;;
        *killactive*)     echo "Đóng cửa sổ" ;;
        *exit*)           echo "Đăng xuất" ;;
        *togglefloating*) echo "Cửa sổ nổi" ;;
        *fullscreen*)     echo "Toàn màn hình" ;;
        *grimblast*)      echo "Chụp màn hình" ;;
        *wlogout*)        echo "Menu nguồn" ;;
        *toggle-bar*|*eww*bar*) echo "Ẩn/Hiện Bar" ;;
        *wallpaper*)      echo "Đổi hình nền" ;;
        *movefocus*)      echo "Chuyển focus" ;;
        *movewindow*)     echo "Di chuyển cửa sổ" ;;
        *resizewindow*)   echo "Resize cửa sổ" ;;
        *swapwindow*)     echo "Hoán đổi cửa sổ" ;;
        *togglegroup*)    echo "Toggle group" ;;
        *spotify*)        echo "Spotify" ;;
        *keyhints*)       echo "Xem phím tắt" ;;
        *)                echo "Lệnh hệ thống" ;;
    esac
}

tmp_file=$(mktemp)

grep -E '^bind[a-z]* *=' ~/.config/hypr/hyprland.conf 2>/dev/null \
| while read -r line; do
    content=$(echo "$line" | sed -E 's/^bind[a-z]* *= *//')
    mod=$(echo "$content" | cut -d',' -f1 \
        | sed 's/\$mainMod/Win/g; s/SHIFT/Shift/g; s/CTRL/Ctrl/g; s/ //g')
    key=$(echo "$content" | cut -d',' -f2 | sed 's/ //g')
    cmd=$(echo "$content" | cut -d',' -f3-)

    [[ -z "$key" ]] && continue

    # Gom workspace keys
    if [[ "$key" =~ ^[1-9]$ ]]; then
        if [[ "$cmd" == *"movetoworkspace"* ]]; then
            echo "Win+Shift+[1-9]  ➜  Di chuyển App sang WS" >> "$tmp_file"
        elif [[ "$cmd" == *"workspace"* ]]; then
            echo "Win+[1-9]        ➜  Chuyển Workspace" >> "$tmp_file"
        fi
        continue
    fi

    desc=$(get_desc "$cmd")
    echo "$mod+$key  ➜  $desc" >> "$tmp_file"
done

final_list=$(sort -u "$tmp_file")
rm -f "$tmp_file"

echo -e "$final_list" | rofi -dmenu \
    -i \
    -p "  Hyprland Keys" \
    -theme-str '
    window {
        width: 620px;
        border-radius: 12px;
        border: 1px;
        border-color: rgba(0,230,255,0.4);
        background-color: rgba(1,6,12,0.97);
    }
    mainbox { children: [ "inputbar", "listview" ]; }
    inputbar {
        padding: 14px;
        background-color: rgba(0,230,255,0.06);
        border-radius: 12px 12px 0 0;
        children: [ "prompt", "entry" ];
    }
    prompt {
        text-color: #00e6ff;
        font: "JetBrainsMono Nerd Font Bold 11";
        margin: 0 10px 0 0;
    }
    entry {
        text-color: rgba(255,255,255,0.7);
        placeholder: "Tìm phím tắt...";
        placeholder-color: rgba(255,255,255,0.2);
    }
    listview {
        columns: 1;
        lines: 14;
        padding: 8px;
        spacing: 3px;
        fixed-height: false;
    }
    element { border-radius: 6px; padding: 7px 12px; }
    element selected {
        background-color: rgba(0,230,255,0.15);
        border: 1px;
        border-color: rgba(0,230,255,0.4);
    }
    element-text {
        text-color: rgba(255,255,255,0.6);
        font: "JetBrainsMono Nerd Font 10";
    }
    element-text selected { text-color: #00e6ff; }
    '
