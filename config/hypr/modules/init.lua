-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   CYBERDOTFILES v7 — MODULE ORCHESTRATOR (modules/init.lua)          ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Nạp tuần tự các module cấu hình với cơ chế cô lập lỗi (fault isolation).
-- Nếu một module gặp lỗi, các module khác (đặc biệt là monitor và binds)
-- vẫn tiếp tục được nạp để bảo vệ phiên làm việc của người dùng.

local raw_require = _G.__require or require

local function load_data_module(mod_name, fallback_name)
    local ok, mod = pcall(raw_require, mod_name)
    if ok and type(mod) == "table" then
        return mod
    end
    if fallback_name then
        local ok2, mod2 = pcall(require, fallback_name)
        if ok2 and type(mod2) == "table" then
            return mod2
        end
    end
    return nil
end

-- 1. Nạp bảng màu Sakura Glass và bảng tùy chọn tập trung trước tiên
local tokens = load_data_module("themes.tokens", "themes/tokens") or _G.CyberTokens
if not tokens then
    tokens = {
        font_ui   = "Inter",
        font_mono = "JetBrainsMono Nerd Font",
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
    }
    _G.CyberTokens = tokens
end

local options = load_data_module("modules.options", "modules/options") or _G.CyberOptions

-- 2. Danh sách các module thực thi theo đúng thứ tự phụ thuộc
local execution_modules = {
    "modules.environment",
    "modules.monitor",
    "modules.input",
    "modules.appearance",
    "modules.animations",
    "modules.workspaces",
    "modules.window-rules",
    "modules.layer-rules",
    "modules.binds",
    "modules.autostart",
}

_G.CyberLoadErrors = {}

local function safe_load(mod_name)
    local ok, err = pcall(require, mod_name)
    if not ok then
        -- Thử lại với dấu gạch chéo '/' nếu tên module có dấu gạch ngang '-'
        local slash_name = mod_name:gsub("%.", "/")
        local ok2, err2 = pcall(require, slash_name)
        if not ok2 then
            local msg = string.format("[CyberDotfiles v7] Lỗi nạp module '%s': %s", mod_name, tostring(err2 or err))
            print(msg)
            table.insert(_G.CyberLoadErrors, msg)
            return false
        end
    end
    return true
end

for _, mod_name in ipairs(execution_modules) do
    safe_load(mod_name)
end

-- 3. Nạp file override cá nhân (config/hypr/user.lua) nếu tồn tại
pcall(require, "user")

-- 4. Nếu có lỗi ở bất kỳ module nào, thông báo rõ ràng qua notify-send
if #_G.CyberLoadErrors > 0 then
    local err_summary = table.concat(_G.CyberLoadErrors, "\n")
    hl.on("hyprland.start", function()
        hl.exec_cmd(string.format("notify-send -u critical 'Hyprland Lua Error' %q", err_summary))
    end)
end

return {
    tokens  = tokens,
    options = options,
    errors  = _G.CyberLoadErrors,
}
