-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — WORKSPACE RULES (modules/workspaces.lua)        ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/rules/workspace-rules/

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local primary_out = (opts and opts.monitor and opts.monitor.primary and opts.monitor.primary.output) or "eDP-1"

-- Gắn Workspace 1 làm mặc định trên màn hình chính eDP-1;
-- định tuyến sẵn các Workspace 1..6 đồng bộ với 6 chấm tròn trên Waybar.
for i = 1, 6 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = primary_out,
        default   = (i == 1),
    })
end
