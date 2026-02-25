#!/bin/bash

# Đường dẫn folder ảnh 
WALLPAPER_DIR="/home/tung/Pictures/Wallpapers/wallpapers"

if [ -z "$1" ]; then
    SELECTED_WALL=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)
else
    SELECTED_WALL="$1"
fi

echo "🚀 Đang thiết lập hình nền: $SELECTED_WALL"

# Đổi hình nền bằng swww
swww img "$SELECTED_WALL" --transition-type grow --transition-duration 2

# Chạy Pywal để đổi màu hệ thống
wal -i "$SELECTED_WALL"

# Reload Waybar để nhận màu mới
pkill -USR2 waybar

echo "✅ Đã đổi hình nền và màu Cyber!"
