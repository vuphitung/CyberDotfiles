#!/usr/bin/env python3
# check_health.py — CyberTung System Health Check v6

import glob, os, re, shutil, subprocess

D = os.path.expanduser("~/CyberDotfiles")

FILES = {
    "Hyprland config":  "~/.config/hypr/hyprland.conf",
    "Wlogout layout":   "~/.config/wlogout/layout",
    "Wlogout style":    "~/.config/wlogout/style.css",
    "iwlwifi fix":      "/etc/modprobe.d/iwlwifi.conf",
}
SCRIPTS = {
    "wallpaper.sh":     f"{D}/scripts/wallpaper.sh",
    "wall-picker.sh":   f"{D}/scripts/wall-picker.sh",
    "keyhints.sh":      f"{D}/scripts/keyhints.sh",
    "setup_all.sh":     f"{D}/scripts/setup_all.sh",
    "iwlwifi-fix.sh":   f"{D}/scripts/iwlwifi-fix.sh",
}
APPS = [
    "hyprland", "hyprlock", "hypridle", "awww", "kitty", "rofi", "wlogout",
    "wpctl", "pamixer", "playerctl", "brightnessctl", "grimblast",
    "swaync", "notify-send", "nmcli", "wal", "sensors", "fcitx5",
]
PROCS = {"awww/swww-daemon": "awww-daemon|swww-daemon", "swaync": "swaync",
         "hypridle": "hypridle", "fcitx5": "fcitx5", "polkit agent": "hyprpolkitagent|polkit-kde-authentication"}

def chk_file(p): return os.path.exists(os.path.expanduser(p))
def chk_proc(k):
    try: return subprocess.run(["pgrep","-f",k],capture_output=True).returncode==0
    except: return False
def get_temp():
    try:
        r = subprocess.run(["sensors"],capture_output=True,text=True)
        for l in r.stdout.splitlines():
            if any(k in l for k in ["Package id 0","Tdie","Tccd","CPU Temp"]):
                m = re.search(r"\+(\d+\.\d+)°C",l)
                if m: return float(m.group(1))
    except: pass
    try:
        ts = []
        for f in glob.glob("/sys/class/thermal/thermal_zone*/temp"):
            v = int(open(f).read())//1000
            if 0<v<120: ts.append(v)
        return max(ts) if ts else None
    except: return None
def chk_gpu_renderer():
    if not shutil.which("glxinfo"):
        return None
    try:
        r = subprocess.run(["glxinfo"], capture_output=True, text=True, timeout=5)
        for l in r.stdout.splitlines():
            if "OpenGL renderer" in l:
                return l.split(":",1)[1].strip()
    except: pass
    return None

def chk_hw_cursor():
    try:
        r = subprocess.run(["hyprctl","getoption","cursor:no_hardware_cursors"],
                            capture_output=True, text=True, timeout=3)
        return r.stdout.strip()
    except: return None

def chk_mem_pressure():
    try:
        with open("/proc/pressure/memory") as f:
            for l in f:
                if l.startswith("some"):
                    m = re.search(r"avg60=(\d+\.\d+)", l)
                    if m: return float(m.group(1))
    except: pass
    return None

def chk_faillock():
    user = os.environ.get("USER") or os.environ.get("LOGNAME")
    if not user:
        return None
    try:
        r = subprocess.run(["faillock", "--user", user], capture_output=True, text=True, timeout=3)
        lines = [l for l in r.stdout.splitlines() if l.strip().endswith(("V","I"))]
        # Count recent valid failures
        recent_fails = sum(1 for l in lines if l.rstrip().endswith("V"))
        return recent_fails
    except Exception:
        return None

def chk_wifi():
    try:
        r = subprocess.run(["iw","dev"],capture_output=True,text=True)
        iface = next((l.split()[-1] for l in r.stdout.splitlines() if "Interface" in l),None)
        if iface:
            r2 = subprocess.run(["iw","dev",iface,"get","power_save"],capture_output=True,text=True)
            return "off" in r2.stdout.lower(), iface
    except: pass
    return None, None


def sh(cmd):
    try: return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception: return ""

def chk_system_extra():
    """Các kiểm tra rút ra từ lỗi thật sau khi Arch cập nhật. Trả về số vấn đề."""
    n = 0
    print("\n  ─── Hyprland / hệ thống")
    ver = sh("hyprctl version 2>/dev/null | head -1")
    print(f"    ℹ️  {ver or 'hyprctl không chạy (không ở trong phiên Hyprland?)'}")
    if ver:
        errs = sh("hyprctl configerrors 2>/dev/null")
        ok = (errs == "")
        print(f"    {'✅' if ok else '❌'} configerrors {'sạch' if ok else '→ có lỗi:'}")
        if not ok: print("       " + errs.replace("\n", "\n       ")); n += 1
        if os.path.exists(os.path.expanduser("~/.config/hypr/hyprland.conf")) and not os.path.exists(os.path.expanduser("~/.config/hypr/hyprland.lua")):
            print("    ⚠️  Đang dùng hyprlang (hyprland.conf). Hyprland >= 0.55 đã deprecate — lên kế hoạch chuyển Lua")
    tlp = sh("systemctl is-active tlp 2>/dev/null") == "active" or sh("systemctl is-enabled tlp 2>/dev/null") == "enabled"
    ppd = sh("systemctl is-enabled power-profiles-daemon 2>/dev/null") == "enabled"
    if tlp and ppd:
        print("    ❌ tlp VÀ power-profiles-daemon cùng bật (xung đột) → sudo systemctl disable --now tlp"); n += 1
    prof = sh("powerprofilesctl get 2>/dev/null")
    bat = sh("cat /sys/class/power_supply/BAT*/status 2>/dev/null")
    if prof == "performance" and "Discharging" in bat:
        print("    ⚠️  Đang chạy bằng pin nhưng profile = performance → powerprofilesctl set balanced"); n += 1
    cores = sh("coredumpctl list --since '-7 days' --no-pager 2>/dev/null | grep -c python")
    if cores and cores != "0":
        print(f"    ⚠️  {cores} crash python trong 7 ngày → coredumpctl info <PID>"); n += 1
    return n

