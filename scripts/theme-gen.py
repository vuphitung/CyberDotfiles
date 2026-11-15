#!/usr/bin/env python3
"""theme-gen.py v7 — Single Source of Truth Theme Engine cho CyberDotfiles.

Đọc cấu hình từ `themes/sakura-glass.json`, kiểm tra tính hợp lệ (schema validation),
tạo bản sao lưu tự động trước khi ghi, bảo vệ các tệp bị chỉnh sửa thủ công (trừ khi
dùng `--force`), và sinh đồng bộ 7 tệp token cho toàn bộ hệ sinh thái desktop:
  1. config/hypr/themes/tokens.lua   (Lua native table cho Hyprland 0.57.2+)
  2. config/hypr/tokens.conf         (Hyprlang variables cho hyprlock.conf & tham chiếu v6)
  3. config/waybar/tokens.css        (GTK3 @define-color cho Waybar)
  4. config/swaync/tokens.css        (GTK3 @define-color cho SwayNC)
  5. config/wlogout/tokens.css       (GTK3 @define-color cho Wlogout)
  6. config/rofi/tokens.rasi         (RASI variables #RRGGBBAA cho Rofi)
  7. config/kitty/sakura-glass.conf  (Kitty terminal palette & opacity)

Cách dùng:
  python3 scripts/theme-gen.py            # Kiểm tra, sao lưu và sinh toàn bộ token
  python3 scripts/theme-gen.py --check    # Chỉ kiểm tra tính hợp lệ của sakura-glass.json
  python3 scripts/theme-gen.py --force    # Ghi đè kể cả khi tệp đích đã bị sửa tay
  python3 scripts/theme-gen.py --restore  # Khôi phục các tệp token từ bản sao lưu gần nhất
"""

import argparse
import datetime
import json
import os
import re
import shutil
import sys
import tempfile
from typing import Dict, Any, Tuple

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME_PATH = os.path.join(ROOT, "themes", "sakura-glass.json")
BACKUP_ROOT = os.path.expanduser("~/.cache/cyberdotfiles/theme-backups")
HEADER_MARKER = "GENERATED từ themes/sakura-glass.json bởi scripts/theme-gen.py — ĐỪNG SỬA TAY"

REQUIRED_COLORS = (
    "glass",
    "glass-strong",
    "glass-hi",
    "specular",
    "text",
    "text-muted",
    "pink",
    "pink-soft",
    "green",
    "amber",
    "red",
    "shadow",
)

HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")


class ThemeValidationError(Exception):
    """Lỗi khi file JSON theme không đúng định dạng hoặc thiếu khóa bắt buộc."""


