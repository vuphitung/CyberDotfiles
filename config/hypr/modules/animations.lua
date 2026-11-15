-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — ANIMATIONS (modules/animations.lua)             ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/animations/
-- Giữ trọn vẹn các đường cong Bezier mượt, nhanh và nhẹ GPU của CyberTung v6.

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions
local lite = opts and opts.mode and opts.mode() == "lite"

hl.config({ animations = { enabled = not lite } })

-- Khai báo các đường cong Bezier (hl.curve)
hl.curve("appleEase", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5,  1.0 } } })
hl.curve("smooth",    { type = "bezier", points = { { 0.25, 1.0 }, { 0.25, 1.0 } } })
hl.curve("snappy",    { type = "bezier", points = { { 0.4,  0.0 }, { 0.2,  1.0 } } })
hl.curve("pop",       { type = "bezier", points = { { 0.1,  0.9 }, { 0.2,  1.0 } } })

-- Khai báo hoạt ảnh (hl.animation) với thời lượng ngắn (speed = 2..3 deciseconds)
-- để tiết kiệm chu kỳ render trên Intel HD Graphics 520
hl.animation({ leaf = "windows",     enabled = true, speed = 3, bezier = "pop",       style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2, bezier = "smooth",    style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "appleEase" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "snappy",    style = "slidevert" })
hl.animation({ leaf = "layers",      enabled = true, speed = 3, bezier = "appleEase", style = "fade" })
hl.animation({ leaf = "border",      enabled = true, speed = 3, bezier = "appleEase" })
