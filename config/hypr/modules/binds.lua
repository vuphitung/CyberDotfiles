-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — KEYBINDINGS (modules/binds.lua)                 ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu:
--   https://wiki.hypr.land/configuring/core/binds/
--   https://wiki.hypr.land/configuring/core/binds/flags/
--   https://wiki.hypr.land/configuring/core/binds/submaps/
--   https://wiki.hypr.land/configuring/core/dispatchers/
--
-- Nguyên tắc:
--   1. Mọi phím tắt đều có { description = "..." } để `scripts/keyhints.sh` (Super+F1)
--      đọc trực tiếp từ `hyprctl binds -j`.
--   2. Không có bất kỳ thao tác blocking (io.popen, sleep) nào trong Lua callback.
--   3. Đã giải quyết triệt để xung đột Super + R (trả về submap resize) và
--      Super + Space (mở Rofi drun).

local raw_require = _G.__require or require
local ok, opts = pcall(raw_require, "modules.options")
opts = (ok and type(opts) == "table") and opts or _G.CyberOptions

local mod     = (opts and opts.main_mod) or "SUPER"
local apps    = (opts and opts.apps) or {}
local paths   = (opts and opts.paths) or {}
local scripts = paths.scripts or ((os.getenv("HOME") or "/home/tung") .. "/CyberDotfiles/scripts")
local shots   = paths.screenshots or ((os.getenv("HOME") or "/home/tung") .. "/Pictures/Screenshots")

local terminal     = apps.terminal     or "kitty"
local launcher     = apps.launcher     or "rofi -show drun"
local file_manager = apps.file_manager or (scripts .. "/app-launch.sh file-manager")
local browser      = apps.browser      or (scripts .. "/app-launch.sh browser")
local lock_cmd     = apps.lock         or "loginctl lock-session"
local logout_cmd   = apps.logout       or "wlogout"
local notif_toggle = apps.notif_toggle or "swaync-client -t -sw"
local notif_panel  = apps.notif_panel  or "swaync-client -t -sw"
local clipboard    = apps.clipboard    or "bash -c 'cliphist list | rofi -dmenu -i -p \"Clipboard\" | cliphist decode | wl-copy'"
local wall_picker  = apps.wall_picker  or ("kitty --class wall-picker " .. scripts .. "/wall-picker.sh")
local keyhints     = apps.keyhints     or (scripts .. "/keyhints.sh")
local perf_mode    = apps.perf_mode    or (scripts .. "/power-auto.sh toggle")

-- ── 1. ỨNG DỤNG CHÍNH (CORE APPLICATIONS) ──────────────────────────────────
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(launcher),     { description = "Tìm kiếm App (Rofi)" })
hl.bind(mod .. " + Q",     hl.dsp.exec_cmd(terminal),     { description = "Mở Terminal (Kitty)" })
hl.bind(mod .. " + E",     hl.dsp.exec_cmd(file_manager), { description = "Quản lý File" })
hl.bind(mod .. " + G",     hl.dsp.exec_cmd(browser),      { description = "Trình duyệt Web" })

-- ── 2. QUẢN LÝ CỬA SỔ & BỐ CỤC (WINDOW & LAYOUT MANAGEMENT) ────────────────
hl.bind(mod .. " + C", hl.dsp.window.close(),                                         { description = "Đóng cửa sổ" })
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }), { description = "Toàn màn hình" })
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }),                    { description = "Cửa sổ nổi (Floating)" })
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"),                                  { description = "Đổi hướng chia (Split)" })

-- ── 3. HỆ THỐNG, THÔNG BÁO, GIAO DIỆN & TIỆN ÍCH ───────────────────────────
hl.bind(mod .. " + L",         hl.dsp.exec_cmd(logout_cmd),   { description = "Menu nguồn (Wlogout)" })
hl.bind(mod .. " + P",         hl.dsp.exec_cmd(lock_cmd),     { description = "Khóa màn hình (Hyprlock)" })
hl.bind(mod .. " + I",         hl.dsp.exec_cmd(notif_toggle), { description = "Trung tâm thông báo" })
hl.bind(mod .. " + B",         hl.dsp.exec_cmd(notif_panel),  { description = "Bảng điều khiển nhanh" })
hl.bind(mod .. " + F1",        hl.dsp.exec_cmd(keyhints),     { description = "Xem bảng phím tắt" })
hl.bind(mod .. " + W",         hl.dsp.exec_cmd(wall_picker),  { description = "Chọn hình nền (PRISM)" })
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd(clipboard),    { description = "Lịch sử Clipboard" })
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd(perf_mode),    { description = "Bật/tắt chế độ Lite (không blur/animation)" })

