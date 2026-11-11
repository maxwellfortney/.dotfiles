-- Hyprland 0.57+ config (Lua), converted from the old hyprland.conf and
-- modules/*.conf (in git history). https://wiki.hypr.land/configuring/

local home = os.getenv("HOME")

------------------
---- COLORS ------
------------------
-- From the old matugen/colors.conf (matugen's Hyprland template is off, so these are fixed).

local colors = {
    primary  = "rgba(a0cafdff)",
    surface  = "rgba(101418ff)",
    tertiary = "rgba(d6bee5ff)",
}

------------------
---- MONITORS ----
------------------

-- Real monitors
hl.monitor({ output = "HDMI-A-2", mode = "3840x2160@240", position = "0x0", scale = 1.0666667 })
-- Headless monitor for sunshine
hl.monitor({ output = "HEADLESS-2", disabled = true })
-- Fake EDID monitor for sunshine
hl.monitor({ output = "DP-1", disabled = true })

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal         = "kitty -o allow_remote_control=yes"
local fileManager      = "nautilus"
local menu             = "walker"
local browser          = "zen-browser"
local emojiPicker      = "walker -m symbols"
local clipboardHistory = "walker -m clipboard"
local screenshot       = "hyprshot -m region --clipboard-only"

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- PATH for exec
hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or ""))

-- Cursors
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Toolkit backends
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GDK_SCALE", "1") -- xwayland apps scale fix

-- XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Dark mode
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("XDG_PREFER_DARK_MODE", "1")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")
hl.env("ELECTRON_FORCE_DARK_MODE", "1")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-- Firefox, Electron, SDL2
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("SDL_VIDEODRIVER", "wayland")

-- NVIDIA
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("waybar")
    hl.exec_cmd("walker --gapplication-service")
    -- GTK4/libadwaita and Electron apps read this via xdg-desktop-portal
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'")
    -- Sunshine's headless output, then sunshine itself
    hl.exec_cmd("hyprctl output create headless")
    hl.exec_cmd("sunshine")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 12,

        border_size = 2,
        col = {
            active_border   = colors.primary,
            inactive_border = colors.surface,
        },
        resize_on_border = true,

        no_focus_fallback = true,

        allow_tearing = true, -- lets the `immediate` window rule work

        snap = {
            enabled = true,
        },
    },

    decoration = {
        rounding = 18,

        blur = {
            enabled                   = true,
            xray                      = false,
            special                   = false,
            new_optimizations         = true,
            size                      = 14,
            passes                    = 3,
            brightness                = 1,
            noise                     = 0.01,
            contrast                  = 1,
            popups                    = true,
            popups_ignorealpha        = 0.6,
            input_methods             = true,
            input_methods_ignorealpha = 0.8,
        },

        shadow = {
            enabled      = true,
            range        = 30,
            offset       = { 0, 2 },
            render_power = 4,
            color        = "rgba(00000010)",
        },

        dim_inactive = true,
        dim_strength = 0.025,
        dim_special  = 0.07,
    },

    group = {
        col = {
            border_active = colors.tertiary,
        },
        groupbar = {
            col = {
                active = colors.surface,
            },
        },
    },

    animations = {
        enabled = true,
    },
})

----------------------
---- ANIMATIONS ------
----------------------

local function bezier(name, x1, y1, x2, y2)
    hl.curve(name, { type = "bezier", points = { { x1, y1 }, { x2, y2 } } })
end

bezier("linear",        0,    0,    1,    1)
bezier("md3_standard",  0.2,  0,    0,    1)
bezier("md3_decel",     0.05, 0.7,  0.1,  1)
bezier("md3_accel",     0.3,  0,    0.8,  0.15)
bezier("overshot",      0.05, 0.9,  0.1,  1.1)
bezier("crazyshot",     0.1,  1.5,  0.76, 0.92)
bezier("hyprnostretch", 0.05, 0.9,  0.1,  1.0)
bezier("fluent_decel",  0.1,  1,    0,    1)
bezier("easeInOutCirc", 0.85, 0,    0.15, 1)
bezier("easeOutCirc",   0,    0.55, 0.45, 1)
bezier("easeOutExpo",   0.16, 1,    0.3,  1)

hl.animation({ leaf = "windows",          enabled = true, speed = 3,   bezier = "md3_decel",   style = "popin 60%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",   style = "slidevert" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

------------------
---- SETTINGS ----
------------------

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = false,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact      = 0.5,
    },

    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        vrr                        = 0,
        mouse_move_enables_dpms    = true,
        enable_swallow             = true,
        swallow_regex              = "^(kitty)$",
        focus_on_activate          = true,
        initial_workspace_tracking = 0,
        middle_click_paste         = true,
    },

    debug = {
        vfr = false,
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local function key(k) return mainMod .. " + " .. k end
local function shiftKey(k) return mainMod .. " + SHIFT + " .. k end

hl.bind(key("Return"), hl.dsp.exec_cmd(terminal))
hl.bind(key("Q"),      hl.dsp.window.close())
hl.bind(key("M"),      hl.dsp.exit())
hl.bind(key("E"),      hl.dsp.exec_cmd(fileManager))
hl.bind(key("T"),      hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("Space"),  hl.dsp.exec_cmd(menu))
hl.bind(key("P"),      hl.dsp.window.pseudo()) -- dwindle
hl.bind(key("B"),      hl.dsp.exec_cmd(browser))
hl.bind(key("X"),      hl.dsp.exec_cmd('fish -c "xmint-main"'))

-- hyprpicker, save to clipboard
hl.bind(key("C"), hl.dsp.exec_cmd("hyprpicker -ar"))

-- Move focus with mainMod + arrow keys; move the window with SHIFT as well
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(key(dir),      hl.dsp.focus({ direction = dir }))
    hl.bind(shiftKey(dir), hl.dsp.window.move({ direction = dir }))
end

-- Switch workspaces with mainMod + [0-9]; move the window there (staying put) with SHIFT
for i = 1, 10 do
    local k = tostring(i % 10) -- 10 maps to key 0
    hl.bind(key(k),      hl.dsp.focus({ workspace = i }))
    hl.bind(shiftKey(k), hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys for volume and brightness
local held = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     held)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   held)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  held)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  held)

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Reload waybar
hl.bind(key("R"), hl.dsp.exec_cmd("pkill waybar; waybar"))

hl.bind(key("period"), hl.dsp.exec_cmd(emojiPicker))
hl.bind(key("V"),      hl.dsp.exec_cmd(clipboardHistory))
hl.bind(shiftKey("S"), hl.dsp.exec_cmd(screenshot))
hl.bind(shiftKey("M"), hl.dsp.exec_cmd("toggle-monitor"))

----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "pwvucontrol",
    match = { class = "^(com.saivert.pwvucontrol)$" },
    float = true,
    size  = "826 800",
})

hl.window_rule({
    name  = "nwg-look",
    match = { class = "^(nwg-look)$" },
    float = true,
    pin   = true,
    size  = "1000 1000",
})

hl.window_rule({
    name  = "thunar",
    match = { class = "^(thunar)$" },
    float = true,
    pin   = true,
    size  = "826 800",
})

hl.window_rule({
    name  = "blueman-manager",
    match = { class = "^(blueman-manager)$" },
    float = true,
    size  = "826 800",
})

-- Browser picture in picture
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    move  = { "monitor_w*0.725", "monitor_h*0.7" },
    size  = "520 320",
})

---------------------
---- LAYER RULES ----
---------------------

local function blurLayer(namespace, ignoreAlpha)
    hl.layer_rule({
        name         = "blur-" .. namespace,
        match        = { namespace = namespace },
        blur         = true,
        ignore_alpha = ignoreAlpha,
    })
end

blurLayer("waybar", 0.3)
blurLayer("walker", 0.3)
blurLayer("notifications", 0.5)              -- dunst
blurLayer("swaync-control-center", 0.5)
blurLayer("swaync-notification-window", 0.5)
blurLayer("logout_dialog")                    -- wlogout
