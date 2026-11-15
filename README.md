# CyberDotfiles v7 — Lua Native Architecture & Sakura Glass

Hệ thống cấu hình Desktop hoàn chỉnh cho **Arch Linux + Hyprland 0.57.2 (Lua Native)**.  
Được thiết kế và tối ưu chuyên biệt cho **Dell Latitude E7470** (**Intel Core i7-6600U · Intel HD Graphics 520 · 8 GB RAM · Màn hình eDP-1 2560×1440@60Hz, Scale 1.25 / Logic 2048×1152**).

## Điểm Mới Trong Phiên Bản v7

- **Kiến trúc Lua Native 100% (`config/hypr/hyprland.lua`)**: Chuyển đổi toàn bộ cấu hình sang Lua API chính thức của Hyprland 0.57.2, chia thành các module độc lập có cơ chế cô lập lỗi (`pcall`) trong `config/hypr/modules/`.
- **Màn hình 2560×1440 ở Scale 1.25**: Khắc phục triệt để lỗi tự động nhảy `scale = 2.0` (1280×720) do `scale = "auto"`, mở rộng không gian hiển thị logic lên **2048×1152** sắc nét.
- **Khởi động Phiên Làm Việc Tự Động & Chống Trùng Lặp (`scripts/startup.sh`)**: Tự động khởi chạy `hyprpolkitagent`, `swaync`, `waybar`, `awww-daemon`, `wallpaper.sh`, `fcitx5`, `hypridle`, `cliphist` và `power-auto.sh` qua sự kiện `hl.on("hyprland.start", ...)` với khóa `flock` chống trùng lặp.
- **Theme Engine Nguồn Đơn (`themes/sakura-glass.json` + `scripts/theme-gen.py`)**: Tự động kiểm tra tính hợp lệ (schema validation), sao lưu trước khi ghi, và sinh đồng bộ 7 tệp token cho Hyprland Lua (`tokens.lua`), Hyprlock (`tokens.conf`), Waybar, SwayNC, Wlogout (`tokens.css`), Rofi (`tokens.rasi`) và Kitty (`sakura-glass.conf`).
- **Tối Ưu Hiệu Năng Intel HD Graphics 520**: Giữ Kawase blur nhẹ (`size = 4`, `passes = 2`, `xray = true`, `new_optimizations = true`), bảo toàn Hardware Cursors (Direct Scanout) và bật Variable Frame Rate (`vfr = true`).

## Cấu Trúc Thư Mục

```
CyberDotfiles/
├── config/
│   ├── hypr/
│   │   ├── hyprland.lua          ← Entrypoint Lua duy nhất cho Hyprland 0.57.2
│   │   ├── user.lua              ← Ghi đè cá nhân (nạp cuối cùng)
│   │   ├── modules/              ← 12 module Lua (options, monitor, binds, rules, autostart...)
│   │   ├── themes/tokens.lua     ← Token màu Sakura Glass cho Lua (sinh tự động)
│   │   ├── tokens.conf           ← Token màu cho hyprlock.conf (sinh tự động)
│   │   ├── hyprlock.conf         ← Màn hình khóa Sakura Glass
│   │   ├── hypridle.conf         ← Quản lý nghỉ & tự động khóa màn hình
│   │   └── hyprland.conf         ← Lưu trữ tham chiếu từ bản v6
│   ├── waybar/                   ← Top bar 3 đảo nổi (Floating Islands)
│   ├── swaync/                   ← Trung tâm thông báo & bảng điều khiển nhanh
│   ├── rofi/                     ← App launcher & Clipboard Sakura Glass
│   ├── kitty/                    ← Terminal tích hợp Sakura Glass + Pywal
│   ├── wlogout/                  ← Menu nguồn Sakura Glass
│   └── nano/                     ← Cấu hình Nano editor
├── scripts/
│   ├── startup.sh                ← Trình điều phối khởi động phiên làm việc
│   ├── app-launch.sh             ← Mở ứng dụng với cơ chế fallback tự động
│   ├── theme-gen.py              ← Trình sinh mã màu tập trung (validation + backup + restore)
│   ├── wallpaper.sh              ← Quản lý hình nền awww + pywal
│   ├── wall-picker.sh            ← Bộ chọn hình nền PRISM TUI
│   ├── power-auto.sh             ← Power profile + chế độ Lite tự động theo sạc/pin (<=30%)
│   ├── screenshot.sh / lagcheck.sh ← Chụp ảnh nhẹ / chẩn đoán lag
│   ├── keyhints.sh               ← Bảng tra cứu phím tắt trực tiếp từ runtime
│   └── check_health.py           ← Kiểm toán toàn diện hệ thống v7
├── themes/
│   └── sakura-glass.json         ← Nguồn dữ liệu màu sắc & font duy nhất
├── docs/
│   ├── ARCHITECTURE_V7.md        ← Tài liệu thiết kế kiến trúc v7
│   ├── MIGRATION_LUA.md          ← Hướng dẫn chuyển đổi Hyprlang sang Lua 0.57.2
│   ├── KEYBIND_REFERENCE.md      ← Tài liệu tham chiếu phím tắt đầy đủ
│   └── TROUBLESHOOTING.md        ← Hướng dẫn đổi scale, chẩn đoán & rollback
└── install.sh
```

## Vận Hành Nhanh

1. **Sinh lại bộ mã màu Sakura Glass**:
   ```bash
   python3 ~/CyberDotfiles/scripts/theme-gen.py
   ```
2. **Nạp lại cấu hình Hyprland 0.57.2 và kiểm tra lỗi**:
   ```bash
   hyprctl reload && hyprctl configerrors
   ```
3. **Kiểm tra sức khỏe toàn hệ thống**:
   ```bash
   python3 ~/CyberDotfiles/scripts/check_health.py
   ```
4. **Thay đổi tỷ lệ Scale màn hình**:
   Sửa trường `monitor.primary.scale` trong `config/hypr/modules/options.lua` (mặc định `1.25`, có thể đổi sang `1.333333` hoặc `1.5`) rồi chạy `hyprctl reload`.
