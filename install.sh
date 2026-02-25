#!/bin/bash

# --- 1. Cấu hình màu sắc & Biến môi trường ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Tự động lấy đường dẫn tuyệt đối của thư mục hiện tại
DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}🚀 Khởi động hệ thống thiết lập Cyber Dotfiles...${NC}"
echo -e "${YELLOW}📍 Thư mục nguồn: $DOTFILES_DIR${NC}"

# --- 2. Hàm xử lý thông minh (Helper Functions) ---

# Hàm cài đặt gói phần mềm
install_pkg() {
    echo -e "${BLUE}📦 Đang kiểm tra: $1...${NC}"
    
    # 1. Kiểm tra xem app đã có trong máy chưa
    if pacman -Qi "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 đã được cài đặt.${NC}"
    else
        # 2. Nếu chưa có, thử cài bằng pacman
        echo -e "${YELLOW}⏳ Đang cài $1 qua pacman...${NC}"
        if sudo pacman -S --needed --noconfirm "$1" &> /dev/null; then
            echo -e "${GREEN}✅ Cài đặt $1 thành công!${NC}"
        else
            # 3. Nếu pacman thất bại, thử dùng yay (AUR)
            if command -v yay &> /dev/null; then
                echo -e "${YELLOW}🚀 Pacman không thấy, đang thử cài $1 qua YAY (AUR)...${NC}"
                yay -S --noconfirm "$1"
            else
                echo -e "${RED}❌ Lỗi: Không tìm thấy $1 và máy cũng không có YAY để cài từ AUR.${NC}"
            fi
        fi
    fi
}



# Hàm tạo link chuẩn (Chống lỗi lồng folder và tự động backup)
make_link() {
    local source="$1"
    local target="$2"

    if [ -d "$source" ] || [ -f "$source" ]; then
        if [ -e "$target" ]; then
            echo -e "${YELLOW}⚠️  Phát hiện cấu hình cũ tại $target. Đang sao lưu...${NC}"
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
        ln -s "$source" "$target"
        echo -e "${GREEN}✅ Đã kết nối: $target${NC}"
    else
        echo -e "${RED}❌ Lỗi: Không tìm thấy file nguồn tại $source${NC}"
    fi
}

# --- 3. Bắt đầu thực thi ---

# Bước 1: Cài đặt phần mềm
echo -e "\n${BLUE}--- BƯỚC 1: CÀI ĐẶT PHẦN MỀM ---${NC}"
APPS=("hyprland" "waybar" "swww" "python-pywal" "kitty" "rofi" "wlogout")
for app in "${APPS[@]}"; do
    install_pkg "$app"
done

# Bước 2: Nối dây cấu hình (Symlinks)
echo -e "\n${BLUE}--- BƯỚC 2: THIẾT LẬP LIÊN KẾT (SYMLINKS) ---${NC}"
mkdir -p "$HOME/.config"

make_link "$DOTFILES_DIR/config/hypr" "$HOME/.config/hypr"
make_link "$DOTFILES_DIR/config/waybar" "$HOME/.config/waybar"
make_link "$DOTFILES_DIR/config/wlogout" "$HOME/.config/wlogout"

# Bước 3: Cấp quyền thực thi cho các Script
echo -e "\n${BLUE}--- BƯỚC 3: CẤP QUYỀN SỬ DỤNG ---${NC}"
chmod +x "$DOTFILES_DIR/scripts/"*.sh
chmod +x "$DOTFILES_DIR/install.sh"
echo -e "${GREEN}✅ Đã cấp quyền thực thi cho tất cả scripts.${NC}"

# Bước 4: Chạy giao diện lần đầu
echo -e "\n${BLUE}--- BƯỚC 4: KÍCH HOẠT GIAO DIỆN ---${NC}"
if [ -f "$DOTFILES_DIR/scripts/wallpaper.sh" ]; then
    bash "$DOTFILES_DIR/scripts/wallpaper.sh"
else
    echo -e "${RED}❌ Không tìm thấy script wallpaper.sh để chạy!${NC}"
fi

echo -e "\n${GREEN}🔥 HOÀN TẤT! Hệ thống của ông đã sẵn sàng để quẩy.${NC}"
if [ -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}📂 Lưu ý: Các cấu hình cũ đã được cất an toàn tại: $BACKUP_DIR${NC}"
fi
