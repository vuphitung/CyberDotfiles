# ╔══════════════════════════════════════════════════════════╗
# ║           CYBERTUNG — ALIASES v5                        ║
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
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias orphans='sudo pacman -Rns $(pacman -Qtdq)'
alias mirrors='sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'

# ── CLIPBOARD / TOOLS ────────────────────────────────────────
alias copy='wl-copy'
alias paste='wl-paste'
alias cat='bat --style=plain' 2>/dev/null || alias cat='cat'

# ── GIT ──────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --color'

# ── TEMPERATURE ──────────────────────────────────────────────
alias temp='sensors | grep -E "Core|temp"'
alias htop='btop' 2>/dev/null || alias htop='htop'
