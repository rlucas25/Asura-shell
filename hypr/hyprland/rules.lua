local vars = require("variables")

----------------------
---- Window rules ----
----------------------

-- Opacity is managed dynamically via decoration.active_opacity and decoration.inactive_opacity
-- hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })

hl.window_rule({ match = { float = true, xwayland = false }, center = true }) -- Center all floating windows (not xwayland cause popups)

-- Floating Applications
hl.window_rule({
    match = {
        class =
        "flameshot|xdg-desktop-portal-gtk|guifetch|yad|zenity|wev|org.gnome.FileRoller|file-roller|blueman-manager|com.github.GradienceTeam.Gradience|feh|imv|system-config-printer|org.quickshell",
    },
    tag   = "+float",
})

hl.window_rule({
    match = {
        title =
        "flameshot-pin|(Select|Open)( a)? (File|Folder)(s)?|File (Operation|Upload)( Progress)?|.* Properties|Export Image as PNG|GIMP Crash Debug|Save As|Library",
    },
    tag   = "+float_50_60",
})
hl.window_rule({ match = { class = "steam", title = "Friends List" }, tag = "+float" })
hl.window_rule({ match = { class = "com-atlauncher-App", title = "ATLauncher Console" }, tag = "+float" })
hl.window_rule({ match = { class = "", title = "" }, tag = "+float" })
hl.window_rule({ match = { class = "PandoraLauncher", title = "Minecraft Game Output" }, tag = "+float" })

hl.window_rule({ match = { tag = "float" }, float = true })

-- Opaque Apps (Terminal, Image Viewers, Creative Software, Games) as they prefer native transparency as required
hl.window_rule({
    match = {
        class =
        "flameshot|foot|equibop|org.quickshell|imv|swappy|krita|gimp|inkscape|darktable|resolve|kdenlive|shotcut|blender|godot|(steam_app_(default|[0-9]+))|gamescope",
    },
    tag   = "+opaque_app",
})

hl.window_rule({ match = { tag = "opaque_app" }, opaque = true })

-- Sized & Centered Floaters
hl.window_rule({ match = { class = "foot", title = "nmtui" }, tag = "+float_60_70" })
--hl.window_rule({ match = { class = "kitty" }, tag = "+float_50_60" })
hl.window_rule({ match = { class = "org.pulseaudio.pavucontrol|yad-icon-browser" }, tag = "+float_60_70" })
hl.window_rule({ match = { class = "org.gnome.Settings" }, tag = "+float_70_80" })
hl.window_rule({ match = { class = "nwg-look" }, tag = "+float_50_60" })


hl.window_rule({
    match  = { tag = "float_50_60" },
    float  = true,
    size   = "(monitor_w*0.5) (monitor_h*0.6)",
    center = true,
})
hl.window_rule({
    match  = { tag = "float_60_70" },
    float  = true,
    size   = "(monitor_w*0.6) (monitor_h*0.7)",
    center = true,
})
hl.window_rule({
    match  = { tag = "float_70_80" },
    float  = true,
    size   = "(monitor_w*0.7) (monitor_h*0.8)",
    center = true,
})

-- Terminal
hl.window_rule({match = { class = "kitty"}, opacity = 0.85})


-- Shell Settings
hl.window_rule({ match = { title = "Shell Settings" }, animation = "slide top" })


--VsCode
hl.window_rule({match = { class = "code"}, opacity = 0.9})

--Obsidian
hl.window_rule({match = { class = "md.obsidian.Obsidian"}, opacity = 0.95})

-- Games (Steam, Lutris/Wine, Gamescope)
hl.window_rule({
    match        = { class = "(steam_app_(default|[0-9]+))|gamescope" },
    immediate    = true,
    idle_inhibit = "always",
})

-- Steam
hl.window_rule({ match = { class = "steam" }, rounding = 10 })

-- Picture in picture (resize and move done via script)
hl.window_rule({
    match             = { title = "Picture(-| )in(-| )[Pp]icture" },
    move              = "(monitor_w*0.98-window_w) (monitor_h*0.97-window_h)",
    pin               = true,
    float             = true,
    keep_aspect_ratio = true,
})

-- Ueberzugpp
hl.window_rule({ match = { class = "^(ueberzugpp_.*)$" }, float = true, no_initial_focus = true })

-- Autodesk Fusion 360
hl.window_rule({ match = { class = "fusion360.exe", title = "Fusion360|(Marking Menu)" }, no_blur = true })

-- Ugh xwayland popups
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, tag = "+xwl_popup" })
hl.window_rule({
    match = { xwayland = true, title = "", class = "", initial_title = "", initial_class = "" },
    tag   = "+xwl_popup",
})
hl.window_rule({
    match     = { tag = "xwl_popup" },
    no_dim    = true,
    no_shadow = true,
    no_blur   = true,
    opaque    = true,
    rounding  = 10,
})

----------------------------
---- Special Workspaces ----
----------------------------
--[[
hl.window_rule({ match = { class = "btop" }, workspace = "special:sysmon" })
hl.window_rule({
    match     = {
        class = "feishin|Spotify|Supersonic|Cider|com.github.th_ch.youtube_music|Plexamp|com-maxrave-simpmusic-MainKt",
    },
workspace = "special:music",
})
hl.window_rule({ match = { initial_title = "Spotify( %(?Free%)?)?" }, workspace = "special:music" }) -- Spotify wayland, it has no class for some reason
hl.window_rule({ match = { class = "discord|equibop|vesktop|whatsapp" }, workspace = "special:communication" })
hl.window_rule({ match = { class = "Todoist" }, workspace = "special:todo" })
]]--
-------------------------
---- Workspace rules ----
-------------------------

hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })

---------------------
---- Layer rules ----
---------------------

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })                 -- Colour picker out animation
hl.layer_rule({ match = { namespace = "wayfreeze" }, animation = "fade" })                  -- wayfreeze
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%", blur = true }) -- Fuzzel
hl.layer_rule({ match = { namespace = "quickshell" }, animation = "fade", blur = true })
hl.layer_rule({ match = { namespace = "flameshot" }, animation = "fade", blur = true })
hl.layer_rule({ match = { namespace = "flameshot-gui" }, animation = "fade", blur = true })


hl.layer_rule({
    name = "quickshell-no-blur",
    match = {
        namespace = "^quickshell$",
    },
    animation = "slide bottom",
    blur = false,
})
hl.layer_rule({
    name = "asura-bar",
    match = {
        namespace = "^(asura-bar.*)$",
    },
    animation = "slide top",
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "CenterLauncher",
    match = {
        namespace = "^(CenterLauncher.*)$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "ZenLauncher",
    match = {
        namespace = "^(ZenLauncher.*)$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "ClipboardPanel",
    match = {
        namespace = "^(ClipboardPanel.*)$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "window-switcher",
    match = {
        namespace = "^window-switcher$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "volumeOSD",
    match = {
        namespace = "^volumeOSD$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "NotificationToast",
    match = {
        namespace = "^NotificationToast$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "TimerTransitionPopup",
    match = {
        namespace = "^TimerTransitionPopup$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})
hl.layer_rule({
    name = "lockscreen",
    match = {
        namespace = "^lockscreen$",
    },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.05,
})

hl.layer_rule({
    name      = "qs",
    match     = { namespace = "selection" },
    no_anim   = true,
})