def run():
    print()
    print("  ╔══════════════════════════════════════════╗")
    print("  ║   CYBERTUNG // HEALTH CHECK v6          ║")
    print("  ╚══════════════════════════════════════════╝")
    issues = 0

    print("\n  ─── Config files")
    for n,p in FILES.items():
        ok = chk_file(p)
        print(f"    {'✅' if ok else '❌'} {n:<22} {os.path.expanduser(p)}")
        issues += 0 if ok else 1

    print("\n  ─── Scripts")
    for n,p in SCRIPTS.items():
        ok = os.path.exists(p)
        print(f"    {'✅' if ok else '❌'} {n:<22} {p}")
        issues += 0 if ok else 1

    print("\n  ─── Apps")
    miss = []
    for a in APPS:
        ok = shutil.which(a) is not None
        print(f"    {'✅' if ok else '⚠️ '} {a}")
        if not ok: miss.append(a); issues += 1
    if miss: print(f"\n    💡 yay -S {' '.join(miss)}")

    print("\n  ─── Processes")
    for n,k in PROCS.items():
        ok = chk_proc(k)
        print(f"    {'🟢' if ok else '🔴'} {n:<20} {'running' if ok else 'NOT running'}")
        issues += 0 if ok else 1

    issues += chk_system_extra()

    print("\n  ─── GPU / Cursor / RAM pressure")
    renderer = chk_gpu_renderer()
    if renderer is None and not shutil.which("glxinfo"):
        print("    ⚠️  glxinfo chưa cài — cài mesa-utils để check renderer")
        issues += 1
    elif renderer:
        if "llvmpipe" in renderer.lower():
            print(f"    🔥 Renderer: {renderer}  ← ĐANG DÙNG SOFTWARE RENDER (nguyên nhân lag chính!)")
            issues += 1
        else:
            print(f"    ✅ Renderer: {renderer}")

    cur = chk_hw_cursor()
    if cur:
        forced = "set: true" in cur
        val0 = "int: 0" in cur
        if forced:
            print(f"    ⚠️  no_hardware_cursors bị ép set (forced) — có thể gây giật cursor lúc login/unlock")
            issues += 1
        else:
            print(f"    ✅ no_hardware_cursors: mặc định (không bị ép)")

    pressure = chk_mem_pressure()
    if pressure is not None:
        if pressure > 5:
            print(f"    🔥 Memory pressure (avg60): {pressure}%  ← RAM đang bị nghẽn")
            issues += 1
        else:
            print(f"    ✅ Memory pressure (avg60): {pressure}%")

    print("\n  ─── Sudo / Faillock")
    fails = chk_faillock()
    if fails is None:
        print("    ℹ️  Không đọc được faillock (cần lệnh 'faillock' có sẵn)")
    elif fails >= 3:
        print(f"    🔥 {fails} lần sudo auth fail gần đây — có thể sắp/đang bị khóa!")
        print("       Fix: faillock --user $USER --reset")
        issues += 1
    elif fails > 0:
        print(f"    ⚠️  {fails} lần sudo auth fail gần đây (chưa tới ngưỡng khóa)")
    else:
        print("    ✅ Không có lần auth fail nào gần đây")

    print("\n  ─── WiFi")
    ps, iface = chk_wifi()
    if ps is True:   print(f"    ✅ {iface}: power_save=off")
    elif ps is False: print(f"    ⚠️  {iface}: power_save=ON"); issues += 1
    else:            print("    ℹ️  Không đọc được")

    print("\n  ─── CPU temp")
    t = get_temp()
    if t:
        lbl = f"🔥 {t}°C NGUY HIỂM" if t>85 else f"⚠️ {t}°C Nóng" if t>75 else f"🌡️ {t}°C Ổn" if t>65 else f"❄️ {t}°C Mát"
        print(f"    {lbl}")
    else: print("    ⚠️  Không đọc được")

    print("\n  ─── Dotfiles")
    print(f"    {'✅' if os.path.isdir(f'{D}/.git') else '⚠️ '} Git repo: {D}")
    print(f"    {'✅' if os.path.isdir(f'{D}/shell') else 'ℹ️ '} Shell: {D}/shell")

    print()
    print("  " + "═"*44)
    if issues == 0:
        print("  ⚡ SẠCH! git add -A && git push")
    else:
        print(f"  ⚠️  {issues} vấn đề → bash {D}/install.sh")
    print()

if __name__ == "__main__": run()
