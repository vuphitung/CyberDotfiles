#!/bin/bash

# --- 1. Cấu hình màu sắc & Biến môi trường ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' 

# Lấy đường dẫn tuyệt đối của thư mục Dotfiles
DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${PURPLE}🚀 [CYBER-DOTFILES] BẮT ĐẦU QUÁ TRÌNH THIẾT LẬP TỔNG LỰC...${NC}"
echo -e "${BLUE}📍 Nguồn: $DOTFILES_DIR${NC}"

# --- 2. Hàm xử lý thông minh ---

# Cài đặt gói (Hỗ trợ Pacman & Yay)
install_pkg() {
    if pacman -Qi "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 đã có trên hệ thống.${NC}"
    else
        echo -e "${YELLOW}⏳ Đang cài $1...${NC}"
        sudo pacman -S --needed --noconfirm "$1" &> /dev/null || (command -v yay &> /dev/null && yay -S --noconfirm "$1")
    fi
}

# Tạo Symlink chuẩn (Có Backup file thật, ghi đè link cũ)
make_link() {
    local source="$1"
    local target="$2"
    if [ -d "$source" ] || [ -f "$source" ]; then
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo -e "${YELLOW}⚠️  Sao lưu cấu hình cũ: $target${NC}"
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
        ln -sf "$source" "$target"
        echo -e "${GREEN}✅ Đã kết nối: $target${NC}"
    else
        echo -e "${RED}❌ Lỗi: Không tìm thấy $source${NC}"
    fi
}

# --- 3. Thực thi các bước ---

# BƯỚC 1: Cài đặt Apps & Drivers
echo -e "\n${BLUE}--- BƯỚC 1: CÀI ĐẶT PHẦN MỀM THIẾT YẾU ---${NC}"
APPS=("hyprland" "waybar" "swww" "python-pywal" "kitty" "rofi" "wlogout" "intel-gpu-tools" "libnotify")
for app in "${APPS[@]}"; do
    install_pkg "$app"
done

# BƯỚC 2: Cấp quyền và Quét tối ưu hệ thống
echo -e "\n${BLUE}--- BƯỚC 2: QUÉT XUNG ĐỘT & TỐI ƯU DRIVER ---${NC}"
chmod +x "$DOTFILES_DIR/scripts/"*.sh
if [ -f "$DOTFILES_DIR/scripts/setup_all.sh" ]; then
    bash "$DOTFILES_DIR/scripts/setup_all.sh"
else
    echo -e "${RED}❌ Không tìm thấy setup_all.sh!${NC}"
fi

# BƯỚC 3: Thiết lập liên kết cấu hình (Symlinks)
echo -e "\n${BLUE}--- BƯỚC 3: THIẾT LẬP LIÊN KẾT CẤU HÌNH ---${NC}"
mkdir -p "$HOME/.config"
make_link "$DOTFILES_DIR/config/hypr" "$HOME/.config/hypr"
make_link "$DOTFILES_DIR/config/waybar" "$HOME/.config/waybar"
make_link "$DOTFILES_DIR/config/wlogout" "$HOME/.config/wlogout"

# BƯỚC 4: Kích hoạt Vệ sĩ & Giao diện
echo -e "\n${BLUE}--- BƯỚC 4: KÍCH HOẠT HỆ THỐNG PHỤ TRỢ ---${NC}"
# Khởi động CyberGuard (Vệ sĩ CPU)
pkill -f cyberguard.sh
if [ -f "$DOTFILES_DIR/scripts/cyberguard.sh" ]; then
    bash "$DOTFILES_DIR/scripts/cyberguard.sh" &
    echo -e "${GREEN}✅ Vệ sĩ CPU CyberGuard đã lên nòng.${NC}"
fi

# Khởi động Wallpaper
[ -f "$DOTFILES_DIR/scripts/wallpaper.sh" ] && bash "$DOTFILES_DIR/scripts/wallpaper.sh"

# --- 4. Hoàn tất ---
echo -e "\n${PURPLE}==================================================${NC}"
echo -e "${GREEN}🔥 HOÀN TẤT! Hệ thống của ông đã được Cyber-Hóa thành công.${NC}"
[ -d "$BACKUP_DIR" ] && echo -e "${YELLOW}📂 Cấu hình cũ được lưu tại: $BACKUP_DIR${NC}"
echo -e "${BLUE}💡 Hãy restart Hyprland (Super+M) để mọi thứ đồng bộ nhé!${NC}"
echo -e "${PURPLE}==================================================${NC}"
