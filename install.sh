#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║         CyberTung Dotfiles — install.sh v6              ║
# ║         Arch Linux + Hyprland                           ║
# ╚══════════════════════════════════════════════════════════╝
set -e

G='\033[0;32m' B='\033[0;34m' Y='\033[1;33m' R='\033[0;31m' P='\033[0;35m' N='\033[0m'
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BAK="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

log()  { echo -e "${B}▸ $*${N}"; }
ok()   { echo -e "  ${G}✅ $*${N}"; }
warn() { echo -e "  ${Y}⚠️  $*${N}"; }
err()  { echo -e "  ${R}❌ $*${N}"; }

pkg() {
    pacman -Qi "$1" &>/dev/null && { ok "$1"; return; }
    warn "Cài $1..."
    sudo pacman -S --needed --noconfirm "$1" &>/dev/null \
        || (command -v yay &>/dev/null && yay -S --noconfirm "$1" &>/dev/null) \
        || err "$1 — cài thủ công"
}

aur() {
    (pacman -Qi "$1" &>/dev/null || yay -Qi "$1" &>/dev/null 2>/dev/null) \
        && { ok "$1 (AUR)"; return; }
    warn "Cài AUR: $1..."
    command -v yay &>/dev/null \
        && yay -S --noconfirm "$1" &>/dev/null \
        || err "$1 — cần yay"
}

lnk() {
    [ -e "$1" ] || { err "Không tìm thấy: $1"; return; }
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        mkdir -p "$BAK"; mv "$2" "$BAK/"; warn "Backup: $2"
    fi
    # Xóa symlink cũ sai nếu có
    [ -L "$2" ] && rm -f "$2"
    ln -sfn "$1" "$2" && ok "Linked: $2"
}

echo -e "${P}"
cat << 'ART'
   ██████╗██╗   ██╗██████╗ ███████╗██████╗
  ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗
  ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝
  ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗
  ╚██████╗   ██║   ██████╔╝███████╗██║  ██║
   ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ██║
ART
echo -e "  TUNG DOTFILES v6 — $D${N}\n"

# ── 1. PACKAGES ─────────────────────────────────────────────
log "PACKAGES"
PKGS="hyprland hyprlock hypridle hyprpolkitagent awww python-pywal \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk wl-clipboard cliphist \
  kitty rofi wlogout nautilus \
  pipewire pipewire-pulse wireplumber pamixer playerctl brightnessctl \
  swaynotificationcenter libnotify \
  networkmanager nm-connection-editor blueman \
  power-profiles-daemon lm_sensors \
  imagemagick fzf jq bat btop \
  ttf-jetbrains-mono-nerd noto-fonts-emoji papirus-icon-theme breeze \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-unikey \
  starship nano zsh"
# Một lệnh pacman duy nhất (nhanh hơn, và HIỆN lỗi thay vì nuốt vào /dev/null)
sudo pacman -S --needed --noconfirm $PKGS || warn "pacman báo lỗi — kiểm tra phía trên"
# Lưu ý: tlp đã bị bỏ vì xung đột power-profiles-daemon.
# Nếu máy đang bật tlp:  sudo systemctl disable --now tlp

log "AUR"
for p in grimblast-git; do aur "$p"; done

# ── 2. SYMLINKS ──────────────────────────────────────────────
log "SYMLINKS"
mkdir -p "$HOME/.config"
lnk "$D/config/hypr"    "$HOME/.config/hypr"
lnk "$D/config/wlogout" "$HOME/.config/wlogout"
lnk "$D/config/kitty"   "$HOME/.config/kitty"
lnk "$D/config/rofi"    "$HOME/.config/rofi"

# nano cần tạo thư mục trước
mkdir -p "$HOME/.config/nano"
ln -sf "$D/config/nano/nanorc" "$HOME/.config/nano/nanorc" \
    && ok "Linked: ~/.config/nano/nanorc"

# starship
mkdir -p "$HOME/.config"
ln -sf "$D/shell/starship.toml" "$HOME/.config/starship.toml" \
    && ok "Linked: ~/.config/starship.toml"

# ── 3. SHELL ─────────────────────────────────────────────────
log "SHELL"
# Thêm source aliases vào zshrc nếu chưa có
if ! grep -q "CyberDotfiles/shell/aliases.sh" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# CyberTung aliases" >> "$HOME/.zshrc"
    echo "source $D/shell/aliases.sh" >> "$HOME/.zshrc"
    ok "Đã thêm aliases vào ~/.zshrc"
else
    ok "aliases.sh đã có trong ~/.zshrc"
fi

# Thêm starship init nếu chưa có
if ! grep -q "starship init" "$HOME/.zshrc" 2>/dev/null; then
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    ok "Đã thêm starship init vào ~/.zshrc"
else
    ok "starship init đã có"
fi

# ── 4. THƯ MỤC ──────────────────────────────────────────────
log "THƯ MỤC"
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers/wallpapers"
ok "~/Pictures/Screenshots"
ok "~/Pictures/Wallpapers/wallpapers"

# ── 5. SCRIPTS ──────────────────────────────────────────────
log "SCRIPTS"
chmod +x "$D/scripts/"*.sh 2>/dev/null
chmod +x "$D/scripts/"*.py 2>/dev/null
ok "chmod +x scripts/*"

# ── 6. WIFI FIX ──────────────────────────────────────────────
log "WIFI FIX"
if lspci 2>/dev/null | grep -iq "wireless\|wifi\|network"; then
    if [ ! -f /etc/modprobe.d/iwlwifi.conf ]; then
        sudo tee /etc/modprobe.d/iwlwifi.conf > /dev/null << 'MOD'
options iwlwifi power_save=0 uapsd_disable=1
options iwlmvm power_scheme=1
MOD
        sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'NM'
[connection]
wifi.powersave = 2
NM
        ok "WiFi fix applied"
    else
        ok "WiFi fix đã có"
    fi
fi

# ── 7. WALLPAPER ─────────────────────────────────────────────
log "WALLPAPER"
WALL_DIR="$HOME/Pictures/Wallpapers/wallpapers"
WALL_COUNT=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | wc -l)
if [ "$WALL_COUNT" -gt 0 ]; then
    bash "$D/scripts/wallpaper.sh" 2>/dev/null && ok "Wallpaper set"
else
    warn "Chưa có ảnh trong $WALL_DIR"
    warn "Thêm ảnh vào $WALL_DIR rồi chạy: bash scripts/wallpaper.sh"
fi

# ── 8. HEALTH CHECK ──────────────────────────────────────────
log "HEALTH CHECK"
python3 "$D/scripts/check_health.py"

# ── DONE ─────────────────────────────────────────────────────
echo -e "\n${P}══════════════════════════════════════════${N}"
echo -e "${G}⚡ XONG! Chạy: hyprctl reload${N}"
[ -d "$BAK" ] && echo -e "${Y}📂 Backup cũ: $BAK${N}"
echo -e "${P}══════════════════════════════════════════${N}"
