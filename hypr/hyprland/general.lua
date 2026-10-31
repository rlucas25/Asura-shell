local vars = require("variables")

local function layout_bind(bind_table)
    return function()
        local workspace = hl.get_active_special_workspace()
                         or hl.get_active_workspace()

        if not workspace then
            return
        end

        local layout = workspace.tiled_layout

        if bind_table[layout] then
            hl.dispatch(bind_table[layout])
        end
    end
end


hl.config({
    general = {
        layout          = "dwindle",
        allow_tearing   = false,
        gaps_workspaces = vars.workspaceGaps,
        gaps_in         = vars.windowGapsIn,
        gaps_out        = vars.windowGapsOut,
        border_size     = vars.windowBorderSize,

        col = {
            active_border   = vars.activeWindowBorderColour,
            inactive_border = vars.inactiveWindowBorderColour,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },

    scrolling = {
        fullscreen_on_one_column = true,
        focus_fit_method         = 1,
        column_width             = 0.5,
        follow_focus             = true,
        follow_min_visible       = 0.0,
        explicit_column_widths   = "0.25, 0.5, 0.75, 1.0",
    },

--    plugin = {
--        scrolloverview = {
--            gesture_distance = 300,
--            scale = 0.5,
--            workspace_gap = 50,
--            layout = "auto",
--            wallpaper = 0,
--            blur = false,

--            shadow = {
--                enabled = true,
--                range = 25,
--            },
--        },
--    },
})
hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"))
hl.bind("SUPER + SHIFT + Left", layout_bind({
    scrolling = hl.dsp.layout("swapcol l"),
    dwindle = hl.dsp.layout("swapsplit"),
    monocle = hl.dsp.layout("cycleprev"),
    master = hl.dsp.layout("cycleprev"),
}))

hl.bind("SUPER + SHIFT + Right", layout_bind({
    scrolling = hl.dsp.layout("swapcol r"),
    dwindle = hl.dsp.layout("swapsplit"),
    monocle = hl.dsp.layout("cyclenext"),
    master = hl.dsp.layout("cyclenext"),
}))
