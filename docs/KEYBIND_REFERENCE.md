# Bảng Tham Chiếu Phím Tắt — CyberDotfiles v7 (`KEYBIND_REFERENCE.md`)

> **Mẹo tra cứu nhanh**: Nhấn `Super + F1` bất kỳ lúc nào trong phiên Hyprland để mở bảng tra cứu phím tắt trực tiếp trên Rofi (đọc dữ liệu thời gian thực từ `hyprctl binds -j`).

## 1. Ứng Dụng & Tiện Ích Chính

| Tổ hợp phím | Chức năng | Dispatcher / Lệnh thực thi | Cơ chế Fallback |
| :--- | :--- | :--- | :--- |
| `Super + Space` | Mở trình tìm kiếm ứng dụng (App Launcher) | `rofi -show drun` | Fallback sang `fuzzel` hoặc `wofi` qua `app-launch.sh` nếu chỉ định |
| `Super + Q` | Mở Terminal | `kitty` | Fallback sang `foot`, `alacritty`, `xterm` |
| `Super + E` | Mở trình quản lý tệp (File Manager) | `scripts/app-launch.sh file-manager` | Tự động ưu tiên `nautilus` → `dolphin` → `thunar` → `pcmanfm` → `kitty -e yazi` |
| `Super + G` | Mở trình duyệt web (Browser) | `scripts/app-launch.sh browser` | Tự động ưu tiên `google-chrome-stable` → `google-chrome` → `chromium` → `firefox` |
| `Super + W` | Mở bộ chọn hình nền (PRISM Wallpaper Picker) | `kitty --class wall-picker ~/CyberDotfiles/scripts/wall-picker.sh` | Nếu thiếu `fzf`/`magick`, tự động đổi ảnh ngẫu nhiên qua `wallpaper.sh` |
| `Super + F1` | Xem danh sách phím tắt (Keybind Help) | `~/CyberDotfiles/scripts/keyhints.sh` | Đọc trực tiếp từ `hyprctl binds -j` và hiển thị qua Rofi |

## 2. Quản Lý Cửa Sổ & Bố Cục (Dwindle Layout)

| Tổ hợp phím | Chức năng | Dispatcher Lua (`hl.dsp.*`) | Ghi chú |
| :--- | :--- | :--- | :--- |
| `Super + C` | Đóng cửa sổ đang active | `hl.dsp.window.close()` | Đóng an toàn (graceful close) |
| `Super + F` | Bật/tắt toàn màn hình (Fullscreen) | `hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" })` | Tương đương `fullscreen, 0` |
| `Super + V` | Bật/tắt cửa sổ nổi (Floating) | `hl.dsp.window.float({ action = "toggle" })` | Chuyển đổi giữa Tiled và Floating |
| `Super + J` | Đổi hướng chia cửa sổ (Toggle Split) | `hl.dsp.layout("togglesplit")` | Dành cho bố cục `dwindle` |
| `Super + Left` | Di chuyển tiêu điểm (Focus) sang trái | `hl.dsp.focus({ direction = "left" })` | Phím mũi tên trái |
| `Super + Right` | Di chuyển tiêu điểm (Focus) sang phải | `hl.dsp.focus({ direction = "right" })` | Phím mũi tên phải |
| `Super + Up` | Di chuyển tiêu điểm (Focus) lên trên | `hl.dsp.focus({ direction = "up" })` | Phím mũi tên lên |
| `Super + Down` | Di chuyển tiêu điểm (Focus) xuống dưới | `hl.dsp.focus({ direction = "down" })` | Phím mũi tên xuống |
| `Super + LMB (Chuột trái)` | Kéo di chuyển cửa sổ | `hl.dsp.window.drag()` (`{ mouse = true }`) | `mouse:272` |
| `Super + RMB (Chuột phải)` | Kéo thay đổi kích thước cửa sổ | `hl.dsp.window.resize()` (`{ mouse = true }`) | `mouse:273` |

## 3. Chế Độ Thay Đổi Kích Thước Bằng Bàn Phím (Resize Submap)

> **Giải quyết xung đột v6 vs Lua mẫu**: Trong file Lua mẫu tự sinh, `Super + R` bị gán cho `hyprlauncher` (gây lỗi vì chưa cài đặt và đè lên phím tắt Resize của v6). Trong CyberDotfiles v7, `Super + Space` đảm nhiệm mở Rofi và `Super + R` được khôi phục đúng cho `submap("resize")`.

| Tổ hợp phím | Chức năng | Dispatcher Lua (`hl.dsp.*`) |
| :--- | :--- | :--- |
| `Super + R` | Vào chế độ thay đổi kích thước (`resize` submap) | `hl.dsp.submap("resize")` |
| `Right` *(trong submap)* | Tăng chiều rộng cửa sổ (+10px) | `hl.dsp.window.resize({ x = 10, y = 0, relative = true })` (`repeating = true`) |
| `Left` *(trong submap)* | Giảm chiều rộng cửa sổ (-10px) | `hl.dsp.window.resize({ x = -10, y = 0, relative = true })` (`repeating = true`) |
| `Up` *(trong submap)* | Giảm chiều cao cửa sổ (-10px) | `hl.dsp.window.resize({ x = 0, y = -10, relative = true })` (`repeating = true`) |
| `Down` *(trong submap)* | Tăng chiều cao cửa sổ (+10px) | `hl.dsp.window.resize({ x = 0, y = 10, relative = true })` (`repeating = true`) |
| `Escape` / `Enter` *(trong submap)* | Thoát chế độ resize về mặc định | `hl.dsp.submap("reset")` |

