-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — CENTRALIZED OPTIONS (modules/options.lua)       ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Nguồn cấu hình tập trung cho toàn bộ hệ thống Hyprland Lua.
-- Để thay đổi scale màn hình, độ mờ kính, con trỏ hoặc ứng dụng mặc định,
-- chỉ cần chỉnh sửa tại đây (hoặc ghi đè trong config/hypr/user.lua).

local home = os.getenv("HOME") or "/home/tung"
local dotfiles = home .. "/CyberDotfiles"
local scripts  = dotfiles .. "/scripts"

-- Chế độ hiệu ứng: "full" | "lite". power-auto.sh ghi vào file này rồi `hyprctl reload`.
-- lite = tắt blur/shadow/animation (pin <= 30% hoặc bật tay bằng Super+Shift+B).
local function current_mode()
    local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/cyber-mode", "r")
    if not f then return "full" end
    local m = f:read("*l"); f:close()
    return (m == "lite") and "lite" or "full"
end

local M = {
    mode = current_mode,
    paths = {
        home        = home,
        dotfiles    = dotfiles,
        scripts     = scripts,
        screenshots = home .. "/Pictures/Screenshots",
        wallpapers  = home .. "/Pictures/Wallpapers",
    },

    -- ── MÀN HÌNH (MONITOR & SCALING) ───────────────────────────────────
    -- Panel: Dell Latitude E7470 · eDP-1 · AU Optronics 2560x1440 @ 60Hz (310x170mm)
    -- Scale 1.25 -> Không gian hiển thị logic 2048x1152 (sắc nét, rộng rãi).
    -- Các mức scale an toàn khác cho 2560x1440:
    --   1.0       -> 2560x1440 (chữ rất nhỏ trên 14")
    --   1.25      -> 2048x1152 (khuyến nghị mặc định)
    --   1.333333  -> 1920x1080 (tương đương chuẩn Full HD)
    --   1.5       -> 1706x960
    --   1.6       -> 1600x900
    --   2.0       -> 1280x720
    monitor = {
        primary = {
            output   = "eDP-1",
            mode     = "2560x1440@60",
            position = "0x0",
            scale    = 1.25,
        },
        fallback = {
            output   = "",
            mode     = "preferred",
            position = "auto",
            scale    = 1.0,
        },
    },

    -- ── ỨNG DỤNG MẶC ĐỊNH & LỆNH HỆ THỐNG ──────────────────────────────
    -- Sử dụng app-launch.sh cho file-manager và browser để tự động fallback
    -- nếu nautilus/dolphin hoặc google-chrome-stable chưa được cài đặt.
    apps = {
        terminal     = "kitty",
        launcher     = "rofi -show drun",
        file_manager = scripts .. "/app-launch.sh file-manager",
        browser      = scripts .. "/app-launch.sh browser",
        lock         = "loginctl lock-session",
        logout       = "wlogout",
        notif_toggle = "swaync-client -t -sw",
        notif_panel  = "swaync-client -t -sw",
        clipboard    = "bash -c 'cliphist list | rofi -dmenu -i -p \"Clipboard\" | cliphist decode | wl-copy'",
        wall_picker  = "kitty --class wall-picker " .. scripts .. "/wall-picker.sh",
        keyhints     = scripts .. "/keyhints.sh",
        perf_mode    = scripts .. "/power-auto.sh toggle",
        screenshot   = scripts .. "/screenshot.sh",
        startup      = "bash " .. scripts .. "/startup.sh",
    },

    -- ── CON TRỎ (CURSOR) & BỘ GÕ (IME) ─────────────────────────────────
    -- Các theme con trỏ đã xác nhận trên máy: Breeze, Bibata-Modern-Ice, Bibata-Modern-Amber
    cursor = {
        theme            = "Breeze",
        size             = 24,
        inactive_timeout = 3,
    },

    ime = {
        enabled = true,
        module  = "fcitx",
    },

    -- ── BÀN PHÍM & TOUCHPAD ────────────────────────────────────────────
    input = {
        kb_layout            = "us",
        kb_variant           = "",
        kb_model             = "",
        kb_options           = "",
        kb_rules             = "",
        repeat_rate          = 40,
        repeat_delay         = 300,
        follow_mouse         = 1,
        sensitivity          = 0.0,
        natural_scroll       = true,
        tap_to_click         = true,
        disable_while_typing = true,
    },

    -- ── GIAO DIỆN SAKURA GLASS (TỐI ƯU INTEL HD 520 @ 1440P) ───────────
    appearance = {
        gaps_in          = 5,
        gaps_out         = 12,   -- Đồng bộ với margin-left/right 12px của Waybar
        border_size      = 2,
        layout           = "dwindle",
        rounding         = 14,
        rounding_power   = 4.0,  -- Bo góc squircle mượt kiểu Apple
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,

        -- Kính mờ Kawase: size = 4, passes = 2, xray = true giúp Intel HD 520
        -- giữ tốc độ khung hình 60fps ổn định mà không gây nóng máy.
        blur = {
            enabled           = true,
            size              = 4,
            passes            = 2,
            xray              = true,
            new_optimizations = true,
            ignore_opacity    = true,
            vibrancy          = 0.15,
        },

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
        },

        layer_ignore_alpha = 0.1,
    },

    -- ── PHÍM MODIFIER CHÍNH ────────────────────────────────────────────
    main_mod = "SUPER",
}

_G.CyberOptions = M
return M
