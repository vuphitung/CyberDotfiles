-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — SAKURA GLASS APPEARANCE (modules/appearance.lua)║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/config-options/
-- Thiết kế tối ưu cho Intel HD Graphics 520 @ 2560x1440:
--   - Giữ Kawase blur nhẹ (size = 4, passes = 2, xray = true, new_optimizations = true).
--   - Giữ hardware cursors mặc định (không ép software cursor) để bảo toàn direct scanout.
--   - Bật VFR (Variable Frame Rate) để giảm tải GPU/CPU về gần 0% khi màn hình đứng yên.

local raw_require = _G.__require or require
local ok_t, tokens = pcall(raw_require, "themes.tokens")
tokens = (ok_t and type(tokens) == "table") and tokens or _G.CyberTokens

local ok_o, opts = pcall(raw_require, "modules.options")
opts = (ok_o and type(opts) == "table") and opts or _G.CyberOptions

local lite   = opts and opts.mode and opts.mode() == "lite"
local app    = (opts and opts.appearance) or {}
local cur    = (opts and opts.cursor) or {}
local blur   = app.blur or {}
local shadow = app.shadow or {}
local colors = (tokens and tokens.hypr) or {
    pink       = "rgba(ffb7c5ed)",
    border_off = "rgba(ffffff22)",
    shadow     = "rgba(00000040)",
}

hl.config({
    general = {
        gaps_in          = app.gaps_in or 5,
        gaps_out         = app.gaps_out or 12,
        border_size      = app.border_size or 2,
        resize_on_border = false,
        allow_tearing    = false,
        layout           = app.layout or "dwindle",

        col = {
            active_border   = colors.pink,
            inactive_border = colors.border_off,
        },
    },

    decoration = {
        rounding         = app.rounding or 14,
        rounding_power   = app.rounding_power or 4.0,
        active_opacity   = app.active_opacity or 1.0,
        inactive_opacity = app.inactive_opacity or 1.0,
        dim_inactive     = (app.dim_inactive == true),

        blur = {
            enabled           = (blur.enabled ~= false) and not lite,
            size              = blur.size or 4,
            passes            = blur.passes or 2,
            xray              = (blur.xray ~= false),
            new_optimizations = (blur.new_optimizations ~= false),
            ignore_opacity    = (blur.ignore_opacity ~= false),
            vibrancy          = blur.vibrancy or 0.15,
        },

        shadow = {
            enabled      = (shadow.enabled ~= false) and not lite,
            range        = shadow.range or 12,
            render_power = shadow.render_power or 3,
            color        = colors.shadow,
        },
    },

    cursor = {
        inactive_timeout  = cur.inactive_timeout or 3,
        sync_gsettings_theme = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        animate_manual_resizes   = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        
        font_family              = (tokens and tokens.font_ui) or "Inter",
    },
    debug = { vfr = true },   -- Hyprland 0.57.2: đúng chỗ là debug.vfr (misc.vfr bị từ chối)

    -- Tam bộ đệm động khi GPU không kịp 60fps: đúng bệnh của iGPU HD 520 @ 1440p.
    render = { new_render_scheduling = true },

    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})
