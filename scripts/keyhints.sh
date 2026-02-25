#!/bin/bash

# --- HÀM DỊCH CHÚ THÍCH ---
get_desc() {
    case "$1" in
        *kitty*) echo "Mở Terminal" ;;
        *dolphin*) echo "Quản lý Tệp tin" ;;
        *rofi*) echo "Tìm kiếm ứng dụng" ;;
        *chrome*) echo "Trình duyệt Web" ;;
        *killactive*) echo "Đóng ứng dụng" ;;
        *exit*) echo "Đăng xuất" ;;
        *togglefloating*) echo "Cửa sổ nổi" ;;
        *fullscreen*) echo "Toàn màn hình" ;;
        *grimblast*) echo "Chụp ảnh màn hình" ;;
        *wlogout*) echo "Menu Nguồn" ;;
        *waybar*) echo "Ẩn/Hiện Waybar" ;;
        *wallpaper*) echo "Đổi hình nền" ;;
        *movefocus*) echo "Chuyển cửa sổ" ;;
        *) echo "Lệnh hệ thống" ;; 
    esac
}

# --- XỬ LÝ DỮ LIỆU ---
# Tạo một file tạm để chứa danh sách (đảm bảo không bị lag biến)
tmp_file=$(mktemp)

grep -E '^bind[a-z]* *=' ~/.config/hypr/hyprland.conf | while read -r line; do
    # Tách dữ liệu
    content=$(echo "$line" | sed -E 's/^bind[a-z]* *= *//')
    mod=$(echo "$content" | cut -d',' -f1 | sed 's/\$mainMod/Win/g; s/SHIFT/Shift/g; s/ //g')
    key=$(echo "$content" | cut -d',' -f2 | sed 's/ //g')
    cmd=$(echo "$content" | cut -d',' -f3-)

    [[ -z "$key" ]] && continue

    # Gom nhóm Workspace
    if [[ "$key" =~ ^[1-6]$ ]]; then
        if [[ "$cmd" == *"movetoworkspace"* ]]; then
            echo "Win+Shift+[1-6]  ➜   Di chuyển App" >> "$tmp_file"
        elif [[ "$cmd" == *"workspace"* ]]; then
            echo "Win + [1-6]      ➜   Chuyển Workspace" >> "$tmp_file"
        fi
        continue
    fi

    # Thêm các phím khác vào file tạm
    desc=$(get_desc "$cmd")
    echo "$mod+$key  ➜   $desc" >> "$tmp_file"
done

# Lọc trùng (cho Workspace) và hiển thị
final_list=$(sort -u "$tmp_file")
rm "$tmp_file"

# --- HIỂN THỊ ROFI ---
echo -e "$final_list" | rofi -dmenu \
    -i \
    -p " Hyprland" \
    -theme-str '
    window { width: 600px; border-radius: 15px; border: 1px; border-color: #d1d1d1; background-color: rgba(252,252,252,0.98); }
    mainbox { children: [ "inputbar", "listview" ]; }
    inputbar { padding: 15px; background-color: #f0f0f2; border-radius: 15px 15px 0 0; children: [ "prompt", "entry" ]; }
    prompt { text-color: #007aff; font: "JetBrainsMono Nerd Font Bold 12"; margin: 0 10px 0 0; }
    entry { text-color: #1d1d1f; placeholder: "Tìm phím tắt..."; }
    listview { columns: 1; lines: 12; padding: 10px; spacing: 4px; fixed-height: false; }
    element { border-radius: 8px; padding: 8px 12px; }
    element selected { background-color: #007aff; }
    element-text { text-color: #424245; font: "JetBrainsMono Nerd Font 10.5"; }
    element-text selected { text-color: #ffffff; }
    '
