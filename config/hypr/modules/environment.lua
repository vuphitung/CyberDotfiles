-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — ENVIRONMENT VARIABLES (modules/environment.lua) ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/environment-variables/

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local cursor_theme = (opts and opts.cursor and opts.cursor.theme) or "Breeze"
local cursor_size  = tostring((opts and opts.cursor and opts.cursor.size) or 24)

-- 1. Con trỏ chuột (XCursor & Hyprcursor)
hl.env("XCURSOR_THEME", cursor_theme)
hl.env("XCURSOR_SIZE", cursor_size)
hl.env("HYPRCURSOR_THEME", cursor_theme)
hl.env("HYPRCURSOR_SIZE", cursor_size)

-- 2. Bộ gõ tiếng Việt Fcitx5
if not opts or not opts.ime or opts.ime.enabled ~= false then
    local im = (opts and opts.ime and opts.ime.module) or "fcitx"
    hl.env("XMODIFIERS", "@im=" .. im)
    hl.env("QT_IM_MODULE", im)
    hl.env("GTK_IM_MODULE", im)
    hl.env("SDL_IM_MODULE", im)
end

-- 3. Chuẩn hóa Backend Wayland cho GTK, Qt, SDL, Electron & Firefox
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
