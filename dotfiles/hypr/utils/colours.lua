-- The active theme's colours, as a table of Material role -> "rrggbb".
--
-- ~/.config/ricistrice/bin/theme.sh writes them to ~/.local/state (outside
-- ~/.config/hypr, so switching themes never makes the live config drift from
-- the repo) and then runs `hyprctl reload`. Before the first theme is set,
-- scheme/default.lua is used instead.
local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local ok, colours = pcall(dofile, state .. "/ricistrice/hypr-colours.lua")

if ok and type(colours) == "table" then
    return colours
end
return require("scheme.default")
