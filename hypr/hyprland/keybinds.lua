local vars = require("variables")
local fn   = require("hyprland.functions")


-- ASURA
hl.bind("ALT + Tab", hl.dsp.exec_cmd("qs ipc call switcher next"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call switcher prev"))
hl.bind("SUPER + O", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)

hl.bind("SUPER + A", hl.dsp.exec_cmd("qs ipc call controlpanel toggle"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("qs ipc call player toggle"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("qs ipc call settings toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(vars.kbLock, hl.dsp.exec_cmd("qs ipc call lock toggle"))
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/caffeine.sh"))
hl.bind("SUPER + G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/gamemode.sh"))
-- Launcher
hl.bind(vars.kbLauncher, hl.dsp.exec_cmd(vars.launcher))
hl.bind(vars.kbWallpaperSelector, hl.dsp.exec_cmd(vars.wallpaperSelector))

local check_file = io.open("/tmp/gamemode_on", "r")
if check_file ~= nil then
    io.close(check_file)
    hl.config({
        animations = { enabled = false },
        decoration = { blur = { enabled = false } }
    })
else
    hl.config({
        animations = { enabled = true },
        decoration = { blur = { enabled = true } }
    })
end


-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +5%"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { locked = true })

-- Media
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("CTRL + SUPER + Equal", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("CTRL + SUPER + Minus", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Kill/restart
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), { release = true })
hl.bind(
    "CTRL + SUPER + ALT + R",
    hl.dsp.exec_cmd("pkill qs; sleep .1; qs"),
    { release = true }
)
hl.bind(
    "SUPER + ALT + Q",
    hl.dsp.exec_cmd("pkill qs"),
    { release = true }
)

for i = 1, 10 do
    local key = i % 10     -- 10 maps to key 0
    hl.bind(vars.kbGoToWs .. " + " .. key, fn.wsaction("focus", "", i))
    hl.bind(vars.kbMoveWinToWs .. " + " .. key, fn.wsaction("move", "", i))
    hl.bind(vars.kbGoToWsGroup .. " + " .. key, fn.wsaction("focus", "group", i))
    hl.bind(vars.kbMoveWinToWsGroup .. " + " .. key, fn.wsaction("move", "group", i))
end

-- Go to workspace -1/+1
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + Page_down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })

-- Go to workspace group -1/+1
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "+10" }))

-- Move window to workspace -1/+1
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + SUPER + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })

-- Move window to/from special workspace
hl.bind("CTRL + SUPER + SHIFT + up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

hl.bind("SUPER + tab", function()
    local layouts   = { "scrolling", "dwindle", "master", "monocle" }
    local workspace = hl.get_active_workspace()
    if hl.get_active_special_workspace() then
        workspace = hl.get_active_special_workspace()
    end

    local next_layout = "dwindle"

    if not workspace then
        return
    end

    for i = 1, #layouts do
        if layouts[i] == workspace.tiled_layout then
            local next_layout_idx = (i % #layouts) + 1
            next_layout = layouts[next_layout_idx]
            break
        end
    end

    if workspace.special then
        hl.workspace_rule({ workspace = tostring(workspace.name), layout = next_layout })
    else
        hl.workspace_rule({ workspace = tostring(workspace.id), layout = next_layout })
    end
end)
local MAX_ZOOM = 3
local MIN_ZOOM = 1
local ZOOM_TOGGLE_FACTOR = 1.5

---@param offset number
---@return nil
local function zoom(offset)
    local current = hl.get_config("cursor.zoom_factor")
    if offset ~= nil then
        current = current + offset
    elseif current ~= MIN_ZOOM then
        current = MIN_ZOOM
    else
        current = ZOOM_TOGGLE_FACTOR
    end
    current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
    hl.config({ cursor = { zoom_factor = current } })
end

hl.bind("SUPER + Z", zoom)
hl.bind("SUPER + KP_ADD", function()
    zoom(0.5)
end)
hl.bind("SUPER + minus", function()
    zoom(-0.5)
end)
hl.bind("SUPER + X", function()
    if hl.get_workspace("special:minimized") then
        hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace(), window = "tag:minimized" }))
        hl.dispatch(hl.dsp.window.clear_tags({ window = "tag:minimized" }))
    else
        hl.dispatch(hl.dsp.window.tag({ tag = "minimized", window = hl.get_active_window() }))
        hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
    end
end)
-- Window actions
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))



hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + Minus", hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + Equal", hl.dsp.window.resize(fn.resize_active_window(10, 0)), { repeating = true })
hl.bind("SUPER + SHIFT + Minus", hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + SHIFT + Equal", hl.dsp.window.resize(fn.resize_active_window(0, 10)), { repeating = true })
hl.bind("SUPER + ALT + left", hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + ALT + right", hl.dsp.window.resize(fn.resize_active_window(10, 0)), { repeating = true })
hl.bind("SUPER + ALT + up", hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + ALT + down", hl.dsp.window.resize(fn.resize_active_window(0, 10)), { repeating = true })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(vars.kbMoveWindow, hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(vars.kbResizeWindow, function()
    local a = hl.get_active_window()
    if not a then return end

    if a.fullscreen or a.fullscreenMode == 1 then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
    end

    hl.dispatch(hl.dsp.window.resize())
end, { mouse = true })
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.center())
hl.bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end)
hl.bind(vars.kbPinWindow, hl.dsp.window.pin())
hl.bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
--hl.bind(vars.kbToggleWindowFloating, hl.dsp.window.float())
hl.bind(vars.kbToggleWindowFloating, function()
    local a = hl.get_active_window()
    if not a then return end

    if not a.floating then
        hl.dispatch(hl.dsp.window.float())
        hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(40, 50)))

        hl.dispatch(hl.dsp.window.center())
    else
        hl.dispatch(hl.dsp.window.float())
    end
end)
hl.bind(vars.kbCloseWindow, hl.dsp.window.close())

hl.bind(vars.kbSpecialWs, hl.dsp.workspace.toggle_special("special"))



-- Apps
hl.bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal))
hl.bind(vars.kbTerminal2, hl.dsp.exec_cmd(vars.terminal))
hl.bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser))
hl.bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor))
hl.bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd(vars.audioSettings))


-- PRINT
hl.bind("Print", hl.dsp.exec_cmd("flameshot gui"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("flameshot gui"))

-- Volume
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("SUPER + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    { locked = true, repeating = true }
)

-- Sleep
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd(vars.sleepGestureCmd), { locked = true })

-- Testing
hl.bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!"]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    )
)