## 4. Không Gian Làm Việc (Workspaces & Scratchpad)

| Tổ hợp phím | Chức năng | Dispatcher Lua (`hl.dsp.*`) |
| :--- | :--- | :--- |
| `Super + 1..6` | Chuyển sang Workspace 1..6 | `hl.dsp.focus({ workspace = 1..6 })` |
| `Super + 7..9, 0` | Chuyển sang Workspace 7..10 | `hl.dsp.focus({ workspace = 7..10 })` |
| `Super + Shift + 1..6` | Đưa cửa sổ hiện tại sang Workspace 1..6 | `hl.dsp.window.move({ workspace = 1..6 })` |
| `Super + Shift + 7..9, 0` | Đưa cửa sổ hiện tại sang Workspace 7..10 | `hl.dsp.window.move({ workspace = 7..10 })` |
| `Super + Tab` | Chuyển về Workspace trước đó | `hl.dsp.focus({ workspace = "previous" })` |
| `Super + Cuộn chuột xuống` | Chuyển sang Workspace kế tiếp đang mở | `hl.dsp.focus({ workspace = "e+1" })` |
| `Super + Cuộn chuột lên` | Chuyển về Workspace liền trước đang mở | `hl.dsp.focus({ workspace = "e-1" })` |
| `Super + S` | Bật/tắt ngăn kéo ẩn (Special Workspace `magic`) | `hl.dsp.workspace.toggle_special("magic")` |
| `Super + Alt + S` | Đưa cửa sổ vào ngăn kéo ẩn (`special:magic`) | `hl.dsp.window.move({ workspace = "special:magic" })` |

*(Lưu ý: `Super + Shift + S` được dành riêng cho chụp ảnh màn hình vùng chọn theo đúng chuẩn v6; việc đưa cửa sổ vào ngăn kéo ẩn `special:magic` được chuyển sang `Super + Alt + S` để loại bỏ hoàn toàn xung đột với Screenshot).*

## 5. Hệ Thống, Thông Báo, Clipboard & Chụp Màn Hình

| Tổ hợp phím | Chức năng | Lệnh thực thi |
| :--- | :--- | :--- |
| `Super + I` | Bật/tắt trung tâm thông báo (SwayNC) | `swaync-client -t -sw` |
| `Super + B` | Mở bảng điều khiển nhanh (SwayNC Control Center) | `swaync-client -t -sw` |
| `Super + Shift + V` | Lịch sử Clipboard (Cliphist + Rofi) | `bash -c 'cliphist list | rofi -dmenu -i -p "Clipboard" | cliphist decode | wl-copy'` |
| `Super + Shift + B` | Bật/tắt chế độ tiết kiệm pin (Performance Mode) | `~/CyberDotfiles/scripts/power-auto.sh toggle` |
| `Super + Shift + S` | Chụp ảnh màn hình vùng chọn (Screenshot Area) | `grimblast --notify copysave area ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png` |
| `Print` | Chụp ảnh toàn màn hình (Screenshot Screen) | `grimblast --notify copysave screen ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png` |
| `Super + P` | Khóa màn hình ngay lập tức (Hyprlock) | `loginctl lock-session` |
| `Super + L` | Mở menu nguồn (Wlogout) | `wlogout` |
| `Super + Ctrl + Shift + Q` | Thoát khẩn cấp phiên Hyprland | `hl.dsp.exit()` |

## 6. Phím Đa Phương Tiện & Độ Sáng (Hoạt Động Cả Khi Khóa Màn Hình)

| Phím | Chức năng | Lệnh thực thi | Cờ Bind |
| :--- | :--- | :--- | :--- |
| `XF86AudioRaiseVolume` | Tăng âm lượng loa (+5%, giới hạn 100%) | `wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+` | `locked`, `repeating` |
| `XF86AudioLowerVolume` | Giảm âm lượng loa (-5%) | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` | `locked`, `repeating` |
| `XF86AudioMute` | Bật/tắt tiếng loa (Mute) | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | `locked` |
| `XF86AudioMicMute` | Bật/tắt micro (Mic Mute) | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` | `locked` |
| `XF86AudioPlay` / `XF86AudioPause` | Phát / Tạm dừng nhạc | `playerctl play-pause` | `locked` |
| `XF86AudioNext` | Bài tiếp theo | `playerctl next` | `locked` |
| `XF86AudioPrev` | Bài trước đó | `playerctl previous` | `locked` |
| `XF86MonBrightnessUp` | Tăng độ sáng màn hình (+5%) | `brightnessctl -e4 -n2 set 5%+` | `locked`, `repeating` |
| `XF86MonBrightnessDown` | Giảm độ sáng màn hình (-5%) | `brightnessctl -e4 -n2 set 5%-` | `locked`, `repeating` |
