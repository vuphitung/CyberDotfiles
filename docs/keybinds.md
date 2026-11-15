# Keybinds — CyberDotfiles v7 (Lua Native)

> Danh sách đầy đủ và luôn cập nhật: nhấn `Super + F1` trong Hyprland hoặc xem chi tiết tại `docs/KEYBIND_REFERENCE.md`.

## Ứng dụng chính
| Phím | Lệnh / Dispatcher |
|---|---|
| `Super + Space` | `rofi -show drun` (Tìm kiếm ứng dụng) |
| `Super + Q` | `kitty` (Mở Terminal) |
| `Super + E` | `scripts/app-launch.sh file-manager` (`nautilus` / `dolphin` / `thunar`) |
| `Super + G` | `scripts/app-launch.sh browser` (`google-chrome-stable` / `chromium` / `firefox`) |

## Cửa sổ & Hệ thống
| Phím | Lệnh / Dispatcher |
|---|---|
| `Super + C` | `hl.dsp.window.close()` (Đóng cửa sổ) |
| `Super + F` | `hl.dsp.window.fullscreen()` (Toàn màn hình) |
| `Super + V` | `hl.dsp.window.float()` (Bật/tắt cửa sổ nổi) |
| `Super + J` | `hl.dsp.layout("togglesplit")` (Đổi hướng chia Dwindle) |
| `Super + L` | `wlogout` (Menu nguồn) |
| `Super + P` | `loginctl lock-session` (Khóa màn hình Hyprlock) |
| `Super + I` | `swaync-client -t -sw` (Trung tâm thông báo) |
| `Super + B` | `swaync-client -t -sw` (Bảng điều khiển nhanh) |
| `Super + W` | `wall-picker.sh` (Bộ chọn hình nền PRISM) |
| `Super + F1` | `keyhints.sh` (Bảng tra cứu phím tắt) |
| `Super + Tab` | `hl.dsp.focus({ workspace = "previous" })` |
| `Super + R` | `hl.dsp.submap("resize")` (Mũi tên để chỉnh cỡ, `Esc`/`Enter` để thoát) |
| `Super + Shift + V` | `cliphist` + `rofi` (Lịch sử clipboard) |
| `Super + Shift + B` | `power-auto.sh toggle` (ép chế độ Lite) |
| `Super + Ctrl + Shift + Q` | `hl.dsp.exit()` (Thoát khẩn cấp Hyprland) |

## Workspaces & Scratchpad
| Phím | Lệnh / Dispatcher |
|---|---|
| `Super + 1–6` | Chuyển sang Workspace 1–6 |
| `Super + Shift + 1–6` | Đưa cửa sổ sang Workspace 1–6 |
| `Super + S` | Bật/tắt ngăn kéo ẩn (`special:magic`) |
| `Super + Alt + S` | Đưa cửa sổ vào ngăn kéo ẩn (`special:magic`) |

## Chụp màn hình & Đa phương tiện
| Phím | Lệnh |
|---|---|
| `Super + Shift + S` | `grimblast --notify copysave area` |
| `Print` | `grimblast --notify copysave screen` |
| `XF86AudioRaiseVolume` / `LowerVolume` | Âm lượng loa `+5%` / `-5%` |
| `XF86AudioMute` / `MicMute` | Tắt/bật tiếng loa / Micro |
| `XF86AudioPlay` / `Next` / `Prev` | Điều khiển nhạc (`playerctl`) |
| `XF86MonBrightnessUp` / `Down` | Độ sáng màn hình `+5%` / `-5%` |
