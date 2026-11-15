-- GENERATED từ themes/sakura-glass.json bởi scripts/theme-gen.py — ĐỪNG SỬA TAY
-- Module token màu và font thống nhất cho Hyprland 0.57.2 Lua Native Architecture.

local M = {
    theme_name = "sakura-glass",
    font_ui    = "Inter",
    font_mono  = "JetBrainsMono Nerd Font",
    kitty_opacity = 0.72,

    -- Chuỗi màu định dạng Hyprland (rgba/rgb) dùng trực tiếp trong hl.config / hl.window_rule
    hypr = {
        pink         = "rgba(ffb7c5ed)",
        pink_solid   = "rgb(ffb7c5)",
        pink_soft    = "rgba(ffb7c533)",
        border_off   = "rgba(ffffff22)",
        specular     = "rgba(ffffff2e)",
        shadow       = "rgba(00000040)",
        glass        = "rgba(18182080)",
        glass_strong = "rgba(181820b8)",
        glass_hi     = "rgba(ffffff1f)",
        text         = "rgb(f5f5f7)",
        text_muted   = "rgba(f5f5f78c)",
        green        = "rgb(34c759)",
        amber        = "rgb(ffd60a)",
        red          = "rgb(ff453a)",
    },

    -- Dữ liệu gốc (hex + alpha) cho các script hoặc module mở rộng
    raw = {
        glass          = { hex = "#181820", alpha = 0.5, hex8 = "#18182080" },
        glass_strong   = { hex = "#181820", alpha = 0.72, hex8 = "#181820b8" },
        glass_hi       = { hex = "#ffffff", alpha = 0.12, hex8 = "#ffffff1f" },
        specular       = { hex = "#ffffff", alpha = 0.18, hex8 = "#ffffff2e" },
        text           = { hex = "#f5f5f7", alpha = 1, hex8 = "#f5f5f7ff" },
        text_muted     = { hex = "#f5f5f7", alpha = 0.55, hex8 = "#f5f5f78c" },
        pink           = { hex = "#ffb7c5", alpha = 1, hex8 = "#ffb7c5ff" },
        pink_soft      = { hex = "#ffb7c5", alpha = 0.2, hex8 = "#ffb7c533" },
        green          = { hex = "#34c759", alpha = 1, hex8 = "#34c759ff" },
        amber          = { hex = "#ffd60a", alpha = 1, hex8 = "#ffd60aff" },
        red            = { hex = "#ff453a", alpha = 1, hex8 = "#ff453aff" },
        shadow         = { hex = "#000000", alpha = 0.25, hex8 = "#00000040" },
    },
}

_G.CyberTokens = M
return M
