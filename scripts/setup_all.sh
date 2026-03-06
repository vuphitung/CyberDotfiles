#!/bin/bash
# ============================================================
# setup_all.sh — CyberTung System Auditor v3
# Kiểm tra xung đột, cài driver, tối ưu power profile
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}  🛡️  CYBER-AUDITOR: KIỂM TRA HỆ THỐNG${NC}"

# ── 1. Xung đột power management ──────────────────────────
echo -e "\n${BLUE}  → Power management${NC}"
CONFLICTS=("auto-cpufreq" "thermald")
for app in "${CONFLICTS[@]}"; do
    if systemctl is-active --quiet "$app" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠️  $app đang chạy — conflict với tlp${NC}"
        echo -e "  ${YELLOW}   Tắt thủ công: sudo systemctl disable --now $app${NC}"
    fi
done
echo -e "  ${GREEN}✅ Power check xong${NC}"

# ── 2. Intel VA-API Driver ────────────────────────────────
echo -e "\n${BLUE}  → Intel GPU driver${NC}"
if lspci 2>/dev/null | grep -iq intel; then
    if ! pacman -Qs intel-media-driver &>/dev/null; then
        echo -e "  ${YELLOW}⏳ Cài Intel Media Driver...${NC}"
        sudo pacman -S --needed --noconfirm intel-media-driver libva-intel-driver &>/dev/null
    fi
    echo -e "  ${GREEN}✅ Intel driver ok${NC}"
fi

# ── 3. Power Profile ──────────────────────────────────────
echo -e "\n${BLUE}  → Power profile${NC}"
if command -v powerprofilesctl &>/dev/null; then
    sudo systemctl enable --now power-profiles-daemon &>/dev/null
    sudo powerprofilesctl set balanced 2>/dev/null \
        && echo -e "  ${GREEN}✅ Power profile: balanced${NC}" \
        || echo -e "  ${YELLOW}⚠️  powerprofilesctl set failed${NC}"
fi

# ── 4. Sudoers cho scripts ────────────────────────────────
echo -e "\n${BLUE}  → Sudoers${NC}"
SUDOERS_FILE="/etc/sudoers.d/cybertung"
if [ ! -f "$SUDOERS_FILE" ]; then
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /proc/sys/vm/drop_caches" \
        | sudo tee "$SUDOERS_FILE" &>/dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo -e "  ${GREEN}✅ Sudoers configured${NC}"
else
    echo -e "  ${GREEN}✅ Sudoers ok${NC}"
fi

# ── 5. EWW scripts permission ─────────────────────────────
echo -e "\n${BLUE}  → EWW scripts${NC}"
EWW_SCRIPTS="$HOME/CyberDotfiles/config/eww/scripts"
if [ -d "$EWW_SCRIPTS" ]; then
    chmod +x "$EWW_SCRIPTS"/*.sh 2>/dev/null
    echo -e "  ${GREEN}✅ EWW scripts: chmod +x${NC}"
fi

echo -e "\n${GREEN}  ✅ Audit hoàn tất${NC}"
