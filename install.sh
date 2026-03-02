#!/bin/bash
# ============================================================
# install.sh — CyberTung Dotfiles Installer v2.0
# Arch Linux + Hyprland
# Dùng: bash install.sh
# ============================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${PURPLE}⚡ [CYBERTUNG DOTFILES] BẮT ĐẦU CÀI ĐẶT...${NC}"
echo -e "${BLUE}📍 Nguồn: $DOTFILES_DIR${NC}"

# ── HÀM TIỆN ÍCH ──────────────────────────────────────────
install_pkg() {
    if pacman -Qi "$1" &>/dev/null; then
        echo -e "${GREEN}✅ $1 đã có${NC}"
    else
        echo -e "${YELLOW}⏳ Cài $1...${NC}"
        sudo pacman -S --needed --noconfirm "$1" &>/dev/null \
            || (command -v yay &>/dev/null && yay -S --noconfirm "$1")
    fi
}

make_link() {
    local source="$1" target="$2"
    if [ -d "$source" ] || [ -f "$source" ]; then
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo -e "${YELLOW}⚠️  Backup: $target${NC}"
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
        ln -sf "$source" "$target"
        echo -e "${GREEN}✅ Linked: $target${NC}"
    else
        echo -e "${RED}❌ Không tìm thấy: $source${NC}"
    fi
}

# ── BƯỚC 1: CÀI PHẦN MỀM ─────────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 1: CÀI ĐẶT PHẦN MỀM ---${NC}"
APPS=(
    "hyprland" "waybar" "swww" "python-pywal"
    "kitty" "rofi" "wlogout"
    "lm_sensors"     # Cần cho smartd đọc nhiệt độ
    "libnotify"      # Cần cho notify-send
    "intel-gpu-tools"
)
for app in "${APPS[@]}"; do install_pkg "$app"; done

# ── BƯỚC 2: QUÉT XUNG ĐỘT ────────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 2: QUÉT XUNG ĐỘT ---${NC}"
chmod +x "$DOTFILES_DIR/scripts/"*.sh
[ -f "$DOTFILES_DIR/scripts/setup_all.sh" ] \
    && bash "$DOTFILES_DIR/scripts/setup_all.sh" \
    || echo -e "${RED}❌ Không tìm thấy setup_all.sh${NC}"

# ── BƯỚC 3: SYMLINKS ──────────────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 3: THIẾT LẬP CONFIG ---${NC}"
mkdir -p "$HOME/.config"
make_link "$DOTFILES_DIR/config/hypr"    "$HOME/.config/hypr"
make_link "$DOTFILES_DIR/config/waybar"  "$HOME/.config/waybar"
make_link "$DOTFILES_DIR/config/wlogout" "$HOME/.config/wlogout"

# ── BƯỚC 4: SETUP LM_SENSORS ─────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 4: SETUP SENSORS ---${NC}"
if command -v sensors-detect &>/dev/null; then
    sudo sensors-detect --auto &>/dev/null
    echo -e "${GREEN}✅ sensors ready${NC}"
fi

# ── BƯỚC 5: START SMART DAEMON ────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 5: KHỞI ĐỘNG SMART DAEMON ---${NC}"

# Kill daemon cũ nếu có
pkill -f "smartd.sh start"  2>/dev/null
pkill -f "cyberguard.sh"    2>/dev/null
pkill -f "cyberguard_v2.sh" 2>/dev/null
sleep 1

# Start smartd v2 (daemon chính)
if [ -f "$DOTFILES_DIR/scripts/smartd.sh" ]; then
    bash "$DOTFILES_DIR/scripts/smartd.sh" start
    echo -e "${GREEN}✅ smartd v2.0 đã khởi động${NC}"
else
    echo -e "${RED}❌ Không tìm thấy smartd.sh${NC}"
fi

# Start cyberguard v2 song song (monitor độc lập)
if [ -f "$DOTFILES_DIR/scripts/cyberguard_v2.sh" ]; then
    nohup bash "$DOTFILES_DIR/scripts/cyberguard_v2.sh" \
        >> /tmp/cyberguard.log 2>&1 &
    echo -e "${GREEN}✅ cyberguard_v2 đã khởi động${NC}"
fi

# ── BƯỚC 6: WALLPAPER ─────────────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 6: WALLPAPER ---${NC}"
[ -f "$DOTFILES_DIR/scripts/wallpaper.sh" ] \
    && bash "$DOTFILES_DIR/scripts/wallpaper.sh"

# ── BƯỚC 7: HEALTH CHECK ──────────────────────────────────
echo -e "\n${BLUE}--- BƯỚC 7: KIỂM TRA SỨC KHỎE ---${NC}"
[ -f "$DOTFILES_DIR/scripts/check_health.py" ] \
    && python3 "$DOTFILES_DIR/scripts/check_health.py"

# ── DONE ──────────────────────────────────────────────────
echo -e "\n${PURPLE}══════════════════════════════════════${NC}"
echo -e "${GREEN}⚡ HOÀN TẤT! CyberTung đã sẵn sàng.${NC}"
[ -d "$BACKUP_DIR" ] && echo -e "${YELLOW}📂 Config cũ: $BACKUP_DIR${NC}"
echo -e "${BLUE}💡 Reload Hyprland: hyprctl reload${NC}"
echo -e "${BLUE}💡 Hoặc restart: Super+SHIFT+M rồi login lại${NC}"
echo -e "${PURPLE}══════════════════════════════════════${NC}"
