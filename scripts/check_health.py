#!/usr/bin/env python3
# check_health.py — CyberTung System Health Check v5

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
    "hyprland", "hyprlock", "swww", "kitty", "rofi", "wlogout",
    "wpctl", "pamixer", "playerctl", "brightnessctl", "grimblast",
    "swaync", "notify-send", "nmcli", "wal", "sensors", "fcitx5",
]
PROCS = {"swww-daemon": "swww-daemon", "swaync": "swaync"}

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
def chk_wifi():
    try:
        r = subprocess.run(["iw","dev"],capture_output=True,text=True)
        iface = next((l.split()[-1] for l in r.stdout.splitlines() if "Interface" in l),None)
        if iface:
            r2 = subprocess.run(["iw","dev",iface,"get","power_save"],capture_output=True,text=True)
            return "off" in r2.stdout.lower(), iface
    except: pass
    return None, None

def run():
    print()
    print("  ╔══════════════════════════════════════════╗")
    print("  ║   CYBERTUNG // HEALTH CHECK v5          ║")
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
