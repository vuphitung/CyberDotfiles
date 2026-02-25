<div align="center">

# ⚡ Cyber-Tung Dotfiles ⚡
### *Vanilla & High-Performance Hyprland Configuration*

<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" />

[![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/WM-Hyprland-00c8ff?style=for-the-badge&logo=wayland&logoColor=white)](https://hyprland.org/)
[![Vanilla](https://img.shields.io/badge/Philosophy-Vanilla_&_Bloat--free-22c55e?style=for-the-badge&logo=leaflet&logoColor=white)]()
[![License](https://img.shields.io/badge/License-MIT-fbbf24?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE)

**🎯 A purely hand-crafted, lightweight Hyprland configuration built from the ground up**  
*No bloated frameworks. No premade kits. Just pure performance.*

[Features](#-why-this-setup) • [Installation](#-quick-installation) • [Keybinds](#️-essential-keybindings) • [Preview](#️-gallery)

</div>

---

## 🌟 Why This Setup?

<table>
<tr>
<td width="50%">

### 🍃 **Vanilla Core**
No bloated frameworks or rice scripts. Everything is configured manually from base Hyprland, giving you **full control** and **zero dependencies** you don't need.

</td>
<td width="50%">

### 🎨 **Dynamic Theme Engine**
Integrated with **Pywal** to automatically sync system colors (Waybar, Terminal, Rofi) with your wallpaper in **real-time**. Change wallpaper = instant system-wide theme update.

</td>
</tr>
<tr>
<td width="50%">

### 🧠 **Smart Deployment**
Robust `install.sh` with:
- ✅ Dependency validation
- ✅ Automated symlinks
- ✅ Safe configuration backups
- ✅ One-command setup

</td>
<td width="50%">

### ⚡ **Performance First**
Minimal background processes designed for:
- 🎮 **Zero-lag gaming**
- 💻 **Professional workflows**
- 🚀 **Instant response times**
- 🔋 **Extended battery life**

</td>
</tr>
</table>

---

## 📂 System Architecture

<div align="center">

```
CyberDotfiles/
│
├── 📜 install.sh              # Smart Auto-Installer with Dependency Checker
│
├── ⚙️  config/
│   ├── hypr/                  # Pure Hyprland Core Configuration
│   │   ├── hyprland.conf      # Main window manager config
│   │   ├── keybinds.conf      # Custom keybinding definitions
│   │   └── autostart.conf     # Launch applications on startup
│   │
│   ├── waybar/                # Dynamic Status Bar
│   │   ├── config.jsonc       # Bar layout & modules
│   │   └── style.css          # Theming & animations
│   │
│   ├── kitty/                 # GPU-Accelerated Terminal
│   │   └── kitty.conf         # Terminal appearance & behavior
│   │
│   ├── rofi/                  # Application Launcher
│   │   └── config.rasi        # Custom launcher theme
│   │
│   └── wlogout/               # Minimal Power Menu
│       ├── layout             # Button positioning
│       └── style.css          # Power menu styling
│
└── 🔧 scripts/
    ├── wallpaper.sh           # Theming Engine (Wallpaper + Pywal Integration)
    ├── check_health.py        # System Diagnostic Tool
    └── screenshot.sh          # Screenshot utility with Grimblast
```

</div>

---

## 🛠️ Minimalist Components

<div align="center">

| Component | Choice | Reason |
|:---:|:---:|:---|
| 🪟 **Window Manager** | [Hyprland](https://hyprland.org/) | Modern Wayland compositor with smooth animations |
| 📊 **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | C++ based, extremely lightweight & customizable |
| 💻 **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated for 0ms input latency |
| 🎨 **Theme Engine** | [Pywal](https://github.com/dylanaraps/pywal) | Dynamic color generation from wallpapers |
| 🖼️ **Wallpaper Daemon** | [SWWW](https://github.com/LGFae/swww) | Lowest memory usage wallpaper solution |
| 🚀 **App Launcher** | [Rofi](https://github.com/lbonn/rofi) | Fast, keyboard-driven application launcher |
| 📸 **Screenshots** | [Grimblast](https://github.com/hyprwm/contrib) | Native Hyprland screenshot tool |
| 🔔 **Notifications** | [Dunst](https://dunst-project.org/) | Minimal notification daemon |

</div>

---

## 🚀 Quick Installation

> [!IMPORTANT]  
> This configuration is optimized for **Arch Linux**. Ensure you have `git` and `base-devel` installed before proceeding.

### 📥 One-Command Setup

```bash
git clone https://github.com/vuphitung/CyberDotfiles.git ~/CyberDotfiles
cd ~/CyberDotfiles
chmod +x install.sh
./install.sh
```

### 🔍 What the installer does:

1. ✅ Checks for required dependencies
2. ✅ Creates safe backups of existing configs
3. ✅ Symlinks all configurations to proper locations
4. ✅ Sets up theming engine integration
5. ✅ Validates installation integrity

### 🎯 Manual Installation (for advanced users)

<details>
<summary>Click to expand manual setup steps</summary>

```bash
# 1. Install required packages
yay -S hyprland waybar kitty rofi swww python-pywal dunst grimblast-git

# 2. Backup existing configs
mkdir -p ~/.config/backup
cp -r ~/.config/hypr ~/.config/backup/ 2>/dev/null

# 3. Create symlinks
ln -sf ~/CyberDotfiles/config/hypr ~/.config/
ln -sf ~/CyberDotfiles/config/waybar ~/.config/
ln -sf ~/CyberDotfiles/config/kitty ~/.config/
ln -sf ~/CyberDotfiles/config/rofi ~/.config/

# 4. Make scripts executable
chmod +x ~/CyberDotfiles/scripts/*.sh
```

</details>

---

## ⌨️ Essential Keybindings

<div align="center">

| Key Combination | Action |
|:---|:---|
| `Super` + `Q` | 💻 Launch Terminal (Kitty) |
| `Super` + `Alt` + `W` | 🎨 Switch Wallpaper & Auto-Theme System |
| `Super` + `Shift` + `C` | 🔄 Reload Hyprland Configuration |
| `Super` + `M` | ⚡ Power Menu (Lock/Logout/Shutdown) |
| `Super` + `Space` | 🚀 Application Launcher (Rofi) |
| `Super` + `S` | 📸 Screenshot (Selection Mode) |
| `Super` + `Shift` + `S` | 📸 Screenshot (Fullscreen) |
| `Super` + `V` | 📋 Clipboard History (Cliphist) |
| `Super` + `F` | 🖥️ Toggle Fullscreen |
| `Super` + `[1-9]` | 🔢 Switch to Workspace 1-9 |
| `Super` + `Shift` + `[1-9]` | 📦 Move Window to Workspace 1-9 |
| `Super` + `Mouse Scroll` | 🔄 Cycle Through Workspaces |

</div>

---

## 🖼️ Gallery

> [!NOTE]  
> Add your screenshots here to showcase your setup! Recommended format:

<div align="center">

### Desktop Overview
<img src="screenshots/desktop.png" width="800px" />

### Terminal & Coding
<img src="screenshots/terminal.png" width="800px" />

### Dynamic Theme Switching
<img src="screenshots/theme-change.gif" width="800px" />

</div>

---

## 🎨 Customization Guide

<details>
<summary><b>🌈 Changing Colors & Themes</b></summary>

### Using Pywal (Automatic)
```bash
# Generate theme from wallpaper
wal -i /path/to/wallpaper.jpg

# Or use the included script
~/CyberDotfiles/scripts/wallpaper.sh /path/to/wallpaper.jpg
```

### Manual Color Editing
Edit `~/.config/hypr/colors.conf` to set your preferred color scheme:
```conf
$background = rgb(1e1e2e)
$foreground = rgb(cdd6f4)
$accent = rgb(89b4fa)
```

</details>

<details>
<summary><b>⚙️ Modifying Keybindings</b></summary>

Edit `~/.config/hypr/keybinds.conf` to customize your shortcuts:
```conf
bind = SUPER, Q, exec, kitty                    # Your terminal
bind = SUPER, SPACE, exec, rofi -show drun      # App launcher
bind = SUPER SHIFT, C, exec, hyprctl reload     # Reload config
```

</details>

<details>
<summary><b>📊 Waybar Customization</b></summary>

### Adding/Removing Modules
Edit `~/.config/waybar/config.jsonc`:
```json
"modules-left": ["hyprland/workspaces", "hyprland/window"],
"modules-center": ["clock"],
"modules-right": ["network", "pulseaudio", "battery"]
```

### Styling
Customize appearance in `~/.config/waybar/style.css`.

</details>

---

## 🐛 Troubleshooting

<details>
<summary><b>❌ Hyprland won't start</b></summary>

1. Check if you're running Wayland-compatible GPU drivers:
```bash
hyprctl version
```

2. Verify config syntax:
```bash
hyprland -c ~/.config/hypr/hyprland.conf --validate
```

</details>

<details>
<summary><b>🎨 Pywal colors not applying</b></summary>

1. Ensure Pywal is installed:
```bash
pip install pywal
```

2. Restart Waybar after theme change:
```bash
killall waybar && waybar &
```

</details>

<details>
<summary><b>⌨️ Keybinds not working</b></summary>

Check if another program is capturing the keys:
```bash
hyprctl devices
```

Verify your keybind syntax in `~/.config/hypr/keybinds.conf`.

</details>

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. 🍴 Fork the repository
2. 🌿 Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. 💾 Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push to the branch (`git push origin feature/AmazingFeature`)
5. 🎉 Open a Pull Request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💖 Acknowledgments

<div align="center">

Special thanks to:
- [Hyprland](https://hyprland.org/) - The amazing compositor
- [Waybar](https://github.com/Alexays/Waybar) - Beautiful status bar
- [r/unixporn](https://reddit.com/r/unixporn) - Inspiration & community

---

<sub>Made with ⚡ by [vuphitung](https://github.com/vuphitung)</sub>

**⭐ If you find this useful, please consider giving it a star!**

</div>
