local vars = require("variables")

hl.config({
    decoration = {
        rounding = vars.windowRounding,
        rounding_power = vars.windowRoundingPower,
        active_opacity = vars.activeOpacity or 1.0,
        inactive_opacity = vars.inactiveOpacity or 1.0,
        
        blur = {
            enabled           = vars.blurEnabled,
            size              = vars.blurSize,
            passes            = vars.blurPasses,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true, -- Allows opacity blurring
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            noise             = 0,
        },
        dim_inactive = false,
        dim_strength = 0.25,
        dim_special = 0.5,

        shadow = {
            enabled      = vars.shadowEnabled,
            range        = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color        = vars.shadowColour,
        },
    },
})