def validate_theme(data: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    if not isinstance(data, dict):
        raise ThemeValidationError("Dữ liệu theme phải là một JSON object.")

    colors: Dict[str, Dict[str, Any]] = {}
    for key in REQUIRED_COLORS:
        if key not in data:
            raise ThemeValidationError(f"Thiếu khóa màu bắt buộc trong sakura-glass.json: '{key}'")
        val = data[key]
        if not isinstance(val, dict):
            raise ThemeValidationError(f"Màu '{key}' phải là một object chứa 'hex' và 'alpha'.")
        hex_val = val.get("hex", "")
        alpha_val = val.get("alpha", None)
        if not isinstance(hex_val, str) or not HEX_RE.match(hex_val):
            raise ThemeValidationError(f"Màu '{key}' có mã hex không hợp lệ: '{hex_val}' (cần dạng #RRGGBB).")
        if not isinstance(alpha_val, (int, float)) or not (0.0 <= float(alpha_val) <= 1.0):
            raise ThemeValidationError(f"Màu '{key}' có alpha không hợp lệ: '{alpha_val}' (cần trong khoảng 0.0 - 1.0).")
        colors[key] = {"hex": hex_val.lower(), "alpha": float(alpha_val), "note": val.get("note", "")}

    # Include any extra valid color objects defined in the file
    for key, val in data.items():
        if key not in colors and isinstance(val, dict) and "hex" in val and "alpha" in val:
            if not HEX_RE.match(str(val["hex"])):
                raise ThemeValidationError(f"Màu bổ sung '{key}' có mã hex không hợp lệ: {val['hex']}")
            alpha_f = float(val["alpha"])
            if not (0.0 <= alpha_f <= 1.0):
                raise ThemeValidationError(f"Màu bổ sung '{key}' có alpha ngoài khoảng [0, 1]: {alpha_f}")
            colors[key] = {"hex": val["hex"].lower(), "alpha": alpha_f, "note": val.get("note", "")}

    kitty_op = data.get("kitty-opacity", 0.72)
    if not isinstance(kitty_op, (int, float)) or not (0.1 <= float(kitty_op) <= 1.0):
        raise ThemeValidationError(f"'kitty-opacity' không hợp lệ: {kitty_op} (cần trong khoảng 0.1 - 1.0).")

    return colors


def rgb_tuple(hex_str: str) -> Tuple[int, int, int]:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def alpha_hex(alpha: float) -> str:
    return f"{round(alpha * 255):02x}"


def to_hex8(c: Dict[str, Any], override_alpha: float = None) -> str:
    a = c["alpha"] if override_alpha is None else override_alpha
    return c["hex"].lstrip("#").lower() + alpha_hex(a)


def to_css_color(c: Dict[str, Any]) -> str:
    r, g, b = rgb_tuple(c["hex"])
    a = c["alpha"]
    return f"rgb({r},{g},{b})" if a >= 1.0 else f"rgba({r},{g},{b},{a:g})"


def to_hypr_rgba(c: Dict[str, Any], override_alpha: float = None) -> str:
    return f"rgba({to_hex8(c, override_alpha)})"


def to_hypr_rgb(c: Dict[str, Any]) -> str:
    return f"rgb({c['hex'].lstrip('#').lower()})"


def build_outputs(raw: Dict[str, Any], colors: Dict[str, Dict[str, Any]]) -> Dict[str, str]:
    font_ui = raw.get("font-ui", "Inter")
    font_mono = raw.get("font-mono", "JetBrainsMono Nerd Font")
    kitty_opacity = float(raw.get("kitty-opacity", 0.72))
    border_off_hex = "ffffff22"

    # 1. GTK3 CSS (waybar, swaync, wlogout)
    gtk_css = f"/* {HEADER_MARKER} */\n" + "".join(
        f"@define-color {k} {to_css_color(v)};\n" for k, v in colors.items()
    )

    # 2. Rofi RASI
    rasi = (
        f"/* {HEADER_MARKER} */\n* {{\n"
        + "".join(f"    {k}: #{to_hex8(v)};\n" for k, v in colors.items())
        + "}\n"
    )

    # 3. Kitty Sakura Glass config
    kitty = (
        f"# {HEADER_MARKER}\n"
        f"background            #{colors['glass-strong']['hex'].lstrip('#')}\n"
        f"foreground            {colors['text']['hex']}\n"
        f"cursor                {colors['pink']['hex']}\n"
        f"cursor_text_color     #{colors['glass-strong']['hex'].lstrip('#')}\n"
        f"selection_background  {colors['pink']['hex']}\n"
        f"selection_foreground  {colors['glass']['hex']}\n"
        f"url_color             {colors['pink']['hex']}\n"
        f"active_tab_background {colors['pink']['hex']}\n"
        f"active_tab_foreground {colors['glass']['hex']}\n"
        f"inactive_tab_background {colors['glass']['hex']}\n"
        f"inactive_tab_foreground {colors['text']['hex']}\n"
        f"background_opacity    {kitty_opacity:g}\n"
    )

    # 4. Hyprlang tokens.conf (for hyprlock.conf & legacy reference)
    hypr_conf = (
        f"# {HEADER_MARKER}\n"
        f"$col_pink          = {to_hypr_rgba(colors['pink'], 0.93)}\n"
        f"$col_pink_solid    = {to_hypr_rgb(colors['pink'])}\n"
        f"$col_border_off    = rgba({border_off_hex})\n"
        f"$col_shadow        = {to_hypr_rgba(colors['shadow'])}\n"
        f"$col_glass         = {to_hypr_rgba(colors['glass'])}\n"
        f"$col_glass_strong  = {to_hypr_rgba(colors['glass-strong'])}\n"
        f"$col_text          = {to_hypr_rgb(colors['text'])}\n"
        f"$col_text_muted    = {to_hypr_rgba(colors['text-muted'])}\n"
        f"$col_green         = {to_hypr_rgb(colors['green'])}\n"
        f"$col_amber         = {to_hypr_rgb(colors['amber'])}\n"
        f"$col_red           = {to_hypr_rgb(colors['red'])}\n"
        f"$font_ui           = {font_ui}\n"
    )

    # 5. Native Lua tokens.lua for Hyprland 0.57.2+
    lua_lines = [
        f"-- {HEADER_MARKER}",
        "-- Module token màu và font thống nhất cho Hyprland 0.57.2 Lua Native Architecture.",
        "",
        "local M = {",
        f'    theme_name = "sakura-glass",',
        f'    font_ui    = "{font_ui}",',
        f'    font_mono  = "{font_mono}",',
        f"    kitty_opacity = {kitty_opacity:g},",
        "",
        "    -- Chuỗi màu định dạng Hyprland (rgba/rgb) dùng trực tiếp trong hl.config / hl.window_rule",
        "    hypr = {",
        f'        pink         = "{to_hypr_rgba(colors["pink"], 0.93)}",',
        f'        pink_solid   = "{to_hypr_rgb(colors["pink"])}",',
        f'        pink_soft    = "{to_hypr_rgba(colors["pink-soft"])}",',
        f'        border_off   = "rgba({border_off_hex})",',
        f'        specular     = "{to_hypr_rgba(colors["specular"])}",',
        f'        shadow       = "{to_hypr_rgba(colors["shadow"])}",',
        f'        glass        = "{to_hypr_rgba(colors["glass"])}",',
        f'        glass_strong = "{to_hypr_rgba(colors["glass-strong"])}",',
        f'        glass_hi     = "{to_hypr_rgba(colors["glass-hi"])}",',
        f'        text         = "{to_hypr_rgb(colors["text"])}",',
        f'        text_muted   = "{to_hypr_rgba(colors["text-muted"])}",',
        f'        green        = "{to_hypr_rgb(colors["green"])}",',
        f'        amber        = "{to_hypr_rgb(colors["amber"])}",',
        f'        red          = "{to_hypr_rgb(colors["red"])}",',
        "    },",
        "",
        "    -- Dữ liệu gốc (hex + alpha) cho các script hoặc module mở rộng",
        "    raw = {",
    ]
    for k, v in colors.items():
        lua_key = k.replace("-", "_")
        lua_lines.append(
            f'        {lua_key:<14} = {{ hex = "{v["hex"]}", alpha = {v["alpha"]:g}, hex8 = "#{to_hex8(v)}" }},'
        )
    lua_lines.extend([
        "    },",
        "}",
        "",
        "_G.CyberTokens = M",
        "return M",
        "",
    ])
    hypr_lua = "\n".join(lua_lines)

    return {
        "config/waybar/tokens.css": gtk_css,
        "config/swaync/tokens.css": gtk_css,
        "config/wlogout/tokens.css": gtk_css,
        "config/rofi/tokens.rasi": rasi,
        "config/kitty/sakura-glass.conf": kitty,
        "config/hypr/tokens.conf": hypr_conf,
        "config/hypr/themes/tokens.lua": hypr_lua,
    }


def is_safe_to_overwrite(abs_path: str, force: bool) -> bool:
    if force or not os.path.exists(abs_path):
        return True
    try:
        with open(abs_path, "r", encoding="utf-8") as f:
            first_lines = f.read(256)
        return "GENERATED" in first_lines or "theme-gen.py" in first_lines
    except Exception:
        return False


def create_backup(rel_paths):
    existing = [rel for rel in rel_paths if os.path.exists(os.path.join(ROOT, rel))]
    if not existing:
        return None
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    dest_dir = os.path.join(BACKUP_ROOT, ts)
    os.makedirs(dest_dir, exist_ok=True)
    for rel in existing:
        src = os.path.join(ROOT, rel)
        dst = os.path.join(dest_dir, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
    # Prune old backups (keep last 10)
    try:
        snaps = sorted(
            [d for d in os.listdir(BACKUP_ROOT) if os.path.isdir(os.path.join(BACKUP_ROOT, d))]
        )
        while len(snaps) > 10:
            old = snaps.pop(0)
            shutil.rmtree(os.path.join(BACKUP_ROOT, old), ignore_errors=True)
    except Exception:
        pass
    return dest_dir


def restore_latest_backup() -> int:
    if not os.path.isdir(BACKUP_ROOT):
        print("❌ Không tìm thấy thư mục sao lưu tại:", BACKUP_ROOT, file=sys.stderr)
        return 1
    snaps = sorted(
        [d for d in os.listdir(BACKUP_ROOT) if os.path.isdir(os.path.join(BACKUP_ROOT, d))]
    )
    if not snaps:
        print("❌ Không có bản sao lưu theme nào để khôi phục.", file=sys.stderr)
        return 1
    latest = os.path.join(BACKUP_ROOT, snaps[-1])
    restored = 0
    for dirpath, _, filenames in os.walk(latest):
        for fn in filenames:
            src = os.path.join(dirpath, fn)
            rel = os.path.relpath(src, latest)
            dst = os.path.join(ROOT, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)
            print(f"  🔄 Đã khôi phục: {rel}")
            restored += 1
    print(f"✅ Đã khôi phục {restored} tệp từ bản sao lưu: {latest}")
    return 0


def atomic_write(abs_path: str, content: str):
    parent = os.path.dirname(abs_path)
    os.makedirs(parent, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(prefix=".theme_gen_", dir=parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_path, abs_path)
    except Exception:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description="CyberDotfiles v7 Sakura Glass Theme Generator")
    parser.add_argument("--check", action="store_true", help="Chỉ kiểm tra tính hợp lệ của sakura-glass.json")
    parser.add_argument("--force", action="store_true", help="Ghi đè kể cả khi tệp đích đã bị sửa thủ công")
    parser.add_argument("--restore", action="store_true", help="Khôi phục token từ bản sao lưu gần nhất")
    args = parser.parse_args()

    if args.restore:
        return restore_latest_backup()

    if not os.path.exists(THEME_PATH):
        print(f"❌ Không tìm thấy tệp nguồn theme: {THEME_PATH}", file=sys.stderr)
        return 1

    try:
        with open(THEME_PATH, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
        colors = validate_theme(raw_data)
    except (json.JSONDecodeError, ThemeValidationError) as exc:
        print(f"❌ Lỗi kiểm tra theme ({THEME_PATH}): {exc}", file=sys.stderr)
        print("🛡️ Đã hủy quá trình sinh file để bảo vệ theme hiện tại.", file=sys.stderr)
        return 1

    if args.check:
        print(f"✅ Tệp theme hợp lệ ({len(colors)} token màu): {THEME_PATH}")
        return 0

    outputs = build_outputs(raw_data, colors)

    # Check overwrite protection before touching any file
    protected = []
    for rel in outputs:
        abs_p = os.path.join(ROOT, rel)
        if not is_safe_to_overwrite(abs_p, args.force):
            protected.append(rel)

    if protected:
        print("⚠️ Phát hiện tệp đích đã được chỉnh sửa thủ công (thiếu header GENERATED):", file=sys.stderr)
        for rel in protected:
            print(f"   - {rel}", file=sys.stderr)
        print("💡 Dùng `python3 scripts/theme-gen.py --force` nếu bạn muốn ghi đè.", file=sys.stderr)
        return 1

    # Check if any file content actually changes before creating backup
    needs_update = False
    for rel, content in outputs.items():
        abs_p = os.path.join(ROOT, rel)
        if not os.path.exists(abs_p):
            needs_update = True
            break
        try:
            with open(abs_p, "r", encoding="utf-8") as f:
                if f.read() != content:
                    needs_update = True
                    break
        except Exception:
            needs_update = True
            break

    if needs_update:
        backup_dir = create_backup(outputs.keys())
        if backup_dir:
            print(f"  📦 Backup trước khi cập nhật: {backup_dir}")

    for rel, content in outputs.items():
        abs_p = os.path.join(ROOT, rel)
        atomic_write(abs_p, content)
        print(f"  ✅ {rel}")

    print("✨ Hoàn tất đồng bộ Sakura Glass tokens.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
