# CyberTung Dotfiles v6

Dotfiles cá nhân — Arch Linux + Hyprland.  
Tối ưu cho **Intel iGPU**, laptop **2560x1440@60Hz**.

## Cài đặt nhanh

```bash
git clone https://github.com/vuphucng/CyberDotfiles ~/CyberDotfiles
cd ~/CyberDotfiles
bash install.sh
```

Sau đó:
1. Thêm ảnh vào `~/Pictures/Wallpapers/wallpapers/`
2. Chạy `hyprctl reload`
3. Đăng xuất và đăng nhập lại vào Hyprland

---

## Cấu trúc

```
CyberDotfiles/
├── config/
│   ├── waybar/             ← Top bar: 3 đảo kính nổi (Sakura Glass)
│   ├── hypr/
│   │   ├── hyprland.conf   ← config chính, KHÔNG sửa trực tiếp
│   │   ├── hypridle.conf   ← idle daemon (auto lock / suspend)
│   │   ├── hyprlock.conf   ← lock screen Sakura Glass
│   │   └── user.conf       ← override cá nhân, sửa thoải mái
│   ├── kitty/
│   │   └── kitty.conf      ← terminal, tự đổi màu theo wallpaper
│   ├── rofi/
│   │   └── config.rasi     ← app launcher Sakura Glass
│   ├── swaync/             ← notification center & popups
│   │   ├── config.json
│   │   └── style.css
│   ├── nano/
│   │   └── nanorc          ← syntax highlight + line numbers
│   └── wlogout/            ← power menu Sakura Glass
├── shell/
│   ├── aliases.sh          ← shortcuts tiện dụng
│   └── starship.toml       ← prompt nhanh (<1ms)
├── scripts/
│   ├── wallpaper.sh        ← awww + pywal, tự reload màu kitty
│   ├── wall-picker.sh      ← TUI chọn ảnh (fzf + kitty icat)
│   ├── perf-mode.sh        ← toggle chế độ tiết kiệm Intel iGPU
│   ├── keyhints.sh         ← xem phím tắt
│   ├── fix_symlinks.sh     ← sửa symlink nếu bị lỗi
│   ├── iwlwifi-fix.sh      ← fix wifi Intel
│   ├── setup_all.sh        ← audit hệ thống
│   └── check_health.py     ← kiểm tra toàn bộ
├── docs/
│   └── keybinds.md
├── themes/
├── install.sh
└── README.md
```

---

## Phụ thuộc

| Package | Vai trò |
|---|---|
| `hyprland` | Window manager |
| `hyprlock` | Lock screen |
| `hypridle` | Idle management daemon |
| `waybar` | Top bar 3 đảo nổi (module native, nhẹ) |
| `awww` | Wallpaper daemon (hiệu ứng chuyển ảnh) |
| `python-pywal` | Tự sinh màu theo wallpaper |
| `kitty` | Terminal |
| `rofi` | App launcher |
| `swaync` | Notification center |
| `wlogout` | Power menu |
| `grimblast-git` | Screenshot (AUR) |
| `starship` | Prompt shell nhanh |
| `fcitx5` | Input method (gõ tiếng Việt) |
| `ttf-jetbrains-mono-nerd` | Font terminal & icons |

---

## Phím tắt

| Phím | Hành động |
|---|---|
| `Super + Q` | Mở terminal (kitty) |
| `Super + E` | File manager (nautilus) |
| `Super + G` | Chrome |
| `Super + Space` | App launcher (rofi) |
| `Super + B` | Bảng điều khiển / Control Center (swaync) |
| `Super + I` | Notifications (swaync) |
| `Super + C` | Đóng cửa sổ |
| `Super + F` | Fullscreen |
| `Super + V` | Floating window |
| `Super + L` | Power menu (wlogout) |
| `Super + P` | Lock screen (hyprlock) |
| `Super + W` | Chọn wallpaper |
| `Super + F1` | Xem phím tắt |
| `Super + R` | Resize mode |
| `Super + Tab` | Workspace trước |
| `Super + 1-6` | Chuyển workspace |
| `Super + Shift + 1-6` | Chuyển window sang workspace |
| `Super + Shift + V` | Lịch sử clipboard |
| `Super + Shift + B` | Bật/tắt chế độ tiết kiệm pin (perf-mode) |
| `Super + Shift + S` | Screenshot vùng chọn |
| `Print` | Screenshot toàn màn hình |

---

## Tuỳ chỉnh

Sửa `config/hypr/user.conf` để thay đổi:
- Hiệu ứng blur, dim, animation
- Cursor
- Biến môi trường

**Không sửa `hyprland.conf` trực tiếp** — dùng `user.conf` để override.

---

## Màu sắc tự động

Hệ thống dùng **pywal** để sinh màu từ wallpaper:
- Kitty terminal tự đổi màu khi đổi wallpaper
- Rofi launcher tự đổi màu theo
- Đổi wallpaper bằng `Super + W` hoặc lệnh `wal-pick`

---

## Roadmap

- [x] Phase 0 — Cấu trúc chuẩn, install script
- [x] Phase 1 — Kitty + Rofi + pywal integration
- [x] Phase 2 — Performance tuning Intel iGPU
- [x] Phase 3 — Waybar 3 đảo + Control Center (swaync) — Sakura Glass
- [x] Phase 4 — Hyprlock theme (Sakura Glass)
- [x] Phase 5 — Notification Center & Settings (SwayNC Control Center)
