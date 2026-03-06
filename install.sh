#!/bin/bash
# ============================================================
# install.sh — CyberTung Dotfiles Installer v2
# Arch Linux + Hyprland + EWW (không dùng Waybar)
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

echo -e "${PURPLE}"
echo -e "  ███╗   ██╗ ██████╗    ██████╗  ██████╗ ███████╗"
echo -e "  ████╗  ██║██╔════╝   ╚════██╗██╔═████╗╚════██╔╝"
echo -e "  ██╔██╗ ██║██║         █████╔╝██║██╔██║    ██╔╝ "
echo -e "  ██║╚██╗██║██║        ██╔═══╝ ████╔╝██║   ██╔╝  "
echo -e "  ██║ ╚████║╚██████╗██╗███████╗╚██████╔╝   ██║   "
echo -e "  ╚═╝  ╚═══╝ ╚═════╝╚═╝╚══════╝ ╚═════╝    ╚═╝   "
echo -e "${NC}"
echo -e "${BLUE}📍 Nguồn: $DOTFILES_DIR${NC}"
echo ""

# ── HÀM TIỆN ÍCH ──────────────────────────────────────────
install_pkg() {
    if pacman -Qi "$1" &>/dev/null; then
        echo -e "  ${GREEN}✅ $1${NC}"
    else
        echo -e "  ${YELLOW}⏳ Cài $1...${NC}"
        sudo pacman -S --needed --noconfirm "$1" &>/dev/null \
            || (command -v yay &>/dev/null && yay -S --noconfirm "$1" &>/dev/null) \
            || echo -e "  ${RED}❌ Không cài được $1 — bro cài thủ công${NC}"
    fi
}

install_aur() {
    if pacman -Qi "$1" &>/dev/null || yay -Qi "$1" &>/dev/null 2>/dev/null; then
        echo -e "  ${GREEN}✅ $1 (AUR)${NC}"
    else
        echo -e "  ${YELLOW}⏳ Cài AUR: $1...${NC}"
        command -v yay &>/dev/null \
            && yay -S --noconfirm "$1" &>/dev/null \
            || echo -e "  ${RED}❌ Cần yay để cài $1${NC}"
    fi
}

make_link() {
    local source="$1" target="$2"
    if [ -d "$source" ] || [ -f "$source" ]; then
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo -e "  ${YELLOW}⚠️  Backup: $target${NC}"
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
        ln -sf "$source" "$target"
        echo -e "  ${GREEN}✅ Linked: $target${NC}"
    else
        echo -e "  ${RED}❌ Không tìm thấy: $source${NC}"
    fi
}

# ── BƯỚC 1: PACMAN PACKAGES ───────────────────────────────
echo -e "${BLUE}━━━ BƯỚC 1: PACKAGES ━━━━━━━━━━━━━━━━━━━━━${NC}"
PACMAN_APPS=(
    # WM
    "hyprland"
    # Bar — dùng EWW, không cần waybar
    "swww"
    # Terminal & launcher
    "kitty" "rofi" "wlogout"
    # EWW dependencies
    "jq" "socat"
    # Audio
    "pamixer" "pipewire" "pipewire-pulse"
    # Brightness
    "brightnessctl"
    # Screenshot
    "grimblast"
    # Bluetooth
    "blueman"
    # Notification
    "libnotify" "swaynotificationcenter"
    # Sensors & monitoring
    "lm_sensors"
    # Network
    "networkmanager" "nm-connection-editor"
    # Media
    "playerctl"
    # Wallpaper
    "python-pywal"
    # Fonts
    "ttf-jetbrains-mono-nerd"
    # Night mode
    "gammastep"
)
for app in "${PACMAN_APPS[@]}"; do install_pkg "$app"; done

echo ""
echo -e "${BLUE}━━━ AUR PACKAGES ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
AUR_APPS=(
    "eww"           # Bar chính
    "grimblast-git" # Screenshot (nếu pacman không có)
)
for app in "${AUR_APPS[@]}"; do install_aur "$app"; done

# ── BƯỚC 2: AUDIT HỆ THỐNG ───────────────────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 2: AUDIT HỆ THỐNG ━━━━━━━━━━━━━━━${NC}"
chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null
[ -f "$DOTFILES_DIR/scripts/setup_all.sh" ] \
    && bash "$DOTFILES_DIR/scripts/setup_all.sh" \
    || echo -e "  ${RED}❌ Không tìm thấy setup_all.sh${NC}"

