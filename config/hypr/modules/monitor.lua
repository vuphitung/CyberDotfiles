-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — MONITOR CONFIGURATION (modules/monitor.lua)     ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/monitors/
-- Giải quyết triệt để lỗi scale = 2.0 (do scale = "auto" trên màn eDP-1 2560x1440).
-- Đặt mặc định scale = 1.25 (không gian logic 2048x1152) từ modules/options.lua.

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local mon_cfg = (opts and opts.monitor) or {}
local primary = mon_cfg.primary or {
    output   = "eDP-1",
    mode     = "2560x1440@60",
    position = "0x0",
    scale    = 1.25,
}
local fallback = mon_cfg.fallback or {
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.0,
}

-- 1. Màn hình chính của laptop (eDP-1: 2560x1440@60Hz, scale 1.25)
hl.monitor({
    output   = primary.output or "eDP-1",
    mode     = primary.mode or "2560x1440@60",
    position = primary.position or "0x0",
    scale    = primary.scale or 1.25,
})

-- 2. Quy tắc dự phòng (Fallback) cho màn hình rời (HDMI / DisplayPort)
-- Khi cắm thêm màn hình ngoài chưa có rule riêng, tự động đặt ở bên phải với độ phân giải gốc.
hl.monitor({
    output   = fallback.output or "",
    mode     = fallback.mode or "preferred",
    position = fallback.position or "auto",
    scale    = fallback.scale or 1.0,
})

-- 3. Giữ độ sắc nét cho ứng dụng XWayland (Wine / Steam) khi dùng fractional scale 1.25
hl.config({
    xwayland = {
        enabled            = true,
        force_zero_scaling = true,
    },
})
