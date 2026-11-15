# CyberDotfiles v7 — Kiến Trúc Lua Native & Sakura Glass

> **Phiên bản mục tiêu**: Hyprland 0.57.2 · Arch Linux · Dell Latitude E7470 (Intel Core i7-6600U / Intel HD Graphics 520 / 8 GB RAM / eDP-1 2560×1440@60Hz)

## 1. Kết Quả Kiểm Toán Kiến Trúc Cũ (Phase 0 Audit & Root Cause Analysis)

Qua quá trình kiểm toán toàn bộ mã nguồn trong repository `CyberDotfiles` (commit `9439815`, nhánh `main`) và đối chiếu với tài liệu chính thức [Hyprland Wiki: Core](https://wiki.hypr.land/configuring/core/), chúng tôi xác định **6 nguyên nhân gốc rễ** gây ra các lỗi hiện tại trên hệ thống:

| STT | Vấn đề ghi nhận | Bằng chứng trong Repository | Nguyên nhân gốc rễ (Root Cause) |
| :--- | :--- | :--- | :--- |
| **1** | **Hyprland 0.57.2 bỏ qua toàn bộ cấu hình CyberTung v6** | Tồn tại song song `config/hypr/hyprland.conf` (tracked) và `config/hypr/hyprland.lua` (untracked `??`). | Từ Hyprland 0.55+, trình quản lý cửa sổ ưu tiên nạp `$XDG_CONFIG_HOME/hypr/hyprland.lua` ([Hyprland Wiki: Core](https://wiki.hypr.land/configuring/core/)). Vì `hyprland.lua` tồn tại trong `~/.config/hypr/`, Hyprland 0.57.2 chỉ nạp file mẫu `hyprland.lua` và bỏ qua hoàn toàn `hyprland.conf`. |
| **2** | **Nhấn `SUPER + SPACE` không mở Rofi; xung đột `SUPER + R`** | `hyprland.lua` dòng 36 khai báo `local menu = "hyprlauncher"` và dòng 225 bind `SUPER + R` cho `menu`, không có bind `SUPER + SPACE`. | `hyprland.lua` không có bind `SUPER + SPACE`. Đồng thời `SUPER + R` trong `hyprland.lua` gọi `hyprlauncher` (chưa cài đặt) và xung đột trực tiếp với submap `resize` (`SUPER + R`) trong `hyprland.conf` dòng 164. |
| **3** | **Màn hình `eDP-1` bị khóa ở `scale = 2.0` (1280×720 logic)** | `hyprland.lua` dòng 22–27 đặt `hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })`. | Panel AU Optronics `2560x1440` có kích thước vật lý `310x170 mm` (~210 PPI). Khi `scale = "auto"`, thuật toán PPI của Hyprland ([Hyprland Wiki: Monitors](https://wiki.hypr.land/configuring/core/monitors/)) tự động gán `scale = 2.0`. Rule `monitor = eDP-1, 2560x1440@60, 0x0, 1` trong `hyprland.conf` không được nạp. |
| **4** | **Waybar, SwayNC, Fcitx5, awww không tự khởi động cùng Hyprland** | `hyprland.lua` dòng 45–50 comment toàn bộ khối `-- hl.on("hyprland.start", ...)`. | Toàn bộ danh sách `exec-once` nằm trong `hyprland.conf` (bị bỏ qua), trong khi sự kiện `hyprland.start` ([Hyprland Wiki: Autostart](https://wiki.hypr.land/configuring/core/autostart/)) trong `hyprland.lua` đang bị đóng comment. |
| **5** | **SwayNC báo lỗi `notifications: Config not found!` & MPRIS null** | `config/swaync/config.json` dòng 31–68 liệt kê `"notifications"` trong `"widgets"` nhưng thiếu cấu hình trong `"widget-config"`. | SwayNC 0.12.6 tìm khóa `"notifications"` trong `"widget-config"` cho mọi phần tử khai báo trong `"widgets"`. Ngoài ra `"mpris"` chưa bật `"autohide": true`, dẫn tới cảnh báo metadata `null` khi không có trình phát nhạc hoạt động. |
| **6** | **Theme Engine chưa hỗ trợ Lua & thiếu cơ chế bảo vệ/backup** | `scripts/theme-gen.py` chỉ sinh `tokens.conf` (Hyprlang), `tokens.css`, `tokens.rasi`, `sakura-glass.conf`. | Chưa sinh module Lua (`config/hypr/themes/tokens.lua`), chưa kiểm tra tính hợp lệ (schema validation) của `themes/sakura-glass.json`, và chưa tạo bản sao lưu trước khi ghi đè. |

## 2. Kiến Trúc CyberDotfiles v7 (Lua Native Architecture)

Kiến trúc v7 loại bỏ hoàn toàn tình trạng hai hệ cấu hình chồng chéo, đưa `config/hypr/hyprland.lua` trở thành entrypoint duy nhất cho Hyprland 0.57.2, đồng thời giữ lại `config/hypr/hyprland.conf` (đổi tên hoặc giữ làm tài liệu tham chiếu/migration source an toàn) và `config/hypr/tokens.conf` (phục vụ riêng cho `hyprlock.conf`).

### 2.1. Cấu Trúc Thư Mục Toàn Hệ Thống

```
CyberDotfiles/
├── config/
│   ├── hypr/
│   │   ├── hyprland.lua              # Entrypoint duy nhất của Hyprland 0.57.2
│   │   ├── user.lua                  # Override cá nhân (tùy chọn, nạp cuối cùng qua pcall)
│   │   ├── modules/
│   │   │   ├── init.lua              # Bộ điều phối nạp module an toàn (pcall + thông báo lỗi)
│   │   │   ├── options.lua           # Nguồn cấu hình tập trung (scale, màn hình, app, hiệu năng)
│   │   │   ├── environment.lua       # Biến môi trường (Fcitx5, Cursor, Wayland toolkits)
│   │   │   ├── monitor.lua           # Quản lý màn hình eDP-1 (scale 1.25) + fallback màn hình rời
│   │   │   ├── input.lua             # Bàn phím, chuột, touchpad, cử chỉ 3 ngón (hl.gesture)
│   │   │   ├── appearance.lua        # Giao diện Sakura Glass, blur, shadow, cursor, dwindle, misc
│   │   │   ├── animations.lua        # Đường cong Bezier (hl.curve) & hoạt ảnh tối ưu HD 520
│   │   │   ├── workspaces.lua        # Quy tắc workspace (hl.workspace_rule)
│   │   │   ├── window-rules.lua      # Quy tắc cửa sổ (hl.window_rule) theo class/title thực tế
│   │   │   ├── layer-rules.lua       # Kính mờ cho Waybar, Rofi, SwayNC, Wlogout (hl.layer_rule)
│   │   │   ├── binds.lua             # Hệ thống phím tắt đầy đủ + submap resize (hl.define_submap)
│   │   │   └── autostart.lua         # Khởi động phiên làm việc qua hl.on("hyprland.start", ...)
│   │   ├── themes/
│   │   │   └── tokens.lua            # [AUTO-GENERATED] Bảng màu Sakura Glass cho Lua
│   │   ├── tokens.conf               # [AUTO-GENERATED] Biến màu cho hyprlock.conf
│   │   ├── hyprlock.conf             # Cấu hình màn hình khóa Sakura Glass
│   │   ├── hypridle.conf             # Cấu hình quản lý trạng thái nghỉ (lock/dpms/suspend)
│   │   ├── hyprland.conf             # [REFERENCE ONLY] Lưu trữ cấu hình v6 để đối chiếu/rollback
│   │   └── user.conf                 # [REFERENCE ONLY] Lưu trữ cấu hình user v6
│   ├── waybar/
│   │   ├── config.jsonc              # Cấu hình 3 đảo nổi (Floating Islands)
│   │   ├── style.css                 # Giao diện GTK3 CSS Sakura Glass
│   │   └── tokens.css                # [AUTO-GENERATED] Token màu GTK3 CSS
│   ├── swaync/
│   │   ├── config.json               # Cấu hình trung tâm thông báo & control center
│   │   ├── style.css                 # Giao diện GTK3 CSS cho SwayNC
│   │   └── tokens.css                # [AUTO-GENERATED] Token màu GTK3 CSS
│   ├── rofi/
│   │   ├── config.rasi               # Cấu hình Rofi App Launcher & Clipboard
│   │   └── tokens.rasi               # [AUTO-GENERATED] Token màu RASI
│   ├── kitty/
│   │   ├── kitty.conf                # Cấu hình Kitty terminal + tích hợp pywal
│   │   └── sakura-glass.conf         # [AUTO-GENERATED] Màu nền/chữ/con trỏ Sakura Glass
│   ├── wlogout/
│   │   ├── layout                    # Bố cục 6 nút nguồn
│   │   ├── style.css                 # Giao diện menu nguồn Sakura Glass
│   │   └── tokens.css                # [AUTO-GENERATED] Token màu GTK3 CSS
│   └── nano/
│       └── nanorc                    # Cấu hình trình soạn thảo Nano
├── scripts/
│   ├── startup.sh                    # Orchestrator khởi động daemon theo thứ tự, chống chạy trùng
│   ├── app-launch.sh                 # Helper mở ứng dụng có fallback an toàn (file manager/browser/launcher)
│   ├── theme-gen.py                  # Trình sinh mã màu tập trung (validation + backup + restore)
│   ├── wallpaper.sh                  # Quản lý hình nền awww + pywal + bảo toàn cache
│   ├── wall-picker.sh                # Giao diện chọn hình nền PRISM TUI
│   ├── power-auto.sh                 # Tự động chuyển power profile theo nguồn sạc (AC/Battery)
│   ├── perf-mode.sh                  # Bật/tắt chế độ tiết kiệm pin cho Intel HD 520
│   ├── keyhints.sh                   # Hiển thị bảng phím tắt runtime từ `hyprctl binds -j`
│   ├── check_health.py               # Kiểm toán sức khỏe hệ thống v7 (hỗ trợ Lua native)
│   ├── fix_symlinks.sh               # Khôi phục và xác minh toàn bộ symlink
│   ├── setup_all.sh                  # Kiểm tra xung đột dịch vụ và driver Intel VA-API
│   └── iwlwifi-fix.sh                # Tối ưu ổn định Wi-Fi Intel
├── themes/
│   └── sakura-glass.json             # Nguồn dữ liệu màu và typography duy nhất (Single Source of Truth)
├── docs/
│   ├── ARCHITECTURE_V7.md            # Tài liệu kiến trúc hệ thống v7
│   ├── MIGRATION_LUA.md              # Tài liệu chuyển đổi Hyprlang sang Hyprland 0.57.2 Lua
│   ├── KEYBIND_REFERENCE.md          # Bảng tham chiếu phím tắt đầy đủ
│   ├── TROUBLESHOOTING.md            # Hướng dẫn chẩn đoán lỗi, thay đổi scale & rollback
│   └── keybinds.md                   # Bản tóm tắt nhanh phím tắt
├── shell/
│   ├── aliases.sh                    # Bí danh Zsh cập nhật cho v7 (`hconf` mở `hyprland.lua`)
│   └── starship.toml                 # Cấu hình Starship prompt
└── install.sh                        # Script cài đặt và kiểm tra an toàn
```

### 2.2. Nguyên Tắc Thiết Kế Module & Cơ Chế Nạp (`require`) Trên Hyprland 0.57.2

Theo tài liệu [Hyprland Wiki: Core - Require](https://wiki.hypr.land/configuring/core/#require), Hyprland 0.57.2 tùy biến hàm `require` để mỗi tệp được nạp chạy trong một phạm vi (scope) bảo vệ riêng, đồng thời giữ hàm `require` gốc của Lua dưới tên `__require`.

Để đảm bảo:
1. **Chia sẻ dữ liệu cấu hình tập trung** (`themes/tokens.lua` và `modules/options.lua`) giữa các module mà không bị ảnh hưởng bởi việc tách scope của Hyprland.
2. **Cô lập lỗi (Fault Isolation)**: Một module gặp lỗi cú pháp hoặc runtime không được làm sập toàn bộ phiên Hyprland hay làm mất phím tắt.

Kiến trúc CyberDotfiles v7 áp dụng mô hình 2 tầng trong `config/hypr/modules/init.lua`:
- **Tầng Dữ Liệu (`themes/tokens.lua`, `modules/options.lua`)**: Sử dụng hàm nạp ưu tiên `__require` (hoặc `require` chuẩn) kết hợp đăng ký vào bảng toàn cục `_G.CyberTokens` và `_G.CyberOptions`. Mọi module con đều đọc thông số từ `modules/options.lua` và `themes/tokens.lua` thông qua helper `opts.get()`, đảm bảo không hardcode giá trị rải rác.
- **Tầng Thực Thi (`environment`, `monitor`, `input`, `appearance`, `animations`, `workspaces`, `window-rules`, `layer-rules`, `binds`, `autostart`, `user`)**: Nạp tuần tự theo thứ tự phụ thuộc bằng `pcall(require, module_name)`. Nếu một module phát sinh lỗi, `init.lua` ghi nhận lỗi vào danh sách chẩn đoán và gửi thông báo qua `notify-send` khi phiên khởi động xong, nhưng các module còn lại (đặc biệt là `monitor` và `binds`) vẫn hoạt động bình thường.

## 3. Vòng Đời Khởi Động (Autostart Lifecycle)

Thay vì gọi hàng loạt lệnh rời rạc hoặc dùng `sleep` ngẫu nhiên trong cấu hình Hyprland, module `config/hypr/modules/autostart.lua` lắng nghe sự kiện chính thức `hl.on("hyprland.start", ...)` ([Hyprland Wiki: Autostart](https://wiki.hypr.land/configuring/core/autostart/)) và kích hoạt duy nhất trình điều phối `scripts/startup.sh`.

Luồng khởi động trong `scripts/startup.sh` được chia làm 4 pha có kiểm soát:
1. **Pha 1 — Đồng bộ môi trường D-Bus & Systemd**:
   - Chạy `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XCURSOR_THEME XCURSOR_SIZE QT_IM_MODULE GTK_IM_MODULE XMODIFIERS` để các dịch vụ D-Bus/Systemd nhận đúng biến môi trường trước khi khởi chạy UI.
2. **Pha 2 — Bảo mật & Daemon Nền Tảng**:
   - Khởi động `hyprpolkitagent` qua `systemctl --user start hyprpolkitagent` (hoặc thực thi trực tiếp binary nếu service unit không tồn tại).
   - Khởi động `awww-daemon` (hoặc `swww-daemon` fallback) chỉ khi chưa có tiến trình nào đang chạy (`pgrep -x`), sau đó gọi `scripts/wallpaper.sh` (script này tự kiểm tra phản hồi IPC bằng `awww query` tối đa 5 giây thay vì `sleep` mù quáng).
3. **Pha 3 — Dịch Vụ Giao Diện & Tiện Ích**:
   - Khởi động `swaync` (kiểm tra trước `pgrep -x swaync` để tránh xung đột với D-Bus activation).
   - Khởi động `waybar` (đảm bảo duy nhất 1 tiến trình `pgrep -x waybar`).
   - Khởi động bộ gõ tiếng Việt `fcitx5 -d --replace` (nếu đã cài đặt).
   - Khởi động quản lý nghỉ `hypridle` (nếu chưa chạy).
   - Khởi động trình lưu lịch sử clipboard `wl-paste --type text --watch cliphist store` và `wl-paste --type image --watch cliphist store` (chỉ khi cả `wl-paste` và `cliphist` tồn tại và chưa chạy).
4. **Pha 4 — Quản Lý Năng Lượng**:
   - Khởi động `scripts/power-auto.sh` (tự động kiểm tra sự hiện diện của `powerprofilesctl` và dịch vụ `power-profiles-daemon` trước khi lắng nghe sự kiện `udevadm`).
   - Mọi bước khởi động đều được ghi log chi tiết kèm dấu thời gian vào `~/.cache/cyberdotfiles/startup.log` để dễ dàng chẩn đoán.

## 4. Luồng Dữ Liệu Theme Engine (Sakura Glass Single Source of Truth)

```
themes/sakura-glass.json (Nguồn dữ liệu duy nhất: Màu sắc, Opacity, Font, Blur, Border)
        │
        ▼
scripts/theme-gen.py (Kiểm tra schema JSON + Tạo bản sao lưu ~/.cache/cyberdotfiles/theme-backups/)
        │
        ├──► config/hypr/themes/tokens.lua   (Bảng màu Lua native cho Hyprland 0.57.2)
        ├──► config/hypr/tokens.conf         (Biến màu Hyprlang cho hyprlock.conf)
        ├──► config/waybar/tokens.css        (Biến @define-color GTK3 cho Waybar)
        ├──► config/swaync/tokens.css        (Biến @define-color GTK3 cho SwayNC)
        ├──► config/wlogout/tokens.css       (Biến @define-color GTK3 cho Wlogout)
        ├──► config/rofi/tokens.rasi         (Biến màu #RRGGBBAA cho Rofi)
        └──► config/kitty/sakura-glass.conf  (Màu giao diện và độ trong suốt cho Kitty)
```

## 5. Chiến Lược Khôi Phục (Rollback Strategy)

Hệ thống cung cấp 3 cấp độ khôi phục an toàn:
1. **Khôi phục cấu hình Hyprland tức thì (chuyển về v6 `hyprland.conf`)**:
   - Chỉ cần đổi tên `config/hypr/hyprland.lua` thành `config/hypr/hyprland.lua.disabled` và chạy `hyprctl reload` (hoặc khởi động với `start-hyprland -- --config ~/.config/hypr/hyprland.conf`).
2. **Khôi phục Theme Token trước đó**:
   - Chạy `python3 ~/CyberDotfiles/scripts/theme-gen.py --restore` để tự động phục hồi các file token từ bản sao lưu gần nhất trong `~/.cache/cyberdotfiles/theme-backups/`.
3. **Khôi phục toàn bộ Repository từ bản Backup trước nâng cấp**:
   - Bản sao lưu nguyên trạng trước khi nâng cấp được lưu độc lập ngoài repository. Có thể khôi phục bằng một lệnh `cp -a` mà không làm mất bất kỳ file cá nhân nào.
