-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — LAYER RULES (modules/layer-rules.lua)           ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/rules/layer-rules/
-- Áp dụng kính mờ (Kawase blur + ignore_alpha) cho các lớp bề mặt Sakura Glass.
-- Kiểm tra danh sách namespace thực tế bằng lệnh: hyprctl layers

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local ignore_alpha = (opts and opts.appearance and opts.appearance.layer_ignore_alpha) or 0.1

local glass_layers = {
    { name = "glass-waybar",       namespace = "^(waybar)$" },
    { name = "glass-rofi",         namespace = "^(rofi)$" },
    { name = "glass-wlogout",      namespace = "^(logout_dialog)$" },
    { name = "glass-swaync-cc",    namespace = "^(swaync-control-center)$" },
    { name = "glass-swaync-notif", namespace = "^(swaync-notification-window)$" },
}

for _, layer in ipairs(glass_layers) do
    hl.layer_rule({
        name         = layer.name,
        match        = { namespace = layer.namespace },
        blur         = true,
        ignore_alpha = ignore_alpha,
    })
end
