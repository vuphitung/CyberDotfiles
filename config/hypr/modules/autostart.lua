-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — AUTOSTART LIFECYCLE (modules/autostart.lua)     ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/autostart/
-- Sử dụng sự kiện `hyprland.start` để gọi trình điều phối `scripts/startup.sh`,
-- đảm bảo khởi động đúng thứ tự phụ thuộc, không chạy trùng daemon và ghi log đầy đủ.

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local startup_cmd = (opts and opts.apps and opts.apps.startup)
    or ("bash " .. ((os.getenv("HOME") or "/home/tung") .. "/CyberDotfiles/scripts/startup.sh"))

hl.on("hyprland.start", function()
    hl.exec_cmd(startup_cmd)
end)
