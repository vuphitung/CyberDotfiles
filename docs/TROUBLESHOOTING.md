# Hướng Dẫn Vận Hành, Xử Lý Sự Cố & Khôi Phục (`TROUBLESHOOTING.md`)

Tài liệu này hướng dẫn cách thay đổi tỷ lệ hiển thị (scale) an toàn, kiểm tra sức khỏe hệ thống, xử lý các sự cố thường gặp và khôi phục cấu hình (rollback) trên Dell Latitude E7470 chạy Arch Linux + Hyprland 0.57.2.

## 1. Hướng Dẫn Thay Đổi Monitor Scale An Toàn

Trong kiến trúc CyberDotfiles v7, thông số màn hình được quản lý tập trung tại một nơi duy nhất: **`config/hypr/modules/options.lua`** (hoặc ghi đè cá nhân trong `config/hypr/user.lua`).

### 1.1. Các mức Scale khuyến nghị cho màn hình 2560×1440 (`eDP-1`)

| Mức Scale | Không gian hiển thị logic | Đặc điểm trên màn hình 14" (2560×1440) |
| :--- | :--- | :--- |
| **`1.25`** *(Mặc định v7)* | **2048 × 1152 px** | Không gian làm việc rộng rãi, sắc nét, chia đôi 2 cửa sổ code/trình duyệt thoải mái. |
| **`1.333333`** | **1920 × 1080 px** | Tương đương chuẩn Full HD 1080p, chữ to hơn một chút so với 1.25, chia nguyên 2560/1.333333. |
| **`1.5`** | **1706 × 960 px** | Chữ lớn, dễ đọc khi ngồi xa nhưng không gian hiển thị hẹp hơn. |
| **`1.6`** | **1600 × 900 px** | Chia chẵn 2560×1440, phù hợp nếu mắt mỏi khi làm việc ban đêm. |
| **`2.0`** *(Mặc định auto cũ)* | **1280 × 720 px** | Quá lớn trên màn hình 14", làm chật không gian hiển thị. |

### 1.2. Cách đổi Scale vĩnh viễn

1. Mở tệp `~/CyberDotfiles/config/hypr/modules/options.lua` (hoặc tạo/sửa `~/CyberDotfiles/config/hypr/user.lua`):
   ```lua
   -- Trong config/hypr/modules/options.lua:
   monitor = {
       primary = {
           output   = "eDP-1",
           mode     = "2560x1440@60",
           position = "0x0",
           scale    = 1.25, -- Đổi thành 1.333333 hoặc 1.5 tùy ý
       },
   }
   ```
2. Lưu tệp. Hyprland 0.57.2 sẽ tự động nạp lại, hoặc chạy lệnh:
   ```bash
   hyprctl reload
   ```
3. Xác minh kết quả thực tế:
   ```bash
   hyprctl monitors
   ```

## 2. Quy Trình Kiểm Thử & Xác Minh Runtime (Validation Checklist)

Chạy công cụ kiểm tra sức khỏe toàn diện:
```bash
python3 ~/CyberDotfiles/scripts/check_health.py
```

Hoặc kiểm tra từng thành phần bằng các lệnh chuẩn sau:

1. **Kiểm tra lỗi cấu hình Hyprland Lua**:
   ```bash
   hyprctl configerrors
   ```
2. **Kiểm tra độ phân giải và Scale màn hình**:
   ```bash
   hyprctl monitors | grep -E "Monitor|2560x1440|scale"
   ```
3. **Kiểm tra danh sách phím tắt đã nạp**:
   ```bash
   hyprctl binds -j | jq -r '.[] | "\(.modmask) \(.key) -> \(.description // .dispatcher)"' | head -n 30
   ```
4. **Kiểm tra các lớp kính mờ (Layer Rules)**:
   ```bash
   hyprctl layers
   ```
5. **Kiểm tra tiến trình nền (Đảm bảo mỗi daemon chỉ chạy 1 instance)**:
   ```bash
   ps -ef | grep -E "waybar|swaync|awww-daemon|fcitx5|hypridle|wl-paste|power-auto" | grep -v grep
   ```
6. **Kiểm tra log khởi động của CyberDotfiles v7**:
   ```bash
   cat ~/.cache/cyberdotfiles/startup.log
   ```

## 3. Xử Lý Các Sự Cố Thường Gặp

### 3.1. Lag / khựng khi dùng pin
- **Nguyên nhân đã đo trên Dell E7470**: `CPU_ENERGY_PERF_POLICY_ON_BAT=power` trong `/etc/tlp.conf` khiến CPU kẹt ~800 MHz kể cả khi full tải (`balance_performance` lên 3.2 GHz tức thì).
- **Cách sửa**: `install.sh` cài `system/tlp/90-cyber.conf` và comment hai dòng tên cũ trong `/etc/tlp.conf` (TLP >= 1.9 dịch tên cũ `_AC/_BAT` thành `_PRF/_BAL` và để chúng đè lên `tlp.d`).
- **Kiểm tra**: rút sạc rồi `cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference` phải ra `balance_performance`; `sudo tlp-stat -c | grep ENERGY_PERF` chỉ liệt kê file `90-cyber.conf`.
- **Không dùng** `power-profiles-daemon` cùng `tlp`. Chế độ Lite (tắt blur/shadow/animation khi pin <= 30%) do `scripts/power-auto.sh` lo, không cần PPD.

### 3.2. SwayNC không hiển thị hoặc bị kẹt
- **Nguyên nhân**: Có một tiến trình thông báo khác (như `dunst` hoặc `mako`) đang chiếm giữ D-Bus name `org.freedesktop.Notifications`.
- **Cách khắc phục**:
  ```bash
  pkill -x dunst mako swaync 2>/dev/null || true
  swaync & disown
  swaync-client -rs
  ```

### 3.3. Hình nền không đổi hoặc `awww` báo lỗi kết nối
- **Cách khắc phục**:
  ```bash
  bash ~/CyberDotfiles/scripts/wallpaper.sh
  ```
  Script `wallpaper.sh` v7 sẽ tự động kiểm tra socket `awww query`, khởi chạy duy nhất một `awww-daemon` nếu chưa có, và áp dụng lại ảnh gần nhất từ `~/.cache/wal/.last_wall` (hoặc chọn ngẫu nhiên từ `~/Pictures/Wallpapers`).

### 3.4. Chỉnh sửa màu sắc Sakura Glass bị lỗi hoặc muốn khôi phục
- Để sinh lại toàn bộ token màu từ `themes/sakura-glass.json`:
  ```bash
  python3 ~/CyberDotfiles/scripts/theme-gen.py
  ```
- Để khôi phục bản token màu gần nhất trước khi chạy `theme-gen.py`:
  ```bash
  python3 ~/CyberDotfiles/scripts/theme-gen.py --restore
  ```

## 4. Hướng Dẫn Rollback (Khôi Phục Về Cấu Hình v6 Cũ)

Nếu bạn muốn tạm thời quay lại cấu hình Hyprlang v6 (`hyprland.conf`) bất kỳ lúc nào:

```bash
# Cách 1: Vô hiệu hóa tạm thời entrypoint Lua để Hyprland nạp hyprland.conf
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.v7.bak
hyprctl reload

# Để bật lại kiến trúc Lua v7:
mv ~/.config/hypr/hyprland.lua.v7.bak ~/.config/hypr/hyprland.lua
hyprctl reload
```