# ── BƯỚC 3: SYMLINKS CONFIG ───────────────────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 3: CONFIG SYMLINKS ━━━━━━━━━━━━━━━${NC}"
mkdir -p "$HOME/.config"

make_link "$DOTFILES_DIR/config/hypr"    "$HOME/.config/hypr"
make_link "$DOTFILES_DIR/config/eww"     "$HOME/.config/eww"
make_link "$DOTFILES_DIR/config/kitty"   "$HOME/.config/kitty"
make_link "$DOTFILES_DIR/config/rofi"    "$HOME/.config/rofi"
make_link "$DOTFILES_DIR/config/wlogout" "$HOME/.config/wlogout"

# Không link waybar — dùng eww thay thế
echo -e "  ${BLUE}ℹ️  Waybar đã được thay bằng EWW${NC}"

# ── BƯỚC 4: WIFI FIX (iwlwifi power save) ────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 4: WIFI STABILITY FIX ━━━━━━━━━━━━${NC}"
IWLWIFI_CONF="/etc/modprobe.d/iwlwifi.conf"
if lspci | grep -iq "network\|wireless\|wifi"; then
    if [ ! -f "$IWLWIFI_CONF" ]; then
        echo -e "  ${YELLOW}⏳ Tạo iwlwifi config...${NC}"
        sudo tee "$IWLWIFI_CONF" << 'EOF' &>/dev/null
# Tắt power save để tránh mất kết nối liên tục
options iwlwifi power_save=0 d0i3_disable=1 uapsd_disable=1
options iwlmvm power_scheme=1
EOF
        sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf << 'EOF' &>/dev/null
[connection]
wifi.powersave = 2
EOF
        echo -e "  ${GREEN}✅ WiFi stability config đã tạo${NC}"
    else
        echo -e "  ${GREEN}✅ WiFi config đã có${NC}"
    fi
fi

# ── BƯỚC 5: SENSORS ───────────────────────────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 5: SENSORS ━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if command -v sensors-detect &>/dev/null; then
    sudo sensors-detect --auto &>/dev/null
    echo -e "  ${GREEN}✅ sensors ready${NC}"
fi

# ── BƯỚC 6: CYBERGUARD ────────────────────────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 6: CYBERGUARD ━━━━━━━━━━━━━━━━━━━━${NC}"
pkill -f "cyberguard.sh" 2>/dev/null
sleep 0.5
if [ -f "$DOTFILES_DIR/scripts/cyberguard.sh" ]; then
    nohup bash "$DOTFILES_DIR/scripts/cyberguard.sh" \
        >> /tmp/cyberguard.log 2>&1 &
    echo -e "  ${GREEN}✅ cyberguard started (PID: $!)${NC}"
else
    echo -e "  ${RED}❌ Không tìm thấy cyberguard.sh${NC}"
fi

# ── BƯỚC 7: WALLPAPER ─────────────────────────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 7: WALLPAPER ━━━━━━━━━━━━━━━━━━━━━${NC}"
[ -f "$DOTFILES_DIR/scripts/wallpaper.sh" ] \
    && bash "$DOTFILES_DIR/scripts/wallpaper.sh" \
    || echo -e "  ${RED}❌ Không tìm thấy wallpaper.sh${NC}"

# ── BƯỚC 8: HEALTH CHECK ──────────────────────────────────
echo ""
echo -e "${BLUE}━━━ BƯỚC 8: HEALTH CHECK ━━━━━━━━━━━━━━━━━━${NC}"
[ -f "$DOTFILES_DIR/scripts/check_health.py" ] \
    && python3 "$DOTFILES_DIR/scripts/check_health.py"

# ── DONE ──────────────────────────────────────────────────
echo ""
echo -e "${PURPLE}══════════════════════════════════════════${NC}"
echo -e "${GREEN}⚡ HOÀN TẤT! Hệ thống sẵn sàng.${NC}"
[ -d "$BACKUP_DIR" ] && echo -e "${YELLOW}📂 Config cũ đã backup: $BACKUP_DIR${NC}"
echo ""
echo -e "${BLUE}💡 Bước tiếp theo:${NC}"
echo -e "   1. hyprctl reload"
echo -e "   2. bash ~/CyberDotfiles/config/eww/scripts/launch-bar.sh"
echo -e "   3. Thêm vào hyprland.conf nếu chưa có:"
echo -e "      exec-once = bash ~/CyberDotfiles/config/eww/scripts/launch-bar.sh"
echo -e "${PURPLE}══════════════════════════════════════════${NC}"
