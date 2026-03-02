#!/bin/bash
# ============================================================
# setup_all.sh — CyberTung System Auditor v2.0
# Kiểm tra xung đột, cài driver, tối ưu power profile
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}--- 🛡️ CYBER-AUDITOR: KIỂM TRA HỆ THỐNG ---${NC}"

# ── 1. Xung đột power management ──────────────────────────
# Giữ tlp vì hyprland.conf dùng "exec-once = tlp start"
# Chỉ tắt auto-cpufreq và thermald nếu đang chạy song song
CONFLICTS=("auto-cpufreq" "thermald")
for app in "${CONFLICTS[@]}"; do
    if systemctl is-active --quiet "$app"; then
        echo -e "${YELLOW}⚠️  $app đang chạy — có thể conflict với tlp${NC}"
        read -p "Tắt $app? (y/n): " choice
        [[ "$choice" == "y" ]] && sudo systemctl disable --now "$app" \
            && echo -e "${GREEN}✅ Đã tắt $app${NC}"
    fi
done

# ── 2. Intel VA-API Driver ────────────────────────────────
if lspci | grep -iq intel; then
    if ! pacman -Qs intel-media-driver &>/dev/null; then
        echo -e "${YELLOW}⏳ Cài Intel Media Driver (VA-API)...${NC}"
        sudo pacman -S --needed --noconfirm intel-media-driver libva-intel-driver
        echo -e "${GREEN}✅ Intel driver đã cài${NC}"
    else
        echo -e "${GREEN}✅ Intel driver đã có${NC}"
    fi
fi

# ── 3. Power Profile ──────────────────────────────────────
# Dùng balanced thay vì performance để giảm nhiệt máy yếu
if command -v powerprofilesctl &>/dev/null; then
    sudo systemctl unmask power-profiles-daemon &>/dev/null
    sudo systemctl enable --now power-profiles-daemon &>/dev/null
    # i7-6600U máy yếu → balanced để không quá nóng
    sudo powerprofilesctl set balanced 2>/dev/null \
        && echo -e "${GREEN}✅ Power profile: balanced (phù hợp i7-6600U)${NC}" \
        || echo -e "${YELLOW}⚠️  powerprofilesctl set failed, bỏ qua${NC}"
fi

# ── 4. Sudoers cho purge.sh ───────────────────────────────
# Cho phép drop_caches không cần mật khẩu
SUDOERS_FILE="/etc/sudoers.d/cybertung"
if [ ! -f "$SUDOERS_FILE" ]; then
    echo -e "${YELLOW}⏳ Setup sudoers cho purge.sh...${NC}"
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /proc/sys/vm/drop_caches" \
        | sudo tee "$SUDOERS_FILE" &>/dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo -e "${GREEN}✅ Sudoers configured${NC}"
else
    echo -e "${GREEN}✅ Sudoers đã có${NC}"
fi

echo -e "${GREEN}✅ Audit hoàn tất${NC}"
