local vars = require("variables")
local home = os.getenv("HOME")

-- Shell plugin, built user-local by scripts/build-shell.sh. Quickshell finds
-- the Caelestia and M3Shapes QML modules through QML_IMPORT_PATH, and the
-- shell finds its version helper through CAELESTIA_LIB_DIR.
local shell_prefix = home .. "/.local/lib/ricistrice"
hl.env("QML_IMPORT_PATH", shell_prefix .. "/qml")
hl.env("CAELESTIA_LIB_DIR", shell_prefix .. "/caelestia")

-- Themes (caelestia sets QT_QPA_PLATFORMTHEME=qtengine, an Arch-only package)
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
