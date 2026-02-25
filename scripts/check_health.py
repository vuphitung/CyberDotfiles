import os
import shutil

# Danh sách các file/folder "sống còn" của bộ Cyber Green
REQUIRED_STUFF = {
    "Hyprland Config": "~/.config/hypr/hyprland.conf",
    "Waybar Config": "~/.config/waybar/config.jsonc",
    "Waybar Style": "~/.config/waybar/style.css",
    "Wlogout Layout": "~/.config/wlogout/layout",
    "Pywal Colors": "~/.cache/wal/colors-waybar.css"
}

# Danh sách các app bắt buộc phải có để hệ thống chạy
REQUIRED_APPS = ["hyprland", "waybar", "wal", "wlogout", "swww", "kitty"]

def check_system():
    print("=== 🛠️  ĐANG KIỂM TRA HỆ THỐNG CỦA TÙNG ===\n")
    
    # 1. Kiểm tra File
    print("📂 Kiểm tra cấu hình:")
    missing_files = 0
    for name, path in REQUIRED_STUFF.items():
        full_path = os.path.expanduser(path)
        if os.path.exists(full_path):
            print(f"  ✅ {name:15} : Đã tìm thấy")
        else:
            print(f"  ❌ {name:15} : THIẾU ({path})")
            missing_files += 1

    # 2. Kiểm tra App
    print("\n📦 Kiểm tra phần mềm:")
    missing_apps = 0
    for app in REQUIRED_APPS:
        if shutil.which(app):
            print(f"  ✅ {app:15} : Đã cài đặt")
        else:
            print(f"  ⚠️ {app:15} : CHƯA CÀI")
            missing_apps += 1

    # 3. Kết luận
    print("\n=== 📝 KẾT QUẢ ===")
    if missing_files == 0 and missing_apps == 0:
        print("🔥 TUYỆT VỜI! Hệ thống của ông đã sẵn sàng để đóng gói.")
        print("👉 Bước tiếp theo: Tạo repo GitHub và push lên thôi!")
    else:
        print(f"⚠️ Cần xử lý {missing_files} file thiếu và {missing_apps} app chưa cài.")

if __name__ == "__main__":
    check_system()
