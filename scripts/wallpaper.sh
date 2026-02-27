#!/bin/bash

# --- 1. Cấu hình đường dẫn linh hoạt ---
WALL_DIR="$HOME/Pictures/Wallpapers"
# Link ảnh "cứu trợ" chất lượng cao (Cyberpunk City)
BACKUP_WALL_URL="https://raw.githubusercontent.com/flandre-scarlet65/wallpapers/main/cyberpunk-city.jpg"

# Tạo thư mục nếu chưa có
mkdir -p "$WALL_DIR"

# --- 2. Kiểm tra và Hỗ trợ tải ảnh ---

# Nếu thư mục rỗng, tự động tải 1 tấm làm vốn
if [ -z "$(ls -A "$WALL_DIR" 2>/dev/null)" ]; then
    echo -e "\033[1;33m⚠️ Thư mục ảnh đang trống. Đang tải hình nền 'cứu trợ'...\033[0m"
    curl -L -o "$WALL_DIR/cyber-default.jpg" "$BACKUP_WALL_URL"
    
    # Hỏi người dùng có muốn tải bộ sưu tập Jakboot (Void-Dots) không
    echo -e "\033[1;34m❓ Ông có muốn tải bộ sưu tập hình nền Jakboot (Void-Dots) không? (y/n)\033[0m"
    read -t 10 -p "> " wp_choice # Tự động bỏ qua sau 10 giây nếu không phản hồi
    if [[ "$wp_choice" == "y" ]]; then
        echo -e "\033[1;33m⏳ Đang tải bộ sưu tập (vui lòng chờ)...\033[0m"
        git clone --depth 1 https://github.com/jak606/Void-Dots-Wallpapers.git "$WALL_DIR/Jakboot"
    fi
fi

# --- 3. Lựa chọn hình nền ---

# Nếu người dùng kéo thả ảnh vào hoặc truyền tham số ($1)
if [ -f "$1" ]; then
    SELECTED_WALL="$1"
else
    # Tìm ngẫu nhiên 1 tấm trong thư mục (bao gồm cả thư mục con)
    SELECTED_WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
fi

# Kiểm tra lại lần cuối xem có tìm được ảnh không
if [ -z "$SELECTED_WALL" ]; then
    echo -e "\033[1;31m❌ Lỗi: Không tìm thấy hình nền nào trong $WALL_DIR\033[0m"
    exit 1
fi

echo -e "\033[1;32m🚀 Đang thiết lập hình nền: $(basename "$SELECTED_WALL")\033[0m"

# --- 4. Thực thi biến hình ---

# Đổi hình nền bằng swww (với hiệu ứng grow)
swww img "$SELECTED_WALL" --transition-type grow --transition-duration 2 --transition-fps 60

# Chạy Pywal để đổi màu hệ thống (chế độ im lặng -q)
wal -i "$SELECTED_WALL" -q

# Reload Waybar để nhận màu mới (Gửi tín hiệu USR2)
pkill -USR2 waybar

echo -e "\033[1;32m✅ Đã đổi hình nền và màu Cyber thành công!\033[0m"
