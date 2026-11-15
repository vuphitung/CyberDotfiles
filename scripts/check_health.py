#!/usr/bin/env python3
"""check_health.py — CyberDotfiles v7 System & Lua Architecture Auditor."""

import glob
import json
import os
import re
import shutil
import subprocess

D = os.path.expanduser("~/CyberDotfiles")
if not os.path.isdir(D):
    D = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FILES = {
    "Hyprland Lua Entry":  "~/.config/hypr/hyprland.lua",
    "Hyprland Options":    "~/.config/hypr/modules/options.lua",
    "Hyprland Tokens Lua": "~/.config/hypr/themes/tokens.lua",
    "Hyprlock Config":     "~/.config/hypr/hyprlock.conf",
    "Hypridle Config":     "~/.config/hypr/hypridle.conf",
    "Waybar Config":       "~/.config/waybar/config.jsonc",
    "Waybar Style":        "~/.config/waybar/style.css",
    "SwayNC Config":       "~/.config/swaync/config.json",
    "SwayNC Style":        "~/.config/swaync/style.css",
    "Rofi Config":         "~/.config/rofi/config.rasi",
    "Wlogout Layout":      "~/.config/wlogout/layout",
    "Wlogout Style":       "~/.config/wlogout/style.css",
    "Sakura Glass JSON":   f"{D}/themes/sakura-glass.json",
}

LUA_MODULES = [
    "init.lua",
    "options.lua",
    "environment.lua",
    "monitor.lua",
    "input.lua",
    "appearance.lua",
    "animations.lua",
    "workspaces.lua",
    "window-rules.lua",
    "layer-rules.lua",
    "binds.lua",
    "autostart.lua",
]

SCRIPTS = {
    "startup.sh":      f"{D}/scripts/startup.sh",
    "app-launch.sh":   f"{D}/scripts/app-launch.sh",
    "theme-gen.py":    f"{D}/scripts/theme-gen.py",
    "wallpaper.sh":    f"{D}/scripts/wallpaper.sh",
    "wall-picker.sh":  f"{D}/scripts/wall-picker.sh",
    "power-auto.sh":   f"{D}/scripts/power-auto.sh",
    "screenshot.sh":   f"{D}/scripts/screenshot.sh",
    "lagcheck.sh":     f"{D}/scripts/lagcheck.sh",
    "keyhints.sh":     f"{D}/scripts/keyhints.sh",
    "fix_symlinks.sh": f"{D}/scripts/fix_symlinks.sh",
}

APPS = [
    "hyprland", "hyprlock", "hypridle", "awww", "kitty", "rofi", "wlogout",
    "waybar", "wpctl", "playerctl", "brightnessctl", "grimblast",
    "swaync", "notify-send", "nmcli", "wal", "fcitx5", "wl-paste", "cliphist",
]

PROCS = {
    "awww/swww-daemon": "awww-daemon|swww-daemon",
    "waybar":           "^waybar$",
    "swaync":           "^swaync$",
    "hypridle":         "^hypridle$",
    "fcitx5":           "^fcitx5$",
    "polkit agent":     "hyprpolkitagent|polkit-kde-authentication|polkit-gnome",
}


def sh(cmd: str) -> str:
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=8).stdout.strip()
    except Exception:
        return ""


def chk_file(p: str) -> bool:
    return os.path.exists(os.path.expanduser(p))


def count_proc(pattern: str) -> int:
    try:
        r = subprocess.run(["pgrep", "-f", pattern], capture_output=True, text=True, timeout=3)
        if r.returncode != 0:
            return 0
        return len([line for line in r.stdout.splitlines() if line.strip()])
    except Exception:
        return 0


