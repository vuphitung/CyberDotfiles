#!/usr/bin/env python3
# ============================================================
# check_health.py — CyberTung System Health Check v2.0
# ============================================================

import os
import shutil
import subprocess

# Config files cần thiết
REQUIRED_FILES = {
    "Hyprland Config":   "~/.config/hypr/hyprland.conf",
    "Waybar Config":     "~/.config/waybar/config.jsonc",
    "Waybar Style":      "~/.config/waybar/style.css",
    "Wlogout Layout":    "~/.config/wlogout/layout",
    "Pywal Colors":      "~/.cache/wal/colors-waybar.css",
}

# Scripts cần thiết (v2.0)
REQUIRED_SCRIPTS = {
    "smartd.sh":         "~/CyberDotfiles/scripts/smartd.sh",
    "apps.sh":           "~/CyberDotfiles/scripts/apps.sh",
    "purge.sh":          "~/CyberDotfiles/scripts/purge.sh",
    "cyberguard_v2.sh":  "~/CyberDotfiles/scripts/cyberguard_v2.sh",
}

# Apps cần cài
REQUIRED_APPS = [
    "hyprland", "waybar", "wal", "wlogout",
    "swww", "kitty", "sensors", "notify-send",
]

# Processes nên đang chạy
REQUIRED_PROCS = {
    "smartd.sh":        "smartd.sh start",
    "cyberguard_v2.sh": "cyberguard_v2.sh",
}

def check_file(path):
    return os.path.exists(os.path.expanduser(path))

def check_proc(keyword):
    try:
        result = subprocess.run(
            ["pgrep", "-f", keyword],
            capture_output=True, text=True
        )
        return result.returncode == 0
    except:
        return False

def get_temp():
    try:
        result = subprocess.run(
            ["sensors"], capture_output=True, text=True
        )
        for line in result.stdout.splitlines():
            if "Package id 0" in line:
                temp = line.split("+")[1].split("°")[0]
                return float(temp)
    except:
        pass
    return None

def check_system():
    print("╔══════════════════════════════════════╗")
    print("║   CyberTung Health Check v2.0        ║")
    print("╚══════════════════════════════════════╝\n")

    total_issues = 0

    # ── Config files ────────────────────────────────────
    print("📂 Config files:")
    for name, path in REQUIRED_FILES.items():
        ok = check_file(path)
        status = "✅" if ok else "❌"
        print(f"  {status} {name:20} {path}")
        if not ok:
            total_issues += 1

    # ── Scripts v2.0 ────────────────────────────────────
    print("\n📜 Scripts v2.0:")
    for name, path in REQUIRED_SCRIPTS.items():
        ok = check_file(path)
        status = "✅" if ok else "❌"
        print(f"  {status} {name:20} {path}")
        if not ok:
            total_issues += 1

    # ── Apps ────────────────────────────────────────────
    print("\n📦 Apps:")
    for app in REQUIRED_APPS:
        ok = shutil.which(app) is not None
        status = "✅" if ok else "⚠️ "
        print(f"  {status} {app}")
        if not ok:
            total_issues += 1

    # ── Processes đang chạy ─────────────────────────────
    print("\n🔄 Processes:")
    for name, keyword in REQUIRED_PROCS.items():
        ok = check_proc(keyword)
        status = "🟢" if ok else "🔴"
        print(f"  {status} {name:20} {'running' if ok else 'NOT running'}")
        if not ok:
            total_issues += 1

    # ── Nhiệt độ ────────────────────────────────────────
    print("\n🌡️  Nhiệt độ CPU:")
    temp = get_temp()
    if temp:
        if temp > 85:
            status = f"🔥 {temp}°C — NGUY HIỂM"
        elif temp > 75:
            status = f"⚠️  {temp}°C — Nóng"
        elif temp > 65:
            status = f"🌡️  {temp}°C — Hơi ấm"
        else:
            status = f"❄️  {temp}°C — Mát"
        print(f"  {status}")
    else:
        print("  ⚠️  Không đọc được (cần lm_sensors)")

    # ── Kết luận ────────────────────────────────────────
    print("\n══════════════════════════════════════")
    if total_issues == 0:
        print("⚡ Hệ thống HOÀN HẢO — sẵn sàng dùng!")
        print("👉 Commit lên Git: cd ~/CyberDotfiles && git push")
    else:
        print(f"⚠️  {total_issues} vấn đề cần xử lý")
        print("👉 Chạy lại: bash ~/CyberDotfiles/install.sh")

if __name__ == "__main__":
    check_system()
