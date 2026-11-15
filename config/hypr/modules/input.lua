-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — INPUT & GESTURES (modules/input.lua)            ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu:
--   https://wiki.hypr.land/configuring/core/config-options/#input
--   https://wiki.hypr.land/configuring/core/binds/gestures/

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local inp = (opts and opts.input) or {}

hl.config({
    input = {
        kb_layout    = inp.kb_layout or "us",
        kb_variant   = inp.kb_variant or "",
        kb_model     = inp.kb_model or "",
        kb_options   = inp.kb_options or "",
        kb_rules     = inp.kb_rules or "",
        repeat_rate  = inp.repeat_rate or 40,
        repeat_delay = inp.repeat_delay or 300,
        follow_mouse = inp.follow_mouse or 1,
        sensitivity  = inp.sensitivity or 0.0,

        touchpad = {
            natural_scroll       = (inp.natural_scroll ~= false),
            tap_to_click         = (inp.tap_to_click ~= false),
            disable_while_typing = (inp.disable_while_typing ~= false),
        },
    },

    binds = {
        allow_workspace_cycles   = true,
        workspace_back_and_forth = 0,
        drag_threshold           = 10,
    },
})

-- Cử chỉ vuốt 3 ngón ngang trên Touchpad để chuyển đổi Workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
