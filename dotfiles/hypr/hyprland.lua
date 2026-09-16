-- RicistRice Hyprland config, adapted from caelestia's hypr/hyprland.lua
-- (refs/caelestia). Hyprland loads hyprland.lua instead of hyprland.conf when
-- it exists, and require("x.y") resolves to ./x/y.lua next to this file, so
-- scripts/check.sh verifies the repo copy, not the live one.
--
-- Caelestia layers ~/.config/caelestia/hypr-vars.lua and hypr-user.lua on top
-- so their installer can update these files; this repo *is* the config, so
-- edit variables.lua (apps, look, keybinds) or the modules below directly.

-- Fallback for any monitor monitors.lua doesn't name
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Written by nwg-displays (it also writes monitors.conf and workspaces.conf,
-- which are kept only so its output stays in sync with the repo; unused)
require("monitors")
require("workspaces")

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")
