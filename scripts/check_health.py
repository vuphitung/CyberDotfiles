#!/usr/bin/env python3
# ============================================================
# check_health.py — CyberTung System Health Check v2
# EWW-based setup (no Waybar)
# ============================================================

import os
import shutil
import subprocess

REQUIRED_FILES = {
    "Hyprland Config":   "~/.config/hypr/hyprland.conf",
    "EWW Config":        "~/CyberDotfiles/config/eww/eww.yuck",
    "EWW CSS":           "~/CyberDotfiles/config/eww/eww.css",
    "EWW hub.sh":        "~/CyberDotfiles/config/eww/scripts/hub.sh",
    "EWW launch-bar":    "~/CyberDotfiles/config/eww/scripts/launch-bar.sh",
    "Wlogout Layout":    "~/.config/wlogout/layout",
    "iwlwifi fix":       "/etc/modprobe.d/iwlwifi.conf",
}

REQUIRED_SCRIPTS = {
    "cyberguard.sh":  "~/CyberDotfiles/scripts/cyberguard.sh",
    "keyhints.sh":    "~/CyberDotfiles/scripts/keyhints.sh",
    "wallpaper.sh":   "~/CyberDotfiles/scripts/wallpaper.sh",
    "setup_all.sh":   "~/CyberDotfiles/scripts/setup_all.sh",
}

REQUIRED_APPS = [
    "hyprland", "eww", "kitty", "rofi", "wlogout",
    "swww", "jq", "socat", "pamixer", "brightnessctl",
    "playerctl", "gammastep", "sensors", "notify-send",
    "nmcli", "grimblast",
]

REQUIRED_PROCS = {
    "eww daemon":       "eww",
    "cyberguard.sh":    "cyberguard.sh",
    "wintitle.sh":      "wintitle.sh",
    "workspaces.sh":    "workspaces.sh",
}

def check_file(path):
    return os.path.exists(os.path.expanduser(path))

def check_proc(keyword):
    try:
        r = subprocess.run(["pgrep", "-f", keyword], capture_output=True)
        return r.returncode == 0
    except:
        return False

def get_temp():
    # Try sensors first
    try:
        r = subprocess.run(["sensors"], capture_output=True, text=True)
        for line in r.stdout.splitlines():
            if any(k in line for k in ["Package id 0", "Tdie", "Tccd", "CPU Temp"]):
                import re
                m = re.search(r'\+(\d+\.\d+)°C', line)
                if m:
                    return float(m.group(1))
    except:
        pass
    # Fallback: /sys/class/thermal
    try:
        import glob
        temps = []
        for f in glob.glob("/sys/class/thermal/thermal_zone*/temp"):
            with open(f) as fp:
                v = int(fp.read()) // 1000
                if 0 < v < 120:
                    temps.append(v)
        return max(temps) if temps else None
    except:
        return None

def get_eww_state():
    try:
        r = subprocess.run(["eww", "state"], capture_output=True, text=True, timeout=2)
        if r.returncode == 0:
            return r.stdout.strip()
    except:
        pass
    return None

def check_wifi_powersave():
    try:
        r = subprocess.run(["iw", "dev"], capture_output=True, text=True)
        iface = None
        for line in r.stdout.splitlines():
            if "Interface" in line:
                iface = line.split()[-1]
        if iface:
            r2 = subprocess.run(["iw", "dev", iface, "get", "power_save"],
                                capture_output=True, text=True)
            return "off" in r2.stdout.lower(), iface
    except:
        pass
    return None, None

def run():
    print("")
    print("  ╔══════════════════════════════════════════╗")
    print("  ║     NC2077 // SYSTEM HEALTH CHECK        ║")
    print("  ╚══════════════════════════════════════════╝")
    print("")

    issues = 0

    # Config files
    print("  📂 Config Files:")
    for name, path in REQUIRED_FILES.items():
        ok = check_file(path)
        icon = "✅" if ok else "❌"
        print(f"    {icon} {name:<22} {path}")
        if not ok: issues += 1

    # Scripts
    print("\n  📜 Scripts:")
    for name, path in REQUIRED_SCRIPTS.items():
        ok = check_file(path)
        icon = "✅" if ok else "❌"
        print(f"    {icon} {name:<22} {path}")
        if not ok: issues += 1

    # Apps
    print("\n  📦 Required Apps:")
    missing_apps = []
    for app in REQUIRED_APPS:
        ok = shutil.which(app) is not None
        icon = "✅" if ok else "⚠️ "
        print(f"    {icon} {app}")
        if not ok:
            missing_apps.append(app)
            issues += 1
    if missing_apps:
        print(f"\n    💡 Cài thiếu: yay -S {' '.join(missing_apps)}")

    # Processes
    print("\n  🔄 Running Processes:")
    for name, keyword in REQUIRED_PROCS.items():
        ok = check_proc(keyword)
        icon = "🟢" if ok else "🔴"
        status = "running" if ok else "NOT running"
        print(f"    {icon} {name:<22} {status}")
        if not ok: issues += 1

    # EWW State
    print("\n  📊 EWW State:")
    state = get_eww_state()
    if state:
        for line in state.splitlines():
            print(f"    {line}")
    else:
        print("    ⚠️  eww daemon không chạy")
        issues += 1

    # WiFi power save
    print("\n  📶 WiFi Power Save:")
    ps_off, iface = check_wifi_powersave()
    if ps_off is True:
        print(f"    ✅ {iface}: power_save=off (ổn định)")
    elif ps_off is False:
        print(f"    ⚠️  {iface}: power_save=ON — có thể gây mất kết nối!")
        print(f"    💡 Fix: sudo bash ~/CyberDotfiles/scripts/iwlwifi-fix.sh")
        issues += 1
    else:
        print("    ℹ️  Không đọc được (không phải iwlwifi)")

    # Temperature
    print("\n  🌡️  CPU Temperature:")
    temp = get_temp()
    if temp:
        if   temp > 85: label = f"🔥 {temp}°C — NGUY HIỂM"
        elif temp > 75: label = f"⚠️  {temp}°C — Nóng"
        elif temp > 65: label = f"🌡️  {temp}°C — Hơi ấm"
        else:           label = f"❄️  {temp}°C — Mát"
        print(f"    {label}")
    else:
        print("    ⚠️  Không đọc được (cài lm_sensors)")

    # Result
    print("")
    print("  ══════════════════════════════════════════")
    if issues == 0:
        print("  ⚡ Hệ thống HOÀN HẢO!")
        print("  👉 git push: cd ~/CyberDotfiles && git add -A && git push")
    else:
        print(f"  ⚠️  {issues} vấn đề cần xử lý")
        print("  👉 Chạy: bash ~/CyberDotfiles/install.sh")
    print("")

if __name__ == "__main__":
    run()