def chk_hypland_runtime() -> int:
    n = 0
    print("\n  ─── Hyprland 0.57.2 & Monitor Runtime")
    ver = sh("hyprctl version 2>/dev/null | head -1")
    if not ver:
        print("    ℹ️  hyprctl không phản hồi (không chạy trong phiên Wayland/Hyprland trực tiếp)")
        return 0

    print(f"    ✅ {ver}")
    errs = sh("hyprctl configerrors 2>/dev/null")
    if not errs:
        print("    ✅ hyprctl configerrors: Sạch (0 lỗi)")
    else:
        print("    ❌ hyprctl configerrors phát hiện lỗi:")
        print("       " + errs.replace("\n", "\n       "))
        n += 1

    # Kiểm tra scale màn hình eDP-1
    mons_raw = sh("hyprctl monitors -j 2>/dev/null")
    if mons_raw:
        try:
            mons = json.loads(mons_raw)
            for m in mons:
                name = m.get("name", "?")
                w, h = m.get("width", 0), m.get("height", 0)
                scale = m.get("scale", 0)
                logic_w = round(w / scale) if scale else 0
                logic_h = round(h / scale) if scale else 0
                ok_scale = abs(float(scale) - 1.25) < 0.05 if name == "eDP-1" else True
                icon = "✅" if ok_scale else "⚠️ "
                print(f"    {icon} Monitor {name}: {w}x{h} @ scale={scale} (không gian logic ~{logic_w}x{logic_h})")
                if not ok_scale:
                    n += 1
        except Exception:
            pass
    return n


def run() -> int:
    print()
    print("  ╔══════════════════════════════════════════════════╗")
    print("  ║   CYBERDOTFILES v7 // HEALTH & ARCHITECTURE      ║")
    print("  ╚══════════════════════════════════════════════════╝")
    issues = 0

    print("\n  ─── Core Config Files")
    for name, path in FILES.items():
        ok = chk_file(path)
        print(f"    {'✅' if ok else '❌'} {name:<22} {os.path.expanduser(path)}")
        if not ok:
            issues += 1

    print("\n  ─── Hyprland Lua Modules (config/hypr/modules/)")
    mod_dir = os.path.join(D, "config", "hypr", "modules")
    for mod in LUA_MODULES:
        p = os.path.join(mod_dir, mod)
        ok = os.path.isfile(p)
        print(f"    {'✅' if ok else '❌'} modules/{mod:<18} {'OK' if ok else 'MISSING'}")
        if not ok:
            issues += 1

    print("\n  ─── Scripts")
    for name, path in SCRIPTS.items():
        ok = os.path.isfile(path) and os.access(path, os.X_OK)
        print(f"    {'✅' if ok else '❌'} {name:<22} {'executable' if ok else 'missing or not +x'}")
        if not ok:
            issues += 1

    print("\n  ─── Installed Packages / Binaries")
    miss = []
    for app in APPS:
        ok = shutil.which(app) is not None
        print(f"    {'✅' if ok else '⚠️ '} {app}")
        if not ok:
            miss.append(app)

    # Check File Manager & Browser candidates
    fm_ok = any(shutil.which(x) for x in ("nautilus", "dolphin", "thunar", "pcmanfm"))
    br_ok = any(shutil.which(x) for x in ("google-chrome-stable", "google-chrome", "chromium", "firefox"))
    print(f"    {'✅' if fm_ok else '⚠️ '} File Manager (nautilus/dolphin/thunar)")
    print(f"    {'✅' if br_ok else '⚠️ '} Web Browser (google-chrome-stable/chromium/firefox)")

    print("\n  ─── Daemons & Single-Instance Check")
    for name, pat in PROCS.items():
        cnt = count_proc(pat)
        if cnt == 1:
            print(f"    🟢 {name:<20} running (1 instance)")
        elif cnt > 1:
            print(f"    ⚠️  {name:<20} DUPLICATE ({cnt} instances running!)")
            issues += 1
        else:
            print(f"    ⚪ {name:<20} not running in current environment")

    issues += chk_hypland_runtime()

    print("\n  " + "═" * 50)
    if issues == 0:
        print("  ⚡ KIẾN TRÚC CYBERDOTFILES v7 SẠCH LỖI CẤU HÌNH!")
    else:
        print(f"  ⚠️  Phát hiện {issues} mục cần lưu ý (xem chi tiết phía trên).")
    print()
    return issues


if __name__ == "__main__":
    run()
