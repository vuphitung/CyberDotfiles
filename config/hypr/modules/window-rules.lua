-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — WINDOW RULES (modules/window-rules.lua)         ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Tài liệu tham chiếu: https://wiki.hypr.land/configuring/core/rules/window-rules/
-- Chỉ áp dụng rule trên các class/title thực tế đã xác minh, không dùng rule quá rộng.

-- 1. Ngăn ứng dụng tự ý phóng đại đè lên bố cục Tiling
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- 2. Sửa lỗi bóng ma khi kéo thả trên XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- 3. Bộ chọn hình nền PRISM (kitty --class wall-picker)
hl.window_rule({
    name       = "prism-wall-picker",
    match      = { class = "^(wall-picker)$" },
    float      = true,
    size       = { 1100, 700 },
    center     = true,
    dim_around = true,
})

-- 4. Hộp thoại xác thực quyền (Polkit & Pinentry)
hl.window_rule({
    name         = "polkit-authentication-dialog",
    match        = { class = "^(hyprpolkitagent|org\\.kde\\.polkit-kde-authentication-agent-1|polkit-gnome-authentication-agent-1)$" },
    float        = true,
    center       = true,
    stay_focused = true,
    dim_around   = true,
})

hl.window_rule({
    name         = "pinentry-dialog",
    match        = { class = "^(pinentry-)(.*)$" },
    float        = true,
    center       = true,
    stay_focused = true,
})

-- 5. Các tiện ích cài đặt nhanh từ Waybar / SwayNC (Mạng, Bluetooth, Âm thanh)
hl.window_rule({
    name   = "control-panel-applets",
    match  = { class = "^(nm-connection-editor|blueman-manager|pavucontrol|org\\.pulseaudio\\.pavucontrol)$" },
    float  = true,
    size   = { 820, 560 },
    center = true,
})

-- 6. Hộp thoại chọn tệp (XDG Desktop Portal & File Chooser Dialogs)
hl.window_rule({
    name   = "xdg-portal-file-dialogs",
    match  = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "common-file-dialogs",
    match  = { title = "^(Open File|Save File|Save As|Select a File|Choose Files|Open Folder|Confirm to replace files|File Operation Progress)(.*)$" },
    float  = true,
    center = true,
})

-- 7. Cửa sổ Picture-in-Picture (Trình duyệt Chrome / Firefox)
hl.window_rule({
    name              = "browser-pip",
    match             = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = { 640, 360 },
    move              = { "monitor_w-window_w-24", "monitor_h-window_h-24" },
})

-- 8. Trình xem ảnh và phát đa phương tiện độc lập
hl.window_rule({
    name   = "media-picture-viewers",
    match  = { class = "^(imv|feh|org\\.gnome\\.Loupe|eog|mpv)$" },
    float  = true,
    center = true,
})

-- 9. Rise of Kingdoms (Wine / XWayland) — bảo toàn từ cấu hình cá nhân v6
hl.window_rule({
    name  = "rok-wine-float",
    match = { class = "^(launcher\\.exe|mass\\.exe|explorer\\.exe)$" },
    float = true,
})

hl.window_rule({
    name   = "rok-wine-main",
    match  = { class = "^(mass\\.exe)$" },
    center = true,
    size   = { 1280, 720 },
})
