# ╔══════════════════════════════════════════════════════════╗
# ║           CYBERTUNG — ALIASES v6                        ║
# ╚══════════════════════════════════════════════════════════╝

# ── NAVIGATION ──────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls --color=auto'

# ── DOTFILES ─────────────────────────────────────────────────
alias dot='cd ~/CyberDotfiles'
alias dotpush='cd ~/CyberDotfiles && git add -A && git commit -m "update: $(date +%Y-%m-%d)" && git push'
alias hconf='nvim ~/.config/hypr/hyprland.conf'
alias uconf='nvim ~/.config/hypr/user.conf'
alias kconf='nvim ~/.config/kitty/kitty.conf'
alias rconf='nvim ~/.config/rofi/config.rasi'
alias reload='hyprctl reload && echo "✅ Hyprland reloaded"'

# ── PYWAL ────────────────────────────────────────────────────
alias wal-set='bash ~/CyberDotfiles/scripts/wallpaper.sh'
alias wal-pick='bash ~/CyberDotfiles/scripts/wall-picker.sh'

# ── SYSTEM ───────────────────────────────────────────────────
alias update='sudo pacman -Syu'
alias pacin='sudo pacman -S'   # đổi tên: 'install' trùng lệnh coreutils
alias remove='sudo pacman -Rns'
alias mirrors='sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'

# ── CLIPBOARD / TOOLS ────────────────────────────────────────
alias copy='wl-copy'
alias paste='wl-paste'
command -v bat  >/dev/null && alias cat='bat --style=plain'

# ── GIT ──────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --color'

# ── TEMPERATURE ──────────────────────────────────────────────
alias temp='sensors | grep -E "Core|temp"'
command -v btop >/dev/null && alias htop='btop'


# ── v6 ──
export EDITOR="${EDITOR:-nano}"
alias doctor='python3 ~/CyberDotfiles/scripts/check_health.py'
alias hcheck='hyprctl configerrors'
alias orphans='pacman -Qtdq | sudo pacman -Rns - 2>/dev/null || echo "Không có gói mồ côi"'