-- Lối thoát khẩn cấp nếu menu nguồn gặp sự cố
hl.bind(mod .. " + CTRL + SHIFT + Q", hl.dsp.exit(), { description = "Thoát khẩn cấp Hyprland" })

-- ── 4. CHỤP ẢNH MÀN HÌNH (SCREENSHOTS) ─────────────────────────────────────
local shot = apps.screenshot or (scripts .. "/screenshot.sh")

hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(shot .. " area"),   { description = "Chụp màn hình vùng chọn" })
hl.bind("Print",               hl.dsp.exec_cmd(shot .. " screen"), { description = "Chụp toàn màn hình" })

-- ── 5. DI CHUYỂN TIÊU ĐIỂM (FOCUS NAVIGATION) ──────────────────────────────
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }),  { description = "Focus cửa sổ trái" })
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus cửa sổ phải" })
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }),    { description = "Focus cửa sổ trên" })
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }),  { description = "Focus cửa sổ dưới" })

-- ── 6. CHẾ ĐỘ RESIZE CỬA SỔ (RESIZE SUBMAP) ────────────────────────────────
hl.bind(mod .. " + R", hl.dsp.submap("resize"), { description = "Chế độ thay đổi kích thước (Resize)" })

hl.define_submap("resize", function()
    hl.bind("right",  hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true, description = "Tăng chiều rộng" })
    hl.bind("left",   hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true, description = "Giảm chiều rộng" })
    hl.bind("up",     hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true, description = "Giảm chiều cao" })
    hl.bind("down",   hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true, description = "Tăng chiều cao" })
    hl.bind("escape", hl.dsp.submap("reset"), { description = "Thoát chế độ Resize" })
    hl.bind("return", hl.dsp.submap("reset"), { description = "Thoát chế độ Resize" })
end)

-- ── 7. KHÔNG GIAN LÀM VIỆC (WORKSPACES 1..10 & SCRATCHPAD) ─────────────────
hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }), { description = "Chuyển về Workspace trước" })

for i = 1, 10 do
    local key = tostring(i % 10)
    local desc_focus = (i <= 6) and ("Chuyển sang Workspace " .. i) or nil
    local desc_move  = (i <= 6) and ("Đưa cửa sổ sang Workspace " .. i) or nil

    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       desc_focus and { description = desc_focus } or {})
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), desc_move  and { description = desc_move }  or {})
end

-- Ngăn kéo ẩn (Special Workspace / Scratchpad)
-- Lưu ý: Dùng Super + Alt + S để đưa cửa sổ vào Scratchpad nhằm tránh xung đột với Super + Shift + S (Chụp vùng chọn)
hl.bind(mod .. " + S",       hl.dsp.workspace.toggle_special("magic"),           { description = "Bật/tắt ngăn kéo ẩn (Scratchpad)" })
hl.bind(mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Đưa cửa sổ vào ngăn kéo ẩn" })

-- Cuộn chuột chuyển Workspace
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ── 8. THAO TÁC CHUỘT (MOUSE DRAG & RESIZE) ────────────────────────────────
-- Lưu ý Hyprland 0.57.2: cờ { mouse = true } là độc quyền (exclusive), không kết hợp với locked/repeating/click.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── 9. PHÍM ĐA PHƯƠNG TIỆN & ĐỘ SÁNG (MEDIA & BRIGHTNESS KEYS) ──────────────
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Tăng âm lượng (+5%)" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true, description = "Giảm âm lượng (-5%)" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, description = "Tắt/bật tiếng loa" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true, description = "Tắt/bật Micro" })

hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Phát / Tạm dừng nhạc" })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Bài nhạc tiếp theo" })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Bài nhạc trước đó" })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true, description = "Tăng độ sáng màn hình (+5%)" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true, description = "Giảm độ sáng màn hình (-5%)" })
