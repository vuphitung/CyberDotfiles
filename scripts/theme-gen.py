#!/usr/bin/env python3
"""theme-gen.py — sinh file màu cho từng app từ themes/sakura-glass.json.

Mỗi app đọc token từ file nằm CẠNH config của nó (relative), nên hoạt động
dù thư mục được symlink vào ~/.config hay không:
  config/waybar/tokens.css   config/swaync/tokens.css   config/wlogout/tokens.css
  config/rofi/tokens.rasi    config/kitty/sakura-glass.conf   config/hypr/tokens.conf
Chỉ dùng thư viện chuẩn, chạy < 50ms.
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = json.load(open(os.path.join(ROOT, "themes", "sakura-glass.json"), encoding="utf-8"))
COLORS = {k: v for k, v in T.items() if isinstance(v, dict)}

def rgb(h):  h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
def a8(a):   return f"{round(a * 255):02x}"
def hex8(c): return c["hex"].lstrip("#").lower() + a8(c["alpha"])
def css(c):
    r, g, b = rgb(c["hex"]); a = c["alpha"]
    return f"rgb({r},{g},{b})" if a >= 1 else f"rgba({r},{g},{b},{a:g})"

HEADER = "GENERATED từ themes/sakura-glass.json bởi scripts/theme-gen.py — ĐỪNG SỬA TAY"

def write(rel, text):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f: f.write(text)
    print("  ✅", rel)

# ── GTK3 CSS (waybar, swaync, wlogout): @define-color ─────────────
gtk = f"/* {HEADER} */\n" + "".join(
    f"@define-color {k} {css(v)};\n" for k, v in COLORS.items())
for app in ("waybar", "swaync", "wlogout"):
    write(f"config/{app}/tokens.css", gtk)

# ── Rofi: biến trong * { } (hex 8 số = #RRGGBBAA) ─────────────────
rasi = f"/* {HEADER} */\n* {{\n" + "".join(
    f"    {k}: #{hex8(v)};\n" for k, v in COLORS.items()) + "}\n"
write("config/rofi/tokens.rasi", rasi)

# ── Kitty: chỉ phần "chrome" (nền/chữ/con trỏ/tab); 16 màu ANSI vẫn từ pywal ─
c = COLORS
kitty = f"# {HEADER}\n" \
    f"background            #{c['glass-strong']['hex'].lstrip('#')}\n" \
    f"foreground            {c['text']['hex']}\n" \
    f"cursor                {c['pink']['hex']}\n" \
    f"cursor_text_color     #{c['glass-strong']['hex'].lstrip('#')}\n" \
    f"selection_background  {c['pink']['hex']}\n" \
    f"selection_foreground  {c['glass']['hex']}\n" \
    f"url_color             {c['pink']['hex']}\n" \
    f"active_tab_background {c['pink']['hex']}\n" \
    f"active_tab_foreground {c['glass']['hex']}\n" \
    f"inactive_tab_background {c['glass']['hex']}\n" \
    f"inactive_tab_foreground {c['text']['hex']}\n" \
    f"background_opacity    {T['kitty-opacity']}\n"
write("config/kitty/sakura-glass.conf", kitty)

# ── Hyprland + Hyprlock (hyprlang biến $name) ─────────────────────
def rg(name, alpha=None):
    v = c[name]; a = v["alpha"] if alpha is None else alpha
    return f"rgba({v['hex'].lstrip('#').lower()}{a8(a)})"
hypr = f"# {HEADER}\n" \
    f"$col_pink          = {rg('pink', 0.93)}\n" \
    f"$col_pink_solid    = rgb({c['pink']['hex'].lstrip('#')})\n" \
    f"$col_border_off    = rgba(ffffff22)\n" \
    f"$col_shadow        = {rg('shadow')}\n" \
    f"$col_glass         = {rg('glass')}\n" \
    f"$col_glass_strong  = {rg('glass-strong')}\n" \
    f"$col_text          = rgb({c['text']['hex'].lstrip('#')})\n" \
    f"$col_text_muted    = {rg('text-muted')}\n" \
    f"$col_green         = rgb({c['green']['hex'].lstrip('#')})\n" \
    f"$col_amber         = rgb({c['amber']['hex'].lstrip('#')})\n" \
    f"$col_red           = rgb({c['red']['hex'].lstrip('#')})\n" \
    f"$font_ui           = Inter\n"
write("config/hypr/tokens.conf", hypr)
print("Xong.")
