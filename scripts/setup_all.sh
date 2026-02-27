#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}--- 🛡️ CYBER-AUDITOR: KIỂM TRA HỆ THỐNG TOÀN DIỆN ---${NC}"

# 1. Kiểm tra Xung đột
CONFLICTS=("tlp" "auto-cpufreq" "thermald")
for app in "${CONFLICTS[@]}"; do
    if systemctl is-active --quiet "$app"; then
        echo -e "${RED}⚠️ Phát hiện $app đang chạy!${NC}"
        read -p "Tắt $app để tối ưu hiệu năng nhé? (y/n): " choice
        [[ "$choice" == "y" ]] && sudo systemctl disable --now "$app"
    fi
done

# 2. Kiểm tra Intel Driver (VA-API)
if lspci | grep -iq intel; then
    if ! pacman -Qs intel-media-driver > /dev/null; then
        echo -e "${YELLOW}⏳ Đang cài driver Intel Media để mượt GPU...${NC}"
        sudo pacman -S --needed --noconfirm intel-media-driver libva-intel-driver
    fi
fi

# 3. Kích hoạt Power Profile
sudo systemctl unmask power-profiles-daemon &>/dev/null
sudo systemctl enable --now power-profiles-daemon &>/dev/null
sudo powerprofilesctl set performance
echo -e "${GREEN}✅ Đã ép CPU chạy chế độ Performance.${NC}"
